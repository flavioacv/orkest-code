import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/notebook_plugin_eval.dart';
import 'package:orkest_code/app/core/domain/services/notebook_plugin_eval_service.dart';

void main() {
  group('JupyterNotebookParser (X04)', () {
    const parser = JupyterNotebookParser();

    test('parses Jupyter notebook .ipynb with code, markdown and outputs', () {
      const ipynbJson = '''
{
  "nbformat": 4,
  "nbformat_minor": 5,
  "metadata": {
    "kernelspec": {
      "name": "python3",
      "display_name": "Python 3"
    },
    "language_info": {
      "name": "python"
    }
  },
  "cells": [
    {
      "cell_type": "markdown",
      "id": "md_cell_1",
      "source": ["# Titulo do Experimento\\n", "Explicacao introdutoria."]
    },
    {
      "cell_type": "code",
      "id": "code_cell_2",
      "execution_count": 1,
      "source": ["import math\\n", "print(math.pi)"],
      "outputs": [
        {
          "output_type": "stream",
          "name": "stdout",
          "text": ["3.141592653589793\\n"]
        }
      ]
    },
    {
      "cell_type": "code",
      "id": "code_cell_3",
      "execution_count": 2,
      "source": ["1 / 0"],
      "outputs": [
        {
          "output_type": "error",
          "ename": "ZeroDivisionError",
          "evalue": "division by zero",
          "traceback": ["ZeroDivisionError: division by zero"]
        }
      ]
    }
  ]
}
''';

      final doc = parser.parseIpynb(ipynbJson);
      expect(doc, isNotNull);
      expect(doc!.nbformat, equals(4));
      expect(doc.kernelName, equals('python3'));
      expect(doc.kernelLanguage, equals('python'));
      expect(doc.cells.length, equals(3));
      expect(doc.codeCellCount, equals(2));
      expect(doc.markdownCellCount, equals(1));

      // Markdown cell
      expect(doc.cells[0].kind, equals(NotebookCellKind.markdown));
      expect(doc.cells[0].source, contains('# Titulo do Experimento'));

      // Code cell 1
      expect(doc.cells[1].kind, equals(NotebookCellKind.code));
      expect(doc.cells[1].executionCount, equals(1));
      expect(doc.cells[1].outputs.first.outputType, equals('stream'));
      expect(doc.cells[1].outputs.first.text, contains('3.141592'));

      // Code cell 2 (error output)
      expect(doc.cells[2].outputs.first.isError, isTrue);
      expect(doc.cells[2].outputs.first.ename, equals('ZeroDivisionError'));
    });
  });

  group('PluginManifestValidator & Sandbox (X04)', () {
    const validator = PluginManifestValidator();

    test('validates conformant plugin manifest with permissions and contributions', () {
      const manifestJson = '''
{
  "id": "com.orkest.git-lens",
  "name": "Orkest Git Lens",
  "version": "1.2.0",
  "minOrkestVersion": "1.0.0",
  "description": "Visual blame annotations in gutter",
  "permissions": ["filesystem.read"],
  "contributions": [
    {
      "type": "command",
      "id": "git.toggleBlame",
      "title": "Toggle Line Blame"
    }
  ]
}
''';

      final res = validator.validate(manifestJson, currentOrkestVersion: '1.4.0');
      expect(res.errors, isEmpty);
      expect(res.manifest, isNotNull);
      expect(res.manifest!.id, equals('com.orkest.git-lens'));
      expect(res.manifest!.permissions, contains(PluginPermission.filesystemRead));
      expect(res.manifest!.contributions.first.id, equals('git.toggleBlame'));
    });

    test('flags semver version incompatibility', () {
      const manifestJson = '''
{
  "id": "com.orkest.future-ext",
  "name": "Future Extension",
  "version": "0.1.0",
  "minOrkestVersion": "2.0.0",
  "description": "Requires future orkest version"
}
''';

      final res = validator.validate(manifestJson, currentOrkestVersion: '1.4.0');
      expect(res.manifest, isNull);
      expect(res.errors.any((e) => e.contains('requer Orkest versão >= 2.0.0')), isTrue);
    });

    test('audits sandbox violations when restricted permissions are requested', () {
      const maliciousManifest = '''
{
  "id": "com.untrusted.spy",
  "name": "Untrusted Spy",
  "version": "1.0.0",
  "minOrkestVersion": "1.0.0",
  "description": "Attempts dangerous permissions",
  "permissions": ["network", "filesystem.write", "terminal.pty"]
}
''';

      const strictPolicy = PluginSandboxPolicy(
        allowNetwork: false,
        allowFilesystemWrite: false,
        allowPtyAccess: false,
        enforceTimeoutSeconds: 5,
      );

      final res = validator.validate(
        maliciousManifest,
        currentOrkestVersion: '1.4.0',
        policy: strictPolicy,
      );

      expect(res.manifest, isNull);
      expect(res.errors.length, equals(3));
      expect(res.errors.any((e) => e.contains('Permissão de rede não permitida')), isTrue);
      expect(res.errors.any((e) => e.contains('escrita no sistema de arquivos')), isTrue);
      expect(res.errors.any((e) => e.contains('PTY de terminal bloqueado')), isTrue);
    });
  });

  group('ExtensibilityEvaluationRegistry (X04 Acceptance ADR)', () {
    test('contains explicit decisions rejecting React plugins and deferring Jupyter native kernel', () {
      final reports = ExtensibilityEvaluationRegistry.reports;
      expect(reports.length, equals(2));

      // 1. React DOM Plugins -> Rejeição fundamentada
      final reactReport = reports.firstWhere((r) => r.topic.contains('React'));
      expect(reactReport.decision, equals(ArchitectureDecision.rejectApproach));
      expect(reactReport.technicalRationale, contains('Plugins React foram concebidos para o ecossistema Web/DOM'));
      expect(reactReport.technicalRationale, contains('componentes React não são widgets nativos'));
      expect(reactReport.recommendedAlternative, contains('LSP/DAP/MCP'));

      // 2. Jupyter Native Kernel Execution -> Adiamento fundamentado (KISS/YAGNI)
      final jupyterReport = reports.firstWhere((r) => r.topic.contains('Jupyter'));
      expect(jupyterReport.decision, equals(ArchitectureDecision.deferImplementation));
      expect(jupyterReport.technicalRationale, contains('complexidade desproporcional'));
      expect(jupyterReport.recommendedAlternative, contains('.notebook'));
    });
  });
}
