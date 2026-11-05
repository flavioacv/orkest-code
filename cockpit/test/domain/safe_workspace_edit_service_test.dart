import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_workspace_edit.dart';
import 'package:orkest_code/app/core/domain/services/safe_workspace_edit_service.dart';

void main() {
  group('SafeWorkspaceEditService (L04)', () {
    const service = SafeWorkspaceEditService();

    test('generates preview with correct diffs, edit counts and resource flags', () {
      final edit = LspWorkspaceEdit.fromJson({
        'changes': {
          'file:///src/service.dart': [
            {
              'range': {
                'start': {'line': 0, 'character': 6},
                'end': {'line': 0, 'character': 13},
              },
              'newText': 'NewUser',
            },
          ],
        },
        'documentChanges': [
          {
            'kind': 'create',
            'uri': 'file:///src/new_file.dart',
          },
          {
            'kind': 'rename',
            'oldUri': 'file:///src/old_name.dart',
            'newUri': 'file:///src/renamed.dart',
          },
          {
            'kind': 'delete',
            'uri': 'file:///src/unused.dart',
          },
        ],
      });

      final currentContents = {
        '/src/service.dart': 'class OldUser {}',
        '/src/unused.dart': '// to be deleted',
      };

      final preview = service.generatePreview(
        edit: edit,
        currentFileContents: currentContents,
      );

      expect(preview.hasVersionConflict, isFalse);
      expect(preview.totalEdits, 1);
      expect(preview.createdFiles, contains('/src/new_file.dart'));
      expect(preview.renamedFiles['/src/old_name.dart'], '/src/renamed.dart');
      expect(preview.deletedFiles, contains('/src/unused.dart'));

      final serviceDiff = preview.fileDiffs.firstWhere((d) => d.path == '/src/service.dart');
      expect(serviceDiff.originalContent, 'class OldUser {}');
      expect(serviceDiff.newContent, 'class NewUser {}');
      expect(serviceDiff.editsCount, 1);
      expect(preview.canApplySafely, isTrue);
    });

    test('detects version mismatch and blocks preview/apply safely', () async {
      final edit = LspWorkspaceEdit.fromJson({
        'documentChanges': [
          {
            'textDocument': {
              'uri': 'file:///src/app.dart',
              'version': 5, // versão exigida
            },
            'edits': [
              {
                'range': {
                  'start': {'line': 0, 'character': 0},
                  'end': {'line': 0, 'character': 3},
                },
                'newText': 'void',
              },
            ],
          },
        ],
      });

      // Simula que o buffer aberto já está na versão 6
      final openVersions = {'/src/app.dart': 6};

      final preview = service.generatePreview(
        edit: edit,
        currentFileContents: {'/src/app.dart': 'int main() {}'},
        openDocumentVersions: openVersions,
      );

      expect(preview.hasVersionConflict, isTrue);
      expect(preview.conflictingFiles, contains('/src/app.dart'));
      expect(preview.canApplySafely, isFalse);

      // Tentativa de apply deve falhar imediatamente sem tocar em nada
      var writeCalled = false;
      final result = await service.apply(
        edit: edit,
        openDocumentVersions: openVersions,
        readFile: (path) async => 'int main() {}',
        writeFile: (path, content) async {
          writeCalled = true;
        },
      );

      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Version mismatch'));
      expect(writeCalled, isFalse);
    });

    test('applies multi-file edit atomically and supports reversible undo', () async {
      final vfs = <String, String>{
        '/project/lib/user.dart': 'class OldUser {}',
        '/project/lib/repo.dart': 'OldUser getUser() => OldUser();',
        '/project/lib/obsolete.dart': '// remove me',
      };

      final edit = LspWorkspaceEdit.fromJson({
        'changes': {
          'file:///project/lib/user.dart': [
            {
              'range': {
                'start': {'line': 0, 'character': 6},
                'end': {'line': 0, 'character': 13},
              },
              'newText': 'NewUser',
            },
          ],
          'file:///project/lib/repo.dart': [
            {
              'range': {
                'start': {'line': 0, 'character': 0},
                'end': {'line': 0, 'character': 7},
              },
              'newText': 'NewUser',
            },
            {
              'range': {
                'start': {'line': 0, 'character': 21},
                'end': {'line': 0, 'character': 28},
              },
              'newText': 'NewUser',
            },
          ],
        },
        'documentChanges': [
          {
            'kind': 'create',
            'uri': 'file:///project/lib/models.dart',
          },
          {
            'kind': 'delete',
            'uri': 'file:///project/lib/obsolete.dart',
          },
        ],
      });

      final result = await service.apply(
        edit: edit,
        readFile: (path) async => vfs[path] ?? '',
        writeFile: (path, content) async {
          vfs[path] = content;
        },
        deleteFile: (path) async {
          vfs.remove(path);
        },
      );

      expect(result.success, isTrue);
      expect(vfs['/project/lib/user.dart'], 'class NewUser {}');
      expect(vfs['/project/lib/repo.dart'], 'NewUser getUser() => NewUser();');
      expect(vfs.containsKey('/project/lib/models.dart'), isTrue);
      expect(vfs.containsKey('/project/lib/obsolete.dart'), isFalse);

      // Testa a reversibilidade com undo
      expect(result.undoAction, isNotNull);
      await result.undoAction!();

      expect(vfs['/project/lib/user.dart'], 'class OldUser {}');
      expect(vfs['/project/lib/repo.dart'], 'OldUser getUser() => OldUser();');
      expect(vfs.containsKey('/project/lib/models.dart'), isFalse);
      expect(vfs['/project/lib/obsolete.dart'], '// remove me');
    });

    test('automatically rolls back prior modifications when a file write fails midway', () async {
      final vfs = <String, String>{
        '/project/lib/a.dart': 'original A',
        '/project/lib/b.dart': 'original B',
      };

      final edit = LspWorkspaceEdit.fromJson({
        'changes': {
          'file:///project/lib/a.dart': [
            {
              'range': {
                'start': {'line': 0, 'character': 9},
                'end': {'line': 0, 'character': 10},
              },
              'newText': 'MODIFIED',
            },
          ],
          'file:///project/lib/b.dart': [
            {
              'range': {
                'start': {'line': 0, 'character': 9},
                'end': {'line': 0, 'character': 10},
              },
              'newText': 'MODIFIED',
            },
          ],
        },
      });

      // Na escrita de b.dart, simula falha de permissão / I/O
      final result = await service.apply(
        edit: edit,
        readFile: (path) async => vfs[path] ?? '',
        writeFile: (path, content) async {
          if (path.contains('b.dart')) {
            throw FileSystemException('Disk write failed', path);
          }
          vfs[path] = content;
        },
      );

      // Transação deve reportar falha
      expect(result.success, isFalse);
      expect(result.errorMessage, contains('Disk write failed'));
      expect(result.rolledBackFiles, contains('/project/lib/a.dart'));

      // a.dart deve ter sido revertido para o conteúdo original!
      expect(vfs['/project/lib/a.dart'], 'original A');
      expect(vfs['/project/lib/b.dart'], 'original B');
    });
  });
}
