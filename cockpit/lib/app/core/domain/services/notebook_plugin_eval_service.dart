import 'dart:convert';
import 'package:orkest_code/app/core/domain/entities/notebook_plugin_eval.dart';

/// Decodificador tolerante de cadernos Jupyter Notebook `.ipynb` (X04).
class JupyterNotebookParser {
  const JupyterNotebookParser();

  /// Decodifica o conteúdo JSON de um arquivo `.ipynb`.
  JupyterNotebookDocument? parseIpynb(String jsonContent) {
    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) return null;

      final nbformat = decoded['nbformat'] as int? ?? 4;
      final nbformatMinor = decoded['nbformat_minor'] as int? ?? 2;
      final metadata = (decoded['metadata'] as Map<String, dynamic>?) ?? {};

      final kernelSpec = (metadata['kernelspec'] as Map<String, dynamic>?) ?? {};
      final kernelName = kernelSpec['name'] as String? ?? 'python3';
      final kernelLanguage = (metadata['language_info'] as Map<String, dynamic>?)?['name'] as String? ?? 'python';

      final rawCells = (decoded['cells'] as List?) ?? [];
      final cells = <NotebookCell>[];

      for (var idx = 0; idx < rawCells.length; idx++) {
        final cellObj = rawCells[idx];
        if (cellObj is! Map<String, dynamic>) continue;

        final cellTypeStr = cellObj['cell_type'] as String? ?? 'code';
        final kind = switch (cellTypeStr) {
          'markdown' => NotebookCellKind.markdown,
          'raw' => NotebookCellKind.raw,
          _ => NotebookCellKind.code,
        };

        final id = cellObj['id'] as String? ?? 'cell_$idx';
        final sourceRaw = cellObj['source'];
        final source = sourceRaw is List
            ? sourceRaw.map((e) => '$e').join()
            : sourceRaw is String
                ? sourceRaw
                : '';

        final executionCount = cellObj['execution_count'] as int?;
        final rawOutputs = (cellObj['outputs'] as List?) ?? [];
        final outputs = <NotebookCellOutput>[];

        for (final outObj in rawOutputs) {
          if (outObj is! Map<String, dynamic>) continue;
          final outType = outObj['output_type'] as String? ?? 'stream';
          final textRaw = outObj['text'];
          final text = textRaw is List ? textRaw.map((e) => '$e').join() : textRaw?.toString();
          final mimeData = (outObj['data'] as Map<String, dynamic>?) ?? {};
          final ename = outObj['ename'] as String?;
          final evalue = outObj['evalue'] as String?;
          final traceback = (outObj['traceback'] as List?)?.map((e) => '$e').toList() ?? [];

          outputs.add(
            NotebookCellOutput(
              outputType: outType,
              text: text,
              mimeData: Map.unmodifiable(mimeData),
              ename: ename,
              evalue: evalue,
              traceback: List.unmodifiable(traceback),
            ),
          );
        }

        cells.add(
          NotebookCell(
            id: id,
            kind: kind,
            source: source,
            executionCount: executionCount,
            outputs: List.unmodifiable(outputs),
            metadata: Map.unmodifiable((cellObj['metadata'] as Map<String, dynamic>?) ?? {}),
          ),
        );
      }

      return JupyterNotebookDocument(
        nbformat: nbformat,
        nbformatMinor: nbformatMinor,
        cells: List.unmodifiable(cells),
        kernelName: kernelName,
        kernelLanguage: kernelLanguage,
        metadata: Map.unmodifiable(metadata),
      );
    } catch (_) {
      return null;
    }
  }
}

/// Validador de manifestos de extensão e conformidade de sandbox (X04).
class PluginManifestValidator {
  const PluginManifestValidator();

