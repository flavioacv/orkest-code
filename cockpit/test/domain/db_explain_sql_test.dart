import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/db_schema_sql.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';

void main() {
  group('dbExplainSql (B03)', () {
    test('generates sqlite EXPLAIN QUERY PLAN', () {
      final sql = dbExplainSql(DbEngine.sqlite, 'SELECT * FROM users WHERE id = 1');
      expect(sql, 'EXPLAIN QUERY PLAN SELECT * FROM users WHERE id = 1;');
    });

    test('generates postgres EXPLAIN and EXPLAIN ANALYZE', () {
      final plan = dbExplainSql(DbEngine.postgres, 'SELECT * FROM users');
      expect(plan, 'EXPLAIN SELECT * FROM users;');

      final analyze = dbExplainSql(
        DbEngine.postgres,
        'SELECT * FROM users;',
        analyze: true,
      );
      expect(analyze, 'EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS) SELECT * FROM users;');
    });

    test('generates mysql EXPLAIN and EXPLAIN ANALYZE', () {
      final plan = dbExplainSql(DbEngine.mysql, 'SELECT * FROM orders');
      expect(plan, 'EXPLAIN SELECT * FROM orders;');

      final analyze = dbExplainSql(
        DbEngine.mysql,
        'SELECT * FROM orders',
        analyze: true,
      );
      expect(analyze, 'EXPLAIN ANALYZE SELECT * FROM orders;');
    });

    test('generates mssql SET SHOWPLAN_TEXT and STATISTICS PROFILE', () {
      final plan = dbExplainSql(DbEngine.mssql, 'SELECT * FROM customers');
      expect(plan, contains('SET SHOWPLAN_TEXT ON;'));
      expect(plan, contains('SELECT * FROM customers;'));
      expect(plan, contains('SET SHOWPLAN_TEXT OFF;'));

      final analyze = dbExplainSql(
        DbEngine.mssql,
        'SELECT * FROM customers',
        analyze: true,
      );
      expect(analyze, contains('SET STATISTICS PROFILE ON;'));
      expect(analyze, contains('SET STATISTICS PROFILE OFF;'));
    });

    test('throws DbQueryException on empty query', () {
      expect(
        () => dbExplainSql(DbEngine.sqlite, '   '),
        throwsA(isA<DbQueryException>().having((e) => e.kind, 'kind', 'invalid_query')),
      );
    });

    test('throws DbQueryException on non-SQL engines', () {
      expect(
        () => dbExplainSql(DbEngine.redis, 'KEYS *'),
        throwsA(isA<DbQueryException>().having((e) => e.kind, 'kind', 'unsupported_engine')),
      );
      expect(
        () => dbExplainSql(DbEngine.mongo, 'db.users.find()'),
        throwsA(isA<DbQueryException>().having((e) => e.kind, 'kind', 'unsupported_engine')),
      );
    });
  });
}
