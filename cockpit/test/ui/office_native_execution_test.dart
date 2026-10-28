import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/utils/spawn_directory.dart';
import 'package:orkest_code/app/core/domain/entities/terminal_profile.dart';
import 'package:orkest_code/app/orkest/domain/contracts/terminal_gateway.dart';
import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/orkest/ui/session/office_room_effects.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_world_flutter_view.dart';

class _Gateway implements TerminalGateway {
  final controller = StreamController<List<int>>();
  @override
  SpawnDirectory? get spawnDirectory => null;
  @override
  int? get rootProcessId => null;
  @override
  Stream<List<int>> get output => controller.stream;
  @override
  void start({
    required String workingDirectory,
    required TerminalProfile profile,
    int rows = 25,
    int columns = 80,
    Map<String, String> extraEnv = const {},
  }) {}
  @override
  void write(List<int> data) {}
  @override
  void resize(int rows, int columns) {}
  @override
  void acknowledgeOutput() {}
  @override
  Future<void> kill() async {
    if (!controller.isClosed) await controller.close();
  }
}

TerminalSession _session(
  _Gateway gateway, {
  String id = 'native',
  String projectId = 'project',
}) => TerminalSession(
  id: id,
  projectId: projectId,
  workingDirectory: '/tmp',
  gateway: gateway,
  profile: const TerminalProfile(
    id: 'test',
    label: 'Shell',
    executable: '/bin/sh',
    args: [],
  ),
);

