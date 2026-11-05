import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness_replay_event.dart';
import 'package:orkest_code/app/core/domain/services/harness_replay_runner.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Harness Corpus & Deterministic Replay (H02)', () {
    late Directory corpusDir;
    late List<File> fixtureFiles;

    setUpAll(() {
      // Localiza diretório de fixtures sanitizadas
      final currentDir = Directory.current.path;
      final candidates = [
        p.join(currentDir, 'test', 'fixtures', 'harness'),
        p.join(currentDir, 'cockpit', 'test', 'fixtures', 'harness'),
      ];

      Directory? found;
      for (final candidate in candidates) {
        final dir = Directory(candidate);
        if (dir.existsSync()) {
          found = dir;
          break;
        }
      }

      expect(found, isNotNull,
          reason: 'Diretório fixtures/harness deve existir.');
      corpusDir = found!;

      fixtureFiles = corpusDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList()
        ..sort((a, b) => a.path.compareTo(b.path));

      expect(fixtureFiles.length, equals(8),
          reason:
              'O corpus deve conter exatamente as 8 fixtures obrigatórias sanitizadas.');
    });

    test('validates corpus fixtures have zero secrets or host leaks', () {
      final secretPatterns = [
        RegExp(r'sk-[a-zA-Z0-9_-]{20,}'),
        RegExp(r'ghp_[a-zA-Z0-9]{20,}'),
        RegExp(r'password["\s:=]+[a-zA-Z0-9_!@#$%^&*]+', caseSensitive: false),
        RegExp(r'/Users/[a-zA-Z0-9_]+'),
        RegExp(r'[a-zA-Z]:\\Users\\[a-zA-Z0-9_]+', caseSensitive: false),
      ];

      for (final file in fixtureFiles) {
        final content = file.readAsStringSync();
        for (final pattern in secretPatterns) {
          final match = pattern.firstMatch(content);
          expect(match, isNull,
              reason:
                  'Fixture ${file.path} contém possível vazamento ou segredo: ${match?.group(0)}');
        }
      }
    });

    test('replays 01_ansi_fragmented cleanly without buffer corruption', () {
      final file = fixtureFiles.firstWhere((f) => f.path.contains('01_ansi'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças encontradas: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 02_screen_redraw without resurrecting completed tasks', () {
      final file =
          fixtureFiles.firstWhere((f) => f.path.contains('02_screen_redraw'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
      // Garante que o redraw foi descartado (1 rejeição)
      expect(report.rejectedSignals, greaterThanOrEqualTo(1));
    });

    test('replays 03_repeated_prompts with zero superfluous transitions', () {
      final file = fixtureFiles
          .firstWhere((f) => f.path.contains('03_repeated_prompts'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 04_concurrent_permissions consolidating into waiting state', () {
      final file = fixtureFiles
          .firstWhere((f) => f.path.contains('04_concurrent_permissions'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 05_subagents tracking hierarchical lifecycle', () {
      final file =
          fixtureFiles.firstWhere((f) => f.path.contains('05_subagents'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 06_stop_session_end with detached termination', () {
      final file = fixtureFiles
          .firstWhere((f) => f.path.contains('06_stop_session_end'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 07_wsl_environment isolating Linux process boundaries', () {
      final file =
          fixtureFiles.firstWhere((f) => f.path.contains('07_wsl_environment'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.flickerCount, equals(0));
    });

    test('replays 08_session_reconnect rejecting stale generation output', () {
      final file = fixtureFiles
          .firstWhere((f) => f.path.contains('08_session_reconnect'));
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final scenario = HarnessReplayScenario.fromJson(json);

      final runner = HarnessReplayRunner();
      final report = runner.runScenario(scenario);

      expect(report.matchesExpected, isTrue,
          reason: 'Diferenças: ${report.differences.join("; ")}');
      expect(report.rejectedSignals, greaterThanOrEqualTo(1));
      expect(report.flickerCount, equals(0));
    });

    test('guarantees 100% deterministic reproducibility across multiple runs', () {
      for (final file in fixtureFiles) {
        final json =
            jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final scenario = HarnessReplayScenario.fromJson(json);

        final run1 = HarnessReplayRunner().runScenario(scenario);
        final run2 = HarnessReplayRunner().runScenario(scenario);

        expect(run1.matchesExpected, isTrue);
        expect(run2.matchesExpected, isTrue);
        expect(run1.observedTransitions, equals(run2.observedTransitions));
        expect(run1.acceptedSignals, equals(run2.acceptedSignals));
        expect(run1.rejectedSignals, equals(run2.rejectedSignals));
      }
    });
  });
}
