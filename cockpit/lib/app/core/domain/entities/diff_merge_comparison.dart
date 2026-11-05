/// Tipo de algoritmo de diff e merge avaliado na migração (M01).
enum DiffAlgorithmKind {
  myersLineDiff,
  wordDiff,
  charDiff,
  mergeDiff3ThreeWay,
}

/// Casos adversos de codificação e terminação de linha testados no corpus (M01).
enum TextEncodingCase {
  asciiUtf8,
  utf16SurrogatePairs, // Caracteres compostos (ex: emojis, símbolos matemáticos)
  crlfWindows, // \r\n
  lfUnix, // \n
  mixedEol, // Mistura de CRLF e LF no mesmo arquivo
}

/// Chunk de merge de três vias resultante de `mergeDiff3` (M01).
class Merge3Chunk {
  const Merge3Chunk({
    required this.isConflict,
    required this.baseLines,
    required this.oursLines,
    required this.theirsLines,
    this.resolvedLines,
  });

  final bool isConflict;
  final List<String> baseLines;
  final List<String> oursLines;
  final List<String> theirsLines;
  final List<String>? resolvedLines;

  List<String> get effectiveLines {
    if (resolvedLines != null) return resolvedLines!;
    if (!isConflict) {
      if (oursLines.isNotEmpty) return oursLines;
      return theirsLines;
    }
    return [
      '<<<<<<< ours',
      ...oursLines,
      '=======',
      ...theirsLines,
      '>>>>>>> theirs',
    ];
  }
}

/// Resultado consolidado de uma operação de merge de 3 vias (M01).
class Merge3Result {
  const Merge3Result({
    required this.chunks,
    required this.hasConflicts,
    required this.conflictCount,
    required this.mergedText,
  });

  final List<Merge3Chunk> chunks;
  final bool hasConflicts;
  final int conflictCount;
  final String mergedText;
}

/// Amostra de benchmark comparativo entre implementações (M01).
class AlgorithmBenchmarkSample {
  const AlgorithmBenchmarkSample({
    required this.algorithm,
    required this.implementationTarget, // 'TypeScript (Node)', 'Rust (IPC/FFI)', 'Dart Pure (Isolate)'
    required this.encodingCase,
    required this.corpusLines,
    required this.executionTimeMs,
    required this.memoryRssDeltaMb,
    required this.ipcTransferOverheadMs,
    required this.isOutputIdentical,
  });

  final DiffAlgorithmKind algorithm;
  final String implementationTarget;
  final TextEncodingCase encodingCase;
  final int corpusLines;
  final double executionTimeMs;
  final double memoryRssDeltaMb;
  final double ipcTransferOverheadMs;
  final bool isOutputIdentical;

  /// Custo total efetivo (computação + sobrecarga de transporte).
  double get totalElapsedMs => executionTimeMs + ipcTransferOverheadMs;
}

/// Veredito arquitetural e decisão técnica algoritmo a algoritmo (M01).
class AlgorithmDecisionVerdict {
  const AlgorithmDecisionVerdict({
    required this.algorithm,
    required this.chosenImplementation,
    required this.rationale,
    required this.recommendation,
    required this.measuredSpeedupOrPenalty,
  });

  final DiffAlgorithmKind algorithm;
  final String chosenImplementation;
  final String rationale;
  final String recommendation;
  final String measuredSpeedupOrPenalty;
}
