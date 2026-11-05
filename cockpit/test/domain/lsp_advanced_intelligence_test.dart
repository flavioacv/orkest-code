import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_inlay_hint.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_hierarchy.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_code_lens.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/core/domain/services/structural_analysis_service.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_server_pool.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:orkest_code/app/core/domain/exceptions/lsp_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';

class _FakeLspClientFactory implements LspClientFactory {
  const _FakeLspClientFactory();

  @override
  LspClient create({required LspServerSpec spec, required String rootPath}) {
    return _FakeLspClient();
  }
}

class _FakeLspClient implements LspClient {
  _FakeLspClient();

  final bool _running = true;

  @override
  bool get isRunning => _running;

  @override
  Future<Result<Object?, LspError>> request(
    String method,
    Map<String, dynamic> params, {
    String? documentPath,
  }) async {
    return const Success(null);
  }

  @override
  void dispose() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('LSP Inlay Hints (L06)', () {
    test('parses type and parameter inlay hints with label parts and tooltips', () {
      final jsonList = [
        {
          'position': {'line': 12, 'character': 15},
          'label': ': String',
          'kind': 1, // type
          'paddingLeft': true,
          'paddingRight': false,
          'tooltip': 'Inferred return type',
        },
        {
          'position': {'line': 14, 'character': 8},
          'label': [
            {'value': 'timeout:'},
            {'value': ' Duration'},
          ],
          'kind': 2, // parameter
          'paddingLeft': false,
          'paddingRight': true,
        },
      ];

      final hints = parseInlayHints(jsonList);
      expect(hints.length, equals(2));

      // Tipo inferido
      expect(hints[0].position.line, equals(12));
      expect(hints[0].position.character, equals(15));
      expect(hints[0].label, equals(': String'));
      expect(hints[0].kind, equals(LspInlayHintKind.type));
      expect(hints[0].paddingLeft, isTrue);
      expect(hints[0].tooltip, equals('Inferred return type'));

      // Nome de parâmetro com partes
      expect(hints[1].position.line, equals(14));
      expect(hints[1].label, equals('timeout: Duration'));
      expect(hints[1].kind, equals(LspInlayHintKind.parameter));
      expect(hints[1].paddingRight, isTrue);
    });

    test('degrades gracefully on null or malformed response', () {
      expect(parseInlayHints(null), isEmpty);
      expect(parseInlayHints('invalid'), isEmpty);
      expect(parseInlayHints([123, 'bad']), isEmpty);
    });
  });

  group('LSP Call & Type Hierarchy (L06)', () {
    test('parses call hierarchy item and incoming/outgoing calls', () {
      final itemJson = {
        'name': 'processPayment',
        'kind': 6, // method
        'uri': 'file:///repo/payment.dart',
        'range': {
          'start': {'line': 10, 'character': 2},
          'end': {'line': 20, 'character': 3},
        },
        'selectionRange': {
          'start': {'line': 10, 'character': 7},
          'end': {'line': 10, 'character': 21},
        },
        'detail': 'Future<PaymentResult> Function()',
      };

      final item = LspCallHierarchyItem.fromJson(itemJson);
      expect(item.name, equals('processPayment'));
      expect(item.kind, equals(LspSymbolKind.method));
      expect(item.uri, equals('file:///repo/payment.dart'));
      expect(item.range.start.line, equals(10));
      expect(item.detail, equals('Future<PaymentResult> Function()'));

      final incomingJson = [
        {
          'from': itemJson,
          'fromRanges': [
            {
              'start': {'line': 45, 'character': 12},
              'end': {'line': 45, 'character': 26},
            }
          ],
        }
      ];

      final incoming = parseCallHierarchyIncomingCalls(incomingJson);
      expect(incoming.length, equals(1));
      expect(incoming[0].from.name, equals('processPayment'));
      expect(incoming[0].fromRanges.length, equals(1));
      expect(incoming[0].fromRanges[0].start.line, equals(45));

      final outgoingJson = [
        {
          'to': itemJson,
          'fromRanges': [
            {
              'start': {'line': 15, 'character': 4},
              'end': {'line': 15, 'character': 18},
            }
          ],
        }
      ];

      final outgoing = parseCallHierarchyOutgoingCalls(outgoingJson);
      expect(outgoing.length, equals(1));
      expect(outgoing[0].to.name, equals('processPayment'));
    });

    test('parses type hierarchy item and subtypes/supertypes', () {
      final typeJson = [
        {
          'name': 'BaseController',
          'kind': 5, // class
          'uri': 'file:///repo/base.dart',
          'range': {
            'start': {'line': 1, 'character': 0},
            'end': {'line': 50, 'character': 1},
          },
        }
      ];

      final types = parseTypeHierarchyItems(typeJson);
      expect(types.length, equals(1));
      expect(types[0].name, equals('BaseController'));
      expect(types[0].kind, equals(LspSymbolKind.classType));
    });
  });

