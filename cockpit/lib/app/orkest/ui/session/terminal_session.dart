import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'office_social_state.dart';
import 'office_room_effects.dart';
import 'office_harness_identity.dart';
import 'package:orkest_code/app/orkest/domain/services/git_terminal_event_detector.dart';

import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_scrollback_store.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_status_server.dart';
import 'package:orkest_code/app/core/data/diagnostics/performance_diagnostics.dart';
import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/core/terminal/secret_redactor.dart';
import 'package:orkest_code/app/core/terminal/pty_command_markers.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_monitor.dart';
import 'package:orkest_code/app/core/domain/entities/terminal_profile.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/core/terminal/terminal_controller.dart';
import 'package:orkest_code/app/core/terminal/pty_output_scheduler.dart';
import 'package:orkest_code/app/core/utils/quiet_period_debouncer.dart';
import 'package:orkest_code/app/core/utils/bounded_text_buffer.dart';
import 'package:orkest_code/app/orkest/ui/session/pane_item.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_input.dart';
import 'package:flutter/foundation.dart';
import 'package:pasteboard/pasteboard.dart';
import 'package:orkest_code/app/core/terminal/xterm/xterm.dart';

/// Status de um `claude` (ou outro harness) rodando dentro de uma aba de
/// terminal, reportado pelo `orkest-hook` via socket (ver
/// [TerminalStatusServer]).
enum TerminalStatus { idle, working, waiting }

/// A bounded hook event or state change observed for the current PTY.
class TerminalStatusEvent {
  const TerminalStatusEvent(
    this.status,
    this.at, {
    this.event,
    this.toolName,
    this.activityKind,
    this.activityPhase,
    this.activitySummary,
    this.sequence = 0,
  });

  final TerminalStatus status;
  final DateTime at;
  final String? event;
  final String? toolName;
  final String? activityKind;
  final String? activityPhase;
  final String? activitySummary;
  final int sequence;
}

/// Ciclo de vida efêmero de um subagente observado pelos hooks do harness.
class OfficeSubagent {
  const OfficeSubagent({
    required this.id,
    required this.type,
    required this.startedAt,
    this.finishedAt,
    this.outcome,
    this.parentSubagentId,
  });

  final String id;
  final String? type;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final String? outcome;
  final String? parentSubagentId;
}

/// Uma aba de terminal: um shell num PTY ([TerminalGateway]) ligado a um
/// emulador [Terminal] do xterm. O `TerminalView` (na PaneView) renderiza
/// `terminal`. Mata o PTY no `dispose` (sem órfão).
class TerminalSession extends PaneItem {
  TerminalSession({
    required this.id,
    required this.projectId,
    required this.workingDirectory,
    required this._gateway,
    required this.profile,
    String? title,
    Map<String, String> spawnEnv = const <String, String>{},
    Iterable<String> redactSecrets = const <String>[],
    TerminalScrollbackStore? scrollbackStore,
    String? replay,
    String? startupCommand,
    TerminalEngine engine = TerminalEngine.xterm,
    this._monitor,
    Iterable<OfficeSubagent> restoredOfficeSubagents = const [],
    String? officeIdentity,
    this.officeParentIdentity,
    Map<String, dynamic>? restoredOfficeSocialState,
  }) : officeSocial = OfficeSocialState(
         identity: officeIdentity,
         restored: restoredOfficeSocialState,
       ),
       _scrollback = scrollbackStore,
       _redactor = SecretRedactor(redactSecrets),
       _title = title ?? 'New terminal' {
    // O `ShiftEnterInputHandler` (antes do padrão) faz Shift+Enter virar quebra
    // de linha nos harnesses (claude, codex, pi) em vez de submeter; ele lê o
    // estado do kitty keyboard protocol que `_kitty` rastreia pela saída do PTY.
    terminal = createTerminalController(
      engine,
      xtermInputHandler: CascadeInputHandler([
        ShiftEnterInputHandler(_kitty),
        defaultInputHandler,
      ]),
    );
    _officeSubagents.addEntries(
      restoredOfficeSubagents.map((agent) => MapEntry(agent.id, agent)),
    );
    if (PerformanceDiagnostics.instance.enabled) {
      _firstOutputClock = Stopwatch()..start();
    }

    // Replay do scrollback salvo (restauração): entra na fila ANTES de subir o
    // shell, então a saída viva nasce logo abaixo. No Ghostty a fila só é
    // aplicada após o primeiro resize da view, evitando interpretar posições
    // gravadas numa grade provisória de 80 colunas. O `\x1bc` que limpa estado
    // residual já vem embutido em `replay` (montado na VM).
    if (replay != null && replay.isNotEmpty) terminal.restore(replay);

    // Sobe o shell e liga os dois lados. O `.cast<List<int>>()` re-vincula o
    // tipo do stream (o PTY emite Uint8List) para o `utf8.decoder` aceitar e
    // decodificar em streaming (trata multibyte partido entre chunks).
    _gateway.start(
      workingDirectory: workingDirectory,
      profile: profile,
      rows: 25,
      columns: 80,
      extraEnv: spawnEnv,
    );
    // A pasta do workspace pode ter sumido entre dois boots (o layout salvo
    // ainda aponta pra lá). O gateway abre no ancestral mais próximo em vez de
    // falhar, mas isso precisa ficar VISÍVEL: senão o usuário digita achando
    // que está na pasta do projeto.
    final spawned = _gateway.spawnDirectory;
    if (spawned != null && spawned.fellBack) {
      // Fora da árvore de widgets não há `context`: o `t` global é o acesso
      // certo aqui (ver a regra de i18n no CLAUDE.md).
      terminal.write(
        '\x1b[33m'
        '${t.orkest.terminal.cwdFallbackWarning(requested: spawned.requested, path: spawned.path)}'
        '\x1b[0m\r\n',
      );
    }
    // Coalesce + backpressure (plan/57): um `terminal.write` por frame e
    // `acknowledgeOutput` com cap, pra TUI busy não saturar o isolate principal.
    _coalescer = PtyOutputCoalescer(
      onAcknowledge: _gateway.acknowledgeOutput,
      onFlush: (batch) {
        final firstOutputClock = _firstOutputClock;
        if (firstOutputClock != null) {
          _firstOutputClock = null;
          PerformanceDiagnostics.instance.record(
            PerfMetric.terminalFirstOutput,
            {PerfField.durationUs: firstOutputClock.elapsedMicroseconds},
            force: true,
          );
        }
        _kitty.feed(batch); // observa push/pop do kitty antes de renderizar.
        _commandMarkers.feed(batch);
        terminal.write(batch);
        _observeTerminalActivity();
        _record(batch); // grava o scrollback pra replay no próximo boot.
        _trackCwd(batch); // rastreia o cwd vivo (OSC 7) pra restaurar nele.
        // Saída do PTY costuma coincidir com spawn/troca de processo em
        // foreground — reavalia o ícone sem esperar o timer de baseline.
        _kickHarnessMonitor();
      },
    );
    _coalescer.visible = false; // a view ainda não foi montada
    // Redação dos valores do `.env.orkest` ANTES do coalescer: cobre tela,
    // scrollback gravado e `read-tab` de uma vez. Sem segredos é passthrough.
    final decoded = _gateway.output.cast<List<int>>().transform(
      const Utf8Decoder(allowMalformed: true),
    );
    // Sempre pelo filtro (passthrough quando vazio): o workspace remoto só
    // conhece seus segredos depois do spawn, via [updateRedaction].
    _sub = decoded
        .map(_redactor.feed)
        .where((s) => s.isNotEmpty)
        .listen(
          _coalescer.add,
          onDone: () async {
            final tail = _redactor.flush();
            if (tail.isNotEmpty) _coalescer.add(tail);
            await _coalescer.drained;
            // Fim do stream = processo encerrado (o PTY local fecha a porta no
            // exit; o sidecar fecha no `PtyExitEvent`). No `dispose` fomos nós
            // que matamos — aí não é notícia pra ninguém.
            if (!_disposed) {
              _processExited = true;
              _officeCommands.clear();
              _officeShell = null;
              _setStatus(TerminalStatus.idle);
              notifyListeners();
              onProcessExit?.call();
            }
          },
        );
    terminal.onOutput = (data) {
      _writeInput(data);
    };
    terminal.onResize = (columns, rows) {
      _viewportColumns = columns;
      _viewportRows = rows;
      if (!_firstViewportResize.isCompleted) _firstViewportResize.complete();
      _gateway.resize(rows, columns);
    };
    // Programas mudam o título da janela via OSC 0/2 (ex.: shell mostra o cwd,
    // `vim`/`ssh` mostram o arquivo/host). Refletimos isso no nome da aba.
    terminal.onTitleChanged = (osc) {
      rename(_shortTitle(osc));
      _kickHarnessMonitor();
    };

    // Restauração de aba que rodava um harness (ex.: `claude --resume <sid>`):
    // digita o comando no shell novo. Espera o shell de login (`-l`, que lê
    // `.zprofile`/`.zshrc`) montar o prompt antes de enviar, senão a entrada se
    // perde no meio da init. O `\r` submete. NÃO entra no scrollback do replay
    // (o `_record` já roda; mas o comando é re-derivável, então tudo bem).
    if (startupCommand != null && startupCommand.isNotEmpty) {
      _startupTimer = Timer(const Duration(milliseconds: 600), () {
        _gateway.write(utf8.encode('$startupCommand\r'));
        _kickHarnessMonitor(burst: true);
      });
    }

    _monitor?.registerSession(
      sessionId: id,
      rootPid: () => _gateway.rootProcessId,
      wslDistro: profile.wslDistro,
      onHarnessChanged: (newHarness) {
        if (_activeHarness != newHarness) {
          _activeHarness = newHarness;
          if (newHarness == null) {
            _agentSessionEnded = true;
            _turnActive = false;
            _officePermissionPromptVisible = false;
            _setStatus(TerminalStatus.idle, event: 'SessionEnd');
          } else {
            _agentSessionEnded = false;
            // OSC 133 tracks the shell command that launched this harness.
            // Its lifetime is not a work request inside the interactive app.
            final launchCommand = _ptyCommandId;
            if (launchCommand != null) {
              _officeCommands.remove(launchCommand);
              _ptyCommandId = null;
              if (!_turnActive && _status != TerminalStatus.waiting) {
                _setStatus(TerminalStatus.idle, event: 'SessionStart');
                _notifyDebounce?.cancel();
              }
            }
            _officeTurnCompleted = _status == TerminalStatus.idle;
          }
          notifyListeners();
        }
      },
    );
  }

