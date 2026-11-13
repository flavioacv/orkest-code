import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_operation_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  testWidgets(
    'operation survives the last resolved file and allows continuation',
    (tester) async {
      final root = Directory.systemTemp.createTempSync('git-operation-ui-');
      addTearDown(() => root.deleteSync(recursive: true));
      Directory(p.join(root.path, '.git')).createSync();
      File(p.join(root.path, '.git', 'MERGE_HEAD')).writeAsStringSync('commit');
      final commands = <List<String>>[];
      String? opened;
      Future<void> render(GitInfo info) => tester.pumpWidget(
        TranslationProvider(
          child: ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: Scaffold(
              child: SizedBox(
                width: 320,
                child: GitOperationPanel(
                  root: root.path,
                  info: info,
                  onCommand: (args, _) async => commands.add(args),
                  onOpenFile: (path) => opened = path,
                ),
              ),
            ),
          ),
        ),
      );
      await render(
        const GitInfo(
          branch: 'feature',
          files: {'a.txt': GitFileStatus.conflict},
        ),
      );
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const ValueKey('git-integration-continue')),
            )
            .onPressed,
        isNull,
      );
      await tester.tap(find.byKey(const ValueKey('git-conflict-a.txt')));
      expect(opened, p.join(root.path, 'a.txt'));
      await render(const GitInfo(branch: 'feature'));
      expect(
        find.byKey(const ValueKey('git-integration-state')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<PrimaryButton>(
              find.byKey(const ValueKey('git-integration-continue')),
            )
            .onPressed,
        isNotNull,
      );
      await tester.tap(find.byKey(const ValueKey('git-integration-continue')));
      await tester.pump();
      expect(commands, [
        ['merge', '--continue'],
      ]);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
