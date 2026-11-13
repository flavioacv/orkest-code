import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_tag_entry.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_branch_picker.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class _Git extends Fake implements GitController {
  @override
  Future<Result<List<GitBranch>, GitBranchError>> branches(
    String root,
  ) async => const Success([
    GitBranch(name: 'main', isCurrent: true, isRemote: false),
    GitBranch(name: 'origin/feature/login', isCurrent: false, isRemote: true),
  ]);
  @override
  Future<Result<List<GitTagEntry>, String>> listTags(String root) async =>
      const Success([GitTagEntry(name: 'v1.0', commitHash: 'abc')]);
}

void main() {
  testWidgets(
    'collapsed remote prefixes reopen for search and tags select exact refs',
    (tester) async {
      final git = _Git();
      Set<String>? saved;
      String? selected;
      await tester.pumpWidget(
        TranslationProvider(
          child: ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: Scaffold(
              child: SizedBox(
                width: 400,
                height: 550,
                child: GitBranchesPanel(
                  root: '/repo',
                  git: git,
                  includeTags: true,
                  initialCollapsed: const {'/repo|g2/origin'},
                  onCollapsedChanged: (value) => saved = value,
                  onSelectRef: (value) => selected = value,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('branch-refs/remotes/origin/feature/login')),
        findsNothing,
      );
      await tester.enterText(find.byType(TextField), 'login');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('branch-refs/remotes/origin/feature/login')),
        findsOneWidget,
      );
      await tester.enterText(find.byType(TextField), '');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('git-folder-g2/origin')));
      await tester.pumpAndSettle();
      expect(saved, isNot(contains('/repo|g2/origin')));
      await tester.ensureVisible(find.byKey(const ValueKey('git-tag-v1.0')));
      await tester.tap(find.byKey(const ValueKey('git-tag-v1.0')));
      expect(selected, 'refs/tags/v1.0');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
