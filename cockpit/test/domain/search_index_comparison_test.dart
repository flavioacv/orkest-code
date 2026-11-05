import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/search_index_comparison.dart';
import 'package:orkest_code/app/core/domain/services/search_index_comparison_service.dart';

void main() {
  group('M02 · SearchIndexComparisonService (Dart Pure vs Rust)', () {
    const service = SearchIndexComparisonService();

    test('detecta arquivos binários por presença de byte nulo (0x00)', () {
      final textBytes = 'import "package:flutter/material.dart";\nvoid main() {}'.codeUnits;
      expect(service.isBinaryPayload(textBytes), isFalse);

      final pngHeader = [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00];
      expect(service.isBinaryPayload(pngHeader), isTrue);

      final emptyBytes = <int>[];
      expect(service.isBinaryPayload(emptyBytes), isFalse);
    });

    test('reconhece pastas de build, cache e controle de versão a serem ignoradas', () {
      expect(service.isDirectoryIgnored('node_modules'), isTrue);
      expect(service.isDirectoryIgnored('build'), isTrue);
      expect(service.isDirectoryIgnored('.dart_tool'), isTrue);
      expect(service.isDirectoryIgnored('.git'), isTrue);
      expect(service.isDirectoryIgnored('target'), isTrue);
      expect(service.isDirectoryIgnored('venv'), isTrue);
      expect(service.isDirectoryIgnored('lib'), isFalse);
      expect(service.isDirectoryIgnored('src'), isFalse);
    });

    test('mede latência superior de cancelamento para processos externos frente a Isolate', () {
      final dartCancel = service.estimateCancelLatencyMs(SearchEngineKind.dartPureIsolate);
      final rustProcessCancel = service.estimateCancelLatencyMs(SearchEngineKind.rustRipgrepProcess);
      final rustFfiCancel = service.estimateCancelLatencyMs(SearchEngineKind.rustFfiNative);

      expect(dartCancel, lessThan(1.0));
      expect(rustProcessCancel, greaterThan(20.0));
      expect(rustFfiCancel, greaterThan(10.0));
      expect(rustProcessCancel, greaterThan(dartCancel * 20));
    });

    test('avalia perfis operacionais e calcula taxa de arquivos por segundo', () {
      final sample = service.evaluateEngineProfile(
        engine: SearchEngineKind.dartPureIsolate,
        dimension: SearchComparisonDimension.cancelResponsiveness,
        corpusFiles: 10000,
      );

      expect(sample.totalFilesScanned, equals(10000));
      expect(sample.leftoverZombieProcesses, equals(0));
      expect(sample.filesPerSecond, greaterThan(50000.0));
      expect(sample.peakRssDeltaMb, lessThan(10.0));
    });
  });

  group('M02 · SearchDecisionRegistry (Decisões de Produção)', () {
    test('contém vereditos fundamentados para busca de arquivo, conteúdo e símbolos', () {
      final verdicts = SearchDecisionRegistry.verdicts;
      expect(verdicts.length, equals(3));

      final fileSearchVerdict = verdicts.firstWhere((v) => v.subsystem.contains('FileSearcher'));
      expect(fileSearchVerdict.chosenEngine, equals(SearchEngineKind.dartPureIsolate));
      expect(fileSearchVerdict.measuredLatencyMs, lessThan(5.0));

      final contentSearchVerdict = verdicts.firstWhere((v) => v.subsystem.contains('ContentSearcher'));
      expect(contentSearchVerdict.chosenEngine, equals(SearchEngineKind.dartPureIsolate));
      expect(contentSearchVerdict.cancelGuarantee, contains('Isolate.kill imediato'));

      final symbolVerdict = verdicts.firstWhere((v) => v.subsystem.contains('SymbolIndex'));
      expect(symbolVerdict.chosenEngine, equals(SearchEngineKind.dartPureIsolate));
      expect(symbolVerdict.rationale, contains('LSP'));
    });
  });
}
