import 'lsp_diagnostic.dart';

class LspCompletionEdit {
  const LspCompletionEdit(this.range, this.text);
  final LspRange range;
  final String text;
}

/// Sugestão simples; o payload opaco é preservado para completionItem/resolve.
class LspCompletionItem {
  const LspCompletionItem({
    required this.label,
    required this.insertText,
    this.detail,
    this.edit,
    this.additionalEdits = const [],
    this.raw = const {},
  });
  final String label;
  final String insertText;
  final String? detail;
  final LspCompletionEdit? edit;
  final List<LspCompletionEdit> additionalEdits;
  final Map<String, dynamic> raw;
}
