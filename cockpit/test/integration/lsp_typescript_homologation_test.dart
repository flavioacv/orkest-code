import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_launchers.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_server_pool.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/exceptions/lsp_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/domain/services/lsp_completion_edits.dart';
import 'package:path/path.dart' as p;

/// Emulador controlado de respostas do typescript-language-server (tsserver) (L02).
class _MockTypeScriptLspClient implements LspClient {
  _MockTypeScriptLspClient(this.rootPath);

  @override
  final String rootPath;

  final _diag = StreamController<LspDiagnosticsBatch>.broadcast();
  bool _running = false;
  final List<String> openedDocuments = [];
  final List<Map<String, dynamic>> receivedRequests = [];

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
  Future<void> didOpen({required String path, required String text}) async {
    openedDocuments.add(path);
  }

  @override
  Future<void> didChange({
    required String path,
    required String text,
    required int version,
  }) async {}

  @override
  Future<void> didClose({required String path}) async {
    openedDocuments.remove(path);
  }

  @override
  void cancelRequests(String path, {String? method}) {}

  @override
  Future<Result<Object?, LspError>> request(
    String method,
    Map<String, dynamic> params, {
    String? documentPath,
  }) async {
    receivedRequests.add({'method': method, 'params': params});

    switch (method) {
      case 'textDocument/completion':
        return Success({
          'isIncomplete': false,
          'items': [
            {
              'label': 'filter',
              'kind': 2, // Method
              'detail': '(method) Array<string>.filter(predicate: (value: string) => boolean): string[]',
              'documentation': 'Returns the elements of an array that meet the condition.',
              'sortText': '11',
              'textEdit': {
                'range': {
                  'start': {'line': 1, 'character': 6},
                  'end': {'line': 1, 'character': 8},
                },
                'newText': 'filter',
              },
            },
            {
              'label': 'User',
              'kind': 7, // Interface
              'detail': "import { User } from './models/user'",
              'sortText': '12',
              'textEdit': {
                'range': {
                  'start': {'line': 1, 'character': 6},
                  'end': {'line': 1, 'character': 8},
                },
                'newText': 'User',
              },
              'additionalTextEdits': [
                {
                  'range': {
                    'start': {'line': 0, 'character': 0},
                    'end': {'line': 0, 'character': 0},
                  },
                  'newText': "import { User } from './models/user';\n",
                },
              ],
              'data': {'entryNames': ['User'], 'file': '/app/main.ts'},
            },
            {
              'label': 'useState',
              'kind': 3, // Function
              'detail': 'React.useState<T>(initialState: T): [T, Dispatch<SetStateAction<T>>]',
              'insertTextFormat': 2, // Snippet
              'insertText': 'useState(\${1:initialState});',
              'sortText': '13',
            },
          ],
        });

      case 'completionItem/resolve':
        final item = Map<String, dynamic>.from(params);
        item['documentation'] = 'Resolved documentation for ${item['label']}';
        return Success(item);

      case 'textDocument/hover':
        return const Success({
          'contents': {
            'kind': 'markdown',
            'value': '```typescript\ninterface User {\n  id: string;\n  name: string;\n}\n```\nRepresents a user profile.',
          },
        });

      case 'textDocument/signatureHelp':
        return const Success({
          'signatures': [
            {
              'label': 'addEventListener(type: string, listener: EventListener): void',
              'documentation': 'Appends an event listener.',
              'parameters': [
                {'label': 'type: string'},
                {'label': 'listener: EventListener'},
              ],
            },
          ],
          'activeSignature': 0,
          'activeParameter': 1,
        });

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
    return const Success(null);
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

class _MockTypeScriptFactory implements LspClientFactory {
  _MockTypeScriptLspClient? lastCreated;

  @override
  LspClient create({required LspServerSpec spec, required String rootPath}) {
    final client = _MockTypeScriptLspClient(rootPath);
    lastCreated = client;
    return client;
  }
}

void main() {
  group('TypeScript LSP Homologation (L02)', () {
    late Directory tempDir;
    late _MockTypeScriptFactory factory;
    late LspServerPool pool;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('ts_lsp_test_');
      File('${tempDir.path}/package.json').writeAsStringSync('{"name": "test-ts-app"}');
      File('${tempDir.path}/tsconfig.json').writeAsStringSync('{"compilerOptions": {}}');

      factory = _MockTypeScriptFactory();
      pool = LspServerPool(factory);
      pool.commandOverrides = {
        'typescript': Platform.resolvedExecutable,
      };
    });

    tearDown(() {
      pool.dispose();
      tempDir.deleteSync(recursive: true);
    });

    test('recognizes TypeScript extensions and resolves project root via tsconfig.json', () {
      final tsDef = languageForPath('${tempDir.path}/src/app.ts');
      final tsxDef = languageForPath('${tempDir.path}/src/component.tsx');
      final mtsDef = languageForPath('${tempDir.path}/src/utils.mts');
      final ctsDef = languageForPath('${tempDir.path}/src/common.cts');

      expect(tsDef?.id, 'typescript');
      expect(tsxDef?.id, 'typescript');
      expect(mtsDef?.id, 'typescript');
      expect(ctsDef?.id, 'typescript');

      expect(tsDef?.defaultExecutable, 'typescript-language-server');
      expect(tsDef?.defaultArgs, ['--stdio']);
    });

    test('opens TypeScript document in pool and manages server lifecycle', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      File(filePath)
        ..createSync(recursive: true)
        ..writeAsStringSync("const items = ['a', 'b'];\nitems.fi");

      await pool.openDocument(
        path: filePath,
        text: "const items = ['a', 'b'];\nitems.fi",
        fallbackRoot: tempDir.path,
      );

      final status = pool.statusForPath(filePath);
      expect(status?.languageId, 'typescript');
      expect(status?.running, isTrue);
      expect(factory.lastCreated?.openedDocuments, contains(filePath));
    });

    test('processes TypeScript completions with imports and method signatures', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      const code = "const items = ['a', 'b'];\nitems.fi";

      await pool.openDocument(
        path: filePath,
        text: code,
        fallbackRoot: tempDir.path,
      );

      final completions = await pool.completions(filePath, 1, 8);
      expect(completions.length, 2); // 'filter' and 'User'

      final filterItem = completions.firstWhere((c) => c.label == 'filter');
      expect(filterItem.detail, contains('(method) Array<string>.filter'));

      final userItem = completions.firstWhere((c) => c.label == 'User');
      expect(userItem.detail, contains("import { User } from './models/user'"));

      // Aplica completion do User com auto-import ESM
      final applied = applyCompletion(code, 32, userItem);
      expect(applied?.text, startsWith("import { User } from './models/user';\n"));
      expect(applied?.text, contains('items.User'));
    });

    test('resolves TypeScript completion items with documentation', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      const code = "const items = ['a', 'b'];\nitems.fi";

      await pool.openDocument(
        path: filePath,
        text: code,
        fallbackRoot: tempDir.path,
      );

      final completions = await pool.completions(filePath, 1, 7);
      final userItem = completions.firstWhere((c) => c.label == 'User');

      final resolved = await pool.resolveCompletion(filePath, userItem);
      expect(resolved?.raw['documentation'], contains('Resolved documentation for User'));
    });

