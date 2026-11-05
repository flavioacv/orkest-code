/// Entrada de stash Git (`git stash list`).
class GitStashEntry {
  const GitStashEntry({
    required this.index,
    required this.commitHash,
    required this.relativeTime,
    required this.message,
  });

  /// Índice numérico do stash (ex.: `0` para `stash@{0}`).
  final int index;

  /// Hash abreviado do commit base do stash.
  final String commitHash;

  /// Tempo relativo da criação do stash (ex.: "2 hours ago").
  final String relativeTime;

  /// Mensagem ou descrição do stash.
  final String message;

  /// Referência Git padrão do stash (ex.: `stash@{0}`).
  String get stashRef => 'stash@{$index}';
}
