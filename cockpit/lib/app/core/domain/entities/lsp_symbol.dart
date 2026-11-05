import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_location.dart';

/// Tipos de símbolos suportados pela especificação LSP (SymbolKind 1..26).
enum LspSymbolKind {
  file(1, 'File'),
  module(2, 'Module'),
  namespace(3, 'Namespace'),
  package(4, 'Package'),
  classType(5, 'Class'),
  method(6, 'Method'),
  property(7, 'Property'),
  field(8, 'Field'),
  constructor(9, 'Constructor'),
  enumType(10, 'Enum'),
  interfaceType(11, 'Interface'),
  function(12, 'Function'),
  variable(13, 'Variable'),
  constant(14, 'Constant'),
  string(15, 'String'),
  number(16, 'Number'),
  boolean(17, 'Boolean'),
  array(18, 'Array'),
  object(19, 'Object'),
  key(20, 'Key'),
  nullType(21, 'Null'),
  enumMember(22, 'EnumMember'),
  struct(23, 'Struct'),
  event(24, 'Event'),
  operator(25, 'Operator'),
  typeParameter(26, 'TypeParameter'),
  unknown(0, 'Unknown');

  const LspSymbolKind(this.value, this.label);

  final int value;
  final String label;

  static LspSymbolKind fromValue(int? val) {
    if (val == null) return LspSymbolKind.unknown;
    for (final kind in LspSymbolKind.values) {
      if (kind.value == val) return kind;
    }
    return LspSymbolKind.unknown;
  }
}

/// Símbolo de código semântico (L03) — resultado de `textDocument/documentSymbol`
/// ou `workspace/symbol`.
class LspDocumentSymbol {
  const LspDocumentSymbol({
    required this.name,
    required this.kind,
    required this.range,
    required this.selectionRange,
    this.detail,
    this.containerName,
    this.children = const [],
    this.location,
  });

  final String name;
  final String? detail;
  final LspSymbolKind kind;
  final LspRange range;
  final LspRange selectionRange;
  final String? containerName;
  final List<LspDocumentSymbol> children;
  final LspLocation? location;

  factory LspDocumentSymbol.fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String? ?? '';
    final kind = LspSymbolKind.fromValue(json['kind'] as int?);
    final detail = json['detail'] as String?;
    final containerName = json['containerName'] as String?;

    // Hierárquico moderno (DocumentSymbol)
    if (json.containsKey('range') && json.containsKey('selectionRange')) {
      final range = LspRange.fromJson((json['range'] as Map).cast<String, dynamic>());
      final selRange = LspRange.fromJson((json['selectionRange'] as Map).cast<String, dynamic>());
      final rawChildren = json['children'] as List?;
      final children = <LspDocumentSymbol>[];
      if (rawChildren != null) {
        for (final c in rawChildren) {
          if (c is Map<String, dynamic>) {
            children.add(LspDocumentSymbol.fromJson(c));
          }
        }
      }
      return LspDocumentSymbol(
        name: name,
        detail: detail,
        kind: kind,
        range: range,
        selectionRange: selRange,
        children: children,
      );
    }

    // Plano legado ou workspace/symbol (SymbolInformation)
    LspLocation? loc;
    LspRange range = const LspRange(LspPosition(0, 0), LspPosition(0, 0));
    if (json['location'] is Map<String, dynamic>) {
      loc = LspLocation.fromJson(json['location'] as Map<String, dynamic>);
      range = loc.range;
    }

    return LspDocumentSymbol(
      name: name,
      detail: detail,
      kind: kind,
      range: range,
      selectionRange: range,
      containerName: containerName,
      location: loc,
    );
  }
}

/// Decodifica a resposta de `textDocument/documentSymbol` ou `workspace/symbol`.
List<LspDocumentSymbol> parseDocumentSymbols(Object? response) {
  if (response is! List) return const [];
  final results = <LspDocumentSymbol>[];
  for (final item in response) {
    if (item is Map<String, dynamic>) {
      results.add(LspDocumentSymbol.fromJson(item));
    }
  }
  return results;
}
