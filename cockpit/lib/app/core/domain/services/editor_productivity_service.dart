import '../entities/editor_productivity.dart';

/// Serviço de expansão de sintaxe abreviada Emmet (X01).
class EmmetAbbreviationService {
  const EmmetAbbreviationService();

  /// Expande uma abreviação Emmet [abbreviation] em marcação estruturada.
  ///
  /// Suporta:
  /// - Aninhamento (`>`): `div>ul>li`
  /// - Irmãos (`+`): `header+main+footer`
  /// - Multiplicação (`*`): `li*3`
  /// - Classes (`.`): `div.container.fluid`
  /// - Identificadores (`#`): `section#hero`
  /// - Texto interno (`{}`): `a{Link}`
  /// - Atributos (`[]`): `input[type="text" placeholder="Nome"]`
  String expand(
    String abbreviation, {
    String language = 'html',
    int indentSpaces = 2,
  }) {
    final trimmed = abbreviation.trim();
    if (trimmed.isEmpty) return '';

    // Separa por irmãos de nível superior (+)
    final siblingTokens = _splitTopLevel(trimmed, '+');
    final buffer = StringBuffer();

    for (var i = 0; i < siblingTokens.length; i++) {
      final rendered = _renderToken(siblingTokens[i], indentLevel: 0, indentSpaces: indentSpaces);
      buffer.write(rendered);
      if (i < siblingTokens.length - 1) {
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  String _renderToken(String token, {required int indentLevel, required int indentSpaces}) {
    // 1. Verifica aninhamento de nível superior (>): ex. div>ul>li
    final childIndex = _findTopLevelChar(token, '>');
    if (childIndex != -1) {
      final parentPart = token.substring(0, childIndex);
      final childPart = token.substring(childIndex + 1);

      final parentTag = _parseTagSpec(parentPart);
      final indent = ' ' * (indentLevel * indentSpaces);

      final renderedChild = _renderToken(
        childPart,
        indentLevel: indentLevel + 1,
        indentSpaces: indentSpaces,
      );

      final isSelfClosing = _isSelfClosing(parentTag.name);
      if (isSelfClosing) {
        return '$indent<${parentTag.openTagString} />\n$renderedChild';
      }

      return '$indent<${parentTag.openTagString}>\n'
          '$renderedChild\n'
          '$indent</${parentTag.name}>';
    }

    // 2. Verifica multiplicação: ex. li*3 ou li*3{Item}
    final multMatch = RegExp(r'\*(\d+)').firstMatch(token);
    if (multMatch != null) {
      final count = int.parse(multMatch.group(1)!);
      if (count > 0) {
        final base = token.replaceFirst(multMatch.group(0)!, '');
        final buffer = StringBuffer();
        for (var i = 0; i < count; i++) {
          final res = _renderToken(base, indentLevel: indentLevel, indentSpaces: indentSpaces);
          buffer.write(res);
          if (i < count - 1) buffer.writeln();
        }
        return buffer.toString();
      }
    }

    // 3. Tag simples
    final tagSpec = _parseTagSpec(token);
    final indent = ' ' * (indentLevel * indentSpaces);
    final isSelfClosing = _isSelfClosing(tagSpec.name);

    if (isSelfClosing) {
      return '$indent<${tagSpec.openTagString} />';
    }

    if (tagSpec.textContent != null && tagSpec.textContent!.isNotEmpty) {
      return '$indent<${tagSpec.openTagString}>${tagSpec.textContent}</${tagSpec.name}>';
    }

    return '$indent<${tagSpec.openTagString}></${tagSpec.name}>';
  }

  int _findTopLevelChar(String input, String target) {
    var bracketDepth = 0;
    var braceDepth = 0;
    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '[') bracketDepth++;
      if (ch == ']') bracketDepth = bracketDepth > 0 ? bracketDepth - 1 : 0;
      if (ch == '{') braceDepth++;
      if (ch == '}') braceDepth = braceDepth > 0 ? braceDepth - 1 : 0;

      if (ch == target && bracketDepth == 0 && braceDepth == 0) {
        return i;
      }
    }
    return -1;
  }

  bool _isSelfClosing(String tag) {
    const selfClosingTags = {'img', 'input', 'br', 'hr', 'meta', 'link'};
    return selfClosingTags.contains(tag.toLowerCase());
  }

  _TagSpec _parseTagSpec(String raw) {
    var textContent = '';
    var working = raw;

    // Extrai texto entre {} se houver
    final textStart = working.indexOf('{');
    final textEnd = working.lastIndexOf('}');
    if (textStart != -1 && textEnd > textStart) {
      textContent = working.substring(textStart + 1, textEnd);
      working = working.substring(0, textStart) + working.substring(textEnd + 1);
    }

    // Extrai atributos entre [] se houver
    final attrs = <String>[];
    final attrStart = working.indexOf('[');
    final attrEnd = working.lastIndexOf(']');
    if (attrStart != -1 && attrEnd > attrStart) {
      final attrStr = working.substring(attrStart + 1, attrEnd);
      attrs.addAll(attrStr.split(RegExp(r'\s+')).where((a) => a.isNotEmpty));
      working = working.substring(0, attrStart) + working.substring(attrEnd + 1);
    }

    // Extrai classes (.) e id (#)
    String tagName = 'div';
    String? id;
    final classes = <String>[];

    final match = RegExp(r'^([a-zA-Z0-9_\-]+)?').firstMatch(working);
    if (match != null && match.group(1) != null && match.group(1)!.isNotEmpty) {
      tagName = match.group(1)!;
      working = working.substring(tagName.length);
    }

    final idMatches = RegExp(r'#([a-zA-Z0-9_\-]+)').allMatches(working);
    for (final m in idMatches) {
      id = m.group(1);
    }

    final classMatches = RegExp(r'\.([a-zA-Z0-9_\-]+)').allMatches(working);
    for (final m in classMatches) {
      final cls = m.group(1);
      if (cls != null) classes.add(cls);
    }

    return _TagSpec(
      name: tagName,
      id: id,
      classes: classes,
      attributes: attrs,
      textContent: textContent.isNotEmpty ? textContent : null,
    );
  }

  List<String> _splitTopLevel(String input, String delimiter) {
    final result = <String>[];
    var current = StringBuffer();
    var bracketDepth = 0;
    var braceDepth = 0;

    for (var i = 0; i < input.length; i++) {
      final ch = input[i];
      if (ch == '[') bracketDepth++;
      if (ch == ']') bracketDepth = bracketDepth > 0 ? bracketDepth - 1 : 0;
      if (ch == '{') braceDepth++;
      if (ch == '}') braceDepth = braceDepth > 0 ? braceDepth - 1 : 0;

      if (ch == delimiter && bracketDepth == 0 && braceDepth == 0) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }

    if (current.isNotEmpty) {
      result.add(current.toString().trim());
    }
    return result;
  }
}

class _TagSpec {
  const _TagSpec({
    required this.name,
    this.id,
    this.classes = const [],
    this.attributes = const [],
    this.textContent,
  });