    test('retrieves TypeScript hover information and typed interfaces', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      await pool.openDocument(
        path: filePath,
        text: 'const user: User = { id: "1", name: "Alice" };',
        fallbackRoot: tempDir.path,
      );

      final hoverText = await pool.hover(filePath, 0, 14);
      expect(hoverText, contains('interface User'));
      expect(hoverText, contains('Represents a user profile.'));
    });

    test('retrieves TypeScript signature help with parameters and active parameter index', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      await pool.openDocument(
        path: filePath,
        text: "element.addEventListener('click', () => {});",
        fallbackRoot: tempDir.path,
      );

      final sigHelp = await pool.signatureHelp(filePath, 0, 35);
      expect(sigHelp, contains('addEventListener'));
      expect(sigHelp, contains('listener: EventListener'));
    });

    test('discards delayed completion and resolve replies if document is edited concurrently', () async {
      final filePath = p.join(tempDir.path, 'src', 'index.ts');
      await pool.openDocument(
        path: filePath,
        text: 'let a = 1;',
        fallbackRoot: tempDir.path,
      );

      final completionsFuture = pool.completions(filePath, 0, 8);

      // Edição concorrente avança a versão do documento
      await pool.changeDocument(path: filePath, text: 'let a = 2;\n// updated');

      final delayedCompletions = await completionsFuture;
      expect(delayedCompletions, isEmpty); // descartado por mudança de versão
    });
  });
}
