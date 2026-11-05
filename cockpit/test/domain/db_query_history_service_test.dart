import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/db_query_history_service.dart';

void main() {
  group('DbQueryHistoryService (B03)', () {
    late DbQueryHistoryService history;

    setUp(() {
      history = DbQueryHistoryService(maxEntries: 3);
    });

    test('records queries and returns entries sorted newest-first', () {
      history.record(
        connName: 'pg_prod',
        sql: 'SELECT 1;',
        elapsed: const Duration(milliseconds: 10),
        rowCount: 1,
      );
      history.record(
        connName: 'pg_prod',
        sql: 'SELECT 2;',
        elapsed: const Duration(milliseconds: 20),
        rowCount: 1,
      );

      final list = history.entries();
      expect(list.length, 2);
      expect(list[0].sql, 'SELECT 2;');
      expect(list[1].sql, 'SELECT 1;');
      expect(list[0].isSuccess, isTrue);
    });

    test('respects maxEntries cap with FIFO eviction', () {
      history.record(
        connName: 'conn',
        sql: 'QUERY 1',
        elapsed: Duration.zero,
      );
      history.record(
        connName: 'conn',
        sql: 'QUERY 2',
        elapsed: Duration.zero,
      );
      history.record(
        connName: 'conn',
        sql: 'QUERY 3',
        elapsed: Duration.zero,
      );
      history.record(
        connName: 'conn',
        sql: 'QUERY 4',
        elapsed: Duration.zero,
      );

      expect(history.length, 3);
      final list = history.entries();
      expect(list.map((e) => e.sql).toList(), ['QUERY 4', 'QUERY 3', 'QUERY 2']);
    });

    test('filters entries by connection and search term', () {
      history.record(
        connName: 'sqlite_local',
        sql: 'SELECT * FROM users;',
        elapsed: const Duration(milliseconds: 5),
        rowCount: 10,
      );
      history.record(
        connName: 'mysql_remote',
        sql: 'SELECT * FROM orders WHERE total > 100;',
        elapsed: const Duration(milliseconds: 12),
        rowCount: 5,
      );
      history.record(
        connName: 'sqlite_local',
        sql: 'UPDATE users SET active = 1;',
        elapsed: const Duration(milliseconds: 8),
        affectedRows: 3,
      );

      final sqliteEntries = history.entries(connName: 'sqlite_local');
      expect(sqliteEntries.length, 2);
      expect(sqliteEntries.every((e) => e.connName == 'sqlite_local'), isTrue);

      final searchEntries = history.entries(search: 'orders');
      expect(searchEntries.length, 1);
      expect(searchEntries.first.sql, contains('orders'));
    });

    test('records query errors correctly', () {
      final entry = history.record(
        connName: 'pg_prod',
        sql: 'SELECT * FROM invalid_table;',
        elapsed: const Duration(milliseconds: 15),
        error: 'relation "invalid_table" does not exist',
      );

      expect(entry.isSuccess, isFalse);
      expect(entry.error, contains('invalid_table'));
    });

    test('clears history globally or by connection', () {
      history.record(connName: 'c1', sql: 'SQL 1', elapsed: Duration.zero);
      history.record(connName: 'c2', sql: 'SQL 2', elapsed: Duration.zero);

      history.clear(connName: 'c1');
      expect(history.length, 1);
      expect(history.entries().first.connName, 'c2');

      history.clear();
      expect(history.length, 0);
    });
  });
}