  group('LSP CodeLens (L06)', () {
    test('parses code lenses with resolved and unresolved commands', () {
      final lensesJson = [
        {
          'range': {
            'start': {'line': 5, 'character': 0},
            'end': {'line': 5, 'character': 10},
          },
          'command': {
            'title': '4 references',
            'command': 'editor.action.showReferences',
            'arguments': ['file:///repo/main.dart', 5, 2],
          },
        },
        {
          'range': {
            'start': {'line': 15, 'character': 0},
            'end': {'line': 15, 'character': 8},
          },
          'data': {'id': 'lazy-resolve-1'},
        },
      ];

      final lenses = parseCodeLenses(lensesJson);
      expect(lenses.length, equals(2));
      expect(lenses[0].command?.title, equals('4 references'));
      expect(lenses[0].command?.command, equals('editor.action.showReferences'));
      expect(lenses[0].command?.arguments?.length, equals(3));

      expect(lenses[1].command, isNull);
      expect(lenses[1].data['id'], equals('lazy-resolve-1'));
    });
  });

  group('StructuralAnalysisService (L06)', () {
    test('detects code duplications across lines with high similarity', () {
      const code = '''
void handlerA() {
  final client = HttpClient();
  final request = client.getUrl(uri);
  final response = request.close();
  return response;
}

// comentário separador

void handlerB() {
  final client = HttpClient();
  final request = client.getUrl(uri);
  final response = request.close();
  return response;
}
''';

      final duplications = StructuralAnalysisService.findDuplications(
        code,
        minLines: 3,
        similarityThreshold: 0.85,
      );

      expect(duplications.isNotEmpty, isTrue);
      expect(duplications[0].lineCount, equals(3));
      expect(duplications[0].similarity, greaterThanOrEqualTo(0.85));
      expect(duplications[0].originalRange.start.line, lessThan(duplications[0].duplicateRange.start.line));
    });

    test('searches structural patterns with identifier captures', () {
      const source = '''
final name = user.name;
final email = user.email;
final phone = contact.phone;
''';

      final matches = StructuralAnalysisService.searchPattern(
        source,
        'final \$FIELD = user.\$PROP;',
      );

      expect(matches.length, equals(2));
      expect(matches[0].captures['FIELD'], equals('name'));
      expect(matches[0].captures['PROP'], equals('name'));
      expect(matches[1].captures['FIELD'], equals('email'));
      expect(matches[1].captures['PROP'], equals('email'));
    });

    test('audits intelligence subsets and recommends viable features per language', () {
      // Dart: ecossistema completo viável
      final dartAudit = StructuralAnalysisService.auditLanguageSubset(
        languageId: 'dart',
        serverAvailable: true,
        measuredLatencyMs: 18.0,
      );
      expect(dartAudit.supportsInlayHints, isTrue);
      expect(dartAudit.supportsCallHierarchy, isTrue);
      expect(dartAudit.supportsTypeHierarchy, isTrue);
      expect(dartAudit.supportsCodeLens, isTrue);
      expect(dartAudit.recommendedSubset, contains('inlayHints'));

      // TypeScript: subset útil focado em inlays e hierarquias sem overhead de CodeLens
      final tsAudit = StructuralAnalysisService.auditLanguageSubset(
        languageId: 'typescript',
        serverAvailable: true,
      );
      expect(tsAudit.supportsCodeLens, isFalse);
      expect(tsAudit.recommendedSubset, contains('inlayHints'));

      // JSON / Tier 3: recursos desabilitados por design
      final jsonAudit = StructuralAnalysisService.auditLanguageSubset(
        languageId: 'json',
        serverAvailable: true,
      );
      expect(jsonAudit.recommendedSubset, isEmpty);

      // Servidor indisponível: fallback seguro
      final missingAudit = StructuralAnalysisService.auditLanguageSubset(
        languageId: 'rust',
        serverAvailable: false,
      );
      expect(missingAudit.recommendedSubset, isEmpty);
      expect(missingAudit.averageLatencyMs, equals(0.0));
    });
  });

  group('LspServerPool Advanced Intelligence Integration (L06)', () {
    test('methods return empty collections when no server is registered or active', () async {
      final pool = LspServerPool(const _FakeLspClientFactory());

      // Documento não aberto no pool
      final inlays = await pool.inlayHints(
        '/workspace/non_opened.dart',
        const LspRange(LspPosition(0, 0), LspPosition(10, 0)),
      );
      expect(inlays, isEmpty);

      final calls = await pool.prepareCallHierarchy('/workspace/non_opened.dart', 5, 2);
      expect(calls, isEmpty);

      final types = await pool.prepareTypeHierarchy('/workspace/non_opened.dart', 5, 2);
      expect(types, isEmpty);

      final lenses = await pool.codeLenses('/workspace/non_opened.dart');
      expect(lenses, isEmpty);
    });
  });
}
