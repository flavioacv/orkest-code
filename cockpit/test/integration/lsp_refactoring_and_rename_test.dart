import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_server_pool.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_code_action.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/exceptions/lsp_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/domain/services/safe_workspace_edit_service.dart';
import 'package:path/path.dart' as p;

class _RefactorMockClient implements LspClient {
  _RefactorMockClient(this.rootPath);

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
  Future<void> didChange({
    required String path,
    required String text,
    required int version,
  }) async {}

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
      case 'textDocument/prepareRename':
        final pos = params['position'] as Map;
        final line = pos['line'] as int;
        if (line == 10) {
          return Success({
            'range': {
              'start': {'line': 10, 'character': 6},
              'end': {'line': 10, 'character': 17},
            },
            'placeholder': 'UserService',
          });
        }
        return const Success(null);

      case 'textDocument/rename':
        final newName = params['newName'] as String;
        return Success({
          'changes': {
            'file:///workspace/lib/user_service.dart': [
              {
                'range': {
                  'start': {'line': 0, 'character': 6},
                  'end': {'line': 0, 'character': 17},
                },
                'newText': newName,
              },
            ],
            'file:///workspace/lib/consumer.dart': [
              {
                'range': {
                  'start': {'line': 0, 'character': 6},
                  'end': {'line': 0, 'character': 17},
                },
                'newText': newName,
              },
            ],
          },
        });

      case 'textDocument/codeAction':
        final context = params['context'] as Map? ?? {};
        final only = context['only'] as List?;

        if (only != null && only.contains(LspCodeActionKind.sourceOrganizeImports)) {
          return Success([
            {
              'title': 'Organize Imports',
              'kind': LspCodeActionKind.sourceOrganizeImports,
              'isPreferred': true,
              'edit': {
                'changes': {
                  params['textDocument']['uri']: [
                    {
                      'range': {
                        'start': {'line': 0, 'character': 0},
                        'end': {'line': 2, 'character': 0},
                      },
                      'newText': 'import "dart:async";\nimport "dart:io";\n',
                    },
                  ],
                },
              },
            },
          ]);
        }

        return Success([
          {
            'title': 'Quick Fix: Add missing type annotation',
            'kind': LspCodeActionKind.quickFix,
            'isPreferred': true,
            'data': {'id': 'quickfix-type'},
          },
          {
            'title': 'Refactor: Extract Local Variable',
            'kind': LspCodeActionKind.refactorExtract,
          },
        ]);

      case 'codeAction/resolve':
        return Success({
          'title': params['title'],
          'kind': params['kind'],
          'isPreferred': true,
          'edit': {
            'changes': {
              'file:///workspace/lib/user_service.dart': [
                {
                  'range': {
                    'start': {'line': 5, 'character': 0},
                    'end': {'line': 5, 'character': 0},
                  },
                  'newText': 'final String ',
                },
              ],
            },
          },
        });

      case 'textDocument/formatting':
        return Success([
          {
            'range': {
              'start': {'line': 0, 'character': 0},
              'end': {'line': 0, 'character': 4},
            },
            'newText': '  ',
          },
        ]);

      default:
        return const Success(null);
    }
  }

  @override
  Future<Result<Object?, LspError>> definition(
    String path, {
    required int line,
    required int character,
  }) async => const Success(null);

  @override
  Future<Result<Object?, LspError>> semanticTokensFull(String path) async =>
      const Success(null);

  @override
  Future<void> kill() async {
    _running = false;
  }

  @override
  void dispose() {
    _running = false;
    if (!_diag.isClosed) _diag.close();
  }
}

class _RefactorFactory implements LspClientFactory {
  @override
  LspClient create({required LspServerSpec spec, required String rootPath}) {
    return _RefactorMockClient(rootPath);
  }
}