  /// Analisa o manifesto JSON do plugin, valida a compatibilidade de versão e as permissões.
  ({PluginManifest? manifest, List<String> errors}) validate(
    String jsonContent, {
    required String currentOrkestVersion,
    PluginSandboxPolicy? policy,
  }) {
    final errors = <String>[];

    try {
      final decoded = jsonDecode(jsonContent);
      if (decoded is! Map<String, dynamic>) {
        return (manifest: null, errors: ['Manifesto inválido: raiz deve ser um objeto JSON.']);
      }

      final id = decoded['id'] as String?;
      final name = decoded['name'] as String?;
      final version = decoded['version'] as String?;
      final minVersion = decoded['minOrkestVersion'] as String?;
      final description = decoded['description'] as String? ?? '';

      if (id == null || id.isEmpty) errors.add('Campo "id" obrigatório ausente.');
      if (name == null || name.isEmpty) errors.add('Campo "name" obrigatório ausente.');
      if (version == null || version.isEmpty) errors.add('Campo "version" obrigatório ausente.');
      if (minVersion == null || minVersion.isEmpty) {
        errors.add('Campo "minOrkestVersion" obrigatório ausente.');
      }

      if (minVersion != null && !_isVersionCompatible(currentOrkestVersion, minVersion)) {
        errors.add(
          'Extensão requer Orkest versão >= $minVersion (versão atual do ambiente: $currentOrkestVersion).',
        );
      }

      // Permissões
      final permissions = <PluginPermission>[];
      final rawPerms = (decoded['permissions'] as List?) ?? [];
      for (final p in rawPerms) {
        final perm = _parsePermission('$p');
        if (perm != null) permissions.add(perm);
      }

      // Contribuições
      final contributions = <PluginContribution>[];
      final rawContribs = (decoded['contributions'] as List?) ?? [];
      for (final c in rawContribs) {
        if (c is Map<String, dynamic>) {
          contributions.add(
            PluginContribution(
              type: c['type'] ?? 'command',
              id: c['id'] ?? '',
              title: c['title'] ?? '',
              whenClause: c['when'],
            ),
          );
        }
      }

      final manifest = PluginManifest(
        id: id ?? '',
        name: name ?? '',
        version: version ?? '',
        minOrkestVersion: minVersion ?? '',
        description: description,
        author: decoded['author'] as String?,
        permissions: List.unmodifiable(permissions),
        contributions: List.unmodifiable(contributions),
      );

      // Auditoria de violações de sandbox se policy fornecida
      if (policy != null) {
        final violations = policy.auditViolations(manifest);
        errors.addAll(violations);
      }

      return (manifest: errors.isEmpty ? manifest : null, errors: errors);
    } catch (e) {
      return (manifest: null, errors: ['Falha ao decodificar JSON do manifesto: $e']);
    }
  }

  bool _isVersionCompatible(String current, String required) {
    // Comparação simples semver major.minor.patch
    final currParts = current.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    final reqParts = required.split('.').map((p) => int.tryParse(p) ?? 0).toList();

    while (currParts.length < 3) {
      currParts.add(0);
    }
    while (reqParts.length < 3) {
      reqParts.add(0);
    }

    for (var i = 0; i < 3; i++) {
      if (currParts[i] > reqParts[i]) return true;
      if (currParts[i] < reqParts[i]) return false;
    }
    return true;
  }

  PluginPermission? _parsePermission(String perm) {
    switch (perm.toLowerCase()) {
      case 'filesystem.read':
      case 'filesystemread':
        return PluginPermission.filesystemRead;
      case 'filesystem.write':
      case 'filesystemwrite':
        return PluginPermission.filesystemWrite;
      case 'network':
        return PluginPermission.network;
      case 'terminal.pty':
      case 'terminalpty':
        return PluginPermission.terminalPty;
      case 'execute.command':
      case 'executecommand':
        return PluginPermission.executeCommand;
      case 'workspace.secrets':
      case 'workspacesecrets':
        return PluginPermission.workspaceSecrets;
      default:
        return null;
    }
  }
}

/// Registro formal de avaliações técnicas e decisões de deferral (X04).
class ExtensibilityEvaluationRegistry {
  ExtensibilityEvaluationRegistry._();

  static const List<ExtensibilityEvaluationReport> reports = [
    ExtensibilityEvaluationReport(
      topic: 'React DOM Plugin UI Bridge',
      decision: ArchitectureDecision.rejectApproach,
      technicalRationale:
          'Plugins React foram concebidos para o ecossistema Web/DOM do VS Code/Theia. '
          'No Flutter, componentes React não são widgets nativos; sua embutição exigiria WebView '
          'pesada por painel, quebrando o pipeline de 60fps, aumentando consumo de RAM em centenas de MBs '
          'e duplicando o motor de renderização. O modelo de UI do Orkest deve permanecer Flutter puro.',
      recommendedAlternative:
          'Contribuições declarativas via manifesto JSON (menus, comandos, snippets, temas) e '
          'serviços headless via LSP/DAP/MCP.',
    ),
    ExtensibilityEvaluationReport(
      topic: 'Jupyter Native Runtime Kernel Execution',
      decision: ArchitectureDecision.deferImplementation,
      technicalRationale:
          'Gerenciamento nativo de ciclo de vida de kernels Jupyter (ZeroMQ, sockets interprocessuais, '
          'python ipykernel lifecycle) adiciona complexidade desproporcional para uma IDE de desenvolvimento '
          'de software primariamente project-first e terminal-first, sem demanda comprovada de data science.',
      recommendedAlternative:
          'Visualização estática limpa de células de arquivos `.ipynb` e cadernos `.notebook` '
          'baseados em Markdown já integrados nativamente no Orkest.',
    ),
  ];
}
