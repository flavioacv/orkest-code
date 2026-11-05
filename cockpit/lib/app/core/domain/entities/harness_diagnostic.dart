import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart' show TerminalStatus;

/// Grau de confiança e certeza na detecção do estado atual do harness (H05).
enum HarnessDetectionConfidence {
  /// Nenhum sinal registrado ou ausência de monitor de processo (shell puro).
  ///
  /// Garante deterministicamente que falta de sinal NUNCA inventa execução.
  unasserted,

  /// Heurística fraca baseada estritamente em observação de tela/buffer (screenObservation).
  low,

  /// Entrada física do usuário recente no terminal (userInput).
  medium,

  /// Marcadores determinísticos de protocolo de terminal (PTY / OSC 133).
  high,

  /// Sinais estruturados verificados via socket/IPC (structuredHook / activity).
  authoritative,
}

/// Diagnóstico de estado do harness exposto sem reter ou capturar conteúdo sensível (H05).
///
/// Atende às regras estritas de privacidade: nenhum buffer de texto do terminal,
/// prompt de usuário, código-fonte ou saída de comando é persistido ou serializado.
class HarnessStateDiagnostic {
  const HarnessStateDiagnostic({
    required this.presence,
    required this.phase,
    required this.terminalStatus,
    required this.lastSource,
    required this.lastUpdatedAt,
    required this.signalAge,
    required this.confidence,
    required this.limitedDataMode,
    required this.totalSignalsReceived,
    required this.sourceDistribution,
    required this.generation,
    this.sessionId,
    this.turnId,
    this.activeActivityId,
  });

  /// Presença atual do harness no terminal.
  final HarnessPresence presence;

  /// Fase formal do ciclo de vida da execução.
  final HarnessExecutionPhase phase;

  /// Status legado mapeado para o Orkest.
  final TerminalStatus terminalStatus;

  /// Origem do último sinal recebido (`null` se nenhum sinal foi emitido).
  final HarnessSignalSource? lastSource;

  /// Timestamp do último sinal recebido (`null` se nenhum sinal foi emitido).
  final DateTime? lastUpdatedAt;

  /// Idade do sinal em relação ao momento da consulta diagnóstica.
  final Duration signalAge;

  /// Grau de confiança na detecção atual.
  final HarnessDetectionConfidence confidence;

  /// Indica se a detecção está operando em modo degradado com dados limitados
  /// (ex.: ambiente sem suporte a hooks estruturados ou sem marcadores PTY).
  final bool limitedDataMode;

  /// Total acumulado de sinais válidos recebidos na sessão.
  final int totalSignalsReceived;

  /// Distribuição de sinais recebidos por fonte.
  final Map<HarnessSignalSource, int> sourceDistribution;

  /// Geração da sessão do PTY.
  final int generation;

  /// Identificador opcional da sessão ativa.
  final String? sessionId;

  /// Identificador opcional do turno ativo.
  final String? turnId;

  /// Identificador opcional da atividade corrente em andamento.
  final String? activeActivityId;

  /// Exportação segura para telemetria sem expor conteúdo, prompts ou buffers de tela.
  Map<String, dynamic> toTelemetryMap() => {
        'presence': presence.name,
        'phase': phase.name,
        'terminal_status': terminalStatus.name,
        'last_source': lastSource?.name,
        'signal_age_ms': signalAge.inMilliseconds,
        'confidence': confidence.name,
        'limited_data_mode': limitedDataMode,
        'total_signals_received': totalSignalsReceived,
        'source_distribution': {
          for (final entry in sourceDistribution.entries)
            entry.key.name: entry.value,
        },
        'generation': generation,
        'has_active_activity': activeActivityId != null,
      };

  @override
  String toString() =>
      'HarnessStateDiagnostic(status: ${terminalStatus.name}, '
      'source: ${lastSource?.name ?? "none"}, '
      'age: ${signalAge.inMilliseconds}ms, '
      'confidence: ${confidence.name}, '
      'signals: $totalSignalsReceived, '
      'limitedData: $limitedDataMode)';
}

/// Amostra rotulada de corpus para validação de matriz de confusão (H05).
class HarnessLabeledSample {
  const HarnessLabeledSample({
    required this.name,
    required this.signal,
    required this.expectedPhase,
    this.notes,
  });

  final String name;
  final HarnessSignal signal;
  final HarnessExecutionPhase expectedPhase;
  final String? notes;
}

/// Matriz de confusão e métricas de acurácia sobre corpus rotulado (H05).
class HarnessCorpusConfusionMatrix {
  const HarnessCorpusConfusionMatrix({
    required this.totalSamples,
    required this.trueWorking,
    required this.falseWorking,
    required this.trueWaiting,
    required this.falseWaiting,
    required this.trueIdle,
    required this.falseIdle,
  });

  final int totalSamples;
  final int trueWorking;
  final int falseWorking;
  final int trueWaiting;
  final int falseWaiting;
  final int trueIdle;
  final int falseIdle;

  /// Taxa global de acurácia da detecção [0.0 - 1.0].
  double get accuracyRate {
    if (totalSamples == 0) return 1.0;
    final correct = trueWorking + trueWaiting + trueIdle;
    return correct / totalSamples;
  }

  /// Taxa de falsos working (detectado working quando ground truth era idle ou waiting).
  double get falseWorkingRate {
    if (totalSamples == 0) return 0.0;
    return falseWorking / totalSamples;
  }

  /// Taxa de falsos waiting (detectado waiting quando ground truth era working ou idle).
  double get falseWaitingRate {
    if (totalSamples == 0) return 0.0;
    return falseWaiting / totalSamples;
  }

  /// Taxa de falsos idle (detectado idle quando ground truth era working ou waiting).
  double get falseIdleRate {
    if (totalSamples == 0) return 0.0;
    return falseIdle / totalSamples;
  }

  Map<String, dynamic> toJson() => {
        'total_samples': totalSamples,
        'true_working': trueWorking,
        'false_working': falseWorking,
        'true_waiting': trueWaiting,
        'false_waiting': falseWaiting,
        'true_idle': trueIdle,
        'false_idle': falseIdle,
        'accuracy_rate': accuracyRate,
        'false_working_rate': falseWorkingRate,
        'false_waiting_rate': falseWaitingRate,
        'false_idle_rate': falseIdleRate,
      };

  @override
  String toString() =>
      'HarnessCorpusConfusionMatrix(samples: $totalSamples, '
      'accuracy: ${(accuracyRate * 100).toStringAsFixed(1)}%, '
      'falseWorking: $falseWorking, '
      'falseWaiting: $falseWaiting, '
      'falseIdle: $falseIdle)';
}
