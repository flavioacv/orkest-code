/// Perfil de hardware e ambiente host capturado durante o benchmark (A02).
class HostHardwareProfile {
  const HostHardwareProfile({
    required this.architecture,
    required this.cpuCores,
    required this.totalMemoryMb,
    required this.osPlatform,
    required this.osRelease,
  });

  final String architecture; // x86_64, arm64
  final int cpuCores;
  final int totalMemoryMb;
  final String osPlatform; // macos, linux, windows
  final String osRelease;
}

/// Tamanho do corpus utilizado no teste de carga (A02).
enum CorpusScale {
  small, // ~50 arquivos, 10k linhas
  large, // ~5.000 arquivos, 500k linhas
}

/// Estado dos caches e do heap no início da medição (A02).
enum CacheState {
  cold, // Sem caches em memória, cold start
  warm, // Caches e buffers populados, heap aquecido
}

/// Medição estatística de desempenho de uma operação crítica (A02).
class BaselineMeasurement {
  const BaselineMeasurement({
    required this.operationId,
    required this.runtimeTarget,
    required this.corpusScale,
    required this.cacheState,
    required this.iterations,
    required this.p50Ms,
    required this.p95Ms,
    required this.maxMs,
    required this.memoryRssMb,
    required this.cpuPercent,
    required this.jankFramesCount,
    required this.cancelLatencyMs,
    required this.ipcBytesTransferred,
    this.remoteRoundtripBytes = 0,
  });

  final String operationId; // fileIndex, diff3Merge, textSearch, rpcDispatch
  final String runtimeTarget; // Dart (Orkest), TypeScript (Node), Rust (IPC/FFI)
  final CorpusScale corpusScale;
  final CacheState cacheState;
  final int iterations;

  // Latências estatísticas
  final double p50Ms;
  final double p95Ms;
  final double maxMs;

  // Recursos do host
  final double memoryRssMb;
  final double cpuPercent;
  final int jankFramesCount; // Frames que excederam 16.7ms (> 60fps)

  // Resposta a cancelamento e I/O
  final double cancelLatencyMs;
  final int ipcBytesTransferred;
  final int remoteRoundtripBytes;
}

/// Relatório consolidado de baseline de performance sem presunção de ganho em Rust (A02).
class PerformanceBaselineReport {
  const PerformanceBaselineReport({
    required this.id,
    required this.hardware,
    required this.runtimeVersions,
    required this.measurements,
    required this.generatedAt,
    this.rustGainPresumed = false,
  });

  final String id;
  final HostHardwareProfile hardware;
  final Map<String, String> runtimeVersions;
  final List<BaselineMeasurement> measurements;
  final DateTime generatedAt;

  /// Exigência inegociável do aceite: nenhum ganho de Rust presumido a priori.
  final bool rustGainPresumed;

  List<BaselineMeasurement> byOperation(String opId) =>
      measurements.where((m) => m.operationId == opId).toList(growable: false);

  List<BaselineMeasurement> byScale(CorpusScale scale) =>
      measurements.where((m) => m.corpusScale == scale).toList(growable: false);

  /// Calcula a razão de sobrecarga média de ponte IPC/FFI em relação ao processamento puro.
  double computeAverageBridgeOverheadRatio() {
    final ipcMeasurements =
        measurements.where((m) => m.ipcBytesTransferred > 0).toList();
    if (ipcMeasurements.isEmpty) return 1.0;
    // Cômputo do overhead de serialização
    return ipcMeasurements.fold(0.0, (acc, m) => acc + (m.p95Ms / (m.p50Ms > 0 ? m.p50Ms : 1.0))) /
        ipcMeasurements.length;
  }
}
