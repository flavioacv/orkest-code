import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';

/// Item de Call Hierarchy segundo a especificação LSP 3.16+ (L06).
class LspCallHierarchyItem {
  const LspCallHierarchyItem({
    required this.name,
    required this.kind,
    required this.uri,
    required this.range,
    required this.selectionRange,
    this.detail,
    this.data,
  });

  final String name;
  final LspSymbolKind kind;
  final String uri;
  final LspRange range;
  final LspRange selectionRange;
  final String? detail;
  final dynamic data;

  factory LspCallHierarchyItem.fromJson(Map<String, dynamic> json) {
    return LspCallHierarchyItem(
      name: json['name'] as String? ?? '',
      kind: LspSymbolKind.fromValue((json['kind'] as num?)?.toInt() ?? 0),
      uri: json['uri'] as String? ?? '',
      range: LspRange.fromJson((json['range'] as Map? ?? const {}).cast<String, dynamic>()),
      selectionRange: LspRange.fromJson(
        (json['selectionRange'] as Map? ??
                json['range'] as Map? ??
                const {})
            .cast<String, dynamic>(),
      ),
      detail: json['detail'] as String?,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.value,
        'uri': uri,
        'range': range.toJson(),
        'selectionRange': selectionRange.toJson(),
        if (detail != null) 'detail': detail,
        if (data != null) 'data': data,
      };

  @override
  String toString() =>
      'LspCallHierarchyItem(name: "$name", kind: ${kind.name}, uri: $uri)';
}

/// Chamada recebida (quem chama este item) em Call Hierarchy (L06).
class LspCallHierarchyIncomingCall {
  const LspCallHierarchyIncomingCall({
    required this.from,
    required this.fromRanges,
  });

  /// O símbolo chamador.
  final LspCallHierarchyItem from;

  /// Os ranges específicos no arquivo onde a chamada ocorre.
  final List<LspRange> fromRanges;

  factory LspCallHierarchyIncomingCall.fromJson(Map<String, dynamic> json) {
    final fromMap = (json['from'] as Map? ?? const {}).cast<String, dynamic>();
    final rawRanges = json['fromRanges'] as List? ?? const [];
    return LspCallHierarchyIncomingCall(
      from: LspCallHierarchyItem.fromJson(fromMap),
      fromRanges: rawRanges
          .whereType<Map>()
          .map((m) => LspRange.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'from': from.toJson(),
        'fromRanges': [for (final r in fromRanges) r.toJson()],
      };
}

/// Chamada realizada (quem este item chama) em Call Hierarchy (L06).
class LspCallHierarchyOutgoingCall {
  const LspCallHierarchyOutgoingCall({
    required this.to,
    required this.fromRanges,
  });

  /// O símbolo que é chamado.
  final LspCallHierarchyItem to;

  /// Os ranges específicos no código onde a chamada é efetuada.
  final List<LspRange> fromRanges;

  factory LspCallHierarchyOutgoingCall.fromJson(Map<String, dynamic> json) {
    final toMap = (json['to'] as Map? ?? const {}).cast<String, dynamic>();
    final rawRanges = json['fromRanges'] as List? ?? const [];
    return LspCallHierarchyOutgoingCall(
      to: LspCallHierarchyItem.fromJson(toMap),
      fromRanges: rawRanges
          .whereType<Map>()
          .map((m) => LspRange.fromJson(m.cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'to': to.toJson(),
        'fromRanges': [for (final r in fromRanges) r.toJson()],
      };
}

/// Item de Type Hierarchy segundo a especificação LSP 3.17+ (L06).
class LspTypeHierarchyItem {
  const LspTypeHierarchyItem({
    required this.name,
    required this.kind,
    required this.uri,
    required this.range,
    required this.selectionRange,
    this.detail,
    this.data,
  });

  final String name;
  final LspSymbolKind kind;
  final String uri;
  final LspRange range;
  final LspRange selectionRange;
  final String? detail;
  final dynamic data;

  factory LspTypeHierarchyItem.fromJson(Map<String, dynamic> json) {
    return LspTypeHierarchyItem(
      name: json['name'] as String? ?? '',
      kind: LspSymbolKind.fromValue((json['kind'] as num?)?.toInt() ?? 0),
      uri: json['uri'] as String? ?? '',
      range: LspRange.fromJson((json['range'] as Map? ?? const {}).cast<String, dynamic>()),
      selectionRange: LspRange.fromJson(
        (json['selectionRange'] as Map? ??
                json['range'] as Map? ??
                const {})
            .cast<String, dynamic>(),
      ),
      detail: json['detail'] as String?,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'kind': kind.value,
        'uri': uri,
        'range': range.toJson(),
        'selectionRange': selectionRange.toJson(),
        if (detail != null) 'detail': detail,
        if (data != null) 'data': data,
      };

  @override
  String toString() =>
      'LspTypeHierarchyItem(name: "$name", kind: ${kind.name}, uri: $uri)';
}

/// Parsers utilitários para hierarquias de LSP.
List<LspCallHierarchyItem> parseCallHierarchyItems(dynamic response) {
  if (response is! List) return const [];
  return List.unmodifiable(
    response
        .whereType<Map>()
        .map((m) => LspCallHierarchyItem.fromJson(m.cast<String, dynamic>())),
  );
}

List<LspCallHierarchyIncomingCall> parseCallHierarchyIncomingCalls(dynamic response) {
  if (response is! List) return const [];
  return List.unmodifiable(
    response
        .whereType<Map>()
        .map((m) => LspCallHierarchyIncomingCall.fromJson(m.cast<String, dynamic>())),
  );
}

List<LspCallHierarchyOutgoingCall> parseCallHierarchyOutgoingCalls(dynamic response) {
  if (response is! List) return const [];
  return List.unmodifiable(
    response
        .whereType<Map>()
        .map((m) => LspCallHierarchyOutgoingCall.fromJson(m.cast<String, dynamic>())),
  );
}

List<LspTypeHierarchyItem> parseTypeHierarchyItems(dynamic response) {
  if (response is! List) return const [];
  return List.unmodifiable(
    response
        .whereType<Map>()
        .map((m) => LspTypeHierarchyItem.fromJson(m.cast<String, dynamic>())),
  );
}
