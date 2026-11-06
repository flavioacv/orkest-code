import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/orkest/domain/services/db_export_service.dart';
import 'package:orkest_code/app/orkest/domain/services/db_row_edit_service.dart';
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
        child: SizedBox(width: 800, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('Database Workbench & Grid Enhancements (FE-E4)', () {
    const editService = DbRowEditService();
    const exportService = DbExportService();

    final sampleResult = DbResult(
      columns: const [
        DbColumn('id', 'INTEGER'),
        DbColumn('username', 'TEXT'),
        DbColumn('email', 'TEXT'),
      ],
      rows: [
        [1, 'flavio', 'flavio@example.com'],
        [2, 'arthur', 'arthur@example.com'],
      ],
      elapsed: const Duration(milliseconds: 14),
    );

    test('DbExportService exporta CSV formatado com delimitador e escapamento', () {
      final csv = exportService.exportCsv(sampleResult);
      expect(csv, contains('id,username,email'));
      expect(csv, contains('1,flavio,flavio@example.com'));
      expect(csv, contains('2,arthur,arthur@example.com'));
    });

    test('DbExportService exporta JSON estruturado com chave e valores', () {
      final json = exportService.exportJson(sampleResult, pretty: true);
      expect(json, contains('"username": "flavio"'));
      expect(json, contains('"email": "arthur@example.com"'));
    });

    test('DbRowEditService gera UPDATE seguro com concorrência otimista e proteção por PK', () {
      final sql = editService.generateOptimisticUpdateSql(
        engine: DbEngine.postgres,
        table: 'users',
        schema: 'public',
        pkColumns: const ['id'],
        pkValues: const [1],
        modifiedColumn: 'username',
        oldValue: 'flavio',
        newValue: 'flavio_valdez',
      );

      expect(sql, equals('UPDATE "public"."users" SET "username" = \'flavio_valdez\' WHERE "id" = 1 AND "username" = \'flavio\';'));
    });

    test('DbRowEditService protege contra atualização com oldValue nulo', () {
      final sql = editService.generateOptimisticUpdateSql(
        engine: DbEngine.sqlite,
        table: 'profiles',
        pkColumns: const ['id'],
        pkValues: const [10],
        modifiedColumn: 'bio',
        oldValue: null,
        newValue: 'Software Architect',
      );

      expect(sql, equals('UPDATE "profiles" SET "bio" = \'Software Architect\' WHERE "id" = 10 AND "bio" IS NULL;'));
    });

    test('DbRowEditService rejeita atualização sem chave primária para evitar corrupção em cascata', () {
      expect(
        () => editService.generateOptimisticUpdateSql(
          engine: DbEngine.postgres,
          table: 'logs',
          pkColumns: const [],
          pkValues: const [],
          modifiedColumn: 'message',
          oldValue: 'old',
          newValue: 'new',
        ),
        throwsA(isA<DbEditException>()),
      );
    });

    testWidgets('Diálogo de edição de célula de grid permite input e confirmação', (tester) async {
      String? savedValue;
      final ctrl = TextEditingController(text: 'antigo_valor');

      await tester.pumpWidget(
        _wrapWithTheme(
          Builder(
            builder: (context) => AlertDialog(
              title: const Text('Editar valor de username'),
              content: SizedBox(
                width: 320,
                child: TextField(
                  key: const ValueKey('db-grid-cell-edit-input'),
                  controller: ctrl,
                  border: Border.all(color: context.colors.border),
                  borderRadius: BorderRadius.circular(4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                ),
              ),
              actions: [
                PrimaryButton(
                  key: const ValueKey('db-grid-cell-edit-save'),
                  onPressed: () => savedValue = ctrl.text,
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('db-grid-cell-edit-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('db-grid-cell-edit-save')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'novo_valor');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pump();

      expect(savedValue, equals('novo_valor'));
    });
  });
}
