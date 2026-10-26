/// Uma ref selecionável no seletor de branches.
class GitBranch {
  const GitBranch({
    required this.name,
    required this.isRemote,
    required this.isCurrent,
    this.isUsedByWorktree = false,
  });

  final String name;
  final bool isRemote;
  final bool isCurrent;
  final bool isUsedByWorktree;
}
