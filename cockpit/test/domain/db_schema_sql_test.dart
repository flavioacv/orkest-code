import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/db_schema_sql.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';

void main() {
  group('dbSchemaSql - Introspecção básica de tabelas e colunas', () {
    test('SQLite gera consultas para sqlite_master e pragma_table_info', () {
      final tablesSql = dbSchemaSql(DbEngine.sqlite);
      expect(tablesSql, contains('FROM sqlite_master'));

      final colsSql = dbSchemaSql(DbEngine.sqlite, table: 'users');
      expect(colsSql, contains("pragma_table_info('users')"));
    });

    test('PostgreSQL respeita schema e information_schema', () {
      final tablesSql = dbSchemaSql(DbEngine.postgres);
      expect(tablesSql, contains('information_schema.tables'));

      final colsSql = dbSchemaSql(DbEngine.postgres, table: 'orders', schema: 'store');
      expect(colsSql, contains("tc.table_schema = 'store'"));
      expect(colsSql, contains("tc.table_name = 'orders'"));
    });
  });

  group('dbIndexesSql - Introspecção de índices (B01)', () {
    test('SQLite usa PRAGMA index_list', () {
      final sql = dbIndexesSql(DbEngine.sqlite, table: 'customers');
      expect(sql, equals("PRAGMA index_list('customers')"));
    });

    test('PostgreSQL consulta pg_indexes e pg_index', () {
      final sql = dbIndexesSql(DbEngine.postgres, table: 'customers', schema: 'public');
      expect(sql, contains('FROM pg_indexes'));
      expect(sql, contains("schemaname = 'public'"));
      expect(sql, contains("tablename = 'customers'"));
    });

    test('MySQL usa SHOW INDEX FROM', () {
      final sql = dbIndexesSql(DbEngine.mysql, table: 'customers');
      expect(sql, equals('SHOW INDEX FROM `customers`'));
    });

    test('MSSQL consulta sys.indexes e sys.tables', () {
      final sql = dbIndexesSql(DbEngine.mssql, table: 'customers', schema: 'dbo');
      expect(sql, contains('FROM sys.indexes'));
      expect(sql, contains("s.name = 'dbo'"));
      expect(sql, contains("t.name = 'customers'"));
    });

    test('Rejeita engines NoSQL (Redis, Mongo)', () {
      expect(() => dbIndexesSql(DbEngine.redis, table: 'test'), throwsA(isA<DbQueryException>()));
      expect(() => dbIndexesSql(DbEngine.mongo, table: 'test'), throwsA(isA<DbQueryException>()));
    });
  });

  group('dbForeignKeysSql - Introspecção de chaves estrangeiras (B01)', () {
    test('SQLite usa PRAGMA foreign_key_list', () {
      final sql = dbForeignKeysSql(DbEngine.sqlite, table: 'items');
      expect(sql, equals("PRAGMA foreign_key_list('items')"));
    });

    test('PostgreSQL consulta referential_constraints e table_constraints', () {
      final sql = dbForeignKeysSql(DbEngine.postgres, table: 'items', schema: 'ecommerce');
      expect(sql, contains('information_schema.referential_constraints'));
      expect(sql, contains("tc.table_schema = 'ecommerce'"));
      expect(sql, contains("tc.table_name = 'items'"));
    });

    test('MySQL consulta information_schema.KEY_COLUMN_USAGE', () {
      final sql = dbForeignKeysSql(DbEngine.mysql, table: 'items');
      expect(sql, contains('information_schema.KEY_COLUMN_USAGE'));
      expect(sql, contains("TABLE_NAME = 'items'"));
      expect(sql, contains('REFERENCED_TABLE_NAME IS NOT NULL'));
    });

    test('MSSQL consulta sys.foreign_keys', () {
      final sql = dbForeignKeysSql(DbEngine.mssql, table: 'items', schema: 'dbo');
      expect(sql, contains('FROM sys.foreign_keys'));
      expect(sql, contains("s.name = 'dbo'"));
      expect(sql, contains("t1.name = 'items'"));
    });
  });

  group('dbRoutinesSql - Introspecção de rotinas / functions (B01)', () {
    test('SQLite retorna query vazia', () {
      final sql = dbRoutinesSql(DbEngine.sqlite);
      expect(sql, contains('WHERE 1=0'));
    });

    test('PostgreSQL filtra schemas de sistema por padrão', () {
      final sql = dbRoutinesSql(DbEngine.postgres);
      expect(sql, contains('information_schema.routines'));
      expect(sql, contains("routine_schema NOT IN ('pg_catalog', 'information_schema')"));
    });

    test('MySQL e MSSQL extraem rotinas estruturadas', () {
      expect(dbRoutinesSql(DbEngine.mysql), contains('information_schema.ROUTINES'));
      expect(dbRoutinesSql(DbEngine.mssql), contains('INFORMATION_SCHEMA.ROUTINES'));
    });
  });

  group('dbViewDefinitionSql - Definição SQL de Views (B01)', () {
    test('SQLite busca definição em sqlite_master', () {
      final sql = dbViewDefinitionSql(DbEngine.sqlite, view: 'active_users');
      expect(sql, equals('SELECT sql AS "definition" FROM sqlite_master WHERE type = \'view\' AND name = \'active_users\''));
    });

    test('PostgreSQL busca view_definition em information_schema.views', () {
      final sql = dbViewDefinitionSql(DbEngine.postgres, view: 'v_orders', schema: 'public');
      expect(sql, contains('information_schema.views'));
      expect(sql, contains("table_name = 'v_orders'"));
    });
  });
}
