import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_command_runner_impl.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_status_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory temporary;
  late String root;
  late GitController controller;
  const conflicts = GitConflictService();

  Future<ProcessResult> git(
    List<String> args, {
    String? at,
    bool fails = false,
  }) async {
    final result = await Process.run(
      'git',
      ['-C', at ?? root, ...args],
      environment: {'GIT_TERMINAL_PROMPT': '0', 'GIT_EDITOR': 'true'},
    );
    if (!fails) {
      expect(result.exitCode, 0, reason: '${args.join(' ')}: ${result.stderr}');
    }
    return result;
  }

  setUp(() async {
    temporary = await Directory.systemTemp.createTemp('orkest-integration-');
    root = p.join(temporary.path, 'repo');
    await Directory(root).create();
    await git(['init', '-b', 'trunk']);
    await git(['config', 'user.name', 'Git Test']);
    await git(['config', 'user.email', 'git@example.test']);
    await File(p.join(root, 'file.txt')).writeAsString('base\n');
    await git(['add', '.']);
    await git(['commit', '-m', 'base']);
    final activity = WindowActivityController();
    controller = GitController(
      GitStatusReaderImpl(GitBinary()),
      GitCommandRunnerImpl(GitBinary()),
      activity,
    );
    addTearDown(controller.dispose);
    addTearDown(activity.dispose);
  });
  tearDown(() async => temporary.delete(recursive: true));

  Future<String> conflictingWorktree() async {
    await git(['switch', '-c', 'feature']);
    await File(p.join(root, 'file.txt')).writeAsString('feature\n');
    await git(['commit', '-am', 'feature']);
    await git(['switch', 'trunk']);
    await File(p.join(root, 'file.txt')).writeAsString('trunk\n');
    await git(['commit', '-am', 'trunk']);
    final worktree = p.join(temporary.path, 'linked');
    await git(['worktree', 'add', worktree, 'feature']);
    final result = await git(['merge', 'trunk'], at: worktree, fails: true);
    expect(result.exitCode, isNot(0));
    return worktree;
  }

  test(
    'remote checkout reuses a tracking local branch with a different name',
    () async {
      await git(['remote', 'add', 'origin', p.join(temporary.path, 'remote')]);
      await git(['update-ref', 'refs/remotes/origin/topic', 'HEAD']);
      await git(['branch', '--track', 'local-topic', 'origin/topic']);
      final branches = (await controller.branches(
        root,
      )).fold((value) => value, (e) => throw e);
      expect(
        branches.singleWhere((b) => b.name == 'local-topic').upstream,
        'origin/topic',
      );
      final result = await controller.checkoutBranch(
        root,
        branches.singleWhere((b) => b.name == 'origin/topic'),
      );
      expect(result, isA<Success<void, dynamic>>());
      expect(
        (await git(['branch', '--show-current'])).stdout.toString().trim(),
        'local-topic',
      );
    },
  );

  test(
    'create branch uses the chosen starting ref and Git name validation',
    () async {
      final first = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
      await File(p.join(root, 'file.txt')).writeAsString('next\n');
      await git(['commit', '-am', 'next']);
      expect(
        (await controller.createBranch(
          root,
          'from-base',
          startPoint: first,
        )).isSuccess,
        isTrue,
      );
      expect(
        (await git(['rev-parse', 'HEAD'])).stdout.toString().trim(),
        first,
      );
      expect(
        (await controller.createBranch(root, 'bad~name')).isSuccess,
        isFalse,
      );
    },
  );

  test(
    'linked worktree merge remains detectable after resolving the last marker',
    () async {
      final worktree = await conflictingWorktree();
      expect(File(p.join(worktree, '.git')).existsSync(), isTrue);
      expect(
        conflicts.detectOngoingOperation(worktree),
        GitOngoingOperation.merge,
      );
      expect(
        (await conflicts.continueOperation(repoRoot: worktree)).isSuccess,
        isFalse,
      );
      final file = File(p.join(worktree, 'file.txt'));
      await file.writeAsString('reviewed\n');
      expect(
        (await conflicts.markResolved(
          repoRoot: worktree,
          relativePath: 'file.txt',
          expectedText: 'stale\n',
        )).isSuccess,
        isFalse,
      );
      expect(
        (await git([
          'diff',
          '--name-only',
          '--diff-filter=U',
        ], at: worktree)).stdout.toString(),
        contains('file.txt'),
      );
      expect(
        (await conflicts.markResolved(
          repoRoot: worktree,
          relativePath: 'file.txt',
          expectedText: 'reviewed\n',
        )).isSuccess,
        isTrue,
      );
      expect(
        conflicts.detectOngoingOperation(worktree),
        GitOngoingOperation.merge,
      );
      expect(
        (await conflicts.continueOperation(repoRoot: worktree)).isSuccess,
        isTrue,
      );
      expect(
        conflicts.detectOngoingOperation(worktree),
        GitOngoingOperation.none,
      );
      expect(await file.readAsString(), 'reviewed\n');
    },
  );

  test(
    'worktree integration never aborts a pre-existing parent merge',
    () async {
      final worktree = await conflictingWorktree();
      final runner = GitCommandRunnerImpl(GitBinary());
      final outcome = runner.mergeIntoParent(worktree, root, 'trunk');
      await outcome.output.drain<void>();
      expect((await outcome.status).name, 'error');
      expect(
        conflicts.detectOngoingOperation(worktree),
        GitOngoingOperation.merge,
      );
    },
  );

  test(
    'abort works in a linked worktree and restores the original side',
    () async {
      final worktree = await conflictingWorktree();
      expect(
        (await conflicts.abortOperation(repoRoot: worktree)).isSuccess,
        isTrue,
      );
      expect(
        conflicts.detectOngoingOperation(worktree),
        GitOngoingOperation.none,
      );
      expect(
        await File(p.join(worktree, 'file.txt')).readAsString(),
        'feature\n',
      );
    },
  );
  test(
    'checkout ignores stale isCurrent metadata from an old dialog',
    () async {
      await git(['branch', 'topic']);
      final result = await controller.checkoutBranch(
        root,
        const GitBranch(name: 'topic', isRemote: false, isCurrent: true),
      );
      expect(result.isSuccess, isTrue);
      expect(
        (await git(['branch', '--show-current'])).stdout.toString().trim(),
        'topic',
      );
    },
  );

  test(
    'occupied worktree reports a path instead of silently disabling checkout',
    () async {
      final linked = p.join(temporary.path, 'occupied');
      await git(['worktree', 'add', '-b', 'occupied', linked]);
      final branches = (await controller.branches(
        root,
      )).fold((value) => value, (error) => throw error);
      final branch = branches.singleWhere(
        (branch) => branch.name == 'occupied',
      );
      expect(branch.worktreePath, Directory(linked).resolveSymbolicLinksSync());
      final result = await controller.checkoutBranch(root, branch);
      final error = result.fold((_) => null, (error) => error);
      expect(error?.kind, GitBranchErrorKind.inUse);
      expect(error?.detail, Directory(linked).resolveSymbolicLinksSync());
      expect(
        (await git(['branch', '--show-current'])).stdout.toString().trim(),
        'trunk',
      );
    },
  );

  test('a branch deleted since listing returns missingRef', () async {
    await git(['branch', 'removed']);
    final branch = (await controller.branches(root))
        .fold((value) => value, (error) => throw error)
        .singleWhere((branch) => branch.name == 'removed');
    await git(['branch', '-D', 'removed']);
    final result = await controller.checkoutBranch(root, branch);
    expect(
      result.fold((_) => null, (error) => error.kind),
      GitBranchErrorKind.missingRef,
    );
  });

  test(
    'remote checkout reports a local name collision without changing tracking',
    () async {
      await git(['remote', 'add', 'origin', p.join(temporary.path, 'remote')]);
      await git(['update-ref', 'refs/remotes/origin/topic', 'HEAD']);
      await git(['branch', 'topic']);
      final result = await controller.checkoutBranch(
        root,
        const GitBranch(name: 'origin/topic', isRemote: true, isCurrent: false),
      );
      expect(
        result.fold((_) => null, (error) => error.kind),
        GitBranchErrorKind.localNameCollision,
      );
      expect(
        (await git(['branch', '--show-current'])).stdout.toString().trim(),
        'trunk',
      );
    },
  );
}
