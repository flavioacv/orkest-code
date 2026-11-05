import 'dart:collection';
import 'package:orkest_code/app/core/domain/entities/harness_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_diagnostic_service.dart';

/// Coordenador de estado e precedência formal dos sinais de harness (H01).
///
/// Aplica regras estritas de precedência de fontes, proteção contra sinais atrasados
/// de gerações anteriores, deduplicação de atividades finalizadas e separação
/// independente entre presença, fase de execução e espera de input humano.
class HarnessStateCoordinator {
  HarnessStateCoordinator({
    HarnessPresence initialPresence = HarnessPresence.none,
    HarnessExecutionPhase initialPhase = HarnessExecutionPhase.idle,
    int initialGeneration = 0,
    String? initialSessionId,
  })  : _presence = initialPresence,
        _phase = initialPhase,
        _currentGeneration = initialGeneration,
        _currentSessionId = initialSessionId,
        _lastUpdatedAt = DateTime.now();

  static const int kMaxSettledActivities = 256;

  HarnessPresence _presence;
  HarnessExecutionPhase _phase;
  int _currentGeneration;
  String? _currentSessionId;
  String? _currentTurnId;
  String? _activeActivityId;
  String? _lastSummary;
  HarnessSignalSource _lastSource = HarnessSignalSource.userInput;
  DateTime _lastUpdatedAt;

  bool _hasEverReceivedSignal = false;
  int _totalSignalsReceived = 0;
  final Map<HarnessSignalSource, int> _sourceDistribution = <HarnessSignalSource, int>{};

  final LinkedHashSet<String> _settledActivityIds = LinkedHashSet<String>();
  final LinkedHashSet<String> _activeActivityIds = LinkedHashSet<String>();

  /// Snapshot imutável do estado atual.
  HarnessStateSnapshot get snapshot => HarnessStateSnapshot(
    presence: _presence,
    phase: _phase,
    generation: _currentGeneration,
    sessionId: _currentSessionId,
    turnId: _currentTurnId,
    activeActivityId: _activeActivityId,
    lastSummary: _lastSummary,
    lastSource: _lastSource,
    lastUpdatedAt: _lastUpdatedAt,
  );

  HarnessPresence get presence => _presence;
  HarnessExecutionPhase get phase => _phase;
  int get generation => _currentGeneration;
  String? get currentSessionId => _currentSessionId;
  String? get currentTurnId => _currentTurnId;
  bool get hasActiveActivities => _activeActivityIds.isNotEmpty;

  /// Retorna se ao menos um sinal já foi processado e aceito na sessão.
  bool get hasEverReceivedSignal => _hasEverReceivedSignal;

  /// Total acumulado de sinais aceitos na sessão.
  int get totalSignalsReceived => _totalSignalsReceived;

  /// Origem do último sinal recebido ou `null` se nenhum sinal foi emitido.
  HarnessSignalSource? get lastSource => _hasEverReceivedSignal ? _lastSource : null;

  /// Timestamp do último sinal recebido ou `null` se nenhum sinal foi emitido.
  DateTime? get lastUpdatedAt => _hasEverReceivedSignal ? _lastUpdatedAt : null;

  /// Distribuição de sinais aceitos por fonte.
  Map<HarnessSignalSource, int> get sourceDistribution => Map.unmodifiable(_sourceDistribution);

  /// Gera um diagnóstico de estado seguro e livre de dados sensíveis (H05).
  HarnessStateDiagnostic getDiagnostic({
    DateTime? referenceTime,
    bool limitedDataMode = false,
  }) {
    return HarnessDiagnosticService.buildDiagnostic(
      coordinator: this,
      referenceTime: referenceTime,
      limitedDataMode: limitedDataMode,
    );
  }

