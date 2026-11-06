import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/ui/session/diff_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/widgets/diff_viewer.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  DiffViewerSession sessionWith(FileDiff diff) => DiffViewerSession(
    id: 'd1',
    projectId: 'p1',
    path: '/repo/a.txt',
    diff: diff,
  );

  Widget host(FileDiff diff, {double scale = 1, DiffViewerSession? session}) =>
      TranslationProvider(
        child: ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            // Box limitado (como um pane) — pega regressão de largura infinita.
            child: SizedBox(
              width: 400,
              height: 300,
              child: Builder(
                builder: (context) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: DiffViewer(session: session ?? sessionWith(diff)),
                ),
              ),
            ),
          ),
        ),
      );

  for (final scale in [1.0, 1.8]) {
    testWidgets(
      'navigation reveals offscreen hunks without filtering at scale $scale',
      (tester) async {
        final diff = FileDiff(
          path: '/repo/a.txt',
          kind: FileDiffKind.modified,
          hunks: [
            for (var hunk = 0; hunk < 3; hunk++)
              DiffHunk(
                header: '@@ -${hunk * 80 + 1},35 +${hunk * 80 + 1},35 @@',
                lines: [
                  for (var line = 0; line < (hunk == 2 ? 2 : 70); line++)
                    DiffLine(
                      kind: line < 35
                          ? DiffLineKind.removed
                          : DiffLineKind.added,
                      text: 'hunk $hunk line $line',
                      oldLine: line < 35 ? hunk * 80 + line + 1 : null,
                      newLine: line >= 35 ? hunk * 80 + line - 34 : null,
                    ),
                ],
              ),
          ],
        );
        await tester.pumpWidget(host(diff, scale: scale));
        await tester.pumpAndSettle();
        final count = tester
            .widget<ListView>(find.byType(ListView))
            .childrenDelegate
            .estimatedChildCount;
        expect(find.byKey(const ValueKey('diff-hunk-2')), findsNothing);
        for (var i = 0; i < 3; i++) {
          if (i == 1) {
            await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
            await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
            await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
          } else {
            await tester.tap(find.byKey(const ValueKey('diff-next-hunk')));
          }
          await tester.pumpAndSettle();
          expect(
            find.byKey(ValueKey('diff-hunk-$i')).hitTestable(),
            findsOneWidget,
          );
          expect(find.text('${i + 1} / 3'), findsOneWidget);
          expect(
            tester
                .widget<ListView>(find.byType(ListView))
                .childrenDelegate
                .estimatedChildCount,
            count,
          );
        }
        await tester.tap(find.byKey(const ValueKey('diff-previous-hunk')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('diff-hunk-1')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('diff-layout-toggle')));
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<ListView>(find.byType(ListView))
              .childrenDelegate
              .estimatedChildCount,
          greaterThan(count!),
        );
        expect(
          find.byKey(const ValueKey('diff-hunk-1')).hitTestable(),
          findsOneWidget,
        );
        await tester.tap(find.byKey(const ValueKey('diff-overview')));
        await tester.pumpAndSettle();
        expect(
          find.byKey(const ValueKey('diff-hunk-0')).hitTestable(),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('reused preview session resets navigation after a shorter diff', (
    tester,
  ) async {
    final large = FileDiff(
      path: '/repo/a.txt',
      kind: FileDiffKind.modified,
      hunks: [
        for (var i = 0; i < 3; i++)
          DiffHunk(
            header: '@@ -$i,0 +$i,30 @@',
            lines: [
              for (var line = 0; line < 30; line++)
                DiffLine(
                  kind: DiffLineKind.added,
                  text: 'line $i/$line',
                  newLine: line + 1,
                ),
            ],
          ),
      ],
    );
    final session = sessionWith(large);
    await tester.pumpWidget(host(large, session: session));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('diff-previous-hunk')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('diff-hunk-2')).hitTestable(),
      findsOneWidget,
    );
    final small = FileDiff(
      path: '/repo/b.txt',
      kind: FileDiffKind.modified,
      hunks: [large.hunks.first],
    );
    session.diff = small;
    await tester.pumpWidget(host(small, session: session));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('diff-hunk-0')).hitTestable(),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'unified diff preserves removal/addition order and context once',
    (tester) async {
      await tester.pumpWidget(
        host(
          const FileDiff(
            path: '/repo/a.txt',
            kind: FileDiffKind.modified,
            hunks: [
              DiffHunk(
                header: '@@ -1,2 +1,2 @@',
                lines: [
                  DiffLine(
                    kind: DiffLineKind.context,
                    text: 'context',
                    oldLine: 1,
                    newLine: 1,
                  ),
                  DiffLine(
                    kind: DiffLineKind.removed,
                    text: 'before',
                    oldLine: 2,
                  ),
                  DiffLine(kind: DiffLineKind.added, text: 'after', newLine: 2),
                ],
              ),
            ],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('context'), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('diff-layout-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('context'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('before')).dy,
        lessThan(tester.getTopLeft(find.text('after')).dy),
      );
      await tester.tap(find.byKey(const ValueKey('diff-layout-toggle')));
      await tester.pumpAndSettle();
      expect(find.text('context'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('modified diff renderiza sem exceção de layout', (tester) async {
    final diff = FileDiff(
      path: '/repo/a.txt',
      kind: FileDiffKind.modified,
      beforeRevision: '1111111111111111',
      afterRevision: '2222222222222222',
      hunks: const [
        DiffHunk(
          header: '@@ -1,3 +1,3 @@',
          lines: [
            DiffLine(
              kind: DiffLineKind.context,
              text: 'line1',
              oldLine: 1,
              newLine: 1,
            ),
            DiffLine(kind: DiffLineKind.removed, text: 'line2', oldLine: 2),
            DiffLine(kind: DiffLineKind.added, text: 'CHANGED', newLine: 2),
            DiffLine(
              kind: DiffLineKind.context,
              text: 'line3',
              oldLine: 3,
              newLine: 3,
            ),
          ],
        ),
      ],
    );
    await tester.pumpWidget(host(diff));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('CHANGED'), findsOneWidget);
    expect(find.text('line2'), findsOneWidget);
    expect(find.text('Original 11111111'), findsOneWidget);
    expect(find.text('Modified 22222222'), findsOneWidget);
    expect(find.text('repo'), findsOneWidget);
    expect(find.text('a.txt'), findsOneWidget);
  });

  testWidgets('binário mostra mensagem', (tester) async {
    await tester.pumpWidget(host(const FileDiff.binary('/repo/bin.dat')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Binary file'), findsOneWidget);
  });

  testWidgets('binário histórico mantém as refs da comparação', (tester) async {
    await tester.pumpWidget(
      host(
        const FileDiff(
          path: '/repo/bin.dat',
          kind: FileDiffKind.binary,
          beforeRevision: '1111111111111111',
          afterRevision: '2222222222222222',
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Original 11111111'), findsOneWidget);
    expect(find.text('Modified 22222222'), findsOneWidget);
  });

  testWidgets('unchanged mostra No changes', (tester) async {
    await tester.pumpWidget(host(const FileDiff.unchanged('/repo/a.txt')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No changes.'), findsOneWidget);
  });
}
