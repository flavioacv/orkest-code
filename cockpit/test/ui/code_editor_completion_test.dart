import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_completion.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  Future<void> mount(
    WidgetTester tester,
    CodeEditingController ctrl,
    Future<List<LspCompletionItem>> Function(({int line, int character}))
    request, {
    Future<LspCompletionItem?> Function(LspCompletionItem)? resolve,
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
              controller: ctrl,
              focusNode: focus,
              onCompletions: request,
              onResolveCompletion: resolve,
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

  void edit(CodeEditingController ctrl, String text) {
    ctrl.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> wait(WidgetTester tester) async {
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pump();
  }

  const items = [
    LspCompletionItem(label: 'answer', insertText: 'answer'),
    LspCompletionItem(label: 'another', insertText: 'another'),
  ];

  for (final resolving in [false, true]) {
    for (final action in ['escape', 'focus', 'scroll', 'dispose']) {
      testWidgets(
        'cancel $action reaches ${resolving ? 'resolve' : 'completion'}',
        (tester) async {
          final ctrl = CodeEditingController(text: 'a', language: 'dart');
          final suggestions = Completer<List<LspCompletionItem>>();
          final resolution = Completer<LspCompletionItem?>();
          final cancelled = <String>[];
          await mount(
            tester,
            ctrl,
            (_) => suggestions.future,
            resolve: (_) => resolution.future,
            cancel: cancelled.add,
          );
          edit(ctrl, 'an\n${List.filled(80, 'line').join('\n')}');
          ctrl.selection = const TextSelection.collapsed(offset: 2);
          // A seleção mudou após a edição; o atalho consulta esta posição.
          await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
          await tester.sendKeyEvent(LogicalKeyboardKey.space);
          await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
          await wait(tester);
          if (resolving) {
            suggestions.complete(items);
            await tester.pump();
            await tester.sendKeyEvent(LogicalKeyboardKey.enter);
            await tester.pump();
          }
          cancelled.clear();
          switch (action) {
            case 'escape':
              await tester.sendKeyEvent(LogicalKeyboardKey.escape);
            case 'focus':
              FocusManager.instance.primaryFocus?.unfocus();
            case 'scroll':
              tester
                  .widget<EditableText>(find.byType(EditableText))
                  .scrollController!
                  .jumpTo(40);
            case 'dispose':
              await tester.pumpWidget(const SizedBox());
          }
          await tester.pump();
          expect(
            cancelled,
            contains(
              resolving ? 'completionItem/resolve' : 'textDocument/completion',
            ),
          );
          if (!suggestions.isCompleted) suggestions.complete(items);
          if (!resolution.isCompleted) resolution.complete(items.first);
          await tester.pump();
          expect(ctrl.text, startsWith('an\n'));
          expect(find.text('answer'), findsNothing);
          await tester.pumpWidget(const SizedBox());
          ctrl.dispose();
        },
      );
    }
  }

  for (final key in [LogicalKeyboardKey.enter, LogicalKeyboardKey.tab]) {
    testWidgets(
      'keyboard selection accepts without inserting ${key.keyLabel}',
      (tester) async {
        final ctrl = CodeEditingController(text: 'a', language: 'dart');
        await mount(tester, ctrl, (_) async => items);
        edit(ctrl, 'an');
        await wait(tester);
        expect(find.text('answer'), findsOneWidget);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        await tester.sendKeyEvent(key);
        await tester.pump();
        expect(ctrl.text, 'another');
        expect(ctrl.selection.baseOffset, 7);
        await tester.pumpWidget(const SizedBox());
        ctrl.dispose();
      },
    );
  }

  testWidgets('manual shortcut and Escape preserve text', (tester) async {
    final ctrl = CodeEditingController(text: 'a', language: 'dart');
    edit(ctrl, 'a');
    await mount(tester, ctrl, (_) async => items);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await wait(tester);
    expect(find.text('answer'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pump();
    expect(find.text('answer'), findsNothing);
    expect(ctrl.text, 'a');
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  testWidgets('late suggestions after edit are discarded', (tester) async {
    final ctrl = CodeEditingController(text: 'a', language: 'dart');
    final gate = Completer<List<LspCompletionItem>>();
    await mount(tester, ctrl, (_) => gate.future);
    edit(ctrl, 'an');
    await wait(tester);
    edit(ctrl, '');
    gate.complete(items);
    await tester.pump();
    expect(find.text('answer'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  testWidgets('Escape cancels suggestions before the menu is visible', (
    tester,
  ) async {
    final ctrl = CodeEditingController(text: 'a', language: 'dart');
    final gate = Completer<List<LspCompletionItem>>();
    await mount(tester, ctrl, (_) => gate.future);
    edit(ctrl, 'an');
    await wait(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    gate.complete(items);
    await tester.pump();
    expect(find.text('answer'), findsNothing);
    expect(ctrl.text, 'an');
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  testWidgets('dot triggers suggestions accepted by pointer', (tester) async {
    final ctrl = CodeEditingController(text: 'obj', language: 'dart');
    await mount(tester, ctrl, (_) async => items);
    edit(ctrl, 'obj.');
    await wait(tester);
    await tester.tap(find.text('answer'));
    await tester.pump();
    expect(ctrl.text, 'obj.answer');
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  for (final action in ['focus', 'dispose']) {
    testWidgets('late suggestions after $action are discarded', (tester) async {
      final ctrl = CodeEditingController(text: 'a', language: 'dart');
      final gate = Completer<List<LspCompletionItem>>();
      await mount(tester, ctrl, (_) => gate.future);
      edit(ctrl, 'an');
      await wait(tester);
      if (action == 'focus') {
        FocusManager.instance.primaryFocus?.unfocus();
      } else {
        await tester.pumpWidget(const SizedBox());
      }
      gate.complete(items);
      await tester.pump();
      expect(find.text('answer'), findsNothing);
      await tester.pumpWidget(const SizedBox());
      ctrl.dispose();
    });
  }

  testWidgets('resolve cannot overwrite newer typing', (tester) async {
    final ctrl = CodeEditingController(text: 'a', language: 'dart');
    final gate = Completer<LspCompletionItem?>();
    await mount(tester, ctrl, (_) async => items, resolve: (_) => gate.future);
    edit(ctrl, 'an');
    await wait(tester);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    edit(ctrl, 'changed');
    gate.complete(items.first);
    await tester.pump();
    expect(ctrl.text, 'changed');
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });
}
