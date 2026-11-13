import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_graph_layout.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';

GitHistoryCommit c(String id, List<String> parents) => GitHistoryCommit(
  hash: id,
  parents: parents,
  refs: const [],
  subject: id,
  author: 'test',
  authoredAt: null,
);

void main() {
  test(
    'merge parents split into distinct lanes and converge on their ancestor',
    () {
      final rows = layoutGitGraph([
        c('merge', ['a', 'b']),
        c('a', ['base']),
        c('b', ['base']),
        c('base', []),
      ]);
      expect(rows[0].down.map((edge) => edge.to).toSet(), {0, 1});
      expect(rows[2].lane, 1);
      expect(
        rows[2].down.any((edge) => edge.from == 1 && edge.to == 0),
        isTrue,
      );
      expect(rows[3].lane, 0);
      expect(rows[3].down, isEmpty);
    },
  );
  test('unrelated roots do not get a fabricated connecting edge', () {
    final rows = layoutGitGraph([c('a', []), c('b', [])]);
    expect(rows.every((row) => row.up.isEmpty && row.down.isEmpty), isTrue);
  });
  test(
    'first-parent chain stays in one lane and duplicates are not drawn twice',
    () {
      final rows = layoutGitGraph([
        c('a', ['b', 'b']),
        c('b', ['c']),
        c('c', []),
      ]);
      expect(rows.map((row) => row.lane), [0, 0, 0]);
      expect(rows.first.down.length, 1);
      expect(layoutGitGraph([]), isEmpty);
    },
  );
}
