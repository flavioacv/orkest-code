import 'dart:convert';
import 'dart:typed_data';

/// Informações do servidor retornadas pelo handshake `initialize`.
class RustServerInfo {
  final String version;
  final int protocol;
  final String os;
  final String arch;
  final String home;

  const RustServerInfo({
    required this.version,
    required this.protocol,
    required this.os,
    required this.arch,
    required this.home,
  });

  factory RustServerInfo.fromJson(Map<String, dynamic> json) {
    return RustServerInfo(
      version: json['version'] as String? ?? 'unknown',
      protocol: json['protocol'] as int? ?? 0,
      os: json['os'] as String? ?? 'unknown',
      arch: json['arch'] as String? ?? 'unknown',
      home: json['home'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'protocol': protocol,
        'os': os,
        'arch': arch,
        'home': home,
      };
}

/// Mensagem de erro tipada retornada pelo JSON-RPC do Rust Host.
class RustRpcException implements Exception {
  final int code;
  final String message;
  final dynamic data;

  const RustRpcException({
    required this.code,
    required this.message,
    this.data,
  });

  @override
  String toString() => 'RustRpcException(code: $code, message: $message, data: $data)';
}

/// Status de arquivo retornado pelo comando `vcs_status`.
class RustVcsFileStatus {
  final String path;
  final String status;
  final bool staged;

  const RustVcsFileStatus({
    required this.path,
    required this.status,
    this.staged = false,
  });

  factory RustVcsFileStatus.fromJson(Map<String, dynamic> json) {
    return RustVcsFileStatus(
      path: json['path'] as String? ?? '',
      status: json['status'] as String? ?? 'unknown',
      staged: json['staged'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'path': path,
        'status': status,
        'staged': staged,
      };
}

/// Raiz de repositório retornada pelo comando `vcs_roots`.
class RustVcsRoot {
  final String root;
  final String? operation;
  final String? head;
  final String? headCommit;

  const RustVcsRoot({
    required this.root,
    this.operation,
    this.head,
    this.headCommit,
  });

  factory RustVcsRoot.fromJson(Map<String, dynamic> json) {
    return RustVcsRoot(
      root: json['root'] as String? ?? '',
      operation: json['operation'] as String?,
      head: json['head'] as String?,
      headCommit: json['headCommit'] as String?,
    );
  }
}

/// Configuração de inicialização de sessão DAP (`debug_start`).
class RustDebugLaunchConfig {
  final String name;
  final String adapter;
  final String request;
  final String? program;
  final List<String> args;
  final String? cwd;
  final Map<String, String> env;
  final Map<String, dynamic>? extra;

  const RustDebugLaunchConfig({
    required this.name,
    required this.adapter,
    this.request = 'launch',
    this.program,
    this.args = const [],
    this.cwd,
    this.env = const {},
    this.extra,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'adapter': adapter,
        'request': request,
        if (program != null) 'program': program,
        'args': args,
        if (cwd != null) 'cwd': cwd,
        'env': env,
        if (extra != null) 'extraJson': jsonEncode(extra),
      };
}

/// Breakpoint registrado pelo comando `debug_set_breakpoints`.
class RustSourceBreakpoint {
  final int line;
  final int? column;
  final String? condition;
  final String? hitCondition;
  final String? logMessage;

  const RustSourceBreakpoint({
    required this.line,
    this.column,
    this.condition,
    this.hitCondition,
    this.logMessage,
  });

  Map<String, dynamic> toJson() => {
        'line': line,
        if (column != null) 'column': column,
        if (condition != null) 'condition': condition,
        if (hitCondition != null) 'hitCondition': hitCondition,
        if (logMessage != null) 'logMessage': logMessage,
      };
}

/// Thread de execução retornada por `debug_threads`.
class RustDebugThread {
  final int id;
  final String name;

  const RustDebugThread({required this.id, required this.name});

  factory RustDebugThread.fromJson(Map<String, dynamic> json) {
    return RustDebugThread(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
    );
  }
}

/// Frame de pilha retornado por `debug_stack_trace`.
class RustStackFrame {
  final int id;
  final String name;
  final String? sourcePath;
  final int line;
  final int column;

  const RustStackFrame({
    required this.id,
    required this.name,
    this.sourcePath,
    required this.line,
    required this.column,
  });

  factory RustStackFrame.fromJson(Map<String, dynamic> json) {
    return RustStackFrame(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? '',
      sourcePath: json['source']?['path'] as String?,
      line: json['line'] as int? ?? 0,
      column: json['column'] as int? ?? 0,
    );
  }
}

/// Variável inspecionada retornada por `debug_variables`.
class RustDebugVariable {
  final String name;
  final String value;
  final String? type;
  final int variablesReference;

  const RustDebugVariable({
    required this.name,
    required this.value,
    this.type,
    this.variablesReference = 0,
  });

  factory RustDebugVariable.fromJson(Map<String, dynamic> json) {
    return RustDebugVariable(
      name: json['name'] as String? ?? '',
      value: json['value'] as String? ?? '',
      type: json['type'] as String?,
      variablesReference: json['variablesReference'] as int? ?? 0,
    );
  }
}

/// Utilitário para codificar e decodificar mensagens no formato `Content-Length: <n>\r\n\r\n<json>`.
class RustContentLengthCodec {
  static Uint8List encode(Map<String, dynamic> message) {
    final body = utf8.encode(jsonEncode(message));
    final header = ascii.encode('Content-Length: ${body.length}\r\n\r\n');
    final builder = BytesBuilder(copy: false)
      ..add(header)
      ..add(body);
    return builder.takeBytes();
  }
}
