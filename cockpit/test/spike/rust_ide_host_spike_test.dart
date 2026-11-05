import 'package:flutter_test/flutter_test.dart';

import 'mock_rust_ide_host_server.dart';
import 'rust_ide_host_client.dart';
import 'rust_ide_host_protocol.dart';

void main() {
  group('A03 · Prova de reaproveitamento Rust (VCS e DAP)', () {
    late MockRustIdeHostServer mockServer;
    late RustIdeHostClient client;

    setUp(() {
      mockServer = MockRustIdeHostServer();
      client = RustIdeHostClient(
        input: mockServer.stream,
        output: mockServer.sink,
      );
    });

    tearDown(() async {
      await client.close();
      mockServer.close();
    });

    test('1. Handshake initialize e inventário de comandos', () async {
      final info = await client.initialize(protocolVersion: 2);
      expect(info.protocol, equals(2));
      expect(info.version, equals('0.1.36'));
      expect(info.os, isNotEmpty);
      expect(info.arch, isNotEmpty);

      final commands = await client.getCommands();
      expect(commands, contains('vcs_status'));
      expect(commands, contains('vcs_roots'));
      expect(commands, contains('debug_start'));
      expect(commands, contains('debug_set_breakpoints'));
      expect(commands, contains('debug_threads'));
      expect(commands, contains('debug_stack_trace'));
      expect(commands, contains('cancel_request'));
    });

    test('2. Abertura e fechamento de projeto no host', () async {
      await client.initialize();
      final projectInfo = await client.openProject(
        window: 'win_1',
        path: '/Volumes/Externo 1/projetos/zurc/remote_pi',
      );

      expect(projectInfo['root'], contains('remote_pi'));
      expect(projectInfo['trusted'], isTrue);

      await expectLater(client.closeProject(window: 'win_1'), completes);
    });

    test('3. Operações VCS: status, roots e cancelamento', () async {
      await client.initialize();
      await client.openProject(window: 'win_1', path: '/test/repo');

      final statusList = await client.vcsStatus(window: 'win_1');
      expect(statusList, hasLength(3));
      expect(statusList.any((s) => s.path == 'lib/main.dart' && s.status == 'modified' && !s.staged), isTrue);
      expect(statusList.any((s) => s.path == 'pubspec.yaml' && s.staged), isTrue);
      expect(statusList.any((s) => s.path == 'test/new_test.dart' && s.status == 'untracked'), isTrue);

      final roots = await client.vcsRoots(window: 'win_1');
      expect(roots, hasLength(1));
      expect(roots.first.head, equals('fix/harness-state-detection'));
      expect(roots.first.headCommit, equals('3809c4d7'));

      // Cancelamento de requisição longa
      await expectLater(client.cancelRequest(42), completes);
    });

    test('4. Ciclo de vida completo de sessão DAP (Debug Adapter Protocol)', () async {
      await client.initialize();
      await client.openProject(window: 'win_1', path: '/test/repo');

      // 4.1 debug_start
      final config = RustDebugLaunchConfig(
        name: 'Launch Cockpit',
        adapter: 'dart',
        request: 'launch',
        program: 'lib/main.dart',
      );
      final sessionId = await client.debugStart(window: 'win_1', config: config);
      expect(sessionId, startsWith('debug-session-'));

      // 4.2 debug_set_breakpoints
      final breakpoints = [
        const RustSourceBreakpoint(line: 42),
        const RustSourceBreakpoint(line: 105, condition: 'count > 10'),
      ];
      final verifiedBreakpoints = await client.debugSetBreakpoints(
        window: 'win_1',
        path: 'lib/main.dart',
        breakpoints: breakpoints,
      );
      expect(verifiedBreakpoints, hasLength(2));

      // 4.3 debug_threads
      final threads = await client.debugThreads(window: 'win_1', session: sessionId);
      expect(threads, hasLength(2));
      expect(threads.first.name, equals('main'));

      // 4.4 debug_stack_trace
      final frames = await client.debugStackTrace(
        window: 'win_1',
        session: sessionId,
        threadId: threads.first.id,
      );
      expect(frames, hasLength(2));
      expect(frames.first.name, equals('main()'));
      expect(frames.first.line, equals(42));

      // 4.5 debug_variables & evaluate
      final vars = await client.debugVariables(
        window: 'win_1',
        session: sessionId,
        reference: 0,
      );
      expect(vars, hasLength(2));
      expect(vars.first.name, equals('status'));

      final evalResult = await client.debugEvaluate(
        window: 'win_1',
        session: sessionId,
        frameId: frames.first.id,
        expression: '1 + 1',
      );
      expect(evalResult['result'], contains('1 + 1'));

      // 4.6 controle de fluxo: step, pause, resume
      await client.debugStep(window: 'win_1', session: sessionId, threadId: 1, kind: 'over');
      await client.debugPause(window: 'win_1', session: sessionId, threadId: 1);
      await client.debugResume(window: 'win_1', session: sessionId, threadId: 1);

      // 4.7 debug_stop
      await expectLater(client.debugStop(window: 'win_1', session: sessionId), completes);
    });

    test('5. Recepção de eventos assíncronos e streaming de progresso', () async {
      await client.initialize();

      final eventsReceived = <dynamic>[];
      client.onWindowEvent('win_1', (event) {
        eventsReceived.add(event);
      });

      // Simula evento emitido pelo servidor Rust
      mockServer.emitEvent(
        window: 'win_1',
        event: {'type': 'git_head_changed', 'newHead': 'commit-abc'},
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(eventsReceived, hasLength(1));
      expect(eventsReceived.first['type'], equals('git_head_changed'));

      // Streaming de progresso via canal
      final streamingChunks = <dynamic>[];
      final invokeFuture = client.invoke(
        window: 'win_1',
        cmd: 'open_project',
        args: {'path': '/some/repo'},
        onStreamingData: (data) => streamingChunks.add(data),
      );

      mockServer.emitChannelData(channelId: 1, data: {'percent': 50});
      mockServer.emitChannelData(channelId: 1, data: {'percent': 100});

      await invokeFuture;
      expect(streamingChunks, hasLength(2));
      expect(streamingChunks.first['percent'], equals(50));
    });

    test('6. Isolamento de falhas: detecção de crash sem quebra de processo', () async {
      await client.initialize();

      // Configura servidor para cair na próxima requisição
      mockServer.triggerCrash();

      expect(
        () => client.vcsStatus(window: 'win_1'),
        throwsA(isA<RustRpcException>()),
      );
    });

    test('7. Benchmark de latência IPC (round-trip p50 e p95)', () async {
      await client.initialize();

      final latenciesMicroseconds = <int>[];
      const iterations = 50;

      for (var i = 0; i < iterations; i++) {
        final stopwatch = Stopwatch()..start();
        await client.vcsRoots(window: 'win_1');
        stopwatch.stop();
        latenciesMicroseconds.add(stopwatch.elapsedMicroseconds);
      }

      latenciesMicroseconds.sort();
      final p50 = latenciesMicroseconds[(iterations * 0.50).floor()];
      final p95 = latenciesMicroseconds[(iterations * 0.95).floor()];

      // IPC in-process mock deve ter latência submilissegundo (< 2000 microssegundos)
      expect(p50, lessThan(2000), reason: 'p50 deve ser menor que 2ms');
      expect(p95, lessThan(5000), reason: 'p95 deve ser menor que 5ms');
    });
  });
}
