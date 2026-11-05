import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';

void main() {
  group('LspSymbol (L03)', () {
    test('maps symbol kind values correctly', () {
      expect(LspSymbolKind.fromValue(1), LspSymbolKind.file);
      expect(LspSymbolKind.fromValue(5), LspSymbolKind.classType);
      expect(LspSymbolKind.fromValue(6), LspSymbolKind.method);
      expect(LspSymbolKind.fromValue(11), LspSymbolKind.interfaceType);
      expect(LspSymbolKind.fromValue(12), LspSymbolKind.function);
      expect(LspSymbolKind.fromValue(999), LspSymbolKind.unknown);
      expect(LspSymbolKind.fromValue(null), LspSymbolKind.unknown);
    });

    test('parses hierarchical DocumentSymbol with children', () {
      final raw = [
        {
          'name': 'UserService',
          'detail': 'class',
          'kind': 5,
          'range': {
            'start': {'line': 10, 'character': 0},
            'end': {'line': 30, 'character': 1},
          },
          'selectionRange': {
            'start': {'line': 10, 'character': 6},
            'end': {'line': 10, 'character': 17},
          },
          'children': [
            {
              'name': 'findById',
              'detail': '(id: string): User',
              'kind': 6,
              'range': {
                'start': {'line': 12, 'character': 2},
                'end': {'line': 15, 'character': 3},
              },
              'selectionRange': {
                'start': {'line': 12, 'character': 2},
                'end': {'line': 12, 'character': 10},
              },
            },
          ],
        },
      ];

      final symbols = parseDocumentSymbols(raw);
      expect(symbols.length, 1);
      final cls = symbols.first;
      expect(cls.name, 'UserService');
      expect(cls.kind, LspSymbolKind.classType);
      expect(cls.children.length, 1);

      final method = cls.children.first;
      expect(method.name, 'findById');
      expect(method.kind, LspSymbolKind.method);
      expect(method.range.start.line, 12);
    });

    test('parses flat SymbolInformation format with location and container', () {
      final raw = [
        {
          'name': 'formatCurrency',
          'kind': 12,
          'containerName': 'utils',
          'location': {
            'uri': 'file:///src/utils.ts',
            'range': {
              'start': {'line': 5, 'character': 0},
              'end': {'line': 8, 'character': 1},
            },
          },
        },
      ];

      final symbols = parseDocumentSymbols(raw);
      expect(symbols.length, 1);
      final fn = symbols.first;
      expect(fn.name, 'formatCurrency');
      expect(fn.kind, LspSymbolKind.function);
      expect(fn.containerName, 'utils');
      expect(fn.location?.uri, 'file:///src/utils.ts');
      expect(fn.range.start.line, 5);
    });

    test('returns empty list on malformed response', () {
      expect(parseDocumentSymbols(null), isEmpty);
      expect(parseDocumentSymbols('invalid'), isEmpty);
      expect(parseDocumentSymbols({'error': true}), isEmpty);
    });
  });
}