  final String name;
  final String? id;
  final List<String> classes;
  final List<String> attributes;
  final String? textContent;

  String get openTagString {
    final parts = <String>[name];
    if (id != null) {
      parts.add('id="$id"');
    }
    if (classes.isNotEmpty) {
      parts.add('class="${classes.join(' ')}"');
    }
    if (attributes.isNotEmpty) {
      parts.addAll(attributes);
    }
    return parts.join(' ');
  }
}

/// Serviço de detecção e gestão de regiões dobráveis de código (Code Folding) (X01).
class CodeFoldingService {
  const CodeFoldingService();

  /// Analisa o texto [sourceCode] e calcula as regiões de código dobráveis.
  List<FoldingRange> computeFoldingRanges(
    String sourceCode, {
    String language = 'dart',
  }) {
    final lines = sourceCode.split('\n');
    final ranges = <FoldingRange>[];

    final braceStack = <int>[];
    int? commentStartLine;
    int? regionStartLine;
    String regionPlaceholder = '...';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final trimmed = line.trim();

      // 1. Regiões explícitas // #region / // #endregion
      if (trimmed.startsWith('// #region') || trimmed.startsWith('// <editor-fold>')) {
        regionStartLine = i + 1;
        final desc = trimmed.replaceFirst(RegExp(r'//\s*(?:#region|<editor-fold\s*desc="?|#region\s+)'), '').replaceAll('">', '').trim();
        regionPlaceholder = desc.isNotEmpty ? desc : '...';
        continue;
      }
      if (trimmed.startsWith('// #endregion') || trimmed.startsWith('// </editor-fold>')) {
        if (regionStartLine != null && (i + 1) > regionStartLine) {
          ranges.add(
            FoldingRange(
              startLine: regionStartLine,
              endLine: i + 1,
              kind: FoldingKind.region,
              placeholder: regionPlaceholder,
            ),
          );
        }
        regionStartLine = null;
        regionPlaceholder = '...';
        continue;
      }

      // 2. Comentários de bloco /* ... */
      if (trimmed.startsWith('/*') && !trimmed.contains('*/')) {
        commentStartLine = i + 1;
        continue;
      }
      if (commentStartLine != null && trimmed.contains('*/')) {
        ranges.add(
          FoldingRange(
            startLine: commentStartLine,
            endLine: i + 1,
            kind: FoldingKind.comment,
            placeholder: '/* ... */',
          ),
        );
        commentStartLine = null;
        continue;
      }

      // 3. Blocos de código delimitados por { e }
      var inString = false;
      String stringChar = '';
      for (var col = 0; col < line.length; col++) {
        final char = line[col];

        if (char == "'" || char == '"') {
          if (!inString) {
            inString = true;
            stringChar = char;
          } else if (stringChar == char && (col == 0 || line[col - 1] != '\\')) {
            inString = false;
          }
          continue;
        }

        if (inString) continue;

        if (char == '{') {
          braceStack.add(i + 1);
        } else if (char == '}' && braceStack.isNotEmpty) {
          final openLine = braceStack.removeLast();
          if ((i + 1) > openLine) {
            ranges.add(
              FoldingRange(
                startLine: openLine,
                endLine: i + 1,
                kind: FoldingKind.block,
              ),
            );
          }
        }
      }
    }

