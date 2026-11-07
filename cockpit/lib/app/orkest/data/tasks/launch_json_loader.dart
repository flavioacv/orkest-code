import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/data/jsonc.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:path/path.dart' as p;

/// Carrega e importa configurações de execução a partir de `.vscode/launch.json`
/// ou `.orkest/run.json` presentes no workspace.
class LaunchJsonLoader {
  const LaunchJsonLoader();

  /// Locais padrão investigados no workspace, por ordem de prioridade.
  static const List<String> candidatePaths = [
    '.orkest/run.json',
    '.orkest/launch.json',
    '.vscode/launch.json',
  ];

  /// Carrega as configurações de execução do workspace em [workspaceRoot].
  Future<List<RunConfiguration>> load(
    String workspaceRoot, {
    List<String> workspaceRoots = const [],
  }) async {
    if (workspaceRoot.isEmpty) return const [];

    final allRoots = <String>{
      workspaceRoot,
      ...workspaceRoots,
    }.toList();

    for (final relative in candidatePaths) {
      final file = File(p.join(workspaceRoot, relative));
      if (await file.exists()) {
        try {
          final content = await file.readAsString();
          final configs = parseContent(
            content,
            workspaceRoot,
            workspaceRoots: allRoots,
          );
          if (configs.isNotEmpty) {
            return configs;
          }
        } catch (_) {}
      }
    }

    return const [];
  }

  /// Parseia o conteúdo JSONC de um arquivo launch/run.
  List<RunConfiguration> parseContent(
    String content,
    String workspaceRoot, {
    List<String> workspaceRoots = const [],
  }) {
    final Object? decoded;
    try {
      decoded = jsonDecode(stripJsonc(content));
    } catch (_) {
      return const [];
    }

    if (decoded is! Map) return const [];

    final rawConfigs = decoded['configurations'];
    if (rawConfigs is! List) return const [];

    final configs = <RunConfiguration>[];
    for (final raw in rawConfigs) {
      if (raw is! Map) continue;
      final parsed = _parseEntry(
        raw,
        workspaceRoot,
        workspaceRoots: workspaceRoots,
      );
      if (parsed != null) {
        configs.add(parsed);
      }
    }

    return configs;
  }

  RunConfiguration? _parseEntry(
    Map<dynamic, dynamic> m,
    String workspaceRoot, {
    List<String> workspaceRoots = const [],
  }) {
    final name = m['name'] as String?;
    final type = (m['type'] as String?) ?? 'custom';
    if (name == null || name.isEmpty) return null;

    final rawProgram = (m['program'] as String?) ?? '';
    final program = _substituteVariables(
      rawProgram,
      workspaceRoot,
      workspaceRoots: workspaceRoots,
    );

    final rawCwd = (m['cwd'] as String?) ?? workspaceRoot;
    final cwd = _resolveCwd(
      _substituteVariables(
        rawCwd,
        workspaceRoot,
        workspaceRoots: workspaceRoots,
      ),
      workspaceRoot,
    );

    final rawArgs = m['args'];
    final args = <String>[];
    if (rawArgs is List) {
      for (final a in rawArgs) {
        args.add(_substituteVariables(
          a.toString(),
          workspaceRoot,
          workspaceRoots: workspaceRoots,
        ));
      }
    }

    final rawEnv = m['env'];
    final env = <String, String>{};
    if (rawEnv is Map) {
      for (final entry in rawEnv.entries) {
        env[entry.key.toString()] = _substituteVariables(
          entry.value.toString(),
          workspaceRoot,
          workspaceRoots: workspaceRoots,
        );
      }
    }

    final isTest = (m['isTest'] == true) ||
        name.toLowerCase().contains('test') ||
        program.contains('_test.dart') ||
        program.contains('.test.');

    return RunConfiguration(
      id: 'launch:$name',
      name: name,
      type: type,
      kind: isTest ? RunConfigurationKind.test : RunConfigurationKind.run,
      program: program,
      cwd: cwd,
      args: args,
      env: env,
      isTest: isTest,
    );
  }

  String _substituteVariables(
    String input,
    String workspaceRoot, {
    List<String> workspaceRoots = const [],
  }) {
    var result = input
        .replaceAll(r'${workspaceFolder}', workspaceRoot)
        .replaceAll(r'${workspaceRoot}', workspaceRoot);
    for (final wr in workspaceRoots) {
      final folderName = p.basename(wr);
      result = result
          .replaceAll('\${workspaceFolder:$folderName}', wr)
          .replaceAll('\${workspaceRoot:$folderName}', wr);
    }
    return result;
  }

  String _resolveCwd(String cwd, String workspaceRoot) {
    if (cwd.isEmpty) return workspaceRoot;
    if (p.isAbsolute(cwd)) return p.normalize(cwd);
    return p.normalize(p.join(workspaceRoot, cwd));
  }
}
