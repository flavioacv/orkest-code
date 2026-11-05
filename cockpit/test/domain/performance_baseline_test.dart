import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/performance_baseline.dart';
import 'package:orkest_code/app/core/domain/services/performance_baseline_service.dart';

void main() {
  const service = PerformanceBaselineService();

  group('PerformanceBaselineService Math & Percentiles (A02)', () {
    test('calculates accurate p50, p95 and max from latency distribution', () {
      final samples = [10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0, 80.0, 90.0, 100.0];

      final p50 = PerformanceBaselineService.calculatePercentile(samples, 0.50);
      expect(p50, equals(55.0));

      final p95 = PerformanceBaselineService.calculatePercentile(samples, 0.95);
      expect(p95, equals(95.5));

      final p0 = PerformanceBaselineService.calculatePercentile(samples, 0.0);
      expect(p0, equals(10.0));

      final p100 = PerformanceBaselineService.calculatePercentile(samples, 1.0);
      expect(p100, equals(100.0));
    });

    test('builds baseline measurement aggregating resources and cancel latency', () {
      final measurement = service.buildMeasurement(
        operationId: 'fileIndex',
        runtimeTarget: 'Dart (Isolate VFS)',
        corpusScale: CorpusScale.large,
        cacheState: CacheState.cold,
        latencySamplesMs: [180.0, 190.0, 200.0, 210.0, 220.0],
        memoryRssMb: 195.0,
        cpuPercent: 42.0,
        jankFramesCount: 1,
        cancelLatencyMs: 4.5,
        ipcBytesTransferred: 1048576,
      );

      expect(measurement.operationId, equals('fileIndex'));
      expect(measurement.p50Ms, equals(200.0));
      expect(measurement.maxMs, equals(220.0));
      expect(measurement.memoryRssMb, equals(195.0));
      expect(measurement.cancelLatencyMs, equals(4.5));
      expect(measurement.ipcBytesTransferred, equals(1048576));
    });
  });

  group('PerformanceBaselineReport Requirements & ADR (A02)', () {
    test('enforces zero rust gain presumption and contains all mandatory scales and cache states', () {
      final report = service.generateStandardReport(
        hardwareOverride: const HostHardwareProfile(
          architecture: 'arm64',
          cpuCores: 8,
          totalMemoryMb: 16384,
          osPlatform: 'macos',
          osRelease: 'Darwin 24.3.0',
        ),
      );

      expect(report.hardware.architecture, equals('arm64'));
      expect(report.hardware.cpuCores, equals(8));
      expect(report.runtimeVersions.containsKey('dartSdk'), isTrue);

      // Requisito inegociável do aceite: nenhum ganho de Rust presumido
      expect(report.rustGainPresumed, isFalse);

      // Cobertura de Corpus: Pequeno e Grande
      final small = report.byScale(CorpusScale.small);
      final large = report.byScale(CorpusScale.large);
      expect(small, isNotEmpty);
      expect(large, isNotEmpty);

      // Cobertura de Estados: Cold e Warm
      final hasCold = report.measurements.any((m) => m.cacheState == CacheState.cold);
      final hasWarm = report.measurements.any((m) => m.cacheState == CacheState.warm);
      expect(hasCold, isTrue);
      expect(hasWarm, isTrue);

      // Comparações de Operações Reais
      expect(report.byOperation('fileIndex'), isNotEmpty);
      expect(report.byOperation('diff3Merge'), isNotEmpty);
      expect(report.byOperation('textSearch'), isNotEmpty);
    });

    test('measures IPC bridge penalty demonstrating serialization overhead', () {
      final report = service.generateStandardReport();

      final dartDiff = report.measurements.firstWhere(
        (m) => m.operationId == 'diff3Merge' && m.runtimeTarget.contains('Dart'),
      );
      final rustBridgeDiff = report.measurements.firstWhere(
        (m) => m.operationId == 'diff3Merge' && m.runtimeTarget.contains('Rust Native over IPC'),
      );

      final penaltyRatio = service.computeBridgePenaltyRatio(
        nativeMeasurement: dartDiff,
        bridgeMeasurement: rustBridgeDiff,
      );

      // Demonstra que a ponte IPC introduz overhead e maior consumo de memória RSS
      expect(penaltyRatio, greaterThan(1.0));
      expect(rustBridgeDiff.memoryRssMb, greaterThan(dartDiff.memoryRssMb));
      expect(rustBridgeDiff.ipcBytesTransferred, greaterThan(0));
    });
  });
}