  /// Disparado quando o turno entra em `idle` ou `waiting` (terminou ou precisa
  /// de aprovação). A VM usa pra notificar o workspace — espelha o `onTurnEnd`
  /// do [AgentSession].
  VoidCallback? onTurnFinished;

  /// Disparado quando o shell muda de diretório (capturado por OSC 7). A VM usa
  /// pra persistir o cwd vivo no layout — assim o restore sobe o shell onde o
  /// usuário parou, não no cwd inicial da aba.
  VoidCallback? onCwdChanged;
  final OfficeSocialState officeSocial;
  String get officeIdentity => officeSocial.identity;
  String? officeParentIdentity;
  VoidCallback? onOfficeStateChanged;
  void updateOfficeSocialState(Map<String, dynamic> data) {
    if (!_disposed && officeSocial.update(data)) onOfficeStateChanged?.call();
  }

  Map<String, dynamic>? _officeShell;
  Map<String, dynamic>? _officeShellDone;
  bool _processExited = false;
  int _ptyCommandSerial = 0;
  String? _ptyCommandId;
  late final _commandMarkers = PtyCommandMarkers(
    onStart: () {
      // A delayed shell marker may arrive after the interactive app was
      // detected. Its launch is not work performed by that app.
      if (_disposed || _processExited || _activeHarness != null) return;
      final previous = _ptyCommandId;
      if (previous != null) _officeCommands.remove(previous);
      final run = 'pty:${++_ptyCommandSerial}';
      _ptyCommandId = run;
      beginOfficeCommand(run, t.orkest.officeWorld.runningCommand);
    },
    onFinish: (code) {
      final run = _ptyCommandId;
      _ptyCommandId = null;
      if (run == null) return;
      finishOfficeCommand(
        run,
        code,
        code == 0
            ? t.orkest.officeWorld.toolCompleted
            : t.orkest.officeWorld.activityError,
      );
      if (_officeCommands.isEmpty && _activeHarness == null) {
        _setStatus(TerminalStatus.idle);
      }
    },
  );
  final Map<String, Map<String, dynamic>> _officeTasks = {};
  int _officeTaskRevision = 0;
  int get officeTaskRevision => _officeTaskRevision;
  List<Map<String, dynamic>> get officeTasks => [
    for (final task in _officeTasks.values)
      Map<String, dynamic>.unmodifiable(task),
  ];
  DateTime? _officeStatusChangedAt;
  String? _reportedOfficeHarness;
  OfficeHarnessIdentity get officeHarness =>
      OfficeHarnessIdentity.resolve(_activeHarness, _reportedOfficeHarness);
  DateTime get officeStatusSince => _officeStatusChangedAt ?? createdAt;
  String get officeVisualStatus {
    if (status == TerminalStatus.waiting) return 'waiting';
    final lastKind = _officeStatusHistory.lastOrNull?.activityKind;
    final waitingForBackground =
        officeShells.any((shell) => shell['background'] == true) &&
        (status == TerminalStatus.idle ||
            lastKind == 'wait' ||
            lastKind == 'command');
    if (waitingForBackground) return 'shell';
    return status.name;
  }

  final Map<String, Map<String, dynamic>> _officeCommands = {};
  final _finishedOfficeActivities = <String>{};
  void _rememberOfficeActivity(String id) {
    _finishedOfficeActivities.add(id);
    if (_finishedOfficeActivities.length > 128) {
      _finishedOfficeActivities.remove(_finishedOfficeActivities.first);
    }
  }

  List<Map<String, dynamic>> get officeShells => [
    ?_officeShell,
    ..._officeCommands.values,
  ]..sort((a, b) => (a['startedAt'] as int).compareTo(b['startedAt'] as int));
  Map<String, dynamic>? get officeShell => officeShells.firstOrNull;
  Map<String, dynamic>? get officeShellDone => _officeShellDone;
  void beginOfficeCommand(String runId, String label) {
    if (_disposed || _officeCommands.containsKey(runId)) return;
    _officeCommands[runId] = {
      'id': runId,
      'label': label,
      'startedAt': DateTime.now().millisecondsSinceEpoch,
      'background': false,
      'kind': 'shell',
    };
    applyOfficeActivity(kind: 'command', phase: 'updated', summary: label);
  }

  void finishOfficeCommand(String runId, int exitCode, String label) {
    if (_disposed || _officeCommands.remove(runId) == null) return;
    final phase = exitCode == 0
        ? 'completed'
        : exitCode >= 128
        ? 'interrupted'
        : 'failed';
    applyOfficeActivity(kind: 'command', phase: phase, summary: label);
    _officeShellDone = {
      'id': '$id:$runId:$phase',
      'kind': exitCode == 0 ? 'done' : 'error',
      'tool': 'ShellDone',
      'icon': exitCode == 0 ? '🎉' : '🌧️',
      'text': label,
      'at': DateTime.now().millisecondsSinceEpoch,
      'error': exitCode != 0,
    };
    notifyListeners();
  }

  /// Disparado quando o processo do PTY termina por conta própria (não pelo
  /// [dispose]). Uma aba de shell fica na tela mostrando o terminal morto; a do
  /// Neovim é assinada pela VM e fecha junto com o `:q`.
  VoidCallback? onProcessExit;

  bool _disposed = false;

  int? _viewportColumns;
  int? _viewportRows;
  final Completer<void> _firstViewportResize = Completer<void>();

  /// Última grade medida pela view, sem recorrer ao tamanho inicial da PTY.
  ({int columns, int rows})? get viewportSize {
    final columns = _viewportColumns;
    final rows = _viewportRows;
    if (columns == null || rows == null) return null;
    return (columns: columns, rows: rows);
  }

