import '../entities/lsp_completion.dart';
import '../entities/lsp_diagnostic.dart';

bool isCompletionWordUnit(int unit) =>
    unit >= 65 && unit <= 90 ||
    unit >= 97 && unit <= 122 ||
    unit >= 48 && unit <= 57 ||
    unit == 95 ||
    unit == 36;

/// Valida todas as edições antes de produzir texto/caret, sem modificar o buffer.
({String text, int caret})? applyCompletion(
  String text,
  int caret,
  LspCompletionItem item,
) {
  if (caret < 0 || caret > text.length) return null;
  final starts = <int>[0];
  for (var i = 0; i < text.length; i++) {
    if (text.codeUnitAt(i) == 10) starts.add(i + 1);
  }
  int? offset(LspPosition position) {
    if (position.line < 0 ||
        position.line >= starts.length ||
        position.character < 0) {
      return null;
    }
    final start = starts[position.line];
    var end = position.line + 1 < starts.length
        ? starts[position.line + 1] - 1
        : text.length;
    if (end > start && text.codeUnitAt(end - 1) == 13) end--;
    return position.character <= end - start
        ? start + position.character
        : null;
  }

  var start = caret;
  var end = caret;
  while (start > 0 && isCompletionWordUnit(text.codeUnitAt(start - 1))) {
    start--;
  }
  while (end < text.length && isCompletionWordUnit(text.codeUnitAt(end))) {
    end++;
  }
  final main = item.edit;
  if (main != null) {
    final from = offset(main.range.start);
    final to = offset(main.range.end);
    if (from == null || to == null || from > caret || to < caret || from > to) {
      return null;
    }
    start = from;
    end = to;
  }
  final edits = <({int start, int end, String text})>[
    (start: start, end: end, text: main?.text ?? item.insertText),
  ];
  var shift = 0;
  for (final edit in item.additionalEdits) {
    final from = offset(edit.range.start);
    final to = offset(edit.range.end);
    if (from == null || to == null || from > to) return null;
    edits.add((start: from, end: to, text: edit.text));
    if (to <= start) shift += edit.text.length - (to - from);
  }
  edits.sort((a, b) => a.start.compareTo(b.start));
  for (var i = 1; i < edits.length; i++) {
    if (edits[i].start < edits[i - 1].end ||
        edits[i].start == edits[i - 1].start) {
      return null;
    }
  }
  var result = text;
  for (final edit in edits.reversed) {
    result = result.replaceRange(edit.start, edit.end, edit.text);
  }
  return (
    text: result,
    caret: start + (main?.text ?? item.insertText).length + shift,
  );
}