void main() {
  group('LSP Refactoring, Rename & Workspace Edits (L04)', () {
    late Directory tempDir;
    late LspServerPool pool;
    late String mainDartPath;
    late String consumerDartPath;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('lsp_refactor_test_');
      final pubspec = File(p.join(tempDir.path, 'pubspec.yaml'));
      pubspec.writeAsStringSync('name: test_project\n');

      final libDir = Directory(p.join(tempDir.path, 'lib'))..createSync();
      mainDartPath = p.join(libDir.path, 'user_service.dart');
      File(mainDartPath).writeAsStringSync('''
import "dart:io";
import "dart:async";

class UserService {
  void run() {}
}
''');

      consumerDartPath = p.join(libDir.path, 'consumer.dart');
      File(consumerDartPath).writeAsStringSync('''
import 'user_service.dart';
final UserService svc = UserService();
''');

      pool = LspServerPool(_RefactorFactory());
      pool.commandOverrides = {'dart': Platform.resolvedExecutable};
    });

    tearDown(() {
      pool.dispose();
      tempDir.deleteSync(recursive: true);
    });

    test('validates prepareRename with range and placeholder', () async {
      await pool.openDocument(
        path: mainDartPath,
        text: File(mainDartPath).readAsStringSync(),
        fallbackRoot: tempDir.path,
      );

      final valid = await pool.prepareRename(mainDartPath, 10, 8);
      expect(valid.canRename, isTrue);
      expect(valid.placeholder, 'UserService');
      expect(valid.range?.start.line, 10);

      final invalid = await pool.prepareRename(mainDartPath, 0, 0);
      expect(invalid.canRename, isFalse);
    });

    test('executes rename across multiple files and applies changes safely', () async {
      await pool.openDocument(
        path: mainDartPath,
        text: File(mainDartPath).readAsStringSync(),
        fallbackRoot: tempDir.path,
      );

      final edit = await pool.rename(mainDartPath, 10, 8, 'CustomerService');
      expect(edit, isNotNull);
      expect(edit!.changes.length, 2);

      const service = SafeWorkspaceEditService();
      final preview = service.generatePreview(
        edit: edit,
        currentFileContents: {
          '/workspace/lib/user_service.dart': 'class UserService {}',
          '/workspace/lib/consumer.dart': 'final UserService svc = UserService();',
        },
      );

      expect(preview.canApplySafely, isTrue);
      expect(preview.fileDiffs.length, 2);

      final vfs = {
        '/workspace/lib/user_service.dart': 'class UserService {}',
        '/workspace/lib/consumer.dart': 'final UserService svc = UserService();',
      };

      final tx = await service.apply(
        edit: edit,
        readFile: (path) async => vfs[path] ?? '',
        writeFile: (path, content) async {
          vfs[path] = content;
        },
      );

      expect(tx.success, isTrue);
      expect(vfs['/workspace/lib/user_service.dart'], 'class CustomerService {}');
      expect(vfs['/workspace/lib/consumer.dart'], 'final CustomerService svc = UserService();');
    });

    test('requests code actions with diagnostics and filters organize imports', () async {
      await pool.openDocument(
        path: mainDartPath,
        text: File(mainDartPath).readAsStringSync(),
        fallbackRoot: tempDir.path,
      );

      final actions = await pool.codeActions(
        mainDartPath,
        const LspRange(LspPosition(0, 0), LspPosition(1, 0)),
        diagnostics: const [
          LspDiagnostic(
            range: LspRange(LspPosition(5, 0), LspPosition(5, 10)),
            message: 'Type annotation missing',
            severity: LspSeverity.warning,
          ),
        ],
      );

      expect(actions.length, 2);
      expect(actions.first.kind, LspCodeActionKind.quickFix);
      expect(actions.first.isPreferred, isTrue);

      // Resolve a code action
      final resolved = await pool.resolveCodeAction(mainDartPath, actions.first);
      expect(resolved, isNotNull);
      expect(resolved!.edit, isNotNull);

      // Organize Imports
      final imports = await pool.organizeImports(
        mainDartPath,
        const LspRange(LspPosition(0, 0), LspPosition(2, 0)),
      );
      expect(imports.length, 1);
      expect(imports.first.kind, LspCodeActionKind.sourceOrganizeImports);
      expect(imports.first.edit, isNotNull);
    });

    test('formats document via textDocument/formatting and applies edits', () async {
      await pool.openDocument(
        path: mainDartPath,
        text: '    class Foo {}',
        fallbackRoot: tempDir.path,
      );

      final edits = await pool.formatDocument(mainDartPath);
      expect(edits.length, 1);
      expect(edits.first.newText, '  ');
    });
  });
}

