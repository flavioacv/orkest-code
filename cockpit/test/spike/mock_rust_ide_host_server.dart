import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'rust_ide_host_protocol.dart';

/// Servidor mock que emula o comportamento do `openidea-server` (Rust) sobre stdio para os testes de spike.
class MockRustIdeHostServer {
  final StreamController<List<int>> _inputController = StreamController<List<int>>();
  final StreamController<List<int>> _outputController = StreamController<List<int>>();

  final BytesBuilder _buffer = BytesBuilder();
  int? _expectedContentLength;

  bool _crashOnNextRequest = false;
  final Set<int> _cancelledRequests = {};
  int _activeDebugSessions = 0;

  MockRustIdeHostServer() {
    _inputController.stream.listen(_onData);
  }

  StreamSink<List<int>> get sink => _inputController.sink;
  Stream<List<int>> get stream => _outputController.stream;

  void triggerCrash() {
    _crashOnNextRequest = true;
  }

  void close() {
    _inputController.close();
    _outputController.close();
  }

  void emitEvent({required String window, required Map<String, dynamic> event}) {
    final notification = {
      'jsonrpc': '2.0',
      'method': 'event',
      'params': {
        'window': window,
        'event': event,
      },
    };
    _outputController.add(RustContentLengthCodec.encode(notification));
  }

  void emitChannelData({required int channelId, required dynamic data}) {
    final notification = {
      'jsonrpc': '2.0',
      'method': 'channel',
      'params': {
        'id': channelId,
        'data': data,
      },
    };
    _outputController.add(RustContentLengthCodec.encode(notification));
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
          return;
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
          _handleMessage(decoded);
        }
      } catch (_) {}
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

  void _handleMessage(Map<String, dynamic> msg) {
    final id = msg['id'] as int?;
    if (id == null) return;

    if (_crashOnNextRequest) {
      _crashOnNextRequest = false;
      _outputController.close();
      return;
    }

    final method = msg['method'] as String?;
    final params = msg['params'] as Map<String, dynamic>? ?? {};

    if (method == 'initialize') {
      _sendReply(id, {
        'version': '0.1.36',
        'protocol': 2,
        'os': 'macos',
        'arch': 'aarch64',
        'home': '/Users/developer',
      });
      return;
    }

    if (method == 'commands') {
      _sendReply(id, [
        'open_project',
        'close_project',
        'project_current',
        'project_roots',
        'cancel_request',
        'cancel_task',
        'vcs_status',
        'vcs_roots',
        'vcs_diff',
        'vcs_diff_with_worktree',
        'vcs_stage_hunks',
        'debug_start',
        'debug_set_breakpoints',
        'debug_threads',
        'debug_stack_trace',
        'debug_scopes',
        'debug_variables',
        'debug_evaluate',
        'debug_resume',
        'debug_pause',
        'debug_step',
        'debug_stop',
      ]);
      return;
    }

    if (method == 'invoke') {
      final cmd = params['cmd'] as String?;
      final args = params['args'] as Map<String, dynamic>? ?? {};
      _handleInvoke(id, cmd, args);
      return;
    }

    _sendError(id, -32601, 'Method not found: $method');
  }

  void _handleInvoke(int id, String? cmd, Map<String, dynamic> args) {
    switch (cmd) {
      case 'open_project':
        final path = args['path'] as String? ?? '/mock/project';
        _sendReply(id, {
          'root': path,
          'name': path.split('/').last,
          'trusted': true,
        });
        break;

      case 'close_project':
        _sendReply(id, null);
        break;

      case 'cancel_request':
        final targetId = args['id'] as int? ?? 0;
        _cancelledRequests.add(targetId);
        _sendReply(id, null);
        break;

      case 'vcs_status':
        _sendReply(id, [
          {'path': 'lib/main.dart', 'status': 'modified', 'staged': false},
          {'path': 'pubspec.yaml', 'status': 'modified', 'staged': true},
          {'path': 'test/new_test.dart', 'status': 'untracked', 'staged': false},
        ]);
        break;

      case 'vcs_roots':
        _sendReply(id, [
          {
            'root': '/mock/project',
            'operation': null,
            'head': 'fix/harness-state-detection',
            'headCommit': '3809c4d7',
          }
        ]);
        break;

      case 'debug_start':
        _activeDebugSessions++;
        final sessionId = 'debug-session-$_activeDebugSessions';
        _sendReply(id, sessionId);
        break;

      case 'debug_set_breakpoints':
        final breakpoints = args['breakpoints'] as List<dynamic>? ?? [];
        _sendReply(
          id,
          breakpoints.map((b) => {'verified': true, 'line': b['line']}).toList(),
        );
        break;

      case 'debug_threads':
        _sendReply(id, [
          {'id': 1, 'name': 'main'},
          {'id': 2, 'name': 'worker-io'},
        ]);
        break;

      case 'debug_stack_trace':
        _sendReply(id, [
          {
            'id': 100,
            'name': 'main()',
            'source': {'path': 'lib/main.dart'},
            'line': 42,
            'column': 12,
          },
          {
            'id': 101,
            'name': 'runApp()',
            'source': {'path': 'packages/flutter/lib/src/widgets/binding.dart'},
            'line': 150,
            'column': 8,
          }
        ]);
        break;

      case 'debug_variables':
        _sendReply(id, [
          {'name': 'status', 'value': '"connected"', 'type': 'String', 'variablesReference': 0},
          {'name': 'count', 'value': '42', 'type': 'int', 'variablesReference': 0},
        ]);
        break;

      case 'debug_evaluate':
        final expr = args['expression'] as String? ?? '';
        _sendReply(id, {'result': 'Evaluation of $expr: ok', 'type': 'String'});
        break;

      case 'debug_resume':
      case 'debug_pause':
      case 'debug_step':
        _sendReply(id, null);
        break;

      case 'debug_stop':
        _activeDebugSessions = (_activeDebugSessions > 0) ? _activeDebugSessions - 1 : 0;
        _sendReply(id, null);
        break;

      default:
        _sendError(id, -32601, 'Command not available: $cmd');
        break;
    }
  }

  void _sendReply(int id, dynamic result) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'result': result,
    };
    _outputController.add(RustContentLengthCodec.encode(response));
  }

  void _sendError(int id, int code, String message) {
    final response = {
      'jsonrpc': '2.0',
      'id': id,
      'error': {
        'code': code,
        'message': message,
      },
    };
    _outputController.add(RustContentLengthCodec.encode(response));
  }
}
