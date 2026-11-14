import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'debug_failure.dart';

import 'package:orkest_code/app/core/data/dap/dap_codec.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';

/// Cliente assíncrono para comunicação com um adaptador DAP (Debug Adapter Protocol).
class DapClient {
  DapClient({
    required Stream<List<int>> stdout,
    required this._stdin,
    this._process,
    this.sessionId = 'default-session',
    this.onReverseRequest,
    Stream<String>? diagnostics,
  }) {
    final process = _process;
    if (process != null || diagnostics != null) {
      _stderrSubscription =
          (diagnostics ?? process!.stderr.transform(utf8.decoder)).listen((
            text,
          ) {
            if (!_isClosed) {
              _outputController.add(
                DapOutputEvent(category: 'adapter', output: text),
              );
            }
          }, onError: _handleError);
    }
    _subscription = _codec
        .decodeStream(stdout)
        .listen(_handleMessage, onError: _handleError, onDone: _handleDone);
  }

  /// Cria uma instância conectando-se a um subprocesso adaptador DAP nativo.
  static Future<DapClient> startProcess({
    required String executable,
    List<String> args = const [],
    String? workingDirectory,
    Map<String, String>? environment,
    String sessionId = 'default-session',
  }) async {
    final process = await Process.start(
      executable,
      args,
      workingDirectory: workingDirectory,
      environment: environment,
    );

    return DapClient(
      stdout: process.stdout,
      stdin: process.stdin,
      process: process,
      sessionId: sessionId,
    );
  }

  /// Cria um cliente DapClient a partir de um [Process] já em execução.
  factory DapClient.fromProcess({
    required Process process,
    String sessionId = 'default-session',
  }) {
    return DapClient(
      stdout: process.stdout,
      stdin: process.stdin,
      process: process,
      sessionId: sessionId,
    );
  }

  static Future<DapClient> connectSocket({
    required String host,
    required int port,
    String sessionId = 'socket-session',
    Process? process,
    Stream<String>? diagnostics,
  }) async {
    final socket = await Socket.connect(
      host,
      port,
      timeout: const Duration(seconds: 5),
    );
    return DapClient(
      stdout: socket,
      stdin: socket,
      process: process,
      sessionId: sessionId,
      diagnostics: diagnostics,
    );
  }

  Future<Map<String, dynamic>> Function(
    String command,
    Map<String, dynamic> arguments,
  )?
  onReverseRequest;
  StreamSubscription<String>? _stderrSubscription;
  Object? lastTransportError;
  final StreamSink<List<int>> _stdin;
  final Process? _process;
  final String sessionId;
  final DapCodec _codec = const DapCodec();

  late final StreamSubscription<Map<String, dynamic>> _subscription;
  int _sequence = 1;
  bool _isClosed = false;

  final Map<int, Completer<DapResponse>> _pendingRequests = {};
  final StreamController<DapEvent> _eventsController =
      StreamController<DapEvent>.broadcast();
  final StreamController<DapStoppedEvent> _stoppedController =
      StreamController<DapStoppedEvent>.broadcast();
  final StreamController<DapOutputEvent> _outputController =
      StreamController<DapOutputEvent>.broadcast();

  Stream<DapEvent> get events => _eventsController.stream;
  Stream<DapStoppedEvent> get stoppedEvents => _stoppedController.stream;
  Stream<DapOutputEvent> get outputEvents => _outputController.stream;

  DapCapabilities capabilities = const DapCapabilities();

  /// Envia mensagem customizada e aguarda resposta casada por `request_seq`.
  Future<DapResponse> sendRequest(
    String command, [
    Map<String, dynamic>? arguments,
  ]) {
    if (_isClosed) {
      return Future.error(
        StateError('Não é possível enviar request: cliente DAP já encerrado.'),
      );
    }

    final seq = _sequence++;
    final completer = Completer<DapResponse>();
    _pendingRequests[seq] = completer;

    final request = DapRequest(
      seq: seq,
      command: command,
      arguments: arguments,
    );

    final bytes = DapCodec.encode(request.toJson());
    _stdin.add(bytes);

    return completer.future.timeout(
      command == 'launch' || command == 'attach'
          ? const Duration(minutes: 5)
          : const Duration(seconds: 15),
      onTimeout: () {
        _pendingRequests.remove(seq);
        throw DebugFailure(
          DebugFailureKind.transport,
          'DAP response timeout',
          command: command,
        );
      },
    );
  }

