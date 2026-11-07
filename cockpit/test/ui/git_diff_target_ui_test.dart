import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_diff_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/ui/session/diff_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/widgets/diff_viewer.dart';
import 'package:orkest_code/app/orkest/ui/widgets/file_tree_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';

Widget _wrap(Widget child) => TranslationProvider(
  child: ShadcnApp(
    theme: buildTheme(brightness: Brightness.dark),
    home: Scaffold(child: child),
  ),
);
void main() {
  for (final mode in SourceControlViewMode.values) {
    testWidgets('staged and working tree keep distinct callbacks in $mode', (
      tester,
    ) async {
      final calls = <String>[];
      await tester.pumpWidget(
        _wrap(
          FileTreePanel(
            rootPath: '/workspace',
            revision: 0,
            sourceControlViewMode: mode,
            workbenchLayout: const WorkbenchLayoutState(
              activeTool: WorkbenchToolId.sourceControl,
            ),
            listChildren: (_) async => const [],
            gitStatusOf: (_) => GitFileStatus.modified,
            onOpenFile: (_) {},
            onOpenDiff: (path) => calls.add('working pin:$path'),
            onTapDiff: (path) => calls.add('working preview:$path'),
            onOpenStagedDiff: (path) => calls.add('index pin:$path'),
            onTapStagedDiff: (path) => calls.add('index preview:$path'),
            isGitRepo: true,
            changedPaths: const ['/workspace/file.dart'],
            stagedPaths: const ['/workspace/file.dart'],
            unstagedPaths: const ['/workspace/file.dart'],
            onOpenWith: (_) {},
            onCreateInFolder: (_, {command}) {},
            onCreate: (_, _, _) async => const Success(null),
            onRename: (_, _) async => const Success(null),
            onDelete: (_) async => const Success(null),
            onMove: (_, _) async => const Success(null),
            onCopy: (_) {},
            onCut: (_) {},
            onPaste: (_) async => const Success(null),
            canPaste: false,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('file.dart'), findsNWidgets(2));
      await tester.tap(find.text('file.dart').first);
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('file.dart').last);
      await tester.pump(const Duration(milliseconds: 350));
      expect(calls, [
        'index preview:/workspace/file.dart',
        'working preview:/workspace/file.dart',
      ]);
      calls.clear();
      for (final finder in [
        find.text('file.dart').first,
        find.text('file.dart').last,
      ]) {
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 50));
        await tester.tap(finder);
        await tester.pump(const Duration(milliseconds: 350));
      }
      expect(calls.where((call) => call.contains(' pin:')).toList(), [
        'index pin:/workspace/file.dart',
        'working pin:/workspace/file.dart',
      ]);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }

  for (final target in [GitDiffTarget.staged, GitDiffTarget.workingTree]) {
    testWidgets('diff header identifies $target with Index', (tester) async {
      final session = DiffViewerSession(
        id: 'diff',
        projectId: 'app',
        path: '/repo/file.dart',
        target: target,
        diff: const FileDiff(
          path: '/repo/file.dart',
          kind: FileDiffKind.modified,
          hunks: [
            DiffHunk(
              header: '@@ -1 +1 @@',
              lines: [
                DiffLine(kind: DiffLineKind.added, text: 'new', newLine: 1),
              ],
            ),
          ],
        ),
      );
      addTearDown(session.dispose);
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 800,
            height: 400,
            child: DiffViewer(session: session),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Index'), findsOneWidget);
      if (target == GitDiffTarget.staged) {
        expect(find.text('HEAD'), findsOneWidget);
        expect(find.text('Working tree'), findsNothing);
      } else {
        expect(find.text('HEAD'), findsNothing);
        expect(find.text('Working tree'), findsOneWidget);
      }
      expect(session.isStaged, target == GitDiffTarget.staged);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
