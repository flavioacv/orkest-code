/// Uma ref selecionável no seletor de branches.
class GitBranch {
  const GitBranch({
    required this.name,
    required this.isRemote,
    required this.isCurrent,
    this.isUsedByWorktree = false,
    this.upstream,
    this.trackingStatus,
    this.worktreePath,
  });

  final String name;
  final bool isRemote;
  final bool isCurrent;
  final bool isUsedByWorktree;
  final String? upstream;
  final String? trackingStatus;
  final String? worktreePath;

  String get ref => "${isRemote ? 'refs/remotes' : 'refs/heads'}/$name";
}