  /// Reaplica à PTY a grade efetivamente medida pela view.
  ///
  /// TUIs podem nascer na grade provisória 80x25 antes do primeiro layout. Ao
  /// reativar uma aba, a view também pode ter sido redimensionada enquanto
  /// estava desmontada. Esperar a primeira medida e repeti-la elimina ambos os
  /// casos sem depender de um segundo resize do usuário.
  Future<void> synchronizeViewport() async {
    if (_viewportColumns == null || _viewportRows == null) {
      await _firstViewportResize.future.timeout(
        const Duration(milliseconds: 500),
        onTimeout: () {},
      );
    }
    final columns = _viewportColumns;
    final rows = _viewportRows;
    if (columns != null && rows != null) _gateway.resize(rows, columns);
  }

  TerminalStatus _status = TerminalStatus.idle;
  TerminalStatus get status => _status;
  final List<TerminalStatusEvent> _officeStatusHistory = [];
  int _officeEventSequence = 0;

  /// Generic hook events and state changes observed during this Orkest run.
  /// This is a bounded activity summary, not a provider transcript.
  List<TerminalStatusEvent> get officeStatusHistory =>
      List.unmodifiable(_officeStatusHistory);

  /// A live harness stays in Office between turns. The terminal alone does
  /// not keep its character after the harness session ends.
  bool get hasOfficeAgentPresence =>
      !_processExited &&
      !_agentSessionEnded &&
      (_activeHarness != null ||
          _officeAgentActivityObserved ||
          _status != TerminalStatus.idle ||
          _officeCommands.isNotEmpty ||
          _officeShell?['background'] == true ||
          _officeSubagents.values.any((agent) => agent.finishedAt == null));

  /// Most recent generic prompt/permission event, if this session is waiting.
  int get latestWaitingEventSequence {
    for (final event in _officeStatusHistory.reversed) {
      if (event.activityKind == 'needs_input' ||
          (event.status == TerminalStatus.waiting &&
              event.event != null &&
              event.activityKind == null)) {
        return event.sequence;
      }
    }
    return -1;
  }

  String? get officeWaitingSummary {
    for (final event in _officeStatusHistory.reversed) {
      if (event.activityKind == 'needs_input' &&
          event.activitySummary != null) {
        if (event.activityPhase == 'observed') return null;
        return event.activitySummary;
      }
      if (event.status == TerminalStatus.waiting &&
          event.event != null &&
          event.activityKind == null) {
        return 'Precisa de uma resposta no terminal';
      }
    }
    return null;
  }

  final Map<String, OfficeSubagent> _officeSubagents = {};
  List<OfficeSubagent> get officeSubagents {
    final expiry = DateTime.now().subtract(const Duration(seconds: 45));
    _officeSubagents.removeWhere(
      (_, agent) => agent.finishedAt?.isBefore(expiry) ?? false,
    );
    return List.unmodifiable(_officeSubagents.values);
  }

  /// Registra eventos sem tocar no status do terminal principal. A retenção
  /// curta após a conclusão permite ao simulador executar a entrega e a saída.
  void applySubagentEvent({
    required String id,
    required String? type,
    String? outcome,
    String? parentSubagentId,
    required bool started,
  }) {
    final safeId = id.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (safeId.isEmpty) return;
    final rawType = type?.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    final safeType = rawType == null || rawType.length <= 80
        ? rawType
        : rawType.substring(0, 80);
    final rawParentId = parentSubagentId
        ?.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
    final safeParentId = rawParentId == null || rawParentId.length <= 120
        ? rawParentId
        : rawParentId.substring(0, 120);
    final safeOutcome = switch (outcome) {
      'success' || 'error' || 'interrupted' => outcome,
      _ => null,
    };
    final previous = _officeSubagents[safeId];
    if (started) {
      if (previous?.finishedAt != null) return; // descarta start reordenado.
      _officeSubagents[safeId] = OfficeSubagent(
        id: safeId,
        type: safeType == null || safeType.isEmpty ? previous?.type : safeType,
        startedAt: previous?.startedAt ?? DateTime.now(),
        parentSubagentId: safeParentId == null || safeParentId.isEmpty
            ? previous?.parentSubagentId
            : safeParentId,
      );
    } else if (previous == null) {
      // Cria tombstone curto: hooks são processos independentes e o Stop pode
      // chegar antes do Start. Assim um Start atrasado não ressuscita o ator.
      final now = DateTime.now();
      _officeSubagents[safeId] = OfficeSubagent(
        id: safeId,
        type: safeType == null || safeType.isEmpty ? null : safeType,
        startedAt: now,
        finishedAt: now,
        outcome: safeOutcome,
        parentSubagentId: safeParentId,
      );
    } else if (previous.finishedAt == null) {
      _officeSubagents[safeId] = OfficeSubagent(
        id: safeId,
        type: safeType == null || safeType.isEmpty ? previous.type : safeType,
        startedAt: previous.startedAt,
        finishedAt: DateTime.now(),
        outcome: safeOutcome,
        parentSubagentId: safeParentId == null || safeParentId.isEmpty
            ? previous.parentSubagentId
            : safeParentId,
      );
    }
    final expiry = DateTime.now().subtract(const Duration(seconds: 45));
    _officeSubagents.removeWhere(
      (_, agent) => agent.finishedAt?.isBefore(expiry) ?? false,
    );
    notifyListeners();
  }

  HarnessKind? _activeHarness;
  HarnessKind? get activeHarness => _activeHarness;

  /// `true` enquanto o harness está processando um turno (acende o spinner).
  @override
  bool get isWorking => _status == TerminalStatus.working;

  /// Perfil que subiu esta aba (login shell, PowerShell, `Ubuntu (WSL)`…).
  /// Guardado pra fatia 3 (dropdown do `+`) e pra restauração da aba no perfil
  /// em que ela nasceu.
  final TerminalProfile profile;

  /// Session-id e transcript do agente rodando nesta aba, capturados dos hooks.
  /// Servem pra retomar a sessão no restore da aba e pra ler o `.jsonl`.
  String? claudeSessionId;
  String? transcriptPath;

  /// Qual harness emitiu o [claudeSessionId]. Sem isso o restore montaria
  /// sempre `claude --resume <id>` — que falha com "No conversation found" se o
  /// id veio do Codex.
  AgentHarness agentHarness = AgentHarness.claude;

  bool _unseen = false;
  @override
  bool get unseenFinish => _unseen;

  @override
  void markUnseen() {
    if (_unseen) return;
    _unseen = true;
    notifyListeners();
  }

  @override
  void clearUnseen() {
    if (!_unseen) return;
    _unseen = false;
    notifyListeners();
  }

  Timer? _notifyDebounce;

  /// `true` entre o início do turno (`UserPromptSubmit`) e o seu fim (`Stop` →
  /// idle). Um `working` de atividade mid-turn (Pre/PostToolUse) só é válido com
  /// um turno ativo — se chega sem turno ativo logo após um `idle`, é um hook
  /// tardio/reordenado do turno que já acabou e é descartado (senão o spinner
  /// fica girando pra sempre).
  bool _turnActive = false;
  bool _agentSessionEnded = false;
  bool _officeTurnCompleted = false;
  DateTime? _lastIdleAt;
  // Completion text is scoped to the current turn, not deduplicated forever.
  // Only rows already present when work starts are stale until they disappear.
  final Set<int> _officeCompletionBaseline = <int>{};
  final Set<int> _observedOfficeActivityFingerprints = <int>{};
  final Queue<int> _observedOfficeActivityOrder = Queue<int>();
  static const _gitEventDetector = GitTerminalEventDetector();
  DateTime? _lastOfficeActivityScanAt;
  DateTime? _lastOfficeGitScanAt;
  List<String>? _previousGitScreenLines;
  bool _awaitingGitPushResult = false;
  bool _officeAgentActivityObserved = false;
  bool _officePermissionPromptVisible = false;
  bool _suppressVisiblePermissionPrompt = false;

  /// Janela em que um `working` mid-turn órfão (sem turno ativo) pós-`idle` é
  /// tratado como reordenação. Generosa (a real reordenação chega em ms); turnos
  /// novos legítimos vêm como `UserPromptSubmit` (isTurnStart), que nunca é
  /// filtrado — então a janela não atrapalha follow-ups enfileirados.
  static const Duration _staleWorkingGuard = Duration(seconds: 5);