    // Ordena pelo número da linha inicial
    ranges.sort((a, b) => a.startLine.compareTo(b.startLine));
    return List.unmodifiable(ranges);
  }
}

/// Serviço de varredura e extração de pendências e anotações (TODO, FIXME, etc.) (X01).
class TodoScanningService {
  const TodoScanningService();

  static final _todoRegex = RegExp(
    r'(?://|/\*|#|<!--)\s*(TODO|FIXME|HACK|BUG|NOTE|XXX)\s*[:\-]?\s*(.+)',
    caseSensitive: false,
  );

  /// Varre o [sourceCode] linha a linha e extrai todos os [TodoItem] encontrados.
  List<TodoItem> scan(String sourceCode, {String? filePath}) {
    final lines = sourceCode.split('\n');
    final items = <TodoItem>[];
    final file = filePath ?? 'untitled';

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final match = _todoRegex.firstMatch(line);
      if (match != null) {
        final tag = (match.group(1) ?? 'TODO').toUpperCase();
        var message = (match.group(2) ?? '').trim();
        // Remove delimitadores residuais de fechamento
        if (message.endsWith('*/')) {
          message = message.substring(0, message.length - 2).trim();
        }
        if (message.endsWith('-->')) {
          message = message.substring(0, message.length - 3).trim();
        }

        final TodoSeverity severity;
        if (tag == 'BUG' || tag == 'FIXME') {
          severity = TodoSeverity.error;
        } else if (tag == 'TODO' || tag == 'HACK' || tag == 'XXX') {
          severity = TodoSeverity.warning;
        } else {
          severity = TodoSeverity.info;
        }

        items.add(
          TodoItem(
            id: '$file:${i + 1}:${match.start}',
            filePath: file,
            line: i + 1,
            column: match.start,
            tag: tag,
            message: message,
            severity: severity,
          ),
        );
      }
    }

    return List.unmodifiable(items);
  }
}

/// Serviço de detecção e visualização de amostras de cores no editor (X01).
class ColorPreviewService {
  const ColorPreviewService();

  static final _hexRegex = RegExp(r'#([0-9a-fA-F]{3,8})\b');
  static final _flutterColorRegex = RegExp(r'Color\(\s*(0x[0-9a-fA-F]{8})\s*\)');
  static final _rgbRegex = RegExp(
    r'rgba?\(\s*(\d{1,3})\s*,\s*(\d{1,3})\s*,\s*(\d{1,3})(?:\s*,\s*([\d\.]+))?\s*\)',
  );

