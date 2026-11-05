import 'lsp_hover.dart';

/// Seleciona a assinatura e o parâmetro ativos em uma resposta SignatureHelp.
String? parseSignatureHelpText(Object? response) {
  if (response is! Map || response['signatures'] is! List) return null;
  final signatures = response['signatures'] as List;
  if (signatures.isEmpty) return null;
  final active = response['activeSignature'];
  final index = active is int && active >= 0 && active < signatures.length
      ? active
      : 0;
  final signature = signatures[index];
  if (signature is! Map || signature['label'] is! String) return null;
  final label = signature['label'] as String;
  if (label.trim().isEmpty) return null;
  final parts = <String>[label.trim()];
  final parameters = signature['parameters'];
  final parameterIndex =
      signature['activeParameter'] ?? response['activeParameter'] ?? 0;
  if (parameters is List &&
      parameterIndex is int &&
      parameterIndex >= 0 &&
      parameterIndex < parameters.length) {
    final parameter = parameters[parameterIndex];
    if (parameter is Map) {
      final raw = parameter['label'];
      String? name;
      if (raw is String) name = raw;
      if (raw is List && raw.length == 2 && raw[0] is int && raw[1] is int) {
        final start = raw[0] as int;
        final end = raw[1] as int;
        if (start >= 0 && end >= start && end <= label.length) {
          name = label.substring(start, end);
        }
      }
      final doc = parseHoverText({'contents': parameter['documentation']});
      if (name != null && name.trim().isNotEmpty) {
        parts.add(doc == null ? name.trim() : '${name.trim()}: $doc');
      }
    }
  }
  final doc = parseHoverText({'contents': signature['documentation']});
  if (doc != null) parts.add(doc);
  return parts.join('\n\n');
}
