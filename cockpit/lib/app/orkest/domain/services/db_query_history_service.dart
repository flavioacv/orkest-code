import 'package:orkest_code/app/orkest/domain/entities/db_query_history_entry.dart';

/// Serviço de gerenciamento do histórico de consultas executadas (B03).
class DbQueryHistoryService {
  DbQueryHistoryService({this.maxEntries = 100});

  final int maxEntries;
  final List<DbQueryHistoryEntry> _entries = [];
  int _sequence = 0;

  /// Retorna as entradas ordenadas da mais recente para a mais antiga.
  List<DbQueryHistoryEntry> entries({String? connName, String? search}) {
    var result = _entries.reversed.toList();
    if (connName != null && connName.isNotEmpty) {
      result = result.where((e) => e.connName == connName).toList();
    }
    if (search != null && search.isNotEmpty) {
      final term = search.toLowerCase();
      result = result
          .where((e) =>
              e.sql.toLowerCase().contains(term) ||
              e.connName.toLowerCase().contains(term))
          .toList();
    }
    return result;
  }

  /// Adiciona uma nova entrada de execução ao histórico.
  DbQueryHistoryEntry record({
    required String connName,
    required String sql,
    required Duration elapsed,
    int rowCount = 0,
    int? affectedRows,
    String? error,
  }) {
    _sequence++;
    final entry = DbQueryHistoryEntry(
      id: '${DateTime.now().millisecondsSinceEpoch}_$_sequence',
      connName: connName,
      sql: sql.trim(),
      timestamp: DateTime.now(),
      elapsed: elapsed,
      rowCount: rowCount,
      affectedRows: affectedRows,
      error: error,
    );

    _entries.add(entry);
    if (_entries.length > maxEntries) {
      _entries.removeRange(0, _entries.length - maxEntries);
    }
    return entry;
  }

  /// Limpa o histórico de uma conexão específica ou de todas.
  void clear({String? connName}) {
    if (connName != null) {
      _entries.removeWhere((e) => e.connName == connName);
    } else {
      _entries.clear();
    }
  }

  /// Tamanho atual do histórico.
  int get length => _entries.length;
}
