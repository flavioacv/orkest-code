import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/docker_build_deploy.dart';
import 'package:orkest_code/app/core/domain/services/docker_build_deploy_service.dart';

void main() {
  group('DockerInspectionParser (X03)', () {
    const parser = DockerInspectionParser();

    test('parses docker ps json stream accurately', () {
      const psOutput = '''
{"ID":"c1a2b3c4d5e6","Names":"backend_api","Image":"node:20-alpine","Status":"Up 3 hours","Ports":"0.0.0.0:3000->3000/tcp","Command":"npm start"}
{"ID":"f7e8d9c0b1a2","Names":"postgres_db,db","Image":"postgres:16","Status":"Up 4 hours","Ports":"0.0.0.0:5432->5432/tcp","Command":"docker-entrypoint.sh postgres"}
{"ID":"1234567890ab","Names":"worker_job","Image":"python:3.11","Status":"Exited (0) 10 minutes ago","Ports":"","Command":"python worker.py"}
''';

      final containers = parser.parsePsJson(psOutput);
      expect(containers.length, equals(3));

      expect(containers[0].id, equals('c1a2b3c4d5e6'));
      expect(containers[0].primaryName, equals('backend_api'));
      expect(containers[0].isRunning, isTrue);
      expect(containers[0].status, equals(DockerContainerStatus.running));
      expect(containers[0].ports, contains('0.0.0.0:3000->3000/tcp'));

      expect(containers[1].primaryName, equals('postgres_db'));
      expect(containers[1].isRunning, isTrue);

      expect(containers[2].primaryName, equals('worker_job'));
      expect(containers[2].isRunning, isFalse);
      expect(containers[2].status, equals(DockerContainerStatus.exited));
    });

    test('parses docker inspect json report with network, ports and volumes', () {
      const inspectJson = '''
[{
  "Id": "c1a2b3c4d5e67890abcdef1234567890",
  "Name": "/my_web_service",
  "State": {
    "Status": "running",
    "Running": true,
    "ExitCode": 0
  },
  "Config": {
    "Image": "nginx:alpine",
    "Env": ["PORT=80", "NODE_ENV=production"]
  },
  "NetworkSettings": {
    "IPAddress": "172.18.0.4",
    "Ports": {
      "80/tcp": [{"HostIp": "0.0.0.0", "HostPort": "8080"}]
    }
  },
  "Mounts": [
    {"Source": "/var/data", "Destination": "/usr/share/nginx/html"}
  ],
  "HostConfig": {
    "RestartPolicy": {"Name": "unless-stopped"}
  }
}]
''';

      final report = parser.parseInspectJson(inspectJson);
      expect(report, isNotNull);
      expect(report!.name, equals('my_web_service'));
      expect(report.image, equals('nginx:alpine'));
      expect(report.status, equals(DockerContainerStatus.running));
      expect(report.ipAddress, equals('172.18.0.4'));
      expect(report.portBindings['80/tcp'], equals('8080'));
      expect(report.volumes, contains('/var/data:/usr/share/nginx/html'));
      expect(report.restartPolicy, equals('unless-stopped'));
    });
  });

  group('UsefulBuildTaskDetector (X03)', () {
    const detector = UsefulBuildTaskDetector();

    test('detects build tasks for Flutter, Cargo, NPM and Docker without installing tools', () {
      final workspaceFiles = [
        'lib/main.dart',
        'pubspec.yaml',
        'frontend/package.json',
        'backend/Cargo.toml',
        'deploy/Dockerfile',
        'compose.yaml',
      ];

      final tasks = detector.detectTasks(workspaceFilePaths: workspaceFiles);
      expect(tasks, isNotEmpty);

      final tools = tasks.map((t) => t.tool).toSet();
      expect(tools, contains('flutter'));
      expect(tools, contains('npm'));
      expect(tools, contains('cargo'));
      expect(tools, contains('docker'));

      // Valida comando do Flutter
      final flutterTask = tasks.firstWhere((t) => t.id == 'build.flutter.bundle');
      expect(flutterTask.fullCommandLine, equals('flutter build bundle'));
      expect(flutterTask.isDefault, isTrue);

      // Valida comando do Cargo
      final cargoTask = tasks.firstWhere((t) => t.id == 'build.cargo.release');
      expect(cargoTask.fullCommandLine, equals('cargo build --release'));

      // Valida comando do Docker Compose
      final composeTask = tasks.firstWhere((t) => t.id == 'build.docker.compose');
      expect(composeTask.fullCommandLine, equals('docker compose build'));
    });
  });

  group('DeploymentPlanService & Safety Confirmations (X03)', () {
    const deployService = DeploymentPlanService();

    test('computes deployment diff accurately (added, modified, deleted, unchanged)', () {
      final sourceFiles = {
        'dist/index.html': 1024,
        'dist/main.js': 20480, // Modificado (mesmo path, tamanho diferente)
        'dist/new_asset.png': 5120, // Adicionado
      };

      final targetFiles = {
        'dist/index.html': 1024, // Inalterado
        'dist/main.js': 18000,
        'dist/old_script.js': 4096, // Removido
      };

      final plan = deployService.buildPlan(
        targetName: 'Production Cloudflare Pages',
        targetHostOrUrl: 'https://api.cloudflare.com/deploy',
        sourceFiles: sourceFiles,
        targetFiles: targetFiles,
      );

      expect(plan.targetName, equals('Production Cloudflare Pages'));
      expect(plan.isConfirmed, isFalse); // Segurança: inicia estritamente desconfirmado
      expect(plan.addedCount, equals(1));
      expect(plan.modifiedCount, equals(1));
      expect(plan.deletedCount, equals(1));
      expect(plan.totalChanges, equals(3));
      expect(plan.totalTransferBytes, equals(1024 + 20480 + 5120 - 1024)); // main.js + new_asset.png
    });

    test('enforces explicit user confirmation before executing deployment', () {
      final plan = deployService.buildPlan(
        targetName: 'Staging Server',
        targetHostOrUrl: 'ssh://deploy@10.0.0.15',
        sourceFiles: {'app.bin': 5000},
        targetFiles: {},
      );

      expect(plan.isConfirmed, isFalse);

      // Tentativa de execução sem confirmação deve falhar com erro tipado
      expect(
        () => deployService.executeDeployment(plan),
        throwsA(isA<StateError>()),
      );

      // Com confirmação explícita comprovada, a execução prossegue com segurança
      final confirmedPlan = deployService.confirmPlan(plan);
      expect(confirmedPlan.isConfirmed, isTrue);
      expect(deployService.executeDeployment(confirmedPlan), isTrue);
    });
  });
}
