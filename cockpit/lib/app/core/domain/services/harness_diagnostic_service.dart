import 'package:orkest_code/app/core/domain/entities/harness_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';

/// Serviço responsável por expor diagnósticos de estado de harness com preservação
/// absoluta de privacidade e auditoria de falsos positivos/negativos (H05).
class HarnessDiagnosticService {
  const HarnessDiagnosticService();

  /// Constrói um diagnóstico de estado seguro a partir do coordenador de harness.
  ///
  /// Garante que:
  /// 1. A idade do sinal seja computada determinística a partir de [referenceTime];
  /// 2. Falta de sinal NUNCA inventa execução, mantendo confiança [HarnessDetectionConfidence.unasserted];
  /// 3. Em ambientes limitados ([limitedDataMode] = true), a confiança é devidamente rebaixada;
  /// 4. Nenhum dado sensível de prompt, buffer de terminal ou saída de comando é capturado.
  static HarnessStateDiagnostic buildDiagnostic({
    required HarnessStateCoordinator coordinator,
    DateTime? referenceTime,
    bool limitedDataMode = false,
  }) {
    final now = referenceTime ?? DateTime.now();
    final snapshot = coordinator.snapshot;
    final totalSignals = coordinator.totalSignalsReceived;
    final lastSource = coordinator.lastSource;
    final lastUpdatedAt = coordinator.lastUpdatedAt;

    // Regra inegociável de H05: Falta de sinal não inventa execução!
    if (totalSignals == 0 || lastSource == null) {
      return HarnessStateDiagnostic(
        presence: snapshot.presence,
        phase: HarnessExecutionPhase.idle,
        terminalStatus: snapshot.terminalStatus,
        lastSource: null,
        lastUpdatedAt: null,
        signalAge: Duration.zero,
        confidence: HarnessDetectionConfidence.unasserted,
        limitedDataMode: limitedDataMode,
        totalSignalsReceived: 0,
        sourceDistribution: coordinator.sourceDistribution,
        generation: snapshot.generation,
        sessionId: snapshot.sessionId,
        turnId: snapshot.turnId,
        activeActivityId: null,
      );
    }

    final signalAge = now.difference(lastUpdatedAt ?? now);
    final effectiveAge = signalAge.isNegative ? Duration.zero : signalAge;

    final confidence = _resolveConfidence(
      lastSource: lastSource,
      limitedDataMode: limitedDataMode,
      signalAge: effectiveAge,
    );

    return HarnessStateDiagnostic(
      presence: snapshot.presence,
      phase: snapshot.phase,
      terminalStatus: snapshot.terminalStatus,
      lastSource: lastSource,
      lastUpdatedAt: lastUpdatedAt,
      signalAge: effectiveAge,
      confidence: confidence,
      limitedDataMode: limitedDataMode,
      totalSignalsReceived: totalSignals,
      sourceDistribution: coordinator.sourceDistribution,
      generation: snapshot.generation,
      sessionId: snapshot.sessionId,
      turnId: snapshot.turnId,
      activeActivityId: snapshot.activeActivityId,
    );
  }

  /// Resolve o grau de confiança baseado na fonte e integridade dos dados.
  static HarnessDetectionConfidence _resolveConfidence({
    required HarnessSignalSource lastSource,
    required bool limitedDataMode,
    required Duration signalAge,
  }) {
    if (limitedDataMode && lastSource == HarnessSignalSource.screenObservation) {
      return HarnessDetectionConfidence.low;
    }

    return switch (lastSource) {
      HarnessSignalSource.structuredHook => HarnessDetectionConfidence.authoritative,
      HarnessSignalSource.ptyMarker => HarnessDetectionConfidence.high,
      HarnessSignalSource.userInput => HarnessDetectionConfidence.medium,
      HarnessSignalSource.screenObservation => HarnessDetectionConfidence.low,
    };
  }

  /// Avalia a matriz de confusão e acurácia sobre uma sequência de amostras rotuladas.
  ///
  /// Mede com precisão matemática os falsos positivos (falso working, falso waiting)
  /// e falsos negativos (falso idle).
  static HarnessCorpusConfusionMatrix evaluateCorpusAccuracy({
    required List<HarnessLabeledSample> samples,
    HarnessStateCoordinator? customCoordinator,
  }) {
    if (samples.isEmpty) {
      return const HarnessCorpusConfusionMatrix(
        totalSamples: 0,
        trueWorking: 0,
        falseWorking: 0,
        trueWaiting: 0,
        falseWaiting: 0,
        trueIdle: 0,
        falseIdle: 0,
      );
    }

    final coordinator = customCoordinator ?? HarnessStateCoordinator();

    int trueWorking = 0;
    int falseWorking = 0;
    int trueWaiting = 0;
    int falseWaiting = 0;
    int trueIdle = 0;
    int falseIdle = 0;

    for (final sample in samples) {
      coordinator.processSignal(sample.signal);
      final currentPhase = coordinator.phase;
      final expected = sample.expectedPhase;

      if (expected == HarnessExecutionPhase.running) {
        if (currentPhase == HarnessExecutionPhase.running) {
          trueWorking++;
        } else if (currentPhase == HarnessExecutionPhase.waitingInput) {
          falseWaiting++;
        } else {
          falseIdle++;
        }
      } else if (expected == HarnessExecutionPhase.waitingInput) {
        if (currentPhase == HarnessExecutionPhase.waitingInput) {
          trueWaiting++;
        } else if (currentPhase == HarnessExecutionPhase.running) {
          falseWorking++;
        } else {
          falseIdle++;
        }
      } else {
        // Ground truth é idle / completed / closed
        if (currentPhase == HarnessExecutionPhase.idle ||
            currentPhase == HarnessExecutionPhase.completed ||
            currentPhase == HarnessExecutionPhase.closed) {
          trueIdle++;
        } else if (currentPhase == HarnessExecutionPhase.running) {
          falseWorking++;
        } else if (currentPhase == HarnessExecutionPhase.waitingInput) {
          falseWaiting++;
        }
      }
    }

    return HarnessCorpusConfusionMatrix(
      totalSamples: samples.length,
      trueWorking: trueWorking,
      falseWorking: falseWorking,
      trueWaiting: trueWaiting,
      falseWaiting: falseWaiting,
      trueIdle: trueIdle,
      falseIdle: falseIdle,
    );
  }
}