  /// Aplica um status reportado pelo `orkest hook` (via [TerminalStatusServer]).
  /// [sessionId]/[transcriptPath]/[harness] são capturados pra persistência —
  /// é o que permite retomar a aba no harness certo.
  /// [isTurnStart] = evento `UserPromptSubmit` (início de turno).
  void applyClaudeStatus({
    required TerminalStatus status,
    bool isTurnStart = false,
    String? event,
    String? toolName,
    String? sessionId,
    String? transcriptPath,
    AgentHarness? harness,
  }) {
    if (_disposed) return;
    final startsSession = event == 'SessionStart';
    // A terminal can outlive its agent. Late hooks must neither revive an
    // ended session nor replace its resume identity with another agent's ID.
    if (!startsSession &&
        (_agentSessionEnded ||
            (sessionId != null &&
                sessionId.isNotEmpty &&
                claudeSessionId != null &&
                claudeSessionId != sessionId))) {
      return;
    }
    if (startsSession) {
      _agentSessionEnded = false;
      _officeAgentActivityObserved = true;
    }
    if (status != TerminalStatus.waiting) {
      // An authoritative hook settles any approval still painted in the TUI.
      // Do not reinterpret that same screen as a new request on the next tick.
      _suppressVisiblePermissionPrompt = _visiblePermissionPrompt();
      _officePermissionPromptVisible = false;
    } else {
      _officePermissionPromptVisible = _visiblePermissionPrompt();
      _suppressVisiblePermissionPrompt = false;
    }
    if (event == 'SessionEnd') {
      _agentSessionEnded = true;
      _turnActive = false;
      _officePermissionPromptVisible = false;
    }
    // O harness anda junto do id: trocar um sem o outro montaria um comando de
    // resume com o id do harness errado.
    if (sessionId != null && sessionId.isNotEmpty && harness != null) {
      agentHarness = harness;
    }
    if (sessionId != null && sessionId.isNotEmpty) claudeSessionId = sessionId;
    if (transcriptPath != null && transcriptPath.isNotEmpty) {
      this.transcriptPath = transcriptPath;
    }

    // Ciclo de vida do turno a partir da semântica do evento.
    if (isTurnStart) {
      _turnActive = true;
      _officeShell = null;
    }
    if (status == TerminalStatus.waiting) _officeShell = null;
    if (status == TerminalStatus.idle) _turnActive = false;
    if (status == TerminalStatus.waiting) _turnActive = false;

    // Guard anti-spinner-eterno: descarta um `working` mid-turn que chega SEM
    // turno ativo e logo após um `idle` — é o Pre/PostToolUse do turno que
    // acabou, entregue fora de ordem depois do `Stop`.
    if (status == TerminalStatus.working &&
        !isTurnStart &&
        !_turnActive &&
        _lastIdleAt != null &&
        DateTime.now().difference(_lastIdleAt!) < _staleWorkingGuard) {
      return;
    }

    if (status == TerminalStatus.waiting && _status == TerminalStatus.waiting) {
      return;
    }
    _setStatus(status, event: event, toolName: toolName);
  }

