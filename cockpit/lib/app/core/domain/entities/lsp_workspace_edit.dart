import 'package:orkest_code/app/core/data/lsp/lsp_text_edit.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';

/// Um documento com edições de texto e controle opcional de versão (LSP 3.x).
class LspTextDocumentEdit {
  const LspTextDocumentEdit({
    required this.uri,
    this.version,
    required this.edits,
  });

  final String uri;
  final int? version;
  final List<LspTextEdit> edits;

  factory LspTextDocumentEdit.fromJson(Map<String, dynamic> json) {
    final textDocument = json['textDocument'] as Map?;
    final uri = textDocument?['uri'] as String? ?? json['uri'] as String? ?? '';
    final version = textDocument?['version'] as int?;
    final editsRaw = json['edits'] as List? ?? const [];

    final edits = <LspTextEdit>[
      for (final e in editsRaw)
        if (e is Map) LspTextEdit.fromJson(e.cast<String, dynamic>()),
    ];

    return LspTextDocumentEdit(
      uri: uri,
      version: version,
      edits: edits,
    );
  }
}

/// Criação de arquivo indicada pelo LSP.
class LspCreateFile {
  const LspCreateFile({
    required this.uri,
    this.overwrite = false,
    this.ignoreIfExists = false,
  });

  final String uri;
  final bool overwrite;
  final bool ignoreIfExists;

  factory LspCreateFile.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map?;
    return LspCreateFile(
      uri: json['uri'] as String? ?? '',
      overwrite: options?['overwrite'] as bool? ?? false,
      ignoreIfExists: options?['ignoreIfExists'] as bool? ?? false,
    );
  }
}

/// Renomeação de arquivo indicada pelo LSP.
class LspRenameFile {
  const LspRenameFile({
    required this.oldUri,
    required this.newUri,
    this.overwrite = false,
    this.ignoreIfExists = false,
  });

  final String oldUri;
  final String newUri;
  final bool overwrite;
  final bool ignoreIfExists;

  factory LspRenameFile.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map?;
    return LspRenameFile(
      oldUri: json['oldUri'] as String? ?? '',
      newUri: json['newUri'] as String? ?? '',
      overwrite: options?['overwrite'] as bool? ?? false,
      ignoreIfExists: options?['ignoreIfExists'] as bool? ?? false,
    );
  }
}

/// Exclusão de arquivo indicada pelo LSP.
class LspDeleteFile {
  const LspDeleteFile({
    required this.uri,
    this.recursive = false,
    this.ignoreIfNotExists = false,
  });

  final String uri;
  final bool recursive;
  final bool ignoreIfNotExists;

  factory LspDeleteFile.fromJson(Map<String, dynamic> json) {
    final options = json['options'] as Map?;
    return LspDeleteFile(
      uri: json['uri'] as String? ?? '',
      recursive: options?['recursive'] as bool? ?? false,
      ignoreIfNotExists: options?['ignoreIfNotExists'] as bool? ?? false,
    );
  }
}

/// Representa um WorkspaceEdit do protocolo LSP (3.x).
/// Pode vir sob o formato simples `changes` (`Map<Uri, List<TextEdit>>`) ou sob o
/// formato moderno `documentChanges` (com versões e operações estruturadas de recursos).
class LspWorkspaceEdit {
  const LspWorkspaceEdit({
    this.changes = const {},
    this.documentChanges = const [],
    this.creates = const [],
    this.renames = const [],
    this.deletes = const [],
  });

  final Map<String, List<LspTextEdit>> changes;
  final List<LspTextDocumentEdit> documentChanges;
  final List<LspCreateFile> creates;
  final List<LspRenameFile> renames;
  final List<LspDeleteFile> deletes;

  bool get isEmpty =>
      changes.isEmpty &&
      documentChanges.isEmpty &&
      creates.isEmpty &&
      renames.isEmpty &&
      deletes.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Retorna todas as edições agrupadas por URI (unificando `changes` e `documentChanges`).
  Map<String, List<LspTextEdit>> get consolidatedEdits {
    final result = <String, List<LspTextEdit>>{};

    for (final entry in changes.entries) {
      result.putIfAbsent(entry.key, () => []).addAll(entry.value);
    }

    for (final docEdit in documentChanges) {
      result.putIfAbsent(docEdit.uri, () => []).addAll(docEdit.edits);
    }

    return result;
  }

