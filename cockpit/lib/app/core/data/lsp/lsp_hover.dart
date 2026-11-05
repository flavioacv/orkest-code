/// Extrai texto de Hover/MarkupContent/MarkedString sem interpretar HTML.
String? parseHoverText(Object? response) {
  if (response is! Map) return null;
  final contents = response['contents'];
  String? textOf(Object? value) {
    if (value is String) return value.trim();
    if (value is Map && value['value'] is String) {
      return (value['value'] as String).trim();
    }
    return null;
  }

  final parts = contents is List ? contents : <Object?>[contents];
  final text = parts
      .map(textOf)
      .whereType<String>()
      .where((s) => s.isNotEmpty)
      .join('\n\n');
  return text.isEmpty ? null : text;
}
