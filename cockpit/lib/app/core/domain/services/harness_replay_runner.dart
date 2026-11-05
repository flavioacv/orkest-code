import 'package:orkest_code/app/core/domain/entities/harness_replay_event.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

/// Relatório de execução determinística de um cenário de replay do harness.
class HarnessReplayReport {
  final String scenarioId;
  final int totalEvents;
  final int acceptedSignals;
  final int rejectedSignals;
  final List<HarnessReplayTransition> observedTransitions;
  final List<HarnessReplayTransition> expectedTransitions;
  final int flickerCount;
  final bool matchesExpected;
  final List<String> differences;

  const HarnessReplayReport({
    required this.scenarioId,
    required this.totalEvents,
    required this.acceptedSignals,
    required this.rejectedSignals,
    required this.observedTransitions,
    required this.expectedTransitions,
    required this.flickerCount,
    required this.matchesExpected,
    required this.differences,
  });

  @override
  String toString() {
    return 'HarnessReplayReport(scenario: $scenarioId, matches: $matchesExpected, '
        'transitions: ${observedTransitions.length}/${expectedTransitions.length}, '
        'flickers: $flickerCount, diffs: ${differences.length})';
  }
}

/// Executor determinístico que reproduz eventos de terminal e valida transições do harness.
class HarnessReplayRunner {
  final HarnessStateCoordinator coordinator;
  final List<HarnessReplayTransition> _observedTransitions = [];
  final List<int> _generationAtTransition = [];
  String _ansiCarryover = '';
  int _acceptedSignals = 0;
  int _rejectedSignals = 0;
  int _flickerCount = 0;

  HarnessReplayRunner({HarnessStateCoordinator? coordinator})
      : coordinator = coordinator ?? HarnessStateCoordinator() {
    // Registra o estado inicial como primeira transição
    _observedTransitions.add(
      HarnessReplayTransition.fromSnapshot(this.coordinator.snapshot),
    );
    _generationAtTransition.add(this.coordinator.generation);
  }

  /// Executa o cenário completo e retorna o relatório determinístico.
  HarnessReplayReport runScenario(HarnessReplayScenario scenario) {
    for (final event in scenario.events) {
      _processEvent(event);
    }

    final diffs = _computeDifferences(scenario.expectedTransitions);
    final matches = diffs.isEmpty;

    return HarnessReplayReport(
      scenarioId: scenario.id,
      totalEvents: scenario.events.length,
      acceptedSignals: _acceptedSignals,
      rejectedSignals: _rejectedSignals,
      observedTransitions: List.unmodifiable(_observedTransitions),
      expectedTransitions: scenario.expectedTransitions,
      flickerCount: _flickerCount,
      matchesExpected: matches,
      differences: diffs,
    );
  }

  void _processEvent(HarnessReplayEvent event) {
    switch (event.type) {
      case ReplayEventType.signal:
        if (event.signal != null) {
          _applySignal(event.signal!);
        }
        break;

      case ReplayEventType.ptyChunk:
        if (event.ptyData != null) {
          _processPtyChunk(event.ptyData!, event.offsetMs);
        }
        break;

      case ReplayEventType.userInput:
        final signal = HarnessSignal(
          source: HarnessSignalSource.userInput,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.fromMillisecondsSinceEpoch(event.offsetMs),
          summary: 'User keyboard interaction',
          generation: coordinator.generation,
        );
        _applySignal(signal);
        break;

      case ReplayEventType.reconnect:
        coordinator.advanceGeneration();
        // Em reconexão, confirma se houve sinal de rede ou se a geração foi incrementada
        if (event.signal != null) {
          _applySignal(event.signal!);
        }
        break;

      case ReplayEventType.processSnapshot:
        if (event.signal != null) {
          _applySignal(event.signal!);
        }
        break;
    }
  }

  void _applySignal(HarnessSignal signal) {
    final prevSnapshot = coordinator.snapshot;
    final accepted = coordinator.processSignal(signal);

    if (accepted) {
      _acceptedSignals++;
      final newSnapshot = coordinator.snapshot;
      if (prevSnapshot != newSnapshot) {
        _recordTransition(newSnapshot);
      }
    } else {
      _rejectedSignals++;
    }
  }

