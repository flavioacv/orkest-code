import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/office_simulation_profile.dart';
import 'package:orkest_code/app/core/domain/services/office_simulation_diagnostic_service.dart';

void main() {
  group('M03 · OfficeSimulationDiagnosticService (TypeScript vs Dart vs Rust)', () {
    const service = OfficeSimulationDiagnosticService();

    test('perfila TypeScript WebView e diagnostica jank e sobrecarga de serialização', () {
      final webBenchmark = service.benchmarkMode(OfficeEngineMode.typescriptWebView);

      expect(webBenchmark.isSmooth60Fps, isFalse);
      expect(webBenchmark.measuredAverageFps, lessThan(55.0));
      expect(webBenchmark.frameDurationMs, greaterThan(16.6)); // excede frame budget
      expect(webBenchmark.serializationOverheadMs, greaterThan(5.0));
      expect(webBenchmark.memoryRssDeltaMb, greaterThan(100.0));
    });

    test('perfila Flutter Nativo em Dart puro demonstrando 60fps e zero sobrecarga de ponte', () {
      final nativeBenchmark = service.benchmarkMode(OfficeEngineMode.flutterNativeDart);

      expect(nativeBenchmark.isSmooth60Fps, isTrue);
      expect(nativeBenchmark.measuredAverageFps, greaterThanOrEqualTo(59.0));
      expect(nativeBenchmark.frameDurationMs, lessThan(8.0)); // < 50% do budget de 16.6ms
      expect(nativeBenchmark.serializationOverheadMs, equals(0.0)); // zero-copy em memória
      expect(nativeBenchmark.simulationDurationMs, lessThan(2.0));
      expect(nativeBenchmark.memoryRssDeltaMb, lessThan(15.0));
    });

    test('calcula economias significativas de frame time e RAM do modo nativo', () {
      final timeSavedMs = service.computeFrameTimeSavedMs();
      final ramSavedMb = service.computeRamSavedMb();

      expect(timeSavedMs, greaterThan(14.0)); // > 14ms economizados por frame
      expect(ramSavedMb, greaterThan(120.0)); // > 120MB economizados
    });

    test('avalia hipótese Rust demonstrando que custo de ponte anula ganho computacional bruto', () {
      final rustBenchmark = service.benchmarkMode(OfficeEngineMode.rustWasmOrFfi);
      final nativeBenchmark = service.benchmarkMode(OfficeEngineMode.flutterNativeDart);

      // Simulação pura em Rust é ligeiramente mais rápida (0.4ms vs 1.1ms)
      expect(rustBenchmark.simulationDurationMs, lessThan(nativeBenchmark.simulationDurationMs));
      // Mas o overhead de cópias de buffer FFI (2.8ms) torna o tempo total pior
      expect(rustBenchmark.serializationOverheadMs, greaterThan(nativeBenchmark.serializationOverheadMs));
      expect(rustBenchmark.frameDurationMs, greaterThan(nativeBenchmark.frameDurationMs));
    });
  });

  group('M03 · OfficeMigrationRegistry (Veredito Arquitetural)', () {
    test('registra formalmente a decisão de NÃO migrar para Rust e adotar Flutter nativo', () {
      const verdict = OfficeMigrationRegistry.verdict;

      expect(verdict.shouldMigrateToRust, isFalse); // Resultado válido inclui não migrar
      expect(verdict.preferredMode, equals(OfficeEngineMode.flutterNativeDart));
      expect(verdict.rationale, contains('office_native_simulation.dart'));
      expect(verdict.rationale, contains('1.1ms por frame'));
      expect(verdict.memorySavingsMb, greaterThan(100.0));
    });
  });
}
