import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_pr_review_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/source_control_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Scaffold;

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
  group('SourceControlPanel & GitPrReviewPanel Integration Tests (FE-E6)', () {
    late GitPullRequestService service;
    late List<GitHistoryFileChange> selectedChanges;
    late List<int> checkouts;

    setUp(() {
      selectedChanges = [];
      checkouts = [];

      final prsListJson = jsonEncode([
        {
          'number': 42,
          'title': 'feat: suporte completo a pull requests',
          'body': 'Adiciona revisao contextual de PRs no workbench',
          'state': 'open',
          'user': {'login': 'dev'},
          'head': {'ref': 'feat/pr-workbench'},
          'base': {'ref': 'main'},
          'html_url': 'https://github.com/flavioacv/remote_pi/pull/42',
          'created_at': '2026-11-06T08:00:00Z',
          'draft': false,
        },
      ]);

      final prDetailJson = jsonEncode({
        'number': 42,
        'title': 'feat: suporte completo a pull requests',
        'body': 'Adiciona revisao contextual de PRs no workbench',
        'state': 'open',
        'user': {'login': 'dev'},
        'head': {'ref': 'feat/pr-workbench'},
        'base': {'ref': 'main'},
        'html_url': 'https://github.com/flavioacv/remote_pi/pull/42',
        'created_at': '2026-11-06T08:00:00Z',
        'draft': false,
        'changed_files': 2,
        'additions': 50,
        'deletions': 5,
        'mergeable': true,
      });

      final prFilesJson = jsonEncode([
        {
          'filename': 'lib/workbench.dart',
          'status': 'modified',
          'additions': 30,
          'deletions': 2,
        },
        {
          'filename': 'test/workbench_test.dart',
          'status': 'added',
          'additions': 20,
          'deletions': 3,
        },
      ]);

      service = GitPullRequestService(
        httpRequester: (method, uri, headers, body) async {
          final path = uri.path;
          if (path.endsWith('/pulls')) {
            return (200, prsListJson);
          }
          if (path.endsWith('/pulls/42')) {
            return (200, prDetailJson);
          }
          if (path.endsWith('/pulls/42/files')) {
            return (200, prFilesJson);
          }
          if (path.endsWith('/pulls/42/comments')) {
            return (200, '[]');
          }
          return (404, 'Not found');
        },
        originUrlOverride: 'https://github.com/flavioacv/remote_pi.git',
      );
    });

    testWidgets('alterna para a secao Pull Requests e preserva estado no WorkbenchToolHost', (tester) async {
      SourceControlSection activeSection = SourceControlSection.changes;

      await tester.pumpWidget(
        _wrapWithTheme(
          StatefulBuilder(
            builder: (context, setState) {
              return SourceControlPanel(
                section: activeSection,
                onSectionChanged: (sec) {
                  setState(() => activeSection = sec);
                },
                changeCount: 3,
                repositoryLabel: 'remote_pi · main',
                onMenuRequested: (_) {},
                changesBuilder: (_) => const Text('Changes View Active'),
                historyBuilder: (_) => const Text('History View Active'),
                pullRequestsBuilder: (_) => GitPrReviewPanel(
                  repoRoot: '/path/to/repo',
                  service: service,
                  onSelectFileChange: (change) => selectedChanges.add(change),
                  onCheckoutSuccess: (prNum) => checkouts.add(prNum),
                ),
                composerBuilder: (_) => const SizedBox.shrink(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Inicialmente na view de Changes
      expect(find.text('Changes View Active'), findsOneWidget);
      expect(find.byKey(const ValueKey('source-control-pull-requests-tab')), findsOneWidget);

      // Clica na tab "Pull Requests"
      await tester.tap(find.byKey(const ValueKey('source-control-pull-requests-tab')));
      await tester.pumpAndSettle();

      expect(activeSection, equals(SourceControlSection.pullRequests));
      expect(find.text('Pull Requests'), findsNWidgets(2));
      expect(find.text('#42'), findsOneWidget);
      expect(find.text('feat: suporte completo a pull requests'), findsOneWidget);

      // Inspeciona aba de arquivos alterados (Files Changed)
      expect(find.textContaining('Arquivos Alterados (2)'), findsOneWidget);
      await tester.tap(find.textContaining('Arquivos Alterados'));
      await tester.pumpAndSettle();

      expect(find.text('lib/workbench.dart'), findsOneWidget);
      expect(find.text('test/workbench_test.dart'), findsOneWidget);

      // Clica em um arquivo alterado
      await tester.tap(find.text('lib/workbench.dart'));
      await tester.pumpAndSettle();

      expect(selectedChanges, hasLength(1));
      expect(selectedChanges.first.path, equals('lib/workbench.dart'));

      // Volta para Changes e depois reabre Pull Requests sem descarte
      await tester.tap(find.byKey(const ValueKey('source-control-changes-tab')));
      await tester.pumpAndSettle();
      expect(find.text('Changes View Active'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('source-control-pull-requests-tab')));
      await tester.pumpAndSettle();
      expect(find.text('lib/workbench.dart'), findsOneWidget);
    });
  });
}
