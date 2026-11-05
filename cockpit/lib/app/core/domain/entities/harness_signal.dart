import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart' show TerminalStatus;

/// Presença do processo/agente de harness na sessão de terminal (H01).
enum HarnessPresence {
  /// Nenhum harness ativo ou monitorado (sessão de terminal comum/shell puro).
  none,

  /// Harness anexado, ativo e monitorado na sessão.
  attached,

  /// Harness desvinculado ou processo encerrado.
  detached,
}

/// Fase do ciclo de vida e execução do turno do harness (H01).
enum HarnessExecutionPhase {
  /// Ocioso no prompt do harness, aguardando início de novo turno pelo usuário.
  idle,

  /// Em execução ativa (geração de modelo, raciocínio, ferramentas ou comandos).
  running,

  /// Parado aguardando entrada humana (permissão de ferramenta, confirmação ou escolha).
  waitingInput,

  /// Turno concluído (resposta gerada e finalizada).
  completed,

  /// Sessão do harness encerrada explicitamente (SessionEnd/exit).
  closed,
}

/// Origem do sinal recebido pelo monitor de terminal (H01).
enum HarnessSignalSource {
  /// Sinais estruturados enviados via IPC/socket (orkest activity, hooks).
  structuredHook(100),

  /// Marcadores de comando de PTY/shell (ex.: OSC 133).
  ptyMarker(75),

  /// Ações físicas de entrada do usuário no terminal (Enter, Escape, digitação).
  userInput(50),

  /// Leitura e observação heurística de linhas de texto renderizadas na tela.
  screenObservation(25);

  const HarnessSignalSource(this.precedenceWeight);

  /// Peso de precedência: fontes com maior peso superam fontes de menor peso.
  final int precedenceWeight;
}

/// Sinal unificado de harness emitido por qualquer produtor ou observador (H01).
class HarnessSignal {
  const HarnessSignal({
    required this.source,
    required this.phase,
    required this.timestamp,
    this.activityId,
    this.activityKind,
    this.activityPhase,
    this.summary,
    this.generation = 0,
    this.sessionId,
    this.turnId,
    this.requestId,
  });

  final HarnessSignalSource source;
  final HarnessExecutionPhase phase;
  final DateTime timestamp;
  final String? activityId;
  final String? activityKind;
  final String? activityPhase;
  final String? summary;
  final int generation;
  final String? sessionId;
  final String? turnId;
  final String? requestId;
}

/// Snapshot determinístico do estado do harness na sessão (H01).
class HarnessStateSnapshot {
  const HarnessStateSnapshot({
    required this.presence,
    required this.phase,
    required this.generation,
    this.sessionId,
    this.turnId,
    this.activeActivityId,
    this.lastSummary,
    required this.lastSource,
    required this.lastUpdatedAt,
  });

  final HarnessPresence presence;
  final HarnessExecutionPhase phase;
  final int generation;
  final String? sessionId;
  final String? turnId;
  final String? activeActivityId;
  final String? lastSummary;
  final HarnessSignalSource lastSource;
  final DateTime lastUpdatedAt;

  /// Mapeia o estado formal para o [TerminalStatus] legado do Orkest.
  TerminalStatus get terminalStatus => switch (phase) {
    HarnessExecutionPhase.running => TerminalStatus.working,
    HarnessExecutionPhase.waitingInput => TerminalStatus.waiting,
    HarnessExecutionPhase.idle ||
    HarnessExecutionPhase.completed ||
    HarnessExecutionPhase.closed => TerminalStatus.idle,
  };

  /// `true` se o harness está presente na sessão (mesmo que ocioso).
  bool get isPresent => presence == HarnessPresence.attached;

  /// `true` se há um turno ativo em execução ou em espera de input.
  bool get isTurnActive =>
      phase == HarnessExecutionPhase.running ||
      phase == HarnessExecutionPhase.waitingInput;
}
