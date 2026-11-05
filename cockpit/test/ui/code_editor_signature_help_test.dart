import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    CodeEditingController controller,
    Future<String?> Function(({int line, int character})) request, {
    ValueChanged<String>? cancel,
  }) async {
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
              onSignatureHelp: request,
              onCancelLspRequest: cancel,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    focus.requestFocus();
    await tester.pump();
  }

  void edit(CodeEditingController controller, String text) {
    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  testWidgets('opening parenthesis and comma show updated parameter help', (
    tester,
  ) async {
    final ctrl = CodeEditingController(text: 'call', language: 'dart');
    var calls = 0;
    ({int line, int character})? requestedPosition;
    await mount(tester, ctrl, (position) async {
      calls++;
      requestedPosition = position;
      return calls == 1
          ? 'call(first, second)\n\nfirst'
          : 'call(first, second)\n\nsecond';
    });
    edit(ctrl, 'call(');
    await tester.pump(const Duration(milliseconds: 100));
    expect(calls, 0);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump();
    expect(requestedPosition, (line: 0, character: 5));
    expect(find.text('call(first, second)\n\nfirst'), findsOneWidget);
    edit(ctrl, 'call(1,');
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('call(first, second)\n\nsecond'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('call(first, second)\n\nsecond'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  testWidgets('manual shortcut requests help without modifying the document', (
    tester,
  ) async {
    final ctrl = CodeEditingController(text: 'call(1)', language: 'dart');
    await mount(tester, ctrl, (_) async => 'call(int value)');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();
    expect(find.text('call(int value)'), findsOneWidget);
    expect(ctrl.text, 'call(1)');
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  for (final action in ['escape', 'move', 'dispose', 'focus']) {
    testWidgets('ignores delayed signature after $action', (tester) async {
      final ctrl = CodeEditingController(text: 'call', language: 'dart');
      final response = Completer<String?>();
      final cancelled = <String>[];
      await mount(tester, ctrl, (_) => response.future, cancel: cancelled.add);
      edit(ctrl, 'call(');
      await tester.pump(const Duration(milliseconds: 200));
      cancelled.clear();
      if (action == 'escape') {
        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      }
      if (action == 'move') {
        ctrl.selection = const TextSelection.collapsed(offset: 0);
      }
      if (action == 'dispose') await tester.pumpWidget(const SizedBox());
      if (action == 'focus') FocusManager.instance.primaryFocus?.unfocus();
      response.complete('Old signature');
      await tester.pump();
      expect(cancelled, contains('textDocument/signatureHelp'));
      expect(find.text('Old signature'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      ctrl.dispose();
    });
  }
}
