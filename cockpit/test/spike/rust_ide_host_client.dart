import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'rust_ide_host_protocol.dart';

/// Cliente Dart para comunicação com o processo Rust `openidea-server` ou equivalente via JSON-RPC 2.0 stdio.
class RustIdeHostClient {
  final Stream<List<int>> input;
  final StreamSink<List<int>> output;

  int _nextId = 1;
  int _nextChannelId = 1;

  final Map<int, Completer<dynamic>> _pendingRequests = {};
  final Map<int, void Function(dynamic data)> _activeChannels = {};
  final Map<String, void Function(dynamic event)> _windowEventHandlers = {};

  final BytesBuilder _buffer = BytesBuilder();
  int? _expectedContentLength;
  StreamSubscription<List<int>>? _subscription;
  bool _closed = false;

  RustIdeHostClient({
    required this.input,
    required this.output,
  }) {
    _subscription = input.listen(
      _onData,
      onError: _onError,
      onDone: _onDone,
    );
  }

  bool get isClosed => _closed;

  /// Registra ouvinte para notificações de eventos do servidor por janela (`event`).
  void onWindowEvent(String window, void Function(dynamic event) handler) {
    _windowEventHandlers[window] = handler;
  }

  /// Realiza o handshake `initialize` conforme protocolo OpenIDEA (protocol = 2).
  Future<RustServerInfo> initialize({int protocolVersion = 2}) async {
    final response = await _sendRequest('initialize', {
      'version': protocolVersion,
    });
    return RustServerInfo.fromJson(response as Map<String, dynamic>);
  }

  /// Consulta lista de todos os comandos registrados no Dispatcher do Rust Host.
  Future<List<String>> getCommands() async {
    final response = await _sendRequest('commands', {});
    return (response as List<dynamic>).map((e) => e.toString()).toList();
  }

  /// Abre um projeto no host associando-o a uma janela (`open_project`).
  Future<Map<String, dynamic>> openProject({
    required String window,
    required String path,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'open_project',
      args: {'path': path},
    );
    return response as Map<String, dynamic>? ?? {};
  }

  /// Fecha projeto no host (`close_project`).
  Future<void> closeProject({required String window}) async {
    await invoke(window: window, cmd: 'close_project', args: {});
  }

