import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/diff_merge_comparison.dart';
import 'package:orkest_code/app/core/domain/services/diff_merge_comparison_service.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';

void main() {
  group('M01 · MyersDiffAlgorithm (Dart Pure vs Rust)', () {
    const algorithm = MyersDiffAlgorithm();

    test('calcula diff simples com adições, remoções e contexto', () {
      const a = 'linha 1\nlinha 2\nlinha 3';
      const b = 'linha 1\nlinha 2 alterada\nlinha 3\nlinha 4 nova';

      final diff = algorithm.computeLineDiff(a, b);

      expect(diff, isNotEmpty);
      expect(diff.any((d) => d.kind == DiffLineKind.context && d.text == 'linha 1'), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.removed && d.text == 'linha 2'), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.added && d.text == 'linha 2 alterada'), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.context && d.text == 'linha 3'), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.added && d.text == 'linha 4 nova'), isTrue);
    });

    test('normaliza quebras de linha Windows CRLF (\r\n) e preserva paridade', () {
      const a = 'primeira\r\nsegunda\r\n';
      const b = 'primeira\nsegunda\nterceira\n';

      final diff = algorithm.computeLineDiff(a, b);

      expect(diff.where((d) => d.kind == DiffLineKind.context).length, equals(2));
      expect(diff.where((d) => d.kind == DiffLineKind.added).length, equals(1));
      expect(diff.last.text, equals('terceira'));
    });

    test('trata caracteres compostos UTF-16 (surrogate pairs / emojis) sem corromper offsets', () {
      const a = 'config: 🚀 foguete\nstatus: ativo\n';
      const b = 'config: 🚀 foguete\nstatus: pausado ⏸️\n';

      final diff = algorithm.computeLineDiff(a, b);

      expect(diff.any((d) => d.kind == DiffLineKind.context && d.text.contains('🚀')), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.removed && d.text.contains('ativo')), isTrue);
      expect(diff.any((d) => d.kind == DiffLineKind.added && d.text.contains('⏸️')), isTrue);
    });

    test('retorna lista vazia para strings vazias', () {
      final diff = algorithm.computeLineDiff('', '');
      expect(diff, isEmpty);
    });
  });

  group('M01 · MergeDiff3Algorithm (Resolução de 3 vias)', () {
    const mergeAlgo = MergeDiff3Algorithm();

    test('reconcilia sem conflito quando somente ours altera a linha', () {
      const base = 'linha original 1\nlinha original 2';
      const ours = 'linha modificada por mim\nlinha original 2';
      const theirs = 'linha original 1\nlinha original 2';

      final result = mergeAlgo.merge(baseText: base, oursText: ours, theirsText: theirs);

      expect(result.hasConflicts, isFalse);
      expect(result.conflictCount, equals(0));
      expect(result.mergedText, equals('linha modificada por mim\nlinha original 2'));
    });

    test('reconcilia sem conflito quando somente theirs altera a linha', () {
      const base = 'linha 1\nlinha 2';
      const ours = 'linha 1\nlinha 2';
      const theirs = 'linha 1\nlinha 2 alterada por colega';

      final result = mergeAlgo.merge(baseText: base, oursText: ours, theirsText: theirs);

      expect(result.hasConflicts, isFalse);
      expect(result.conflictCount, equals(0));
      expect(result.mergedText, equals('linha 1\nlinha 2 alterada por colega'));
    });

    test('reconcilia convergência idêntica sem conflito quando ambos aplicam a mesma mudança', () {
      const base = 'linha 1';
      const ours = 'linha 1 com correcao';
      const theirs = 'linha 1 com correcao';

      final result = mergeAlgo.merge(baseText: base, oursText: ours, theirsText: theirs);

      expect(result.hasConflicts, isFalse);
      expect(result.conflictCount, equals(0));
      expect(result.mergedText, equals('linha 1 com correcao'));
    });

    test('gera marcadores de conflito explícitos quando há modificações concorrentes divergentes', () {
      const base = 'linha comum 1\nlinha de conflito\nlinha comum 3';
      const ours = 'linha comum 1\nversao do usuario local\nlinha comum 3';
      const theirs = 'linha comum 1\nversao remota do servidor\nlinha comum 3';

      final result = mergeAlgo.merge(baseText: base, oursText: ours, theirsText: theirs);

      expect(result.hasConflicts, isTrue);
      expect(result.conflictCount, equals(1));
      expect(result.mergedText, contains('<<<<<<< ours'));
      expect(result.mergedText, contains('versao do usuario local'));
      expect(result.mergedText, contains('======='));
      expect(result.mergedText, contains('versao remota do servidor'));
      expect(result.mergedText, contains('>>>>>>> theirs'));
    });
  });

  group('M01 · AlgorithmDecisionRegistry & Benchmark Metrics', () {
    test('contém decisões arquiteturais documentadas para todos os tipos principais de diff', () {
      final verdicts = AlgorithmDecisionRegistry.verdicts;
      expect(verdicts, isNotEmpty);

      final myersVerdict = verdicts.firstWhere((v) => v.algorithm == DiffAlgorithmKind.myersLineDiff);
      expect(myersVerdict.chosenImplementation, contains('Dart Pure'));
      expect(myersVerdict.rationale, contains('isolate Dart puro'));
      expect(myersVerdict.measuredSpeedupOrPenalty, contains('penalidade'));

      final mergeVerdict = verdicts.firstWhere((v) => v.algorithm == DiffAlgorithmKind.mergeDiff3ThreeWay);
      expect(mergeVerdict.chosenImplementation, contains('Dart Pure'));

      final wordVerdict = verdicts.firstWhere((v) => v.algorithm == DiffAlgorithmKind.wordDiff);
      expect(wordVerdict.rationale, contains('UTF-16'));
    });

    test('calcula custo total efetivo computação + overhead de IPC em AlgorithmBenchmarkSample', () {
      const sample = AlgorithmBenchmarkSample(
        algorithm: DiffAlgorithmKind.myersLineDiff,
        implementationTarget: 'Rust (IPC via stdio)',
        encodingCase: TextEncodingCase.utf16SurrogatePairs,
        corpusLines: 10000,
        executionTimeMs: 1.2,
        memoryRssDeltaMb: 4.8,
        ipcTransferOverheadMs: 4.5,
        isOutputIdentical: true,
      );

      expect(sample.totalElapsedMs, closeTo(5.7, 0.001));
      expect(sample.ipcTransferOverheadMs, greaterThan(sample.executionTimeMs));
    });
  });
}
