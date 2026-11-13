class GitCommandLog {
  const GitCommandLog({
    required this.id,
    required this.root,
    required this.command,
    required this.startedAt,
    this.finishedAt,
    this.exitCode,
    this.lines = const [],
  });
  final int id;
  final String root;
  final String command;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final int? exitCode;
  final List<String> lines;
  bool get isRunning => finishedAt == null;
  GitCommandLog copyWith({
    DateTime? finishedAt,
    int? exitCode,
    List<String>? lines,
  }) => GitCommandLog(
    id: id,
    root: root,
    command: command,
    startedAt: startedAt,
    finishedAt: finishedAt ?? this.finishedAt,
    exitCode: exitCode ?? this.exitCode,
    lines: lines == null ? this.lines : List.unmodifiable(lines),
  );
}
