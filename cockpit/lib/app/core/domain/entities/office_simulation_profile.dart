/// Modos de execução da engine do mundo virtual do Office (M03).
enum OfficeEngineMode {
  typescriptWebView, // Legado: JS/Canvas 2D dentro de InAppWebView
  flutterNativeDart, // Nativo: CustomPainter + simulação em Dart puro
  rustWasmOrFfi, // Hipótese avaliada: compilação de hotspot de simulação em Rust
}

/// Fases discretas do ciclo de vida por frame no Office (M03).
enum OfficeProfilingStage {
  snapshotGeneration, // Coleta de sessões e status das tarefas no Dart
  serializationBridge, // Conversão JSON e transporte IPC/bridge para WebView ou Rust
  simulationLogic, // Movimentação, pathfinding A*, colisões e máquinas de estado de agentes
  renderingPipeline, // Desenho de sprites, sombras e luzes no Canvas/Skia
}

/// Amostra de métricas de desempenho obtidas em cada modo de execução (M03).
class OfficePerformanceBenchmark {
  const OfficePerformanceBenchmark({
    required this.mode,
    required this.targetFps,
    required this.measuredAverageFps,
    required this.frameDurationMs,
    required this.serializationOverheadMs,
    required this.simulationDurationMs,
    required this.renderDurationMs,
    required this.memoryRssDeltaMb,
    required this.cpuUsagePercent,
  });

  final OfficeEngineMode mode;
  final double targetFps;
  final double measuredAverageFps;
  final double frameDurationMs; // Total por frame
  final double serializationOverheadMs;
  final double simulationDurationMs;
  final double renderDurationMs;
  final double memoryRssDeltaMb;
  final double cpuUsagePercent;

  /// Indica se a taxa de quadros atinge fluidez aceitável (≥ 58 fps).
  bool get isSmooth60Fps => measuredAverageFps >= 58.0;

  /// Razão do tempo gasto com ponte/serialização frente ao tempo total de frame.
  double get bridgeOverheadRatio =>
      frameDurationMs > 0 ? (serializationOverheadMs / frameDurationMs) : 0.0;
}

/// Veredito arquitetural e decisão sobre a engine do Office (M03).
class OfficeMigrationVerdict {
  const OfficeMigrationVerdict({
    required this.preferredMode,
    required this.shouldMigrateToRust,
    required this.rationale,
    required this.measuredFrameBudgetSavings,
    required this.memorySavingsMb,
  });

  final OfficeEngineMode preferredMode;
  final bool shouldMigrateToRust;
  final String rationale;
  final String measuredFrameBudgetSavings;
  final double memorySavingsMb;
}
