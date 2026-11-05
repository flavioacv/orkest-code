import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

void main() {
  group('Harness Signal State & Precedence (H01)', () {
    test('separates presence, execution phase and waiting orthogonally', () {
      final coordinator = HarnessStateCoordinator();
      expect(coordinator.presence, HarnessPresence.none);
      expect(coordinator.phase, HarnessExecutionPhase.idle);
      expect(coordinator.snapshot.isPresent, isFalse);
      expect(coordinator.snapshot.isTurnActive, isFalse);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.idle);

      // Inicia execução via hook estruturado
      final signal = HarnessSignal(
        source: HarnessSignalSource.structuredHook,
        phase: HarnessExecutionPhase.running,
        timestamp: DateTime.now(),
        activityId: 'act-1',
        summary: 'Compiling code',
      );
      expect(coordinator.processSignal(signal), isTrue);

      expect(coordinator.presence, HarnessPresence.attached);
      expect(coordinator.phase, HarnessExecutionPhase.running);
      expect(coordinator.snapshot.isPresent, isTrue);
      expect(coordinator.snapshot.isTurnActive, isTrue);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.working);

      // Transiciona para espera humana de permissão
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.waitingInput,
          timestamp: DateTime.now(),
          activityId: 'act-1',
          summary: 'Waiting for permission',
        ),
      );
      expect(coordinator.phase, HarnessExecutionPhase.waitingInput);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.waiting);
      expect(coordinator.snapshot.isPresent, isTrue); // Permanece anexado!

      // Conclusão do turno preserva presença em ociosidade
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.completed,
          timestamp: DateTime.now(),
          activityId: 'act-1',
          summary: 'Done',
        ),
      );
      expect(coordinator.phase, HarnessExecutionPhase.completed);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.idle);
      expect(coordinator.snapshot.isPresent, isTrue); // Harness continua presente no prompt!
    });

    test('structured hook strictly supersedes screen observation during active work', () {
      final coordinator = HarnessStateCoordinator();

      // Hook estruturado reporta execução ativa
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.now(),
          activityId: 'heavy-task',
          summary: 'Executing heavy task',
        ),
      );

      // Observação de tela antiga ou residual reporta ocioso imediatamente após
      final screenSignal = HarnessSignal(
        source: HarnessSignalSource.screenObservation,
        phase: HarnessExecutionPhase.idle,
        timestamp: DateTime.now(),
        summary: 'Prompt text visible on screen',
      );

      // A observação de tela deve ser descartada por precedência inferior
      final accepted = coordinator.processSignal(screenSignal);
      expect(accepted, isFalse);
      expect(coordinator.phase, HarnessExecutionPhase.running);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.working);
    });

    test('discards stale signals from prior generations', () {
      final coordinator = HarnessStateCoordinator(initialGeneration: 2);

      // Sinal de uma geração anterior (geração 1)
      final staleSignal = HarnessSignal(
        source: HarnessSignalSource.screenObservation,
        phase: HarnessExecutionPhase.running,
        timestamp: DateTime.now(),
        generation: 1,
        summary: 'Ghost output from previous session',
      );

      expect(coordinator.processSignal(staleSignal), isFalse);
      expect(coordinator.phase, HarnessExecutionPhase.idle);
    });

    test('deduplicates completed activities and prevents re-triggering by screen redraws', () {
      final coordinator = HarnessStateCoordinator();

      // Atividade iniciada e completada
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.now(),
          activityId: 'deploy-job',
        ),
      );
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.completed,
          timestamp: DateTime.now(),
          activityId: 'deploy-job',
        ),
      );
      expect(coordinator.phase, HarnessExecutionPhase.completed);

      // Redraw de terminal repintando a linha do comando não reabre a atividade finalizada
      final redrawSignal = HarnessSignal(
        source: HarnessSignalSource.screenObservation,
        phase: HarnessExecutionPhase.running,
        timestamp: DateTime.now(),
        activityId: 'deploy-job',
      );

      expect(coordinator.processSignal(redrawSignal), isFalse);
      expect(coordinator.phase, HarnessExecutionPhase.completed);
    });

    test('producer names do not alter precedence behavior or state transitions', () {
      // Valida que produtores com identidades distintas operam com a mesma regra neutra
      for (final producer in ['claude', 'codex', 'gemini', 'anti-gravity', 'kimi', 'custom-agent']) {
        final coordinator = HarnessStateCoordinator();

        coordinator.processSignal(
          HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.running,
            timestamp: DateTime.now(),
            activityId: '$producer-run',
            summary: '$producer thinking',
          ),
        );
        expect(coordinator.phase, HarnessExecutionPhase.running);
        expect(coordinator.snapshot.terminalStatus, TerminalStatus.working);

        coordinator.processSignal(
          HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.waitingInput,
            timestamp: DateTime.now(),
            activityId: '$producer-run',
            summary: '$producer waiting approval',
          ),
        );
        expect(coordinator.phase, HarnessExecutionPhase.waitingInput);
        expect(coordinator.snapshot.terminalStatus, TerminalStatus.waiting);

        coordinator.processSignal(
          HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.completed,
            timestamp: DateTime.now(),
            activityId: '$producer-run',
            summary: '$producer turn completed',
          ),
        );
        expect(coordinator.phase, HarnessExecutionPhase.completed);
        expect(coordinator.snapshot.terminalStatus, TerminalStatus.idle);
        expect(coordinator.snapshot.isPresent, isTrue);
      }
    });

    test('explicit close signal transitions presence to detached', () {
      final coordinator = HarnessStateCoordinator();
      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.now(),
        ),
      );
      expect(coordinator.presence, HarnessPresence.attached);

      coordinator.processSignal(
        HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.closed,
          timestamp: DateTime.now(),
        ),
      );
      expect(coordinator.presence, HarnessPresence.detached);
      expect(coordinator.phase, HarnessExecutionPhase.closed);
      expect(coordinator.snapshot.isPresent, isFalse);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.idle);
    });
  });
}
