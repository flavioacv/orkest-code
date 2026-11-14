import 'dart:async';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/dap_codec.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_failure.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/data/dap/multi_language_debug_adapter.dart';
import '../support/debug_adapter_fixture.dart';

void main() {
  late DebugAdapterFixture server;
  late DebugSessionController controller;
  setUp(() {
    server = DebugAdapterFixture();
    controller = DebugSessionController();
  });
  tearDown(() async {
    await controller.stop();
    controller.dispose();
    await server.close();
  });
  Future<void> launch() => controller.startSession(
    client: server.client(),
    program: '/repo/main.dart',
  );
  Future<void> pause() async {
    server.event('stopped', {'reason': 'breakpoint', 'threadId': 1});
    await waitForDebug(
      () => controller.currentFrame?.id == 10 && controller.scopes.isNotEmpty,
    );
  }

  test(
    'breakpoints and watches restore without launching or sharing workspace state',
    () async {
      controller.restoreState({
        'breakpointsEnabled': false,
        'breakpoints': {
          '/repo/main.dart': [
            {
              'line': 3,
              'enabled': false,
              'condition': 'x > 0',
              'logMessage': 'value={x}',
            },
            {'line': -1},
            null,
          ],
        },
        'watches': ['x', 'x', 42],
      });
      expect(controller.breakpointsByPath['/repo/main.dart'], hasLength(1));
      expect(controller.watchExpressions, ['x']);
      expect(controller.breakpointsEnabled, isFalse);
      final other = DebugSessionController()
        ..restoreState(controller.exportState());
      addTearDown(other.dispose);
      expect(
        other.breakpointsByPath['/repo/main.dart']!.single.logMessage,
        'value={x}',
      );
      other.addWatch('other');
      expect(controller.watchExpressions, ['x']);
      await launch();
      expect(
        (server.sent('setBreakpoints').last['arguments'] as Map)['breakpoints'],
        isEmpty,
      );
    },
  );

  test(
    'unsupported logpoints stay unverified rather than becoming unconditional stops',
    () async {
      server.capabilities['supportsLogPoints'] = false;
      await controller.updateBreakpoint(
        '/repo/main.dart',
        const SourceBreakpoint(line: 3, logMessage: 'x={x}'),
      );
      await launch();
      expect(
        controller.breakpointStatus('/repo/main.dart', 3)?.verified,
        isFalse,
      );
      expect(
        (server.sent('setBreakpoints').last['arguments'] as Map)['breakpoints'],
        isEmpty,
      );
      server.event('capabilities', {
        'capabilities': {'supportsLogPoints': true},
      });
      await waitForDebug(() => controller.capabilities.supportsLogPoints);
      await controller.setBreakpointsEnabled(true);
      expect(
        controller.breakpointStatus('/repo/main.dart', 3)?.verified,
        isTrue,
      );
    },
  );

  test(
    'late scopes cannot replace selected frame and evaluation uses that frame',
    () async {
      final pending = Completer<Map<String, dynamic>?>();
      server.handle = (command, args) {
        if (command == 'scopes' && args['frameId'] == 10) return pending.future;
        return null;
      };
      await launch();
      server.event('stopped', {'reason': 'breakpoint', 'threadId': 1});
      await waitForDebug(() => server.sent('scopes').isNotEmpty);
      await controller.selectFrame(20);
      pending.complete({
        'scopes': [
          {'name': 'old', 'variablesReference': 100},
        ],
      });
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.currentFrame?.id, 20);
      expect(controller.scopes.single.variablesReference, 200);
      expect(await controller.evaluate('x'), 'value@20');
      expect((server.sent('evaluate').last['arguments'] as Map)['frameId'], 20);
    },
  );

  test(
    'a step stop received before the next response remains paused',
    () async {
      await launch();
      await pause();
      server.handle = (command, args) async {
        if (command == 'next') {
          server.event('stopped', {'reason': 'step', 'threadId': 1});
          await Future<void>.delayed(const Duration(milliseconds: 5));
          return {};
        }
        return null;
      };
      await controller.stepOver();
      await waitForDebug(() => controller.currentFrame != null);
      expect(controller.isStopped, isTrue);
      expect(controller.busy, isFalse);
    },
  );

  test(
    'exception filters use actual adapter identifiers and preserve explicit none',
    () async {
      controller.restoreState({
        'exceptionsConfigured': true,
        'exceptionFilters': [],
      });
      await launch();
      expect(
        (server.sent('setExceptionBreakpoints').last['arguments']
            as Map)['filters'],
        isEmpty,
      );
      await controller.toggleExceptionFilter('raised');
      expect(
        (server.sent('setExceptionBreakpoints').last['arguments']
            as Map)['filters'],
        ['raised'],
      );
      await controller.toggleExceptionFilter('not-advertised');
      expect(controller.exceptionFilters, {'raised'});
    },
  );

  test(
    'attached processes are disconnected without requesting termination',
    () async {
      await controller.startSession(
        client: server.client(),
        program: '',
        request: 'attach',
      );
      await controller.stop();
      expect(server.sent('terminate'), isEmpty);
      expect(
        (server.sent('disconnect').last['arguments']
            as Map)['terminateDebuggee'],
        isFalse,
      );
    },
  );

  test(
    'reverse requests receive success or an explicit failure response',
    () async {
      final client = server.client();
      client.onReverseRequest = (command, args) async {
        if (command != 'runInTerminal') throw UnsupportedError(command);
        return {'shellProcessId': 42};
      };
      await client.initialize();
      expect(
        (server.sent('initialize').single['arguments']
            as Map)['supportsRunInTerminalRequest'],
        isTrue,
      );
      final result = await server.reverse('runInTerminal', {
        'args': ['dart', 'app.dart'],
      });
      expect(result['success'], isTrue);
      expect((result['body'] as Map)['shellProcessId'], 42);
      expect((await server.reverse('startDebugging'))['success'], isFalse);
      await client.close();
    },
  );

  test(
    'output and exit lifecycle can feed an external telemetry sink once',
    () async {
      final output = <String>[];
      final exits = <int?>[];
      controller.dispose();
      controller = DebugSessionController(
        onOutput: (_, event) => output.add(event.output),
        onSessionEnded: (_, exit) => exits.add(exit),
      );
      await launch();
      server.event('output', {'category': 'stderr', 'output': 'failure\n'});
      server.event('exited', {'exitCode': 2});
      server.event('terminated');
      await waitForDebug(() => !controller.isActive);
      expect(output, ['failure\n']);
      expect(exits, [2]);
    },
  );

  test(
    'configured TCP transport speaks framed DAP over a real socket',
    () async {
      final listener = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final sockets = <Socket>[];
      final subscription = listener.listen((socket) {
        sockets.add(socket);
        const DapCodec()
            .decodeStream(socket)
            .listen(
              (message) => socket.add(
                DapCodec.encode({
                  'seq': 100,
                  'type': 'response',
                  'request_seq': message['seq'],
                  'command': message['command'],
                  'success': true,
                  'body': {'supportsLogPoints': true},
                }),
              ),
            );
      });
      final client = await MultiLanguageDebugAdapter.spawnClient(
        languageId: 'javascript',
        cwd: '.',
        configuration: {'debugServer': listener.port},
      );
      expect((await client!.initialize()).supportsLogPoints, isTrue);
      await client.close();
      await subscription.cancel();
      for (final socket in sockets) {
        socket.destroy();
      }
      await listener.close();
    },
  );

  test(
    'a new launch waits for disconnection of the previous session',
    () async {
      await launch();
      final disconnect = Completer<Map<String, dynamic>>();
      server.handle = (command, args) =>
          command == 'disconnect' ? disconnect.future : null;
      final stopping = controller.stop();
      await waitForDebug(() => server.sent('disconnect').isNotEmpty);
      final next = DebugAdapterFixture();
      addTearDown(next.close);
      final starting = controller.startSession(
        client: next.client(id: 'next'),
        program: '/repo/next.dart',
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(next.sent('initialize'), isEmpty);
      disconnect.complete({});
      await stopping;
      await starting;
      expect(controller.sessionId, 'next');
      expect(controller.isRunning, isTrue);
      await controller.stop();
    },
  );

  test(
    'editing a variable uses its parent reference and refreshes inspection',
    () async {
      await launch();
      await pause();
      final epoch = controller.inspectionVersion;
      await controller.setVariable(100, 'object', '42');
      expect(server.sent('setVariable').single['arguments'], {
        'variablesReference': 100,
        'name': 'object',
        'value': '42',
      });
      expect(controller.inspectionVersion, greaterThan(epoch));
      expect(controller.currentFrame?.id, 10);
    },
  );

  test(
    'Node inspector is not advertised as a DAP server and bad endpoints fail immediately',
    () async {
      final command = MultiLanguageDebugAdapter.resolveAdapterCommand(
        languageId: 'javascript',
      );
      expect(command?.$2, isNot(contains('--inspect-brk')));
      await expectLater(
        MultiLanguageDebugAdapter.spawnClient(
          languageId: 'javascript',
          cwd: '.',
          configuration: {'debugServer': -1},
        ),
        throwsA(isA<DebugFailure>()),
      );
    },
  );
}
