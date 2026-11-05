import 'dart:math' as math;

/// Categorias funcionais de produtividade do editor de código (X01).
enum ProductivityCategory {
  snippets,
  templates,
  emmet,
  folding,
  bookmarks,
  todo,
  vim,
  macros,
  colorPreview,
  scratchFiles,
}

/// Status de entrega ou viabilidade de cada recurso do inventário (X01).
enum CapabilityStatus {
  delivered,
  ready,
  inProgress,
  deferred,
}

/// Capacidade de produtividade catalogada no inventário (X01).
class ProductivityCapability {
  const ProductivityCapability({
    required this.id,
    required this.category,
    required this.name,
    required this.description,
    required this.status,
    this.defaultShortcut,
    this.usageTier = 1,
    this.accessibilityLabel,
  });

  final String id;
  final ProductivityCategory category;
  final String name;
  final String description;
  final CapabilityStatus status;
  final String? defaultShortcut;

  /// Nível de prioridade de uso: 1 (alta frequência / dia a dia), 2 (intermediário), 3 (especializado).
  final int usageTier;

  /// Rótulo explícito para leitores de tela e acessibilidade (a11y).
  final String? accessibilityLabel;

  bool get isDelivered => status == CapabilityStatus.delivered;
}

/// Inventário oficial e catálogo de recursos de edição e visualização (X01).
class ProductivityInventoryRegistry {
  ProductivityInventoryRegistry._();

  static const List<ProductivityCapability> capabilities = [
    // 1. Snippets & LSP Live Templates
    ProductivityCapability(
      id: 'productivity.snippets.lsp',
      category: ProductivityCategory.snippets,
      name: 'LSP & Live Snippets',
      description: 'Expansão de snippets com tabstops (\$1, \$2) e placeholders contextuais.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Tab',
      usageTier: 1,
      accessibilityLabel: 'Inserir trecho de código predefinido',
    ),
    ProductivityCapability(
      id: 'productivity.templates.files',
      category: ProductivityCategory.templates,
      name: 'File Templates',
      description: 'Modelos de arquivos novos (Dart Class/Widget, HTML5, TypeScript, Markdown).',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Ctrl+Alt+Insert',
      usageTier: 2,
      accessibilityLabel: 'Criar novo arquivo a partir de modelo',
    ),

    // 2. Emmet Syntax
    ProductivityCapability(
      id: 'productivity.emmet.expand',
      category: ProductivityCategory.emmet,
      name: 'Emmet Abbreviation Expansion',
      description: 'Expansão de sintaxe abreviada HTML/XML/CSS (ex: div.card>ul>li*3>a).',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Tab / Ctrl+E',
      usageTier: 1,
      accessibilityLabel: 'Expandir abreviação Emmet em HTML',
    ),

    // 3. Code Folding
    ProductivityCapability(
      id: 'productivity.folding.toggle',
      category: ProductivityCategory.folding,
      name: 'Code Folding',
      description: 'Colapso e expansão de blocos de código, comentários multilinhas e regiões customizadas.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Ctrl+Shift+[ / Ctrl+Shift+]',
      usageTier: 1,
      accessibilityLabel: 'Alternar visibilidade de bloco de código dobrável',
    ),

    // 4. Bookmarks
    ProductivityCapability(
      id: 'productivity.bookmarks.toggle',
      category: ProductivityCategory.bookmarks,
      name: 'Editor Bookmarks',
      description: 'Marcadores rápidos numerados (0-9) e nomeados com navegação bidirecional instantânea.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Ctrl+F11 / F11',
      usageTier: 1,
      accessibilityLabel: 'Alternar marcador de linha no editor',
    ),

    // 5. TODO & Tasks Scanner
    ProductivityCapability(
      id: 'productivity.todo.scanner',
      category: ProductivityCategory.todo,
      name: 'TODO & Task Tag Scanner',
      description: 'Detecção e agrupamento de anotações (TODO, FIXME, HACK, BUG, NOTE) no código.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Alt+6',
      usageTier: 1,
      accessibilityLabel: 'Listar tarefas pendentes e pendências no código',
    ),

    // 6. Vim Emulation State
    ProductivityCapability(
      id: 'productivity.vim.modal',
      category: ProductivityCategory.vim,
      name: 'Vim Modal Keybindings',
      description: 'Modos canônicos (Normal, Insert, Visual, Command) com movimentos e operadores básicos.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Esc / i / v / :',
      usageTier: 2,
      accessibilityLabel: 'Alternar modo de edição modal Vim',
    ),

    // 7. Keyboard Macros
    ProductivityCapability(
      id: 'productivity.macros.recorder',
      category: ProductivityCategory.macros,
      name: 'Keyboard Macro Recorder',
      description: 'Gravação e reprodução atômica de sequências de digitação e navegação de teclado.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Ctrl+Alt+R / Ctrl+Alt+P',
      usageTier: 3,
      accessibilityLabel: 'Gravar ou reproduzir macro de teclado',
    ),

    // 8. Color Preview & Gutter Swatch
    ProductivityCapability(
      id: 'productivity.color.preview',
      category: ProductivityCategory.colorPreview,
      name: 'Color Preview & Contrast',
      description: 'Detecção de hex, rgb, rgba e Color(0x...), swatch no gutter e conformidade WCAG.',
      status: CapabilityStatus.delivered,
      defaultShortcut: null,
      usageTier: 1,
      accessibilityLabel: 'Amostra visual de cor com contraste acessível',
    ),

    // 9. Scratch Files
    ProductivityCapability(
      id: 'productivity.scratch.buffers',
      category: ProductivityCategory.scratchFiles,
      name: 'Scratchpad Buffers',
      description: 'Buffers temporários para anotações rápidas e prototipagem sem poluir o repositório.',
      status: CapabilityStatus.delivered,
      defaultShortcut: 'Ctrl+Alt+Shift+Insert',
      usageTier: 2,
      accessibilityLabel: 'Criar rascunho temporário de código',
    ),
  ];

