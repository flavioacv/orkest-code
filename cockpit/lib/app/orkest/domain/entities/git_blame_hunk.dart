/// Informações estruturadas de autoria (`git blame`) para um bloco de linhas.
class GitBlameHunk {
  const GitBlameHunk({
    required this.commitHash,
    required this.author,
    required this.authorEmail,
    required this.authorTime,
    required this.summary,
    required this.originalLine,
    required this.finalLine,
    required this.lineCount,
    this.lines = const [],
  });

  /// Hash completo SHA-1 do commit autor.
  final String commitHash;

  /// Nome do autor.
  final String author;

  /// Email do autor.
  final String authorEmail;

  /// Data e hora do commit de autoria.
  final DateTime authorTime;

  /// Mensagem de sumário do commit.
  final String summary;

  /// Número da linha inicial no arquivo original no momento do commit (base 1).
  final int originalLine;

  /// Número da linha inicial na versão final do arquivo inspecionado (base 1).
  final int finalLine;

  /// Quantidade de linhas contíguas pertencentes a este bloco.
  final int lineCount;

  /// Linhas de texto correspondentes a este bloco no arquivo atual.
  final List<String> lines;

  /// Hash abreviado de 8 caracteres para exibição em gutters e UI.
  String get shortHash =>
      commitHash.length >= 8 ? commitHash.substring(0, 8) : commitHash;

  /// Verifica se uma linha específica (base 1) pertence a este bloco de autoria.
  bool containsLine(int lineNumber) =>
      lineNumber >= finalLine && lineNumber < finalLine + lineCount;
}