  /// 1. Handshake `initialize`
  Future<DapCapabilities> initialize({
    String clientName = 'Orkest Code',
    String adapterID = 'orkest-dap',
  }) async {
    final response = await sendRequest('initialize', {
      'clientID': 'orkest-code',
      'clientName': clientName,
      'adapterID': adapterID,
      'pathFormat': 'path',
      'linesStartAt1': true,
      'columnsStartAt1': true,
      'supportsVariableType': true,
      'supportsRunInTerminalRequest': onReverseRequest != null,
    });

    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: 'initialize',
      );
    }
    if (response.body != null) {
      capabilities = DapCapabilities.fromJson(response.body);
    }
    return capabilities;
  }

  /// 2. Launch
  Future<DapResponse> launch({
    required String program,
    List<String> args = const [],
    String? cwd,
    Map<String, dynamic>? env,
    bool noDebug = false,
  }) {
    return sendRequest('launch', {
      'program': program,
      'args': args,
      'cwd': ?cwd,
      'env': ?env,
      'noDebug': noDebug,
    });
  }

  /// 2b. Attach
  Future<DapResponse> attach(Map<String, dynamic> arguments) {
    return sendRequest('attach', arguments);
  }

  /// 3. SetBreakpoints
  Future<List<DapBreakpoint>> setBreakpoints({
    required String sourcePath,
    required List<SourceBreakpoint> breakpoints,
  }) async {
    final response = await sendRequest('setBreakpoints', {
      'source': {'path': sourcePath},
      'breakpoints': breakpoints.map((b) => b.toJson()).toList(),
    });

    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      final rawList = response.body!['breakpoints'];
      if (rawList is List) {
        return rawList
            .map((b) => DapBreakpoint.fromJson(b as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

  /// 4. ConfigurationDone
  Future<DapResponse> configurationDone() {
    return sendRequest('configurationDone');
  }

  /// Pause
  Future<DapResponse> pause(int threadId) {
    return sendRequest('pause', {'threadId': threadId});
  }

  /// Continue (Resume)
  Future<DapResponse> resume(int threadId) {
    return sendRequest('continue', {'threadId': threadId});
  }

  /// Step Over (Next)
  Future<DapResponse> stepOver(int threadId) {
    return sendRequest('next', {'threadId': threadId});
  }

  /// Step In
  Future<DapResponse> stepIn(int threadId) {
    return sendRequest('stepIn', {'threadId': threadId});
  }

  /// Step Out
  Future<DapResponse> stepOut(int threadId) {
    return sendRequest('stepOut', {'threadId': threadId});
  }

  /// Threads
  Future<List<DapThread>> threads() async {
    final response = await sendRequest('threads');
    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      final rawList = response.body!['threads'];
      if (rawList is List) {
        return rawList
            .map((t) => DapThread.fromJson(t as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

  /// StackTrace
  Future<List<DapStackFrame>> stackTrace(
    int threadId, {
    int startFrame = 0,
    int levels = 20,
  }) async {
    final response = await sendRequest('stackTrace', {
      'threadId': threadId,
      'startFrame': startFrame,
      'levels': levels,
    });

    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      final rawList = response.body!['stackFrames'];
      if (rawList is List) {
        return rawList
            .map((f) => DapStackFrame.fromJson(f as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

  /// Scopes
  Future<List<DapScope>> scopes(int frameId) async {
    final response = await sendRequest('scopes', {'frameId': frameId});
    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      final rawList = response.body!['scopes'];
      if (rawList is List) {
        return rawList
            .map((s) => DapScope.fromJson(s as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

  /// Variables
  Future<List<DapVariable>> variables(int variablesReference) async {
    final response = await sendRequest('variables', {
      'variablesReference': variablesReference,
    });
    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      final rawList = response.body!['variables'];
      if (rawList is List) {
        return rawList
            .map((v) => DapVariable.fromJson(v as Map<String, dynamic>))
            .toList();
      }
    }
    return const [];
  }

  /// Evaluate
  Future<DapEvaluateResult?> evaluate(
    String expression, {
    int? frameId,
    String? context,
  }) async {
    final response = await sendRequest('evaluate', {
      'expression': expression,
      'frameId': ?frameId,
      'context': ?context,
    });

    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
    if (response.success && response.body != null) {
      return DapEvaluateResult.fromJson(response.body!);
    }
    return null;
  }

  /// Configura filtros de interrupção em exceções (`None`, `All`, `Unhandled`).
  Future<DapResponse> setExceptionBreakpoints(List<String> filters) {
    return sendRequest('setExceptionBreakpoints', {'filters': filters});
  }

  /// Dispara Hot Reload no processo em depuração (requisição customizada Flutter DAP).
  Future<DapResponse> hotReload({String reason = 'manual'}) {
    return sendRequest('hotReload', {'reason': reason});
  }

  /// Dispara Hot Restart no processo em depuração (requisição customizada Flutter DAP).
  Future<DapResponse> hotRestart({String reason = 'manual'}) {
    return sendRequest('hotRestart', {'reason': reason});
  }

  /// Disconnect / Terminate
  Future<void> disconnect({
    bool restart = false,
    bool terminateDebuggee = true,
  }) async {
    try {
      if (!_isClosed) {
        if (terminateDebuggee && capabilities.supportsTerminateRequest) {
          await sendRequest('terminate', {'restart': restart}).timeout(
            const Duration(milliseconds: 1500),
            onTimeout: () => const DapResponse(
              seq: 0,
              requestSeq: 0,
              success: false,
              command: 'terminate',
            ),
          );
        }
        await sendRequest('disconnect', {
          'restart': restart,
          'terminateDebuggee': terminateDebuggee,
        }).timeout(
          const Duration(milliseconds: 1500),
          onTimeout: () => const DapResponse(
            seq: 0,
            requestSeq: 0,
            success: false,
            command: 'disconnect',
          ),
        );
      }
    } catch (_) {}
    await close();
  }

  /// Encerra recursos e subprocesso associado.
  Future<void> close() async {
    if (_isClosed) return;
    _isClosed = true;

    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('Sessão DAP encerrada.'));
      }
    }
    _pendingRequests.clear();

    await _subscription.cancel();
    await _stderrSubscription?.cancel();
    try {
      await _stdin.close().timeout(const Duration(seconds: 1));
    } on Object catch (error) {
      lastTransportError = error;
    }
    await _eventsController.close();
    await _stoppedController.close();
    await _outputController.close();

    try {
      _process?.kill(ProcessSignal.sigkill);
    } catch (_) {}
  }

  void _handleMessage(Map<String, dynamic> json) {
    final type = json['type'] as String?;

    if (type == 'request') {
      unawaited(_handleReverseRequest(json));
    } else if (type == 'response') {
      final response = DapResponse.fromJson(json);
      final completer = _pendingRequests.remove(response.requestSeq);
      if (completer != null && !completer.isCompleted) {
        completer.complete(response);
      }
    } else if (type == 'event') {
      final event = DapEvent.fromJson(json);
      if (event.event == 'capabilities' && event.body?['capabilities'] is Map) {
        capabilities = DapCapabilities.fromJson({
          ...capabilities.toJson(),
          ...(event.body!['capabilities'] as Map).cast<String, dynamic>(),
        });
      }
      _eventsController.add(event);

      if (event.event == 'stopped' && event.body != null) {
        _stoppedController.add(DapStoppedEvent.fromJson(event.body!));
      } else if (event.event == 'output' && event.body != null) {
        _outputController.add(DapOutputEvent.fromJson(event.body!));
      }
    }
  }

  Future<void> _handleReverseRequest(Map<String, dynamic> json) async {
    final command = json['command'] as String? ?? '';
    final handler = onReverseRequest;
    var success = false;
    Map<String, dynamic>? body;
    String? message;
    try {
      if (handler == null) throw UnsupportedError(command);
      body = await handler(
        command,
        (json['arguments'] as Map? ?? const {}).cast<String, dynamic>(),
      ).timeout(const Duration(seconds: 30));
      success = true;
    } on Object catch (error) {
      message = error.toString();
    }
    if (!_isClosed) {
      _stdin.add(
        DapCodec.encode({
          'seq': _sequence++,
          'type': 'response',
          'request_seq': json['seq'],
          'command': command,
          'success': success,
          'body': ?body,
          'message': ?message,
        }),
      );
    }
  }

  Future<DapResponse> restartFrame(int frameId) =>
      sendRequest('restartFrame', {'frameId': frameId});
  Future<DapResponse> restart() => sendRequest('restart');
  Future<DapResponse> setVariable(int reference, String name, String value) =>
      sendRequest('setVariable', {
        'variablesReference': reference,
        'name': name,
        'value': value,
      });

  void _handleError(Object error) {
    lastTransportError = error;
    for (final completer in _pendingRequests.values) {
      if (!completer.isCompleted) completer.completeError(error);
    }
    _pendingRequests.clear();
  }

  void _handleDone() {
    close();
  }
}
