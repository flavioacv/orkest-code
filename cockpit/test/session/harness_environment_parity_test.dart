import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_environment_parity.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';

void main() {
  group('Harness Environment Parity & Transport Integrity (H04)', () {
    test('identical event sequences produce identical states across Local, SSH and WSL', () {
      final environments = [
        HarnessEnvironmentType.local,
        HarnessEnvironmentType.sshRemote,
        HarnessEnvironmentType.wsl,
      ];

      final snapshots = <HarnessEnvironmentType, List<HarnessStateSnapshot>>{};

      for (final env in environments) {
        final coordinator = HarnessStateCoordinator();
        final context = HarnessEnvironmentContext(
          type: env,
          hostOrDistroId: env == HarnessEnvironmentType.wsl
              ? 'Ubuntu-22.04'
              : (env == HarnessEnvironmentType.sshRemote ? 'remote-srv' : 'localhost'),
        );

        final envSnapshots = <HarnessStateSnapshot>[];

        // 1. Sinal de início de comando
        HarnessEnvironmentParity.processSignal(
          coordinator: coordinator,
          context: context,
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.running,
            timestamp: DateTime.fromMillisecondsSinceEpoch(100),
            activityId: 'task-parity-1',
            summary: 'Running build',
          ),
        );
        envSnapshots.add(coordinator.snapshot);

        // 2. Sinal de solicitação de permissão humana
        HarnessEnvironmentParity.processSignal(
          coordinator: coordinator,
          context: context,
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.waitingInput,
            timestamp: DateTime.fromMillisecondsSinceEpoch(200),
            activityId: 'task-parity-1',
            summary: 'Allow file modification? [Y/n]',
          ),
        );
        envSnapshots.add(coordinator.snapshot);

        // 3. Resposta de usuário
        HarnessEnvironmentParity.processSignal(
          coordinator: coordinator,
          context: context,
          signal: HarnessSignal(
            source: HarnessSignalSource.userInput,
            phase: HarnessExecutionPhase.running,
            timestamp: DateTime.fromMillisecondsSinceEpoch(300),
            activityId: 'task-parity-1',
            summary: 'User confirmed',
          ),
        );
        envSnapshots.add(coordinator.snapshot);

        // 4. Conclusão
        HarnessEnvironmentParity.processSignal(
          coordinator: coordinator,
          context: context,
          signal: HarnessSignal(
            source: HarnessSignalSource.structuredHook,
            phase: HarnessExecutionPhase.completed,
            timestamp: DateTime.fromMillisecondsSinceEpoch(400),
            activityId: 'task-parity-1',
            summary: 'Build succeeded',
          ),
        );
        envSnapshots.add(coordinator.snapshot);

        snapshots[env] = envSnapshots;
      }

      final localList = snapshots[HarnessEnvironmentType.local]!;
      final sshList = snapshots[HarnessEnvironmentType.sshRemote]!;
      final wslList = snapshots[HarnessEnvironmentType.wsl]!;

      expect(sshList, equals(localList),
          reason: 'SSH remote execution must be 100% identical to local execution.');
      expect(wslList, equals(localList),
          reason: 'WSL execution must be 100% identical to local execution.');
    });

    test('disconnection never masquerades as completion or approval', () {
      final coordinator = HarnessStateCoordinator();
      final context = const HarnessEnvironmentContext(
        type: HarnessEnvironmentType.sshRemote,
        hostOrDistroId: 'server-prod',
      );

      // Coloca a sessão em espera de permissão
      HarnessEnvironmentParity.processSignal(
        coordinator: coordinator,
        context: context,
        signal: HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.waitingInput,
          timestamp: DateTime.now(),
          activityId: 'critical-deploy',
          summary: 'Approve production deploy? [Y/n]',
        ),
      );

      expect(coordinator.phase, HarnessExecutionPhase.waitingInput);
      expect(coordinator.snapshot.terminalStatus, TerminalStatus.waiting);

      // Queda repentina do transporte de rede (SSH drop / PTY crash)
      final afterDisconnect = HarnessEnvironmentParity.handleDisconnection(
        coordinator: coordinator,
        context: context,
        reason: 'SSH pipe broken (connection reset by peer)',
      );

      // A desconexão NUNCA pode resultar em completed ou waiting
      expect(afterDisconnect.presence, HarnessPresence.detached);
      expect(afterDisconnect.phase, HarnessExecutionPhase.closed);
      expect(afterDisconnect.terminalStatus, TerminalStatus.idle);
      expect(afterDisconnect.isTurnActive, isFalse);
      expect(afterDisconnect.isPresent, isFalse);
      expect(afterDisconnect.lastSummary,
          contains('SSH pipe broken (connection reset by peer)'));
    });

    test('reconnection advances generation and rejects stale output from prior generation', () {
      final coordinator = HarnessStateCoordinator(initialGeneration: 0);
      var context = const HarnessEnvironmentContext(
        type: HarnessEnvironmentType.sshRemote,
        hostOrDistroId: 'remote-host-1',
        generation: 0,
      );

      // Tarefa rodando na geração 0
      HarnessEnvironmentParity.processSignal(
        coordinator: coordinator,
        context: context,
        signal: HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.fromMillisecondsSinceEpoch(100),
          activityId: 'gen0-task',
          generation: 0,
        ),
      );
      expect(coordinator.snapshot.isTurnActive, isTrue);

      // Queda de transporte e reconexão com salto de geração
      context = HarnessEnvironmentParity.handleReconnection(
        coordinator: coordinator,
        context: context,
      );
      expect(context.generation, equals(1));
      expect(coordinator.generation, equals(1));

      // Buffer residual da rede antiga chega atrasado com generation: 0
      final acceptedStale = HarnessEnvironmentParity.processSignal(
        coordinator: coordinator,
        context: context,
        signal: HarnessSignal(
          source: HarnessSignalSource.screenObservation,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.fromMillisecondsSinceEpoch(200),
          activityId: 'gen0-ghost-task',
          generation: 0,
        ),
      );

      // Deve ser categoricamente rejeitado
      expect(acceptedStale, isFalse);

      // Sinal da nova geração (generation: 1) é aceito normalmente
      final acceptedFresh = HarnessEnvironmentParity.processSignal(
        coordinator: coordinator,
        context: context,
        signal: HarnessSignal(
          source: HarnessSignalSource.structuredHook,
          phase: HarnessExecutionPhase.running,
          timestamp: DateTime.fromMillisecondsSinceEpoch(300),
          activityId: 'gen1-task',
          generation: 1,
        ),
      );
      expect(acceptedFresh, isTrue);
      expect(coordinator.snapshot.activeActivityId, equals('gen1-task'));
    });

    test('normalizes WSL and SSH environment paths safely', () {
      // Windows path no WSL converte para /mnt/c/...
      final wslFromWindows = HarnessEnvironmentParity.normalizeEnvironmentPath(
        rawPath: r'C:\Users\developer\repo\code',
        type: HarnessEnvironmentType.wsl,
      );
      expect(wslFromWindows, equals('/mnt/c/Users/developer/repo/code'));

      // Caminho nativo POSIX no WSL permanece inalterado
      final wslNative = HarnessEnvironmentParity.normalizeEnvironmentPath(
        rawPath: '/home/ubuntu/app/server',
        type: HarnessEnvironmentType.wsl,
      );
      expect(wslNative, equals('/home/ubuntu/app/server'));

      // SSH preserva caminhos POSIX remotos com barras normalizadas
      final sshPath = HarnessEnvironmentParity.normalizeEnvironmentPath(
        rawPath: r'/var/log/remote\app/service',
        type: HarnessEnvironmentType.sshRemote,
      );
      expect(sshPath, equals('/var/log/remote/app/service'));
    });
  });
}
