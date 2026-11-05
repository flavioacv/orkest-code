import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/domain/services/git_work_service.dart';

void main() {
  group('GitWorkService - Gestão Avançada de Trabalho Git (G04)', () {
    final service = GitWorkService(GitBinary());
    late Directory repo;

    Future<ProcessResult> git(List<String> args) =>
        Process.run('git', args, workingDirectory: repo.path);

    setUp(() async {
      repo = await Directory.systemTemp.createTemp('orkest_work_service_test_');
      await git(['init', '-b', 'main']);
      await git(['config', 'user.email', 'dev@example.com']);
      await git(['config', 'user.name', 'Developer']);

      // Commit inicial na main
      await File('${repo.path}/file1.txt').writeAsString('linha inicial\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'feat: initial commit']);
    });

    tearDown(() async {
      if (await repo.exists()) await repo.delete(recursive: true);
    });

    test('operações de Stash: push, list, diff, apply, pop e drop', () async {
      // Cria modificação pendente
      await File('${repo.path}/file1.txt').writeAsString('modificação para stash\n');

      // Salva no stash
      final pushRes = await service.stashPush(repo.path, message: 'WIP: my work');
      expect(pushRes, isA<Success>());

      // Confirma que o working tree voltou ao estado limpo
      final cleanContent = await File('${repo.path}/file1.txt').readAsString();
      expect(cleanContent, equals('linha inicial\n'));

      // Lista stashes
      final listRes = await service.listStashes(repo.path);
      expect(listRes, isA<Success>());
      final stashes = (listRes as Success).value;
      expect(stashes.length, equals(1));
      expect(stashes.first.index, equals(0));
      expect(stashes.first.message, contains('WIP: my work'));

      // Diff do stash
      final diffRes = await service.stashDiff(repo.path, index: 0);
      expect(diffRes, isA<Success>());
      final diffText = (diffRes as Success).value;
      expect(diffText, contains('+modificação para stash'));

      // Aplica o stash
      final applyRes = await service.stashApply(repo.path, index: 0);
      expect(applyRes, isA<Success>());
      final appliedContent = await File('${repo.path}/file1.txt').readAsString();
      expect(appliedContent, equals('modificação para stash\n'));

      // Descarta o stash
      final dropRes = await service.stashDrop(repo.path, index: 0);
      expect(dropRes, isA<Success>());
      final emptyList = await service.listStashes(repo.path);
      expect((emptyList as Success).value, isEmpty);
    });

    test('operações de Tags: create, list e delete', () async {
      final initialTags = await service.listTags(repo.path);
      expect((initialTags as Success).value, isEmpty);

      // Cria tag leve
      final tag1Res = await service.createTag(repo.path, name: 'v0.1.0');
      expect(tag1Res, isA<Success>());

      // Cria tag anotada com mensagem
      final tag2Res = await service.createTag(
        repo.path,
        name: 'v1.0.0',
        message: 'Release versão 1.0',
        annotated: true,
      );
      expect(tag2Res, isA<Success>());

      // Lista tags
      final listRes = await service.listTags(repo.path);
      expect(listRes, isA<Success>());
      final tags = (listRes as Success).value;
      expect(tags.length, equals(2));

      final names = tags.map((t) => t.name).toList();
      expect(names, contains('v0.1.0'));
      expect(names, contains('v1.0.0'));

      // Deleta uma tag
      final delRes = await service.deleteTag(repo.path, name: 'v0.1.0');
      expect(delRes, isA<Success>());

      final afterDel = await service.listTags(repo.path);
      final remaining = (afterDel as Success).value;
      expect(remaining.length, equals(1));
      expect(remaining.first.name, equals('v1.0.0'));
    });

    test('operações de Patch: createPatch e applyPatch com checkOnly', () async {
      await File('${repo.path}/file1.txt').writeAsString('conteúdo com patch\n');

      // Gera patch
      final patchRes = await service.createPatch(repo.path);
      expect(patchRes, isA<Success>());
      final patchContent = (patchRes as Success).value;
      expect(patchContent, contains('+conteúdo com patch'));

      // Reverte arquivo para o estado limpo
      await git(['checkout', '--', 'file1.txt']);

      // Valida patch com checkOnly
      final checkRes = await service.applyPatch(
        repo.path,
        patchContent: patchContent,
        checkOnly: true,
      );
      expect(checkRes, isA<Success>());

      // Aplica patch de fato
      final applyRes = await service.applyPatch(
        repo.path,
        patchContent: patchContent,
      );
      expect(applyRes, isA<Success>());

      final finalContent = await File('${repo.path}/file1.txt').readAsString();
      expect(finalContent, equals('conteúdo com patch\n'));
    });

    test('guardrails: bloqueia cherry-pick e rebase direto na main', () async {
      // Cria branch feature
      await git(['checkout', '-b', 'feat/extra']);
      await File('${repo.path}/extra.txt').writeAsString('extra\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'feat: extra commit']);
      final extraHashRes = await git(['rev-parse', 'HEAD']);
      final extraHash = extraHashRes.stdout.toString().trim();

      // Volta para a main
      await git(['checkout', 'main']);

      // Tentativa de cherry-pick diretamente na main DEVE ser bloqueada
      final cherryRes = await service.cherryPick(repo.path, commitHash: extraHash);
      expect(cherryRes, isA<Failure>());
      expect((cherryRes as Failure).error, contains('Guardrail: Operações de alteração direta na branch main são bloqueadas'));

      // Tentativa de rebase diretamente na main DEVE ser bloqueada
      final rebaseRes = await service.rebase(repo.path, upstreamBranch: 'feat/extra');
      expect(rebaseRes, isA<Failure>());
      expect((rebaseRes as Failure).error, contains('Guardrail: Operações de rebase diretamente na branch main são bloqueadas'));
    });

    test('operações de Cherry-pick e Revert em branch de trabalho isolada', () async {
      // Cria commit isolado em branch feature
      await git(['checkout', '-b', 'feat/branch-a']);
      await File('${repo.path}/module_a.txt').writeAsString('modulo A\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'feat: add module a']);
      final commitA = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();

      // Cria branch de trabalho B
      await git(['checkout', 'main']);
      await git(['checkout', '-b', 'feat/branch-b']);

      // Cherry-pick do commitA na branch B
      final cherryOk = await service.cherryPick(repo.path, commitHash: commitA);
      expect(cherryOk, isA<Success>());
      expect(await File('${repo.path}/module_a.txt').exists(), isTrue);

      // Revert do commit cherry-pickado na branch B
      final currentHead = (await git(['rev-parse', 'HEAD'])).stdout.toString().trim();
      final revertOk = await service.revertCommit(repo.path, commitHash: currentHead);
      expect(revertOk, isA<Success>());
      expect(await File('${repo.path}/module_a.txt').exists(), isFalse);
    });
  });
}
