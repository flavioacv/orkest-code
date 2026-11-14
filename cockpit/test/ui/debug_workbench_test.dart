import 'package:flutter/material.dart' as m;
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_variable_tree.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../support/debug_adapter_fixture.dart';

Widget host(Widget child, {Brightness brightness = Brightness.dark}) =>
    TranslationProvider(
      child: ShadcnApp(
        theme: buildTheme(
          brightness: brightness,
        ).copyWith(platform: () => TargetPlatform.windows),
        home: Scaffold(child: child),
      ),
    );

void main() {
  late DebugAdapterFixture server;
  late DebugSessionController controller;
  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    server = DebugAdapterFixture();
    controller = DebugSessionController();
  });
  tearDown(() async {
    await controller.stop();
    controller.dispose();
    await server.close();
  });
  void size(WidgetTester tester, Size value) {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Future<void> paused(WidgetTester tester) async {
    await tester.runAsync(() async {
      await controller.startSession(
        client: server.client(),
        program: '/repo/main.dart',
      );
      server.event('stopped', {'reason': 'breakpoint', 'threadId': 1});
      await waitForDebug(() => controller.scopes.isNotEmpty);
    });
  }

  Future<void> settleDap(WidgetTester tester) async {
    // The fixture streams run in the real zone while widgets use fake async.
    for (var i = 0; i < 4; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pumpAndSettle();
    }
  }

  testWidgets(
    'configuration picker changes the actual launch target and separates Run from Debug',
    (tester) async {
      size(tester, const Size(1100, 500));
      const first = RunConfiguration(
        id: 'one',
        name: 'First target',
        type: 'dart',
        program: 'one.dart',
        cwd: '/repo',
      );
      const second = RunConfiguration(
        id: 'two',
        name: 'Second target',
        type: 'python',
        program: 'two.py',
        cwd: '/repo',
      );
      RunConfiguration? started;
      RunConfiguration? ran;
      await tester.pumpWidget(
        host(
          DebugPanel(
            controller: controller,
            configurations: const [first, second],
            onStartConfiguration: (value) => started = value,
            onRunConfiguration: (value) => ran = value,
          ),
        ),
      );
      await tester.tap(
        find.byKey(const ValueKey('debug-configuration-picker')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.tap(find.text('Second target').last);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('run-config-start')));
      expect(started?.id, 'two');
      await tester.tap(find.byKey(const ValueKey('debug-run-terminal')));
      expect(ran?.id, 'two');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'variables expand lazily and console evaluates in the selected frame',
    (tester) async {
      size(tester, const Size(1200, 600));
      await paused(tester);
      await tester.pumpWidget(host(DebugPanel(controller: controller)));
      await tester.pumpAndSettle();
      expect(
        server
            .sent('variables')
            .where(
              (r) => (r['arguments'] as Map)['variablesReference'] == 1000,
            ),
        isEmpty,
      );
      await tester.tap(
        find
            .descendant(
              of: find
                  .byWidgetPredicate(
                    (widget) =>
                        widget is DebugVariableTree && widget.name == 'object',
                  )
                  .first,
              matching: find.byIcon(m.Icons.chevron_right),
            )
            .first,
      );
      await tester.runAsync(
        () => waitForDebug(
          () => server
              .sent('variables')
              .any(
                (r) => (r['arguments'] as Map)['variablesReference'] == 1000,
              ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        server
            .sent('variables')
            .where(
              (r) => (r['arguments'] as Map)['variablesReference'] == 1000,
            ),
        hasLength(1),
      );
      await tester.tap(find.byKey(const ValueKey('debug-frame-20')));
      await settleDap(tester);
      expect(controller.currentFrame?.id, 20);
      expect(controller.scopes.single.variablesReference, 200);
      await tester.tap(find.byKey(const ValueKey('debug-console-tab')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('debug-console-evaluate')),
        'value',
      );
      await tester.tap(find.byKey(const ValueKey('debug-console-submit')));
      await settleDap(tester);
      expect((server.sent('evaluate').last['arguments'] as Map)['frameId'], 20);
      expect(find.textContaining('value@20'), findsWidgets);
      await tester.enterText(
        find.byKey(const ValueKey('debug-console-filter')),
        'does-not-exist',
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('value@20'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'breakpoint editor sends condition, hit count and logpoint and supports disabling all',
    (tester) async {
      size(tester, const Size(1200, 600));
      await controller.toggleBreakpoint('/repo/main.dart', 3);
      await paused(tester);
      await tester.pumpWidget(host(DebugPanel(controller: controller)));
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('debug-edit-breakpoint-/repo/main.dart-3')),
      );
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('debug-breakpoint-condition')),
        'value > 2',
      );
      await tester.enterText(
        find.byKey(const ValueKey('debug-breakpoint-hit')),
        '3',
      );
      await tester.enterText(
        find.byKey(const ValueKey('debug-breakpoint-log')),
        'value={value}',
      );
      await tester.tap(find.byKey(const ValueKey('debug-breakpoint-apply')));
      await tester.pumpAndSettle();
      await settleDap(tester);
      final point =
          ((server.sent('setBreakpoints').last['arguments']
                          as Map)['breakpoints']
                      as List)
                  .single
              as Map;
      expect(point['condition'], 'value > 2');
      expect(point['hitCondition'], '3');
      expect(point['logMessage'], 'value={value}');
      await tester.tap(find.byKey(const ValueKey('debug-toggle-breakpoints')));
      await settleDap(tester);
      expect(
        (server.sent('setBreakpoints').last['arguments'] as Map)['breakpoints'],
        isEmpty,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'paused inspection fits narrow and wide windows in light and dark themes',
    (tester) async {
      size(tester, const Size(1200, 500));
      await paused(tester);
      controller.addWatch('aVeryLongWatchExpression.withNestedValues');
      for (final brightness in Brightness.values) {
        for (final viewport in [const Size(360, 220), const Size(1280, 420)]) {
          tester.view.physicalSize = viewport;
          await tester.pumpWidget(
            host(DebugPanel(controller: controller), brightness: brightness),
          );
          await settleDap(tester);
          expect(
            find.byKey(const ValueKey('debug-section-variables')),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: '$brightness $viewport',
          );
        }
      }
      expect(find.byType(m.Material), findsWidgets);
    },
  );
}
