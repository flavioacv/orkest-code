import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/orkest/domain/services/db_transaction_session.dart';

void main() {
  group('DbTransactionSession - Ciclo de Vida da Transação (B02)', () {
    const conn = DbConnection(
      name: 'test_db',
      engine: DbEngine.sqlite,
      origin: DbConnectionOrigin.registered,
      url: 'sqlite://test.db',
    );

    test('executa comandos, preserva histórico e faz commit com sucesso', () async {
      final executedSqls = <String>[];

      Future<DbResult> mockExecutor(String sql) async {
        executedSqls.add(sql);
        return const DbResult(columns: [], rows: [], elapsed: Duration.zero);
      }

      final session = DbTransactionSession(
        id: 'tx-1',
        conn: conn,
        workspaceRoot: '.',
        workspaceId: 'ws-1',
        executor: mockExecutor,
      );

      expect(session.isActive, isTrue);
      expect(session.state, equals(DbTransactionState.active));

      await session.execute('INSERT INTO users (name) VALUES (\'Alice\');');
      await session.execute('UPDATE accounts SET balance = balance - 100;');

      expect(session.history.length, equals(2));
      expect(executedSqls.length, equals(2));

      await session.commit();

      expect(session.isActive, isFalse);
      expect(session.state, equals(DbTransactionState.committed));
      expect(executedSqls.last, equals('COMMIT;'));
    });

    test('reverte comandos via rollback explícito', () async {
      final executedSqls = <String>[];

      Future<DbResult> mockExecutor(String sql) async {
        executedSqls.add(sql);
        return const DbResult(columns: [], rows: [], elapsed: Duration.zero);
      }

      final session = DbTransactionSession(
        id: 'tx-2',
        conn: conn,
        workspaceRoot: '.',
        workspaceId: 'ws-1',
        executor: mockExecutor,
      );

      await session.execute('DELETE FROM users WHERE id = 10;');
      await session.rollback();

      expect(session.isActive, isFalse);
      expect(session.state, equals(DbTransactionState.rolledBack));
      expect(executedSqls.last, equals('ROLLBACK;'));
    });

    test('timeout automático dispara rollback e encerra sessão', () async {
      final executedSqls = <String>[];

      Future<DbResult> mockExecutor(String sql) async {
        executedSqls.add(sql);
        return const DbResult(columns: [], rows: [], elapsed: Duration.zero);
      }

      final session = DbTransactionSession(
        id: 'tx-3',
        conn: conn,
        workspaceRoot: '.',
        workspaceId: 'ws-1',
        executor: mockExecutor,
        timeout: const Duration(milliseconds: 50),
      );

      await session.execute('UPDATE settings SET maintenance = 1;');

      // Aguarda expiração do timeout
      await Future.delayed(const Duration(milliseconds: 80));

      expect(session.isActive, isFalse);
      expect(session.state, equals(DbTransactionState.timedOut));
      expect(executedSqls.contains('ROLLBACK;'), isTrue);

      // Nova execução deve ser recusada
      expect(
        () => session.execute('SELECT 1;'),
        throwsA(isA<DbQueryException>()),
      );
    });

    test('dispose dispara rollback preventivo se sessão ainda estiver ativa', () async {
      final executedSqls = <String>[];

      Future<DbResult> mockExecutor(String sql) async {
        executedSqls.add(sql);
        return const DbResult(columns: [], rows: [], elapsed: Duration.zero);
      }

      final session = DbTransactionSession(
        id: 'tx-4',
        conn: conn,
        workspaceRoot: '.',
        workspaceId: 'ws-1',
        executor: mockExecutor,
      );

      await session.execute('INSERT INTO logs (text) VALUES (\'uncommitted\');');
      await session.dispose();

      expect(session.isActive, isFalse);
      expect(session.state, equals(DbTransactionState.rolledBack));
      expect(executedSqls.last, equals('ROLLBACK;'));
    });
  });
}
