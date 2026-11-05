import 'dart:convert';
import 'package:orkest_code/app/core/domain/entities/docker_build_deploy.dart';

/// Analisador determinístico de saídas de inspeção, logs e status do Docker/Podman (X03).
class DockerInspectionParser {
  const DockerInspectionParser();

  /// Decodifica saídas JSON emitidas por `docker ps --format "{{json .}}"` ou `docker inspect`.
  List<DockerContainer> parsePsJson(String jsonLinesOutput) {
    final lines = jsonLinesOutput.split('\n');
    final containers = <DockerContainer>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final id = decoded['ID'] ?? decoded['Id'] ?? decoded['id'] ?? '';
          final namesRaw = decoded['Names'] ?? decoded['Names'] ?? decoded['names'];
          final names = namesRaw is List
              ? namesRaw.map((e) => '$e').toList()
              : namesRaw is String
                  ? namesRaw.split(',').map((e) => e.trim()).toList()
                  : <String>[];

          final image = decoded['Image'] ?? decoded['image'] ?? 'unknown';
          final statusText = decoded['Status'] ?? decoded['State'] ?? '';
          final command = decoded['Command'] ?? decoded['command'];
          final portsRaw = decoded['Ports'] ?? decoded['ports'] ?? '';
          final ports = portsRaw is String && portsRaw.isNotEmpty
              ? portsRaw.split(',').map((p) => p.trim()).toList()
              : <String>[];

          final status = _parseStatus(statusText);

          containers.add(
            DockerContainer(
              id: id,
              names: List.unmodifiable(names),
              image: image,
              status: status,
              statusText: statusText,
              command: command,
              ports: List.unmodifiable(ports),
            ),
          );
        }
      } catch (_) {
        // Ignora linhas que não sejam JSON válido
      }
    }

    return List.unmodifiable(containers);
  }

  /// Processa a saída de `docker inspect <id>` gerando um [DockerInspectReport].
  DockerInspectReport? parseInspectJson(String inspectJson) {
    try {
      final decoded = jsonDecode(inspectJson);
      final Map<String, dynamic> data = decoded is List && decoded.isNotEmpty
          ? decoded.first as Map<String, dynamic>
          : decoded is Map<String, dynamic>
              ? decoded
              : {};

      if (data.isEmpty) return null;

      final id = data['Id'] ?? data['ID'] ?? '';
      final name = (data['Name'] ?? '').toString().replaceFirst('/', '');
      final config = (data['Config'] as Map<String, dynamic>?) ?? {};
      final image = config['Image'] ?? '';
      final envList = (config['Env'] as List?)?.map((e) => '$e').toList() ?? [];

      final state = (data['State'] as Map<String, dynamic>?) ?? {};
      final stateStatus = state['Status'] ?? '';
      final status = _parseStatus(stateStatus);
      final exitCode = state['ExitCode'] as int?;

      final net = (data['NetworkSettings'] as Map<String, dynamic>?) ?? {};
      final ipAddress = net['IPAddress'] ?? '';

      final portsMap = <String, String>{};
      final portsObj = net['Ports'] as Map<String, dynamic>?;
      if (portsObj != null) {
        portsObj.forEach((key, val) {
          if (val is List && val.isNotEmpty && val.first is Map) {
            final hostPort = val.first['HostPort'];
            if (hostPort != null) portsMap[key] = '$hostPort';
          }
        });
      }

      final mounts = (data['Mounts'] as List?)
              ?.map((m) => m is Map ? '${m['Source']}:${m['Destination']}' : '$m')
              .toList() ??
          [];

      final hostConfig = (data['HostConfig'] as Map<String, dynamic>?) ?? {};
      final restartPolicy =
          (hostConfig['RestartPolicy'] as Map<String, dynamic>?)?['Name'] ?? 'no';

      return DockerInspectReport(
        containerId: id,
        name: name,
        image: image,
        status: status,
        ipAddress: ipAddress,
        envVariables: List.unmodifiable(envList),
        portBindings: Map.unmodifiable(portsMap),
        volumes: List.unmodifiable(mounts),
        restartPolicy: restartPolicy,
        exitCode: exitCode,
      );
    } catch (_) {
      return null;
    }
  }

  DockerContainerStatus _parseStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('up') || lower.contains('running')) {
      return DockerContainerStatus.running;
    }
    if (lower.contains('exit') || lower.contains('stopped')) {
      return DockerContainerStatus.exited;
    }
    if (lower.contains('paused')) {
      return DockerContainerStatus.paused;
    }
    if (lower.contains('restart')) {
      return DockerContainerStatus.restarting;
    }
    if (lower.contains('dead')) {
      return DockerContainerStatus.dead;
    }
    return DockerContainerStatus.unknown;
  }
}

