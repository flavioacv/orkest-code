import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/services/semantic_navigation_history.dart';

void main() {
  group('SemanticNavigationHistory (L03)', () {
    late SemanticNavigationHistory history;

    setUp(() {
      history = SemanticNavigationHistory(maxHistory: 3);
    });

    test('pushes entries and allows goBack and goForward', () {
      history.push('file:///a.dart', 10, 5, symbolName: 'ClassA');
      history.push('file:///b.dart', 20, 8, symbolName: 'ClassB');

      expect(history.canGoBack, isTrue);
      expect(history.canGoForward, isFalse);

      final current = const NavigationLocation(uri: 'file:///c.dart', line: 30, character: 0);

      // Volta para ClassB
      final back1 = history.goBack(current);
      expect(back1?.uri, 'file:///b.dart');
      expect(back1?.symbolName, 'ClassB');
      expect(history.canGoForward, isTrue);

      // Volta para ClassA
      final back2 = history.goBack(back1!);
      expect(back2?.uri, 'file:///a.dart');
      expect(back2?.symbolName, 'ClassA');
      expect(history.canGoBack, isFalse);

      // Avança para ClassB
      final forward1 = history.goForward(back2!);
      expect(forward1?.uri, 'file:///b.dart');
      expect(history.canGoForward, isTrue);

      // Avança de volta para o ponto inicial (ClassC)
      final forward2 = history.goForward(forward1!);
      expect(forward2?.uri, 'file:///c.dart');
      expect(history.canGoForward, isFalse);
    });

    test('deduplicates consecutive identical locations', () {
      history.push('file:///a.dart', 10, 5);
      history.push('file:///a.dart', 10, 5); // idêntico

      expect(history.backCount, 1);
    });

    test('new push invalidates forward stack', () {
      history.push('file:///a.dart', 10, 0);
      final current = const NavigationLocation(uri: 'file:///b.dart', line: 20, character: 0);
      history.goBack(current);

      expect(history.canGoForward, isTrue);

      // Novo salto descarta o histórico futuro
      history.push('file:///d.dart', 40, 0);
      expect(history.canGoForward, isFalse);
    });

    test('enforces maxHistory cap', () {
      history.push('file:///1.dart', 1, 0);
      history.push('file:///2.dart', 2, 0);
      history.push('file:///3.dart', 3, 0);
      history.push('file:///4.dart', 4, 0);

      expect(history.backCount, 3);
      final oldest = history.goBack(const NavigationLocation(uri: 'file:///current.dart', line: 0, character: 0));
      expect(oldest?.uri, 'file:///4.dart');
    });

    test('clears entire navigation history', () {
      history.push('file:///a.dart', 10, 0);
      history.clear();

      expect(history.canGoBack, isFalse);
      expect(history.canGoForward, isFalse);
    });
  });
}
