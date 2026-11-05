import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/native_service_supervisor.dart';

class _FakeProcess implements Process {
  _FakeProcess({
    required this.pid,
  }) {
    _exitCompleter = Completer<int>();
  }

  @override
  final int pid;
  late final Completer<int> _exitCompleter;
  final _stdoutController = StreamController<List<int>>();
  final _stderrController = StreamController<List<int>>();

  bool isKilled = false;
  ProcessSignal? lastSignal;

  @override
  Future<int> get exitCode => _exitCompleter.future;

  @override
  Stream<List<int>> get stdout => _stdoutController.stream;

  @override
  Stream<List<int>> get stderr => _stderrController.stream;

  @override
  IOSink get stdin => throw UnimplementedError();

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    isKilled = true;
    lastSignal = signal;
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(signal == ProcessSignal.sigkill ? 137 : 0);
    }
    return true;
  }

  void emitStdout(String text) {
    _stdoutController.add(utf8.encode(text));
  }

  void emitStderr(String text) {
    _stderrController.add(utf8.encode(text));
  }

  void simulateCrash(int code) {
    if (!_exitCompleter.isCompleted) {
      _exitCompleter.complete(code);
    }
  }
}

void main() {
  group('NativeServiceSupervisor (A05)', () {
    late _FakeProcess fakeProc;

    setUp(() {
      fakeProc = _FakeProcess(pid: 1234);
    });

    test('starts service and monitors running state', () async {
      final supervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'test-service',
          binaryPath: '/path/to/bin',
        ),
        processStarter: (_, _) async => fakeProc,
      );

      expect(supervisor.state, NativeServiceState.unstarted);
      await supervisor.start();

      expect(supervisor.state, NativeServiceState.running);
      expect(supervisor.pid, 1234);

      await supervisor.stop();
      expect(supervisor.state, NativeServiceState.stopped);
      expect(fakeProc.isKilled, isTrue);
    });

    test('sanitizes stdout and stderr logs without exposing secrets', () async {
      final supervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'test-service',
          binaryPath: '/path/to/bin',
        ),
        processStarter: (_, _) async => fakeProc,
      );

      await supervisor.start();

      fakeProc.emitStdout('Ready! Connecting to postgres://user:super_secret@localhost:5432/db\n');
      fakeProc.emitStderr('Failed with --password=super_secret_123 in command\n');

      await Future.delayed(const Duration(milliseconds: 50));

      final logs = supervisor.sanitizedLogs;
      expect(logs.any((l) => l.contains('[OUT]') && l.contains('[REDACTED]@localhost')), isTrue);
      expect(logs.any((l) => l.contains('super_secret@')), isFalse);
      expect(logs.any((l) => l.contains('[ERR]') && l.contains('--password=[REDACTED]')), isTrue);
      expect(logs.any((l) => l.contains('super_secret_123')), isFalse);

      await supervisor.stop();
    });

    test('verifies protocol compatibility during handshake', () async {
      final supervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'handshake-service',
          binaryPath: '/path/to/bin',
          expectedProtocolVersion: 2,
        ),
        processStarter: (_, _) async => _FakeProcess(pid: 1111),
      );

      await supervisor.start();

      // Handshake compatível
      await supervisor.performHandshake((proc) async => 2);
      expect(supervisor.state, NativeServiceState.running);

      // Handshake incompatível rejeita
      final badSupervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'handshake-service',
          binaryPath: '/path/to/bin',
          expectedProtocolVersion: 3,
        ),
        processStarter: (_, _) async => _FakeProcess(pid: 2222),
      );
      await badSupervisor.start();

      expect(
        () => badSupervisor.performHandshake((proc) async => 1),
        throwsA(isA<IncompatibleProtocolException>()),
      );
    });

    test('handles unexpected crash and enters degraded state on crash loop', () async {
      var processCount = 0;
      final procs = <_FakeProcess>[];

      final supervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'crash-service',
          binaryPath: '/path/to/bin',
          maxCrashesInWindow: 2,
          crashWindow: Duration(seconds: 5),
        ),
        processStarter: (_, _) async {
          processCount++;
          final p = _FakeProcess(pid: 2000 + processCount);
          procs.add(p);
          return p;
        },
      );

      await supervisor.start();
      expect(supervisor.state, NativeServiceState.running);

      // 1ª queda (deve reiniciar com auto-restart)
      procs[0].simulateCrash(1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(processCount, 2);

      // 2ª queda (excede o limite de 2 quedas na janela -> entra em degraded)
      procs[1].simulateCrash(1);
      await Future.delayed(const Duration(milliseconds: 50));
      expect(supervisor.state, NativeServiceState.degraded);

      await supervisor.dispose();
    });

    test('performs rollback to previous binary successfully', () async {
      final startedPaths = <String>[];

      final supervisor = NativeServiceSupervisor(
        config: const NativeServiceConfig(
          serviceName: 'rollback-service',
          binaryPath: '/path/to/bin_v2',
          fallbackBinaryPath: '/path/to/bin_v1',
        ),
        processStarter: (exec, _) async {
          startedPaths.add(exec);
          return _FakeProcess(pid: 5000);
        },
      );

      await supervisor.start();
      expect(startedPaths.last, '/path/to/bin_v2');

      final rolledBack = await supervisor.rollback();
      expect(rolledBack, isTrue);
      expect(startedPaths.last, '/path/to/bin_v1');
      expect(supervisor.config.binaryPath, '/path/to/bin_v1');
      expect(supervisor.config.fallbackBinaryPath, isNull);

      await supervisor.dispose();
    });
  });
}
