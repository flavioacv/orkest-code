import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/terminal_profile.dart';
import 'package:orkest_code/app/core/utils/spawn_directory.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

class _Gateway implements TerminalGateway {
  final _output = StreamController<List<int>>();
  Map<String, String> environment = {};
  @override
  SpawnDirectory? get spawnDirectory => null;
  @override
  int? get rootProcessId => null;
  @override
  Stream<List<int>> get output => _output.stream;
  @override
  void start({
    required String workingDirectory,
    required TerminalProfile profile,
    int rows = 25,
    int columns = 80,
    Map<String, String> extraEnv = const {},
  }) => environment = extraEnv;
  @override
  void write(List<int> data) {}
  @override
  void resize(int rows, int columns) {}
  @override
  void acknowledgeOutput() {}
  @override
  Future<void> kill() => _output.close();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  for (final explicit in [
    <String, String>{},
    {'NO_COLOR': '1'},
    {'FORCE_COLOR': '0'},
    {'CLICOLOR': '0'},
  ]) {
    test(
      'interactive terminal color capability honors workspace environment $explicit',
      () async {
        final gateway = _Gateway();
        final session = TerminalSession(
          id: 'color-test',
          projectId: 'color-project',
          workingDirectory: '/tmp',
          gateway: gateway,
          spawnEnv: explicit,
          profile: const TerminalProfile(
            id: 'test',
            label: 'test',
            executable: '/bin/sh',
          ),
        );
        try {
          final enabled = explicit.isEmpty;
          expect(gateway.environment['NO_COLOR'], enabled ? '' : '1');
          expect(gateway.environment['FORCE_COLOR'], enabled ? '3' : '0');
          expect(gateway.environment['CLICOLOR_FORCE'], enabled ? '1' : '0');
          expect(
            gateway.environment,
            containsPair('ORKEST_SESSION_TOKEN', session.hookGeneration),
          );
        } finally {
          await session.dispose();
        }
      },
    );
  }
}