/// Detector de tarefas de build úteis no workspace sem instalação arbitrária de pacotes (X03).
class UsefulBuildTaskDetector {
  const UsefulBuildTaskDetector();

  /// Analisa a lista de arquivos presentes no workspace [workspaceFilePaths] e
  /// sugere tarefas de build legítimas e contextualizadas.
  List<UsefulBuildTask> detectTasks({
    required List<String> workspaceFilePaths,
  }) {
    final tasks = <UsefulBuildTask>[];
    final fileSet = workspaceFilePaths.map((p) => p.replaceAll('\\', '/')).toSet();

    // 1. Flutter / Dart
    if (fileSet.any((p) => p.endsWith('pubspec.yaml'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.flutter.bundle',
          name: 'Flutter Build Bundle',
          tool: 'flutter',
          command: 'flutter',
          args: ['build', 'bundle'],
          kind: BuildTaskKind.bundle,
          isDefault: true,
        ),
      );
      tasks.add(
        const UsefulBuildTask(
          id: 'build.flutter.test',
          name: 'Flutter Run Tests',
          tool: 'flutter',
          command: 'flutter',
          args: ['test'],
          kind: BuildTaskKind.test,
        ),
      );
    }

    // 2. Cargo (Rust)
    if (fileSet.any((p) => p.endsWith('Cargo.toml'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.cargo.release',
          name: 'Cargo Build Release',
          tool: 'cargo',
          command: 'cargo',
          args: ['build', '--release'],
          kind: BuildTaskKind.compile,
          isDefault: true,
        ),
      );
      tasks.add(
        const UsefulBuildTask(
          id: 'build.cargo.test',
          name: 'Cargo Test',
          tool: 'cargo',
          command: 'cargo',
          args: ['test'],
          kind: BuildTaskKind.test,
        ),
      );
    }

    // 3. Node / Web
    if (fileSet.any((p) => p.endsWith('package.json'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.npm.run',
          name: 'NPM Build',
          tool: 'npm',
          command: 'npm',
          args: ['run', 'build'],
          kind: BuildTaskKind.bundle,
          isDefault: true,
        ),
      );
    }

    // 4. Go
    if (fileSet.any((p) => p.endsWith('go.mod'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.go.compile',
          name: 'Go Build',
          tool: 'go',
          command: 'go',
          args: ['build', './...'],
          kind: BuildTaskKind.compile,
          isDefault: true,
        ),
      );
    }

    // 5. Makefile
    if (fileSet.any((p) => p.endsWith('Makefile') || p.endsWith('makefile'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.make.all',
          name: 'Make Build',
          tool: 'make',
          command: 'make',
          args: ['build'],
          kind: BuildTaskKind.compile,
        ),
      );
    }

    // 6. Dockerfile
    if (fileSet.any((p) => p.endsWith('Dockerfile') || p.contains('/Dockerfile.'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.docker.image',
          name: 'Docker Build Image',
          tool: 'docker',
          command: 'docker',
          args: ['build', '-t', 'app:latest', '.'],
          kind: BuildTaskKind.dockerBuild,
        ),
      );
    }

    // 7. Docker Compose
    if (fileSet.any((p) =>
        p.endsWith('docker-compose.yml') ||
        p.endsWith('docker-compose.yaml') ||
        p.endsWith('compose.yaml') ||
        p.endsWith('compose.yml'))) {
      tasks.add(
        const UsefulBuildTask(
          id: 'build.docker.compose',
          name: 'Docker Compose Build',
          tool: 'docker',
          command: 'docker',
          args: ['compose', 'build'],
          kind: BuildTaskKind.dockerBuild,
        ),
      );
    }

    return List.unmodifiable(tasks);
  }
}

