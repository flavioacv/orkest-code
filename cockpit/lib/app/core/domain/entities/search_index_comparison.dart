/// Tipos de motor de busca e indexação avaliados no benchmark (M02).
enum SearchEngineKind {
  dartPureIsolate,
  rustRipgrepProcess,
  rustFfiNative,
}

/// Dimensões críticas de auditoria comparativa (M02).
enum SearchComparisonDimension {
  exclusionsAndGitignore, // Respeito a .gitignore e pastas ignoradas
  symlinkHandling, // Prevenção de loops cíclicos em links simbólicos
  binaryDetection, // Detecção e descarte rápido de arquivos binários
  regexParity, // Compatibilidade e segurança contra ReDoS em expressões regulares
  cancelResponsiveness, // Latência para cancelar varreduras e limpar recursos
  memoryRssFootprint, // Consumo de memória residente (RSS) durante a indexação
  incrementalIndexLatency, // Custo de atualização incremental após alterações de arquivos
}

/// Amostra de benchmark para uma varredura de busca ou indexação (M02).
class SearchBenchmarkSample {
  const SearchBenchmarkSample({
    required this.engine,
    required this.dimension,
    required this.totalFilesScanned,
    required this.matchesFound,
    required this.elapsedTimeMs,
    required this.cancelLatencyMs,
    required this.peakRssDeltaMb,
    required this.cpuUtilizationPercent,
    required this.leftoverZombieProcesses,
  });

  final SearchEngineKind engine;
  final SearchComparisonDimension dimension;
  final int totalFilesScanned;
  final int matchesFound;
  final double elapsedTimeMs;
  final double cancelLatencyMs;
  final double peakRssDeltaMb;
  final double cpuUtilizationPercent;
  final int leftoverZombieProcesses;

  /// Taxa de varredura em arquivos por segundo.
  double get filesPerSecond =>
      elapsedTimeMs > 0 ? (totalFilesScanned / (elapsedTimeMs / 1000.0)) : 0.0;
}

/// Veredito arquitetural formal para os subsistemas de busca e indexação (M02).
class SearchDecisionVerdict {
  const SearchDecisionVerdict({
    required this.subsystem,
    required this.chosenEngine,
    required this.rationale,
    required this.recommendation,
    required this.measuredLatencyMs,
    required this.cancelGuarantee,
  });

  final String subsystem; // 'FileSearcher (Quick Open)', 'ContentSearcher (Find in Files)', 'SymbolIndex'
  final SearchEngineKind chosenEngine;
  final String rationale;
  final String recommendation;
  final double measuredLatencyMs;
  final String cancelGuarantee;
}
