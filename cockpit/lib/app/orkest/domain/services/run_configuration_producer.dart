import 'dart:io';

import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:path/path.dart' as p;

/// Gera dinamicamente [RunConfiguration]s contextuais a partir do arquivo
/// e diretório de projeto selecionados.
///
/// Inspirado nos producers de IDE (OpenIDEA / IntelliJ / VSCode CodeLens),
/// permitindo rodar ou testar o arquivo em foco sem configuração manual prévia.
class RunConfigurationProducer {
  const RunConfigurationProducer();

  /// Produz configurações elegíveis para o arquivo [filePath] dentro de [projectRoot].
  List<RunConfiguration> produceForFile({
    required String filePath,
    required String projectRoot,
  }) {
    if (filePath.isEmpty || projectRoot.isEmpty) return const [];

    final normalizedFile = p.normalize(filePath);
    final normalizedRoot = p.normalize(projectRoot);
    final relativePath = p.isWithin(normalizedRoot, normalizedFile)
        ? p.relative(normalizedFile, from: normalizedRoot)
        : normalizedFile;

    final fileName = p.basename(normalizedFile);
    final ext = p.extension(normalizedFile).toLowerCase();

    final configs = <RunConfiguration>[];

    if (ext == '.dart') {
      _produceDartConfigs(
        configs: configs,
        projectRoot: normalizedRoot,
        relativePath: relativePath,
        fileName: fileName,
      );
    } else if (ext == '.ts' || ext == '.js' || ext == '.tsx' || ext == '.jsx') {
      _produceJsTsConfigs(
        configs: configs,
        projectRoot: normalizedRoot,
        relativePath: relativePath,
        fileName: fileName,
      );
    } else if (ext == '.py') {
      _producePythonConfigs(
        configs: configs,
        projectRoot: normalizedRoot,
        relativePath: relativePath,
        fileName: fileName,
      );
    } else if (ext == '.rs') {
      _produceRustConfigs(
        configs: configs,
        projectRoot: normalizedRoot,
        relativePath: relativePath,
        fileName: fileName,
      );
    }

    return configs;
  }

  void _produceDartConfigs({
    required List<RunConfiguration> configs,
    required String projectRoot,
    required String relativePath,
    required String fileName,
  }) {
    final isFlutter = _isFlutterProject(projectRoot);
    final type = isFlutter ? 'flutter' : 'dart';

    if (fileName.endsWith('_test.dart')) {
      configs.add(
        RunConfiguration(
          id: 'producer:$type:test:$relativePath',
          name: 'Test: $fileName',
          type: type,
          kind: RunConfigurationKind.test,
          program: relativePath,
          cwd: projectRoot,
          isTest: true,
        ),
      );
    } else {
      configs.add(
        RunConfiguration(
          id: 'producer:$type:run:$relativePath',
          name: 'Run: $fileName',
          type: type,
          kind: RunConfigurationKind.run,
          program: relativePath,
          cwd: projectRoot,
        ),
      );
    }
  }

  void _produceJsTsConfigs({
    required List<RunConfiguration> configs,
    required String projectRoot,
    required String relativePath,
    required String fileName,
  }) {
    final isTest = fileName.contains('.test.') || fileName.contains('.spec.');
    final isTs = fileName.endsWith('.ts') || fileName.endsWith('.tsx');
    final type = isTs ? 'typescript' : 'node';

    if (isTest) {
      configs.add(
        RunConfiguration(
          id: 'producer:$type:test:$relativePath',
          name: 'Test: $fileName',
          type: type,
          kind: RunConfigurationKind.test,
          program: relativePath,
          cwd: projectRoot,
          isTest: true,
        ),
      );
    } else {
      configs.add(
        RunConfiguration(
          id: 'producer:$type:run:$relativePath',
          name: 'Run: $fileName',
          type: type,
          kind: RunConfigurationKind.run,
          program: relativePath,
          cwd: projectRoot,
        ),
      );
    }
  }

  void _producePythonConfigs({
    required List<RunConfiguration> configs,
    required String projectRoot,
    required String relativePath,
    required String fileName,
  }) {
    final isTest = fileName.startsWith('test_') || fileName.endsWith('_test.py');

    if (isTest) {
      configs.add(
        RunConfiguration(
          id: 'producer:python:test:$relativePath',
          name: 'Pytest: $fileName',
          type: 'python',
          kind: RunConfigurationKind.test,
          program: relativePath,
          cwd: projectRoot,
          isTest: true,
        ),
      );
    } else {
      configs.add(
        RunConfiguration(
          id: 'producer:python:run:$relativePath',
          name: 'Python: $fileName',
          type: 'python',
          kind: RunConfigurationKind.run,
          program: relativePath,
          cwd: projectRoot,
        ),
      );
    }
  }

  void _produceRustConfigs({
    required List<RunConfiguration> configs,
    required String projectRoot,
    required String relativePath,
    required String fileName,
  }) {
    final isTest = relativePath.startsWith('tests/') || fileName.endsWith('_test.rs');

    if (isTest) {
      final testName = p.basenameWithoutExtension(fileName);
      configs.add(
        RunConfiguration(
          id: 'producer:cargo:test:$relativePath',
          name: 'Cargo Test: $testName',
          type: 'cargo',
          kind: RunConfigurationKind.test,
          program: relativePath,
          cwd: projectRoot,
          args: ['--test', testName],
          isTest: true,
        ),
      );
    } else {
      configs.add(
        RunConfiguration(
          id: 'producer:cargo:run:$relativePath',
          name: 'Cargo Run: $fileName',
          type: 'cargo',
          kind: RunConfigurationKind.run,
          program: relativePath,
          cwd: projectRoot,
        ),
      );
    }
  }

  bool _isFlutterProject(String projectRoot) {
    try {
      final pubspec = File(p.join(projectRoot, 'pubspec.yaml'));
      if (!pubspec.existsSync()) return false;
      final content = pubspec.readAsStringSync();
      return content.contains('sdk: flutter') ||
          RegExp(r'^\s*flutter\s*:', multiLine: true).hasMatch(content);
    } catch (_) {
      return false;
    }
  }
}