  /// Processa um sinal de entrada e resolve a precedência determinística.
  ///
  /// Retorna `true` se o estado foi atualizado; `false` se o sinal foi descartado
  /// por precedência inferior, duplicata ou atraso de geração.
  bool processSignal(HarnessSignal signal) {
    // 1. Descarte de sinais atrasados de gerações anteriores
    if (signal.generation < _currentGeneration &&
        signal.source != HarnessSignalSource.structuredHook) {
      return false;
    }

    // 2. Deduplicação de atividades já assentadas/finalizadas
    if (signal.activityId != null &&
        _settledActivityIds.contains(signal.activityId)) {
      if (signal.phase == HarnessExecutionPhase.running ||
          signal.phase == HarnessExecutionPhase.waitingInput) {
        return false;
      }
    }

    // 3. Resolução de conflitos e precedência de fontes:
    // Observações de tela não podem alterar nem sobrescrever execução ou espera ativa
    // originada de fontes mais fortes (structuredHook / ptyMarker) recebidas recentemente (< 5s).
    if (signal.source == HarnessSignalSource.screenObservation) {
      final isHighPriorityActive =
          (_phase == HarnessExecutionPhase.running ||
              _phase == HarnessExecutionPhase.waitingInput) &&
          (_lastSource == HarnessSignalSource.structuredHook ||
              _lastSource == HarnessSignalSource.ptyMarker);

      if (isHighPriorityActive &&
          signal.timestamp.difference(_lastUpdatedAt).inMilliseconds.abs() < 5000) {
        return false;
      }
    }

    // 4. Manutenção da presença do harness
    if (signal.phase == HarnessExecutionPhase.closed) {
      _presence = HarnessPresence.detached;
    } else if (_presence == HarnessPresence.none ||
        _presence == HarnessPresence.detached) {
      _presence = HarnessPresence.attached;
    }

    // 5. Rastreamento e transição de atividades
    if (signal.activityId != null) {
      if (signal.phase == HarnessExecutionPhase.completed) {
        _activeActivityIds.remove(signal.activityId);
        _settledActivityIds.add(signal.activityId!);
        if (_settledActivityIds.length > kMaxSettledActivities) {
          _settledActivityIds.remove(_settledActivityIds.first);
        }
        if (_activeActivityId == signal.activityId) {
          _activeActivityId = _activeActivityIds.lastOrNull;
        }
      } else if (signal.phase == HarnessExecutionPhase.running ||
          signal.phase == HarnessExecutionPhase.waitingInput) {
        _activeActivityIds.add(signal.activityId!);
        _activeActivityId = signal.activityId;
      }
    }

    // 6. Atualização de estado consolidado
    if (signal.phase == HarnessExecutionPhase.completed &&
        _activeActivityIds.isNotEmpty) {
      _phase = HarnessExecutionPhase.running;
    } else {
      _phase = signal.phase;
    }
    _lastSource = signal.source;
    _lastUpdatedAt = signal.timestamp;
    if (signal.summary != null && signal.summary!.isNotEmpty) {
      _lastSummary = signal.summary;
    }
    if (signal.sessionId != null) {
      _currentSessionId = signal.sessionId;
    }
    if (signal.turnId != null) {
      _currentTurnId = signal.turnId;
    }

    _hasEverReceivedSignal = true;
    _totalSignalsReceived++;
    _sourceDistribution[signal.source] = (_sourceDistribution[signal.source] ?? 0) + 1;

    return true;
  }

  /// Reinicia ou incrementa o ciclo para uma nova sessão / nova geração do PTY.
  void advanceGeneration({int? nextGeneration, String? newSessionId}) {
    _currentGeneration = nextGeneration ?? (_currentGeneration + 1);
    _currentSessionId = newSessionId ?? _currentSessionId;
    _currentTurnId = null;
    _activeActivityId = null;
    _activeActivityIds.clear();
    _settledActivityIds.clear();
    _phase = HarnessExecutionPhase.idle;
    _presence = HarnessPresence.attached;
    _lastUpdatedAt = DateTime.now();
  }

  /// Desconecta o harness explicitamente (ex.: PTY destruído ou processo morto).
  void detach() {
    _presence = HarnessPresence.detached;
    _phase = HarnessExecutionPhase.closed;
    _activeActivityIds.clear();
    _activeActivityId = null;
    _lastUpdatedAt = DateTime.now();
  }
}
