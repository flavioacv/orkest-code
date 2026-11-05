/// Status de execução de um caso de teste (R05).
enum TestStatus {
  passed,
  failed,
  skipped,
  running,
}

/// Nó folha representando um teste individual na árvore de execução (R05).
class TestCaseNode {
  const TestCaseNode({
    required this.id,
    required this.name,
    this.suiteName,
    required this.status,
    required this.durationMs,
    this.errorMessage,
    this.stackTrace,
    this.filePath,
    this.lineNumber,
  });

  /// Identificador estável do teste.
  final String id;

  /// Nome legível do teste.
  final String name;

  /// Nome da suite ou grupo ao qual o teste pertence.
  final String? suiteName;

  /// Status final da execução.
  final TestStatus status;

  /// Duração em milissegundos.
  final int durationMs;

  /// Mensagem de erro capturada caso tenha falhado.
  final String? errorMessage;

  /// Rastreamento de pilha caso tenha falhado.
  final String? stackTrace;

  /// Caminho relativo ou absoluto do arquivo onde o teste está definido.
  final String? filePath;

  /// Linha onde o teste está definido.
  final int? lineNumber;

  bool get isFailure => status == TestStatus.failed;
  bool get isPassed => status == TestStatus.passed;
  bool get isSkipped => status == TestStatus.skipped;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (suiteName != null) 'suite_name': suiteName,
        'status': status.name,
        'duration_ms': durationMs,
        if (errorMessage != null) 'error_message': errorMessage,
        if (stackTrace != null) 'stack_trace': stackTrace,
        if (filePath != null) 'file_path': filePath,
        if (lineNumber != null) 'line_number': lineNumber,
      };

  @override
  String toString() => 'TestCaseNode($name: ${status.name} [${durationMs}ms])';
}

/// Nó de agrupamento representando um arquivo ou suite de testes (R05).
class TestSuiteNode {
  const TestSuiteNode({
    required this.name,
    required this.testCases,
    required this.durationMs,
    this.filePath,
  });

  final String name;
  final List<TestCaseNode> testCases;
  final int durationMs;
  final String? filePath;

  int get totalCount => testCases.length;
  int get passedCount => testCases.where((t) => t.isPassed).length;
  int get failedCount => testCases.where((t) => t.isFailure).length;
  int get skippedCount => testCases.where((t) => t.isSkipped).length;
  bool get hasFailures => failedCount > 0;

  Map<String, dynamic> toJson() => {
        'name': name,
        'duration_ms': durationMs,
        if (filePath != null) 'file_path': filePath,
        'total': totalCount,
        'passed': passedCount,
        'failed': failedCount,
        'skipped': skippedCount,
        'test_cases': [for (final t in testCases) t.toJson()],
      };

  @override
  String toString() =>
      'TestSuiteNode($name: $passedCount/$totalCount passed, $failedCount failed)';
}

/// Relatório consolidado da árvore de testes (R05).
class TestTreeReport {
  const TestTreeReport({
    required this.toolName,
    required this.language,
    required this.suites,
    required this.totalDurationMs,
  });

  /// Ferramenta de teste executada (ex.: "dart test", "pytest", "cargo test", "vitest").
  final String toolName;

  /// Linguagem de programação correspondente.
  final String language;

  /// Lista de suites executadas.
  final List<TestSuiteNode> suites;

  /// Duração total acumulada em milissegundos.
  final int totalDurationMs;

  int get totalTests => suites.fold(0, (acc, s) => acc + s.totalCount);
  int get totalPassed => suites.fold(0, (acc, s) => acc + s.passedCount);
  int get totalFailed => suites.fold(0, (acc, s) => acc + s.failedCount);
  int get totalSkipped => suites.fold(0, (acc, s) => acc + s.skippedCount);

  /// Taxa de sucesso [0.0 - 1.0]. Retorna null se não houve testes executados.
  double? get passRate {
    final executable = totalPassed + totalFailed;
    if (executable == 0) return null;
    return totalPassed / executable;
  }

  /// Lista de todos os testes que falharam para fácil inspeção.
  List<TestCaseNode> get failedTests {
    final failures = <TestCaseNode>[];
    for (final suite in suites) {
      for (final test in suite.testCases) {
        if (test.isFailure) failures.add(test);
      }
    }
    return List.unmodifiable(failures);
  }

  /// Nomes dos testes com falha para reexecução filtrada.
  List<String> get failedTestNames => failedTests.map((t) => t.name).toList();

  Map<String, dynamic> toJson() => {
        'tool_name': toolName,
        'language': language,
        'total_duration_ms': totalDurationMs,
        'total_tests': totalTests,
        'total_passed': totalPassed,
        'total_failed': totalFailed,
        'total_skipped': totalSkipped,
        'pass_rate': passRate,
        'failed_test_names': failedTestNames,
        'suites': [for (final s in suites) s.toJson()],
      };

  @override
  String toString() =>
      'TestTreeReport($toolName: $totalPassed/$totalTests passed, $totalFailed failed)';
}

/// Status de cobertura de código para uma linha específica no gutter do editor (R05).
enum LineCoverageStatus {
  /// Linha de código executada pelo menos uma vez durante a bateria de testes.
  covered,

  /// Linha de código executável que NÃO foi executada pelos testes.
  uncovered,

  /// Linha não executável (comentário, linha vazia, assinatura abstrata).
  notExecutable,
}

/// Relatório de cobertura para um arquivo de código específico (R05).
class FileCoverageReport {
  const FileCoverageReport({
    required this.filePath,
    required this.lineStatuses,
    required this.linesFound,
    required this.linesHit,
  });

