import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_pull_request.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';

void main() {
  group('GitPullRequestService - parseOwnerRepo', () {
    test('extrai owner e repo de URL SSH válida', () {
      final res = GitPullRequestService.parseOwnerRepo('git@github.com:zurc/remote_pi.git');
      expect(res, isNotNull);
      expect(res!.$1, equals('zurc'));
      expect(res.$2, equals('remote_pi'));
    });

    test('extrai owner e repo de URL HTTPS válida sem sufixo .git', () {
      final res = GitPullRequestService.parseOwnerRepo('https://github.com/flutter/flutter');
      expect(res, isNotNull);
      expect(res!.$1, equals('flutter'));
      expect(res.$2, equals('flutter'));
    });

    test('retorna null para URL vazia ou inválida', () {
      expect(GitPullRequestService.parseOwnerRepo(''), isNull);
      expect(GitPullRequestService.parseOwnerRepo('invalid-url-without-slash'), isNull);
    });
  });

  group('GitPullRequestService - Operações REST via HttpRequester Mock', () {
    test('listPullRequests trata retorno 200 com array de PRs', () async {
      final dummyJson = jsonEncode([
        {
          'number': 101,
          'title': 'feat: nova funcionalidade',
          'body': 'Descrição do PR',
          'state': 'open',
          'user': {'login': 'flavioacv'},
          'head': {'ref': 'feat/minha-feature'},
          'base': {'ref': 'main'},
          'html_url': 'https://github.com/test/repo/pull/101',
          'created_at': '2026-11-05T10:00:00Z',
          'draft': false,
        }
      ]);

      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        expect(method, equals('GET'));
        expect(uri.path, contains('/pulls'));
        return (200, dummyJson);
      }

      final service = GitPullRequestService(
        httpRequester: mockRequester,
        tokenOverride: 'ghp_fake_token',
      );

      // Usamos um diretório que possua remote origin (o repo atual)
      final res = await service.listPullRequests('.');
      switch (res) {
        case Success(:final value):
          expect(value.length, equals(1));
          final pr = value.first;
          expect(pr.number, equals(101));
          expect(pr.title, equals('feat: nova funcionalidade'));
          expect(pr.author, equals('flavioacv'));
          expect(pr.isOpen, isTrue);
          expect(pr.isDraft, isFalse);
        case Failure(:final error):
          fail('Esperava sucesso, obteve: $error');
      }
    });

    test('listPullRequests retorna mensagem clara em erro 401/403', () async {
      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        return (401, '{"message": "Bad credentials"}');
      }

      final service = GitPullRequestService(
        httpRequester: mockRequester,
      );

      final res = await service.listPullRequests('.');
      switch (res) {
        case Success():
          fail('Esperava erro de autenticação');
        case Failure(:final error):
          expect(error, contains('Autenticação necessária'));
      }
    });

    test('getPullRequestDetail agrega PR, comentários e arquivos alterados', () async {
      final prJson = jsonEncode({
        'number': 42,
        'title': 'Fix bug de layout',
        'body': 'Corrige o overflow na listagem',
        'state': 'open',
        'user': {'login': 'dev'},
        'head': {'ref': 'fix/layout'},
        'base': {'ref': 'main'},
        'html_url': 'https://github.com/test/repo/pull/42',
        'created_at': '2026-11-05T09:00:00Z',
      });

      final commentsJson = jsonEncode([
        {
          'id': 1,
          'user': {'login': 'reviewer'},
          'body': 'Excelente solução!',
          'created_at': '2026-11-05T09:30:00Z',
        }
      ]);

      final filesJson = jsonEncode([
        {
          'filename': 'lib/main.dart',
          'status': 'modified',
        },
        {
          'filename': 'lib/new_file.dart',
          'status': 'added',
        }
      ]);

      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        if (headers['Accept'] == 'application/vnd.github.v3.diff') {
          return (200, 'diff --git a/lib/main.dart b/lib/main.dart\n+ nova linha');
        }
        if (uri.path.endsWith('/comments')) {
          return (200, commentsJson);
        }
        if (uri.path.endsWith('/files')) {
          return (200, filesJson);
        }
        return (200, prJson);
      }

      final service = GitPullRequestService(
        httpRequester: mockRequester,
        tokenOverride: 'ghp_fake_token',
      );

      final res = await service.getPullRequestDetail('.', 42);
      switch (res) {
        case Success(:final value):
          expect(value.pr.number, equals(42));
          expect(value.pr.title, equals('Fix bug de layout'));
          expect(value.comments.length, equals(1));
          expect(value.comments.first.author, equals('reviewer'));
          expect(value.changedFiles.length, equals(2));
          expect(value.changedFiles[0].path, equals('lib/main.dart'));
          expect(value.changedFiles[0].status, equals('M'));
          expect(value.changedFiles[1].path, equals('lib/new_file.dart'));
          expect(value.changedFiles[1].status, equals('A'));
          expect(value.diff, contains('diff --git'));
        case Failure(:final error):
          fail('Esperava sucesso ao obter detalhe do PR: $error');
      }
    });

    test('createPullRequest emite payload correto e retorna PR criado', () async {
      String? capturedPayload;

      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        expect(method, equals('POST'));
        capturedPayload = body;
        return (
          201,
          jsonEncode({
            'number': 77,
            'title': 'PR automático',
            'body': 'Corpo do PR',
            'state': 'open',
            'user': {'login': 'flavioacv'},
            'head': {'ref': 'branch-a'},
            'base': {'ref': 'main'},
            'html_url': 'https://github.com/test/repo/pull/77',
            'created_at': '2026-11-05T11:00:00Z',
          })
        );
      }

      final service = GitPullRequestService(
        httpRequester: mockRequester,
        tokenOverride: 'ghp_fake_token',
      );

      final res = await service.createPullRequest(
        '.',
        title: 'PR automático',
        body: 'Corpo do PR',
        headBranch: 'branch-a',
        baseBranch: 'main',
      );

      switch (res) {
        case Success(:final value):
          expect(value.number, equals(77));
          expect(capturedPayload, isNotNull);
          final decoded = jsonDecode(capturedPayload!) as Map<String, dynamic>;
          expect(decoded['head'], equals('branch-a'));
          expect(decoded['base'], equals('main'));
        case Failure(:final error):
          fail('Falha ao criar PR: $error');
      }
    });

    test('addComment emite requisição adequada para comentário inline ou issue', () async {
      Uri? capturedUri;

      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        capturedUri = uri;
        return (
          201,
          jsonEncode({
            'id': 999,
            'user': {'login': 'flavioacv'},
            'body': 'Comentário inline',
            'created_at': '2026-11-05T11:05:00Z',
          })
        );
      }

      final service = GitPullRequestService(
        httpRequester: mockRequester,
        tokenOverride: 'ghp_fake_token',
      );

      // Comentário inline (com path, line e commitId)
      final inlineRes = await service.addComment(
        '.',
        number: 10,
        body: 'Comentário inline',
        path: 'lib/main.dart',
        line: 12,
        commitId: 'abcdef123',
      );

      expect(inlineRes, isA<Success<GitPrComment, String>>());
      expect(capturedUri.toString(), contains('/pulls/10/comments'));

      // Comentário geral na issue/PR
      final issueRes = await service.addComment(
        '.',
        number: 10,
        body: 'Comentário geral',
      );

      expect(issueRes, isA<Success<GitPrComment, String>>());
      expect(capturedUri.toString(), contains('/issues/10/comments'));
    });
  });
}
