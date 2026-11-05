import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/db_sql_completion_service.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

void main() {
  const service = DbSqlCompletionService();

  final tables = const [
    SchemaTable('users', schema: 'public'),
    SchemaTable('orders', schema: 'public'),
    SchemaTable('user_summary_view', schema: 'public', isView: true),
  ];

  final tableColumns = const {
    'users': [
      SchemaColumn('id', 'INTEGER', primaryKey: true),
      SchemaColumn('email', 'VARCHAR(255)'),
      SchemaColumn('created_at', 'TIMESTAMP'),
    ],
    'orders': [
      SchemaColumn('id', 'INTEGER', primaryKey: true),
      SchemaColumn('user_id', 'INTEGER'),
      SchemaColumn('amount', 'NUMERIC'),
    ],
  };

  group('DbSqlCompletionService (B03)', () {
    test('suggests keywords matching prefix', () {
      final items = service.computeCompletions(
        sql: 'SEL',
        cursorOffset: 3,
        tables: tables,
        tableColumns: tableColumns,
      );

      final keywords = items.where((i) => i.kind == DbSqlCompletionKind.keyword).map((i) => i.label);
      expect(keywords, contains('SELECT'));
    });

    test('prioritizes tables after FROM clause', () {
      final items = service.computeCompletions(
        sql: 'SELECT * FROM u',
        cursorOffset: 15,
        tables: tables,
        tableColumns: tableColumns,
      );

      final tableItems = items.where((i) => i.kind == DbSqlCompletionKind.table).map((i) => i.label).toList();
      expect(tableItems, contains('users'));
      expect(tableItems, contains('user_summary_view'));
      expect(tableItems, isNot(contains('orders')));
    });

    test('prioritizes tables after JOIN clause', () {
      final items = service.computeCompletions(
        sql: 'SELECT * FROM users JOIN ord',
        cursorOffset: 29,
        tables: tables,
        tableColumns: tableColumns,
      );

      final tableItems = items.where((i) => i.kind == DbSqlCompletionKind.table).map((i) => i.label).toList();
      expect(tableItems, contains('orders'));
    });

    test('suggests qualified columns when preceded by table dot', () {
      final items = service.computeCompletions(
        sql: 'SELECT users.em FROM users',
        cursorOffset: 15, // right after "users.em"
        tables: tables,
        tableColumns: tableColumns,
      );

      expect(items.length, 1);
      expect(items.first.kind, DbSqlCompletionKind.column);
      expect(items.first.label, 'email');
      expect(items.first.detail, 'VARCHAR(255)');
    });

    test('suggests common SQL functions', () {
      final items = service.computeCompletions(
        sql: 'SELECT COU',
        cursorOffset: 10,
        tables: tables,
        tableColumns: tableColumns,
      );

      final functions = items.where((i) => i.kind == DbSqlCompletionKind.function).map((i) => i.label);
      expect(functions, contains('COUNT()'));
    });
  });
}