  /// Adds a provider-neutral activity event without inspecting PTY output.
  /// The Orkest CLI and future adapters can report the same bounded contract.
  void applyOfficeActivity({
    required String kind,
    required String phase,
    required String summary,
    String? activityId,
    String? harness,
  }) {
    final safeKind = kind.trim().toLowerCase();
    final safePhase = phase.trim().toLowerCase();
    // A terminal has one current approval surface. Repeated reports of the
    // pending request must not create fresh notification sequences.
    if (safeKind == 'needs_input' && _status == TerminalStatus.waiting) return;
    final safeSummary = summary
        .replaceAll(RegExp(r'[\x00-\x1F\x7F]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (safeKind.isEmpty || safePhase.isEmpty || safeSummary.isEmpty) return;
    if (_disposed) return;
    if (harness != null &&
        RegExp(r'^[A-Za-z0-9_.:/-]{1,80}$').hasMatch(harness)) {
      _reportedOfficeHarness = harness;
    }
    if (activityId != null &&
        !RegExp(r'^[A-Za-z0-9_.:/-]{1,160}$').hasMatch(activityId)) {
      return;
    }
    // Repository outcomes describe the project, not the agent's current turn.
    // Keep working/idle/waiting and all command lifetimes intact.
    if (safeKind == 'git') {
      if (safePhase != 'completed' && safePhase != 'observed') return;
      if (activityId != null) {
        final key = 'event:git:$activityId';
        if (_finishedOfficeActivities.contains(key)) return;
        _rememberOfficeActivity(key);
      }
      _officeStatusHistory.add(
        TerminalStatusEvent(
          _status,
          DateTime.now(),
          event: 'OfficeActivity',
          activityKind: 'git',
          activityPhase: safePhase,
          activitySummary: safeSummary.substring(
            0,
            safeSummary.length > 160 ? 160 : safeSummary.length,
          ),
          sequence: _officeEventSequence++,
        ),
      );
      if (_officeStatusHistory.length > 200) _officeStatusHistory.removeAt(0);
      notifyListeners();
      return;
    }
    if (const {
      'task_pending',
      'task_started',
      'task_completed',
      'task_removed',
    }.contains(safeKind)) {
      if (activityId == null || safePhase != 'completed') return;
      if (safeKind == 'task_removed') {
        _officeTasks.remove(activityId);
      } else {
        if (!_officeTasks.containsKey(activityId) &&
            _officeTasks.length >= 64) {
          final completed = _officeTasks.entries.where(
            (entry) => entry.value['status'] == 'completed',
          );
          if (completed.isEmpty) return;
          _officeTasks.remove(completed.first.key);
        }
        _officeTasks[activityId] = {
          'id': activityId,
          'title': safeSummary.substring(
            0,
            safeSummary.length > 160 ? 160 : safeSummary.length,
          ),
          'status': switch (safeKind) {
            'task_started' => 'in_progress',
            'task_completed' => 'completed',
            _ => 'pending',
          },
        };
      }
      _officeAgentActivityObserved = true;
      _officeTaskRevision++;
      notifyListeners();
      return;
    }
    // Correlation belongs to an execution, regardless of its producer or tool.
    // Legacy callers without an ID retain the original single-command flow.
    if (activityId != null && (safeKind == 'command' || safeKind == 'wait')) {
      final runId = 'activity:$activityId';
      if (_finishedOfficeActivities.contains(runId)) return;
      if (safePhase == 'started') {
        beginOfficeCommand(runId, safeSummary);
        if (safeKind == 'wait') {
          _officeCommands[runId]?['background'] = true;
          notifyListeners();
        }
      } else if (safePhase == 'updated') {
        final command = _officeCommands[runId];
        if (command != null) {
          command['label'] = safeSummary;
          command['background'] = safeKind == 'wait';
          notifyListeners();
        }
      } else if (const {
        'completed',
        'failed',
        'interrupted',
      }.contains(safePhase)) {
        _rememberOfficeActivity(runId);
        finishOfficeCommand(
          runId,
          safePhase == 'completed'
              ? 0
              : safePhase == 'interrupted'
              ? 130
              : 1,
          safeSummary,
        );
      }
      return;
    }
    final gitKind = switch (safeKind) {
      'pr_opened' => GitTerminalEventKind.prOpened,
      'pr_merged' => GitTerminalEventKind.prMerged,
      'release' => GitTerminalEventKind.release,
      'ci_failed' => GitTerminalEventKind.ciFailed,
      'ci_passed' => GitTerminalEventKind.ciPassed,
      'push' => GitTerminalEventKind.push,
      _ => null,
    };
    if (gitKind != null) {
      if (safePhase != 'completed') return;
      if (activityId != null) {
        final key = 'event:$safeKind:$activityId';
        if (_finishedOfficeActivities.contains(key)) return;
        _rememberOfficeActivity(key);
      }
      _handleObservedGitEvent(
        GitTerminalEvent(
          kind: gitKind,
          summary: safeSummary.substring(
            0,
            safeSummary.length > 160 ? 160 : safeSummary.length,
          ),
          banner: safeSummary.substring(
            0,
            safeSummary.length > 30 ? 30 : safeSummary.length,
          ),
          icon: switch (gitKind) {
            GitTerminalEventKind.ciFailed => '🚨',
            GitTerminalEventKind.ciPassed => '✅',
            GitTerminalEventKind.push => '🚀',
            _ => '🎉',
          },
          isError: gitKind == GitTerminalEventKind.ciFailed,
        ),
      );
      return;
    }
    final terminalPhase = {
      'completed',
      'failed',
      'interrupted',
    }.contains(safePhase);
    if ((safeKind == 'wait' || safeKind == 'command') && terminalPhase) {
      if (_officeShell != null) {
        _officeShellDone = {
          'id': '$id:shell:${DateTime.now().microsecondsSinceEpoch}',
          'kind': safePhase == 'completed' ? 'done' : 'error',
          'tool': 'ShellDone',
          'icon': safePhase == 'completed' ? '🎉' : '🌧️',
          'text': safeSummary,
          'at': DateTime.now().millisecondsSinceEpoch,
          'error': safePhase != 'completed',
        };
      }
      _officeShell = null;
    } else if ((safeKind == 'wait' && safePhase != 'observed') ||
        (safeKind == 'command' && safePhase == 'started')) {
      if (safeKind == 'command') _officeShell = null;
      _officeShell = {
        ...?_officeShell,
        'id':
            _officeShell?['id'] ??
            '$id:shell:${DateTime.now().microsecondsSinceEpoch}',
        'label': safeSummary,
        'startedAt':
            _officeShell?['startedAt'] ?? DateTime.now().millisecondsSinceEpoch,
        'background': safeKind == 'wait',
        'kind': 'shell',
      };
    } else if (!(safeKind == 'done' && _officeShell?['background'] == true) &&
        (safePhase != 'observed' || safeKind == 'needs_input')) {
      _officeShell = null;
    }
    if (safeKind == 'prompt' || safeKind == 'respond') {
      _turnActive = true;
    } else if (safeKind == 'done' || safeKind == 'error') {
      _turnActive = false;
    }
    _officeAgentActivityObserved = true;
    _officeStatusHistory.add(
      TerminalStatusEvent(
        _status,
        DateTime.now(),
        event: 'OfficeActivity',
        activityKind: safeKind,
        activityPhase: safePhase,
        activitySummary: safeSummary.substring(
          0,
          safeSummary.length > 160 ? 160 : safeSummary.length,
        ),
        sequence: _officeEventSequence++,
      ),
    );
    if (_officeStatusHistory.length > 200) {
      _officeStatusHistory.removeRange(0, _officeStatusHistory.length - 200);
    }
    switch (safeKind) {
      case 'needs_input':
        _setStatus(
          TerminalStatus.waiting,
          recordHistory: false,
          forceNotify: true,
          forceTurnFinished: true,
        );
      case 'done' || 'error':
        _setStatus(
          TerminalStatus.idle,
          recordHistory: false,
          forceNotify: true,
        );
      default:
        if (terminalPhase &&
            (safeKind == 'command' || safeKind == 'wait') &&
            _officeTurnCompleted) {
          _setStatus(
            TerminalStatus.idle,
            recordHistory: false,
            forceNotify: true,
          );
          return;
        }
        if (_status == TerminalStatus.waiting &&
            safeKind != 'prompt' &&
            safeKind != 'respond') {
          notifyListeners();
          return;
        }
        _setStatus(
          TerminalStatus.working,
          recordHistory: false,
          forceNotify: true,
        );
    }
  }

  /// A submitted line is a harness-neutral signal that work was requested. The
  /// input itself is never inspected or retained.
  void _observeGenericPromptSubmission({required bool responding}) {
    // Enter in the shell may launch the harness; it is not a prompt submitted
    // inside it. Only attribute input to a session already known to be open.
    if (_agentSessionEnded ||
        (!responding &&
            !_officeAgentActivityObserved &&
            _activeHarness == null)) {
      return;
    }
    if (responding) _officePermissionPromptVisible = false;
    applyOfficeActivity(
      kind: responding ? 'respond' : 'prompt',
      phase: 'started',
      summary: responding
          ? 'Resposta enviada pelo terminal'
          : 'Pedido enviado pelo terminal',
    );
  }

  /// Maps visible TUI status/action rows to Office categories. This reads the
  /// already-rendered terminal buffer after ANSI/control processing; raw PTY
  /// chunks and full line contents are neither persisted nor forwarded. The
  /// recognizer intentionally returns fixed labels, never a command or path.
  void _observeTerminalActivity() {
    if (_disposed || _processExited) return;
    _observeGitTerminalActivity();
    if (_agentSessionEnded || _officeTurnCompleted) return;
    final now = DateTime.now();
    final lastScan = _lastOfficeActivityScanAt;
    if (lastScan != null &&
        now.difference(lastScan) < const Duration(seconds: 1)) {
      return;
    }
    _lastOfficeActivityScanAt = now;

    // Permission prompts are a current screen state, not transcript events.
    // Limit detection to the visible terminal rows so an old approval in the
    // scrollback cannot resurrect a notification after it was answered.
    final visibleLines = terminal.plainLines(limit: _viewportRows ?? 25);
    // Codex retains previous turns above its ready prompt. Those rows belong
    // to this PTY, but no longer describe a pending interaction.
    // The input prompt and previous completion rows can remain painted while
    // Codex runs tools. Its current interruptible status takes precedence.
    final hasActiveWork = visibleLines.any(
      (line) => line.toLowerCase().contains('esc to interrupt'),
    );
    final readyIndex = visibleLines.lastIndexWhere(
      (line) => RegExp(
        r'^[›❯>]\s*Ask Codex to do anything\s*$',
      ).hasMatch(line.trim()),
    );
    final permissionIndex = visibleLines.lastIndexWhere(
      (line) => _mapOfficeActivityLine(line.trim())?.$1 == 'needs_input',
    );
    final activityLines = terminal.plainLines(limit: 80);
    final completionFingerprints = <int>{
      for (final line in activityLines)
        if (_mapOfficeActivityLine(line.trim()) case (
          'done',
          _,
          _,
          final fingerprint,
        ))
          fingerprint,
    };
    _officeCompletionBaseline.retainAll(completionFingerprints);
    final hasNewCompletion = visibleLines.any((line) {
      final observation = _mapOfficeActivityLine(line.trim());
      return observation != null &&
          observation.$1 == 'done' &&
          !_officeCompletionBaseline.contains(observation.$4);
    });
    if (!hasActiveWork &&
        (!_turnActive || hasNewCompletion) &&
        readyIndex >= 0 &&
        readyIndex > permissionIndex) {
      _officePermissionPromptVisible = false;
      _suppressVisiblePermissionPrompt = false;
      _turnActive = false;
      _setStatus(TerminalStatus.idle);
      return;
    }
    final rawPermissionPrompt = permissionIndex >= 0;
    if (!rawPermissionPrompt) _suppressVisiblePermissionPrompt = false;
    final hasVisiblePermissionPrompt =
        rawPermissionPrompt && !_suppressVisiblePermissionPrompt;
    if (hasVisiblePermissionPrompt && !_officePermissionPromptVisible) {
      _officePermissionPromptVisible = true;
      _officeAgentActivityObserved = true;
      applyOfficeActivity(
        kind: 'needs_input',
        phase: 'observed',
        summary: 'Precisa de uma resposta no terminal',
      );
    } else if (!hasVisiblePermissionPrompt) {
      final promptWasVisible = _officePermissionPromptVisible;
      _officePermissionPromptVisible = false;
      // Generic PTYs may not send a structured permission-result event. When
      // a visible approval prompt disappears, treat it as answered and resume
      // the turn; a completion marker found below can settle it to idle.
      if (promptWasVisible && _status == TerminalStatus.waiting) {
        applyOfficeActivity(
          kind: 'respond',
          phase: 'observed',
          summary: 'Resposta recebida no terminal',
        );
      }
    }

    for (final raw in activityLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      final observation = _mapOfficeActivityLine(line);
      if (observation == null) continue;
      final (kind, summary, phase, fingerprint) = observation;
      // The visible-screen transition above emits permission requests. Do not
      // replay matching prompts from scrollback or deduplicate them forever.
      if (kind == 'needs_input') continue;
      if (kind == 'done' &&
          (hasActiveWork || _officeCompletionBaseline.contains(fingerprint))) {
        continue;
      }
      // Startup banners and restored output are not proof of a new turn.
      if (!_turnActive && _status == TerminalStatus.idle) continue;
      _officeAgentActivityObserved = true;
      if (_status == TerminalStatus.waiting && kind != 'needs_input') continue;
      if (kind != 'done') {
        if (!_observedOfficeActivityFingerprints.add(fingerprint)) continue;
        _observedOfficeActivityOrder.addLast(fingerprint);
        if (_observedOfficeActivityOrder.length > 256) {
          _observedOfficeActivityFingerprints.remove(
            _observedOfficeActivityOrder.removeFirst(),
          );
        }
      }
      applyOfficeActivity(kind: kind, phase: phase, summary: summary);
    }
  }

  void _observeGitTerminalActivity() {
    final now = DateTime.now();
    final lastScan = _lastOfficeGitScanAt;
    if (lastScan != null &&
        now.difference(lastScan) < const Duration(seconds: 1)) {
      return;
    }
    _lastOfficeGitScanAt = now;
    final screenLines = terminal.plainLines(limit: 80).toList(growable: false);
    final previousGitLines = _previousGitScreenLines;
    _previousGitScreenLines = screenLines;
    for (final raw in screenLines) {
      final line = raw.trim();
      if (line.isEmpty) continue;

      // The first scan contains scrollback from before this observer started.
      // A Git result must appear on a later screen, not merely be present in
      // old output or documentation when a harness is opened.
      final isNewGitLine =
          previousGitLines != null && !previousGitLines.contains(raw);
      if (isNewGitLine && line.startsWith('To ')) {
        _awaitingGitPushResult = true;
      } else if (isNewGitLine && line.startsWith('From ')) {
        _awaitingGitPushResult = false;
      }
      final gitEvent = isNewGitLine
          ? _gitEventDetector.detect(line, isPushOutput: _awaitingGitPushResult)
          : null;
      if (gitEvent?.kind == GitTerminalEventKind.push) {
        _awaitingGitPushResult = false;
      }
      if (gitEvent != null) {
        // A URL alone may come from pr/release view, documentation or a query.
        // URL results require command context from the VCS result adapter.
        if (gitEvent.url != null) continue;
        final gitFp = Object.hash('git', gitEvent.kind, gitEvent.summary, line);
        if (_observedOfficeActivityFingerprints.add(gitFp)) {
          _observedOfficeActivityOrder.addLast(gitFp);
          if (_observedOfficeActivityOrder.length > 256) {
            _observedOfficeActivityFingerprints.remove(
              _observedOfficeActivityOrder.removeFirst(),
            );
          }
          _handleObservedGitEvent(gitEvent);
        }
      }
    }
  }

  void _handleObservedGitEvent(GitTerminalEvent event) {
    final effects = OfficeRoomEffectsManager.instance;
    switch (event.kind) {
      case GitTerminalEventKind.prOpened:
      case GitTerminalEventKind.prMerged:
      case GitTerminalEventKind.release:
        effects.triggerParty(projectId, event.banner, agentId: id);
      case GitTerminalEventKind.ciFailed:
        effects.triggerAlarm(projectId, event.banner, agentId: id);
      case GitTerminalEventKind.ciPassed:
        effects.resolveAlarm(
          projectId,
          celebrationText: event.banner,
          agentId: id,
        );
      case GitTerminalEventKind.push:
        break;
    }

    applyOfficeActivity(kind: 'git', phase: 'observed', summary: event.summary);
  }

  /// Rechecks the rendered terminal screen while the Office is visible.
  ///
  /// This covers sessions that were already running before the Office opened,
  /// and restored scrollback that was rendered before the PTY output listener
  /// was attached. The scan is throttled and only emits fixed activity labels.
  void refreshOfficeActivityFromScreen() => _observeTerminalActivity();

  bool _visiblePermissionPrompt() => terminal
      .plainLines(limit: _viewportRows ?? 25)
      .any((line) => _mapOfficeActivityLine(line.trim())?.$1 == 'needs_input');

  (String, String, String, int)? _mapOfficeActivityLine(String line) {
    // Common agent TUIs show this while a turn is active. It is an observed
    // state marker, not a harness identity or an inference from silence.
    if (line.toLowerCase().contains('esc to interrupt') &&
        RegExp(r'\bworking\s*\(', caseSensitive: false).hasMatch(line)) {
      return (
        'thinking',
        'Processando solicitação',
        'observed',
        Object.hash('working', 'active'),
      );
    }
    // TUI prompts commonly put the question inside box borders or prefix it
    // with a status glyph. Strip only those presentation characters, then
    // recognize generic approval/confirmation wording across harnesses.
    final promptLine = line
        .trim()
        .replaceFirst(RegExp(r'^[│┃╭╰┌└├┤┬┴┼─━╔╗╚╝]+'), '')
        .replaceFirst(RegExp(r'^(?:🔒|🔐|✋|⚠️|❯|›|>|!|\?)+\s*'), '')
        .trimLeft();
    if (RegExp(
      r'^(permission|approval)\s+(is\s+)?(required|requested|needed|pending)\b|'
      r'^requesting\s+(permission|approval)\s+for\b|'
      r'^(waiting|needs|requires)\b.{0,80}\b(your\s+)?(approval|permission|input|response)\b|'
      r'^(do you want|would you like)\b.{0,100}\b(allow|approve|authorize|run|execute|proceed|continue)\b|'
      r'^(allow|approve|authorize)\s+(this|the|once|always|command|action|request)\b.{0,100}(\?|$)|'
      r'^(run|execute|apply)\s+(this|the)\s+(command|action|change)\b.{0,100}(\?|$)|'
      r'^(select|choose|press)\b.{0,100}\b(allow|approve|yes|deny|reject|once|always|option)\b|'
      r'^(select|choose)\s+an\s+option\b',
      caseSensitive: false,
    ).hasMatch(promptLine)) {
      return (
        'needs_input',
        'Precisa de uma resposta no terminal',
        'observed',
        Object.hash('needs_input', promptLine.toLowerCase()),
      );
    }

    // Action rows are rendered in the agent TUI. Match only row-like prefixes
    // so ordinary project output mentioning “read” or “run” is not classified.
    final marker = RegExp(
      r'^(?:🔴|🟢|🟡|✅|❌|⚠️|ℹ️|●|⏺|○|◦|•|\*|└|├|─|›|❯|>)+\s*',
    ).firstMatch(line);
    final row = marker == null
        ? line.trim()
        : line.substring(marker.end).trim();
    if (row.isEmpty) return null;
    final lower = row.toLowerCase();
    if (RegExp(
      r'^(worked for\s+\d|concluiu em\s+\d|turn completed\b|task completed\b|turn finished\b|task finished\b|turno conclu[ií]do\b|tarefa conclu[ií]da\b)',
      caseSensitive: false,
    ).hasMatch(row)) {
      return (
        'done',
        'Turno concluído',
        'observed',
        Object.hash('done', lower),
      );
    }
    if (marker == null) {
      if (RegExp(r'^(thinking|pensando)\.{0,3}$').hasMatch(lower)) {
        return (
          'thinking',
          'Pensando',
          'observed',
          Object.hash('thinking', lower),
        );
      }
      return null;
    }
    if (RegExp(
      r'^(ran|running|executing|executed|failed|falhou)\b.*\b(failed|errored|error|falhou|erro)\b',
      caseSensitive: false,
    ).hasMatch(row)) {
      return (
        'error',
        'A execução encontrou um erro',
        'observed',
        Object.hash('error', lower),
      );
    }
    String? kind;
    String? summary;
    if (RegExp(r'^(edited|editing|editando)\b').hasMatch(lower)) {
      kind = 'edit';
      summary = 'Editando arquivo';
    } else if (RegExp(
      r'^(wrote|writing|escrevendo|escreveu)\b',
    ).hasMatch(lower)) {
      kind = 'write';
      summary = 'Escrevendo arquivo';
    } else if (RegExp(r'^opened\b').hasMatch(lower)) {
      final opensWebResource = RegExp(r'\bhttps?://').hasMatch(lower);
      kind = opensWebResource ? 'web' : 'read';
      summary = opensWebResource ? 'Abrindo página web' : 'Abrindo arquivo';
    } else if (RegExp(r'^(read|reading|lendo|leu)\b').hasMatch(lower)) {
      kind = 'read';
      summary = 'Lendo arquivo';
    } else if (RegExp(
      r'^(explored|searching|searched|buscando|pesquisando)\b',
    ).hasMatch(lower)) {
      kind = 'search';
      summary = 'Buscando no código';
    } else if (RegExp(r'^(browsing|searched) the web\b').hasMatch(lower)) {
      kind = 'web';
      summary = 'Pesquisando na web';
    } else if (RegExp(
      r'^(running tests|ran .*test|rodando testes|executando testes)\b',
    ).hasMatch(lower)) {
      kind = 'test';
      summary = 'Rodando testes';
    } else if (RegExp(
      r'^(ran|running|executing|executando|comando no terminal)\b',
    ).hasMatch(lower)) {
      kind = 'command';
      summary = 'Executando comando';
    } else if (RegExp(r'^(thinking|pensando)\b').hasMatch(lower)) {
      kind = 'thinking';
      summary = 'Pensando';
    } else if (RegExp(
      r'^(calling subagents|chamando subagentes)\b',
    ).hasMatch(lower)) {
      kind = 'delegate';
      summary = 'Chamando subagentes';
    } else if (RegExp(
      r'^(organizing tasks|organizando tarefas)\b',
    ).hasMatch(lower)) {
      kind = 'plan';
      summary = 'Organizando tarefas';
    }
    if (kind == null || summary == null) return null;
    return (kind, summary, 'observed', Object.hash(kind, lower));
  }

  /// Detecta o **interrupt** do harness na entrada do usuário. O Claude Code
  /// (e demais harnesses) interrompem o turno com um `ESC` cru; e o Claude
  /// Code **não emite `Stop` num interrupt do usuário** — só quando o turno
  /// termina sozinho. Sem isto, o último hook recebido seria um `working`
  /// (Pre/PostToolUse) e o spinner giraria pra sempre. Um `ESC` cru (`\x1b`
  /// sozinho, sem sequência de seta/função) enquanto `working` zera o status
  /// otimista. Se não era interrupt de fato, o `_staleWorkingGuard` descarta o
  /// `working` mid-turn tardio, e um `UserPromptSubmit` legítimo reacende.
  void _maybeInterrupt(String data) {
    if (data == '\x1b' && _status == TerminalStatus.waiting) {
      // Escape is the harness' explicit cancel response for permission and
      // choice prompts. Closing the Office mirror never calls this path.
      _officePermissionPromptVisible = false;
      applyOfficeActivity(
        kind: 'respond',
        phase: 'started',
        summary: 'Solicitação cancelada no terminal',
      );
      return;
    }
    if (data == '\x1b' && _status == TerminalStatus.working) {
      _turnActive = false;
      _notifyDebounce?.cancel();
      _setStatus(TerminalStatus.idle);
    }
  }

  void _setStatus(
    TerminalStatus next, {
    String? event,
    String? toolName,
    bool recordHistory = true,
    bool forceNotify = false,
    bool forceTurnFinished = false,
  }) {
    _officeTurnCompleted =
        next == TerminalStatus.idle && event != 'SessionStart';
    final changed = next != _status;
    if (!changed && event == null && !forceNotify) return;
    if (changed) {
      if (next == TerminalStatus.working && _status == TerminalStatus.idle) {
        _officeCompletionBaseline.clear();
        for (final line in terminal.plainLines(limit: 80)) {
          final observation = _mapOfficeActivityLine(line.trim());
          if (observation != null && observation.$1 == 'done') {
            _officeCompletionBaseline.add(observation.$4);
          }
        }
      }
      _status = next;
      _officeStatusChangedAt = DateTime.now();
    }
    final lifecycleOnly = event == 'SessionStart' || event == 'SessionEnd';
    final safeToolName = toolName
        ?.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '')
        .trim();
    if (!lifecycleOnly && recordHistory) {
      _officeStatusHistory.add(
        TerminalStatusEvent(
          next,
          DateTime.now(),
          event: event,
          toolName: safeToolName == null || safeToolName.isEmpty
              ? null
              : safeToolName.substring(
                  0,
                  safeToolName.length > 80 ? 80 : safeToolName.length,
                ),
          sequence: _officeEventSequence++,
        ),
      );
      if (_officeStatusHistory.length > 200) {
        _officeStatusHistory.removeRange(0, _officeStatusHistory.length - 200);
      }
    }
    if (changed && next == TerminalStatus.idle) _lastIdleAt = DateTime.now();
    notifyListeners();
    if (!changed && !forceTurnFinished) return;
    // Debounce ~50ms antes de notificar: absorve flicker idle→working numa
    // repintura de TUI (mesma técnica do iTerm2). Só notifica em idle/waiting.
    _notifyDebounce?.cancel();
    if (next == TerminalStatus.idle || next == TerminalStatus.waiting) {
      _notifyDebounce = Timer(const Duration(milliseconds: 50), () {
        if (_status == next) onTurnFinished?.call();
      });
    }
  }

  /// Encurta títulos longos pra caber melhor na aba. Caminhos viram o último
  /// segmento; `~` é mantido; o resto vai como veio (a aba ainda faz ellipsis).
  String _shortTitle(String raw) {
    final t = raw.trim();
    if (t.isEmpty || !t.contains('/')) return t;
    final segments = t.split('/').where((s) => s.isNotEmpty).toList();
    return segments.isEmpty ? t : segments.last;
  }

  @override
  final String id;

  /// Momento em que esta aba/PTy foi criada nesta execução do Orkest.
  /// Não representa a idade histórica da conversa do harness ao restaurar.
  final DateTime createdAt = DateTime.now();
  @override
  final String projectId;
  @override
  final String workingDirectory;

  final TerminalGateway _gateway;
  final TerminalHarnessMonitor? _monitor;
  final KittyKeyboardTracker _kitty = KittyKeyboardTracker();

  /// Troca os valores do `.env.orkest` por `***` na saída (ver
  /// [SecretRedactor]). Vazio quando o workspace não tem segredos.
  final SecretRedactor _redactor;

  /// Segredos conhecidos depois do spawn (workspace remoto: o `.env.orkest`
  /// é lido no host pelo gateway, já com a aba viva).
  void updateRedaction(Iterable<String> secrets) => _redactor.update(secrets);
  late final PtyOutputCoalescer _coalescer;
  Stopwatch? _firstOutputClock;

  // --- Persistência do scrollback (replay no próximo boot) --------------------
  // Grava a saída DECODIFICADA (após o `Utf8Decoder` em streaming → sem cortar
  // multibyte). Ring em memória: ao passar de `_kMaxRecordChars`, descarta ~25%
  // da frente de uma vez (trim amortizado). Só main-screen — enquanto em
  // alt-screen (TUI: vim/lazygit), a saída é efêmera e NÃO entra no registro.
  final TerminalScrollbackStore? _scrollback;
  late final BoundedTextBuffer _record0 = BoundedTextBuffer(
    maxLength: _kMaxRecordChars,
  );
  int _altDepth = 0;
  late final QuietPeriodDebouncer _saveDebounce = QuietPeriodDebouncer(
    delay: const Duration(seconds: 1),
    onQuiet: () => unawaited(_flush()),
  );
  Timer? _startupTimer;
  final List<Timer> _harnessKickTimers = <Timer>[];
  DateTime? _lastHarnessKickAt;

  /// ~2.5 MB ≈ 10000 linhas (casa com `maxLines`). Acima disso, corta a frente.
  static const int _kMaxRecordChars = 2500000;
  static final RegExp _altScreenSeq = RegExp(r'\x1b\[\?(1049|1047|47)([hl])');

  /// OSC 7 (`ESC ] 7 ; file://host/path BEL|ST`) — o shell reporta o cwd a cada
  /// prompt. Captura o path (grupo 1) até o terminador (BEL `\x07` ou ST `\x1b\`).
  static final RegExp _osc7 = RegExp(
    r'\x1b\]7;file://[^/]*(/[^\x07\x1b]*)(?:\x07|\x1b\\)',
  );

  /// Diretório atual do shell, rastreado por OSC 7. `null` até o 1º prompt (ou
  /// se o shell não emitir OSC 7). A VM persiste isso pra restaurar o cwd.
  String? _cwd;
  String? get currentDirectory => _cwd;
  String _title;
  late final OrkestTerminalController terminal;
  StreamSubscription<String>? _sub;

  @override
  String get title => _title;

  void rename(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty || trimmed == _title) return;
    _title = trimmed;
    notifyListeners();
  }

