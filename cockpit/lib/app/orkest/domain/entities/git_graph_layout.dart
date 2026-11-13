import 'git_history_commit.dart';

class GitGraphSegment {
  const GitGraphSegment(this.from, this.to);
  final int from;
  final int to;
}

class GitGraphRow {
  const GitGraphRow({
    required this.lane,
    required this.width,
    required this.up,
    required this.down,
  });
  final int lane;
  final int width;
  final List<GitGraphSegment> up;
  final List<GitGraphSegment> down;
}

// Commits must be in topological order: a child is visited before its parents.
List<GitGraphRow> layoutGitGraph(List<GitHistoryCommit> commits) {
  final lanes = <String?>[];
  final rows = <GitGraphRow>[];
  int reserve(String hash) {
    final existing = lanes.indexOf(hash);
    if (existing >= 0) return existing;
    final free = lanes.indexOf(null);
    if (free >= 0) {
      lanes[free] = hash;
      return free;
    }
    lanes.add(hash);
    return lanes.length - 1;
  }

  for (final commit in commits) {
    final before = List<String?>.of(lanes);
    final lane = reserve(commit.hash);
    final up = [
      for (var i = 0; i < before.length; i++)
        if (before[i] != null) GitGraphSegment(i, i),
    ];
    lanes[lane] = null;
    final down = <GitGraphSegment>[];
    for (final parent in commit.parents.toSet()) {
      final parentLane = reserve(parent);
      down.add(GitGraphSegment(lane, parentLane));
    }
    for (var i = 0; i < before.length; i++) {
      if (before[i] != null && before[i] != commit.hash) {
        down.add(GitGraphSegment(i, i));
      }
    }
    final width = [
      before.length,
      lanes.length,
      lane + 1,
    ].reduce((a, b) => a > b ? a : b);
    rows.add(GitGraphRow(lane: lane, width: width, up: up, down: down));
    while (lanes.isNotEmpty && lanes.last == null) {
      lanes.removeLast();
    }
  }
  return rows;
}
