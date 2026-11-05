import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_completion.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_completion.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/services/lsp_completion_edits.dart';

void main() {
  Map<String, Object> range(int line, int start, int end) => {
    'start': {'line': line, 'character': start},
    'end': {'line': line, 'character': end},
  };

  test('parses lists, sorts deterministically and rejects snippets', () {
    final items = parseCompletions([
      {'label': 'z', 'sortText': '1'},
      {'label': 'a'},
      {'label': 'selected', 'preselect': true},
      {'label': 'snippet', 'insertTextFormat': 2},
      {1: 'invalid', 'label': 'bad'},
      null,
    ]);
    expect(items.map((e) => e.label), ['selected', 'z', 'a']);
  });

  test('completion list defaults normalize edit ranges for resolve', () {
    final item = parseCompletions({
      'itemDefaults': {'editRange': range(0, 0, 3)},
      'items': [
        {'label': 'answer', 'textEditText': 'answer'},
      ],
    }).single;
    expect(item.edit!.range.end.character, 3);
    expect(item.raw['textEdit'], isNotNull);
    expect(applyCompletion('ans', 3, item), (text: 'answer', caret: 6));
  });

  test('insert replace and additional imports apply atomically', () {
    final item = parseCompletions([
      {
        'label': 'answer',
        'textEdit': {
          'insert': range(1, 0, 2),
          'replace': range(1, 0, 3),
          'newText': 'answer',
        },
        'additionalTextEdits': [
          {'range': range(0, 0, 0), 'newText': 'import x;\n'},
        ],
      },
    ]).single;
    expect(applyCompletion('\nans', 3, item), (
      text: 'import x;\n\nanswer',
      caret: 17,
    ));
  });

  test('invalid edits and malformed responses are rejected', () {
    expect(parseCompletions({'items': 'bad'}), isEmpty);
    expect(
      parseCompletions([
        {
          'label': 'x',
          'textEdit': {'range': range(0, 3, 1), 'newText': 'x'},
        },
        {
          'label': 'x',
          'additionalTextEdits': [null],
        },
      ]),
      isEmpty,
    );
  });

  test('fallback replaces entire identifier and preserves UTF16 and CRLF', () {
    const item = LspCompletionItem(label: 'answer', insertText: 'answer');
    expect(applyCompletion('😀\r\nansOld', 6, item), (
      text: '😀\r\nanswer',
      caret: 10,
    ));
  });

  test('overlap, out of bounds and edits outside caret are rejected', () {
    LspCompletionEdit edit(int start, int end) => LspCompletionEdit(
      LspRange(LspPosition(0, start), LspPosition(0, end)),
      'x',
    );
    for (final item in [
      LspCompletionItem(label: 'x', insertText: 'x', edit: edit(0, 99)),
      LspCompletionItem(label: 'x', insertText: 'x', edit: edit(0, 1)),
      LspCompletionItem(
        label: 'x',
        insertText: 'x',
        edit: edit(0, 3),
        additionalEdits: [edit(1, 2)],
      ),
    ]) {
      expect(applyCompletion('ans', 3, item), isNull);
    }
  });
}
