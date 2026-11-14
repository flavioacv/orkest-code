import 'dart:async';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_codec.dart';

/// Protocol fixture, not a substitute for real language-adapter validation.
class DebugAdapterFixture {
  DebugAdapterFixture({Map<String, dynamic> capabilities = const {}}) {
    this.capabilities.addAll(capabilities);
    const DapCodec().decodeStream(_input.stream).listen(_receive);
  }
  final capabilities = <String, dynamic>{
    'supportsConfigurationDoneRequest': true,
    'supportsTerminateRequest': true,
    'supportsConditionalBreakpoints': true,
    'supportsHitConditionalBreakpoints': true,
    'supportsLogPoints': true,
    'supportsSetVariable': true,
    'exceptionBreakpointFilters': [
      {'filter': 'raised', 'label': 'Raised exceptions'},
      {'filter': 'uncaught', 'label': 'Uncaught exceptions', 'default': true},
    ],
  };
  final _input = StreamController<List<int>>();
  final _output = StreamController<List<int>>.broadcast();
  final requests = <Map<String, dynamic>>[];
  final _reverse = <int, Completer<Map<String, dynamic>>>{};
  int _sequence = 100;
  bool _closed = false;
  FutureOr<Map<String, dynamic>?> Function(String, Map<String, dynamic>)?
  handle;
  DapClient client({String id = 'fixture'}) =>
      DapClient(stdout: _output.stream, stdin: _input.sink, sessionId: id);
  void event(String event, [Map<String, dynamic> body = const {}]) => _send({
    'seq': _sequence++,
    'type': 'event',
    'event': event,
    'body': body,
  });
  Future<Map<String, dynamic>> reverse(
    String command, [
    Map<String, dynamic> args = const {},
  ]) {
    final sequence = _sequence++;
    final response = Completer<Map<String, dynamic>>();
    _reverse[sequence] = response;
    _send({
      'seq': sequence,
      'type': 'request',
      'command': command,
      'arguments': args,
    });
    return response.future.timeout(const Duration(seconds: 3));
  }

  List<Map<String, dynamic>> sent(String command) =>
      requests.where((request) => request['command'] == command).toList();
  void _send(Map<String, dynamic> message) {
    if (!_closed) _output.add(DapCodec.encode(message));
  }

  Future<void> _receive(Map<String, dynamic> message) async {
    if (message['type'] == 'response') {
      _reverse.remove(message['request_seq'])?.complete(message);
      return;
    }
    requests.add(message);
    final command = message['command'] as String;
    final args = (message['arguments'] as Map? ?? const {})
        .cast<String, dynamic>();
    if (command == 'launch' || command == 'attach') event('initialized');
    try {
      final result =
          await handle?.call(command, args) ??
          switch (command) {
            'initialize' => capabilities,
            'threads' => {
              'threads': [
                {'id': 1, 'name': 'main'},
                {'id': 2, 'name': 'worker'},
              ],
            },
            'stackTrace' => {
              'stackFrames': [
                {
                  'id': 10,
                  'name': 'first',
                  'line': 3,
                  'column': 1,
                  'source': {'path': '/repo/main.dart'},
                },
                {
                  'id': 20,
                  'name': 'second',
                  'line': 8,
                  'column': 1,
                  'source': {'path': '/repo/main.dart'},
                },
              ],
            },
            'scopes' => {
              'scopes': [
                {
                  'name': 'Locals',
                  'variablesReference': (args['frameId'] as int) * 10,
                },
              ],
            },
            'variables' => {
              'variables': [
                {
                  'name': 'object',
                  'value': '{}',
                  'variablesReference': args['variablesReference'] == 1000
                      ? 0
                      : 1000,
                },
              ],
            },
            'evaluate' => {
              'result': 'value@${args['frameId']}',
              'variablesReference': 0,
            },
            'setBreakpoints' => {
              'breakpoints': [
                for (final point in args['breakpoints'] as List)
                  {
                    'id': point['line'],
                    'line': point['line'],
                    'verified': true,
                  },
              ],
            },
            _ => <String, dynamic>{},
          };
      _send({
        'seq': _sequence++,
        'type': 'response',
        'request_seq': message['seq'],
        'command': command,
        'success': true,
        'body': result,
      });
    } on Object catch (error) {
      _send({
        'seq': _sequence++,
        'type': 'response',
        'request_seq': message['seq'],
        'command': command,
        'success': false,
        'message': error.toString(),
      });
    }
  }

  Future<void> close() async {
    _closed = true;
    await _input.close();
    await _output.close();
  }
}

Future<void> waitForDebug(bool Function() ready) async {
  final deadline = DateTime.now().add(const Duration(seconds: 3));
  while (!ready()) {
    if (DateTime.now().isAfter(deadline)) {
      throw TimeoutException('debug condition');
    }
    await Future<void>.delayed(const Duration(milliseconds: 2));
  }
}
