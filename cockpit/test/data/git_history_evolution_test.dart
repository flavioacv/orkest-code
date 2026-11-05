import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_history_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';

void main() {
  group('GitHistoryReaderImpl - Evolução G03 (Filtros, Blame e Comparação)', () {
    final reader = GitHistoryReaderImpl(GitBinary());
    late Directory repo;

    Future<ProcessResult> git(List<String> args) =>
        Process.run('git', args, workingDirectory: repo.path);

    setUp(() async {
      repo = await Directory.systemTemp.createTemp('orkest_history_g03_test_');
      await git(['init', '-b', 'main']);
      await git(['config', 'user.email', 'dev@example.com']);
      await git(['config', 'user.name', 'Alice Dev']);

      // Commit 1: Criação de arquivo inicial
      await File('${repo.path}/file1.txt').writeAsString('linha 1\nlinha 2\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'feat: initial setup']);

      // Commit 2: Outro autor altera file1
      await git(['config', 'user.email', 'bob@example.com']);
      await git(['config', 'user.name', 'Bob Coder']);
      await File('${repo.path}/file1.txt').writeAsString('linha 1\nlinha 2 alterada\nlinha 3\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'fix: update line 2']);

      // Commit 3: Adiciona outro arquivo
      await File('${repo.path}/file2.txt').writeAsString('outro arquivo\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'chore: add file2']);

      // Cria branch feature divergente
      await git(['checkout', '-b', 'feature/nova-tela']);
      await File('${repo.path}/tela.txt').writeAsString('interface v1\n');
      await git(['add', '.']);
      await git(['commit', '-m', 'feat: add tela component']);

      // Volta para main
      await git(['checkout', 'main']);
    });

    tearDown(() async {
      if (await repo.exists()) await repo.delete(recursive: true);
    });

    test('paginação com limit e skip retorna os commits corretos', () async {
      final page1Res = await reader.read(repo.path, limit: 2, skip: 0);
      expect(page1Res, isA<Success>());
      final page1 = (page1Res as Success).value;
      expect(page1.length, equals(2));
      expect(page1[0].subject, equals('chore: add file2'));
      expect(page1[1].subject, equals('fix: update line 2'));

      final page2Res = await reader.read(repo.path, limit: 2, skip: 2);
      expect(page2Res, isA<Success>());
      final page2 = (page2Res as Success).value;
      expect(page2.length, equals(1));
      expect(page2[0].subject, equals('feat: initial setup'));
    });

    test('filtro por autor retorna apenas commits do autor correspondente', () async {
      const query = GitHistoryQuery(author: 'Bob');
      final res = await reader.read(repo.path, query: query);
      expect(res, isA<Success>());
      final commits = (res as Success).value;
      expect(commits.length, equals(2));
      expect(commits.every((c) => c.author == 'Bob Coder'), isTrue);
    });

    test('filtro por mensagem (grep) localiza termos específicos', () async {
      const query = GitHistoryQuery(query: 'initial');
      final res = await reader.read(repo.path, query: query);
      expect(res, isA<Success>());
      final commits = (res as Success).value;
      expect(commits.length, equals(1));
      expect(commits.first.subject, equals('feat: initial setup'));
    });

    test('filtro por filePath acompanha alterações focadas no arquivo', () async {
      const query = GitHistoryQuery(filePath: 'file2.txt');
      final res = await reader.read(repo.path, query: query);
      expect(res, isA<Success>());
      final commits = (res as Success).value;
      expect(commits.length, equals(1));
      expect(commits.first.subject, equals('chore: add file2'));
    });

    test('flag all lista commits de todas as branches', () async {
      const query = GitHistoryQuery(all: true);
      final res = await reader.read(repo.path, query: query);
      expect(res, isA<Success>());
      final subjects = (res as Success).value.map((c) => c.subject).toList();
      expect(subjects, contains('feat: add tela component'));
      expect(subjects, contains('chore: add file2'));
    });

    test('readBlame recupera autoria real das linhas do arquivo', () async {
      final blameRes = await reader.readBlame(repo.path, 'file1.txt');
      expect(blameRes, isA<Success>());
      final hunks = (blameRes as Success).value;
      expect(hunks.isNotEmpty, isTrue);

      final authors = hunks.map((h) => h.author).toSet();
      expect(authors, contains('Alice Dev'));
      expect(authors, contains('Bob Coder'));

      final blameHunks = (blameRes as Success).value as List<GitBlameHunk>;
      final line1Hunk = blameHunks.firstWhere((h) => h.containsLine(1));
      expect(line1Hunk.author, equals('Alice Dev'));

      // Linha 2 veio do segundo commit (Bob)
      final line2Hunk = blameHunks.firstWhere((h) => h.containsLine(2));
      expect(line2Hunk.author, equals('Bob Coder'));
    });

    test('compareRefs compara duas branches e retorna commits e arquivos divergentes', () async {
      final compRes = await reader.compareRefs(repo.path, 'main', 'feature/nova-tela');
      expect(compRes, isA<Success>());
      final comp = (compRes as Success).value;

      expect(comp.baseRef, equals('main'));
      expect(comp.targetRef, equals('feature/nova-tela'));
      expect(comp.commitCount, equals(1));
      expect(comp.commits.first.subject, equals('feat: add tela component'));

      expect(comp.fileCount, equals(1));
      expect(comp.changedFiles.first.path, equals('tela.txt'));
      expect(comp.changedFiles.first.status, equals('A'));
    });
  });
}
