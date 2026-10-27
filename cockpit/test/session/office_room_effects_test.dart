import 'package:orkest_code/app/orkest/domain/services/git_terminal_event_detector.dart';
import 'package:orkest_code/app/orkest/ui/session/office_room_effects.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('OfficeRoomEffectsManager', () {
    test('party effect expires after duration', () {
      final manager = OfficeRoomEffectsManager(
        partyDuration: const Duration(seconds: 12),
        alarmDuration: const Duration(minutes: 10),
      );
      const roomId = 'proj-1';
      final start = DateTime(2026, 1, 1, 12, 0).millisecondsSinceEpoch;

      manager.triggerParty(roomId, 'PR #10 aberto!', timestamp: start);

      final active = manager.getEffect(roomId, start + 5000);
      expect(active, isNotNull);
      expect(active!.kind, OfficeRoomEffectKind.party);
      expect(active.text, 'PR #10 aberto!');

      final expired = manager.getEffect(roomId, start + 13000);
      expect(expired, isNull);
    });

    test('alarm cancels party and holds until resolved or timed out', () {
      final manager = OfficeRoomEffectsManager(
        partyDuration: const Duration(seconds: 12),
        alarmDuration: const Duration(minutes: 10),
      );
      const roomId = 'proj-1';
      final start = DateTime(2026, 1, 1, 12, 0).millisecondsSinceEpoch;

      manager.triggerParty(roomId, 'PR #10 aberto!', timestamp: start);
      manager.triggerAlarm(roomId, 'CI falhou', timestamp: start + 1000);

      final alarm = manager.getEffect(roomId, start + 2000);
      expect(alarm, isNotNull);
      expect(alarm!.kind, OfficeRoomEffectKind.alarm);
      expect(alarm.text, 'CI falhou');

      // Resolução com CI verde converte alarme em festa
      final resolved = manager.resolveAlarm(roomId, timestamp: start + 3000);
      expect(resolved, isTrue);

      final celebration = manager.getEffect(roomId, start + 4000);
      expect(celebration, isNotNull);
      expect(celebration!.kind, OfficeRoomEffectKind.party);
      expect(celebration.text, 'CI verde de novo!');
    });
  });

  group('GitTerminalEventDetector', () {
    const detector = GitTerminalEventDetector();

    test('detects PR open from GitHub URL', () {
      final event = detector.detect(
        'https://github.com/my-org/my-repo/pull/42',
      );
      expect(event, isNotNull);
      expect(event!.kind, GitTerminalEventKind.prOpened);
      expect(event.number, 42);
      expect(event.banner, 'PR #42 aberto!');
      expect(event.icon, '🎉');
    });

    test('detects PR created message', () {
      final event = detector.detect('Created pull request #88');
      expect(event, isNotNull);
      expect(event!.kind, GitTerminalEventKind.prOpened);
      expect(event.number, 88);
      expect(event.banner, 'PR #88 aberto!');
    });

    test('detects PR merged', () {
      final event = detector.detect('✓ Merged pull request #15 into main');
      expect(event, isNotNull);
      expect(event!.kind, GitTerminalEventKind.prMerged);
      expect(event.number, 15);
      expect(event.banner, 'PR #15 mergeado!');
    });

    test('detects CI failure and success', () {
      final fail = detector.detect('✗ main CI · 123');
      expect(fail, isNotNull);
      expect(fail!.kind, GitTerminalEventKind.ciFailed);
      expect(fail.isError, isTrue);
      expect(fail.icon, '🚨');

      final pass = detector.detect('All checks were successful');
      expect(pass, isNotNull);
      expect(pass!.kind, GitTerminalEventKind.ciPassed);
      expect(pass.icon, '✅');
    });

    test('ignores prose and source text mentioning CI failures', () {
      expect(
        detector.detect('CI failed before the agent ran anything'),
        isNull,
      );
      expect(detector.detect('expect(text, "CI failed")'), isNull);
      expect(
        detector.detect('CI falhou (com alarme, como no Habblaud)'),
        isNull,
      );
      expect(detector.detect('X main CI failed'), isNull);
    });

    test('detects git push', () {
      final push = detector.detect(
        'abc1234..def5678  main -> main',
        isPushOutput: true,
      );
      expect(push, isNotNull);
      expect(push!.kind, GitTerminalEventKind.push);
      expect(push.icon, '🚀');
    });

    test('does not celebrate URLs, rejected pushes or unrelated output', () {
      expect(
        detector.detect('Veja https://github.com/acme/repo/pull/42'),
        isNull,
      );
      expect(
        detector.detect('https://github.com/acme/repo/pull/42 já existe'),
        isNull,
      );
      expect(
        detector.detect(
          'Release: https://github.com/acme/repo/releases/tag/v1',
        ),
        isNull,
      );
      expect(detector.detect('✓ Merged'), isNull);
      expect(detector.detect('main -> origin/main'), isNull);
      expect(detector.detect('abc1234..def5678  main -> origin/main'), isNull);
      expect(
        detector.detect('! [rejected] main -> main', isPushOutput: true),
        isNull,
      );
    });
  });
}
