import '../../domain/entities/lsp_completion.dart';
import '../../domain/entities/lsp_diagnostic.dart';
import '../../domain/services/lsp_snippet_service.dart';

LspRange? _range(Object? value) {
  if (value is! Map) return null;
  LspPosition? position(Object? raw) {
    if (raw is! Map) return null;
    final line = raw['line'];
    final character = raw['character'];
    return line is int && character is int && line >= 0 && character >= 0
        ? LspPosition(line, character)
        : null;
  }

  final start = position(value['start']);
  final end = position(value['end']);
  if (start == null ||
      end == null ||
      start.line > end.line ||
      (start.line == end.line && start.character > end.character)) {
    return null;
  }
  return LspRange(start, end);
}

/// Lê CompletionItem[] e CompletionList, com suporte configurável a snippets.
List<LspCompletionItem> parseCompletions(
  Object? response, {
  bool supportSnippets = false,
}) {
  final rawItems = response is List
      ? response
      : response is Map
      ? response['items']
      : null;
  if (rawItems is! List) return const [];
  final defaults = response is Map && response['itemDefaults'] is Map
      ? response['itemDefaults'] as Map
      : const {};
  final items = <LspCompletionItem>[];
  const snippetService = LspSnippetService();

  for (final raw in rawItems.take(200)) {
    if (raw is! Map ||
        raw['label'] is! String ||
        (raw['label'] as String).isEmpty) {
      continue;
    }
    if (raw.keys.any((key) => key is! String)) continue;
    final json = Map<String, dynamic>.from(raw);
    final isSnippet = (json['insertTextFormat'] ?? defaults['insertTextFormat']) == 2;
    if (isSnippet && !supportSnippets) {
      continue;
    }
    final label = json['label'] as String;
    var insert = json['insertText'] is String
        ? json['insertText'] as String
        : label;
    if (isSnippet) {
      insert = snippetService.expand(insert).text;
    }
    LspCompletionEdit? edit;
    final textEdit = json['textEdit'];
    if (textEdit != null) {
      if (textEdit is! Map || textEdit['newText'] is! String) continue;
      final range = _range(textEdit['range'] ?? textEdit['replace']);
      if (range == null) continue;
      var rawNewText = textEdit['newText'] as String;
      if (isSnippet) {
        rawNewText = snippetService.expand(rawNewText).text;
      }
      insert = rawNewText;
      edit = LspCompletionEdit(range, insert);
    } else if (defaults['editRange'] != null) {
      final rawRange = defaults['editRange'];
      final range = _range(
        rawRange is Map && rawRange.containsKey('replace')
            ? rawRange['replace']
            : rawRange,
      );
      if (range == null) continue;
      if (json['textEditText'] is String) {
        insert = json['textEditText'] as String;
        if (isSnippet) {
          insert = snippetService.expand(insert).text;
        }
      }
      edit = LspCompletionEdit(range, insert);
      json['textEdit'] = {
        'range': {
          'start': {
            'line': range.start.line,
            'character': range.start.character,
          },
          'end': {'line': range.end.line, 'character': range.end.character},
        },
        'newText': insert,
      };
    }
    final additional = <LspCompletionEdit>[];
    final extra = json['additionalTextEdits'];
    var valid = extra == null || extra is List;
    if (extra is List) {
      for (final value in extra) {
        final range = value is Map ? _range(value['range']) : null;
        if (range == null || value is! Map || value['newText'] is! String) {
          valid = false;
          break;
        }
        additional.add(LspCompletionEdit(range, value['newText'] as String));
      }
    }
    if (!valid) continue;
    items.add(
      LspCompletionItem(
        label: label,
        insertText: insert,
        detail: json['detail'] is String ? json['detail'] as String : null,
        edit: edit,
        additionalEdits: List.unmodifiable(additional),
        raw: Map.unmodifiable(json),
      ),
    );
  }
  final indexed = items.asMap().entries.toList();
  indexed.sort((a, b) {
    final preselect =
        (b.value.raw['preselect'] == true ? 1 : 0) -
        (a.value.raw['preselect'] == true ? 1 : 0);
    if (preselect != 0) return preselect;
    final left = a.value.raw['sortText'];
    final right = b.value.raw['sortText'];
    final order = (left is String ? left : a.value.label).compareTo(
      right is String ? right : b.value.label,
    );
    return order != 0 ? order : a.key.compareTo(b.key);
  });
  return indexed.map((e) => e.value).toList(growable: false);
}
