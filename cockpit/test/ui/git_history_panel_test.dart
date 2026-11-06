import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_comparison.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_history_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Widget host(Widget child) {
    final tokens = buildTokens(brightness: Brightness.dark);
    return TranslationProvider(
      child: ShadcnApp(
        theme: buildTheme(
          brightness: Brightness.dark,
        ).copyWith(platform: () => TargetPlatform.windows),
        home: Scaffold(
          child: OrkestTheme(
            colors: tokens.colors,
            typo: tokens.typo,
            syntax: tokens.syntax,
            terminal: tokens.terminal,
            child: SizedBox(width: 400, height: 500, child: child),
          ),
        ),
      ),
    );
  }

  testWidgets('hidden history suspends polling and resumes when visible', (
    tester,
  ) async {
    var active = true;
    var loads = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return WorkbenchToolVisibility(
              active: active,
              child: GitHistoryPanel(
                roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
                refreshToken: 0,
                loadHistory: (_) async {
                  loads++;
                  return const Success([]);
                },
                loadFiles: (_, _) async => const Success([]),
                onOpenFileDiff: (_, _, _) async {},
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    final initial = loads;
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(loads, greaterThan(initial));
    rebuild(() => active = false);
    await tester.pump();
    final hidden = loads;
    await tester.pump(const Duration(seconds: 12));
    await tester.pump();
    expect(loads, hidden);
    rebuild(() => active = true);
    await tester.pump();
    await tester.pump(const Duration(seconds: 6));
    await tester.pump();
    expect(loads, greaterThan(hidden));
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('shows a compact timeline without raw parent hashes', (
    tester,
  ) async {
    final twoMinutesAgo = DateTime.now().subtract(const Duration(minutes: 2));
    GitHistoryFileChange? openedChange;
    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [
            GitHistoryRoot(path: '/repo', name: 'repo', branch: 'main'),
          ],
          refreshToken: 0,
          loadHistory: (_) async => Success([
            GitHistoryCommit(
              hash: 'aaaaaaaaaaaaaaaa',
              parents: ['bbbbbbbbbbbbbbbb'],
              refs: ['HEAD -> main'],
              subject: 'Merge feature',
              author: 'Ada',
              authoredAt: twoMinutesAgo,
            ),
          ]),
          loadFiles: (_, _) async => const Success([
            GitHistoryFileChange(status: 'M', path: 'lib/main.dart'),
            GitHistoryFileChange(
              status: 'R100',
              previousPath: 'old.dart',
              path: 'lib/widgets/new.dart',
            ),
            GitHistoryFileChange(status: 'A', path: 'lib/widgets/added.dart'),
          ]),
          onOpenFileDiff: (_, _, change) async => openedChange = change,
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Merge feature'), findsOneWidget);
    expect(find.text('HEAD -> main'), findsOneWidget);
    expect(find.textContaining('2m ago · Ada · aaaaaaaa'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('git-history-timeline-node')),
      findsOneWidget,
    );
    expect(find.textContaining('aaaaaaaaaaaaaaaa'), findsNothing);
    expect(find.textContaining('bbbbbbbbbbbbbbbb'), findsNothing);

    await tester.tap(find.text('Merge feature'));
    await tester.pump();
    expect(find.text('Files changed'), findsOneWidget);
    expect(find.text('main.dart - lib'), findsOneWidget);
    expect(find.text('new.dart - widgets'), findsOneWidget);
    expect(find.text('added.dart - widgets'), findsOneWidget);
    expect(
      tester.widget<Text>(find.text('A')).style?.color,
      buildTokens(brightness: Brightness.dark).colors.gitUntracked,
    );
    await tester.tap(find.text('main.dart - lib'));
    expect(openedChange?.path, 'lib/main.dart');
  });

  testWidgets(
    'keeps the latest root history when an older load completes late',
    (tester) async {
      final firstLoad =
          Completer<Result<List<GitHistoryCommit>, GitHistoryError>>();
      final calls = <String>[];

      GitHistoryPanel panel(String root, String name) => GitHistoryPanel(
        roots: [GitHistoryRoot(path: root, name: name, branch: 'main')],
        refreshToken: 0,
        loadHistory: (path) {
          calls.add(path);
          if (path == '/repo-a') return firstLoad.future;
          return Future.value(
            const Success([
              GitHistoryCommit(
                hash: 'bbbbbbbbbbbbbbbb',
                parents: [],
                refs: [],
                subject: 'Second repository commit',
                author: 'Ada',
                authoredAt: null,
              ),
            ]),
          );
        },
        loadFiles: (_, _) async => const Success([]),
        onOpenFileDiff: (_, _, _) async {},
      );

      await tester.pumpWidget(host(panel('/repo-a', 'repo-a')));
      await tester.pump();
      await tester.pumpWidget(host(panel('/repo-b', 'repo-b')));
      await tester.pump();
      expect(calls, [
        '/repo-a',
      ], reason: 'the newer root waits for single-flight');

      firstLoad.complete(
        const Success([
          GitHistoryCommit(
            hash: 'aaaaaaaaaaaaaaaa',
            parents: [],
            refs: [],
            subject: 'First repository commit',
            author: 'Ada',
            authoredAt: null,
          ),
        ]),
      );
      await tester.pump();
      await tester.pump();

      expect(calls, ['/repo-a', '/repo-b']);
      expect(find.text('Second repository commit'), findsOneWidget);
      expect(find.text('First repository commit'), findsNothing);
    },
  );

  testWidgets('periodic history load is single-flight with one rerun', (
    tester,
  ) async {
    final releases = <Completer<void>>[];
    var calls = 0;
    var concurrent = 0;
    var maxConcurrent = 0;

    Future<Result<List<GitHistoryCommit>, GitHistoryError>> load(
      String _,
    ) async {
      calls++;
      concurrent++;
      if (concurrent > maxConcurrent) maxConcurrent = concurrent;
      final release = Completer<void>();
      releases.add(release);
      await release.future;
      concurrent--;
      return const Success([]);
    }

    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
          refreshToken: 0,
          loadHistory: load,
          loadFiles: (_, _) async => const Success([]),
          onOpenFileDiff: (_, _, _) async {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 15));
    expect(calls, 1);

    releases.first.complete();
    await tester.pump();
    expect(calls, 2, reason: 'periodic burst schedules one rerun');

    await tester.pump(const Duration(seconds: 10));
    releases.last.complete();
    await tester.pump();
    expect(maxConcurrent, 1);
    expect(calls, 2, reason: 'calls during rerun do not schedule a third load');
  });

  testWidgets('pending history rerun is discarded when panel is disposed', (
    tester,
  ) async {
    final firstLoad =
        Completer<Result<List<GitHistoryCommit>, GitHistoryError>>();
    var calls = 0;
    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [GitHistoryRoot(path: '/repo', name: 'repo')],
          refreshToken: 0,
          loadHistory: (_) {
            calls++;
            return firstLoad.future;
          },
          loadFiles: (_, _) async => const Success([]),
          onOpenFileDiff: (_, _, _) async {},
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 5));
    expect(calls, 1, reason: 'the timer queued one coalesced rerun');

    await tester.pumpWidget(const SizedBox());
    firstLoad.complete(const Success([]));
    await tester.pump();

    expect(calls, 1, reason: 'dispose cancels the pending rerun');
    expect(tester.takeException(), isNull);
  });

  testWidgets('labels an empty commit subject instead of showing a blank row', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [
            GitHistoryRoot(path: '/repo', name: 'repo', branch: 'main'),
          ],
          refreshToken: 0,
          loadHistory: (_) async => const Success([
            GitHistoryCommit(
              hash: 'aaaaaaaaaaaaaaaa',
              parents: [],
              refs: [],
              subject: '',
              author: 'Ada',
              authoredAt: null,
            ),
          ]),
          loadFiles: (_, _) async => const Success([]),
          onOpenFileDiff: (_, _, _) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Untitled commit'), findsOneWidget);
  });

  testWidgets('uses the singular form for one day ago', (tester) async {
    final fortySevenHoursAgo = DateTime.now().subtract(
      const Duration(hours: 47),
    );
    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [
            GitHistoryRoot(path: '/repo', name: 'repo', branch: 'main'),
          ],
          refreshToken: 0,
          loadHistory: (_) async => Success([
            GitHistoryCommit(
              hash: 'aaaaaaaaaaaaaaaa',
              parents: [],
              refs: [],
              subject: 'Old commit',
              author: 'Ada',
              authoredAt: fortySevenHoursAgo,
            ),
          ]),
          loadFiles: (_, _) async => const Success([]),
          onOpenFileDiff: (_, _, _) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('1d ago'), findsOneWidget);
  });

  testWidgets('filters commits reactively by subject, author, or hash', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [
            GitHistoryRoot(path: '/repo', name: 'repo', branch: 'main'),
          ],
          refreshToken: 0,
          loadHistory: (_) async => const Success([
            GitHistoryCommit(
              hash: 'aaaa111122223333',
              parents: [],
              refs: [],
              subject: 'Fix payment crash',
              author: 'Ada Lovelace',
              authoredAt: null,
            ),
            GitHistoryCommit(
              hash: 'bbbb444455556666',
              parents: [],
              refs: [],
              subject: 'Add profile screen',
              author: 'Grace Hopper',
              authoredAt: null,
            ),
          ]),
          loadFiles: (_, _) async => const Success([]),
          onOpenFileDiff: (_, _, _) async {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Fix payment crash'), findsOneWidget);
    expect(find.text('Add profile screen'), findsOneWidget);

    final searchField = find.byKey(const ValueKey('git-history-search-input'));
    expect(searchField, findsOneWidget);

    await tester.enterText(searchField, 'payment');
    await tester.pump();
    expect(find.text('Fix payment crash'), findsOneWidget);
    expect(find.text('Add profile screen'), findsNothing);

    await tester.enterText(searchField, 'grace');
    await tester.pump();
    expect(find.text('Fix payment crash'), findsNothing);
    expect(find.text('Add profile screen'), findsOneWidget);

    await tester.enterText(searchField, 'aaaa1111');
    await tester.pump();
    expect(find.text('Fix payment crash'), findsOneWidget);
    expect(find.text('Add profile screen'), findsNothing);

    await tester.enterText(searchField, 'inexistente');
    await tester.pump();
    expect(find.text('Fix payment crash'), findsNothing);
    expect(find.text('Add profile screen'), findsNothing);
  });

  testWidgets('compares commit with head and navigates to file diff', (
    tester,
  ) async {
    final commit1 = const GitHistoryCommit(
      hash: 'aaaa111122223333',
      parents: [],
      refs: [],
      subject: 'Base commit',
      author: 'Ada',
      authoredAt: null,
    );
    final commit2 = const GitHistoryCommit(
      hash: 'bbbb222233334444',
      parents: ['aaaa111122223333'],
      refs: ['HEAD -> main'],
      subject: 'Head commit',
      author: 'Grace',
      authoredAt: null,
    );

    String? diffRoot;
    String? diffRef;
    GitHistoryFileChange? diffChange;

    await tester.pumpWidget(
      host(
        GitHistoryPanel(
          roots: const [
            GitHistoryRoot(path: '/repo', name: 'repo', branch: 'main'),
          ],
          refreshToken: 0,
          loadHistory: (_) async => Success([commit1]),
          loadFiles: (_, _) async => const Success([]),
          compareRefs: (root, baseRef, targetRef) async {
            return Success(
              GitComparison(
                baseRef: baseRef,
                targetRef: targetRef,
                commits: [commit2],
                changedFiles: const [
                  GitHistoryFileChange(status: 'M', path: 'lib/app.dart'),
                ],
              ),
            );
          },
          onOpenFileDiff: (root, ref, change) async {
            diffRoot = root;
            diffRef = ref;
            diffChange = change;
          },
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Base commit'), findsOneWidget);

    // Aciona o menu de contexto do commit com clique secundário
    await tester.tap(find.text('Base commit'), buttons: kSecondaryMouseButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Clica em "Comparar com HEAD"
    final compareItem = find.text('Compare with HEAD');
    expect(compareItem, findsOneWidget);
    await tester.tap(compareItem);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    // Valida exibição da tela de comparação
    expect(find.text('Revision comparison'), findsOneWidget);
    expect(find.text('Head commit'), findsOneWidget);
    expect(find.text('app.dart - lib'), findsOneWidget);

    // Clica no arquivo alterado
    await tester.tap(find.text('app.dart - lib'));
    await tester.pump();

    expect(diffRoot, '/repo');
    expect(diffRef, 'HEAD');
    expect(diffChange?.path, 'lib/app.dart');

    // Clica no botão voltar para retornar à timeline regular
    final backButton = find.byIcon(Icons.arrow_back);
    expect(backButton, findsOneWidget);
    await tester.tap(backButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.text('Base commit'), findsOneWidget);
    expect(find.text('Revision comparison'), findsNothing);
  });
}
