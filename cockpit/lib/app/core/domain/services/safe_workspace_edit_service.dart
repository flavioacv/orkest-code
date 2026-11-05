import 'dart:io';
import 'package:orkest_code/app/core/data/lsp/lsp_text_edit.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_workspace_edit.dart';

/// Diferença de conteúdo em um único arquivo do workspace edit.
class WorkspaceFileDiff {
  const WorkspaceFileDiff({
    required this.path,
    required this.originalContent,
    required this.newContent,
    required this.editsCount,
    this.isNewFile = false,
    this.isDeleted = false,
  });

  final String path;
  final String originalContent;
  final String newContent;
  final int editsCount;
  final bool isNewFile;
  final bool isDeleted;

  bool get hasChanges => originalContent != newContent || isNewFile || isDeleted;
}

/// Pré-visualização agregada de todo o WorkspaceEdit antes de sua aplicação.
class WorkspaceEditPreview {
  const WorkspaceEditPreview({
    required this.fileDiffs,
    required this.createdFiles,
    required this.deletedFiles,
    required this.renamedFiles,
    required this.totalEdits,
    this.hasVersionConflict = false,
    this.conflictingFiles = const [],
  });

  final List<WorkspaceFileDiff> fileDiffs;
  final List<String> createdFiles;
  final List<String> deletedFiles;
  final Map<String, String> renamedFiles;
  final int totalEdits;
  final bool hasVersionConflict;
  final List<String> conflictingFiles;

  bool get canApplySafely => !hasVersionConflict && (fileDiffs.isNotEmpty || createdFiles.isNotEmpty || deletedFiles.isNotEmpty || renamedFiles.isNotEmpty);
}

/// Resultado atômico de uma transação de WorkspaceEdit.
class WorkspaceEditTransactionResult {
  const WorkspaceEditTransactionResult({
    required this.success,
    this.errorMessage,
    this.modifiedFiles = const [],
    this.rolledBackFiles = const [],
    this.undoAction,
  });

  final bool success;
  final String? errorMessage;
  final List<String> modifiedFiles;
  final List<String> rolledBackFiles;
  final Future<void> Function()? undoAction;
}

/// Serviço responsável por validar versões, gerar previews e aplicar transacionalmente
/// alterações em múltiplos arquivos com rollback automático em caso de falha.
class SafeWorkspaceEditService {
  const SafeWorkspaceEditService();

  /// Converte uma URI (file://...) em caminho de arquivo local compatível com o SO.
  static String uriToPath(String uri) {
    if (uri.startsWith('file://')) {
      final parsed = Uri.tryParse(uri);
      if (parsed != null && parsed.hasScheme) {
        return parsed.toFilePath(windows: Platform.isWindows);
      }
    }
    return uri;
  }

  /// Gera a pré-visualização completa das alterações sem tocar em disco.
  WorkspaceEditPreview generatePreview({
    required LspWorkspaceEdit edit,
    required Map<String, String> currentFileContents,
    Map<String, int>? openDocumentVersions,
  }) {
    final fileDiffs = <WorkspaceFileDiff>[];
    final createdFiles = <String>[];
    final deletedFiles = <String>[];
    final renamedFiles = <String, String>{};
    final conflictingFiles = <String>[];
    var totalEdits = 0;

    // 1. Validação de versões documentChanges
    if (openDocumentVersions != null) {
      for (final docEdit in edit.documentChanges) {
        if (docEdit.version != null) {
          final path = uriToPath(docEdit.uri);
          final currentVer = openDocumentVersions[path];
          if (currentVer != null && currentVer != docEdit.version) {
            conflictingFiles.add(path);
          }
        }
      }
    }

    // 2. Edições consolidadas de texto
    final consolidated = edit.consolidatedEdits;
    for (final entry in consolidated.entries) {
      final path = uriToPath(entry.key);
      final edits = entry.value;
      totalEdits += edits.length;

      final original = currentFileContents[path] ?? '';
      final updated = applyTextEdits(original, edits);

      fileDiffs.add(
        WorkspaceFileDiff(
          path: path,
          originalContent: original,
          newContent: updated,
          editsCount: edits.length,
        ),
      );
    }

    // 3. Criações de arquivos
    for (final c in edit.creates) {
      final path = uriToPath(c.uri);
      createdFiles.add(path);
      fileDiffs.add(
        WorkspaceFileDiff(
          path: path,
          originalContent: '',
          newContent: '',
          editsCount: 0,
          isNewFile: true,
        ),
      );
    }

    // 4. Renomeações
    for (final r in edit.renames) {
      final oldPath = uriToPath(r.oldUri);
      final newPath = uriToPath(r.newUri);
      renamedFiles[oldPath] = newPath;
    }

    // 5. Exclusões
    for (final d in edit.deletes) {
      final path = uriToPath(d.uri);
      deletedFiles.add(path);
      fileDiffs.add(
        WorkspaceFileDiff(
          path: path,
          originalContent: currentFileContents[path] ?? '',
          newContent: '',
          editsCount: 0,
          isDeleted: true,
        ),
      );
    }

    return WorkspaceEditPreview(
      fileDiffs: fileDiffs,
      createdFiles: createdFiles,
      deletedFiles: deletedFiles,
      renamedFiles: renamedFiles,
      totalEdits: totalEdits,
      hasVersionConflict: conflictingFiles.isNotEmpty,
      conflictingFiles: conflictingFiles,
    );
  }