  /// Insere [text] diretamente no PTY como se o usuário tivesse digitado/colado
  /// (ex.: caminho de arquivo arrastado até o terminal).
  void insertText(String text) => _writeInput(utf8.encode(text));

  /// Envia bytes CRUS ao PTY (sequências de controle: ESC, setas, F-keys,
  /// Ctrl+C...). Usado pela barra de teclas do mobile — plano 60, Wave F.
  void sendKeys(List<int> bytes) => _writeInput(bytes);

  /// Sends an arrow through the terminal engine's keyboard mode encoder.
  void sendArrow({required bool up}) => terminal.sendArrow(up: up);

  void _writeInput(List<int> bytes) {
    final text = utf8.decode(bytes, allowMalformed: true);
    _maybeInterrupt(text);
    _gateway.write(bytes);
    // Newline submission is a harness-neutral signal that a request/command
    // was sent. It does not inspect or classify the submitted text.
    if (text.contains('\r') || text.contains('\n')) {
      _observeGenericPromptSubmission(
        responding: _status == TerminalStatus.waiting,
      );
      _kickHarnessMonitor(burst: true);
    }
  }

  /// Copia a seleção do terminal pro clipboard. No-op sem seleção.
  ///
  /// Existe para o botão de copiar da barra de teclas do mobile: lá não há
  /// atalho de teclado nem menu de contexto, então o único caminho é este.
  /// Usa o mesmo `Pasteboard` do paste (e não o `Clipboard` do Flutter) pra a
  /// aba ficar com um clipboard só, coerente nos dois sentidos.
  void copySelection() {
    final text = terminal.selectedText();
    if (text.isEmpty) return;
    Pasteboard.writeText(text);
  }

