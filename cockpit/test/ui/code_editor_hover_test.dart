import 'dart:async';
import 'dart:ui' show PointerDeviceKind;

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Future<Offset> mount(
    WidgetTester tester,
    CodeEditingController controller,
    Future<String?> Function(({int line, int character})) hover,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    await tester.pumpWidget(
      ShadcnApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: Scaffold(
          child: SizedBox(
            width: 500,
            height: 300,
            child: CodeEditor(
              controller: controller,
              focusNode: focus,
              onSymbolHover: hover,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return tester.getTopLeft(find.byType(EditableText)) + const Offset(12, 10);
  }

  testWidgets('debounces and displays semantic information', (tester) async {
    final controller = CodeEditingController(
      text: 'alpha beta',
      language: 'dart',
    );
    var calls = 0;
    final point = await mount(tester, controller, (position) async {
      calls++;
      expect(position.line, 0);
      return 'int alpha';
    });
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(point);
    await tester.pump(const Duration(milliseconds: 200));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(calls, 1);
    expect(find.text('int alpha'), findsOneWidget);
    await mouse.moveTo(const Offset(799, 599));
    await tester.pump();
    expect(find.text('int alpha'), findsNothing);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  for (final invalidate in ['edit', 'exit', 'dispose', 'document']) {
    testWidgets('ignores delayed reply after $invalidate', (tester) async {
      final controller = CodeEditingController(
        text: 'alpha beta',
        language: 'dart',
      );
      final reply = Completer<String?>();
      var calls = 0;
      final point = await mount(tester, controller, (_) {
        calls++;
        return reply.future;
      });
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: Offset.zero);
      await mouse.moveTo(point);
      await tester.pump(const Duration(milliseconds: 400));
      expect(calls, 1);
      if (invalidate == 'edit') controller.text = 'changed';
      if (invalidate == 'exit') await mouse.moveTo(const Offset(799, 599));
      if (invalidate == 'dispose') await tester.pumpWidget(const SizedBox());
      CodeEditingController? replacement;
      if (invalidate == 'document') {
        replacement = CodeEditingController(text: 'other', language: 'dart');
        await mount(tester, replacement, (_) async => 'New document');
      }
      reply.complete('Stale symbol info');
      await tester.pump();
      expect(find.text('Stale symbol info'), findsNothing);
      expect(tester.takeException(), isNull);
      await mouse.removePointer();
      await tester.pumpWidget(const SizedBox());
      controller.dispose();
      replacement?.dispose();
    });
  }
}