  /// Caminho do arquivo de código-fonte.
  final String filePath;

  /// Mapa de linha (base 1) para o status de cobertura.
  final Map<int, LineCoverageStatus> lineStatuses;

  /// Quantidade de linhas executáveis encontradas.
  final int linesFound;

  /// Quantidade de linhas executadas com sucesso.
  final int linesHit;

  /// Percentual de cobertura [0.0 - 100.0].
  ///
  /// Regra do Aceite: Se não há linhas testáveis, retorna `null` para NUNCA
  /// apresentar dado ausente falsamente como 0.0%!
  double? get coveragePercent {
    if (linesFound == 0) return null;
    return (linesHit / linesFound) * 100.0;
  }

  LineCoverageStatus statusForLine(int line) =>
      lineStatuses[line] ?? LineCoverageStatus.notExecutable;

  Map<String, dynamic> toJson() => {
        'file_path': filePath,
        'lines_found': linesFound,
        'lines_hit': linesHit,
        'coverage_percent': coveragePercent,
      };

  @override
  String toString() =>
      'FileCoverageReport($filePath: ${coveragePercent?.toStringAsFixed(1) ?? "N/A"}% '
      '[$linesHit/$linesFound])';
}

/// Relatório consolidado global de cobertura (formato LCOV) (R05).
class GlobalCoverageReport {
  const GlobalCoverageReport({
    required this.format,
    required this.toolName,
    required this.files,
    required this.totalLinesFound,
    required this.totalLinesHit,
  });

  /// Formato de entrada validado (ex.: "LCOV").
  final String format;

  /// Ferramenta que gerou o arquivo de cobertura (ex.: "flutter test --coverage", "vitest").
  final String toolName;

  /// Mapa de caminho relativo/normalizado para o relatório do arquivo.
  final Map<String, FileCoverageReport> files;

  /// Total acumulado de linhas testáveis no projeto.
  final int totalLinesFound;

  /// Total acumulado de linhas cobertas no projeto.
  final int totalLinesHit;

  /// Percentual global de cobertura do projeto [0.0 - 100.0].
  ///
  /// Regra do Aceite: Retorna `null` se ausente de dados, sem induzir ao falso zero.
  double? get globalCoveragePercent {
    if (totalLinesFound == 0) return null;
    return (totalLinesHit / totalLinesFound) * 100.0;
  }

  bool get hasCoverageData => totalLinesFound > 0;

  Map<String, dynamic> toJson() => {
        'format': format,
        'tool_name': toolName,
        'total_lines_found': totalLinesFound,
        'total_lines_hit': totalLinesHit,
        'global_coverage_percent': globalCoveragePercent,
        'file_count': files.length,
      };

  @override
  String toString() =>
      'GlobalCoverageReport($toolName: ${globalCoveragePercent?.toStringAsFixed(1) ?? "N/A"}% '
      'over ${files.length} files)';
}

/// Função ou método com alto consumo de tempo identificado no profiling (R05).
class ProfilerHotSpot {
  const ProfilerHotSpot({
    required this.functionName,
    this.location,
    required this.cpuTimeMs,
    required this.percentage,
    required this.hitCount,
  });

  final String functionName;
  final String? location;
  final double cpuTimeMs;
  final double percentage;
  final int hitCount;

  Map<String, dynamic> toJson() => {
        'function_name': functionName,
        if (location != null) 'location': location,
        'cpu_time_ms': cpuTimeMs,
        'percentage': percentage,
        'hit_count': hitCount,
      };

  @override
  String toString() =>
      'ProfilerHotSpot($functionName: ${cpuTimeMs.toStringAsFixed(1)}ms [${percentage.toStringAsFixed(1)}%])';
}

/// Relatório de profiling gerado estritamente sob demanda (R05).
class ProfilerReport {
  const ProfilerReport({
    required this.runtimeTool,
    required this.capturedAt,
    required this.duration,
    required this.totalCpuTimeMs,
    this.memoryRssMb,
    required this.hotSpots,
    this.isRealtime = false,
  });

  /// Identificação explícita da ferramenta/runtime (ex.: "Dart VM Service", "pyinstrument").
  final String runtimeTool;

  /// Timestamp da captura.
  final DateTime capturedAt;

  /// Duração do intervalo de amostragem de profiling.
  final Duration duration;

  /// Tempo total de CPU medido durante a amostragem.
  final double totalCpuTimeMs;

  /// Consumo de memória RSS em megabytes, caso reportado pelo profiler.
  final double? memoryRssMb;

  /// Lista ordenada de hotspots da CPU.
  final List<ProfilerHotSpot> hotSpots;

  /// Garantia formal de que o profiler é sob demanda e não contínuo em background.
  final bool isRealtime;

  Map<String, dynamic> toJson() => {
        'runtime_tool': runtimeTool,
        'captured_at': capturedAt.toIso8601String(),
        'duration_ms': duration.inMilliseconds,
        'total_cpu_time_ms': totalCpuTimeMs,
        if (memoryRssMb != null) 'memory_rss_mb': memoryRssMb,
        'is_realtime': isRealtime,
        'hot_spots': [for (final h in hotSpots) h.toJson()],
      };

  @override
  String toString() =>
      'ProfilerReport($runtimeTool: CPU=${totalCpuTimeMs.toStringAsFixed(1)}ms, '
      'RSS=${memoryRssMb?.toStringAsFixed(1) ?? "N/A"}MB, hotspots=${hotSpots.length})';
}
