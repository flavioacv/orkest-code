import 'dart:async';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';

/// Estado do ciclo de vida de uma transação de banco de dados (B02).
enum DbTransactionState {
  active,
  committed,
  rolledBack,
  timedOut,
}

/// Sessão dedicada com lease de conexão para transações manuais seguras (B02).
///
/// Garante que `BEGIN`, comandos intermediários e `COMMIT` ou `ROLLBACK` rodem
/// estritamente no mesmo canal e conexão física, prevenindo a falha do modelo
/// efêmero ingênuo onde comandos rodam em conexões independentes.
class DbTransactionSession {
  DbTransactionSession({
    required this.id,
    required this.conn,
    required this.workspaceRoot,
    required this.workspaceId,
    required this.executor,
    this.timeout = const Duration(seconds: 60),
    this.onDispose,
  })  : _startedAt = DateTime.now() {
    _resetTimeoutTimer();
  }

  final String id;
  final DbConnection conn;
  final String workspaceRoot;
  final String workspaceId;
  final Duration timeout;
  final DateTime _startedAt;
  final Future<DbResult> Function(String sql) executor;
  final void Function(DbTransactionSession session)? onDispose;

  DbTransactionState _state = DbTransactionState.active;
  Timer? _timeoutTimer;
  final List<String> _history = [];

  DbTransactionState get state => _state;
  DateTime get startedAt => _startedAt;
  List<String> get history => List.unmodifiable(_history);
  bool get isActive => _state == DbTransactionState.active;

  void _resetTimeoutTimer() {
    _timeoutTimer?.cancel();
    if (!isActive) return;
    _timeoutTimer = Timer(timeout, _handleTimeout);
  }

  Future<void> _handleTimeout() async {
    if (!isActive) return;
    _state = DbTransactionState.timedOut;
    try {
      await executor('ROLLBACK;');
    } catch (_) {}
    _timeoutTimer?.cancel();
    onDispose?.call(this);
  }

  /// Executa uma instrução SQL dentro do escopo da transação ativa.
  Future<DbResult> execute(String sql) async {
    if (!isActive) {
      throw DbQueryException(
        'transaction_inactive',
        'Transação não está mais ativa (estado: ${_state.name}).',
      );
    }

    _resetTimeoutTimer();
    _history.add(sql);

    try {
      return await executor(sql);
    } catch (e) {
      // Falha de execução na transação não fecha automaticamente a menos que explicitado
      rethrow;
    }
  }

  /// Confirma e persiste as alterações da transação (`COMMIT`).
  Future<DbResult> commit() async {
    if (!isActive) {
      throw DbQueryException(
        'transaction_inactive',
        'Não é possível commitar: transação já finalizada (${_state.name}).',
      );
    }

    _timeoutTimer?.cancel();
    try {
      final res = await executor('COMMIT;');
      _state = DbTransactionState.committed;
      return res;
    } catch (e) {
      _state = DbTransactionState.rolledBack;
      await executor('ROLLBACK;').catchError(
        (_) => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );
      rethrow;
    } finally {
      onDispose?.call(this);
    }
  }

  /// Reverte as alterações da transação (`ROLLBACK`).
  Future<DbResult> rollback() async {
    if (!isActive) {
      throw DbQueryException(
        'transaction_inactive',
        'Não é possível reverter: transação já finalizada (${_state.name}).',
      );
    }

    _timeoutTimer?.cancel();
    _state = DbTransactionState.rolledBack;
    try {
      return await executor('ROLLBACK;');
    } finally {
      onDispose?.call(this);
    }
  }

  /// Descarta a sessão garantindo rollback preventivo se ainda estiver ativa.
  Future<void> dispose() async {
    _timeoutTimer?.cancel();
    if (isActive) {
      _state = DbTransactionState.rolledBack;
      try {
        await executor('ROLLBACK;');
      } catch (_) {}
    }
    onDispose?.call(this);
  }
}