  /// Retorna o conjunto de todas as URIs envolvidas (modificadas, criadas, renomeadas ou deletadas).
  Set<String> get allAffectedUris {
    final uris = <String>{};
    uris.addAll(changes.keys);
    for (final doc in documentChanges) {
      uris.add(doc.uri);
    }
    for (final c in creates) {
      uris.add(c.uri);
    }
    for (final r in renames) {
      uris.add(r.oldUri);
      uris.add(r.newUri);
    }
    for (final d in deletes) {
      uris.add(d.uri);
    }
    return uris;
  }

  factory LspWorkspaceEdit.fromJson(Map<String, dynamic> json) {
    final changesMap = <String, List<LspTextEdit>>{};
    final rawChanges = json['changes'] as Map?;
    if (rawChanges != null) {
      for (final entry in rawChanges.entries) {
        final uri = entry.key.toString();
        final editsRaw = entry.value as List? ?? const [];
        final edits = <LspTextEdit>[
          for (final e in editsRaw)
            if (e is Map) LspTextEdit.fromJson(e.cast<String, dynamic>()),
        ];
        changesMap[uri] = edits;
      }
    }

    final docChanges = <LspTextDocumentEdit>[];
    final creates = <LspCreateFile>[];
    final renames = <LspRenameFile>[];
    final deletes = <LspDeleteFile>[];

    final rawDocChanges = json['documentChanges'] as List?;
    if (rawDocChanges != null) {
      for (final item in rawDocChanges) {
        if (item is! Map) continue;
        final map = item.cast<String, dynamic>();
        final kind = map['kind'] as String?;

        if (kind == 'create') {
          creates.add(LspCreateFile.fromJson(map));
        } else if (kind == 'rename') {
          renames.add(LspRenameFile.fromJson(map));
        } else if (kind == 'delete') {
          deletes.add(LspDeleteFile.fromJson(map));
        } else {
          // É um TextDocumentEdit (ou possui edits/textDocument)
          docChanges.add(LspTextDocumentEdit.fromJson(map));
        }
      }
    }

    return LspWorkspaceEdit(
      changes: changesMap,
      documentChanges: docChanges,
      creates: creates,
      renames: renames,
      deletes: deletes,
    );
  }
}

/// Resultado de `textDocument/prepareRename`.
class LspPrepareRenameResult {
  const LspPrepareRenameResult({
    required this.canRename,
    this.range,
    this.placeholder,
  });

  final bool canRename;
  final LspRange? range;
  final String? placeholder;

  factory LspPrepareRenameResult.cannotRename() =>
      const LspPrepareRenameResult(canRename: false);

  factory LspPrepareRenameResult.fromJson(dynamic json) {
    if (json == null) return const LspPrepareRenameResult(canRename: false);
    if (json is Map<String, dynamic>) {
      // Formato { range: Range, placeholder: string }
      if (json.containsKey('range')) {
        final r = json['range'] as Map;
        return LspPrepareRenameResult(
          canRename: true,
          range: LspRange.fromJson(r.cast<String, dynamic>()),
          placeholder: json['placeholder'] as String?,
        );
      }
      // Formato Range direto { start: {...}, end: {...} }
      if (json.containsKey('start') && json.containsKey('end')) {
        return LspPrepareRenameResult(
          canRename: true,
          range: LspRange.fromJson(json),
          placeholder: null,
        );
      }
    }
    return const LspPrepareRenameResult(canRename: false);
  }
}

/// Decodificador tolerante de WorkspaceEdit vindo do LSP.
LspWorkspaceEdit? parseWorkspaceEdit(dynamic result) {
  if (result is! Map) return null;
  return LspWorkspaceEdit.fromJson(result.cast<String, dynamic>());
}
