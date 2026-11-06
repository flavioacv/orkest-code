import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/data/jsonc.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_producer.dart';
import 'package:path/path.dart' as p;

class RunConfigurationLoader {
  const RunConfigurationLoader();

  Future<List<RunConfiguration>> load(String root, String? file) async {
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
        final config = expand(raw.cast<String, dynamic>(), root, file);
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
            id: '$name:${result.length}',
            name: config['name'] as String? ?? type,
            type: type,
            program: config['program'] as String? ?? '',
            cwd: config['cwd'] as String? ?? root,
            request: request,
            launchArguments: config,
            args: (config['args'] as List?)?.cast<String>() ?? const [],
            env: (config['env'] as Map?)?.cast<String, String>() ?? const {},
          ),
        );
      }
    }
    if (file != null) {
      var fileRoot = p.dirname(file);
      while (p.isWithin(root, fileRoot)) {
        if ([
          'pubspec.yaml',
          'package.json',
          'Cargo.toml',
          'pyproject.toml',
        ].any((marker) => File(p.join(fileRoot, marker)).existsSync())) {
          break;
        }
        fileRoot = p.dirname(fileRoot);
      }
      result.addAll(
        const RunConfigurationProducer().produceForFile(
          filePath: file,
          projectRoot: fileRoot,
        ),
      );
    }
    return result;
  }

  static Map<String, dynamic> expand(
    Map<String, dynamic> config,
    String root,
    String? file,
  ) {
    Object? value(Object? input) {
      if (input is String) {
        final expanded = input
            .replaceAll(r'${workspaceFolder}', root)
            .replaceAll(r'${file}', file ?? '')
            .replaceAll(
              r'${fileDirname}',
              file == null ? root : p.dirname(file),
            );
        if (expanded.contains(r'${')) {
          throw FormatException('Unsupported launch variable in $expanded');
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
