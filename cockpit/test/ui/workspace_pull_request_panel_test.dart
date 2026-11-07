import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_pull_request.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_pr_review_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workspace_pull_request_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class _Service extends GitPullRequestService {
  final listed = <String>[];
  final fetched = <String>[];
  final fetches = <Completer<String>>[];
  final checkout = Completer<Result<void, String>>();
  final comment = Completer<Result<GitPrComment, String>>();
  @override
  Future<Result<List<GitPullRequest>, String>> listPullRequests(
    String root, {
    String state = 'open',
    int limit = 30,
  }) async {
    listed.add(root);
    return Success([
      GitPullRequest(
        number: 1,
        title: 'Change $root',
        body: root,
        state: 'open',
        author: 'dev',
        headRef: 'feature',
        baseRef: 'main',
        htmlUrl: '',
        createdAt: DateTime(2026),
      ),
    ]);
  }

  @override
  Future<Result<GitPrDetail, String>> getPullRequestDetail(
    String root,
    int number,
  ) async {
    final list = await listPullRequests(root);
    return Success(
      GitPrDetail(
        pr: (list as Success<List<GitPullRequest>, String>).value.single,
        comments: [],
        changedFiles: [],
        diff: '',
      ),
    );
  }

  @override
  Future<String> fetchReviewRef(String root, int number) {
    fetched.add(root);
    final completer = Completer<String>();
    fetches.add(completer);
    return completer.future;
  }

  @override
  Future<Result<GitPrComment, String>> addComment(
    String root, {
    required int number,
    required String body,
    String? commitId,
    String? path,
    int? line,
  }) => comment.future;
  @override
  Future<Result<void, String>> checkoutPullRequest(String root, int number) =>
      checkout.future;
}

Widget _wrap(
  _Service service,
  List<String> roots,
  List<String> opened, {
  double width = 800,
}) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: sc.ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: width,
              child: WorkspacePullRequestPanel(
                roots: roots,
                service: service,
                onOpenDiff: (root, ref, change) async =>
                    opened.add('$root:$ref:${change.path}'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _select(WidgetTester tester, String root) async {
  await tester.tap(find.byKey(const ValueKey('pr-repository-selector')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(root == '/api' ? 'api · /api' : 'app · /app').last,
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'repository selection routes fetch and diff; stale fetch is ignored',
    (tester) async {
      final service = _Service();
      final opened = <String>[];
      await tester.pumpWidget(_wrap(service, ['/app', '/api'], opened));
      await tester.pumpAndSettle();
      final first = tester.widget<GitPrReviewPanel>(
        find.byType(GitPrReviewPanel),
      );
      const file = GitHistoryFileChange(path: 'main.dart', status: 'M');
      final oldFetch = first.onSelectReviewFile!(1, file);
      await _select(tester, '/api');
      expect(
        tester.widget<GitPrReviewPanel>(find.byType(GitPrReviewPanel)).repoRoot,
        '/api',
      );
      service.fetches.first.complete('old');
      await oldFetch;
      expect(opened, isEmpty);
      final current = tester.widget<GitPrReviewPanel>(
        find.byType(GitPrReviewPanel),
      );
      final currentFetch = current.onSelectReviewFile!(1, file);
      service.fetches.last.complete('new');
      await currentFetch;
      expect(service.fetched, ['/app', '/api']);
      expect(opened, ['/api:new:main.dart']);
      await tester.pumpWidget(_wrap(service, ['/api', '/app'], opened));
      await tester.pumpAndSettle();
      expect(
        tester.widget<GitPrReviewPanel>(find.byType(GitPrReviewPanel)).repoRoot,
        '/api',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'removed repository invalidates pending navigation and empty roots do not query',
    (tester) async {
      final service = _Service();
      final opened = <String>[];
      await tester.pumpWidget(_wrap(service, ['/app', '/api'], opened));
      await tester.pumpAndSettle();
      final panel = tester.widget<GitPrReviewPanel>(
        find.byType(GitPrReviewPanel),
      );
      final pending = panel.onSelectReviewFile!(
        1,
        const GitHistoryFileChange(path: 'file', status: 'M'),
      );
      await tester.pumpWidget(_wrap(service, ['/api'], opened));
      await tester.pumpAndSettle();
      service.fetches.first.complete('stale');
      await pending;
      expect(opened, isEmpty);
      expect(
        tester.widget<GitPrReviewPanel>(find.byType(GitPrReviewPanel)).repoRoot,
        '/api',
      );
      final count = service.listed.length;
      await tester.pumpWidget(_wrap(service, [], opened));
      await tester.pumpAndSettle();
      expect(find.text('Nenhum repositório Git disponível.'), findsOneWidget);
      expect(service.listed.length, count);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'checkout locks repository selection and releases it on failure',
    (tester) async {
      final service = _Service();
      await tester.pumpWidget(_wrap(service, ['/app', '/api'], []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Checkout Local'));
      await tester.pump();
      DropdownButton<String> selector() =>
          tester.widget(find.byKey(const ValueKey('pr-repository-selector')));
      expect(selector().onChanged, isNull);
      service.checkout.complete(const Failure('Checkout refused'));
      await tester.pumpAndSettle();
      expect(selector().onChanged, isNotNull);
      expect(find.text('Erro no checkout: Checkout refused'), findsOneWidget);
      await _select(tester, '/api');
      expect(
        tester.widget<GitPrReviewPanel>(find.byType(GitPrReviewPanel)).repoRoot,
        '/api',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'comment locks context and exceptions release selector with feedback',
    (tester) async {
      final service = _Service();
      await tester.pumpWidget(_wrap(service, ['/app', '/api'], []));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Comentários (0)'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Review comment');
      await tester.tap(find.text('Comentar'));
      await tester.pump();
      final selector = find.byKey(const ValueKey('pr-repository-selector'));
      expect(tester.widget<DropdownButton<String>>(selector).onChanged, isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      service.comment.completeError(StateError('Comment refused'));
      await tester.pumpAndSettle();
      expect(
        tester.widget<DropdownButton<String>>(selector).onChanged,
        isNotNull,
      );
      expect(
        find.textContaining('Falha ao enviar comentário:'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('narrow selector preserves generation across A to B to A', (
    tester,
  ) async {
    final service = _Service();
    final opened = <String>[];
    await tester.pumpWidget(
      _wrap(service, ['/app', '/api', '/app'], opened, width: 320),
    );
    await tester.pumpAndSettle();
    final panel = tester.widget<GitPrReviewPanel>(
      find.byType(GitPrReviewPanel),
    );
    final pending = panel.onSelectReviewFile!(
      1,
      const GitHistoryFileChange(path: 'file', status: 'M'),
    );
    await _select(tester, '/api');
    await _select(tester, '/app');
    service.fetches.first.complete('old-app');
    await pending;
    expect(opened, isEmpty);
    expect(
      tester.widget<GitPrReviewPanel>(find.byType(GitPrReviewPanel)).repoRoot,
      '/app',
    );
    expect(tester.takeException(), isNull);
  });
}
