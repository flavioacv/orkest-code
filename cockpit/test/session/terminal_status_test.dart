import 'dart:async';
import 'dart:convert';

import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/orkest/domain/contracts/process_tree_provider.dart';
import 'package:orkest_code/app/orkest/domain/entities/process_snapshot.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_monitor.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway.dart';
import 'package:orkest_code/app/core/utils/spawn_directory.dart';
import 'package:orkest_code/app/core/domain/entities/terminal_profile.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/orkest/ui/session/office_room_effects.dart';
import 'package:flutter_test/flutter_test.dart';

/// [TerminalGateway] inerte — não sobe PTY nenhum; só satisfaz o construtor da
/// [TerminalSession] pra testar a máquina de status de turno isoladamente.
class _NoopGateway implements TerminalGateway {
  // `implements` não herda o corpo default do contrato: precisa declarar.
  @override
  SpawnDirectory? get spawnDirectory => null;

  @override
  int? get rootProcessId => 100;

  final _out = StreamController<List<int>>();

  @override
  Stream<List<int>> get output => _out.stream;
  @override
  void start({
    required String workingDirectory,
    required TerminalProfile profile,
    int rows = 25,
    int columns = 80,
    Map<String, String> extraEnv = const <String, String>{},
  }) {}
  @override
  void write(List<int> data) {}
  @override
  void resize(int rows, int columns) {}
  @override
  void acknowledgeOutput() {}
  @override
  Future<void> kill() async {
    await _out.close();
  }
}

class _ProcessTree implements ProcessTreeProvider {
  List<ProcessSnapshot> snapshots = const [
    ProcessSnapshot(pid: 100, ppid: 1, executable: 'sh', argv: ['sh']),
    ProcessSnapshot(pid: 101, ppid: 100, executable: 'codex', argv: ['codex']),
  ];

  @override
  Future<List<ProcessSnapshot>> getProcessSnapshots({
    required List<int> rootPids,
  }) async => snapshots;
}

TerminalSession _session({
  TerminalHarnessMonitor? monitor,
  String id = 't1',
  String projectId = 'p1',
  _NoopGateway? gateway,
}) => TerminalSession(
  id: id,
  projectId: projectId,
  workingDirectory: '/tmp',
  gateway: gateway ?? _NoopGateway(),
  monitor: monitor,
  profile: const TerminalProfile(
    id: 'login-shell',
    label: 'sh (login)',
    executable: '/bin/sh',
    args: ['-l'],
  ),
);