  /// Cola do clipboard no terminal, com suporte a **imagem**.
  ///
  /// No macOS, consulta texto primeiro: apps de ditado podem simular Cmd+V e
  /// restaurar o clipboard logo depois. Consultar a imagem antes acrescentava
  /// uma chamada assíncrona e podia perder essa janela curta. Se há uma imagem
  /// no clipboard, manda o byte de Ctrl+V (`\x16`) pro harness
  /// em primeiro plano (claude/codex/pi) — todos eles, ao receber `\x16`, leem a
  /// imagem do clipboard e a anexam (claude mostra `[Image #1]`, o pi grava num
  /// `.png` temporário). Sem imagem, faz o paste de texto normal (respeitando o
  /// bracketed paste mode).
  ///
  /// Por que existe: o `TerminalView` só cola texto (via `Clipboard`, que não lê
  /// imagem) e, no macOS, o caminho de IME engole o Ctrl+V cru (vira `pageDown`),
  /// então o `\x16` nunca era gerado e a imagem nunca chegava ao harness.
  Future<void> pasteFromClipboard() async {
    if (defaultTargetPlatform == TargetPlatform.macOS) {
      final text = await Pasteboard.text;
      if (text != null && text.isNotEmpty) {
        terminal.paste(text);
        return;
      }
    }
    final image = await Pasteboard.image;
    if (image != null && image.isNotEmpty) {
      _gateway.write(const [
        0x16,
      ]); // Ctrl+V: o harness lê a imagem do clipboard.
      return;
    }
    final text = await Pasteboard.text;
    if (text != null && text.isNotEmpty) {
      terminal.paste(text);
      return;
    }
    // Windows: `Pasteboard.image` só lê `CF_DIB`; muitos apps (browsers, algumas
    // ferramentas de captura) põem a imagem só como PNG/formato registrado →
    // devolve `null` e o `\x16` nunca ia, então a imagem não chegava no harness.
    // Sem texto no clipboard, é provável ser uma imagem que não conseguimos ler
    // — manda `\x16` mesmo assim pro harness (claude/codex/pi) ler o clipboard
    // ele mesmo. macOS/Linux não precisam: lá o `Pasteboard.image` já funciona.
    if (defaultTargetPlatform == TargetPlatform.windows) {
      _gateway.write(const [0x16]);
    }
  }

