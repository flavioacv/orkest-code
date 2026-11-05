import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/terminal/console_link_matcher.dart';

void main() {
  const matcher = ConsoleLinkMatcher();

  group('ConsoleLinkMatcher', () {
    test('localiza file URI explícita com linha e coluna', () {
      const line = 'Error at file:///Users/developer/project/lib/main.dart:42:15 in run()';
      final links = matcher.matchLinks(line);

      expect(links.length, equals(1));
      final link = links.first;
      expect(link.filePath, equals('/Users/developer/project/lib/main.dart'));
      expect(link.line, equals(42));
      expect(link.column, equals(15));
    });

    test('localiza caminho padrão relativo com linha e coluna', () {
      const line = 'Failed test in test/domain/git_conflict_resolution_test.dart:88:5';
      final links = matcher.matchLinks(line);

      expect(links.length, equals(1));
      final link = links.first;
      expect(link.filePath, equals('test/domain/git_conflict_resolution_test.dart'));
      expect(link.line, equals(88));
      expect(link.column, equals(5));
    });

    test('localiza formato do Dart test runner', () {
      const line = '  test/domain/git_hunk_staging_test.dart 30:12  G01 · Revisão';
      final links = matcher.matchLinks(line);

      expect(links.length, equals(1));
      final link = links.first;
      expect(link.filePath, equals('test/domain/git_hunk_staging_test.dart'));
      expect(link.line, equals(30));
      expect(link.column, equals(12));
    });

    test('localiza múltiplos links na mesma linha ordenados por offset', () {
      const line = 'compare a/lib/file_a.dart:10:2 with b/lib/file_b.dart:25:4';
      final links = matcher.matchLinks(line);

      expect(links.length, equals(2));
      expect(links[0].filePath, equals('a/lib/file_a.dart'));
      expect(links[0].line, equals(10));
      expect(links[1].filePath, equals('b/lib/file_b.dart'));
      expect(links[1].line, equals(25));
      expect(links[0].start < links[1].start, isTrue);
    });

    test('retorna lista vazia para texto sem referências de arquivo', () {
      const line = 'Build succeeded in 345ms. 12 packages cached.';
      expect(matcher.matchLinks(line), isEmpty);
    });
  });
}
