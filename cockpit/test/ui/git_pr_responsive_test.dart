import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_pull_request.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_pr_review_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

GitPullRequest _pr(int number) => GitPullRequest(
  number: number,
  title: 'Change $number',
  body: 'Description $number',
  state: 'open',
  author: 'developer',
  headRef: 'feature',
  baseRef: 'main',
  htmlUrl: '',
  createdAt: DateTime(2026),
);
GitPrDetail _detail(int number) =>
    GitPrDetail(pr: _pr(number), comments: [], changedFiles: [], diff: '');

class _Service extends GitPullRequestService {
  final pending = <int, Completer<Result<GitPrDetail, String>>>{};
  @override
  Future<Result<List<GitPullRequest>, String>> listPullRequests(
    String repoRoot, {
    String state = 'open',
    int limit = 30,
  }) async => Success([_pr(1), _pr(2)]);
  @override
  Future<Result<GitPrDetail, String>> getPullRequestDetail(
    String repoRoot,
    int number,
  ) => (pending[number] = Completer<Result<GitPrDetail, String>>()).future;
}

Widget _wrap(double width, _Service service) {
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
              height: 600,
              child: GitPrReviewPanel(repoRoot: '/repo', service: service),
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'narrow review supports list, detail and return without overflow',
    (tester) async {
      final service = _Service();
      await tester.pumpWidget(_wrap(320, service));
      await tester.pump();
      service.pending[1]!.complete(Success(_detail(1)));
      await tester.pumpAndSettle();
      expect(find.text('Change 2'), findsOneWidget);
      expect(find.text('Description 1'), findsNothing);
      await tester.tap(find.text('Change 2'));
      await tester.pump();
      service.pending[2]!.complete(Success(_detail(2)));
      await tester.pumpAndSettle();
      expect(find.text('Description 2'), findsOneWidget);
      expect(find.text('Change 1'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('pr-review-back')));
      await tester.pumpAndSettle();
      expect(find.text('Change 1'), findsOneWidget);
      await tester.pumpWidget(_wrap(800, service));
      await tester.pumpAndSettle();
      expect(find.text('Change 1'), findsOneWidget);
      expect(find.text('Description 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('late detail cannot replace the currently selected PR', (
    tester,
  ) async {
    final service = _Service();
    await tester.pumpWidget(_wrap(800, service));
    await tester.pump();
    await tester.tap(find.text('Change 2'));
    await tester.pump();
    service.pending[2]!.complete(Success(_detail(2)));
    await tester.pumpAndSettle();
    service.pending[1]!.complete(Success(_detail(1)));
    await tester.pumpAndSettle();
    expect(find.text('#2 - Change 2'), findsOneWidget);
    expect(find.text('Description 2'), findsOneWidget);
    expect(find.text('Description 1'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
