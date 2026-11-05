import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_diagnostic_service.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

void main() {
  group('HarnessDiagnosticService (H05)', () {
    test('lack of signal NEVER invents execution and stays unasserted idle', () {
      final coordinator = HarnessStateCoordinator();

      // Sem nenhum sinal emitido
      final diagnostic = coordinator.getDiagnostic(
        referenceTime: DateTime.fromMillisecondsSinceEpoch(10000),
      );

      // Deve estar estritamente idle, unasserted, sem fonte e com zero sinais
      expect(diagnostic.phase, equals(HarnessExecutionPhase.idle));
      expect(diagnostic.terminalStatus, equals(TerminalStatus.idle));
      expect(diagnostic.confidence, equals(HarnessDetectionConfidence.unasserted));
      expect(diagnostic.lastSource, isNull);
      expect(diagnostic.lastUpdatedAt, isNull);
      expect(diagnostic.totalSignalsReceived, equals(0));
      expect(diagnostic.activeActivityId, isNull);
      expect(diagnostic.signalAge, equals(Duration.zero));
    });

    test('exposes last state source and calculates signal age accurately', () {
      final coordinator = HarnessStateCoordinator();
      final signalTime = DateTime.fromMillisecondsSinceEpoch(1000);
      final checkTime = DateTime.fromMillisecondsSinceEpoch(3500);

      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.ptyMarker,
          phase: HarnessExecutionPhase.running,
          timestamp: signalTime,
          activityId: 'pty-cmd-1',
        ),
      );

      final diagnostic = coordinator.getDiagnostic(referenceTime: checkTime);

      expect(diagnostic.lastSource, equals(HarnessSignalSource.ptyMarker));
      expect(diagnostic.phase, equals(HarnessExecutionPhase.running));
      expect(diagnostic.terminalStatus, equals(TerminalStatus.working));
      expect(diagnostic.lastUpdatedAt, equals(signalTime));
      expect(diagnostic.signalAge, equals(const Duration(milliseconds: 2500)));
      expect(diagnostic.confidence, equals(HarnessDetectionConfidence.high));
      expect(diagnostic.totalSignalsReceived, equals(1));
      expect(diagnostic.sourceDistribution[HarnessSignalSource.ptyMarker], equals(1));
    });

    test('derives correct confidence level based on source hierarchy', () {
      final baseTime = DateTime.fromMillisecondsSinceEpoch(1000);

      // 1. structuredHook -> authoritative
      final coord1 = HarnessStateCoordinator();
      coord1.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: baseTime,
        ),
      );
      expect(
        coord1.getDiagnostic(referenceTime: baseTime).confidence,
        equals(HarnessDetectionConfidence.authoritative),
      );

      // 2. ptyMarker -> high
      final coord2 = HarnessStateCoordinator();
      coord2.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.ptyMarker,
          phase: HarnessExecutionPhase.running,
          timestamp: baseTime,
        ),
      );
      expect(
        coord2.getDiagnostic(referenceTime: baseTime).confidence,
        equals(HarnessDetectionConfidence.high),
      );

      // 3. userInput -> medium
      final coord3 = HarnessStateCoordinator();
      coord3.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.userInput,
          phase: HarnessExecutionPhase.running,
          timestamp: baseTime,
        ),
      );
      expect(
        coord3.getDiagnostic(referenceTime: baseTime).confidence,
        equals(HarnessDetectionConfidence.medium),
      );

      // 4. screenObservation -> low
      final coord4 = HarnessStateCoordinator();
      coord4.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.screenObservation,
          phase: HarnessExecutionPhase.running,
          timestamp: baseTime,
        ),
      );
      expect(
        coord4.getDiagnostic(referenceTime: baseTime).confidence,
        equals(HarnessDetectionConfidence.low),
      );
    });

    test('exposes limitedDataMode flag and handles degraded environments safely', () {
      final coordinator = HarnessStateCoordinator();
      final time = DateTime.fromMillisecondsSinceEpoch(5000);

      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.screenObservation,
          phase: HarnessExecutionPhase.waitingInput,
          timestamp: time,
        ),
      );

      final diagnostic = coordinator.getDiagnostic(
        referenceTime: time,
        limitedDataMode: true,
      );

      expect(diagnostic.limitedDataMode, isTrue);
      expect(diagnostic.confidence, equals(HarnessDetectionConfidence.low));
      expect(diagnostic.phase, equals(HarnessExecutionPhase.waitingInput));
      expect(diagnostic.terminalStatus, equals(TerminalStatus.waiting));
    });

    test('strict privacy enforcement: telemetry map contains zero sensitive content', () {
      final coordinator = HarnessStateCoordinator();
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.fromMillisecondsSinceEpoch(1000),
          activityId: 'secret-task-id',
          summary: 'SECRET: rm -rf /my/private/keys && token=xyz123',
          sessionId: 'session-priv-1',
          turnId: 'turn-99',
        ),
      );

      final diagnostic = coordinator.getDiagnostic(
        referenceTime: DateTime.fromMillisecondsSinceEpoch(1500),
      );

      final telemetry = diagnostic.toTelemetryMap();

      // Metadados seguros e anônimos devem existir
      expect(telemetry['presence'], equals('attached'));
      expect(telemetry['phase'], equals('running'));
      expect(telemetry['terminal_status'], equals('working'));
      expect(telemetry['last_source'], equals('structuredHook'));
      expect(telemetry['signal_age_ms'], equals(500));
      expect(telemetry['confidence'], equals('authoritative'));
      expect(telemetry['total_signals_received'], equals(1));
      expect(telemetry['has_active_activity'], isTrue);

      // NENHUM campo de buffer sensível, prompt, texto de comando ou token pode existir
      expect(telemetry.containsKey('summary'), isFalse);
      expect(telemetry.containsKey('prompt'), isFalse);
      expect(telemetry.containsKey('output'), isFalse);
      expect(telemetry.containsKey('text'), isFalse);
      expect(telemetry.containsKey('buffer'), isFalse);
      expect(telemetry.containsKey('secret'), isFalse);
      expect(telemetry.toString().contains('SECRET'), isFalse);
      expect(telemetry.toString().contains('xyz123'), isFalse);
    });

    test('evaluates labeled corpus confusion matrix with precise false working/waiting/idle rates', () {
      final base = DateTime.fromMillisecondsSinceEpoch(1000);

      final samples = <HarnessLabeledSample>[
        // Amostra 1: Working real e detectado como working (trueWorking)
        HarnessLabeledSample(
          name: 'claude tool execution',
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.running,
            timestamp: base,
            activityId: 'act-1',
          ),
          expectedPhase: HarnessExecutionPhase.running,
        ),
        // Amostra 2: Conclusão do turno -> Ground truth idle, detectado idle (trueIdle)
        HarnessLabeledSample(
          name: 'claude stop completion',
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.completed,
            timestamp: base.add(const Duration(milliseconds: 500)),
            activityId: 'act-1',
          ),
          expectedPhase: HarnessExecutionPhase.idle,
        ),
        // Amostra 3: Prompt de autorização -> Ground truth waiting, detectado waiting (trueWaiting)
        HarnessLabeledSample(
          name: 'permission prompt',
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.waitingInput,
            timestamp: base.add(const Duration(milliseconds: 1000)),
            activityId: 'act-perm-1',
          ),
          expectedPhase: HarnessExecutionPhase.waitingInput,
        ),
        // Amostra 4: Ruído de tela heurístico que reporta idle prematuramente enquanto o ground truth era waiting
        // (falso idle)
        HarnessLabeledSample(
          name: 'screen redraw noise during permission',
          signal: HarnessSignal(
            source: HarnessSignalSource.screenObservation,
            phase: HarnessExecutionPhase.idle,
            timestamp: base.add(const Duration(milliseconds: 6500)), // > 5s para contornar guard de precedência
          ),
          expectedPhase: HarnessExecutionPhase.waitingInput,
        ),
      ];

      final matrix = HarnessDiagnosticService.evaluateCorpusAccuracy(
        samples: samples,
      );

      expect(matrix.totalSamples, equals(4));
      expect(matrix.trueWorking, equals(1));
      expect(matrix.trueIdle, equals(1));
      expect(matrix.trueWaiting, equals(1));
      expect(matrix.falseIdle, equals(1));
      expect(matrix.falseWorking, equals(0));
      expect(matrix.falseWaiting, equals(0));

      expect(matrix.accuracyRate, equals(0.75)); // 3 / 4 = 75%
      expect(matrix.falseWorkingRate, equals(0.0));
      expect(matrix.falseIdleRate, equals(0.25));

      final json = matrix.toJson();
      expect(json['accuracy_rate'], equals(0.75));
      expect(json['false_working'], equals(0));
    });
  });
}
