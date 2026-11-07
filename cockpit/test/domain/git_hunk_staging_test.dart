import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/domain/services/git_hunk_service.dart';

void main() {
  group('G01 · Revisão e staging por hunks (GitHunkService)', () {
    const service = GitHunkService();

    test('1. Constrói patch unificado com headers corretos e caminhos normalizados', () {
      const hunk = DiffHunk(
        header: '@@ -10,4 +10,5 @@ void main() {',
        lines: [
          DiffLine(kind: DiffLineKind.context, text: '  final a = 1;'),
          DiffLine(kind: DiffLineKind.removed, text: '  final b = 2;'),
          DiffLine(kind: DiffLineKind.added, text: '  final b = 42;'),
          DiffLine(kind: DiffLineKind.added, text: '  final c = 3;'),
          DiffLine(kind: DiffLineKind.context, text: '  runApp();'),
        ],
      );

      final patch = service.buildHunkPatch(
        relativePath: r'lib\src\app.dart', // caminho estilo Windows com contra-barra
        hunk: hunk,
      );

      expect(patch, contains('diff --git a/lib/src/app.dart b/lib/src/app.dart'));
      expect(patch, contains('--- a/lib/src/app.dart'));
      expect(patch, contains('+++ b/lib/src/app.dart'));
      expect(patch, contains('@@ -10,4 +10,5 @@ void main() {'));
      expect(patch, contains('   final a = 1;'));
      expect(patch, contains('-  final b = 2;'));
      expect(patch, contains('+  final b = 42;'));
      expect(patch, contains('+  final c = 3;'));
      expect(patch, contains('   runApp();'));
    });

    test('2. Staging e unstage real de hunk em repositório Git temporário', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_hunk_test_');

      try {
        // Inicializa repo git de teste
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);

        // Cria arquivo inicial e comita
        final file = File('${tempDir.path}/sample.txt');
        await file.writeAsString(
          'linha 1\n'
          'linha 2\n'
          'linha 3\n'
          'linha 4\n'
          'linha 5\n'
          'linha 6\n'
          'linha 7\n'
          'linha 8\n'
          'linha 9\n'
          'linha 10\n',
        );
        await Process.run('git', ['add', 'sample.txt'], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'initial'], workingDirectory: tempDir.path);

        // Modifica duas partes distintas do arquivo (gerando 2 hunks separados)
        await file.writeAsString(
          'linha 1 alterada\n'
          'linha 2\n'
          'linha 3\n'
          'linha 4\n'
          'linha 5\n'
          'linha 6\n'
          'linha 7\n'
          'linha 8\n'
          'linha 9\n'
          'linha 10 alterada\n',
        );

        // Cria hunk representando apenas a alteração do primeiro trecho (linha 1)
        const hunk1 = DiffHunk(
          header: '@@ -1,3 +1,3 @@',
          lines: [
            DiffLine(kind: DiffLineKind.removed, text: 'linha 1'),
            DiffLine(kind: DiffLineKind.added, text: 'linha 1 alterada'),
            DiffLine(kind: DiffLineKind.context, text: 'linha 2'),
            DiffLine(kind: DiffLineKind.context, text: 'linha 3'),
          ],
        );

        // 2.1 Stage apenas do primeiro hunk
        final stageResult = await service.stageHunk(
          repoRoot: tempDir.path,
          relativePath: 'sample.txt',
          hunk: hunk1,
        );
        expect(stageResult.isSuccess, isTrue);

        // Verifica que o index contém apenas a mudança da linha 1
        final stagedDiff = await Process.run(
          'git',
          ['diff', '--cached'],
          workingDirectory: tempDir.path,
        );
        expect(stagedDiff.stdout, contains('linha 1 alterada'));
        expect(stagedDiff.stdout, isNot(contains('linha 10 alterada')));

        // Verifica que o working tree ainda contém a mudança da linha 10 pendente
        final unstagedDiff = await Process.run(
          'git',
          ['diff'],
          workingDirectory: tempDir.path,
        );
        expect(unstagedDiff.stdout, contains('linha 10 alterada'));
        expect(unstagedDiff.stdout, isNot(contains('linha 1 alterada')));

        // 2.2 Unstage do primeiro hunk
        final unstageResult = await service.unstageHunk(
          repoRoot: tempDir.path,
          relativePath: 'sample.txt',
          hunk: hunk1,
        );
        expect(unstageResult.isSuccess, isTrue);

        // Agora o index deve estar totalmente limpo
        final stagedDiffAfter = await Process.run(
          'git',
          ['diff', '--cached'],
          workingDirectory: tempDir.path,
        );
        expect(stagedDiffAfter.stdout.toString().trim(), isEmpty);

        // E o working tree mantém ambas as alterações intactas!
        final unstagedDiffAfter = await Process.run(
          'git',
          ['diff'],
          workingDirectory: tempDir.path,
        );
        expect(unstagedDiffAfter.stdout, contains('linha 1 alterada'));
        expect(unstagedDiffAfter.stdout, contains('linha 10 alterada'));

        // 2.3 Descarte isolado (discardHunk) da alteração da linha 1
        final discardResult = await service.discardHunk(
          repoRoot: tempDir.path,
          relativePath: 'sample.txt',
          hunk: hunk1,
        );
        expect(discardResult.isSuccess, isTrue);

        // Linha 1 voltou ao original no arquivo; linha 10 continua alterada
        final contentAfterDiscard = await file.readAsString();
        expect(contentAfterDiscard, startsWith('linha 1\n'));
        expect(contentAfterDiscard, contains('linha 10 alterada'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('3. Proteção contra corridas: falha segura quando o índice já mudou', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_hunk_conflict_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);

        final file = File('${tempDir.path}/test.txt');
        await file.writeAsString('linha inicial\n');
        await Process.run('git', ['add', 'test.txt'], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'init'], workingDirectory: tempDir.path);

        // Hunk obsoleto que não bate com o estado atual do arquivo
        const obsoleteHunk = DiffHunk(
          header: '@@ -1,1 +1,1 @@',
          lines: [
            DiffLine(kind: DiffLineKind.removed, text: 'conteudo inexistente'),
            DiffLine(kind: DiffLineKind.added, text: 'nova linha'),
          ],
        );

        final result = await service.stageHunk(
          repoRoot: tempDir.path,
          relativePath: 'test.txt',
          hunk: obsoleteHunk,
        );

        expect(result.isFailure, isTrue);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('5. Staging e descarte de arquivo novo/untracked com Git real', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_new_file_test_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);

        // Cria arquivo novo untracked
        final file = File('${tempDir.path}/novo.txt');
        await file.writeAsString('linha 1 nova\nlinha 2 nova\n');

        const newHunk = DiffHunk(
          header: '@@ -0,0 +1,2 @@',
          lines: [
            DiffLine(kind: DiffLineKind.added, text: 'linha 1 nova'),
            DiffLine(kind: DiffLineKind.added, text: 'linha 2 nova'),
          ],
        );

        // Stage do arquivo novo
        final stageResult = await service.stageHunk(
          repoRoot: tempDir.path,
          relativePath: 'novo.txt',
          hunk: newHunk,
          kind: FileDiffKind.added,
        );
        expect(stageResult.isSuccess, isTrue);

        final staged = await Process.run('git', ['status', '--porcelain'], workingDirectory: tempDir.path);
        expect(staged.stdout, contains('A  novo.txt'));

        // Unstage do arquivo novo
        final unstageResult = await service.unstageHunk(
          repoRoot: tempDir.path,
          relativePath: 'novo.txt',
          hunk: newHunk,
          kind: FileDiffKind.added,
        );
        expect(unstageResult.isSuccess, isTrue);

        final unstaged = await Process.run('git', ['status', '--porcelain'], workingDirectory: tempDir.path);
        expect(unstaged.stdout, contains('?? novo.txt'));

        // Descarte do arquivo novo no working tree
        final discardResult = await service.discardHunk(
          repoRoot: tempDir.path,
          relativePath: 'novo.txt',
          hunk: newHunk,
          kind: FileDiffKind.added,
        );
        expect(discardResult.isSuccess, isTrue);
        expect(await file.exists(), isFalse);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('6. Staging e unstage com caminhos com espaços e Unicode', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_unicode_hunk_test_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);

        const relPath = 'pasta com espaço/arquivo áéí.txt';
        final subDir = Directory('${tempDir.path}/pasta com espaço');
        await subDir.create(recursive: true);
        final file = File('${tempDir.path}/$relPath');
        await file.writeAsString('linha inicial\n');
        await Process.run('git', ['add', relPath], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'init'], workingDirectory: tempDir.path);

        await file.writeAsString('linha inicial alterada\n');

        const unicodeHunk = DiffHunk(
          header: '@@ -1,1 +1,1 @@',
          lines: [
            DiffLine(kind: DiffLineKind.removed, text: 'linha inicial'),
            DiffLine(kind: DiffLineKind.added, text: 'linha inicial alterada'),
          ],
        );

        final stageResult = await service.stageHunk(
          repoRoot: tempDir.path,
          relativePath: relPath,
          hunk: unicodeHunk,
        );
        expect(stageResult.isSuccess, isTrue);

        final diffCached = await Process.run('git', ['diff', '--cached'], workingDirectory: tempDir.path);
        expect(diffCached.stdout, contains('linha inicial alterada'));

        final unstageResult = await service.unstageHunk(
          repoRoot: tempDir.path,
          relativePath: relPath,
          hunk: unicodeHunk,
        );
        expect(unstageResult.isSuccess, isTrue);

        final diffCachedAfter = await Process.run('git', ['diff', '--cached'], workingDirectory: tempDir.path);
        expect(diffCachedAfter.stdout.toString().trim(), isEmpty);
      } finally {
        await tempDir.delete(recursive: true);
      }
    });

    test('7. Suporte a EOF sem newline na aplicação de hunk', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_eof_newline_test_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Test'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'test@example.com'], workingDirectory: tempDir.path);

        final file = File('${tempDir.path}/nonewline.txt');
        await file.writeAsString('conteudo sem quebra final');
        await Process.run('git', ['add', 'nonewline.txt'], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'init'], workingDirectory: tempDir.path);

        await file.writeAsString('conteudo sem quebra final alterado');

        const eofHunk = DiffHunk(
          header: '@@ -1,1 +1,1 @@',
          lines: [
            DiffLine(kind: DiffLineKind.removed, text: 'conteudo sem quebra final', noNewline: true),
            DiffLine(kind: DiffLineKind.added, text: 'conteudo sem quebra final alterado', noNewline: true),
          ],
        );

        final stageResult = await service.stageHunk(
          repoRoot: tempDir.path,
          relativePath: 'nonewline.txt',
          hunk: eofHunk,
        );
        expect(stageResult.isSuccess, isTrue);

        final stagedDiff = await Process.run('git', ['diff', '--cached'], workingDirectory: tempDir.path);
        expect(stagedDiff.stdout, contains('conteudo sem quebra final alterado'));
      } finally {
        await tempDir.delete(recursive: true);
      }
    });
  });
}
