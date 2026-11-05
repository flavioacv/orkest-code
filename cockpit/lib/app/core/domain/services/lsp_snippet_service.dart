/// Resultado da expansão de um snippet LSP (L02).
class LspSnippetExpansion {
  const LspSnippetExpansion({
    required this.text,
    this.caretOffset,
  });

  /// Texto final limpo sem marcadores sintáticos do TextMate (${1:foo}, $0, etc.).
  final String text;

  /// Posição do cursor relativa ao início do texto expandido (onde o primeiro
  /// tabstop $1 ou $0 indicava foco).
  final int? caretOffset;
}

/// Serviço de processamento e expansão de snippets LSP (TextMate snippet syntax) (L02).
class LspSnippetService {
  const LspSnippetService();

  /// Converte um [snippet] LSP em texto limpo para inserção no editor,
  /// calculando o deslocamento de caret do primeiro tabstop ($1 ou $0).
  LspSnippetExpansion expand(String snippet) {
    if (!snippet.contains('\$')) {
      return LspSnippetExpansion(text: snippet);
    }

    final buffer = StringBuffer();
    int? firstCaret;
    var i = 0;
    final len = snippet.length;

    while (i < len) {
      final ch = snippet[i];
      if (ch == '\\' && i + 1 < len) {
        final next = snippet[i + 1];
        if (next == '\$' || next == '\\' || next == '}') {
          buffer.write(next);
          i += 2;
          continue;
        }
      }

      if (ch == '\$' && i + 1 < len) {
        final next = snippet[i + 1];

        // $0 ou $1..$9
        if (RegExp(r'^[0-9]$').hasMatch(next)) {
          final tabstop = int.parse(next);
          if (firstCaret == null || tabstop == 1) {
            firstCaret = buffer.length;
          }
          i += 2;
          continue;
        }

        // ${0} ou ${1:placeholder} ou ${1|choice1,choice2|}
        if (next == '{' && i + 2 < len) {
          final closeIndex = _findClosingBrace(snippet, i + 2);
          if (closeIndex != -1) {
            final content = snippet.substring(i + 2, closeIndex);
            final colonIndex = content.indexOf(':');
            final pipeIndex = content.indexOf('|');

            if (colonIndex != -1) {
              // ${1:placeholder}
              final tabstopStr = content.substring(0, colonIndex);
              final placeholder = content.substring(colonIndex + 1);
              final tabstop = int.tryParse(tabstopStr) ?? 0;
              if (firstCaret == null || tabstop == 1) {
                firstCaret = buffer.length;
              }
              // Expande recursivamente se houver placeholders aninhados
              final inner = expand(placeholder);
              buffer.write(inner.text);
            } else if (pipeIndex != -1) {
              // ${1|one,two|}
              final choices = content.substring(pipeIndex + 1);
              final endPipe = choices.indexOf('|');
              final firstChoice = endPipe != -1
                  ? choices.substring(0, endPipe).split(',').first
                  : choices.split(',').first;
              firstCaret ??= buffer.length;
              buffer.write(firstChoice);
            } else {
              // ${1}
              final tabstop = int.tryParse(content) ?? 0;
              if (firstCaret == null || tabstop == 1) {
                firstCaret = buffer.length;
              }
            }

            i = closeIndex + 1;
            continue;
          }
        }
      }

      buffer.write(ch);
      i++;
    }

    return LspSnippetExpansion(
      text: buffer.toString(),
      caretOffset: firstCaret,
    );
  }

  static int _findClosingBrace(String text, int start) {
    var depth = 1;
    for (var i = start; i < text.length; i++) {
      if (text[i] == '\\' && i + 1 < text.length) {
        i++;
        continue;
      }
      if (text[i] == '{') depth++;
      if (text[i] == '}') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}
