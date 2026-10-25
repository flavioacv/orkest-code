import 'package:orkest_code/app/orkest/data/remote/remote_worktree_gateway.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RemoteWorktreeGateway.parsePorcelain', () {
    const repo = '/home/jacob/proj';

    test('descarta a raiz e extrai forks com branch', () {
      const out = '''
worktree /home/jacob/proj
HEAD aaaa
branch refs/heads/main

worktree /home/jacob/proj/.orkest/worktrees/feature
HEAD bbbb
branch refs/heads/feature
''';
      final entries = RemoteWorktreeGateway.parsePorcelain(out, repo);
      expect(entries.length, 1);
      expect(entries.single.path, '$repo/.orkest/worktrees/feature');
      expect(entries.single.branch, 'feature');
    });

    test('detached HEAD usa o basename como rótulo', () {
      const out = '''
worktree /home/jacob/proj
HEAD aaaa
branch refs/heads/main

worktree /home/jacob/proj/.orkest/worktrees/wip
HEAD cccc
detached
''';
      final entries = RemoteWorktreeGateway.parsePorcelain(out, repo);
      expect(entries.single.branch, 'wip');
    });

    test('saída vazia = sem forks', () {
      expect(RemoteWorktreeGateway.parsePorcelain('', repo), isEmpty);
    });
  });
}
