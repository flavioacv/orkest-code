import 'dart:io';

/// Plataforma e arquitetura de sistema operacional.
enum NativePlatformArch {
  macosArm64('macos', 'arm64', ''),
  macosX64('macos', 'x64', ''),
  linuxArm64('linux', 'arm64', ''),
  linuxX64('linux', 'x64', ''),
  windowsArm64('windows', 'arm64', '.exe'),
  windowsX64('windows', 'x64', '.exe'),
  unsupported('unknown', 'unknown', '');

  const NativePlatformArch(this.os, this.arch, this.executableExtension);

  final String os;
  final String arch;
  final String executableExtension;

  String get directoryName => '$os-$arch';

  /// Detecta a plataforma e arquitetura do ambiente de execução atual.
  static NativePlatformArch current() {
    final isArm = Platform.version.contains('arm') ||
        Platform.version.contains('aarch64') ||
        (Platform.environment['PROCESSOR_ARCHITECTURE']?.toLowerCase().contains('arm') ?? false);

    if (Platform.isMacOS) {
      return isArm ? NativePlatformArch.macosArm64 : NativePlatformArch.macosX64;
    } else if (Platform.isLinux) {
      return isArm ? NativePlatformArch.linuxArm64 : NativePlatformArch.linuxX64;
    } else if (Platform.isWindows) {
      return isArm ? NativePlatformArch.windowsArm64 : NativePlatformArch.windowsX64;
    }
    return NativePlatformArch.unsupported;
  }
}

/// Exceção lançada quando um binário nativo obrigatório não é encontrado (A05).
class NativeBinaryNotFoundException implements Exception {
  const NativeBinaryNotFoundException(this.binaryName, this.searchedPaths);

  final String binaryName;
  final List<String> searchedPaths;

  @override
  String toString() =>
      'NativeBinaryNotFoundException: binary "$binaryName" was not found in: ${searchedPaths.join(', ')}';
}

/// Resolutor de binários nativos por sistema operacional e arquitetura (A05).
class NativeBinaryResolver {
  const NativeBinaryResolver({
    this.customPlatform,
    this.bundledBinariesDir,
  });

  final NativePlatformArch? customPlatform;
  final String? bundledBinariesDir;

  NativePlatformArch get platform => customPlatform ?? NativePlatformArch.current();

  /// Resolve o caminho absoluto do binário [binaryName].
  ///
  /// Ordem de busca:
  /// 1. Diretório de binários empacotados (`bundledBinariesDir/<os>-<arch>/<binaryName>`)
  /// 2. Diretório local de desenvolvimento (`.orkest/bin/<binaryName>`)
  /// 3. Executável no PATH do sistema operacional (se [allowSystemPath] for true)
  String? resolve(
    String binaryName, {
    String? workspaceRoot,
    bool allowSystemPath = true,
  }) {
    final ext = platform.executableExtension;
    final fullName = binaryName.endsWith(ext) ? binaryName : '$binaryName$ext';
    final searched = <String>[];

    // 1. Bundled binaries
    if (bundledBinariesDir != null) {
      final bundledPath = '$bundledBinariesDir/${platform.directoryName}/$fullName';
      searched.add(bundledPath);
      if (File(bundledPath).existsSync()) {
        return bundledPath;
      }
    }

    // 2. Workspace local (.orkest/bin/)
    if (workspaceRoot != null) {
      final wsPath = '$workspaceRoot/.orkest/bin/$fullName';
      searched.add(wsPath);
      if (File(wsPath).existsSync()) {
        return wsPath;
      }
    }

    // 3. Sistema (PATH)
    if (allowSystemPath) {
      searched.add('PATH ($fullName)');
      final systemPath = _findInSystemPath(fullName);
      if (systemPath != null) {
        return systemPath;
      }
    }

    return null;
  }

  /// Resolve obrigatoriamente ou lança [NativeBinaryNotFoundException].
  String resolveRequired(
    String binaryName, {
    String? workspaceRoot,
    bool allowSystemPath = true,
  }) {
    final result = resolve(
      binaryName,
      workspaceRoot: workspaceRoot,
      allowSystemPath: allowSystemPath,
    );
    if (result != null) return result;

    final ext = platform.executableExtension;
    final fullName = binaryName.endsWith(ext) ? binaryName : '$binaryName$ext';
    final searched = <String>[
      if (bundledBinariesDir != null) '$bundledBinariesDir/${platform.directoryName}/$fullName',
      if (workspaceRoot != null) '$workspaceRoot/.orkest/bin/$fullName',
      if (allowSystemPath) 'PATH ($fullName)',
    ];
    throw NativeBinaryNotFoundException(binaryName, searched);
  }

  static String? _findInSystemPath(String executable) {
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv == null) return null;
    final separator = Platform.isWindows ? ';' : ':';
    final dirs = pathEnv.split(separator);

    for (final dir in dirs) {
      if (dir.trim().isEmpty) continue;
      final file = File('$dir/$executable');
      if (file.existsSync()) {
        return file.path;
      }
    }
    return null;
  }
}
