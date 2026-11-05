/// Estado de execução de um container Docker/Podman (X03).
enum DockerContainerStatus {
  running,
  exited,
  paused,
  restarting,
  dead,
  unknown,
}

/// Representação imutável de um container de desenvolvimento ou serviço (X03).
class DockerContainer {
  const DockerContainer({
    required this.id,
    required this.names,
    required this.image,
    required this.status,
    required this.statusText,
    this.command,
    this.ports = const [],
    this.mounts = const [],
    this.labels = const {},
    this.createdAt,
    this.exitCode,
  });

  final String id;
  final List<String> names;
  final String image;
  final DockerContainerStatus status;
  final String statusText;
  final String? command;
  final List<String> ports;
  final List<String> mounts;
  final Map<String, String> labels;
  final DateTime? createdAt;
  final int? exitCode;

  String get primaryName =>
      names.isNotEmpty ? names.first.replaceFirst('/', '') : id.substring(0, 12);

  bool get isRunning => status == DockerContainerStatus.running;
}

/// Diagnóstico detalhado de inspect de container (X03).
class DockerInspectReport {
  const DockerInspectReport({
    required this.containerId,
    required this.name,
    required this.image,
    required this.status,
    required this.ipAddress,
    required this.envVariables,
    required this.portBindings,
    required this.volumes,
    required this.restartPolicy,
    this.startedAt,
    this.finishedAt,
    this.exitCode,
  });

  final String containerId;
  final String name;
  final String image;
  final DockerContainerStatus status;
  final String ipAddress;
  final List<String> envVariables;
  final Map<String, String> portBindings; // ex: {"80/tcp": "8080"}
  final List<String> volumes;
  final String restartPolicy;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? exitCode;
}

/// Categoria funcional de tarefas de build (X03).
enum BuildTaskKind {
  compile,
  bundle,
  test,
  package,
  lint,
  clean,
  dockerBuild,
}

/// Tarefa útil de build detectada sem instalação forçada de dependências (X03).
class UsefulBuildTask {
  const UsefulBuildTask({
    required this.id,
    required this.name,
    required this.tool,
    required this.command,
    required this.kind,
    this.workingDirectory,
    this.args = const [],
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String tool; // flutter, cargo, npm, go, make, docker
  final String command;
  final BuildTaskKind kind;
  final String? workingDirectory;
  final List<String> args;
  final bool isDefault;

  String get fullCommandLine => ([command, ...args]).join(' ');
}

/// Tipo de alteração em artefato no plano de deployment (X03).
enum DeploymentDiffKind {
  added,
  modified,
  deleted,
  unchanged,
}

/// Diferença de arquivo calculada antes do deployment (X03).
class DeploymentDiffEntry {
  const DeploymentDiffEntry({
    required this.relativePath,
    required this.kind,
    required this.sourceSizeBytes,
    this.targetSizeBytes,
    this.sourceHash,
    this.targetHash,
  });

  final String relativePath;
  final DeploymentDiffKind kind;
  final int sourceSizeBytes;
  final int? targetSizeBytes;
  final String? sourceHash;
  final String? targetHash;
}

/// Plano de deployment seguro com pré-visualização de diferenças e confirmação (X03).
class DeploymentPlan {
  const DeploymentPlan({
    required this.id,
    required this.targetName,
    required this.targetHostOrUrl,
    required this.entries,
    this.createdAt,
    this.isConfirmed = false,
  });

  final String id;
  final String targetName; // ex: 'Staging SSH', 'Production S3', 'Local Docker'
  final String targetHostOrUrl;
  final List<DeploymentDiffEntry> entries;
  final DateTime? createdAt;

  /// Exigência inegociável de segurança: o deployment NUNCA executa sem confirmação explícita.
  final bool isConfirmed;

  int get addedCount =>
      entries.where((e) => e.kind == DeploymentDiffKind.added).length;

  int get modifiedCount =>
      entries.where((e) => e.kind == DeploymentDiffKind.modified).length;

  int get deletedCount =>
      entries.where((e) => e.kind == DeploymentDiffKind.deleted).length;

  int get totalChanges => addedCount + modifiedCount + deletedCount;

  int get totalTransferBytes => entries
      .where((e) =>
          e.kind == DeploymentDiffKind.added ||
          e.kind == DeploymentDiffKind.modified)
      .fold(0, (sum, e) => sum + e.sourceSizeBytes);

  DeploymentPlan copyWith({bool? isConfirmed}) {
    return DeploymentPlan(
      id: id,
      targetName: targetName,
      targetHostOrUrl: targetHostOrUrl,
      entries: entries,
      createdAt: createdAt,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }
}
