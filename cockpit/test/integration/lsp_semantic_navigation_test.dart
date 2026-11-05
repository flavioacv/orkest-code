import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_server_pool.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/core/domain/exceptions/lsp_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:path/path.dart' as p;

class _SemanticMockClient implements LspClient {
  _SemanticMockClient(this.rootPath);

  @override
  final String rootPath;

  final _diag = StreamController<LspDiagnosticsBatch>.broadcast();
  bool _running = false;

  @override
  Stream<LspDiagnosticsBatch> get diagnostics => _diag.stream;

  @override
  bool get isRunning => _running;

  @override
  dynamic get semanticTokensLegend => null;

  @override
  Future<Result<void, LspError>> start() async {
    _running = true;
    return const Success(null);
  }

  @override
  Future<void> didOpen({required String path, required String text}) async {}

  @override
  Future<void> didChange({required String path, required String text, required int version}) async {}

  @override
  Future<void> didClose({required String path}) async {}

  @override
  void cancelRequests(String path, {String? method}) {}

  @override
  Future<Result<Object?, LspError>> request(
    String method,
    Map<String, dynamic> params, {
    String? documentPath,
  }) async {
    switch (method) {
      case 'textDocument/references':
        return Success([
          {
            'uri': 'file:///workspace/src/caller1.dart',
            'range': {
              'start': {'line': 15, 'character': 4},
              'end': {'line': 15, 'character': 12},
            },
          },
          {
            'uri': 'file:///workspace/src/caller2.dart',
            'range': {
              'start': {'line': 42, 'character': 10},
              'end': {'line': 42, 'character': 18},
            },
          },
        ]);

      case 'textDocument/implementation':
        return Success([
          {
            'targetUri': 'file:///workspace/lib/impl.dart',
            'targetRange': {
              'start': {'line': 8, 'character': 0},
              'end': {'line': 25, 'character': 1},
            },
            'originSelectionRange': {
              'start': {'line': 8, 'character': 6},
              'end': {'line': 8, 'character': 18},
            },
          },
        ]);

      case 'textDocument/documentSymbol':
        return Success([
          {
            'name': 'OrderController',
            'kind': 5, // Class
            'range': {
              'start': {'line': 5, 'character': 0},
              'end': {'line': 50, 'character': 1},
            },
            'selectionRange': {
              'start': {'line': 5, 'character': 6},
              'end': {'line': 5, 'character': 21},
            },
            'children': [
              {
                'name': 'checkout',
                'kind': 6, // Method
                'range': {
                  'start': {'line': 12, 'character': 2},
                  'end': {'line': 20, 'character': 3},
                },
                'selectionRange': {
                  'start': {'line': 12, 'character': 2},
                  'end': {'line': 12, 'character': 10},
                },
              },
            ],
          },
        ]);

      case 'workspace/symbol':
        final query = params['query'] as String? ?? '';
        return Success([
          {
            'name': 'OrderService',
            'kind': 5, // Class
            'containerName': 'orders',
            'location': {
              'uri': 'file:///workspace/lib/order_service.dart',
              'range': {
                'start': {'line': 1, 'character': 0},
                'end': {'line': 30, 'character': 1},
              },
            },
          },
          if (query.contains('Repo') || query.isEmpty)
            {
              'name': 'OrderRepository',
              'kind': 11, // Interface
              'containerName': 'orders',
              'location': {
                'uri': 'file:///workspace/lib/order_repo.dart',
                'range': {
                  'start': {'line': 2, 'character': 0},
                  'end': {'line': 15, 'character': 1},
                },
              },
            },
        ]);

      default:
        return const Failure(LspError('Unsupported method'));
    }
  }

  @override
  Future<Result<Object?, LspError>> definition(
    String path, {
    required int line,
    required int character,
  }) async {
    return const Success({
      'uri': 'file:///workspace/lib/definition.dart',
      'range': {
        'start': {'line': 10, 'character': 0},
        'end': {'line': 10, 'character': 10},
      },
    });
  }

  @override
  Future<Result<Object?, LspError>> semanticTokensFull(String path) async {
    return const Success(null);
  }

  @override
  Future<void> kill() async {
    _running = false;
  }

  @override
  void dispose() {
    _running = false;
    _diag.close();
  }
}

class _SemanticFactory implements LspClientFactory {
  @override
  LspClient create({required LspServerSpec spec, required String rootPath}) {
    return _SemanticMockClient(rootPath);
  }
}

void main() {
  group('LSP Semantic Navigation & Unified Search (L03)', () {
    late Directory tempDir;
    late LspServerPool pool;
    late String filePath;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('lsp_nav_test_');
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('name: test_proj\n');

      pool = LspServerPool(_SemanticFactory());
      pool.commandOverrides = {'dart': Platform.resolvedExecutable};

      filePath = p.join(tempDir.path, 'lib', 'main.dart');
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsStringSync('void main() {}\n');

      await pool.openDocument(path: filePath, text: 'void main() {}\n', fallbackRoot: tempDir.path);
    });

    tearDown(() {
      pool.dispose();
      tempDir.deleteSync(recursive: true);
    });

    test('retrieves all references across workspace files', () async {
      final refs = await pool.references(filePath, 0, 5);

      expect(refs.length, 2);
      expect(refs[0].uri, 'file:///workspace/src/caller1.dart');
      expect(refs[0].range.start.line, 15);
      expect(refs[0].range.start.character, 4);

      expect(refs[1].uri, 'file:///workspace/src/caller2.dart');
      expect(refs[1].range.start.line, 42);
      expect(refs[1].range.start.character, 10);
    });

    test('retrieves implementations with LocationLink conversion', () async {
      final impls = await pool.implementation(filePath, 0, 5);

      expect(impls.length, 1);
      expect(impls.first.uri, 'file:///workspace/lib/impl.dart');
      expect(impls.first.range.start.line, 8);
    });

    test('retrieves document symbols outline hierarchy', () async {
      final symbols = await pool.documentSymbols(filePath);

      expect(symbols.length, 1);
      final cls = symbols.first;
      expect(cls.name, 'OrderController');
      expect(cls.kind, LspSymbolKind.classType);
      expect(cls.children.length, 1);

      final method = cls.children.first;
      expect(method.name, 'checkout');
      expect(method.kind, LspSymbolKind.method);
    });

    test('performs workspace-wide symbol search by query', () async {
      final allSymbols = await pool.workspaceSymbols('', path: filePath);
      expect(allSymbols.length, 2);
      expect(allSymbols.map((s) => s.name), contains('OrderService'));
      expect(allSymbols.map((s) => s.name), contains('OrderRepository'));

      final filtered = await pool.workspaceSymbols('Repo', path: filePath);
      expect(filtered.any((s) => s.name == 'OrderRepository'), isTrue);
    });
  });
}
