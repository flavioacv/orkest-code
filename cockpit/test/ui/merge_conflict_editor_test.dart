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

  group('MergeDocumentEditor - Full Document Workflow', () {
    setUp(() {
      LocaleSettings.setLocale(AppLocale.en);
    });

    const multiConflictDoc =
        'header\n'
        '<<<<<<< HEAD\n'
        'alpha\n'
        '=======\n'
        'beta\n'
        '>>>>>>> branch-a\n'
        'middle text\n'
        '<<<<<<< HEAD\n'
        'gamma\n'
        '||||||| base\n'
        'base-gamma\n'
        '=======\n'
        'delta\n'
        '>>>>>>> branch-b\n'
        'footer\n';

    Future<void> openDoc(
      WidgetTester tester, {
      required String text,
      required void Function(String?) completed,
      int initialIndex = 0,
    }) async {
      await tester.pumpWidget(
        TranslationProvider(
          child: ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: Scaffold(
              child: Builder(
                builder: (context) => PrimaryButton(
                  onPressed: () async => completed(
                    await showMergeDocumentEditor(
                      context,
                      text: text,
                      initialConflictIndex: initialIndex,
                      fileName: 'example.dart',
                    ),
                  ),
                  child: const Text('Review Document'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Review Document'));
      await tester.pumpAndSettle();
    }

    testWidgets('requires explicit resolution, preserves drafts and composes full document', (
      tester,
    ) async {
      String? appliedResult;
      await openDoc(
        tester,
        text: multiConflictDoc,
        completed: (val) => appliedResult = val,
      );

      // Conflito 1 de 2: inicialmente não resolvido
      expect(find.textContaining('1 of 2'), findsOneWidget);
      expect(
        tester
            .widget<PrimaryButton>(find.byKey(const ValueKey('merge-open-full-doc')))
            .onPressed,
        isNull,
      );

      // Editar rascunho do primeiro conflito e marcar como resolvido
      await tester.tap(find.byKey(const ValueKey('merge-use-both')));
      await tester.pumpAndSettle();

      // Navegar para o próximo bloco (bloco 2)
      await tester.tap(find.byKey(const ValueKey('merge-next-block')));
      await tester.pumpAndSettle();
      expect(find.textContaining('2 of 2'), findsOneWidget);

      // Voltar para o bloco 1 e verificar que o rascunho editado foi preservado
      await tester.tap(find.byKey(const ValueKey('merge-prev-block')));
      await tester.pumpAndSettle();
      expect(find.textContaining('1 of 2'), findsOneWidget);
      final firstResultEditor = tester.widget<material.TextField>(
        find.byType(material.TextField),
      );
      expect(firstResultEditor.controller!.text, 'alpha\nbeta');

      // Ir para o bloco 2 e aceitar Theirs
      await tester.tap(find.byKey(const ValueKey('merge-next-block')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('merge-use-theirs')));
      await tester.pumpAndSettle();

      // Ambos resolvidos: o botão de revisão do documento completo fica habilitado
      final openFullDocBtn = tester.widget<PrimaryButton>(
        find.byKey(const ValueKey('merge-open-full-doc')),
      );
      expect(openFullDocBtn.onPressed, isNotNull);

      // Abrir revisão do documento completo
      await tester.tap(find.byKey(const ValueKey('merge-open-full-doc')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('merge-full-doc-editor')), findsOneWidget);

      // Testar proteção ao voltar para os blocos após edição manual
      await tester.enterText(
        find.byKey(const ValueKey('merge-full-doc-editor')),
        'manual edit in full doc',
      );
      await tester.pumpAndSettle();

      // Clicar em voltar aos blocos
      await tester.tap(find.byKey(const ValueKey('merge-back-to-blocks')));
      await tester.pumpAndSettle();

      // Diálogo de confirmação aparece
      expect(find.byKey(const ValueKey('merge-cancel-discard')), findsOneWidget);
      // Cancelar descarte mantém na visualização do documento completo
      await tester.tap(find.byKey(const ValueKey('merge-cancel-discard')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('merge-full-doc-editor')), findsOneWidget);

      // Aplicar o documento completo
      await tester.tap(find.byKey(const ValueKey('merge-apply-document')));
      await tester.pumpAndSettle();

      expect(appliedResult, 'manual edit in full doc');
    });

    testWidgets('cancellation preserves buffer and discards review state', (
      tester,
    ) async {
      String? appliedResult = 'initial';
      await openDoc(
        tester,
        text: multiConflictDoc,
        completed: (val) => appliedResult = val,
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(appliedResult, isNull);
    });
  });
}
