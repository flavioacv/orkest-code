import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_code_action.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_workspace_edit.dart';

void main() {
  group('LspWorkspaceEdit & LspCodeAction (L04)', () {
    test('parses classic changes map format', () {
      final json = {
        'changes': {
          'file:///path/to/a.dart': [
            {
              'range': {
                'start': {'line': 1, 'character': 2},
                'end': {'line': 1, 'character': 5},
              },
              'newText': 'bar',
            },
          ],
        },
      };

      final edit = LspWorkspaceEdit.fromJson(json);
      expect(edit.isEmpty, isFalse);
      expect(edit.changes.length, 1);
      expect(edit.consolidatedEdits.containsKey('file:///path/to/a.dart'), isTrue);
      expect(edit.consolidatedEdits['file:///path/to/a.dart']!.first.newText, 'bar');
      expect(edit.allAffectedUris, contains('file:///path/to/a.dart'));
    });

    test('parses modern documentChanges with versions and resource operations', () {
      final json = {
        'documentChanges': [
          {
            'textDocument': {
              'uri': 'file:///path/to/b.dart',
              'version': 42,
            },
            'edits': [
              {
                'range': {
                  'start': {'line': 0, 'character': 0},
                  'end': {'line': 0, 'character': 3},
                },
                'newText': 'int',
              },
            ],
          },
          {
            'kind': 'create',
            'uri': 'file:///path/to/c.dart',
            'options': {'overwrite': true},
          },
          {
            'kind': 'rename',
            'oldUri': 'file:///path/to/old.dart',
            'newUri': 'file:///path/to/new.dart',
          },
          {
            'kind': 'delete',
            'uri': 'file:///path/to/temp.dart',
          },
        ],
      };

      final edit = LspWorkspaceEdit.fromJson(json);
      expect(edit.documentChanges.length, 1);
      expect(edit.documentChanges.first.version, 42);
      expect(edit.creates.length, 1);
      expect(edit.creates.first.uri, 'file:///path/to/c.dart');
      expect(edit.creates.first.overwrite, isTrue);
      expect(edit.renames.length, 1);
      expect(edit.renames.first.oldUri, 'file:///path/to/old.dart');
      expect(edit.renames.first.newUri, 'file:///path/to/new.dart');
      expect(edit.deletes.length, 1);
      expect(edit.deletes.first.uri, 'file:///path/to/temp.dart');

      final uris = edit.allAffectedUris;
      expect(uris, containsAll([
        'file:///path/to/b.dart',
        'file:///path/to/c.dart',
        'file:///path/to/old.dart',
        'file:///path/to/new.dart',
        'file:///path/to/temp.dart',
      ]));
    });

    test('parses prepareRename response formats', () {
      // Formato com range e placeholder
      final withPlaceholder = LspPrepareRenameResult.fromJson({
        'range': {
          'start': {'line': 10, 'character': 4},
          'end': {'line': 10, 'character': 12},
        },
        'placeholder': 'oldMethod',
      });
      expect(withPlaceholder.canRename, isTrue);
      expect(withPlaceholder.placeholder, 'oldMethod');
      expect(withPlaceholder.range?.start.line, 10);

      // Formato somente range
      final rangeOnly = LspPrepareRenameResult.fromJson({
        'start': {'line': 2, 'character': 0},
        'end': {'line': 2, 'character': 5},
      });
      expect(rangeOnly.canRename, isTrue);
      expect(rangeOnly.placeholder, isNull);

      // Nulo ou não renomeável
      final cannot = LspPrepareRenameResult.fromJson(null);
      expect(cannot.canRename, isFalse);
    });

    test('parses CodeAction list with kinds and diagnostics', () {
      final jsonList = [
        {
          'title': 'Organize Imports',
          'kind': LspCodeActionKind.sourceOrganizeImports,
          'isPreferred': true,
          'edit': {
            'changes': {
              'file:///path/main.dart': [
                {
                  'range': {
                    'start': {'line': 0, 'character': 0},
                    'end': {'line': 1, 'character': 0},
                  },
                  'newText': 'import "dart:async";\n',
                },
              ],
            },
          },
        },
        {
          'title': 'Extract Method',
          'kind': LspCodeActionKind.refactorExtract,
          'command': {
            'command': 'refactor.extract',
            'title': 'Extract Method',
          },
        },
      ];

      final actions = parseCodeActions(jsonList);
      expect(actions.length, 2);

      final organize = actions.first;
      expect(organize.title, 'Organize Imports');
      expect(organize.kind, LspCodeActionKind.sourceOrganizeImports);
      expect(organize.isPreferred, isTrue);
      expect(organize.edit, isNotNull);
      expect(organize.edit!.consolidatedEdits.containsKey('file:///path/main.dart'), isTrue);

      final extract = actions.last;
      expect(extract.kind, LspCodeActionKind.refactorExtract);
      expect(extract.command?['command'], 'refactor.extract');
    });
  });
}
