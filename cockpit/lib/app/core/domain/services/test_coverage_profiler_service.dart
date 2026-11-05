import 'dart:convert';
import 'package:orkest_code/app/core/domain/entities/test_coverage_profiler.dart';

/// Serviço responsável pelo parsing, agregação e consulta de resultados de testes,
/// cobertura de código em LCOV e profiling sob demanda (R05).
class TestCoverageProfilerService {
  const TestCoverageProfilerService._();

  /// Decodifica o output JSON do executor de testes do Dart/Flutter (`--reporter json`).
  static TestTreeReport parseDartTestJson(
    String jsonLines, {
    String toolName = 'dart test',
    String language = 'dart',
  }) {
    final lines = jsonLines.split('\n');
    final activeTests = <int, _DartTestEntry>{};
    final completedTests = <TestCaseNode>[];
    int totalDuration = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || !trimmed.startsWith('{')) continue;

      try {
        final map = jsonDecode(trimmed) as Map<String, dynamic>;
        final type = map['type'] as String?;

        if (type == 'testStart') {
          final testMap = map['test'] as Map<String, dynamic>?;
          if (testMap != null) {
            final testId = (testMap['id'] as num?)?.toInt() ?? 0;
            final name = testMap['name'] as String? ?? 'Unnamed test';
            final url = testMap['url'] as String?;
            final lineNum = (testMap['line'] as num?)?.toInt();

            activeTests[testId] = _DartTestEntry(
              id: testId.toString(),
              name: name,
              startTime: (map['time'] as num?)?.toInt() ?? 0,
              filePath: url,
              lineNumber: lineNum,
            );
          }
        } else if (type == 'error') {
          final testId = (map['testID'] as num?)?.toInt();
          if (testId != null && activeTests.containsKey(testId)) {
            final entry = activeTests[testId]!;
            final error = map['error'] as String?;
            final stack = map['stackTrace'] as String?;
            entry.errorMessage = error;
            entry.stackTrace = stack;
          }
        } else if (type == 'testDone') {
          final testId = (map['testID'] as num?)?.toInt();
          if (testId != null && activeTests.containsKey(testId)) {
            final entry = activeTests[testId]!;
            final endTime = (map['time'] as num?)?.toInt() ?? 0;
            final duration = endTime >= entry.startTime ? endTime - entry.startTime : 0;
            totalDuration += duration;

            final result = map['result'] as String?;
            final isSkipped = (map['skipped'] as bool?) ?? false;

            final status = isSkipped
                ? TestStatus.skipped
                : (result == 'success' ? TestStatus.passed : TestStatus.failed);

            // Filtra testes de inicialização/carregamento internos do runner ('loading ...')
            if (!entry.name.startsWith('loading ')) {
              completedTests.add(
                TestCaseNode(
                  id: entry.id,
                  name: entry.name,
                  status: status,
                  durationMs: duration,
                  errorMessage: entry.errorMessage,
                  stackTrace: entry.stackTrace,
                  filePath: entry.filePath,
                  lineNumber: entry.lineNumber,
                ),
              );
            }
          }
        }
      } catch (_) {
        // Ignora linhas que não sejam JSON válido
      }
    }

    // Agrupa por arquivo ou cria suite única consolidada
    final suiteMap = <String, List<TestCaseNode>>{};
    for (final test in completedTests) {
      final suiteKey = test.filePath ?? 'Default Suite';
      suiteMap.putIfAbsent(suiteKey, () => []).add(test);
    }

    final suites = <TestSuiteNode>[];
    for (final entry in suiteMap.entries) {
      final suiteDuration = entry.value.fold(0, (acc, t) => acc + t.durationMs);
      suites.add(
        TestSuiteNode(
          name: entry.key,
          testCases: entry.value,
          durationMs: suiteDuration,
          filePath: entry.key != 'Default Suite' ? entry.key : null,
        ),
      );
    }

    return TestTreeReport(
      toolName: toolName,
      language: language,
      suites: List.unmodifiable(suites),
      totalDurationMs: totalDuration,
    );
  }

  /// Decodifica conteúdo estruturado no formato LCOV (`lcov.info`).
  ///
  /// Mapeia deterministicamente linhas executadas (`DA:line,hit`),
  /// contagens totais (`LF`, `LH`) e respeita a regra mandatória de que
  /// arquivos sem linhas executáveis retornam `coveragePercent == null`.
  static GlobalCoverageReport parseLcov(
    String lcovContent, {
    String toolName = 'flutter test --coverage',
  }) {
    final lines = lcovContent.split('\n');
    final fileReports = <String, FileCoverageReport>{};

    String? currentFile;
    final lineStatuses = <int, LineCoverageStatus>{};
    int linesFound = 0;
    int linesHit = 0;

    int globalLinesFound = 0;
    int globalLinesHit = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      if (trimmed.startsWith('SF:')) {
        currentFile = trimmed.substring(3).trim();
        lineStatuses.clear();
        linesFound = 0;
        linesHit = 0;
      } else if (trimmed.startsWith('DA:')) {
        final daParts = trimmed.substring(3).split(',');
        if (daParts.length >= 2) {
          final lineNum = int.tryParse(daParts[0].trim());
          final count = int.tryParse(daParts[1].trim());
          if (lineNum != null && count != null) {
            final isHit = count > 0;
            lineStatuses[lineNum] =
                isHit ? LineCoverageStatus.covered : LineCoverageStatus.uncovered;
          }
        }
      } else if (trimmed.startsWith('LF:')) {
        linesFound = int.tryParse(trimmed.substring(3).trim()) ?? lineStatuses.length;
      } else if (trimmed.startsWith('LH:')) {
        linesHit = int.tryParse(trimmed.substring(3).trim()) ??
            lineStatuses.values.where((s) => s == LineCoverageStatus.covered).length;
      } else if (trimmed == 'end_of_record') {
        if (currentFile != null) {
          // Se LF/LH não vieram explícitos, deriva dos DA coletados
          if (linesFound == 0 && lineStatuses.isNotEmpty) {
            linesFound = lineStatuses.length;
            linesHit = lineStatuses.values
                .where((s) => s == LineCoverageStatus.covered)
                .length;
          }

          fileReports[currentFile] = FileCoverageReport(
            filePath: currentFile,
            lineStatuses: Map.unmodifiable(Map.of(lineStatuses)),
            linesFound: linesFound,
            linesHit: linesHit,
          );

          globalLinesFound += linesFound;
          globalLinesHit += linesHit;
        }
        currentFile = null;
      }
    }

    return GlobalCoverageReport(
      format: 'LCOV',
      toolName: toolName,
      files: Map.unmodifiable(fileReports),
      totalLinesFound: globalLinesFound,
      totalLinesHit: globalLinesHit,
    );
  }

  /// Decodifica output textual de profilers sob demanda extraindo hotspots de CPU e memória.
  static ProfilerReport parseProfilerOutput(
    String rawText, {
    required String runtimeTool,
    DateTime? capturedAt,
    Duration? duration,
    double? memoryRssMb,
  }) {
    final lines = rawText.split('\n');
    final hotSpots = <ProfilerHotSpot>[];
    double totalCpuTime = 0.0;

    // Parser flexível para tabelas de profiling (formato tempo, porcentagem, símbolo)
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty ||
          trimmed.startsWith('#') ||
          trimmed.startsWith('---') ||
          trimmed.startsWith('Function') ||
          trimmed.startsWith('CPU Time')) {
        continue;
      }

      // Procura por colunas separadas por múltiplos espaços ou tabulações
      final parts = trimmed.split(RegExp(r'\s{2,}|\t+'));
      if (parts.length >= 3) {
        // Caso A: Function [0], Time [1], Percentage [2], Location? [3]
        final caseATime = RegExp(r'([\d\.]+)\s*(?:ms|s)').firstMatch(parts[1]);
        final caseAPct = RegExp(r'([\d\.]+)\s*%').firstMatch(parts[2]);
        if (caseATime != null && caseAPct != null) {
          double timeMs = double.tryParse(caseATime.group(1) ?? '') ?? 0.0;
          if (parts[1].contains('s') && !parts[1].contains('ms')) {
            timeMs *= 1000.0;
          }
          final percent = double.tryParse(caseAPct.group(1) ?? '') ?? 0.0;
          final functionName = parts[0].trim();
          final location = parts.length > 3 ? parts[3].trim() : null;

          totalCpuTime += timeMs;
          hotSpots.add(
            ProfilerHotSpot(
              functionName: functionName,
              location: location,
              cpuTimeMs: timeMs,
              percentage: percent,
              hitCount: 1,
            ),
          );
          continue;
        }

        // Caso B: Time [0], Percentage [1], Function [2], Location? [3]
        final caseBTime = RegExp(r'([\d\.]+)\s*(?:ms|s)').firstMatch(parts[0]);
        final caseBPct = RegExp(r'([\d\.]+)\s*%').firstMatch(parts[1]);
        if (caseBTime != null && caseBPct != null) {
          double timeMs = double.tryParse(caseBTime.group(1) ?? '') ?? 0.0;
          if (parts[0].contains('s') && !parts[0].contains('ms')) {
            timeMs *= 1000.0;
          }
          final percent = double.tryParse(caseBPct.group(1) ?? '') ?? 0.0;
          final functionName = parts[2].trim();
          final location = parts.length > 3 ? parts[3].trim() : null;

          totalCpuTime += timeMs;
          hotSpots.add(
            ProfilerHotSpot(
              functionName: functionName,
              location: location,
              cpuTimeMs: timeMs,
              percentage: percent,
              hitCount: 1,
            ),
          );
          continue;
        }
      }
    }

    // Se não encontrou formato tabular, parseia linha simples com regex
    if (hotSpots.isEmpty) {
      final simpleRegex = RegExp(
        r'([\w\.:]+)\s+([\d\.]+)\s*ms\s+\(?([\d\.]+)\s*%\)?',
      );
      for (final line in lines) {
        final match = simpleRegex.firstMatch(line.trim());
        if (match != null) {
          final func = match.group(1) ?? 'unknown';
          final time = double.tryParse(match.group(2) ?? '') ?? 0.0;
          final pct = double.tryParse(match.group(3) ?? '') ?? 0.0;
          totalCpuTime += time;
          hotSpots.add(
            ProfilerHotSpot(
              functionName: func,
              cpuTimeMs: time,
              percentage: pct,
              hitCount: 1,
            ),
          );
        }
      }
    }

    return ProfilerReport(
      runtimeTool: runtimeTool,
      capturedAt: capturedAt ?? DateTime.now(),
      duration: duration ?? const Duration(seconds: 5),
      totalCpuTimeMs: totalCpuTime,
      memoryRssMb: memoryRssMb,
      hotSpots: List.unmodifiable(hotSpots),
      isRealtime: false, // Garantia de que é estritamente sob demanda
    );
  }

  /// Retorna o comando sugerido para reexecução filtrada apenas dos testes com falha.
  static String buildRerunFailedCommand({
    required TestTreeReport report,
    required String testExecutable,
  }) {
    final failedNames = report.failedTestNames;
    if (failedNames.isEmpty) return testExecutable;

    if (report.language == 'dart') {
      final pattern = failedNames.map(RegExp.escape).join('|');
      return '$testExecutable --name "($pattern)"';
    } else if (report.language == 'python') {
      final pattern = failedNames.join(' or ');
      return '$testExecutable -k "$pattern"';
    } else if (report.language == 'rust') {
      final pattern = failedNames.first;
      return '$testExecutable $pattern';
    }

    return testExecutable;
  }
}

class _DartTestEntry {
  _DartTestEntry({
    required this.id,
    required this.name,
    required this.startTime,
    this.filePath,
    this.lineNumber,
  });

  final String id;
  final String name;
  final int startTime;
  final String? filePath;
  final int? lineNumber;
  String? errorMessage;
  String? stackTrace;
}