void main() {
  testWidgets('native layout extends beyond the baked sixteen workspaces', (
    tester,
  ) async {
    await tester.runAsync(() async {
      rootBundle.clear();
      await rootBundle.loadString('assets/office_world/native-scene.json');
    });
    var now = DateTime.now().millisecondsSinceEpoch;
    final projects = List.generate(
      18,
      (i) => i == 0
          ? Project.systemTerminal()
          : Project(
              id: 'p$i',
              name: 'Project $i',
              path: '/tmp',
              colorValue: 0xff4488ff,
              createdAt: DateTime.now(),
            ),
    );
    final sessions = List.generate(
      18,
      (i) => _session(_Gateway(), id: 'many-$i', projectId: projects[i].id),
    );
    for (final session in sessions) {
      session.applyOfficeActivity(
        kind: 'thinking',
        phase: 'started',
        summary: 'Working',
      );
    }
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: OfficeWorldFlutterView(
          projects: projects,
          sessions: sessions,
          labels: const OfficeWorldLabels(
            reception: 'Reception',
            cafe: 'Kitchen',
            restrooms: 'Restrooms',
            lounge: 'Lounge',
            working: 'Working',
            waiting: 'Waiting',
            idle: 'Idle',
          ),
          nowMilliseconds: () => now,
          onOpenSession: (_) {},
          onRenameSession: (_, _) {},
        ),
      ),
    );
    final renderer = find.byWidgetPredicate(
      (w) =>
          w is CustomPaint &&
          w.painter.runtimeType.toString() == '_WorldPainter',
    );
    for (var i = 0; i < 200 && renderer.evaluate().isEmpty; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 30)),
      );
      await tester.pump();
    }
    expect(
      renderer,
      findsOneWidget,
      reason: tester
          .widgetList<Text>(find.byType(Text))
          .map((w) => w.data)
          .join('\n'),
    );
    final dynamic state = tester.state(find.byType(OfficeWorldFlutterView));
    expect(state.debugActors, hasLength(18));
    for (var i = 0; i < 20000; i++) {
      now += 33;
      state.debugTick();
    }
    await tester.pump();
    expect(
      (state.debugActors as List).where((a) => a['gone'] == true),
      isEmpty,
    );
    expect(
      (state.debugActors as List).map((a) => a['pose']),
      everyElement('type'),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(() async {
      for (final session in sessions) {
        await session.dispose();
      }
    });
  });
  testWidgets(
    'native idle scripts execute social encounters and yield to work',
    (tester) async {
      var now = DateTime.now().millisecondsSinceEpoch;
      final sessions = List.generate(
        6,
        (i) => _session(_Gateway(), id: 'idle-$i'),
      );
      for (final session in sessions) {
        session.applyClaudeStatus(
          status: TerminalStatus.idle,
          event: 'SessionStart',
        );
      }
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: OfficeWorldFlutterView(
            projects: [
              Project(
                id: 'project',
                name: 'Social',
                path: '/tmp',
                colorValue: 0xff4488ff,
                createdAt: DateTime.now(),
              ),
            ],
            sessions: sessions,
            labels: const OfficeWorldLabels(
              reception: 'Reception',
              cafe: 'Kitchen',
              restrooms: 'Restrooms',
              lounge: 'Lounge',
              working: 'Working',
              waiting: 'Waiting',
              idle: 'Idle',
            ),
            nowMilliseconds: () => now,
            onOpenSession: (_) {},
            onRenameSession: (_, _) {},
          ),
        ),
      );
      final dynamic state = tester.state(find.byType(OfficeWorldFlutterView));
      final renderer = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_WorldPainter',
      );
      for (var i = 0; i < 100 && renderer.evaluate().isEmpty; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
      }
      expect(renderer, findsOneWidget);
      final groups = <String>{}, poses = <String>{};
      for (var i = 0; i < 40000; i++) {
        now += 33;
        state.debugTick();
        for (final actor in state.debugActors as List) {
          poses.add(actor['pose'] as String);
          if (actor['group'] != null) groups.add(actor['group'] as String);
        }
      }
      expect(
        groups,
        containsAll([
          'tv',
          'videogame',
          'arcade',
          'pingpong',
          'kitchen',
          'talk',
          'rps',
          'mirror',
        ]),
      );
      expect(
        poses,
        containsAll([
          'walk',
          'sit',
          'talk',
          'game',
          'play',
          'rps',
          'groom',
          'use',
          'cheer',
          'sulk',
        ]),
      );
      for (final session in sessions) {
        session.applyOfficeActivity(
          kind: 'prompt',
          phase: 'started',
          summary: 'Work',
        );
      }
      for (var i = 0; i < 2500; i++) {
        now += 33;
        state.debugTick();
      }
      await tester.pump();
      for (final actor in state.debugActors as List) {
        expect(actor['mode'], 'working');
        expect(actor['group'], isNull);
        expect(actor['pose'], 'type');
      }
      sessions.first.applyOfficeActivity(
        kind: 'done',
        phase: 'completed',
        summary: 'Finished',
      );
      sessions[1].applyOfficeActivity(
        kind: 'needs_input',
        phase: 'started',
        summary: 'Approval',
      );
      for (var i = 0; i < 2500; i++) {
        now += 33;
        state.debugTick();
      }
      await tester.pump();
      expect(state.debugActors, hasLength(6));
      expect(
        (state.debugActors as List).where((actor) => actor['mode'] == 'idle'),
        hasLength(1),
      );
      expect(
        (state.debugActors as List).where(
          (actor) => actor['mode'] == 'waiting',
        ),
        hasLength(1),
      );
      expect(
        (state.debugActors as List).where(
          (actor) => actor['mode'] == 'working',
        ),
        hasLength(4),
      );
      sessions.first.applyClaudeStatus(
        status: TerminalStatus.idle,
        event: 'SessionEnd',
      );
      for (var i = 0; i < 2500; i++) {
        now += 33;
        state.debugTick();
      }
      await tester.pump();
      expect(state.debugActors, hasLength(5));
      expect(sessions.first.hasOfficeAgentPresence, false);
      expect(sessions[1].status, TerminalStatus.waiting);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        for (final session in sessions) {
          await session.dispose();
        }
      });
    },
  );
  testWidgets(
    'PTY markers reach the session before stream exit and never invent CI',
    (tester) async {
      await tester.runAsync(() async {
        final gateway = _Gateway();
        final session = _session(gateway);
        session.setVisible(true);
        gateway.controller.add(utf8.encode('\x1b]133;C\x07'));
        await Future<void>.delayed(const Duration(milliseconds: 300));
        expect(session.officeShells, hasLength(1));
        gateway.controller.add(utf8.encode('\x1b]133;D;2\x07'));
        unawaited(gateway.controller.close());
        await Future<void>.delayed(const Duration(milliseconds: 200));
        expect(session.officeShells, isEmpty);
        expect(session.officeShellDone?['error'], true);
        expect(session.hasOfficeAgentPresence, false);
        expect(
          OfficeRoomEffectsManager.instance.getEffect(
            'project',
            DateTime.now().millisecondsSinceEpoch,
          ),
          isNull,
        );
        await session.dispose();
      });
    },
  );

  test(
    'tasks and unknown harness metadata are independent of turn status',
    () async {
      final session = _session(_Gateway());
      for (final (kind, status) in [
        ('task_pending', 'pending'),
        ('task_started', 'in_progress'),
        ('task_completed', 'completed'),
      ]) {
        session.applyOfficeActivity(
          kind: kind,
          phase: 'completed',
          summary: 'Review',
          activityId: 'task:1',
          harness: 'apple-fm',
        );
        expect(session.officeTasks.single['status'], status);
        expect(session.officeVisualStatus, 'idle');
        expect(session.officeHarness.id, 'apple-fm');
      }
      expect(
        () => session.officeTasks.single['status'] = 'bad',
        throwsUnsupportedError,
      );
      session.applyOfficeActivity(
        kind: 'task_removed',
        phase: 'completed',
        summary: 'Review',
        activityId: 'task:1',
      );
      expect(session.officeTasks, isEmpty);
      await session.dispose();
    },
  );

  testWidgets(
    'native assets animate real session work, shell failure and human approval',
    (tester) async {
      tester.view.physicalSize = const Size(2200, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(() async {
        rootBundle.clear();
        await rootBundle.loadString('assets/office_world/native-scene.json');
      });
      final gateway = _Gateway();
      final session = _session(gateway);
      session.applyOfficeActivity(
        kind: 'thinking',
        phase: 'started',
        summary: 'Work',
        harness: 'kimi',
      );
      var now = DateTime.now().millisecondsSinceEpoch;
      final boundaryKey = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RepaintBoundary(
            key: boundaryKey,
            child: OfficeWorldFlutterView(
              projects: [
                Project(
                  id: 'project',
                  name: 'Native test',
                  path: '/tmp',
                  colorValue: 0xff4488ff,
                  createdAt: DateTime.now(),
                ),
              ],
              sessions: [session],
              labels: const OfficeWorldLabels(
                reception: 'Reception',
                cafe: 'Kitchen',
                restrooms: 'Restrooms',
                lounge: 'Lounge',
                working: 'Working',
                waiting: 'Waiting',
                idle: 'Idle',
              ),
              nowMilliseconds: () => now,
              onOpenSession: (_) {},
              onRenameSession: (_, _) {},
            ),
          ),
        ),
      );
      final dynamic state = tester.state(find.byType(OfficeWorldFlutterView));
      final renderer = find.byWidgetPredicate(
        (w) =>
            w is CustomPaint &&
            w.painter.runtimeType.toString() == '_WorldPainter',
      );
      for (
        var attempt = 0;
        attempt < 100 && renderer.evaluate().isEmpty;
        attempt++
      ) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 30)),
        );
        await tester.pump();
      }
      expect(
        renderer,
        findsOneWidget,
        reason:
            '${state.debugActors}; ${tester.widgetList<CustomPaint>(find.byType(CustomPaint)).map((w) => w.painter.runtimeType)}; ${tester.widgetList<Text>(find.byType(Text)).map((w) => w.data)}',
      );
      expect(state.debugActors, hasLength(1));
      void advance(int frames) {
        for (var i = 0; i < frames; i++) {
          now += 33;
          state.debugTick();
        }
      }

      advance(2500);
      await tester.pump();
      expect((state.debugActors as List).single['pose'], 'type');
      session.applyOfficeActivity(
        kind: 'command',
        phase: 'started',
        summary: 'Build',
        activityId: 'build',
      );
      session.officeShells.single['startedAt'] = now - 700000;
      advance(1);
      await tester.pump();
      expect((state.debugActors as List).single['shellStage'], 'cobweb');
      session.applyOfficeActivity(
        kind: 'command',
        phase: 'failed',
        summary: 'Build failed',
        activityId: 'build',
      );
      session.officeShellDone!['at'] = now;
      advance(1);
      await tester.pump();
      expect((state.debugActors as List).single['icon'], 'storm');
      session.applyOfficeActivity(
        kind: 'needs_input',
        phase: 'started',
        summary: 'Confirm',
      );
      advance(200);
      await tester.pump();
      expect((state.debugActors as List).single['mode'], 'waiting');
      expect((state.debugActors as List).single['pose'], 'raise_hand');
      expect(tester.takeException(), isNull);
      final boundary =
          boundaryKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      await tester.runAsync(() async {
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        final file = File('build/office/native-execution.png');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(png!.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(session.dispose);
    },
  );
}