  /// Aplica atomicamente o WorkspaceEdit com garantia de Rollback em falha.
  Future<WorkspaceEditTransactionResult> apply({
    required LspWorkspaceEdit edit,
    required Future<String> Function(String path) readFile,
    required Future<void> Function(String path, String content) writeFile,
    Future<void> Function(String path)? deleteFile,
    Future<void> Function(String oldPath, String newPath)? renameFile,
    Map<String, int>? openDocumentVersions,
  }) async {
    // 1. Verificação prévia de conflito de versões (Fast Fail)
    if (openDocumentVersions != null) {
      for (final docEdit in edit.documentChanges) {
        if (docEdit.version != null) {
          final path = uriToPath(docEdit.uri);
          final currentVer = openDocumentVersions[path];
          if (currentVer != null && currentVer != docEdit.version) {
            return WorkspaceEditTransactionResult(
              success: false,
              errorMessage:
                  'Version mismatch for $path: expected ${docEdit.version}, actual $currentVer',
            );
          }
        }
      }
    }

    // Snapshots originais para Rollback em caso de falha ou Undo
    final originalSnapshots = <String, String?>{};
    final modifiedPaths = <String>[];
    final createdPaths = <String>[];
    final renamedOperations = <({String oldPath, String newPath})>[];
    final deletedOperations = <({String path, String originalContent})>[];

    try {
      // 2. Aplica edições de arquivos existentes
      final consolidated = edit.consolidatedEdits;
      for (final entry in consolidated.entries) {
        final path = uriToPath(entry.key);
        final originalContent = await readFile(path);
        originalSnapshots[path] = originalContent;

        final newContent = applyTextEdits(originalContent, entry.value);
        await writeFile(path, newContent);
        modifiedPaths.add(path);
      }

      // 3. Aplica criações de arquivos
      for (final c in edit.creates) {
        final path = uriToPath(c.uri);
        originalSnapshots[path] = null; // não existia
        await writeFile(path, '');
        createdPaths.add(path);
      }

      // 4. Aplica renomeações de arquivos
      if (renameFile != null) {
        for (final r in edit.renames) {
          final oldPath = uriToPath(r.oldUri);
          final newPath = uriToPath(r.newUri);
          await renameFile(oldPath, newPath);
          renamedOperations.add((oldPath: oldPath, newPath: newPath));
        }
      }

      // 5. Aplica exclusões de arquivos
      if (deleteFile != null) {
        for (final d in edit.deletes) {
          final path = uriToPath(d.uri);
          final content = await readFile(path);
          deletedOperations.add((path: path, originalContent: content));
          await deleteFile(path);
        }
      }

      // 6. Constrói a ação reversível de Undo
      Future<void> undo() async {
        // Desfaz edições de conteúdo
        for (final path in modifiedPaths) {
          final original = originalSnapshots[path];
          if (original != null) {
            await writeFile(path, original);
          }
        }
        // Desfaz criações (deletando os arquivos criados)
        if (deleteFile != null) {
          for (final path in createdPaths) {
            await deleteFile(path);
          }
        }
        // Desfaz renomeações
        if (renameFile != null) {
          for (final op in renamedOperations.reversed) {
            await renameFile(op.newPath, op.oldPath);
          }
        }
        // Desfaz exclusões (recriando com o conteúdo original)
        for (final op in deletedOperations) {
          await writeFile(op.path, op.originalContent);
        }
      }

      return WorkspaceEditTransactionResult(
        success: true,
        modifiedFiles: [
          ...modifiedPaths,
          ...createdPaths,
          ...renamedOperations.map((r) => r.newPath),
          ...deletedOperations.map((d) => d.path),
        ],
        undoAction: undo,
      );
    } catch (error) {
      // 7. Rollback automático imediato em falha parcial!
      final rolledBack = <String>[];

      // Reverte arquivos modificados
      for (final path in modifiedPaths) {
        try {
          final original = originalSnapshots[path];
          if (original != null) {
            await writeFile(path, original);
            rolledBack.add(path);
          }
        } catch (_) {}
      }

      // Remove arquivos criados
      if (deleteFile != null) {
        for (final path in createdPaths) {
          try {
            await deleteFile(path);
            rolledBack.add(path);
          } catch (_) {}
        }
      }

      // Reverte renomeações
      if (renameFile != null) {
        for (final op in renamedOperations.reversed) {
          try {
            await renameFile(op.newPath, op.oldPath);
            rolledBack.add(op.oldPath);
          } catch (_) {}
        }
      }

      // Restaura arquivos deletados
      for (final op in deletedOperations) {
        try {
          await writeFile(op.path, op.originalContent);
          rolledBack.add(op.path);
        } catch (_) {}
      }

      return WorkspaceEditTransactionResult(
        success: false,
        errorMessage: 'Rollback triggered due to error: $error',
        rolledBackFiles: rolledBack,
      );
    }
  }
}
