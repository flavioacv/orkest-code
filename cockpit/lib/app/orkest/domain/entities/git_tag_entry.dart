/// Entrada de tag Git (`git tag -l`).
class GitTagEntry {
  const GitTagEntry({
    required this.name,
    required this.commitHash,
    this.createdAt,
    this.message = '',
  });

  /// Nome da tag (ex.: `v1.0.0`).
  final String name;

  /// Hash abreviado do commit apontado pela tag.
  final String commitHash;

  /// Data e hora de criação da tag (se anotada).
  final DateTime? createdAt;

  /// Mensagem associada à tag (se anotada).
  final String message;

  /// Indica se a tag possui anotação explícita.
  bool get isAnnotated => message.isNotEmpty;
}
