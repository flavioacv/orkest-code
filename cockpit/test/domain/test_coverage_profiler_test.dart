import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/test_coverage_profiler.dart';
import 'package:orkest_code/app/core/domain/services/test_coverage_profiler_service.dart';

void main() {
  group('TestTreeReport & Test Results Integration (R05)', () {
    test('parses Dart test runner JSON events with passing, failing and skipped tests', () {
      const jsonEvents = '''
{"protocolVersion":"0.1.1","runnerVersion":"1.24.0","pid":1234,"type":"start","time":0}
{"test":{"id":1,"name":"loading test/calculator_test.dart","suiteID":0,"groupIDs":[],"metadata":{"skip":false,"skipReason":null},"line":null,"column":null,"url":null},"type":"testStart","time":10}
{"testID":1,"result":"success","skipped":false,"hidden":true,"type":"testDone","time":50}
{"test":{"id":2,"name":"Calculator adds two numbers correctly","suiteID":0,"groupIDs":[1],"metadata":{"skip":false,"skipReason":null},"line":15,"column":5,"url":"test/calculator_test.dart"},"type":"testStart","time":60}
{"testID":2,"result":"success","skipped":false,"hidden":false,"type":"testDone","time":120}
{"test":{"id":3,"name":"Calculator divides by zero throws exception","suiteID":0,"groupIDs":[1],"metadata":{"skip":false,"skipReason":null},"line":25,"column":5,"url":"test/calculator_test.dart"},"type":"testStart","time":130}
{"testID":3,"error":"Expected exception IntegerDivisionByZeroException, but nothing was thrown","stackTrace":"package:test/src/expect.dart 42:5\\ntest/calculator_test.dart 27:7","isFailure":true,"type":"error","time":160}
{"testID":3,"result":"failure","skipped":false,"hidden":false,"type":"testDone","time":180}
{"test":{"id":4,"name":"Calculator experimental feature","suiteID":0,"groupIDs":[1],"metadata":{"skip":true,"skipReason":"Feature not ready"},"line":35,"column":5,"url":"test/calculator_test.dart"},"type":"testStart","time":190}
{"testID":4,"result":"success","skipped":true,"hidden":false,"type":"testDone","time":200}
{"success":false,"type":"done","time":250}
''';

      final report = TestCoverageProfilerService.parseDartTestJson(jsonEvents);

      expect(report.toolName, equals('dart test'));
      expect(report.language, equals('dart'));
      expect(report.totalTests, equals(3)); // Exclui o teste interno "loading ..."
      expect(report.totalPassed, equals(1));
      expect(report.totalFailed, equals(1));
      expect(report.totalSkipped, equals(1));

      // Suite agregada
      expect(report.suites.length, equals(1));
      final suite = report.suites.first;
      expect(suite.name, equals('test/calculator_test.dart'));
      expect(suite.hasFailures, isTrue);
      expect(suite.failedCount, equals(1));

      // Teste com falha e captura de erro
      final failed = report.failedTests;
      expect(failed.length, equals(1));
      expect(failed[0].name, equals('Calculator divides by zero throws exception'));
      expect(failed[0].errorMessage, contains('IntegerDivisionByZeroException'));
      expect(failed[0].stackTrace, contains('test/calculator_test.dart 27:7'));
      expect(failed[0].lineNumber, equals(25));
    });

    test('builds rerun failed command filtering only failing test names', () {
      const jsonEvents = '''
{"test":{"id":1,"name":"Test A passing","url":"test/a_test.dart"},"type":"testStart","time":10}
{"testID":1,"result":"success","skipped":false,"type":"testDone","time":20}
{"test":{"id":2,"name":"Test B failing","url":"test/a_test.dart"},"type":"testStart","time":30}
{"testID":2,"error":"Failed expectation","stackTrace":"","type":"error","time":40}
{"testID":2,"result":"failure","skipped":false,"type":"testDone","time":50}
''';

      final report = TestCoverageProfilerService.parseDartTestJson(jsonEvents);
      expect(report.failedTestNames, equals(['Test B failing']));

      final rerunCmd = TestCoverageProfilerService.buildRerunFailedCommand(
        report: report,
        testExecutable: 'puro flutter test',
      );

      expect(rerunCmd, equals('puro flutter test --name "(Test B failing)"'));
    });
  });

  group('LCOV Coverage & Gutter Integration (R05)', () {
    test('parses LCOV content accurately and maps line coverage status', () {
      const lcovContent = '''
TN:
SF:lib/src/math.dart
DA:10,1
DA:11,1
DA:12,0
DA:15,3
LF:4
LH:3
end_of_record
SF:lib/src/empty.dart
LF:0
LH:0
end_of_record
''';

      final globalCoverage = TestCoverageProfilerService.parseLcov(lcovContent);

      expect(globalCoverage.format, equals('LCOV'));
      expect(globalCoverage.totalLinesFound, equals(4));
      expect(globalCoverage.totalLinesHit, equals(3));
      expect(globalCoverage.globalCoveragePercent, equals(75.0));

      final mathCoverage = globalCoverage.files['lib/src/math.dart'];
      expect(mathCoverage, isNotNull);
      expect(mathCoverage!.linesFound, equals(4));
      expect(mathCoverage.linesHit, equals(3));
      expect(mathCoverage.coveragePercent, equals(75.0));

      // Mapeamento para o gutter do editor
      expect(mathCoverage.statusForLine(10), equals(LineCoverageStatus.covered));
      expect(mathCoverage.statusForLine(11), equals(LineCoverageStatus.covered));
      expect(mathCoverage.statusForLine(12), equals(LineCoverageStatus.uncovered));
      expect(mathCoverage.statusForLine(15), equals(LineCoverageStatus.covered));
      expect(mathCoverage.statusForLine(99), equals(LineCoverageStatus.notExecutable));
    });

    test('mandatory acceptance: missing coverage data is NEVER presented as zero', () {
      // Arquivo sem linhas executáveis testáveis
      const lcovContent = '''
SF:lib/src/declarations_only.dart
LF:0
LH:0
end_of_record
''';

      final report = TestCoverageProfilerService.parseLcov(lcovContent);
      final fileReport = report.files['lib/src/declarations_only.dart'];

      expect(fileReport, isNotNull);
      expect(fileReport!.linesFound, equals(0));
      // Regra de aceite inegociável: dado ausente deve ser null, NUNCA 0.0%
      expect(fileReport.coveragePercent, isNull);
      expect(report.globalCoveragePercent, isNull);
    });
  });

  group('On-Demand Profiler (R05)', () {
    test('parses on-demand profiler output with hotspots and memory RSS', () {
      const profilerOutput = '''
# Profiling capture summary
Total Samples: 1540
Duration: 4.8s

Function                                      CPU Time    Percentage  Location
---------------------------------------------------------------------------------
WidgetTree.layoutChildren                      350.2ms     42.5%      rendering.dart:120
ImageDecoder.parsePngBuffer                    180.5ms     21.8%      codec.dart:45
JsonCodec.decodeBigPayload                      95.0ms     11.5%      json.dart:88
''';

      final report = TestCoverageProfilerService.parseProfilerOutput(
        profilerOutput,
        runtimeTool: 'Dart VM Service',
        duration: const Duration(milliseconds: 4800),
        memoryRssMb: 128.5,
      );

      expect(report.runtimeTool, equals('Dart VM Service'));
      expect(report.isRealtime, isFalse); // Estritamente sob demanda
      expect(report.memoryRssMb, equals(128.5));
      expect(report.hotSpots.length, equals(3));

      expect(report.hotSpots[0].functionName, equals('WidgetTree.layoutChildren'));
      expect(report.hotSpots[0].cpuTimeMs, equals(350.2));
      expect(report.hotSpots[0].percentage, equals(42.5));
      expect(report.hotSpots[0].location, equals('rendering.dart:120'));

      expect(report.hotSpots[1].functionName, equals('ImageDecoder.parsePngBuffer'));
      expect(report.hotSpots[2].functionName, equals('JsonCodec.decodeBigPayload'));
    });
  });
}
