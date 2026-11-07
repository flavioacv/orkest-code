import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/data/tasks/launch_json_loader.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/domain/entities/task_definition.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_loader.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_producer.dart';

void main() {
  group('RunConfiguration & TaskDefinition conversion', () {
    test('converte configuração de teste Dart para TaskDefinition', () {
      const config = RunConfiguration(
        id: 'test-1',
        name: 'Test File',
        type: 'dart',
        kind: RunConfigurationKind.test,
        program: 'test/sample_test.dart',
        cwd: '/project',
        args: ['--reporter', 'compact'],
        env: {'CI': 'true'},
        isTest: true,
      );

      final task = config.toTaskDefinition();
      expect(task.id, equals('test-1'));
      expect(task.label, equals('Test File'));
      expect(task.command, equals('dart'));
      expect(task.args, equals(['test', 'test/sample_test.dart', '--reporter', 'compact']));
      expect(task.kind, equals(TaskKind.oneShot));
      expect(task.profiles.length, equals(1));
      expect(task.profiles.first.env, equals({'CI': 'true'}));
    });

    test('converte configuração de execução Flutter para TaskDefinition', () {
      const config = RunConfiguration(
        id: 'run-app',
        name: 'Run App',
        type: 'flutter',
        kind: RunConfigurationKind.run,
        program: 'lib/main.dart',
        cwd: '/project',
        args: ['-d', 'macos'],
      );

      final task = config.toTaskDefinition();
      expect(task.command, equals('flutter'));
      expect(task.args, equals(['run', '-t', 'lib/main.dart', '-d', 'macos']));
      expect(task.kind, equals(TaskKind.watch));
    });

    test('converte configuração TypeScript para TaskDefinition', () {
      const config = RunConfiguration(
        id: 'run-ts',
        name: 'Run TS script',
        type: 'typescript',
        kind: RunConfigurationKind.run,
        program: 'src/index.ts',
        cwd: '/project',
      );

      final task = config.toTaskDefinition();
      expect(task.command, equals('npx'));
      expect(task.args, equals(['tsx', 'src/index.ts']));
    });
  });

  group('RunConfigurationProducer', () {
    const producer = RunConfigurationProducer();
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('run_producer_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('produz configuração de teste Dart para arquivo *_test.dart', () {
      final configs = producer.produceForFile(
        filePath: '${tempDir.path}/test/unit_test.dart',
        projectRoot: tempDir.path,
      );

      expect(configs.length, equals(1));
      final config = configs.first;
      expect(config.kind, equals(RunConfigurationKind.test));
      expect(config.isTest, isTrue);
      expect(config.name, equals('Test: unit_test.dart'));
      expect(config.type, equals('dart'));
    });

    test('produz configuração de execução para arquivo .dart comum', () {
      final configs = producer.produceForFile(
        filePath: '${tempDir.path}/bin/main.dart',
        projectRoot: tempDir.path,
      );

      expect(configs.length, equals(1));
      final config = configs.first;
      expect(config.kind, equals(RunConfigurationKind.run));
      expect(config.isTest, isFalse);
      expect(config.name, equals('Run: main.dart'));
    });

    test('detecta projeto Flutter ao encontrar pubspec com sdk: flutter', () {
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: sample_flutter
dependencies:
  flutter:
    sdk: flutter
''');

      final configs = producer.produceForFile(
        filePath: '${tempDir.path}/test/widget_test.dart',
        projectRoot: tempDir.path,
      );

      expect(configs.length, equals(1));
      expect(configs.first.type, equals('flutter'));
      expect(configs.first.isTest, isTrue);
    });

    test('produz configuração para teste TypeScript e Python', () {
      final tsConfigs = producer.produceForFile(
        filePath: '${tempDir.path}/src/service.spec.ts',
        projectRoot: tempDir.path,
      );
      expect(tsConfigs.length, equals(1));
      expect(tsConfigs.first.type, equals('typescript'));
      expect(tsConfigs.first.isTest, isTrue);

      final pyConfigs = producer.produceForFile(
        filePath: '${tempDir.path}/tests/test_api.py',
        projectRoot: tempDir.path,
      );
      expect(pyConfigs.length, equals(1));
      expect(pyConfigs.first.type, equals('python'));
      expect(pyConfigs.first.isTest, isTrue);
    });
  });

  group('LaunchJsonLoader', () {
    const loader = LaunchJsonLoader();
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('launch_json_test_');
      Directory('${tempDir.path}/.vscode').createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('parseia .vscode/launch.json com variáveis e comentários (JSONC)', () async {
      final launchFile = File('${tempDir.path}/.vscode/launch.json');
      await launchFile.writeAsString('''
{
  // Configurações de execução VSCode / Orkest
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Dart: Run Current File",
      "type": "dart",
      "request": "launch",
      "program": "\${workspaceFolder}/bin/server.dart",
      "args": ["--port", "8080"],
      "env": {
        "DEBUG": "1"
      },
      "cwd": "\${workspaceFolder}"
    },
    {
      "name": "Flutter: Run App",
      "type": "flutter",
      "request": "launch",
      "program": "lib/main.dart",
    }
  ]
}
''');

      final configs = await loader.load(tempDir.path);
      expect(configs.length, equals(2));

      final first = configs.first;
      expect(first.name, equals('Dart: Run Current File'));
      expect(first.type, equals('dart'));
      expect(first.program, equals('${tempDir.path}/bin/server.dart'));
      expect(first.args, equals(['--port', '8080']));
      expect(first.env, equals({'DEBUG': '1'}));
      expect(first.cwd, equals(tempDir.path));

      final second = configs[1];
      expect(second.name, equals('Flutter: Run App'));
      expect(second.type, equals('flutter'));
      expect(second.program, equals('lib/main.dart'));
    });

    test('resolve referências nomeadas \${workspaceFolder:nome} em workspace multi-root', () async {
      final subDir = Directory('${tempDir.path}/client')..createSync();
      final launchFile = File('${tempDir.path}/.vscode/launch.json');
      await launchFile.writeAsString('''
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Run Client App",
      "type": "dart",
      "program": "\${workspaceFolder:client}/lib/main.dart",
      "cwd": "\${workspaceFolder:client}"
    }
  ]
}
''');

      final configs = await loader.load(
        tempDir.path,
        workspaceRoots: [tempDir.path, subDir.path],
      );

      expect(configs.length, equals(1));
      expect(configs.first.name, equals('Run Client App'));
      expect(configs.first.program, equals('${subDir.path}/lib/main.dart'));
      expect(configs.first.cwd, equals(subDir.path));
    });
  });

  group('RunConfigurationLoader expand & multi-root contextual discovery', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('run_loader_test_');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('expande referências nomeadas \${workspaceFolder:nome}', () {
      final expanded = RunConfigurationLoader.expand(
        {
          'program': r'${workspaceFolder:server}/bin/main.dart',
          'cwd': r'${workspaceFolder:client}',
          'args': [r'--config=${workspaceFolder:server}/config.json'],
        },
        '/workspace/main',
        null,
        workspaceRoots: ['/workspace/server', '/workspace/client'],
      );

      expect(expanded['program'], equals('/workspace/server/bin/main.dart'));
      expect(expanded['cwd'], equals('/workspace/client'));
      expect(expanded['args'], equals(['--config=/workspace/server/config.json']));
    });

    test('descobre contextualmente configurações de subprojetos monorepo com launch.json próprio', () async {
      final subprojectDir = Directory('${tempDir.path}/packages/backend')..createSync(recursive: true);
      File('${subprojectDir.path}/pubspec.yaml').writeAsStringSync('name: backend\n');
      Directory('${subprojectDir.path}/.vscode').createSync(recursive: true);
      File('${subprojectDir.path}/.vscode/launch.json').writeAsStringSync('''
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Backend Service",
      "type": "dart",
      "program": "bin/server.dart"
    }
  ]
}
''');
      final targetFile = File('${subprojectDir.path}/bin/server.dart')..createSync(recursive: true);

      const runLoader = RunConfigurationLoader();
      final configs = await runLoader.load(
        tempDir.path,
        targetFile.path,
        workspaceRoots: [tempDir.path],
      );

      final hasBackendService = configs.any((c) => c.name.contains('Backend Service'));
      expect(hasBackendService, isTrue);
    });
  });
}
