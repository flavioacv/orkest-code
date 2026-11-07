import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/ui/actions/pull_request_review_actions.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';

class _Vm implements OrkestViewModel {
  Project? project;
  bool hasGit = true;
  bool visible = false;
  final layouts = <String, WorkbenchLayoutState>{};
  @override
  Project? get selectedProject => project;
  @override
  bool get activeHasFileTree => project?.kind == WorkspaceKind.project;
  @override
  bool isGitRepo(String projectId) => hasGit;
  @override
  WorkbenchLayoutState workbenchLayout(String projectId) =>
      layouts[projectId] ?? const WorkbenchLayoutState();
  @override
  void setWorkbenchLayout(String projectId, WorkbenchLayoutState layout) =>
      layouts[projectId] = layout;
  @override
  void showTree() => visible = true;
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Project _project(String id) => Project(
  id: id,
  name: id,
  path: '/project/$id',
  colorValue: 0,
  createdAt: DateTime(2026),
);

void main() {
  test('review command reveals PRs and preserves other workspace layouts', () {
    final vm = _Vm()..project = _project('app');
    const previous = WorkbenchLayoutState(
      activeTool: WorkbenchToolId.database,
      isToolWindowCollapsed: true,
      isToolWindowMaximized: true,
    );
    vm.layouts['app'] = previous;
    vm.layouts['other'] = previous;
    final command = pullRequestReviewCommand(vm);
    expect(command.isEnabled, isTrue);
    expect(command.matches('git pull requests'), isTrue);
    command.onSelected();
    expect(vm.visible, isTrue);
    expect(vm.layouts['app']!.activeTool, WorkbenchToolId.sourceControl);
    expect(
      vm.layouts['app']!.sourceControlSection,
      SourceControlSection.pullRequests,
    );
    expect(vm.layouts['app']!.isToolWindowCollapsed, isFalse);
    expect(vm.layouts['app']!.isToolWindowMaximized, isTrue);
    expect(vm.layouts['other'], previous);
    command.onSelected();
    expect(vm.layouts.length, 2);
  });

  test('unsupported contexts expose a reason and never change layout', () {
    final vm = _Vm();
    for (final project in [
      null,
      Project.systemTerminal(),
      Project.remoteHost(
        pinId: 'pin',
        hostId: 'host',
        name: 'Remote',
        remotePath: '/repo',
        colorValue: 0,
      ),
      _project('no-git'),
    ]) {
      vm.project = project;
      vm.hasGit = false;
      final command = pullRequestReviewCommand(vm);
      expect(command.isEnabled, isFalse);
      expect(command.disabledReason, isNotEmpty);
      command.onSelected();
      expect(vm.visible, isFalse);
      expect(vm.layouts, isEmpty);
    }
  });

  test('palette callback revalidates context after workspace change', () {
    final vm = _Vm()..project = _project('app');
    final command = pullRequestReviewCommand(vm);
    vm.project = Project.systemTerminal();
    command.onSelected();
    expect(vm.layouts, isEmpty);
    expect(vm.visible, isFalse);
  });

  testWidgets(
    'shortcut works with consuming focus and rejects repeats or extra modifiers',
    (tester) async {
      final vm = _Vm()..project = _project('app');
      var calls = 0;
      bool handler(KeyEvent event) {
        if (!isPullRequestReviewShortcut(event)) return false;
        calls++;
        pullRequestReviewCommand(vm).onSelected();
        return true;
      }

      HardwareKeyboard.instance.addHandler(handler);
      addTearDown(() => HardwareKeyboard.instance.removeHandler(handler));
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Focus(
            focusNode: focus,
            autofocus: true,
            onKeyEvent: (_, _) => KeyEventResult.handled,
            child: const SizedBox(),
          ),
        ),
      );
      await tester.pump();
      for (final primary in [
        LogicalKeyboardKey.metaLeft,
        LogicalKeyboardKey.controlLeft,
      ]) {
        await tester.sendKeyDownEvent(primary);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyRepeatEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.altLeft);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
        await tester.sendKeyEvent(LogicalKeyboardKey.keyG);
        await tester.sendKeyUpEvent(primary);
      }
      expect(calls, 2);
      expect(vm.visible, isTrue);
      expect(
        vm.layouts['app']!.sourceControlSection,
        SourceControlSection.pullRequests,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
}
