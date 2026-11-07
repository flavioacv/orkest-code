import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_diff_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'multifolder configurations preserve folder context and unique ids',
    () async {
      final temp = await Directory.systemTemp.createTemp('orkest-multifolder-');
      addTearDown(() => temp.delete(recursive: true));
      final roots = [p.join(temp.path, 'app'), p.join(temp.path, 'api')];
      for (final root in roots) {
        await Directory(p.join(root, '.vscode')).create(recursive: true);
        await File(p.join(root, '.vscode', 'launch.json')).writeAsString(r'''{
        "configurations": [{"name":"Start","type":"node","cwd":"src",
          "program":"${workspaceFolder}/src/main.js", "env":{"ROOT":"${workspaceFolder}"}}]
      }''');
      }
      final configs = await const RunConfigurationLoader().load(
        roots.first,
        null,
        workspaceRoots: [roots.first, roots.last, p.join(roots.last, '.')],
      );
      expect(configs, hasLength(2));
      expect(configs.map((config) => config.id).toSet(), hasLength(2));
      expect(configs.map((config) => config.name).toSet(), hasLength(2));
      for (var index = 0; index < roots.length; index++) {
        expect(configs[index].cwd, p.join(roots[index], 'src'));
        expect(configs[index].launchArguments['cwd'], configs[index].cwd);
        expect(configs[index].program, p.join(roots[index], 'src', 'main.js'));
        expect(configs[index].env['ROOT'], roots[index]);
      }
      final reloaded = await const RunConfigurationLoader().load(
        roots.last,
        null,
        workspaceRoots: roots,
      );
      expect(
        reloaded.map((config) => config.id).toSet(),
        configs.map((config) => config.id).toSet(),
      );
    },
  );

  test(
    'contextual runs use the active folder and exclude outside files',
    () async {
      final temp = await Directory.systemTemp.createTemp('orkest-run-roots-');
      addTearDown(() => temp.delete(recursive: true));
      final app = p.join(temp.path, 'app');
      final api = p.join(temp.path, 'api');
      await Directory(p.join(api, 'lib')).create(recursive: true);
      await File(p.join(api, 'pubspec.yaml')).writeAsString('name: api');
      final configs = await const RunConfigurationLoader().load(
        app,
        p.join(api, 'lib', 'main.dart'),
        workspaceRoots: [api],
      );
      expect(configs, isNotEmpty);
      expect(configs.every((config) => config.cwd == api), isTrue);
      expect(
        await const RunConfigurationLoader().load(
          app,
          p.join(temp.path, 'outside.dart'),
        ),
        isEmpty,
      );
    },
  );

  test(
    'launch loader preserves attach, environment and adapter-specific arguments',
    () async {
      final temp = await Directory.systemTemp.createTemp('orkest-launch-');
      addTearDown(() => temp.delete(recursive: true));
      await Directory(p.join(temp.path, '.vscode')).create();
      await File(p.join(temp.path, '.vscode/launch.json')).writeAsString(r'''
      { // JSONC supported
        "configurations": [{"name":"Attach", "type":"dart", "request":"attach",
          "cwd":"${workspaceFolder}", "vmServiceUri":"http://localhost:8181/",
          "env":{"MODE":"test"}, "toolArgs":["-d", "macos"],}],
      }
    ''');
      final configs = await const RunConfigurationLoader().load(
        temp.path,
        null,
      );
      expect(configs.single.request, 'attach');
      expect(configs.single.cwd, temp.path);
      expect(configs.single.env, {'MODE': 'test'});
      expect(configs.single.launchArguments['toolArgs'], ['-d', 'macos']);
      expect(
        configs.single.launchArguments['vmServiceUri'],
        'http://localhost:8181/',
      );
    },
  );

  test(
    'PR review fetch opens the complete merged diff without checkout',
    () async {
      final temp = await Directory.systemTemp.createTemp('orkest-pr-review-');
      addTearDown(() => temp.delete(recursive: true));
      Future<void> git(List<String> args) async {
        final result = await Process.run(
          'git',
          args,
          workingDirectory: temp.path,
        );
        expect(result.exitCode, 0, reason: '${result.stderr}');
      }

      await git(['init', '-b', 'main']);
      await git(['config', 'user.email', 'test@example.com']);
      await git(['config', 'user.name', 'Orkest Test']);
      final file = File(p.join(temp.path, 'sample.txt'));
      await file.writeAsString('one\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'base']);
      await git(['checkout', '-b', 'feature']);
      await file.writeAsString('one\ntwo\n');
      await git(['commit', '-am', 'first']);
      await file.writeAsString('one\ntwo\nthree\n');
      await git(['commit', '-am', 'second']);
      await git(['checkout', 'main']);
      await git(['merge', '--no-ff', 'feature', '-m', 'synthetic merge']);
      await git(['update-ref', 'refs/pull/42/merge', 'HEAD']);
      await git(['remote', 'add', 'origin', temp.path]);
      final ref = await GitPullRequestService().fetchReviewRef(temp.path, 42);
      final diff = await GitDiffReaderImpl(
        GitBinary(),
      ).readCommit(temp.path, ref, 'sample.txt');
      final added = diff.hunks
          .expand((hunk) => hunk.lines)
          .where((line) => line.kind == DiffLineKind.added)
          .map((line) => line.text);
      expect(added, ['two', 'three']);
      final branch = await Process.run('git', [
        'branch',
        '--show-current',
      ], workingDirectory: temp.path);
      expect(branch.stdout.toString().trim(), 'main');
      final status = await Process.run('git', [
        'status',
        '--porcelain',
      ], workingDirectory: temp.path);
      expect(status.stdout.toString().trim(), isEmpty);
    },
  );

  test(
    'unsupported launch variables are rejected rather than executed literally',
    () {
      expect(
        () => RunConfigurationLoader.expand(
          {'program': r'${command:pickProcess}'},
          '/tmp',
          null,
        ),
        throwsFormatException,
      );
    },
  );

  test(
    'Git index base is aligned per conflict and never copied wholesale',
    () async {
      final temp = await Directory.systemTemp.createTemp('orkest-git-base-');
      addTearDown(() => temp.delete(recursive: true));
      Future<void> git(List<String> args, {bool conflict = false}) async {
        final result = await Process.run(
          'git',
          args,
          workingDirectory: temp.path,
        );
        expect(result.exitCode, conflict ? 1 : 0, reason: '${result.stderr}');
      }

      await git(['init', '-b', 'main']);
      await git(['config', 'user.email', 'test@example.com']);
      await git(['config', 'user.name', 'Orkest Test']);
      await git(['config', 'merge.conflictStyle', 'merge']);
      final file = File(p.join(temp.path, 'sample.txt'));
      final middle = List.generate(12, (i) => 'context $i').join('\n');
      String document(String first, String last) =>
          'header\n$first\n$middle\n$last\nfooter\n';
      await file.writeAsString(document('base first', 'base last'));
      await git(['add', '.']);
      await git(['commit', '-m', 'base']);
      await git(['checkout', '-b', 'incoming']);
      await file.writeAsString(document('incoming first', 'incoming last'));
      await git(['commit', '-am', 'incoming']);
      await git(['checkout', 'main']);
      await file.writeAsString(document('ours first', 'ours last'));
      await git(['commit', '-am', 'ours']);
      await git(['merge', 'incoming'], conflict: true);
      const service = GitConflictService();
      final text = await file.readAsString();
      final blocks = await service.reviewBlocks(
        text: text,
        repoRoot: temp.path,
        relativePath: 'sample.txt',
      );
      expect(blocks.length, 2);
      expect(blocks.map((block) => block.base), ['base first', 'base last']);
      expect(
        service.resolveDocument(
          text: text,
          results: blocks.map((b) => b.base!).toList(),
        ),
        document('base first', 'base last'),
      );
      final edited = await service.reviewBlocks(
        text: text.replaceFirst('ours first', 'user edited first'),
        repoRoot: temp.path,
        relativePath: 'sample.txt',
      );
      expect(edited.first.base, isNull);
      expect(edited.last.base, 'base last');
      expect(await file.readAsString(), text);
    },
  );
}