/// Orquestrador de planos de deployment seguro com preview de diferenças e confirmação explícita (X03).
class DeploymentPlanService {
  const DeploymentPlanService();

  /// Constrói o plano de deployment comparando o inventário local com o alvo remoto.
  DeploymentPlan buildPlan({
    required String targetName,
    required String targetHostOrUrl,
    required Map<String, int> sourceFiles, // path -> size
    required Map<String, int> targetFiles, // path -> size
    Map<String, String>? sourceHashes,
    Map<String, String>? targetHashes,
  }) {
    final entries = <DeploymentDiffEntry>[];
    final allKeys = {...sourceFiles.keys, ...targetFiles.keys};

    for (final path in allKeys) {
      final inSource = sourceFiles.containsKey(path);
      final inTarget = targetFiles.containsKey(path);

      if (inSource && !inTarget) {
        entries.add(
          DeploymentDiffEntry(
            relativePath: path,
            kind: DeploymentDiffKind.added,
            sourceSizeBytes: sourceFiles[path]!,
            sourceHash: sourceHashes?[path],
          ),
        );
      } else if (!inSource && inTarget) {
        entries.add(
          DeploymentDiffEntry(
            relativePath: path,
            kind: DeploymentDiffKind.deleted,
            sourceSizeBytes: 0,
            targetSizeBytes: targetFiles[path],
            targetHash: targetHashes?[path],
          ),
        );
      } else {
        // Presente em ambos: verifica se o tamanho ou hash diferem
        final srcSize = sourceFiles[path]!;
        final tgtSize = targetFiles[path]!;
        final srcHash = sourceHashes?[path];
        final tgtHash = targetHashes?[path];

        final isModified = srcHash != null && tgtHash != null
            ? srcHash != tgtHash
            : srcSize != tgtSize;

        entries.add(
          DeploymentDiffEntry(
            relativePath: path,
            kind: isModified ? DeploymentDiffKind.modified : DeploymentDiffKind.unchanged,
            sourceSizeBytes: srcSize,
            targetSizeBytes: tgtSize,
            sourceHash: srcHash,
            targetHash: tgtHash,
          ),
        );
      }
    }

    entries.sort((a, b) => a.relativePath.compareTo(b.relativePath));

    return DeploymentPlan(
      id: 'deploy_${DateTime.now().microsecondsSinceEpoch}',
      targetName: targetName,
      targetHostOrUrl: targetHostOrUrl,
      entries: List.unmodifiable(entries),
      createdAt: DateTime.now(),
      isConfirmed: false, // Mandatório: inicia estritamente desconfirmado
    );
  }

  /// Confirma explicitamente o plano após inspeção humana.
  DeploymentPlan confirmPlan(DeploymentPlan plan) {
    return plan.copyWith(isConfirmed: true);
  }

  /// Executa o deployment apenas se houver confirmação explícita comprovada.
  bool executeDeployment(DeploymentPlan plan) {
    if (!plan.isConfirmed) {
      throw StateError(
        'Deployment unconfirmed: O plano para "${plan.targetName}" requer confirmação explícita antes de qualquer envio de arquivos.',
      );
    }
    return true;
  }
}
