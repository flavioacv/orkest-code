/// Falha de uma operação de branches, sem texto de interface.
class GitBranchError implements Exception {
  const GitBranchError(this.kind, {this.detail});

  final GitBranchErrorKind kind;
  final String? detail;
}

enum GitBranchErrorKind {
  listFailed,
  invalidName,
  alreadyExists,
  dirtyWorktree,
  checkoutFailed,
  createFailed,
}
