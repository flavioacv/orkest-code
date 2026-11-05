/// Tipo de célula de um notebook Jupyter/.ipynb (X04).
enum NotebookCellKind {
  code,
  markdown,
  raw,
}

/// Saída de execução de uma célula de código Jupyter (X04).
class NotebookCellOutput {
  const NotebookCellOutput({
    required this.outputType, // stream, execute_result, display_data, error
    this.text,
    this.mimeData = const {},
    this.ename,
    this.evalue,
    this.traceback = const [],
  });

  final String outputType;
  final String? text;
  final Map<String, dynamic> mimeData;
  final String? ename;
  final String? evalue;
  final List<String> traceback;

  bool get isError => outputType == 'error';
}

/// Célula imutável de notebook (X04).
class NotebookCell {
  const NotebookCell({
    required this.id,
    required this.kind,
    required this.source,
    this.executionCount,
    this.outputs = const [],
    this.metadata = const {},
  });

  final String id;
  final NotebookCellKind kind;
  final String source;
  final int? executionCount;
  final List<NotebookCellOutput> outputs;
  final Map<String, dynamic> metadata;
}

/// Representação completa de um documento Jupyter Notebook `.ipynb` (X04).
class JupyterNotebookDocument {
  const JupyterNotebookDocument({
    required this.nbformat,
    required this.nbformatMinor,
    required this.cells,
    required this.kernelName,
    required this.kernelLanguage,
    this.metadata = const {},
  });

  final int nbformat;
  final int nbformatMinor;
  final List<NotebookCell> cells;
  final String kernelName;
  final String kernelLanguage;
  final Map<String, dynamic> metadata;

  int get codeCellCount =>
      cells.where((c) => c.kind == NotebookCellKind.code).length;

  int get markdownCellCount =>
      cells.where((c) => c.kind == NotebookCellKind.markdown).length;
}

/// Permissão solicitada por uma extensão no manifesto (X04).
enum PluginPermission {
  filesystemRead,
  filesystemWrite,
  network,
  terminalPty,
  executeCommand,
  workspaceSecrets,
}

/// Ponto de contribuição declarativo de um plugin (X04).
class PluginContribution {
  const PluginContribution({
    required this.type, // command, menu, theme, languageServer, keybinding
    required this.id,
    required this.title,
    this.whenClause,
  });

  final String type;
  final String id;
  final String title;
  final String? whenClause;
}

/// Manifesto formal de extensão / plugin (X04).
class PluginManifest {
  const PluginManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.minOrkestVersion,
    required this.description,
    this.author,
    this.permissions = const [],
    this.contributions = const [],
  });

  final String id;
  final String name;
  final String version;
  final String minOrkestVersion;
  final String description;
  final String? author;
  final List<PluginPermission> permissions;
  final List<PluginContribution> contributions;
}

/// Política de sandbox para isolamento de extensões (X04).
class PluginSandboxPolicy {
  const PluginSandboxPolicy({
    required this.allowNetwork,
    required this.allowFilesystemWrite,
    required this.allowPtyAccess,
    required this.enforceTimeoutSeconds,
  });

  final bool allowNetwork;
  final bool allowFilesystemWrite;
  final bool allowPtyAccess;
  final int enforceTimeoutSeconds;

  /// Valida se o manifesto respeita a política da sandbox.
  List<String> auditViolations(PluginManifest manifest) {
    final violations = <String>[];
    if (!allowNetwork && manifest.permissions.contains(PluginPermission.network)) {
      violations.add('Permissão de rede não permitida pela política da sandbox.');
    }
    if (!allowFilesystemWrite &&
        manifest.permissions.contains(PluginPermission.filesystemWrite)) {
      violations.add('Permissão de escrita no sistema de arquivos não permitida.');
    }
    if (!allowPtyAccess &&
        manifest.permissions.contains(PluginPermission.terminalPty)) {
      violations.add('Acesso direto ao PTY de terminal bloqueado.');
    }
    return List.unmodifiable(violations);
  }
}

/// Decisão técnica de arquitetura (ADR) sobre recursos de extensão (X04).
enum ArchitectureDecision {
  adoptStandard,
  deferImplementation,
  rejectApproach,
}

/// Relatório de avaliação e justificativa formal de deferral (X04).
class ExtensibilityEvaluationReport {
  const ExtensibilityEvaluationReport({
    required this.topic,
    required this.decision,
    required this.technicalRationale,
    required this.recommendedAlternative,
  });

  final String topic; // 'Jupyter Native Runtime Kernel', 'React DOM Plugin Bridge'
  final ArchitectureDecision decision;
  final String technicalRationale;
  final String recommendedAlternative;
}
