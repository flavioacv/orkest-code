import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_pr_review_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Scaffold, TextField;

Widget _wrapWithTheme(Widget child) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: Scaffold(
          body: SizedBox(width: 800, height: 600, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('GitPrReviewPanel Widget Tests', () {
    late GitPullRequestService service;

    setUp(() {
      final prsListJson = jsonEncode([
        {
          'number': 10,
          'title': 'feat: autenticacao oauth',
          'body': 'Implementa fluxo OAuth2 completo',
          'state': 'open',
          'user': {'login': 'alice'},
          'head': {'ref': 'feat/oauth'},
          'base': {'ref': 'main'},
          'html_url': 'https://github.com/org/repo/pull/10',
          'created_at': '2026-11-05T08:00:00Z',
          'draft': false,
        },
        {
          'number': 11,
          'title': 'fix: memory leak no terminal',
          'body': 'Fecha buffers descartados',
          'state': 'open',
          'user': {'login': 'bob'},
          'head': {'ref': 'fix/leak'},
          'base': {'ref': 'main'},
          'html_url': 'https://github.com/org/repo/pull/11',
          'created_at': '2026-11-05T09:00:00Z',
          'draft': true,
        }
      ]);

      final prDetailJson = jsonEncode({
        'number': 10,
        'title': 'feat: autenticacao oauth',
        'body': 'Implementa fluxo OAuth2 completo',
        'state': 'open',
        'user': {'login': 'alice'},
        'head': {'ref': 'feat/oauth'},
        'base': {'ref': 'main'},
        'html_url': 'https://github.com/org/repo/pull/10',
        'created_at': '2026-11-05T08:00:00Z',
      });

      final commentsJson = jsonEncode([
        {
          'id': 1,
          'user': {'login': 'charlie'},
          'body': 'LGTM! Código muito limpo.',
          'created_at': '2026-11-05T08:30:00Z',
        }
      ]);

      final filesJson = jsonEncode([
        {
          'filename': 'lib/auth/oauth_service.dart',
          'status': 'added',
        },
        {
          'filename': 'lib/main.dart',
          'status': 'modified',
        }
      ]);

      Future<(int, String)> mockRequester(
        String method,
        Uri uri,
        Map<String, String> headers,
        String? body,
      ) async {
        if (uri.path.endsWith('/comments')) {
          return (200, commentsJson);
        }
        if (uri.path.endsWith('/files')) {
          return (200, filesJson);
        }
        if (uri.path.endsWith('/10')) {
          return (200, prDetailJson);
        }
        return (200, prsListJson);
      }

      service = GitPullRequestService(
        httpRequester: mockRequester,
        tokenOverride: 'ghp_fake_token',
        originUrlOverride: 'https://github.com/org/repo.git',
      );
    });

    testWidgets('exibe lista de PRs e seleciona o primeiro por padrão', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          GitPrReviewPanel(
            repoRoot: '.',
            service: service,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verifica itens na lista
      expect(find.text('#10'), findsWidgets);
      expect(find.text('feat: autenticacao oauth'), findsWidgets);
      expect(find.text('#11'), findsOneWidget);
      expect(find.text('DRAFT'), findsOneWidget);

      // Verifica detalhe carregado do PR #10
      expect(find.text('#10 - feat: autenticacao oauth'), findsOneWidget);
      expect(find.text('Implementa fluxo OAuth2 completo'), findsOneWidget);
    });

    testWidgets('navega entre abas de arquivos alterados e comentários', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          GitPrReviewPanel(
            repoRoot: '.',
            service: service,
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Clica na aba de Arquivos Alterados (2)
      final filesTab = find.text('Arquivos Alterados (2)');
      expect(filesTab, findsOneWidget);
      await tester.tap(filesTab);
      await tester.pumpAndSettle();

      expect(find.text('lib/auth/oauth_service.dart'), findsOneWidget);
      expect(find.text('lib/main.dart'), findsOneWidget);

      // Clica na aba de Comentários (1)
      final commentsTab = find.text('Comentários (1)');
      expect(commentsTab, findsOneWidget);
      await tester.tap(commentsTab);
      await tester.pumpAndSettle();

      expect(find.text('LGTM! Código muito limpo.'), findsOneWidget);
      expect(find.text('charlie'), findsOneWidget);
      expect(find.text('Comentar'), findsOneWidget);
    });
  });
}
