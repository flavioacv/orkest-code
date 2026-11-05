import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_workspace_edit.dart';

/// Categorias canônicas de CodeAction (LSP 3.x).
abstract final class LspCodeActionKind {
  static const empty = '';
  static const quickFix = 'quickfix';
  static const refactor = 'refactor';
  static const refactorExtract = 'refactor.extract';
  static const refactorInline = 'refactor.inline';
  static const refactorRewrite = 'refactor.rewrite';
  static const source = 'source';
  static const sourceOrganizeImports = 'source.organizeImports';
  static const sourceFixAll = 'source.fixAll';
}

/// Um CodeAction do protocolo LSP.
class LspCodeAction {
  const LspCodeAction({
    required this.title,
    this.kind,
    this.diagnostics = const [],
    this.isPreferred = false,
    this.edit,
    this.command,
    this.data,
  });

  final String title;
  final String? kind;
  final List<LspDiagnostic> diagnostics;
  final bool isPreferred;
  final LspWorkspaceEdit? edit;
  final Map<String, dynamic>? command;
  final dynamic data;

  factory LspCodeAction.fromJson(Map<String, dynamic> json) {
    // Pode ser um Command antigo do LSP (title + command) ou um CodeAction moderno
    final title = json['title'] as String? ?? '';
    final kind = json['kind'] as String?;
    final isPreferred = json['isPreferred'] as bool? ?? false;

    final diagnosticsRaw = json['diagnostics'] as List? ?? const [];
    final diagnostics = <LspDiagnostic>[
      for (final d in diagnosticsRaw)
        if (d is Map) LspDiagnostic.fromJson(d.cast<String, dynamic>()),
    ];

    LspWorkspaceEdit? edit;
    if (json.containsKey('edit') && json['edit'] is Map) {
      edit = LspWorkspaceEdit.fromJson(
        (json['edit'] as Map).cast<String, dynamic>(),
      );
    }

    Map<String, dynamic>? command;
    if (json.containsKey('command') && json['command'] is Map) {
      command = (json['command'] as Map).cast<String, dynamic>();
    } else if (json.containsKey('command') && json['command'] is String) {
      command = {
        'command': json['command'],
        'title': title,
        'arguments': json['arguments'] ?? const [],
      };
    }

    return LspCodeAction(
      title: title,
      kind: kind,
      diagnostics: diagnostics,
      isPreferred: isPreferred,
      edit: edit,
      command: command,
      data: json['data'],
    );
  }
}

/// Decodifica a resposta de `textDocument/codeAction` (Lista de CodeAction ou Command).
List<LspCodeAction> parseCodeActions(dynamic result) {
  if (result is! List) return const [];
  final actions = <LspCodeAction>[];

  for (final item in result) {
    if (item is Map) {
      actions.add(LspCodeAction.fromJson(item.cast<String, dynamic>()));
    }
  }

  return actions;
}
