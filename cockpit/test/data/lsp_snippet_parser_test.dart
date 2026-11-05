import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_completion.dart';
import 'package:orkest_code/app/core/domain/services/lsp_snippet_service.dart';

void main() {
  const service = LspSnippetService();

  group('LspSnippetService (L02)', () {
    test('expands plain snippet without variables', () {
      final res = service.expand('console.log("hello");');
      expect(res.text, 'console.log("hello");');
      expect(res.caretOffset, isNull);
    });

    test('expands simple tabstops and calculates first caret', () {
      final res = service.expand('console.log(\$1);\$0');
      expect(res.text, 'console.log();');
      expect(res.caretOffset, 12); // inside the parentheses
    });

    test('expands placeholders to default text and calculates caret', () {
      final res = service.expand('function \${1:myFunc}(\${2:arg1}) {\n  \$0\n}');
      expect(res.text, 'function myFunc(arg1) {\n  \n}');
      expect(res.caretOffset, 9); // at 'myFunc'
    });

    test('expands choices to first option', () {
      final res = service.expand('const mode = "\${1|development,production,test|}";');
      expect(res.text, 'const mode = "development";');
      expect(res.caretOffset, 14);
    });

    test('handles escaped dollar and braces', () {
      final res = service.expand(r'const cost = "\$100"; ${1:name}');
      expect(res.text, 'const cost = "\$100"; name');
      expect(res.caretOffset, 21);
    });
  });

  group('parseCompletions with snippets (L02)', () {
    test('rejects snippets when supportSnippets is false', () {
      final items = parseCompletions([
        {'label': 'snippet_fn', 'insertTextFormat': 2, 'insertText': 'fn(\$1)'},
      ], supportSnippets: false);

      expect(items, isEmpty);
    });

    test('cleans and accepts snippets when supportSnippets is true', () {
      final items = parseCompletions([
        {
          'label': 'log',
          'insertTextFormat': 2,
          'insertText': 'console.log(\${1:msg});',
        },
      ], supportSnippets: true);

      expect(items.length, 1);
      expect(items.first.insertText, 'console.log(msg);');
    });
  });
}
