import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_workbench_view_state.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';

void main() {
  test('workspace layout restores Git selection, filters and split widths', () {
    const view = GitWorkbenchViewState(
      tab: GitWorkbenchTab.worktrees,
      root: '/repo',
      ref: 'origin/feature',
      query: 'fix',
      author: 'Flavio',
      sinceDays: 30,
      selectedHash: 'abc123',
      branchFraction: .24,
      detailsFraction: .32,
      collapsed: {'/repo|remote/origin', '/repo|local/feature'},
    );
    const layout = WorkbenchLayoutState(gitView: view);
    expect(WorkbenchLayoutState.fromJson(layout.toJson()), layout);
    expect(const WorkbenchLayoutState().gitView, const GitWorkbenchViewState());
    expect(view.copyWith(ref: '', author: '').ref, isEmpty);
  });

  test('malformed stored Git state falls back without invalid casts', () {
    for (final value in [null, 7.0, '30', [], -1]) {
      final state = GitWorkbenchViewState.fromJson({
        'sinceDays': value,
        'tab': 'unknown',
        'root': 12,
        'collapsed': ['valid', 4],
        'branchFraction': double.nan,
        'detailsFraction': double.infinity,
      });
      expect(state.sinceDays, 0);
      expect(state.tab, GitWorkbenchTab.log);
      expect(state.root, '');
      expect(state.collapsed, {'valid'});
      expect(state.branchFraction, .18);
      expect(state.detailsFraction, .28);
    }
    final clamped = GitWorkbenchViewState.fromJson({
      'branchFraction': -10,
      'detailsFraction': 20,
    });
    expect(clamped.branchFraction, .12);
    expect(clamped.detailsFraction, .4);
  });
}
