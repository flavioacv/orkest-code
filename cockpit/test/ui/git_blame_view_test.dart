import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_blame_view.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Scaffold, TextField;

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
        child: Scaffold(
          body: SizedBox(width: 450, height: 600, child: child),
        ),
      ),
    ),
  );
}

void main() {
  group('GitBlameView Widget Tests', () {
    final hunks = [
      GitBlameHunk(
        commitHash: '41e97669d6756fdba056a2360f0653d9e8790cb9',
        author: 'Ada Lovelace',
        authorEmail: 'ada@example.com',
        authorTime: DateTime.now().subtract(const Duration(hours: 2)),
        summary: 'feat: add core calculation logic',
        originalLine: 1,
        finalLine: 1,
        lineCount: 15,
        lines: const ['line 1', 'line 2'],
      ),
      GitBlameHunk(
        commitHash: '8a7b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b',
        author: 'Grace Hopper',
        authorEmail: 'grace@example.com',
        authorTime: DateTime.now().subtract(const Duration(days: 3)),
        summary: 'fix: handle corner case in compiler',
        originalLine: 16,
        finalLine: 16,
        lineCount: 5,
        lines: const ['line 16'],
      ),
    ];

    testWidgets('renderiza cabeçalho, blocos de autoria, linhas e metadados', (tester) async {
      int? navigatedLine;
      String? viewedCommit;

      await tester.pumpWidget(
        _wrapWithTheme(
          GitBlameView(
            filePath: 'lib/service.dart',
            hunks: hunks,
            onNavigateToLine: (line) => navigatedLine = line,
            onViewCommit: (hash) => viewedCommit = hash,
          ),
        ),
      );
      await tester.pump();

      expect(find.textContaining('AUTORIA (BLAME) — service.dart'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('L1-15'), findsOneWidget);
      expect(find.text('L16-20'), findsOneWidget);
      expect(find.text('41e97669'), findsOneWidget);
      expect(find.text('8a7b9c0d'), findsOneWidget);
      expect(find.text('feat: add core calculation logic'), findsOneWidget);

      // Clica no badge de linha para navegar
      await tester.tap(find.text('L1-15'));
      await tester.pump();
      expect(navigatedLine, equals(1));

      // Clica no hash do commit para inspecionar
      await tester.tap(find.text('8a7b9c0d'));
      await tester.pump();
      expect(viewedCommit, equals('8a7b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b'));
    });

    testWidgets('filtra blocos dinamicamente ao digitar no campo de busca', (tester) async {
      await tester.pumpWidget(
        _wrapWithTheme(
          GitBlameView(
            filePath: 'lib/service.dart',
            hunks: hunks,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Ada Lovelace'), findsOneWidget);
      expect(find.text('Grace Hopper'), findsOneWidget);

      // Digita no campo de busca
      await tester.enterText(find.byType(TextField), 'compiler');
      await tester.pump();

      expect(find.text('Ada Lovelace'), findsNothing);
      expect(find.text('Grace Hopper'), findsOneWidget);
      expect(find.text('fix: handle corner case in compiler'), findsOneWidget);
    });
  });
}
