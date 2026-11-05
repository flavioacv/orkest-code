import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';

/// Tipo de dica embutida (inlay hint) de acordo com a especificação LSP 3.17 (L06).
enum LspInlayHintKind {
  /// Inlay hint de tipo (ex.: tipo inferido de variável `: int` ou `-> String`).
  type(1),

  /// Inlay hint de parâmetro (ex.: nome do argumento `name:` na chamada de função).
  parameter(2);

  const LspInlayHintKind(this.value);

  final int value;

  static LspInlayHintKind? fromValue(dynamic val) {
    if (val is int) {
      for (final kind in LspInlayHintKind.values) {
        if (kind.value == val) return kind;
      }
    }
    return null;
  }
}

/// Dica embutida no editor de código fornecida pelo language server (L06).
class LspInlayHint {
  const LspInlayHint({
    required this.position,
    required this.label,
    this.kind,
    this.paddingLeft = false,
    this.paddingRight = false,
    this.tooltip,
  });

  /// Posição (linha e caractere) onde o hint deve ser renderizado no editor.
  final LspPosition position;

  /// Texto do hint a ser exibido.
  final String label;

  /// Tipo de hint (tipo inferido ou parâmetro).
  final LspInlayHintKind? kind;

  /// Se deve renderizar espaçamento antes do hint.
  final bool paddingLeft;

  /// Se deve renderizar espaçamento após o hint.
  final bool paddingRight;

  /// Tooltip descritivo exibido ao passar o cursor sobre o hint.
  final String? tooltip;

  factory LspInlayHint.fromJson(Map<String, dynamic> json) {
    final rawPos = json['position'];
    final pos = rawPos is Map
        ? LspPosition(
            (rawPos['line'] as num?)?.toInt() ?? 0,
            (rawPos['character'] as num?)?.toInt() ?? 0,
          )
        : const LspPosition(0, 0);

    // O label pode ser uma String direta ou uma lista de InlayHintLabelPart
    String labelText = '';
    final rawLabel = json['label'];
    if (rawLabel is String) {
      labelText = rawLabel;
    } else if (rawLabel is List) {
      labelText = rawLabel
          .map((part) => part is Map ? (part['value'] ?? '') : part.toString())
          .join();
    }

    String? tooltipText;
    final rawTooltip = json['tooltip'];
    if (rawTooltip is String) {
      tooltipText = rawTooltip;
    } else if (rawTooltip is Map) {
      tooltipText = rawTooltip['value'] as String?;
    }

    return LspInlayHint(
      position: pos,
      label: labelText,
      kind: LspInlayHintKind.fromValue(json['kind']),
      paddingLeft: json['paddingLeft'] as bool? ?? false,
      paddingRight: json['paddingRight'] as bool? ?? false,
      tooltip: tooltipText,
    );
  }

  Map<String, dynamic> toJson() => {
        'position': {'line': position.line, 'character': position.character},
        'label': label,
        if (kind != null) 'kind': kind!.value,
        'paddingLeft': paddingLeft,
        'paddingRight': paddingRight,
        if (tooltip != null) 'tooltip': tooltip,
      };

  @override
  String toString() =>
      'LspInlayHint(pos: $position, label: "$label", kind: ${kind?.name})';
}

/// Decodificador de lista de Inlay Hints da resposta LSP.
List<LspInlayHint> parseInlayHints(dynamic response) {
  if (response is! List) return const [];
  final hints = <LspInlayHint>[];
  for (final item in response) {
    if (item is Map) {
      hints.add(LspInlayHint.fromJson(item.cast<String, dynamic>()));
    }
  }
  return List.unmodifiable(hints);
}
