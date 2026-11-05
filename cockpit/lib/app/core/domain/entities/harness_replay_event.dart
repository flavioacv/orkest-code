import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

/// Tipo de evento simulado em um cenário de replay do corpus de harness.
enum ReplayEventType {
  /// Emissão de um sinal de harness explícito (hook estruturado, marcador PTY, etc.)
  signal,

  /// Chunk de dados de saída bruta emitido pelo PTY (com possíveis escapes ANSI)
  ptyChunk,

  /// Ação do usuário interativo (teclas, Enter, Ctrl+C)
  userInput,

  /// Evento de reconexão de rede ou restauração de PTY com salto de geração
  reconnect,

  /// Atualização de árvore de processos do sistema operacional (local ou WSL)
  processSnapshot,
}

/// Representa uma transição observada ou esperada de estado do harness.
class HarnessReplayTransition {
  final HarnessPresence presence;
  final HarnessExecutionPhase phase;
  final TerminalStatus terminalStatus;
  final String? activityId;
  final String? summary;

  const HarnessReplayTransition({
    required this.presence,
    required this.phase,
    required this.terminalStatus,
    this.activityId,
    this.summary,
  });

  factory HarnessReplayTransition.fromSnapshot(HarnessStateSnapshot snapshot) {
    return HarnessReplayTransition(
      presence: snapshot.presence,
      phase: snapshot.phase,
      terminalStatus: snapshot.terminalStatus,
      activityId: snapshot.activeActivityId,
      summary: snapshot.lastSummary,
    );
  }

  factory HarnessReplayTransition.fromJson(Map<String, dynamic> json) {
    return HarnessReplayTransition(
      presence: HarnessPresence.values.byName(json['presence'] as String),
      phase: HarnessExecutionPhase.values.byName(json['phase'] as String),
      terminalStatus: TerminalStatus.values.byName(json['terminalStatus'] as String),
      activityId: json['activityId'] as String?,
      summary: json['summary'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'presence': presence.name,
        'phase': phase.name,
        'terminalStatus': terminalStatus.name,
        if (activityId != null) 'activityId': activityId,
        if (summary != null) 'summary': summary,
      };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is HarnessReplayTransition &&
        other.presence == presence &&
        other.phase == phase &&
        other.terminalStatus == terminalStatus &&
        other.activityId == activityId;
  }

  @override
  int get hashCode => Object.hash(presence, phase, terminalStatus, activityId);

  @override
  String toString() =>
      'Transition(presence: ${presence.name}, phase: ${phase.name}, status: ${terminalStatus.name}, activity: $activityId)';
}

/// Evento atômico de uma timeline de gravação de harness.
class HarnessReplayEvent {
  final int offsetMs;
  final ReplayEventType type;
  final HarnessSignal? signal;
  final String? ptyData;
  final int? generation;
  final Map<String, dynamic> metadata;

  const HarnessReplayEvent({
    required this.offsetMs,
    required this.type,
    this.signal,
    this.ptyData,
    this.generation,
    this.metadata = const {},
  });

  factory HarnessReplayEvent.fromJson(Map<String, dynamic> json) {
    final type = ReplayEventType.values.byName(json['type'] as String);
    HarnessSignal? signal;
    if (json['signal'] != null) {
      final sigJson = json['signal'] as Map<String, dynamic>;
      signal = HarnessSignal(
        source: HarnessSignalSource.values.byName(sigJson['source'] as String),
        phase: HarnessExecutionPhase.values.byName(sigJson['phase'] as String),
        timestamp: DateTime.fromMillisecondsSinceEpoch(
            sigJson['timestampMs'] as int? ?? 0),
        activityId: sigJson['activityId'] as String?,
        summary: sigJson['summary'] as String?,
        generation: sigJson['generation'] as int? ?? 0,
      );
    }

    return HarnessReplayEvent(
      offsetMs: json['offsetMs'] as int? ?? 0,
      type: type,
      signal: signal,
      ptyData: json['ptyData'] as String?,
      generation: json['generation'] as int?,
      metadata: (json['metadata'] as Map<String, dynamic>?) ?? const {},
    );
  }

  Map<String, dynamic> toJson() => {
        'offsetMs': offsetMs,
        'type': type.name,
        if (signal != null)
          'signal': {
            'source': signal!.source.name,
            'phase': signal!.phase.name,
            'timestampMs': signal!.timestamp.millisecondsSinceEpoch,
            if (signal!.activityId != null) 'activityId': signal!.activityId,
            if (signal!.summary != null) 'summary': signal!.summary,
            'generation': signal!.generation,
          },
        if (ptyData != null) 'ptyData': ptyData,
        if (generation != null) 'generation': generation,
        if (metadata.isNotEmpty) 'metadata': metadata,
      };
}

/// Cenário gravado completo com metadados e baseline de validação determinística.
class HarnessReplayScenario {
  final String id;
  final String name;
  final String description;
  final List<HarnessReplayEvent> events;
  final List<HarnessReplayTransition> expectedTransitions;

  const HarnessReplayScenario({
    required this.id,
    required this.name,
    required this.description,
    required this.events,
    required this.expectedTransitions,
  });

  factory HarnessReplayScenario.fromJson(Map<String, dynamic> json) {
    return HarnessReplayScenario(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      events: (json['events'] as List<dynamic>)
          .map((e) => HarnessReplayEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      expectedTransitions: (json['expectedTransitions'] as List<dynamic>)
          .map((t) =>
              HarnessReplayTransition.fromJson(t as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'events': events.map((e) => e.toJson()).toList(),
        'expectedTransitions':
            expectedTransitions.map((t) => t.toJson()).toList(),
      };
}