  /// Acumula a saída no registro de scrollback, rastreando alt-screen (não grava
  /// estado de TUI) e limitando o tamanho. Agenda o flush em disco (~1s).
  void _record(String data) {
    if (_scrollback == null) return;

    // Atualiza a profundidade de alt-screen a partir das sequências no chunk.
    // Faz isso ANTES de decidir gravar: se o chunk entra em alt-screen no meio,
    // o prefixo (main-screen) ainda é scrollback legítimo, mas pra simplicidade
    // e robustez gravamos o chunk inteiro só quando começa e termina em
    // main-screen — o `\x1bc` no replay cobre qualquer resíduo.
    final wasMain = _altDepth == 0;
    for (final m in _altScreenSeq.allMatches(data)) {
      if (m.group(2) == 'h') {
        _altDepth++;
      } else if (_altDepth > 0) {
        _altDepth--;
      }
    }
    // tocou alt-screen → descarta chunk.
    if (!wasMain || _altDepth != 0) return;

    _record0.add(data);
    _saveDebounce.trigger();
  }

  /// Pede ao monitor uma reavaliação imediata do harness. Com [burst], agenda
  /// retries curtos para cobrir a corrida entre submit e o filho aparecer em
  /// `/proc` (fork+exec ainda em andamento no 1º poll).
  void _kickHarnessMonitor({bool burst = false}) {
    final monitor = _monitor;
    if (monitor == null) return;

    final now = DateTime.now();
    final last = _lastHarnessKickAt;
    if (!burst &&
        last != null &&
        now.difference(last) < const Duration(milliseconds: 40)) {
      return;
    }
    _lastHarnessKickAt = now;
    monitor.requestPoll(sessionId: id, urgent: burst);

    if (!burst) return;
    for (final t in _harnessKickTimers) {
      t.cancel();
    }
    _harnessKickTimers
      ..clear()
      ..addAll([
        for (final delay in const [
          Duration(milliseconds: 40),
          Duration(milliseconds: 120),
          Duration(milliseconds: 280),
        ])
          Timer(delay, () => monitor.requestPoll(sessionId: id, urgent: true)),
      ]);
  }

  /// Atualiza apenas a prioridade de observação do harness. O PTY e os
  /// processos nunca são pausados quando a aba/workspace fica oculto.
  void setVisible(bool visible) {
    _coalescer.visible = visible;
    _monitor?.setSessionVisible(id, visible);
  }

  /// Atualiza [_cwd] a partir de OSC 7 no chunk. Pega a ÚLTIMA ocorrência (o
  /// prompt mais recente). Notifica a VM quando muda → persiste no layout.
  void _trackCwd(String data) {
    String? path;
    for (final m in _osc7.allMatches(data)) {
      path = m.group(1);
    }
    if (path == null) return;
    final decoded = Uri.decodeFull(path);
    if (decoded == _cwd) return;
    _cwd = decoded;
    onCwdChanged?.call();
  }

  /// Scrollback gravado até agora (main-screen apenas), no mesmo formato que
  /// vai pro store. O reinício da aba usa como `replay` da sessão nova sem
  /// esperar o flush em disco.
  String get scrollbackSnapshot => _record0.toString();

  Future<void> _flush() async {
    final store = _scrollback;
    if (store == null) return;
    await store.save(
      projectId: projectId,
      sessionId: id,
      contents: _record0.toString(),
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    officeSocial.clear();
    onOfficeStateChanged = null;
    _officeCommands.clear();
    _finishedOfficeActivities.clear();
    _officeTasks.clear();
    _officeShell = null;
    _monitor?.unregisterSession(id);
    _notifyDebounce?.cancel();
    _saveDebounce.dispose();
    _startupTimer?.cancel();
    for (final t in _harnessKickTimers) {
      t.cancel();
    }
    _harnessKickTimers.clear();
    unawaited(
      _flush(),
    ); // best-effort: persiste o estado final (inclui app-quit).
    await _sub?.cancel();
    _coalescer.dispose();
    await _gateway.kill();
    terminal.dispose();
    super.dispose();
  }
}
