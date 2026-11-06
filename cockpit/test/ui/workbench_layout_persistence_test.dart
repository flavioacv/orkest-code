import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/setup/json_state_store.dart';
import 'package:orkest_code/app/orkest/data/repositories/json_workspace_layout_store.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';

void main() {
  test('old and malformed layouts use safe tool defaults', () {
    for (final input in [
      null,
      12,
      <String, Object?>{},
      {'activeTool': 'future', 'sourceControlSection': []},
    ]) {
      expect(
        WorkbenchLayoutState.fromJson(input),
        const WorkbenchLayoutState(),
      );
    }
  });

  test('persists and restores collapsed and maximized tool window state', () {
    const layout = WorkbenchLayoutState(
      activeTool: WorkbenchToolId.database,
      sourceControlSection: SourceControlSection.changes,
      isToolWindowCollapsed: true,
      isToolWindowMaximized: true,
    );
    final json = layout.toJson();
    expect(json['isToolWindowCollapsed'], isTrue);
    expect(json['isToolWindowMaximized'], isTrue);

    final restored = WorkbenchLayoutState.fromJson(json);
    expect(restored.isToolWindowCollapsed, isTrue);
    expect(restored.isToolWindowMaximized, isTrue);
    expect(restored, layout);

    final toggled = restored.copyWith(isToolWindowCollapsed: false);
    expect(toggled.isToolWindowCollapsed, isFalse);
    expect(toggled.isToolWindowMaximized, isTrue);
  });

  test(
    'workspace tools survive store reopening without changing pane sessions',
    () async {
      final dir = await Directory.systemTemp.createTemp('workbench_layout');
      try {
        final store = JsonWorkspaceLayoutStore(
          await JsonStateStore.open(dir.path, 'layouts'),
        );
        const git = WorkbenchLayoutState(
          activeTool: WorkbenchToolId.sourceControl,
          sourceControlSection: SourceControlSection.history,
        );
        const database = WorkbenchLayoutState(
          activeTool: WorkbenchToolId.database,
        );
        await store.save('local', {
          'v': 1,
          'workbench': git.toJson(),
          'sessions': {
            't1': {'type': 'terminal'},
          },
        });
        await store.save('remote', {'v': 1, 'workbench': database.toJson()});
        JsonStateStore.resetCacheForTesting();
        final reopened = JsonWorkspaceLayoutStore(
          await JsonStateStore.open(dir.path, 'layouts'),
        );
        final local = await reopened.load('local');
        final remote = await reopened.load('remote');
        expect(WorkbenchLayoutState.fromJson(local?['workbench']), git);
        expect(WorkbenchLayoutState.fromJson(remote?['workbench']), database);
        expect(local?['sessions'], {
          't1': {'type': 'terminal'},
        });
        expect(
          WorkbenchLayoutState.fromJson(
            (await reopened.load('missing'))?['workbench'],
          ),
          const WorkbenchLayoutState(),
        );
      } finally {
        JsonStateStore.resetCacheForTesting();
        await dir.delete(recursive: true);
      }
    },
  );
}
