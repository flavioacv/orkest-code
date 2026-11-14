/// Estados do ciclo de vida de uma sessão de depuração DAP.
enum DapSessionState {
  /// Sessão ainda não inicializada ou finalizada.
  idle,

  /// Handshake de inicialização (`initialize`, `launch`/`attach`) em andamento.
  initializing,

  /// Aplicação alvo em execução contínua.
  running,

  /// Aplicação alvo pausada (em breakpoint, exception, step ou pause manual).
  stopped,

  /// Sessão sendo finalizada.
  terminating,
}

/// Razão pela qual a execução foi interrompida no evento `stopped`.
enum DapStopReason { breakpoint, step, pause, exception, entry, goto, unknown }

/// Mensagem base do protocolo Debug Adapter Protocol (DAP).
sealed class DapMessage {
  const DapMessage({required this.seq, required this.type});

  final int seq;
  final String type;

  Map<String, dynamic> toJson();
}

/// Mensagem de requisição enviada do cliente para o adaptador DAP.
class DapRequest extends DapMessage {
  const DapRequest({required super.seq, required this.command, this.arguments})
    : super(type: 'request');

  final String command;
  final Map<String, dynamic>? arguments;

  @override
  Map<String, dynamic> toJson() => {
    'seq': seq,
    'type': type,
    'command': command,
    if (arguments != null) 'arguments': arguments,
  };
}

/// Mensagem de resposta enviada do adaptador DAP para o cliente.
class DapResponse extends DapMessage {
  const DapResponse({
    required super.seq,
    required this.requestSeq,
    required this.success,
    required this.command,
    this.message,
    this.body,
  }) : super(type: 'response');

  final int requestSeq;
  final bool success;
  final String command;
  final String? message;
  final Map<String, dynamic>? body;