  void _recordTransition(HarnessStateSnapshot newSnapshot) {
    final transition = HarnessReplayTransition.fromSnapshot(newSnapshot);

    // Detecta flicker (queda espúria para idle no meio de working ou waiting)
    if (_observedTransitions.length >= 2) {
      final prev = _observedTransitions.last;
      final prevPrev = _observedTransitions[_observedTransitions.length - 2];
      final prevPrevGen =
          _generationAtTransition[_generationAtTransition.length - 2];
      final currGen = coordinator.generation;

      // Só avalia flicker se os eventos ocorreram na mesma geração de PTY
      if (prevPrevGen == currGen) {
        final isWorkingFlicker =
            prevPrev.terminalStatus == TerminalStatus.working &&
                prev.terminalStatus == TerminalStatus.idle &&
                transition.terminalStatus == TerminalStatus.working;
        final isWaitingFlicker =
            prevPrev.terminalStatus == TerminalStatus.waiting &&
                prev.terminalStatus == TerminalStatus.idle &&
                transition.terminalStatus == TerminalStatus.waiting;
        if (isWorkingFlicker || isWaitingFlicker) {
          _flickerCount++;
        }
      }
    }

    _observedTransitions.add(transition);
    _generationAtTransition.add(coordinator.generation);
  }

  /// Processa chunk PTY tratando ANSI fragmentado e sinais embutidos (OSC 133 ou marcadores).
  void _processPtyChunk(String chunk, int offsetMs) {
    final combined = _ansiCarryover + chunk;
    _ansiCarryover = '';

    // Verifica se há sequência de escape ANSI incompleta no final do chunk
    final lastEsc = combined.lastIndexOf('\x1b');
    String textToProcess = combined;

    if (lastEsc != -1) {
      final remainder = combined.substring(lastEsc);
      // Se não termina com terminador válido (m, H, J, etc.), guarda no carryover
      if (!_isCompleteAnsiSequence(remainder)) {
        textToProcess = combined.substring(0, lastEsc);
        _ansiCarryover = remainder;
      }
    }

    // Detecta marcadores de harness explícitos ou de prompt no PTY
    if (textToProcess.contains('\x1b]133;C') ||
        textToProcess.contains('orkest:activity:start')) {
      final signal = HarnessSignal(
        source: HarnessSignalSource.ptyMarker,
        phase: HarnessExecutionPhase.running,
        timestamp: DateTime.fromMillisecondsSinceEpoch(offsetMs),
        summary: 'PTY command start marker',
        generation: coordinator.generation,
      );
      _applySignal(signal);
    } else if (textToProcess.contains('\x1b]133;D') ||
        textToProcess.contains('orkest:activity:end')) {
      final signal = HarnessSignal(
        source: HarnessSignalSource.ptyMarker,
        phase: HarnessExecutionPhase.completed,
        timestamp: DateTime.fromMillisecondsSinceEpoch(offsetMs),
        summary: 'PTY command end marker',
        generation: coordinator.generation,
      );
      _applySignal(signal);
    } else if (textToProcess.contains('? [Y/n]') ||
        textToProcess.contains('Allow tool execution?')) {
      final signal = HarnessSignal(
        source: HarnessSignalSource.screenObservation,
        phase: HarnessExecutionPhase.waitingInput,
        timestamp: DateTime.fromMillisecondsSinceEpoch(offsetMs),
        summary: 'Confirmation prompt detected in PTY output',
        generation: coordinator.generation,
      );
      _applySignal(signal);
    }
  }

  bool _isCompleteAnsiSequence(String seq) {
    if (seq.length < 2) return false;
    final lastChar = seq[seq.length - 1];
    // Terminadores comuns de ANSI CSI / OSC
    return (lastChar.codeUnitAt(0) >= 0x40 && lastChar.codeUnitAt(0) <= 0x7E) ||
        lastChar == '\x07';
  }

  List<String> _computeDifferences(
      List<HarnessReplayTransition> expectedTransitions) {
    final diffs = <String>[];

    if (_observedTransitions.length != expectedTransitions.length) {
      diffs.add(
        'Length mismatch: observed ${_observedTransitions.length} transitions, '
        'expected ${expectedTransitions.length}.',
      );
    }

    final maxLen = _observedTransitions.length > expectedTransitions.length
        ? _observedTransitions.length
        : expectedTransitions.length;

    for (int i = 0; i < maxLen; i++) {
      if (i >= _observedTransitions.length) {
        diffs.add('Missing transition #$i: expected ${expectedTransitions[i]}');
      } else if (i >= expectedTransitions.length) {
        diffs.add('Unexpected extra transition #$i: observed ${_observedTransitions[i]}');
      } else {
        final obs = _observedTransitions[i];
        final exp = expectedTransitions[i];
        if (obs != exp) {
          diffs.add(
            'Mismatch at transition #$i:\n'
            '  Observed: $obs\n'
            '  Expected: $exp',
          );
        }
      }
    }

    return diffs;
  }
}
