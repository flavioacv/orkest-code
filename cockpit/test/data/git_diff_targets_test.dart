import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_diff_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_diff_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:path/path.dart' as p;

void main() {
  final reader = GitDiffReaderImpl(GitBinary());
  late Directory temp;
  Future<void> git(String root, List<String> args) async {
    final result = await Process.run('git', args, workingDirectory: root);
    expect(result.exitCode, 0, reason: '${result.stderr}');
  }

  Future<String> repo(String name, {bool committed = true}) async {
    final root = p.join(temp.path, name);
    await Directory(root).create();
    await git(root, ['init']);
    await git(root, ['config', 'user.email', 'test@example.com']);
    await git(root, ['config', 'user.name', 'Test']);
    if (committed) {
      await File(
        p.join(root, 'same file.txt'),
      ).writeAsString('$name original\n');
      await git(root, ['add', '.']);
      await git(root, ['commit', '-m', 'base']);
    }
    return root;
  }

  List<String> lines(FileDiff diff, DiffLineKind kind) => diff.hunks
      .expand((hunk) => hunk.lines)
      .where((line) => line.kind == kind)
      .map((line) => line.text)
      .toList();
  setUp(
    () async =>
        temp = await Directory.systemTemp.createTemp('orkest-diff-targets-'),
  );
  tearDown(() => temp.delete(recursive: true));

  test(
    'two repositories isolate HEAD, Index and Working Tree for the same filename',
    () async {
      for (final name in ['app', 'api']) {
        final root = await repo(name);
        final path = p.join(root, 'same file.txt');
        await File(path).writeAsString('$name prepared\n');
        await git(root, ['add', '--', 'same file.txt']);
        await File(path).writeAsString('$name local\n');
        await git(root, ['config', 'color.ui', 'always']);
        final staged = await reader.read(
          root,
          path,
          target: GitDiffTarget.staged,
        );
        final working = await reader.read(
          root,
          path,
          target: GitDiffTarget.workingTree,
        );
        final combined = await reader.read(root, path);
        expect(lines(staged, DiffLineKind.removed), ['$name original']);
        expect(lines(staged, DiffLineKind.added), ['$name prepared']);
        expect(lines(working, DiffLineKind.removed), ['$name prepared']);
        expect(lines(working, DiffLineKind.added), ['$name local']);
        expect(lines(combined, DiffLineKind.removed), ['$name original']);
        expect(lines(combined, DiffLineKind.added), ['$name local']);
      }
    },
  );

  test(
    'staged-only and untracked files cannot leak into the wrong comparison',
    () async {
      final root = await repo('app');
      final tracked = p.join(root, 'same file.txt');
      await File(tracked).writeAsString('prepared\n');
      await git(root, ['add', '.']);
      expect(
        (await reader.read(
          root,
          tracked,
          target: GitDiffTarget.workingTree,
        )).kind,
        FileDiffKind.unchanged,
      );
      expect(
        (await reader.read(root, tracked, target: GitDiffTarget.staged)).kind,
        FileDiffKind.modified,
      );
      final untracked = p.join(root, 'ação nova.txt');
      await File(untracked).writeAsString('local only\n');
      expect(
        (await reader.read(root, untracked, target: GitDiffTarget.staged)).kind,
        FileDiffKind.unchanged,
      );
      final diff = await reader.read(
        root,
        untracked,
        target: GitDiffTarget.workingTree,
      );
      expect(diff.kind, FileDiffKind.added);
      expect(lines(diff, DiffLineKind.added), ['local only']);
    },
  );

  test(
    'Index works without an initial commit and retains its version after deletion on disk',
    () async {
      final root = await repo('new', committed: false);
      final path = p.join(root, 'first.txt');
      await File(path).writeAsString('prepared\n');
      await git(root, ['add', '.']);
      await File(path).delete();
      final staged = await reader.read(
        root,
        path,
        target: GitDiffTarget.staged,
      );
      final working = await reader.read(
        root,
        path,
        target: GitDiffTarget.workingTree,
      );
      expect(staged.kind, FileDiffKind.added);
      expect(lines(staged, DiffLineKind.added), ['prepared']);
      expect(working.kind, FileDiffKind.deleted);
      expect(lines(working, DiffLineKind.removed), ['prepared']);
    },
  );

  test(
    'wrong root and invalid repository return errors rather than unchanged',
    () async {
      final app = await repo('app');
      final api = await repo('api');
      expect(
        (await reader.read(app, p.join(api, 'same file.txt'))).kind,
        FileDiffKind.error,
      );
      final plain = await Directory(p.join(temp.path, 'plain')).create();
      expect(
        (await reader.read(plain.path, p.join(plain.path, 'file'))).kind,
        FileDiffKind.error,
      );
    },
  );
}
