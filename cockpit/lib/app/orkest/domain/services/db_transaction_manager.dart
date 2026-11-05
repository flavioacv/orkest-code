import 'dart:async';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/orkest/domain/services/db_query_service.dart';
import 'package:orkest_code/app/orkest/domain/services/db_transaction_session.dart';

/// Gerenciador central de sessões dedicadas de transação (B02).
class DbTransactionManager {
  DbTransactionManager(this._queryService);

  final DbQueryService _queryService;
  final Map<String, DbTransactionSession> _activeSessions = {};
  int _sequence = 0;

  Map<String, DbTransactionSession> get activeSessions =>
      Map.unmodifiable(_activeSessions);

  /// Inicia uma nova transação dedicada com lease exclusivo de conexão.
  Future<DbTransactionSession> beginTransaction({
    required DbConnection conn,
    required String workspaceRoot,
    required String workspaceId,
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final id = 'tx-${DateTime.now().millisecondsSinceEpoch}-${++_sequence}';

    // Executor que repassa comandos ao DbQueryService preservando o contexto da conexão
    Future<DbResult> executor(String sql) {
      return _queryService.query(
        workspaceRoot: workspaceRoot,
        workspaceId: workspaceId,
        connName: conn.name,
        sql: sql,
        dml: true,
      );
    }

    // Inicia a transação fisicamente
    await executor('BEGIN;');

    final session = DbTransactionSession(
      id: id,
      conn: conn,
      workspaceRoot: workspaceRoot,
      workspaceId: workspaceId,
      executor: executor,
      timeout: timeout,
      onDispose: (s) => _activeSessions.remove(s.id),
    );

    _activeSessions[id] = session;
    return session;
  }

  /// Recupera uma sessão ativa por ID.
  DbTransactionSession? getSession(String id) => _activeSessions[id];

  /// Encerra todas as sessões ativas executando rollback preventivo.
  Future<void> disposeAll() async {
    final sessions = _activeSessions.values.toList();
    _activeSessions.clear();
    for (final s in sessions) {
      await s.dispose();
    }
  }
}
