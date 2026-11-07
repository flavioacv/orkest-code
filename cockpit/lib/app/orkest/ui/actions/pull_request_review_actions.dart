import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:orkest_code/app/core/ui/commands/command_item.dart';
import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';

const _shortcuts = [
  SingleActivator(LogicalKeyboardKey.keyG, meta: true, shift: true),
  SingleActivator(LogicalKeyboardKey.keyG, control: true, shift: true),
];

bool isPullRequestReviewShortcut(KeyEvent event) =>
    event is KeyDownEvent &&
    _shortcuts.any(
      (shortcut) => shortcut.accepts(event, HardwareKeyboard.instance),
    );

AppCommandItem pullRequestReviewCommand(OrkestViewModel vm) {
  String? unavailableReason() {
    final project = vm.selectedProject;
    if (project == null || project.kind != WorkspaceKind.project) {
      return 'Requer um workspace local de projeto';
    }
    if (!vm.activeHasFileTree || !vm.isGitRepo(project.id)) {
      return 'Requer um repositório Git no workspace';
    }
    return null;
  }

  final reason = unavailableReason();
  return AppCommandItem(
    id: 'git.reviewPullRequests',
    title: 'Review Pull Requests',
    category: 'Git',
    shortcutHint: defaultTargetPlatform == TargetPlatform.macOS
        ? '⇧⌘G'
        : 'Ctrl+Shift+G',
    isEnabled: reason == null,
    disabledReason: reason,
    onSelected: () {
      // Revalidate because the workspace can change while the palette is open.
      if (unavailableReason() != null) return;
      final id = vm.selectedProject!.id;
      vm.setWorkbenchLayout(
        id,
        vm
            .workbenchLayout(id)
            .copyWith(
              activeTool: WorkbenchToolId.sourceControl,
              sourceControlSection: SourceControlSection.pullRequests,
              isToolWindowCollapsed: false,
            ),
      );
      vm.showTree();
    },
  );
}