  factory DapResponse.fromJson(Map<String, dynamic> json) {
    return DapResponse(
      seq: json['seq'] as int? ?? 0,
      requestSeq: json['request_seq'] as int? ?? 0,
      success: json['success'] as bool? ?? false,
      command: json['command'] as String? ?? '',
      message: json['message'] as String?,
      body: json['body'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'seq': seq,
    'type': type,
    'request_seq': requestSeq,
    'success': success,
    'command': command,
    if (message != null) 'message': message,
    if (body != null) 'body': body,
  };
}

/// Evento assíncrono emitido pelo adaptador DAP.
class DapEvent extends DapMessage {
  const DapEvent({required super.seq, required this.event, this.body})
    : super(type: 'event');

  final String event;
  final Map<String, dynamic>? body;

  factory DapEvent.fromJson(Map<String, dynamic> json) {
    return DapEvent(
      seq: json['seq'] as int? ?? 0,
      event: json['event'] as String? ?? '',
      body: json['body'] as Map<String, dynamic>?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'seq': seq,
    'type': type,
    'event': event,
    if (body != null) 'body': body,
  };
}

/// Capacidades retornadas pelo adaptador no handshake `initialize`.
class DapCapabilities {
  const DapCapabilities({
    this.supportsConfigurationDoneRequest = false,
    this.supportsFunctionBreakpoints = false,
    this.supportsConditionalBreakpoints = false,
    this.supportsHitConditionalBreakpoints = false,
    this.supportsEvaluateForHovers = false,
    this.supportsStepBack = false,
    this.supportsRestartFrame = false,
    this.supportsTerminateRequest = false,
    this.supportsRestartRequest = false,
    this.supportsLogPoints = false,
    this.supportsSetVariable = false,
    this.exceptionBreakpointFilters = const [],
  });

  final bool supportsConfigurationDoneRequest;
  final bool supportsFunctionBreakpoints;
  final bool supportsConditionalBreakpoints;
  final bool supportsHitConditionalBreakpoints;
  final bool supportsEvaluateForHovers;
  final bool supportsStepBack;
  final bool supportsRestartFrame;
  final bool supportsTerminateRequest;
  final bool supportsRestartRequest;
  final bool supportsLogPoints;
  final bool supportsSetVariable;
  final List<DapExceptionFilter> exceptionBreakpointFilters;

  Map<String, dynamic> toJson() => {
    'supportsConfigurationDoneRequest': supportsConfigurationDoneRequest,
    'supportsFunctionBreakpoints': supportsFunctionBreakpoints,
    'supportsConditionalBreakpoints': supportsConditionalBreakpoints,
    'supportsHitConditionalBreakpoints': supportsHitConditionalBreakpoints,
    'supportsEvaluateForHovers': supportsEvaluateForHovers,
    'supportsStepBack': supportsStepBack,
    'supportsRestartFrame': supportsRestartFrame,
    'supportsTerminateRequest': supportsTerminateRequest,
    'supportsRestartRequest': supportsRestartRequest,
    'supportsLogPoints': supportsLogPoints,
    'supportsSetVariable': supportsSetVariable,
    'exceptionBreakpointFilters': [
      for (final f in exceptionBreakpointFilters)
        {
          'filter': f.id,
          'label': f.label,
          'default': f.defaultEnabled,
          if (f.description != null) 'description': f.description,
        },
    ],
  };

  factory DapCapabilities.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DapCapabilities();
    return DapCapabilities(
      supportsConfigurationDoneRequest:
          json['supportsConfigurationDoneRequest'] as bool? ?? false,
      supportsFunctionBreakpoints:
          json['supportsFunctionBreakpoints'] as bool? ?? false,
      supportsConditionalBreakpoints:
          json['supportsConditionalBreakpoints'] as bool? ?? false,
      supportsHitConditionalBreakpoints:
          json['supportsHitConditionalBreakpoints'] as bool? ?? false,
      supportsEvaluateForHovers:
          json['supportsEvaluateForHovers'] as bool? ?? false,
      supportsStepBack: json['supportsStepBack'] as bool? ?? false,
      supportsRestartFrame: json['supportsRestartFrame'] as bool? ?? false,
      supportsTerminateRequest:
          json['supportsTerminateRequest'] as bool? ?? false,
      supportsRestartRequest: json['supportsRestartRequest'] as bool? ?? false,
      supportsLogPoints: json['supportsLogPoints'] as bool? ?? false,
      supportsSetVariable: json['supportsSetVariable'] as bool? ?? false,
      exceptionBreakpointFilters:
          (json['exceptionBreakpointFilters'] as List? ?? const [])
              .whereType<Map>()
              .map(
                (raw) =>
                    DapExceptionFilter.fromJson(raw.cast<String, dynamic>()),
              )
              .toList(),
    );
  }
}

/// Definição de um breakpoint no código-fonte enviado ao adaptador.
class SourceBreakpoint {
  const SourceBreakpoint({
    required this.line,
    this.column,
    this.condition,
    this.hitCondition,
    this.logMessage,
    this.enabled = true,
  });

  final int line;
  final int? column;
  final String? condition;
  final String? hitCondition;
  final String? logMessage;
  final bool enabled;
  SourceBreakpoint copyWith({bool? enabled}) => SourceBreakpoint(
    line: line,
    column: column,
    condition: condition,
    hitCondition: hitCondition,
    logMessage: logMessage,
    enabled: enabled ?? this.enabled,
  );
  Map<String, dynamic> toState() => {...toJson(), 'enabled': enabled};
  static SourceBreakpoint? fromState(Object? value) {
    if (value is! Map || value['line'] is! int || (value['line'] as int) < 1) {
      return null;
    }
    return SourceBreakpoint(
      line: value['line'] as int,
      column: value['column'] is int ? value['column'] as int : null,
      condition: value['condition'] is String
          ? value['condition'] as String
          : null,
      hitCondition: value['hitCondition'] is String
          ? value['hitCondition'] as String
          : null,
      logMessage: value['logMessage'] is String
          ? value['logMessage'] as String
          : null,
      enabled: value['enabled'] != false,
    );
  }

  Map<String, dynamic> toJson() => {
    'line': line,
    if (column != null) 'column': column,
    if (condition != null) 'condition': condition,
    if (hitCondition != null) 'hitCondition': hitCondition,
    if (logMessage != null) 'logMessage': logMessage,
  };
}

/// Breakpoint verificado ou rejeitado retornado pelo adaptador DAP.
class DapBreakpoint {
  const DapBreakpoint({
    this.id,
    required this.verified,
    this.line,
    this.column,
    this.message,
    this.sourcePath,
  });

  final int? id;
  final bool verified;
  final int? line;
  final int? column;
  final String? message;
  final String? sourcePath;

  factory DapBreakpoint.fromJson(Map<String, dynamic> json) {
    return DapBreakpoint(
      id: json['id'] as int?,
      verified: json['verified'] as bool? ?? false,
      line: json['line'] as int?,
      column: json['column'] as int?,
      message: json['message'] as String?,
      sourcePath: json['source']?['path'] as String?,
    );
  }
}

/// Thread de execução.
class DapThread {
  const DapThread({required this.id, required this.name});

  final int id;
  final String name;

  factory DapThread.fromJson(Map<String, dynamic> json) {
    return DapThread(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Thread ${json['id']}',
    );
  }
}

/// Frame individual da pilha de chamadas (Call Stack).
class DapStackFrame {
  const DapStackFrame({
    required this.id,
    required this.name,
    this.sourcePath,
    required this.line,
    required this.column,
  });

  final int id;
  final String name;
  final String? sourcePath;
  final int line;
  final int column;

  factory DapStackFrame.fromJson(Map<String, dynamic> json) {
    return DapStackFrame(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'frame',
      sourcePath: json['source']?['path'] as String?,
      line: json['line'] as int? ?? 0,
      column: json['column'] as int? ?? 0,
    );
  }
}

/// Escopo de variáveis (ex: Local, Global, Closure).
class DapScope {
  const DapScope({
    required this.name,
    required this.variablesReference,
    this.expensive = false,
  });

  final String name;
  final int variablesReference;
  final bool expensive;

  factory DapScope.fromJson(Map<String, dynamic> json) {
    return DapScope(
      name: json['name'] as String? ?? '',
      variablesReference: json['variablesReference'] as int? ?? 0,
      expensive: json['expensive'] as bool? ?? false,
    );
  }
}

/// Variável inspecionada.
class DapVariable {
  const DapVariable({
    required this.name,
    required this.value,
    this.type,
    this.variablesReference = 0,
    this.evaluateName,
  });

  final String name;
  final String value;
  final String? type;
  final int variablesReference;
  final String? evaluateName;

  factory DapVariable.fromJson(Map<String, dynamic> json) {
    return DapVariable(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String?,
      variablesReference: json['variablesReference'] as int? ?? 0,
      evaluateName: json['evaluateName'] as String?,
    );
  }
}

/// Evento emitido quando a execução é interrompida (breakpoint, step, etc).
class DapStoppedEvent {
  const DapStoppedEvent({
    required this.reason,
    this.threadId,
    this.text,
    this.description,
    this.allThreadsStopped = false,
  });

  final DapStopReason reason;
  final int? threadId;
  final String? text;
  final String? description;
  final bool allThreadsStopped;

  factory DapStoppedEvent.fromJson(Map<String, dynamic> json) {
    final rawReason = (json['reason'] as String?)?.toLowerCase();
    final reason = switch (rawReason) {
      'breakpoint' => DapStopReason.breakpoint,
      'step' => DapStopReason.step,
      'pause' => DapStopReason.pause,
      'exception' => DapStopReason.exception,
      'entry' => DapStopReason.entry,
      'goto' => DapStopReason.goto,
      _ => DapStopReason.unknown,
    };

    return DapStoppedEvent(
      reason: reason,
      threadId: json['threadId'] as int?,
      text: json['text'] as String?,
      description: json['description'] as String?,
      allThreadsStopped: json['allThreadsStopped'] as bool? ?? false,
    );
  }
}

/// Evento de saída de console emitido pelo adaptador (`output`).
class DapOutputEvent {
  const DapOutputEvent({
    required this.category,
    required this.output,
    this.variablesReference,
  });

  final String category;
  final String output;
  final int? variablesReference;

  factory DapOutputEvent.fromJson(Map<String, dynamic> json) {
    return DapOutputEvent(
      category: json['category'] as String? ?? 'console',
      output: json['output'] as String? ?? '',
      variablesReference: json['variablesReference'] as int?,
    );
  }
}

/// Resultado de uma avaliação de expressão (`evaluate`).
class DapEvaluateResult {
  const DapEvaluateResult({
    required this.result,
    this.type,
    this.variablesReference = 0,
  });

  final String result;
  final String? type;
  final int variablesReference;

  factory DapEvaluateResult.fromJson(Map<String, dynamic> json) {
    return DapEvaluateResult(
      result: json['result'] as String? ?? '',
      type: json['type'] as String?,
      variablesReference: json['variablesReference'] as int? ?? 0,
    );
  }
}

class DapExceptionFilter {
  const DapExceptionFilter({
    required this.id,
    required this.label,
    this.defaultEnabled = false,
    this.description,
  });
  final String id;
  final String label;
  final bool defaultEnabled;
  final String? description;
  factory DapExceptionFilter.fromJson(Map<String, dynamic> json) =>
      DapExceptionFilter(
        id: json['filter'] as String? ?? '',
        label: json['label'] as String? ?? '',
        defaultEnabled: json['default'] == true,
        description: json['description'] as String?,
      );
}