void main() {
  group('VCS outcomes are independent of agent activity', () {
    test(
      'an uncorrelated PR URL does not celebrate a read or resurrect work',
      () async {
        final s = _session(projectId: 'read-only-pr');
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'SessionStart');
        s.refreshOfficeActivityFromScreen();
        s.terminal.write('https://github.com/org/repo/pull/7\r\n');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        s.refreshOfficeActivityFromScreen();
        expect(
          OfficeRoomEffectsManager.instance.getEffect(
            s.projectId,
            DateTime.now().millisecondsSinceEpoch,
          ),
          isNull,
        );
        expect(s.status, TerminalStatus.idle);
        await s.dispose();
      },
    );
    for (final status in TerminalStatus.values) {
      test(
        'repository events preserve $status and pending command lifetimes',
        () async {
          final s = _session();
          final other = _session(id: 'other', projectId: 'other-project');
          final effects = OfficeRoomEffectsManager.instance;
          effects.prune(DateTime.now().millisecondsSinceEpoch + 1000000);
          s.beginOfficeCommand('run', 'Background build');
          s.applyClaudeStatus(
            status: status,
            isTurnStart: status == TerminalStatus.working,
            event: status == TerminalStatus.waiting
                ? 'PermissionRequest'
                : status == TerminalStatus.idle
                ? 'Stop'
                : 'UserPromptSubmit',
          );
          final commands = s.officeShells;
          final waitingSequence = s.latestWaitingEventSequence;
          for (final kind in [
            'pr_opened',
            'pr_merged',
            'release',
            'push',
            'git',
            'ci_failed',
            'ci_passed',
          ]) {
            s.applyOfficeActivity(
              kind: kind,
              phase: 'completed',
              summary: 'Confirmed repository outcome',
              activityId: kind,
            );
            expect(s.status, status);
            expect(s.officeShells, commands);
            expect(s.latestWaitingEventSequence, waitingSequence);
            expect(other.status, TerminalStatus.idle);
            expect(
              effects.getEffect(
                other.projectId,
                DateTime.now().millisecondsSinceEpoch,
              ),
              isNull,
            );
          }
          expect(
            effects
                .getEffect(s.projectId, DateTime.now().millisecondsSinceEpoch)
                ?.kind,
            OfficeRoomEffectKind.party,
          );
          await s.dispose();
          await other.dispose();
        },
      );
    }

    test(
      'ordinary Git activity is deduplicated without inventing an agent or a party',
      () async {
        final s = _session(projectId: 'shell-only');
        for (var i = 0; i < 2; i++) {
          s.applyOfficeActivity(
            kind: 'git',
            phase: 'completed',
            summary: 'Git pull concluído',
            activityId: 'pull-1',
          );
        }
        expect(s.status, TerminalStatus.idle);
        expect(s.hasOfficeAgentPresence, false);
        expect(s.officeStatusHistory, hasLength(1));
        expect(
          OfficeRoomEffectsManager.instance.getEffect(
            s.projectId,
            DateTime.now().millisecondsSinceEpoch,
          ),
          isNull,
        );
        await s.dispose();
      },
    );

    test(
      'new Git output remains observable after Stop without reviving work or permission',
      () async {
        final s = _session(projectId: 'idle-git');
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'SessionStart');
        s.refreshOfficeActivityFromScreen();
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'Stop');
        s.terminal.write('✓ Merged pull request #7 into main\r\n');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        s.refreshOfficeActivityFromScreen();
        expect(
          OfficeRoomEffectsManager.instance
              .getEffect(s.projectId, DateTime.now().millisecondsSinceEpoch)
              ?.kind,
          OfficeRoomEffectKind.party,
        );
        expect(s.status, TerminalStatus.idle);
        expect(s.latestWaitingEventSequence, -1);
        expect(s.hasOfficeAgentPresence, true);
        await s.dispose();
      },
    );
  });
  group('Office presence follows the open harness session', () {
    for (final (executable, kind) in [
      ('codex', HarnessKind.codex),
      ('antigravity', HarnessKind.antigravity),
    ]) {
      for (final emitMarkers in [false, true]) {
        test(
          '$executable starts idle after launch Enter (shell markers: $emitMarkers)',
          () async {
            final provider = _ProcessTree();
            final shell = provider.snapshots.first;
            final harness = ProcessSnapshot(
              pid: 101,
              ppid: 100,
              executable: executable,
              argv: [executable],
            );
            provider.snapshots = [shell];
            final gateway = _NoopGateway();
            // Drive snapshots explicitly; launch retry timers must not race
            // the transition assertions when the machine is under test load.
            final monitor = TerminalHarnessMonitor(
              provider: provider,
              pollInterval: const Duration(days: 1),
              idlePollInterval: const Duration(days: 1),
              urgentPollInterval: const Duration(days: 1),
              activityPollInterval: const Duration(days: 1),
            );
            final s = _session(monitor: monitor, gateway: gateway);
            s.setVisible(true);
            await Future<void>.delayed(Duration.zero);
            s.sendKeys(utf8.encode('$executable\r'));
            if (emitMarkers) gateway._out.add(utf8.encode('\x1b]133;C\x07'));
            await Future<void>.delayed(const Duration(milliseconds: 300));
            provider.snapshots = [shell, harness];
            await monitor.poll();
            expect(s.activeHarness, kind);
            expect(s.hasOfficeAgentPresence, true);
            expect(s.status, TerminalStatus.idle);
            expect(s.officeShells, isEmpty);
            if (!emitMarkers) {
              // The launch marker can also arrive after process detection.
              gateway._out.add(utf8.encode('\x1b]133;C\x07'));
              await Future<void>.delayed(const Duration(milliseconds: 300));
              expect(s.status, TerminalStatus.idle);
              expect(s.officeShells, isEmpty);
            }
            expect(
              s.officeStatusHistory.where(
                (event) => event.activityKind == 'prompt',
              ),
              isEmpty,
            );
            s.terminal.write('• Reading startup instructions\r\n');
            s.refreshOfficeActivityFromScreen();
            expect(s.status, TerminalStatus.idle);
            s.sendKeys(utf8.encode('Do the task\r'));
            expect(s.status, TerminalStatus.working);
            await Future<void>.delayed(Duration.zero);
            s.applyClaudeStatus(status: TerminalStatus.idle, event: 'Stop');
            expect(s.hasOfficeAgentPresence, true);
            provider.snapshots = [shell];
            await monitor.poll();
            expect(s.hasOfficeAgentPresence, false);
            s.sendKeys(utf8.encode('$executable\r'));
            await Future<void>.delayed(Duration.zero);
            provider.snapshots = [shell, harness];
            await monitor.poll();
            expect(s.hasOfficeAgentPresence, true);
            expect(s.status, TerminalStatus.idle);
            await s.dispose();
            monitor.dispose();
          },
        );
      }
    }
    test('SessionStart alone enters idle and SessionEnd removes it', () async {
      final s = _session();
      s.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionStart',
        sessionId: 'session',
      );
      expect(s.hasOfficeAgentPresence, true);
      expect(s.status, TerminalStatus.idle);
      s.terminal.write('• Reading startup instructions\r\n');
      s.refreshOfficeActivityFromScreen();
      expect(s.status, TerminalStatus.idle);
      s.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionEnd',
        sessionId: 'session',
      );
      expect(s.hasOfficeAgentPresence, false);
      await s.dispose();
    });
    test(
      'SessionEnd removes the character even with unfinished activity records',
      () async {
        final s = _session();
        s.beginOfficeCommand('build', 'Build');
        expect(s.hasOfficeAgentPresence, true);
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'SessionEnd');
        expect(s.officeShells, isNotEmpty);
        expect(s.hasOfficeAgentPresence, false);
        await s.dispose();
      },
    );
    for (final harness in ['codex', 'claude', 'pi', 'gemini', 'kimi']) {
      test(
        '$harness remains idle after completion until the session ends',
        () async {
          final done = _session(id: 'done');
          final pending = _session(id: 'pending');
          expect(done.hasOfficeAgentPresence, false);
          done.applyOfficeActivity(
            kind: 'prompt',
            phase: 'started',
            summary: 'Work',
            harness: harness,
          );
          pending.applyOfficeActivity(
            kind: 'needs_input',
            phase: 'started',
            summary: 'Approval',
            harness: harness,
          );
          expect(done.hasOfficeAgentPresence, true);
          expect(pending.hasOfficeAgentPresence, true);
          done.applyOfficeActivity(
            kind: 'done',
            phase: 'completed',
            summary: 'Finished',
          );
          expect(done.hasOfficeAgentPresence, true);
          expect(done.status, TerminalStatus.idle);
          expect(done.officeStatusHistory, isNotEmpty);
          expect(pending.hasOfficeAgentPresence, true);
          expect(pending.status, TerminalStatus.waiting);
          done.applyOfficeActivity(
            kind: 'prompt',
            phase: 'started',
            summary: 'Next turn',
          );
          expect(done.hasOfficeAgentPresence, true);
          done.applyClaudeStatus(
            status: TerminalStatus.idle,
            event: 'SessionEnd',
          );
          expect(done.hasOfficeAgentPresence, false);
          await done.dispose();
          await pending.dispose();
        },
      );
    }

    test(
      'idle harness stays present and stale output cannot start work',
      () async {
        final provider = _ProcessTree();
        final monitor = TerminalHarnessMonitor(provider: provider);
        final s = _session(monitor: monitor);
        await Future<void>.delayed(Duration.zero);
        expect(s.activeHarness, HarnessKind.codex);
        expect(s.hasOfficeAgentPresence, true);
        expect(s.status, TerminalStatus.idle);
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
        expect(s.hasOfficeAgentPresence, true);
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'Stop');
        expect(s.activeHarness, HarnessKind.codex);
        expect(s.hasOfficeAgentPresence, true);
        s.terminal.write(
          '• Reading a file\r\nWould you like to run the following command?\r\n',
        );
        s.refreshOfficeActivityFromScreen();
        expect(s.hasOfficeAgentPresence, true);
        expect(s.status, TerminalStatus.idle);
        await s.dispose();
        monitor.dispose();
      },
    );

    test('background completion leaves the harness idle and present', () async {
      final s = _session();
      s.applyOfficeActivity(
        kind: 'command',
        phase: 'started',
        summary: 'Build',
        activityId: 'build',
      );
      s.applyOfficeActivity(
        kind: 'done',
        phase: 'completed',
        summary: 'Turn finished',
      );
      expect(s.hasOfficeAgentPresence, true);
      s.applyOfficeActivity(
        kind: 'command',
        phase: 'completed',
        summary: 'Built',
        activityId: 'build',
      );
      expect(s.hasOfficeAgentPresence, true);
      expect(s.status, TerminalStatus.idle);
      s.applySubagentEvent(id: 'child', type: 'worker', started: true);
      expect(s.hasOfficeAgentPresence, true);
      s.applySubagentEvent(id: 'child', type: 'worker', started: false);
      expect(s.hasOfficeAgentPresence, true);
      s.applyClaudeStatus(status: TerminalStatus.idle, event: 'SessionEnd');
      expect(s.hasOfficeAgentPresence, false);
      await s.dispose();
    });
  });
  group('Office approval screen isolation', () {
    test(
      'only the requesting PTY waits when two agents share a project',
      () async {
        final done = _session(id: 'done');
        final pending = _session(id: 'pending');
        done.terminal.write(
          'Would you like to run the following command?\r\n'
          '1. Yes, proceed\r\n'
          'Worked for 14m 17s\r\n'
          '› Ask Codex to do anything\r\n',
        );
        pending.terminal.write(
          'Would you like to run the following command?\r\n'
          '1. Yes, proceed\r\n',
        );
        var requests = 0;
        pending.onTurnFinished = () => requests++;
        for (var i = 0; i < 3; i++) {
          done.refreshOfficeActivityFromScreen();
          pending.refreshOfficeActivityFromScreen();
          await Future<void>.delayed(const Duration(milliseconds: 1100));
        }
        expect(done.projectId, pending.projectId);
        expect(done.status, TerminalStatus.idle);
        expect(done.latestWaitingEventSequence, -1);
        expect(pending.status, TerminalStatus.waiting);
        expect(requests, 1);
        await done.dispose();
        await pending.dispose();
      },
    );

    test(
      'Stop settles a still visible approval without replaying it',
      () async {
        final s = _session();
        s.terminal.write('Would you like to run the following command?\r\n');
        s.refreshOfficeActivityFromScreen();
        expect(s.status, TerminalStatus.waiting);
        s.applyClaudeStatus(status: TerminalStatus.idle, event: 'Stop');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        s.refreshOfficeActivityFromScreen();
        expect(s.status, TerminalStatus.idle);
        s.terminal.write('\x1b[2J\x1b[H');
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        s.refreshOfficeActivityFromScreen();
        s.terminal.write('Would you like to run the following command?\r\n');
        await Future<void>.delayed(const Duration(milliseconds: 1100));
        s.refreshOfficeActivityFromScreen();
        expect(s.status, TerminalStatus.waiting);
        await s.dispose();
      },
    );

    test('repeated pending hooks and activities notify once', () async {
      final s = _session();
      var requests = 0;
      s.onTurnFinished = () => requests++;
      for (var i = 0; i < 3; i++) {
        s.applyClaudeStatus(
          status: TerminalStatus.waiting,
          event: 'PermissionRequest',
          sessionId: 'session',
        );
        s.applyOfficeActivity(
          kind: 'needs_input',
          phase: 'observed',
          summary: 'Approval',
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      }
      expect(requests, 1);
      expect(s.latestWaitingEventSequence, 0);
      s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
      s.applyClaudeStatus(
        status: TerminalStatus.waiting,
        event: 'PermissionRequest',
        sessionId: 'session',
      );
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(requests, 2);
      await s.dispose();
    });
  });
  group('Office agent session isolation', () {
    test(
      'process exit clears permission and rejects late hooks with the PTY open',
      () async {
        final provider = _ProcessTree();
        final monitor = TerminalHarnessMonitor(provider: provider);
        final s = _session(monitor: monitor);
        await Future<void>.delayed(Duration.zero);
        expect(s.activeHarness, HarnessKind.codex);
        s.applyClaudeStatus(
          status: TerminalStatus.waiting,
          event: 'PermissionRequest',
          sessionId: 'remote',
        );
        provider.snapshots = [provider.snapshots.first];
        await monitor.poll();
        expect(s.activeHarness, isNull);
        expect(s.status, TerminalStatus.idle);
        s.applyClaudeStatus(
          status: TerminalStatus.waiting,
          event: 'PermissionRequest',
          sessionId: 'remote',
        );
        expect(s.status, TerminalStatus.idle);
        await s.dispose();
        monitor.dispose();
      },
    );
    test(
      'foreign hooks cannot replace the bound session or request approval',
      () async {
        final s = _session();
        s.applyClaudeStatus(
          status: TerminalStatus.idle,
          event: 'SessionStart',
          sessionId: 'remote',
        );
        s.applyClaudeStatus(
          status: TerminalStatus.waiting,
          event: 'PermissionRequest',
          sessionId: 'detran',
          transcriptPath: '/foreign.jsonl',
        );
        expect(s.status, TerminalStatus.idle);
        expect(s.claudeSessionId, 'remote');
        expect(s.transcriptPath, isNull);
        await s.dispose();
      },
    );

    test('ended agent ignores late hooks until a new session starts', () async {
      final s = _session();
      s.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionStart',
        sessionId: 'remote',
      );
      s.applyClaudeStatus(
        status: TerminalStatus.waiting,
        event: 'PermissionRequest',
        sessionId: 'remote',
      );
      expect(s.status, TerminalStatus.waiting);
      s.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionEnd',
        sessionId: 'remote',
      );
      s.applyClaudeStatus(
        status: TerminalStatus.waiting,
        event: 'PermissionRequest',
        sessionId: 'remote',
      );
      s.applyClaudeStatus(
        status: TerminalStatus.working,
        isTurnStart: true,
        event: 'UserPromptSubmit',
        sessionId: 'remote',
      );
      expect(s.status, TerminalStatus.idle);
      s.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionStart',
        sessionId: 'new',
      );
      s.applyClaudeStatus(
        status: TerminalStatus.waiting,
        event: 'PermissionRequest',
        sessionId: 'new',
      );
      expect(s.status, TerminalStatus.waiting);
      expect(s.claudeSessionId, 'new');
      await s.dispose();
    });
  });
  group('TerminalSession — status de turno (spinner)', () {
    test('working → idle: spinner liga e desliga', () async {
      final s = _session();
      expect(s.isWorking, isFalse);

      s.applyClaudeStatus(
        status: TerminalStatus.working,
        isTurnStart: true,
      ); // UserPromptSubmit
      expect(s.isWorking, isTrue);

      s.applyClaudeStatus(status: TerminalStatus.idle); // Stop
      expect(s.isWorking, isFalse);
      await s.dispose();
    });

    test(
      'FIX: working mid-turn reordenado que chega DEPOIS do idle é descartado',
      () async {
        final s = _session();
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
        s.applyClaudeStatus(status: TerminalStatus.idle); // Stop → idle
        expect(s.isWorking, isFalse);

        // PostToolUse('working') do MESMO turno, entregue fora de ordem depois do
        // Stop (processos/sockets separados). Sem o guard, o spinner voltaria e
        // ficaria girando pra sempre.
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: false);
        expect(
          s.isWorking,
          isFalse,
          reason: 'working mid-turn órfão pós-idle deve ser ignorado',
        );
        await s.dispose();
      },
    );

    test(
      'follow-up enfileirado (UserPromptSubmit) logo após idle LIGA o spinner',
      () async {
        final s = _session();
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
        s.applyClaudeStatus(status: TerminalStatus.idle);
        expect(s.isWorking, isFalse);

        // Turno novo (não é reordenação): isTurnStart pula o guard.
        s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
        expect(s.isWorking, isTrue);
        await s.dispose();
      },
    );

    test('working mid-turn DENTRO de um turno ativo é aceito', () async {
      final s = _session();
      s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: true);
      // PreToolUse volta a idle? não — segue working. Simula waiting→working:
      s.applyClaudeStatus(status: TerminalStatus.waiting); // Notification
      expect(s.isWorking, isFalse);
      // Aprovou → PreToolUse('working') com turno ainda ativo → volta a working.
      s.applyClaudeStatus(status: TerminalStatus.working, isTurnStart: false);
      expect(s.isWorking, isTrue);
      await s.dispose();
    });
  });
  group('Office generic shell lifecycle', () {
    test('parallel command lifecycle needs no harness identity', () async {
      final s = _session();
      void report(String id, String phase) => s.applyOfficeActivity(
        kind: 'command',
        phase: phase,
        summary: 'Build',
        activityId: id,
      );
      report('a', 'started');
      report('b', 'started');
      report('a', 'started');
      expect(s.officeShells, hasLength(2));
      expect(s.officeShells.first['label'], 'Build');
      report('a', 'completed');
      expect(s.officeShellDone?['error'], false);
      expect(s.officeShells.single['id'], 'activity:b');
      report('a', 'started');
      expect(s.officeShells, hasLength(1));
      report('b', 'failed');
      expect(s.officeShellDone?['error'], true);
      expect(s.officeShells, isEmpty);
      report('late', 'completed');
      report('late', 'started');
      expect(s.officeShells, isEmpty);
      await s.dispose();
    });
    test(
      'correlated background work survives turn completion until its own outcome',
      () async {
        final s = _session();
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'started',
          summary: 'Build',
          activityId: 'a',
        );
        final started = s.officeShell!['startedAt'];
        s.applyOfficeActivity(
          kind: 'wait',
          phase: 'updated',
          summary: 'Waiting',
          activityId: 'a',
        );
        expect(s.officeShell?['background'], true);
        expect(s.officeShell?['startedAt'], started);
        s.applyOfficeActivity(
          kind: 'done',
          phase: 'completed',
          summary: 'Turn finished',
        );
        expect(s.officeShells, hasLength(1));
        s.applyOfficeActivity(
          kind: 'wait',
          phase: 'interrupted',
          summary: 'Interrupted',
          activityId: 'a',
        );
        expect(s.officeShells, isEmpty);
        expect(s.officeShellDone?['error'], true);
        await s.dispose();
      },
    );
    test(
      'invalid IDs and observations do not manufacture command executions',
      () async {
        final s = _session();
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'started',
          summary: 'Build',
          activityId: 'invalid id',
        );
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'observed',
          summary: 'Build',
          activityId: 'a',
        );
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'updated',
          summary: 'Build',
          activityId: 'b',
        );
        expect(s.officeShells, isEmpty);
        await s.dispose();
      },
    );
    test(
      'commands have independent IDs from telemetry and respect permission requests',
      () async {
        final s = _session();
        s.beginOfficeCommand('a', 'Telemetry');
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'started',
          summary: 'Build',
          activityId: 'a',
        );
        s.applyOfficeActivity(
          kind: 'needs_input',
          phase: 'started',
          summary: 'Approval',
        );
        s.applyOfficeActivity(
          kind: 'command',
          phase: 'failed',
          summary: 'Failed',
          activityId: 'a',
        );
        expect(s.officeShells.single['id'], 'a');
        expect(s.status, TerminalStatus.waiting);
        await s.dispose();
      },
    );
    test(
      'explicit GitHub events are generic, confirmed and deduplicated by ID',
      () async {
        final s = _session();
        final effects = OfficeRoomEffectsManager.instance;
        final now = DateTime.now().millisecondsSinceEpoch;
        effects.prune(now + 1000000);
        s.applyOfficeActivity(
          kind: 'pr_opened',
          phase: 'started',
          summary: 'PR opened',
          activityId: 'pr1',
        );
        expect(effects.getEffect('p1', now), isNull);
        for (final kind in ['pr_opened', 'pr_merged', 'release']) {
          s.applyOfficeActivity(
            kind: kind,
            phase: 'completed',
            summary: kind,
            activityId: kind,
          );
          final effect = effects.getEffect(
            'p1',
            DateTime.now().millisecondsSinceEpoch,
          )!;
          expect(effect.kind, OfficeRoomEffectKind.party);
          expect(effect.text, kind);
          s.applyOfficeActivity(
            kind: kind,
            phase: 'completed',
            summary: 'duplicate',
            activityId: kind,
          );
          expect(
            effects.getEffect('p1', DateTime.now().millisecondsSinceEpoch),
            same(effect),
          );
        }
        s.applyOfficeActivity(
          kind: 'ci_failed',
          phase: 'completed',
          summary: 'CI failed',
        );
        expect(
          effects.getEffect('p1', DateTime.now().millisecondsSinceEpoch)?.kind,
          OfficeRoomEffectKind.alarm,
        );
        s.applyOfficeActivity(
          kind: 'ci_passed',
          phase: 'completed',
          summary: 'CI passed',
        );
        expect(
          effects.getEffect('p1', DateTime.now().millisecondsSinceEpoch)?.kind,
          OfficeRoomEffectKind.party,
        );
        effects.prune(now + 1000000);
        s.applyOfficeActivity(
          kind: 'push',
          phase: 'completed',
          summary: 'Pushed',
        );
        s.applyOfficeActivity(
          kind: 'ci_passed',
          phase: 'completed',
          summary: 'CI passed',
        );
        expect(
          effects.getEffect('p1', DateTime.now().millisecondsSinceEpoch),
          isNull,
        );
        await s.dispose();
      },
    );
    test('structured commands track start and terminal outcomes', () async {
      final s = _session();
      s.applyOfficeActivity(
        kind: 'command',
        phase: 'started',
        summary: 'Build',
      );
      expect(s.officeShell?['background'], false);
      final started = s.officeShell!['startedAt'];
      s.applyOfficeActivity(
        kind: 'wait',
        phase: 'updated',
        summary: 'Waiting for build',
      );
      expect(s.officeShell?['background'], true);
      expect(s.officeShell?['startedAt'], started);
      s.applyOfficeActivity(
        kind: 'done',
        phase: 'completed',
        summary: 'Turn finished',
      );
      expect(
        s.officeShell,
        isNotNull,
      ); // a background shell can outlive the turn
      s.applyOfficeActivity(
        kind: 'wait',
        phase: 'failed',
        summary: 'Build failed',
      );
      expect(s.officeShell, isNull);
      expect(s.officeShellDone?['error'], true);
      expect(s.officeShellDone?['tool'], 'ShellDone');
      await s.dispose();
    });
    test('PTY text observation does not manufacture a running shell', () async {
      final s = _session();
      s.applyOfficeActivity(
        kind: 'command',
        phase: 'observed',
        summary: 'Ran a command',
      );
      expect(s.officeShell, isNull);
      await s.dispose();
    });
    test(
      'overlapping telemetry commands finish independently and preserve permission',
      () async {
        final s = _session();
        s.beginOfficeCommand('build', 'Build');
        s.beginOfficeCommand('tests', 'Tests');
        expect(s.officeShells.length, 2);
        s.applyOfficeActivity(
          kind: 'needs_input',
          phase: 'started',
          summary: 'Permission',
        );
        s.finishOfficeCommand('build', 0, 'Completed');
        expect(s.officeShells.length, 1);
        expect(s.status, TerminalStatus.waiting);
        expect(s.officeShellDone?['error'], false);
        s.finishOfficeCommand('tests', 130, 'Interrupted');
        expect(s.officeShells, isEmpty);
        expect(s.officeShellDone?['error'], true);
        expect(s.status, TerminalStatus.waiting);
        s.updateOfficeSocialState({
          'identity': s.officeIdentity,
          'version': 1,
          'wallet': {'coins': 120},
        });
        await s.dispose();
        expect(s.officeSocial.data, isNull);
      },
    );
  });
}
