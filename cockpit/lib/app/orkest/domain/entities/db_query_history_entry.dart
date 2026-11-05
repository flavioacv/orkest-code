/// Entrada de histórico de consultas SQL executadas (B03).
class DbQueryHistoryEntry {
  const DbQueryHistoryEntry({
    required this.id,
    required this.connName,
    required this.sql,
    required this.timestamp,
    required this.elapsed,
    this.rowCount = 0,
    this.affectedRows,
    this.error,
  });

  final String id;
  final String connName;
  final String sql;
  final DateTime timestamp;
  final Duration elapsed;
  final int rowCount;
  final int? affectedRows;
  final String? error;

  bool get isSuccess => error == null;

  Map<String, Object?> toJson() => {
    'id': id,
    'connName': connName,
    'sql': sql,
    'timestamp': timestamp.toIso8601String(),
    'elapsedMs': elapsed.inMilliseconds,
    'rowCount': rowCount,
    if (affectedRows != null) 'affectedRows': affectedRows,
    if (error != null) 'error': error,
  };

  factory DbQueryHistoryEntry.fromJson(Map<String, Object?> json) {
    return DbQueryHistoryEntry(
      id: json['id'] as String,
      connName: json['connName'] as String,
      sql: json['sql'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      elapsed: Duration(milliseconds: json['elapsedMs'] as int? ?? 0),
      rowCount: json['rowCount'] as int? ?? 0,
      affectedRows: json['affectedRows'] as int?,
      error: json['error'] as String?,
    );
  }
}
