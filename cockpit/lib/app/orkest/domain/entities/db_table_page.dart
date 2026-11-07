/// Chave de ordenação para leitura paginada de tabelas (migrado do Open IDEA).
class SortKey {
  final String column;
  final bool ascending;

  const SortKey({
    required this.column,
    this.ascending = true,
  });

  Map<String, dynamic> toJson() => {
    'column': column,
    'ascending': ascending,
  };

  factory SortKey.fromJson(Map<String, dynamic> json) => SortKey(
    column: json['column'] as String,
    ascending: (json['ascending'] as bool?) ?? true,
  );
}

/// Requisição de página de tabela com filtros e ordenação (migrado de `db_table_page`).
class DbTablePageRequest {
  final String connectionName;
  final String schema;
  final String table;
  final String? filter;
  final List<SortKey> sort;
  final int offset;
  final int limit;

  const DbTablePageRequest({
    required this.connectionName,
    required this.schema,
    required this.table,
    this.filter,
    this.sort = const [],
    this.offset = 0,
    this.limit = 50,
  });

  /// Gera a cláusula SQL correspondente à requisição para engines padrão.
  String toSql({required String Function(String) quoteIdentifier}) {
    final sb = StringBuffer();
    final tableRef = schema.isNotEmpty
        ? '${quoteIdentifier(schema)}.${quoteIdentifier(table)}'
        : quoteIdentifier(table);
    sb.write('SELECT * FROM $tableRef');

    if (filter != null && filter!.trim().isNotEmpty) {
      sb.write(' WHERE ${filter!.trim()}');
    }

    if (sort.isNotEmpty) {
      final orderClauses = sort.map((s) =>
          '${quoteIdentifier(s.column)} ${s.ascending ? 'ASC' : 'DESC'}');
      sb.write(' ORDER BY ${orderClauses.join(', ')}');
    }

    sb.write(' LIMIT $limit OFFSET $offset');
    return sb.toString();
  }
}

/// Resultado de página de tabela (migrado de `ide_db::TablePage`).
class DbTablePage {
  final List<String> columns;
  final List<List<dynamic>> rows;
  final int totalRows;
  final int offset;
  final int limit;
  final bool hasMore;

  const DbTablePage({
    required this.columns,
    required this.rows,
    required this.totalRows,
    required this.offset,
    required this.limit,
    required this.hasMore,
  });

  Map<String, dynamic> toJson() => {
    'columns': columns,
    'rows': rows,
    'totalRows': totalRows,
    'offset': offset,
    'limit': limit,
    'hasMore': hasMore,
  };

  factory DbTablePage.fromJson(Map<String, dynamic> json) => DbTablePage(
    columns: (json['columns'] as List<dynamic>).map((e) => e.toString()).toList(),
    rows: (json['rows'] as List<dynamic>)
        .map((r) => (r as List<dynamic>).toList())
        .toList(),
    totalRows: (json['totalRows'] as int?) ?? 0,
    offset: (json['offset'] as int?) ?? 0,
    limit: (json['limit'] as int?) ?? 50,
    hasMore: (json['hasMore'] as bool?) ?? false,
  );
}
