import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_codec.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';

/// Emulador mock do adaptador DAP para testes unitários determinísticos.
class MockDapAdapterServer {
  final StreamController<List<int>> _input = StreamController<List<int>>();
  final StreamController<List<int>> _output = StreamController<List<int>>();

  MockDapAdapterServer() {
    const DapCodec().decodeStream(_input.stream).listen(_handleRequest);
  }

  StreamSink<List<int>> get sink => _input.sink;
  Stream<List<int>> get stream => _output.stream;

  void emitEvent(String event, [Map<String, dynamic>? body]) {
    final msg = DapEvent(seq: 999, event: event, body: body).toJson();
    _output.add(DapCodec.encode(msg));
  }

  void _handleRequest(Map<String, dynamic> req) {
    final command = req['command'] as String;
    final seq = req['seq'] as int;
    if (command == 'launch' || command == 'attach') {
      _output.add(
        DapCodec.encode({'seq': 998, 'type': 'event', 'event': 'initialized'}),
      );
    }

    final body = <String, dynamic>{};
    switch (command) {
      case 'initialize':
        body['supportsConfigurationDoneRequest'] = true;
        body['supportsTerminateRequest'] = true;
        body['supportsFunctionBreakpoints'] = true;
        break;
      case 'setBreakpoints':
        final rawArgs = req['arguments'] as Map<String, dynamic>?;
        final rawBps = rawArgs?['breakpoints'] as List? ?? [];
        body['breakpoints'] = [
          for (var i = 0; i < rawBps.length; i++)
            {'id': i + 1, 'verified': true, 'line': rawBps[i]['line']},
        ];
        break;
      case 'threads':
        body['threads'] = [
          {'id': 1, 'name': 'main.dart'},
        ];
        break;
      case 'stackTrace':
        body['stackFrames'] = [
          {
            'id': 10,
            'name': 'calculate',
            'line': 42,
            'column': 8,
            'source': {'path': '/project/lib/math.dart'},
          },
        ];
        break;
      case 'scopes':
        body['scopes'] = [
          {'name': 'Locals', 'variablesReference': 200, 'expensive': false},
        ];
        break;
      case 'variables':
        body['variables'] = [
          {
            'name': 'counter',
            'value': '42',
            'type': 'int',
            'variablesReference': 0,
          },
        ];
        break;
      case 'evaluate':
        body['result'] = '84';
        body['type'] = 'int';
        break;
    }

    final resp = DapResponse(
      seq: seq + 100,
      requestSeq: seq,
      success: true,
      command: command,
      body: body.isNotEmpty ? body : null,
    ).toJson();

    _output.add(DapCodec.encode(resp));
  }

  Future<void> close() async {
    await _input.close();
    await _output.close();
  }
}

