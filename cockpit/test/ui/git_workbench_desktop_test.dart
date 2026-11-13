import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_workbench_view_state.dart';
import 'package:orkest_code/app/orkest/domain/entities/worktree.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_history_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_workbench_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_worktrees_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget host(Widget child) => TranslationProvider(
  child: ShadcnApp(
    theme: buildTheme(brightness: Brightness.dark),
    home: Scaffold(child: SizedBox(width: 1100, height: 420, child: child)),
  ),
);

void main() {
  testWidgets(
    'restored filters reach Git and details remain visible when empty',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final requests = <GitHistoryQuery>[];
      GitWorkbenchViewState? saved;
      await tester.pumpWidget(
        host(
          GitWorkbenchPanel(
            roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
            refreshToken: 0,
            initialState: const GitWorkbenchViewState(
              author: 'Flavio',
              sinceDays: 30,
            ),
            onStateChanged: (value) => saved = value,
            loadHistory: (_, _) async => const Success([]),
            loadFilteredHistory: (_, query) async {
              requests.add(query);
              return const Success([]);
            },
            loadFiles: (_, _) async => const Success([]),
            onOpenFileDiff: (_, _, _) async {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(requests.last.author, 'Flavio');
      expect(requests.last.since, isNotNull);
      expect(find.byKey(const ValueKey('git-details-empty')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('git-log-filters')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('git-author-input')),
        'Other',
      );
      await tester.tap(find.byKey(const ValueKey('git-date-7')));
      await tester.tap(find.byKey(const ValueKey('git-filters-apply')));
      await tester.pumpAndSettle();
      expect(requests.last.author, 'Other');
      expect(saved?.sinceDays, 7);
      expect(saved?.author, 'Other');
      final width = tester
          .getSize(find.byKey(const ValueKey('git-details-pane')))
          .width;
      await tester.drag(
        find.byKey(const ValueKey('git-resize-details')),
        const Offset(-60, 0),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(find.byKey(const ValueKey('git-details-pane'))).width,
        greaterThan(width),
      );
      expect(saved?.detailsFraction, greaterThan(.28));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'worktree switch rejects an old repository response and opens current path',
    (tester) async {
      final pending = Completer<List<Worktree>>();
      final opened = <String>[];
      Widget panel(String root) => host(
        GitWorktreesPanel(
          root: root,
          load: (root) => root == '/old'
              ? pending.future
              : Future.value([
                  const Worktree(
                    path: '/new-linked',
                    branch: 'feature',
                    isDetached: false,
                  ),
                ]),
          onOpen: (path) async => opened.add(path),
        ),
      );
      await tester.pumpWidget(panel('/old'));
      await tester.pump();
      await tester.pumpWidget(panel('/new'));
      await tester.pumpAndSettle();
      pending.complete([
        const Worktree(path: '/old-linked', branch: 'stale', isDetached: false),
      ]);
      await tester.pumpAndSettle();
      expect(find.text('stale'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('git-worktree-/new-linked')));
      await tester.pumpAndSettle();
      expect(opened, ['/new-linked']);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