  /// Localiza todas as ocorrências de declarações literais de cor em [text].
  List<ColorPreviewMatch> findColorMatches(String text) {
    final lines = text.split('\n');
    final matches = <ColorPreviewMatch>[];

    for (var lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final line = lines[lineIdx];
      final lineNum = lineIdx + 1;

      // 1. Hex CSS (#RGB, #RGBA, #RRGGBB, #RRGGBBAA)
      for (final m in _hexRegex.allMatches(line)) {
        final hex = m.group(1)!;
        final parsedArgb = _parseHexToArgb(hex);
        if (parsedArgb != null) {
          final format = hex.length == 3
              ? ColorSyntaxFormat.hex3
              : hex.length == 4
                  ? ColorSyntaxFormat.hex4
                  : hex.length == 6
                      ? ColorSyntaxFormat.hex6
                      : ColorSyntaxFormat.hex8;
          matches.add(
            ColorPreviewMatch(
              rawText: m.group(0)!,
              argbValue: parsedArgb,
              line: lineNum,
              startColumn: m.start,
              endColumn: m.end,
              format: format,
            ),
          );
        }
      }

      // 2. Flutter Color(0xAARRGGBB)
      for (final m in _flutterColorRegex.allMatches(line)) {
        final hexValue = m.group(1)!;
        final intVal = int.tryParse(hexValue.substring(2), radix: 16);
        if (intVal != null) {
          matches.add(
            ColorPreviewMatch(
              rawText: m.group(0)!,
              argbValue: intVal,
              line: lineNum,
              startColumn: m.start,
              endColumn: m.end,
              format: ColorSyntaxFormat.flutterColor,
            ),
          );
        }
      }

      // 3. CSS rgb(...) e rgba(...)
      for (final m in _rgbRegex.allMatches(line)) {
        final r = int.tryParse(m.group(1) ?? '') ?? 0;
        final g = int.tryParse(m.group(2) ?? '') ?? 0;
        final b = int.tryParse(m.group(3) ?? '') ?? 0;
        final aStr = m.group(4);
        final a = aStr != null ? ((double.tryParse(aStr) ?? 1.0) * 255).round().clamp(0, 255) : 255;

        final argb = (a << 24) | ((r & 0xFF) << 16) | ((g & 0xFF) << 8) | (b & 0xFF);
        matches.add(
          ColorPreviewMatch(
            rawText: m.group(0)!,
            argbValue: argb,
            line: lineNum,
            startColumn: m.start,
            endColumn: m.end,
            format: aStr != null ? ColorSyntaxFormat.rgba : ColorSyntaxFormat.rgb,
          ),
        );
      }
    }

    return List.unmodifiable(matches);
  }

  int? _parseHexToArgb(String hex) {
    if (hex.length == 3) {
      // #RGB -> #FFRRGGBB
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      return int.tryParse('FF$r$r$g$g$b$b', radix: 16);
    }
    if (hex.length == 4) {
      // #RGBA -> #AARRGGBB
      final r = hex[0];
      final g = hex[1];
      final b = hex[2];
      final a = hex[3];
      return int.tryParse('$a$a$r$r$g$g$b$b', radix: 16);
    }
    if (hex.length == 6) {
      // #RRGGBB -> #FFRRGGBB
      return int.tryParse('FF$hex', radix: 16);
    }
    if (hex.length == 8) {
      // #RRGGBBAA -> #AARRGGBB
      final rrggbb = hex.substring(0, 6);
      final aa = hex.substring(6, 8);
      return int.tryParse('$aa$rrggbb', radix: 16);
    }
    return null;
  }
}

/// Gerenciador de marcadores de linha (Bookmarks) (X01).
class EditorBookmarkService {
  EditorBookmarkService();

  final List<BookmarkItem> _bookmarks = [];

  List<BookmarkItem> get bookmarks => List.unmodifiable(_bookmarks);

  void toggleBookmark({
    required String filePath,
    required int line,
    int column = 0,
    String? label,
    String? mnemonic,
  }) {
    final existingIndex = _bookmarks.indexWhere(
      (b) => b.filePath == filePath && b.line == line,
    );
    if (existingIndex != -1) {
      _bookmarks.removeAt(existingIndex);
    } else {
      _bookmarks.add(
        BookmarkItem(
          id: '$filePath:$line',
          filePath: filePath,
          line: line,
          column: column,
          label: label,
          mnemonic: mnemonic,
          createdAt: DateTime.now(),
        ),
      );
      _bookmarks.sort((a, b) {
        final cmp = a.filePath.compareTo(b.filePath);
        return cmp != 0 ? cmp : a.line.compareTo(b.line);
      });
    }
  }

