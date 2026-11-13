/// Uma ref selecionável no seletor de branches.
class GitBranch {
  const GitBranch({
    required this.name,
    required this.isRemote,
    required this.isCurrent,
    this.isUsedByWorktree = false,
    this.upstream,
    this.trackingStatus,
  });

  final String name;
  final bool isRemote;
  final bool isCurrent;
  final bool isUsedByWorktree;
  final String? upstream;
  final String? trackingStatus;
}