void main() {
  group('DapCodec', () {
    test('codifica mensagem JSON com Content-Length correto', () {
      final msg = {'seq': 1, 'type': 'request', 'command': 'initialize'};
      final bytes = DapCodec.encode(msg);
      final text = ascii.decode(bytes);

      final jsonPart = jsonEncode(msg);
      final expectedHeader =
          'Content-Length: ${utf8.encode(jsonPart).length}\r\n\r\n';
      expect(text.startsWith(expectedHeader), isTrue);
      expect(text.endsWith(jsonPart), isTrue);
    });

    test('decodifica mensagens em chunks fragmentados e contínuos', () async {
      const codec = DapCodec();
      final controller = StreamController<List<int>>();

      final msg1 = {
        'seq': 1,
        'type': 'response',
        'command': 'initialize',
        'success': true,
      };
      final msg2 = {
        'seq': 2,
        'type': 'event',
        'event': 'stopped',
        'body': {'reason': 'breakpoint'},
      };

      final encoded1 = DapCodec.encode(msg1);
      final encoded2 = DapCodec.encode(msg2);

      final results = <Map<String, dynamic>>[];
      final sub = codec.decodeStream(controller.stream).listen(results.add);

      // Envia primeira mensagem em duas partes
      final mid1 = encoded1.length ~/ 2;
      controller.add(encoded1.sublist(0, mid1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(results, isEmpty);

      controller.add(encoded1.sublist(mid1));
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(results.length, equals(1));
      expect(results[0]['command'], equals('initialize'));

      // Envia segunda mensagem inteira
      controller.add(encoded2);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      expect(results.length, equals(2));
      expect(results[1]['event'], equals('stopped'));

      await sub.cancel();
      await controller.close();
    });
  });

  group('DapClient & Protocol Lifecycle', () {
    late MockDapAdapterServer server;
    late DapClient client;

    setUp(() {
      server = MockDapAdapterServer();
      client = DapClient(
        stdout: server.stream,
        stdin: server.sink,
        sessionId: 'session-42',
      );
    });

    tearDown(() async {
      await client.close();
      await server.close();
    });

    test('executa handshake initialize e armazena capabilities', () async {
      final caps = await client.initialize();
      expect(caps.supportsConfigurationDoneRequest, isTrue);
      expect(caps.supportsFunctionBreakpoints, isTrue);
      expect(caps.supportsTerminateRequest, isTrue);
      expect(caps.supportsStepBack, isFalse);
    });

    test('configura breakpoints e recebe verificação', () async {
      final bps = await client.setBreakpoints(
        sourcePath: '/project/lib/main.dart',
        breakpoints: const [
          SourceBreakpoint(line: 10),
          SourceBreakpoint(line: 25),
        ],
      );

      expect(bps.length, equals(2));
      expect(bps[0].verified, isTrue);
      expect(bps[0].line, equals(10));
      expect(bps[1].verified, isTrue);
      expect(bps[1].line, equals(25));
    });

    test(
      'executa comandos de controle de fluxo: pause, continue, next, stepIn, stepOut',
      () async {
        expect((await client.pause(1)).success, isTrue);
        expect((await client.resume(1)).success, isTrue);
        expect((await client.stepOver(1)).success, isTrue);
        expect((await client.stepIn(1)).success, isTrue);
        expect((await client.stepOut(1)).success, isTrue);
      },
    );

    test(
      'consulta inspeção: threads, stackTrace, scopes, variables e evaluate',
      () async {
        final threads = await client.threads();
        expect(threads.length, equals(1));
        expect(threads.first.name, equals('main.dart'));

        final frames = await client.stackTrace(1);
        expect(frames.length, equals(1));
        expect(frames.first.name, equals('calculate'));
        expect(frames.first.line, equals(42));

        final scopes = await client.scopes(10);
        expect(scopes.length, equals(1));
        expect(scopes.first.variablesReference, equals(200));

        final vars = await client.variables(200);
        expect(vars.length, equals(1));
        expect(vars.first.name, equals('counter'));
        expect(vars.first.value, equals('42'));

        final evalRes = await client.evaluate('counter * 2', frameId: 10);
        expect(evalRes?.result, equals('84'));
      },
    );

    test('recebe eventos assíncronos stopped e output', () async {
      final stoppedEvents = <DapStoppedEvent>[];
      final outputEvents = <DapOutputEvent>[];

      client.stoppedEvents.listen(stoppedEvents.add);
      client.outputEvents.listen(outputEvents.add);

      server.emitEvent('stopped', {
        'reason': 'breakpoint',
        'threadId': 1,
        'text': 'Hit breakpoint at line 10',
      });

      server.emitEvent('output', {
        'category': 'console',
        'output': 'Connecting to VM Service...\n',
      });

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(stoppedEvents.length, equals(1));
      expect(stoppedEvents.first.reason, equals(DapStopReason.breakpoint));
      expect(stoppedEvents.first.threadId, equals(1));

      expect(outputEvents.length, equals(1));
      expect(outputEvents.first.output, contains('Connecting to VM Service'));
    });
  });

  group('DebugSessionController', () {
    late MockDapAdapterServer server;
    late DapClient client;
    late DebugSessionController controller;

    setUp(() {
      server = MockDapAdapterServer();
      client = DapClient(
        stdout: server.stream,
        stdin: server.sink,
        sessionId: 'test-session-1',
      );
      controller = DebugSessionController();
    });

    tearDown(() async {
      controller.dispose();
      await client.close();
      await server.close();
    });

    test(
      'inicia sessão, sincroniza breakpoints, faz launch e transiciona para running',
      () async {
        expect(controller.state, equals(DapSessionState.idle));

        await controller.toggleBreakpoint('/project/lib/main.dart', 15);
        expect(
          controller.breakpointsByPath['/project/lib/main.dart']?.first.line,
          equals(15),
        );

        await controller.startSession(
          client: client,
          program: '/project/lib/main.dart',
          cwd: '/project',
        );

        expect(controller.state, equals(DapSessionState.running));
        expect(controller.isRunning, isTrue);

        // Simula interrupção em breakpoint
        server.emitEvent('stopped', {'reason': 'breakpoint', 'threadId': 1});
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(controller.state, equals(DapSessionState.stopped));
        expect(controller.isStopped, isTrue);
        expect(controller.lastStopReason, equals(DapStopReason.breakpoint));
        expect(controller.stackFrames.length, equals(1));
        expect(controller.variables.first.name, equals('counter'));

        // Finaliza sessão
        await controller.stop();

        expect(controller.state, equals(DapSessionState.idle));
        expect(controller.stackFrames, isEmpty);
        expect(controller.variables, isEmpty);
      },
    );
  });
}
