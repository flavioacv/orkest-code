/// Representa um link clicável detectado na saída de console do terminal.
class ConsoleLinkSpan {
  const ConsoleLinkSpan({
    required this.start,
    required this.end,
    required this.filePath,
    required this.line,
    this.column,
  });

  /// Offset de início na linha ou buffer.
  final int start;

  /// Offset final na linha ou buffer.
  final int end;

  /// Caminho do arquivo referenciado.
  final String filePath;

  /// Linha de destino (base 1).
  final int line;

  /// Coluna de destino opcional (base 1).
  final int? column;
}

/// Detecta links clicáveis de arquivos, testes e stack traces na saída do terminal.
class ConsoleLinkMatcher {
  const ConsoleLinkMatcher();

  // Padrão 1: URI explícita file:///path/to/file.ext:line[:col]
  static final RegExp _fileUriPattern = RegExp(
    r'file://([^\s:\(\)]+):(\d+)(?::(\d+))?',
  );

  // Padrão 2: path/to/file.ext:line[:col] (comum em compiladores e linters)
  static final RegExp _standardPathPattern = RegExp(
    r"""(?:^|[\s\(\[\'"])((?:[a-zA-Z]:[\\/]|/|[a-zA-Z0-9_\-\.]+[/])[a-zA-Z0-9_\-\./\\]+\.[a-zA-Z0-9]+):(\d+)(?::(\d+))?""",
  );

  // Padrão 3: Formato do Dart test runner: "test/foo_test.dart 42:15"
  static final RegExp _dartTestPattern = RegExp(
    r'(?:^|[\s])((?:test[/])[a-zA-Z0-9_\-\./\\]+_test\.dart)\s+(\d+):(\d+)',
  );

  /// Localiza todos os links para arquivos e linhas presentes no texto [lineText].
  List<ConsoleLinkSpan> matchLinks(String lineText) {
    if (lineText.isEmpty) return const [];

    final links = <ConsoleLinkSpan>[];

    // 1. File URIs
    for (final match in _fileUriPattern.allMatches(lineText)) {
      final path = match.group(1);
      final lineStr = match.group(2);
      final colStr = match.group(3);

      if (path != null && lineStr != null) {
        final line = int.tryParse(lineStr);
        final col = colStr != null ? int.tryParse(colStr) : null;
        if (line != null) {
          links.add(
            ConsoleLinkSpan(
              start: match.start,
              end: match.end,
              filePath: path,
              line: line,
              column: col,
            ),
          );
        }
      }
    }

    // 2. Standard Paths (path:line[:col])
    for (final match in _standardPathPattern.allMatches(lineText)) {
      final path = match.group(1);
      final lineStr = match.group(2);
      final colStr = match.group(3);

      if (path != null && lineStr != null) {
        final line = int.tryParse(lineStr);
        final col = colStr != null ? int.tryParse(colStr) : null;

        // Calcula offset exato excluindo pontuação de prefixo
        final matchText = match.group(0)!;
        final prefixLen = matchText.indexOf(path);
        final start = match.start + prefixLen;
        final end = start + path.length + 1 + lineStr.length + (colStr != null ? 1 + colStr.length : 0);

        if (line != null && !_overlaps(links, start, end)) {
          links.add(
            ConsoleLinkSpan(
              start: start,
              end: end,
              filePath: path,
              line: line,
              column: col,
            ),
          );
        }
      }
    }

    // 3. Dart test format
    for (final match in _dartTestPattern.allMatches(lineText)) {
      final path = match.group(1);
      final lineStr = match.group(2);
      final colStr = match.group(3);

      if (path != null && lineStr != null) {
        final line = int.tryParse(lineStr);
        final col = colStr != null ? int.tryParse(colStr) : null;

        final matchText = match.group(0)!;
        final prefixLen = matchText.indexOf(path);
        final start = match.start + prefixLen;
        final end = match.end;

        if (line != null && !_overlaps(links, start, end)) {
          links.add(
            ConsoleLinkSpan(
              start: start,
              end: end,
              filePath: path,
              line: line,
              column: col,
            ),
          );
        }
      }
    }

    links.sort((a, b) => a.start.compareTo(b.start));
    return links;
  }

  bool _overlaps(List<ConsoleLinkSpan> existing, int start, int end) {
    for (final span in existing) {
      if (start < span.end && end > span.start) return true;
    }
    return false;
  }
}
