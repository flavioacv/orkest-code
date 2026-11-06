import 'package:flutter/material.dart' as material;
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/merge_conflict_editor.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  const block = ConflictBlock(
    from: 0,
    to: 10,
    startLine: 1,
    endLine: 7,
    ours: 'ours',
    theirs: 'theirs',
    base: '',
    oursLabel: 'HEAD',
    theirsLabel: 'feature',
  );

  Future<void> open(
    WidgetTester tester,
    ConflictBlock conflict,
    void Function(String?) completed,
  ) async {
    await tester.pumpWidget(
      TranslationProvider(
        child: ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: Builder(
              builder: (context) => PrimaryButton(
                onPressed: () async => completed(
                  await showMergeConflictEditor(context, block: conflict),
                ),
                child: const Text('Review'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Review'));
    await tester.pumpAndSettle();
  }

  testWidgets('both sides remain immutable while the result is editable', (
    tester,
  ) async {
    String? applied;
    await open(tester, block, (value) => applied = value);
    await tester.tap(find.byKey(const ValueKey('merge-use-both')));
    await tester.pumpAndSettle();
    final editor = tester.widget<material.TextField>(
      find.byType(material.TextField),
    );
    expect(editor.controller!.text, 'ours\ntheirs');
    await tester.enterText(
      find.byType(material.TextField),
      'custom merged result',
    );
    await tester.pumpAndSettle();
    expect(block.ours, 'ours');
    expect(block.theirs, 'theirs');
    await tester.tap(find.byKey(const ValueKey('merge-apply')));
    await tester.pumpAndSettle();
    expect(applied, 'custom merged result');
    expect(tester.takeException(), isNull);
  });

  testWidgets('unfinished markers cannot be applied; empty base can', (
    tester,
  ) async {
    String? applied;
    await open(tester, block, (value) => applied = value);
    await tester.enterText(
      find.byType(material.TextField),
      '<<<<<<< unresolved',
    );
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<PrimaryButton>(find.byKey(const ValueKey('merge-apply')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const ValueKey('merge-use-base')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<material.TextField>(find.byType(material.TextField))
          .controller!
          .text,
      '',
    );
    await tester.tap(find.byKey(const ValueKey('merge-apply')));
    await tester.pumpAndSettle();
    expect(applied, '');
  });

  testWidgets('narrow dialog supports two-way conflicts and cancellation', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(560, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var completed = false;
    const twoWay = ConflictBlock(
      from: 0,
      to: 10,
      startLine: 1,
      endLine: 5,
      ours: 'ours',
      theirs: 'theirs',
      oursLabel: 'HEAD',
      theirsLabel: 'feature',
    );
    await open(tester, twoWay, (value) {
      completed = true;
      expect(value, isNull);
    });
    expect(find.byKey(const ValueKey('merge-use-base')), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
  });
}