  /// Obtém status VCS de arquivos do projeto (`vcs_status`).
  Future<List<RustVcsFileStatus>> vcsStatus({required String window}) async {
    final response = await invoke(
      window: window,
      cmd: 'vcs_status',
      args: {},
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((item) => RustVcsFileStatus.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Obtém raízes VCS do projeto (`vcs_roots`).
  Future<List<RustVcsRoot>> vcsRoots({required String window}) async {
    final response = await invoke(
      window: window,
      cmd: 'vcs_roots',
      args: {},
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((item) => RustVcsRoot.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Cancela uma requisição em andamento pelo ID (`cancel_request`).
  Future<void> cancelRequest(int requestId) async {
    await invoke(
      window: '',
      cmd: 'cancel_request',
      args: {'id': requestId},
    );
  }

  /// Inicia uma sessão DAP (`debug_start`).
  Future<String> debugStart({
    required String window,
    required RustDebugLaunchConfig config,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'debug_start',
      args: {'config': config.toJson()},
    );
    return response.toString();
  }

  /// Registra breakpoints para um arquivo em uma sessão DAP (`debug_set_breakpoints`).
  Future<List<dynamic>> debugSetBreakpoints({
    required String window,
    required String path,
    required List<RustSourceBreakpoint> breakpoints,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'debug_set_breakpoints',
      args: {
        'path': path,
        'breakpoints': breakpoints.map((b) => b.toJson()).toList(),
      },
    );
    return response as List<dynamic>? ?? [];
  }

  /// Consulta threads ativas em uma sessão DAP (`debug_threads`).
  Future<List<RustDebugThread>> debugThreads({
    required String window,
    required String session,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'debug_threads',
      args: {'session': session},
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((item) => RustDebugThread.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Inspeciona a pilha de execução de uma thread (`debug_stack_trace`).
  Future<List<RustStackFrame>> debugStackTrace({
    required String window,
    required String session,
    required int threadId,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'debug_stack_trace',
      args: {
        'session': session,
        'threadId': threadId,
      },
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((item) => RustStackFrame.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Inspeciona variáveis em um escopo ou referência (`debug_variables`).
  Future<List<RustDebugVariable>> debugVariables({
    required String window,
    required String session,
    required int reference,
  }) async {
    final response = await invoke(
      window: window,
      cmd: 'debug_variables',
      args: {
        'session': session,
        'reference': reference,
      },
    );
    final list = response as List<dynamic>? ?? [];
    return list.map((item) => RustDebugVariable.fromJson(item as Map<String, dynamic>)).toList();
  }

  /// Avalia uma expressão em um frame (`debug_evaluate`).
  Future<dynamic> debugEvaluate({
    required String window,
    required String session,
    required int frameId,
    required String expression,
  }) async {
    return await invoke(
      window: window,
      cmd: 'debug_evaluate',
      args: {
        'session': session,
        'frameId': frameId,
        'expression': expression,
      },
    );
  }

  /// Continua a execução de uma thread parada (`debug_resume`).
  Future<void> debugResume({
    required String window,
    required String session,
    required int threadId,
  }) async {
    await invoke(
      window: window,
      cmd: 'debug_resume',
      args: {
        'session': session,
        'threadId': threadId,
      },
    );
  }

  /// Pausa a execução de uma thread ativa (`debug_pause`).
  Future<void> debugPause({
    required String window,
    required String session,
    required int threadId,
  }) async {
    await invoke(
      window: window,
      cmd: 'debug_pause',
      args: {
        'session': session,
        'threadId': threadId,
      },
    );
  }

  /// Executa passo (step over, step in, step out) (`debug_step`).
  Future<void> debugStep({
    required String window,
    required String session,
    required int threadId,
    required String kind,
  }) async {
    await invoke(
      window: window,
      cmd: 'debug_step',
      args: {
        'session': session,
        'threadId': threadId,
        'kind': kind,
      },
    );
  }

  /// Encerra a sessão DAP (`debug_stop`).
  Future<void> debugStop({
    required String window,
    required String session,
  }) async {
    await invoke(
      window: window,
      cmd: 'debug_stop',
      args: {'session': session},
    );
  }

  /// Invoca qualquer comando remoto com argumentos e suporte a streaming.
  Future<dynamic> invoke({
    required String window,
    required String cmd,
    required Map<String, dynamic> args,
    void Function(dynamic data)? onStreamingData,
  }) async {
    final processedArgs = Map<String, dynamic>.from(args);
    int? channelId;

    if (onStreamingData != null) {
      channelId = _nextChannelId++;
      _activeChannels[channelId] = onStreamingData;
      processedArgs['onProgress'] = {'\$channel': channelId};
    }

    try {
      return await _sendRequest('invoke', {
        'window': window,
        'cmd': cmd,
        'args': processedArgs,
      });
    } finally {
      if (channelId != null) {
        _activeChannels.remove(channelId);
      }
    }
  }

  Future<dynamic> _sendRequest(String method, Map<String, dynamic> params) {
    if (_closed) {
      throw StateError('RustIdeHostClient já está encerrado.');
    }

    final id = _nextId++;
    final completer = Completer<dynamic>();
    _pendingRequests[id] = completer;

    final message = {
      'jsonrpc': '2.0',
      'id': id,
      'method': method,
      'params': params,
    };

    final bytes = RustContentLengthCodec.encode(message);
    output.add(bytes);

    return completer.future;
  }

  void _onData(List<int> chunk) {
    _buffer.add(chunk);
    _processBuffer();
  }

  void _processBuffer() {
    while (true) {
      if (_expectedContentLength == null) {
        final bytes = _buffer.toBytes();
        final delimiter = _findHeaderDelimiter(bytes);
        if (delimiter == -1) break;

        final headerText = ascii.decode(bytes.sublist(0, delimiter));
        final match = RegExp(r'Content-Length:\s*(\d+)', caseSensitive: false).firstMatch(headerText);
        if (match == null) {
          _buffer.clear();
          throw const RustRpcException(code: -32700, message: 'Header Content-Length inválido');
        }

        _expectedContentLength = int.parse(match.group(1)!);
        final remainingBytes = bytes.sublist(delimiter + 4);
        _buffer.clear();
        _buffer.add(remainingBytes);
      }

      final contentLength = _expectedContentLength!;
      if (_buffer.length < contentLength) break;

      final allBytes = _buffer.toBytes();
      final bodyBytes = allBytes.sublist(0, contentLength);
      final leftoverBytes = allBytes.sublist(contentLength);

      _buffer.clear();
      _buffer.add(leftoverBytes);
      _expectedContentLength = null;

      try {
        final jsonString = utf8.decode(bodyBytes);
        final dynamic decoded = jsonDecode(jsonString);
        if (decoded is Map<String, dynamic>) {
          _dispatchMessage(decoded);
        }
      } catch (e) {
        // Falha de parsing de payload individual
      }
    }
  }

  int _findHeaderDelimiter(Uint8List bytes) {
    for (int i = 0; i < bytes.length - 3; i++) {
      if (bytes[i] == 13 && bytes[i + 1] == 10 && bytes[i + 2] == 13 && bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }

  void _dispatchMessage(Map<String, dynamic> msg) {
    if (msg.containsKey('id') && msg['id'] != null) {
      final id = msg['id'] as int;
      final completer = _pendingRequests.remove(id);
      if (completer != null) {
        if (msg.containsKey('error') && msg['error'] != null) {
          final err = msg['error'];
          completer.completeError(
            RustRpcException(
              code: err['code'] as int? ?? -32603,
              message: err['message']?.toString() ?? 'Erro desconhecido',
              data: err['data'],
            ),
          );
        } else {
          completer.complete(msg['result']);
        }
      }
      return;
    }

    final method = msg['method'] as String?;
    final params = msg['params'];

    if (method == 'channel' && params is Map<String, dynamic>) {
      final channelId = params['id'] as int?;
      final data = params['data'];
      if (channelId != null && _activeChannels.containsKey(channelId)) {
        _activeChannels[channelId]!(data);
      }
    } else if (method == 'event' && params is Map<String, dynamic>) {
      final window = params['window'] as String?;
      final event = params['event'];
      if (window != null && _windowEventHandlers.containsKey(window)) {
        _windowEventHandlers[window]!(event);
      }
    }
  }

  void _onError(Object error) {
    _failPendingRequests(RustRpcException(code: -32000, message: error.toString()));
  }

  void _onDone() {
    _closed = true;
    _failPendingRequests(const RustRpcException(code: -32000, message: 'Conexão encerrada pelo host remoto'));
  }

  void _failPendingRequests(RustRpcException ex) {
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(ex);
      }
    }
    _pendingRequests.clear();
  }

  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    await _subscription?.cancel();
    _failPendingRequests(const RustRpcException(code: -32000, message: 'Cliente encerrado localmente'));
  }
}
