import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/core/domain/services/problems_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/ui/widgets/outline_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/problems_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _wrapWithTheme(Widget child) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: SizedBox(width: 600, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('Problems & Outline Workbench Integration (FE-E5)', () {
    late ProblemsController problemsCtrl;

    setUp(() {
      problemsCtrl = ProblemsController();
    });

    test('ProblemsController gerencia diagnósticos, contadores e filtros', () {
      final diag1 = LspDiagnostic(
        range: const LspRange(LspPosition(10, 4), LspPosition(10, 15)),
        message: 'Variável não utilizada',
        severity: LspSeverity.warning,
        code: 'unused_local_variable',
        source: 'dart',
      );
      final diag2 = LspDiagnostic(
        range: const LspRange(LspPosition(25, 0), LspPosition(25, 12)),
        message: 'Erro de compilação de tipo',
        severity: LspSeverity.error,
        code: 'type_error',
        source: 'dart',
      );

      problemsCtrl.setDiagnostics('/project/lib/main.dart', [diag1, diag2]);
      problemsCtrl.setDiagnostics('/project/lib/utils.dart', [
        LspDiagnostic(
          range: const LspRange(LspPosition(5, 2), LspPosition(5, 8)),
          message: 'Dica de otimização',
          severity: LspSeverity.info,
          code: 'prefer_const',
        ),
      ]);

      expect(problemsCtrl.totalCount, equals(3));
      expect(problemsCtrl.errorCount, equals(1));
      expect(problemsCtrl.warningCount, equals(1));
      expect(problemsCtrl.infoCount, equals(1));

      // Filtro por texto
      problemsCtrl.setFilterQuery('variável');
      expect(problemsCtrl.filteredDiagnostics.length, equals(1));
      expect(problemsCtrl.filteredDiagnostics.containsKey('/project/lib/main.dart'), isTrue);

      // Filtro por severidade
      problemsCtrl.setFilterQuery('');
      problemsCtrl.setSeverityFilter(LspSeverity.error);
      final errors = problemsCtrl.filteredDiagnostics;
      expect(errors.length, equals(1));
      expect(errors['/project/lib/main.dart']!.first.message, contains('Erro de compilação'));

      // Limpeza
      problemsCtrl.clearFile('/project/lib/utils.dart');
      expect(problemsCtrl.totalCount, equals(2));
      problemsCtrl.clearAll();
      expect(problemsCtrl.totalCount, equals(0));
    });

    testWidgets('ProblemsPanel renderiza lista agrupada e permite navegação de fonte', (tester) async {
      String? navigatedFile;
      int? navigatedLine;
      int? navigatedCol;

      final diag = LspDiagnostic(
        range: const LspRange(LspPosition(14, 8), LspPosition(14, 20)),
        message: 'Função não encontrada',
        severity: LspSeverity.error,
        code: 'undefined_function',
      );
      problemsCtrl.setDiagnostics('/workspace/src/app.dart', [diag]);

      await tester.pumpWidget(
        _wrapWithTheme(
          ProblemsPanel(
            controller: problemsCtrl,
            onNavigateToSource: (file, line, col) {
              navigatedFile = file;
              navigatedLine = line;
              navigatedCol = col;
            },
          ),
        ),
      );

      expect(find.text('app.dart'), findsOneWidget);
      expect(find.textContaining('Função não encontrada'), findsOneWidget);
      expect(find.text('[15:9]'), findsOneWidget);

      // Clica no item de problema para navegar
      await tester.tap(find.textContaining('Função não encontrada'));
      await tester.pump();

      expect(navigatedFile, equals('/workspace/src/app.dart'));
      expect(navigatedLine, equals(15));
      expect(navigatedCol, equals(9));

      // Filtro textual na barra
      await tester.enterText(find.byKey(const ValueKey('problems-filter-input')), 'xyz_inexistente');
      await tester.pump();
      expect(find.textContaining('Nenhum problema corresponde aos filtros ativos.'), findsOneWidget);
    });

    testWidgets('OutlinePanel renderiza símbolos semânticos e navega ao clicar', (tester) async {
      int? navLine;
      int? navChar;

      final symbols = [
        const LspDocumentSymbol(
          name: 'UserService',
          kind: LspSymbolKind.classType,
          range: LspRange(LspPosition(0, 0), LspPosition(50, 0)),
          selectionRange: LspRange(LspPosition(0, 6), LspPosition(0, 17)),
          detail: 'class',
          children: [
            LspDocumentSymbol(
              name: 'fetchUser',
              kind: LspSymbolKind.method,
              range: LspRange(LspPosition(10, 2), LspPosition(20, 2)),
              selectionRange: LspRange(LspPosition(10, 11), LspPosition(10, 20)),
              detail: 'Future<User>()',
            ),
            LspDocumentSymbol(
              name: 'apiKey',
              kind: LspSymbolKind.field,
              range: LspRange(LspPosition(2, 2), LspPosition(2, 22)),
              selectionRange: LspRange(LspPosition(2, 8), LspPosition(2, 14)),
              detail: 'String',
            ),
          ],
        ),
      ];

      await tester.pumpWidget(
        _wrapWithTheme(
          OutlinePanel(
            symbols: symbols,
            onNavigateToSource: (line, char) {
              navLine = line;
              navChar = char;
            },
          ),
        ),
      );

      expect(find.text('UserService'), findsOneWidget);
      expect(find.text('fetchUser'), findsOneWidget);
      expect(find.text('apiKey'), findsOneWidget);

      // Clica no método fetchUser
      await tester.tap(find.text('fetchUser'));
      await tester.pump();

      expect(navLine, equals(11));
      expect(navChar, equals(12));

      // Filtra pelo input de outline
      await tester.enterText(find.byKey(const ValueKey('outline-filter-input')), 'apiKey');
      await tester.pump();
      expect(
        find.descendant(of: find.byType(ListView), matching: find.text('apiKey')),
        findsOneWidget,
      );
    });

    test('WorkbenchToolId enum inclui problems e outline com serialização íntegra', () {
      expect(WorkbenchToolId.values.any((t) => t.name == 'problems'), isTrue);
      expect(WorkbenchToolId.values.any((t) => t.name == 'outline'), isTrue);

      final state = WorkbenchLayoutState.fromJson({'activeTool': 'problems'});
      expect(state.activeTool, equals(WorkbenchToolId.problems));

      final stateOutline = WorkbenchLayoutState.fromJson({'activeTool': 'outline'});
      expect(stateOutline.activeTool, equals(WorkbenchToolId.outline));
    });
  });
}
