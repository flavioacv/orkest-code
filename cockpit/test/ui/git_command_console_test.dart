import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_command_runner.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_status_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';

class _Reader implements GitStatusReader {
  @override
  Future<GitInfo?> read(String path) async => null;
}

class _Runner extends Fake implements GitCommandRunner {
  @override
  GitRun run(String root, List<String> args) => GitRun(
    output: Stream.fromIterable([
      'https://user:secret@example.com/repo',
      'done',
    ]),
    exitCode: Future.value(args.first == 'fail' ? 1 : 0),
  );
}

void main() {
  test(
    'console preserves caller output, redacts credentials and isolates roots',
    () async {
      final activity = WindowActivityController();
      final git = GitController(_Reader(), _Runner(), activity);
      try {
        final run = git.run('/first', [
          'fetch',
          'https://user:secret@example.com/repo',
        ]);
        final lines = await run.output.toList();
        expect(await run.exitCode, 0);
        expect(lines.first, contains('user:secret'));
        final entry = git.commandLogs.single;
        expect(entry.command, isNot(contains('secret')));
        expect(entry.lines.first, 'https://***@example.com/repo');
        expect(entry.isRunning, isFalse);
        final failed = git.run('/second', ['fail']);
        await failed.output.drain<void>();
        expect(await failed.exitCode, 1);
        expect(git.commandLogs.last.exitCode, 1);
        git.clearCommandLogs(root: '/first');
        expect(git.commandLogs.single.root, '/second');
        final query = git.output('/second', ['status']);
        await query;
        expect(git.commandLogs, hasLength(1));
      } finally {
        git.dispose();
        activity.dispose();
      }
    },
  );
}