  BookmarkItem? nextBookmark({required String currentFile, required int currentLine}) {
    if (_bookmarks.isEmpty) return null;
    final forward = _bookmarks.firstWhere(
      (b) => b.filePath == currentFile && b.line > currentLine,
      orElse: () => _bookmarks.firstWhere(
        (b) => b.filePath != currentFile,
        orElse: () => _bookmarks.first,
      ),
    );
    return forward;
  }

  BookmarkItem? previousBookmark({required String currentFile, required int currentLine}) {
    if (_bookmarks.isEmpty) return null;
    final reversed = _bookmarks.reversed.toList();
    final backward = reversed.firstWhere(
      (b) => b.filePath == currentFile && b.line < currentLine,
      orElse: () => reversed.firstWhere(
        (b) => b.filePath != currentFile,
        orElse: () => reversed.first,
      ),
    );
    return backward;
  }

  BookmarkItem? getBookmarkByMnemonic(String mnemonic) {
    try {
      return _bookmarks.firstWhere((b) => b.mnemonic == mnemonic);
    } catch (_) {
      return null;
    }
  }

  void clear() => _bookmarks.clear();
}

/// Gravador e executor de macros de teclado (X01).
class EditorMacroService {
  EditorMacroService();

  bool _isRecording = false;
  final List<MacroAction> _currentRecording = [];
  final Map<String, EditorMacro> _savedMacros = {};

  bool get isRecording => _isRecording;
  Map<String, EditorMacro> get savedMacros => Map.unmodifiable(_savedMacros);

  void startRecording() {
    _currentRecording.clear();
    _isRecording = true;
  }

  void recordAction(String actionType, String payload) {
    if (!_isRecording) return;
    _currentRecording.add(
      MacroAction(
        actionType: actionType,
        payload: payload,
        timestampMs: DateTime.now().millisecondsSinceEpoch,
      ),
    );
  }

  EditorMacro? stopRecording({String name = 'default'}) {
    if (!_isRecording) return null;
    _isRecording = false;
    final macro = EditorMacro(
      name: name,
      actions: List.unmodifiable(_currentRecording),
      recordedAt: DateTime.now(),
    );
    _savedMacros[name] = macro;
    return macro;
  }

  void playMacro(
    String name, {
    int times = 1,
    required void Function(MacroAction action) onExecuteAction,
  }) {
    final macro = _savedMacros[name];
    if (macro == null) return;

    for (var i = 0; i < times; i++) {
      for (final action in macro.actions) {
        onExecuteAction(action);
      }
    }
  }
}

/// Controlador de estado de modo Vim com transições e comandos canônicos (X01).
class VimStateController {
  VimStateController({VimMode initialMode = VimMode.normal}) : _currentMode = initialMode;

  VimMode _currentMode;
  String _commandBuffer = '';

  VimMode get currentMode => _currentMode;
  String get commandBuffer => _commandBuffer;

  /// Processa uma tecla pressionada e retorna a ação recomendada ou null.
  String? processKey(
    String key, {
    bool isEscape = false,
    bool isEnter = false,
  }) {
    if (isEscape) {
      _currentMode = VimMode.normal;
      _commandBuffer = '';
      return 'setMode:normal';
    }

    switch (_currentMode) {
      case VimMode.normal:
        if (key == 'i') {
          _currentMode = VimMode.insert;
          return 'setMode:insert';
        }
        if (key == 'v') {
          _currentMode = VimMode.visual;
          return 'setMode:visual';
        }
        if (key == 'V') {
          _currentMode = VimMode.visualLine;
          return 'setMode:visualLine';
        }
        if (key == ':') {
          _currentMode = VimMode.command;
          _commandBuffer = '';
          return 'setMode:command';
        }
        // Movimentos básicos em modo normal
        if (key == 'h' || key == 'j' || key == 'k' || key == 'l') {
          return 'move:$key';
        }
        if (key == 'u') {
          return 'undo';
        }
        if (key == 'x') {
          return 'deleteChar';
        }
        break;

      case VimMode.command:
        if (isEnter) {
          final cmd = _commandBuffer;
          _currentMode = VimMode.normal;
          _commandBuffer = '';
          if (cmd == 'w') return 'command:save';
          if (cmd == 'q') return 'command:quit';
          if (cmd == 'wq') return 'command:saveAndQuit';
          return 'command:$cmd';
        } else {
          _commandBuffer += key;
          return 'commandBuffer:$_commandBuffer';
        }

      case VimMode.insert:
      case VimMode.visual:
      case VimMode.visualLine:
        // Mantém modo até Escape
        break;
    }

    return null;
  }
}
