import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_history_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_workbench_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

GitHistoryCommit commit(String hash, List<String> parents) => GitHistoryCommit(
  hash: hash,
  parents: parents,
  refs: const [],
  subject: 'message $hash',
  author: 'Author',
  authoredAt: null,
);
Widget host(Widget child) => TranslationProvider(
  child: ShadcnApp(
    theme: buildTheme(brightness: Brightness.dark),
    home: Scaffold(child: SizedBox(width: 1100, height: 420, child: child)),
  ),
);

void main() {
  testWidgets(
    'graph rows open commit files and their diff in the same repository',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final opened = <String>[];
      await tester.pumpWidget(
        host(
          GitWorkbenchPanel(
            roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
            refreshToken: 0,
            loadHistory: (_, ref) async {
              expect(ref, isNull);
              return Success([
                commit('merge', ['a', 'b']),
                commit('a', []),
                commit('b', []),
              ]);
            },
            loadFiles: (root, hash) async => const Success([
              GitHistoryFileChange(status: 'M', path: 'lib/main.dart'),
            ]),
            onOpenFileDiff: (root, hash, file) async {
              opened.add('$root:$hash:${file.path}');
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('git-graph-merge')), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('git-log-commit-a')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('git-log-file-lib/main.dart')),
      );
      await tester.pumpAndSettle();
      expect(opened, ['/repo:a:lib/main.dart']);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('repository switch rejects an old history response', (
    tester,
  ) async {
    final pending =
        Completer<Result<List<GitHistoryCommit>, GitHistoryError>>();
    final roots = <String>[];
    Widget panel(String root, int revision) => host(
      GitWorkbenchPanel(
        roots: [GitHistoryRoot(path: root, name: root)],
        refreshToken: revision,
        loadHistory: (root, ref) {
          roots.add(root);
          return root == '/first'
              ? pending.future
              : Future.value(Success([commit('second', [])]));
        },
        loadFiles: (_, _) async => const Success([]),
        onOpenFileDiff: (_, _, _) async {},
      ),
    );
    await tester.pumpWidget(panel('/first', 0));
    await tester.pump();
    await tester.pumpWidget(panel('/second', 1));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('git-log-commit-second')), findsOneWidget);
    pending.complete(Success([commit('first', [])]));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('git-log-commit-first')), findsNothing);
    expect(find.byKey(const ValueKey('git-log-commit-second')), findsOneWidget);
    expect(roots, ['/first', '/second']);
  });

  testWidgets('revision change reloads history without waiting for polling', (
    tester,
  ) async {
    var loads = 0;
    Widget panel(int revision) => host(
      GitWorkbenchPanel(
        roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
        refreshToken: revision,
        loadHistory: (_, _) async => Success([commit('version${++loads}', [])]),
        loadFiles: (_, _) async => const Success([]),
        onOpenFileDiff: (_, _, _) async {},
      ),
    );
    await tester.pumpWidget(panel(0));
    await tester.pumpAndSettle();
    await tester.pumpWidget(panel(1));
    await tester.pumpAndSettle();
    expect(loads, 2);
    expect(
      find.byKey(const ValueKey('git-log-commit-version2')),
      findsOneWidget,
    );
  });
  testWidgets('small dock shows details without overflowing on long refs', (
    tester,
  ) async {
    const item = GitHistoryCommit(
      hash: 'hash',
      parents: [],
      refs: [
        'HEAD -> a/very/long/branch/reference',
        'origin/another/long/reference',
      ],
      subject: 'long subject',
      author: 'Author',
      authoredAt: null,
    );
    await tester.pumpWidget(
      TranslationProvider(
        child: ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: SizedBox(
              width: 320,
              height: 150,
              child: GitWorkbenchPanel(
                roots: const [
                  GitHistoryRoot(
                    path: '/repo',
                    name: 'a-very-long-repository-name-that-needs-clipping',
                  ),
                ],
                refreshToken: 0,
                loadHistory: (_, _) async => const Success([item]),
                loadFiles: (_, _) async => const Success([]),
                onOpenFileDiff: (_, _, _) async {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('git-log-commit-hash')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('git-log-close-details')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
