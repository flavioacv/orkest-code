import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/utils/shell_command.dart';

void main() {
  test(
    'exec preserves spaces quotes and shell metacharacters as arguments',
    () async {
      final result = await runShellCommand(
        'display only',
        argv: ['/usr/bin/printf', '%s', r'spaces "quotes" $HOME ; literal'],
      );
      expect(result.code, 0);
      expect(result.stdout, r'spaces "quotes" $HOME ; literal');
    },
    skip: Platform.isWindows,
  );

  test('timeout terminates children as well as the command', () async {
    final dir = Directory.systemTemp.createTempSync('orkest-timeout-test-');
    final pidFile = File('${dir.path}/child.pid');
    int? pid;
    try {
      final result = await runShellCommand(
        'sleep 60 & echo \$! > "${pidFile.path}"; wait',
        timeout: const Duration(seconds: 1),
      );
      expect(result.timedOut, true);
      expect(result.code, 124);
      pid = int.parse(pidFile.readAsStringSync().trim());
      final status = await Process.run('ps', ['-p', '$pid', '-o', 'stat=']);
      expect(
        status.exitCode != 0 || '${status.stdout}'.trim().startsWith('Z'),
        true,
      );
    } finally {
      if (pid != null) Process.killPid(pid, ProcessSignal.sigkill);
      dir.deleteSync(recursive: true);
    }
  }, skip: Platform.isWindows);
}
