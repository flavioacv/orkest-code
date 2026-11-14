import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/data/jsonc.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_producer.dart';
import 'package:path/path.dart' as p;

class RunConfigurationLoader {
  const RunConfigurationLoader();

  Future<List<RunConfiguration>> load(
    String root,
    String? file, {
    List<String> workspaceRoots = const [],
  }) async {
    final roots = <String>{
      for (final path in [root, ...workspaceRoots])
        if (path.isNotEmpty) p.normalize(p.absolute(path)),
    }.toList();
    final result = <RunConfiguration>[];
    for (final folder in roots) {
      result.addAll(
        await _loadFolder(
          folder,
          file,
          qualifyNames: roots.length > 1,
          workspaceRoots: roots,
        ),
      );
    }
    if (file != null) {
      final absoluteFile = p.normalize(p.absolute(file));
      final containingRoots =
          roots.where((folder) => p.isWithin(folder, absoluteFile)).toList()
            ..sort((a, b) => b.length.compareTo(a.length));
      if (containingRoots.isNotEmpty) {
        final boundary = containingRoots.first;
        var fileRoot = p.dirname(absoluteFile);
        var foundSubproject = false;
        while (p.isWithin(boundary, fileRoot) || fileRoot == boundary) {
          if ([
            'pubspec.yaml',
            'package.json',
            'Cargo.toml',
            'pyproject.toml',
          ].any((marker) => File(p.join(fileRoot, marker)).existsSync())) {
            foundSubproject = true;
            break;
          }
          if (fileRoot == boundary) break;
          fileRoot = p.dirname(fileRoot);
        }
        if (foundSubproject &&
            fileRoot != boundary &&
            !roots.contains(fileRoot)) {
          final subConfigs = await _loadFolder(
            fileRoot,
            file,
            qualifyNames: true,
            workspaceRoots: roots,
          );
          result.addAll(subConfigs);
        }
        result.addAll(
          const RunConfigurationProducer().produceForFile(
            filePath: absoluteFile,
            projectRoot: fileRoot,
          ),
        );
      }
    }
    return result;
  }

  Future<List<RunConfiguration>> _loadFolder(
    String root,
    String? file, {
    required bool qualifyNames,
    List<String> workspaceRoots = const [],
  }) async {
    final result = <RunConfiguration>[];
    for (final name in ['.vscode/launch.json', '.orkest/run.json']) {
      final source = File(p.join(root, name));
      if (!await source.exists()) continue;
      final data = jsonDecode(stripJsonc(await source.readAsString()));
      if (data is! Map || data['configurations'] is! List) {
        throw FormatException('Invalid configurations in $name');
      }
      for (final raw in data['configurations'] as List) {
        if (raw is! Map) continue;
        final config = expand(
          raw.cast<String, dynamic>(),
          root,
          file,
          workspaceRoots: workspaceRoots,
        );
        final configuredCwd = config['cwd'] as String? ?? root;
        config['cwd'] = p.normalize(
          p.isAbsolute(configuredCwd)
              ? configuredCwd
              : p.join(root, configuredCwd),
        );
        var type = config['type'] as String? ?? '';
        final pubspec = File(
          p.join(config['cwd'] as String? ?? root, 'pubspec.yaml'),
        );
        if (type == 'dart' &&
            await pubspec.exists() &&
            RegExp(
              r'^\s+sdk:\s*flutter\s*$',
              multiLine: true,
            ).hasMatch(await pubspec.readAsString())) {
          type = 'flutter';
        }
        final request = config['request'] as String? ?? 'launch';
        if (!['launch', 'attach'].contains(request)) continue;
        result.add(
          RunConfiguration(
            id: '${source.path}:${config['name'] ?? type}',
            name: qualifyNames
                ? '${config['name'] as String? ?? type} · $root'
                : config['name'] as String? ?? type,
            type: type,
            program: config['program'] as String? ?? '',
            cwd: config['cwd'] as String? ?? root,
            request: request,
            sdkPath:
                (config['sdkPath'] ??
                        config[type == 'flutter'
                            ? 'flutterSdkPath'
                            : 'dartSdkPath'])
                    as String?,
            launchArguments: config,
            args: (config['args'] as List?)?.cast<String>() ?? const [],
            env: (config['env'] as Map?)?.cast<String, String>() ?? const {},
          ),
        );
      }
    }
    return result;
  }

  static Map<String, dynamic> expand(
    Map<String, dynamic> config,
    String root,
    String? file, {
    List<String> workspaceRoots = const [],
  }) {
    Object? value(Object? input) {
      if (input is String) {
        var expanded = input
            .replaceAll(r'${workspaceFolder}', root)
            .replaceAll(r'${workspaceRoot}', root)
            .replaceAll(r'${file}', file ?? '')
            .replaceAll(
              r'${fileBasename}',
              file == null ? '' : p.basename(file),
            )
            .replaceAll(
              r'${fileBasenameNoExtension}',
              file == null ? '' : p.basenameWithoutExtension(file),
            )
            .replaceAll(
              r'${fileExtname}',
              file == null ? '' : p.extension(file),
            )
            .replaceAll(
              r'${relativeFile}',
              file == null ? '' : p.relative(file, from: root),
            )
            .replaceAll(r'${workspaceFolderBasename}', p.basename(root))
            .replaceAll(r'${pathSeparator}', p.separator)
            .replaceAll(r'${cwd}', root)
            .replaceAll(
              r'${fileDirname}',
              file == null ? root : p.dirname(file),
            );
        for (final wr in workspaceRoots) {
          final folderName = p.basename(wr);
          expanded = expanded
              .replaceAll('\${workspaceFolder:$folderName}', wr)
              .replaceAll('\${workspaceRoot:$folderName}', wr);
        }
        expanded = expanded.replaceAllMapped(RegExp(r'\$\{env:([^}]+)\}'), (
          match,
        ) {
          final name = match[1]!;
          final environment = Platform.environment[name];
          if (environment == null) throw FormatException('env:$name');
          return environment;
        });
        if (expanded.replaceAll(r'${port}', '').contains(r'${')) {
          throw FormatException(
            'Unsupported launch variable: ${RegExp(r'\$\{[^}]+\}').firstMatch(expanded)?.group(0)}',
          );
        }
        return expanded;
      }
      if (input is List) return input.map(value).toList();
      if (input is Map) {
        return input.map((k, v) => MapEntry(k.toString(), value(v)));
      }
      return input;
    }

    return value(config) as Map<String, dynamic>;
  }
}