  static List<ProductivityCapability> byCategory(ProductivityCategory category) {
    return capabilities.where((c) => c.category == category).toList(growable: false);
  }

  static List<ProductivityCapability> byUsageTier(int tier) {
    return capabilities.where((c) => c.usageTier == tier).toList(growable: false);
  }
}

/// Item de marcador de código no arquivo (Bookmark).
class BookmarkItem {
  const BookmarkItem({
    required this.id,
    required this.filePath,
    required this.line,
    this.column = 0,
    this.label,
    this.mnemonic,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? const _DefaultEpoch();

  final String id;
  final String filePath;
  final int line;
  final int column;
  final String? label;

  /// Mnemônico opcional de 0 a 9 ou caractere identificador rápido.
  final String? mnemonic;
  final DateTime createdAt;
}

class _DefaultEpoch implements DateTime {
  const _DefaultEpoch();
  @override
  dynamic noSuchMethod(Invocation invocation) => DateTime.fromMillisecondsSinceEpoch(0);
}

/// Severidade de uma anotação TODO.
enum TodoSeverity {
  info,
  warning,
  error,
}

/// Item de anotação de tarefa detectada no código.
class TodoItem {
  const TodoItem({
    required this.id,
    required this.filePath,
    required this.line,
    required this.column,
    required this.tag,
    required this.message,
    required this.severity,
  });

  final String id;
  final String filePath;
  final int line;
  final int column;
  final String tag; // TODO, FIXME, HACK, BUG, NOTE, XXX
  final String message;
  final TodoSeverity severity;
}

/// Tipo de região dobrável de código.
enum FoldingKind {
  block, // Delimitado por chaves { ... }
  comment, // Comentários multilinhas /* ... */
  region, // // #region ... // #endregion
  xml, // Tags <tag> ... </tag>
}

/// Região dobrável calculada no documento.
class FoldingRange {
  const FoldingRange({
    required this.startLine,
    required this.endLine,
    required this.kind,
    this.isCollapsed = false,
    this.placeholder = '...',
  });

  final int startLine;
  final int endLine;
  final FoldingKind kind;
  final bool isCollapsed;
  final String placeholder;

  int get lineCount => endLine - startLine + 1;

  FoldingRange copyWith({bool? isCollapsed}) {
    return FoldingRange(
      startLine: startLine,
      endLine: endLine,
      kind: kind,
      isCollapsed: isCollapsed ?? this.isCollapsed,
      placeholder: placeholder,
    );
  }
}

/// Formato sintático da cor detectada no texto.
enum ColorSyntaxFormat {
  hex3, // #RGB
  hex4, // #RGBA
  hex6, // #RRGGBB
  hex8, // #RRGGBBAA
  rgb, // rgb(r, g, b)
  rgba, // rgba(r, g, b, a)
  flutterColor, // Color(0xAARRGGBB) ou 0xFFRRGGBB
}

/// Amostra de cor detectada no código para visualização no editor (Gutter / Swatch).
class ColorPreviewMatch {
  const ColorPreviewMatch({
    required this.rawText,
    required this.argbValue,
    required this.line,
    required this.startColumn,
    required this.endColumn,
    required this.format,
  });

  final String rawText;

  /// Valor inteiro de 32 bits no formato 0xAARRGGBB.
  final int argbValue;
  final int line;
  final int startColumn;
  final int endColumn;
  final ColorSyntaxFormat format;

  int get alpha => (argbValue >> 24) & 0xFF;
  int get red => (argbValue >> 16) & 0xFF;
  int get green => (argbValue >> 8) & 0xFF;
  int get blue => argbValue & 0xFF;

  /// Luminância relativa normalizada segundo WCAG 2.x (0.0 a 1.0).
  double get relativeLuminance {
    double transform(int c) {
      final s = c / 255.0;
      return s <= 0.03928 ? s / 12.92 : math.pow((s + 0.055) / 1.055, 2.4).toDouble();
    }

    final r = transform(red);
    final g = transform(green);
    final b = transform(blue);
    return 0.2126 * r + 0.7152 * g + 0.0722 * b;
  }

  /// Indica se sobre esta cor deve ser usado texto claro (branco) ou escuro (preto/cinza escuro).
  /// Respeita o limiar estrito do Orkest (0.24) em `color_contrast.dart`.
  bool get prefersLightForeground => relativeLuminance < 0.24;
}

/// Modos canônicos de edição modal Vim.
enum VimMode {
  normal,
  insert,
  visual,
  visualLine,
  command,
}

/// Ação atômica gravada em uma macro de teclado.
class MacroAction {
  const MacroAction({
    required this.actionType,
    required this.payload,
    this.timestampMs = 0,
  });

  /// Tipo de ação: 'insertText', 'delete', 'moveCursor', 'executeCommand'
  final String actionType;
  final String payload;
  final int timestampMs;
}

/// Sequência de macro gravada pronta para reprodução.
class EditorMacro {
  const EditorMacro({
    required this.name,
    required this.actions,
    this.recordedAt,
  });

  final String name;
  final List<MacroAction> actions;
  final DateTime? recordedAt;

  int get length => actions.length;
}

/// Buffer temporário em memória para anotações e prototipagem rápida (Scratchpad).
class ScratchBuffer {
  const ScratchBuffer({
    required this.id,
    required this.title,
    required this.language,
    required this.content,
    this.updatedAt,
  });

  final String id;
  final String title;
  final String language;
  final String content;
  final DateTime? updatedAt;

  ScratchBuffer copyWith({
    String? title,
    String? language,
    String? content,
    DateTime? updatedAt,
  }) {
    return ScratchBuffer(
      id: id,
      title: title ?? this.title,
      language: language ?? this.language,
      content: content ?? this.content,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
