import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

/// Tipo de sugestão de completion SQL.
enum DbSqlCompletionKind {
  keyword,
  table,
  column,
  function,
}

/// Item de completion para o console SQL (B03).
class DbSqlCompletionItem {
  const DbSqlCompletionItem({
    required this.label,
    required this.kind,
    this.detail,
    String? insertText,
  }) : insertText = insertText ?? label;

  final String label;
  final DbSqlCompletionKind kind;
  final String? detail;
  final String insertText;
}

/// Serviço de autocompletion de consultas SQL por schema e contexto (B03).
class DbSqlCompletionService {
  const DbSqlCompletionService();

  static const List<String> defaultKeywords = [
    'SELECT',
    'FROM',
    'WHERE',
    'JOIN',
    'INNER JOIN',
    'LEFT JOIN',
    'RIGHT JOIN',
    'ON',
    'GROUP BY',
    'ORDER BY',
    'HAVING',
    'LIMIT',
    'OFFSET',
    'INSERT INTO',
    'VALUES',
    'UPDATE',
    'SET',
    'DELETE',
    'AND',
    'OR',
    'NOT',
    'IN',
    'LIKE',
    'IS NULL',
    'IS NOT NULL',
    'AS',
    'DISTINCT',
    'UNION',
    'UNION ALL',
    'EXPLAIN',
    'EXPLAIN ANALYZE',
    'CREATE TABLE',
    'DROP TABLE',
  ];

  static const List<String> defaultFunctions = [
    'COUNT',
    'SUM',
    'AVG',
    'MIN',
    'MAX',
    'COALESCE',
    'NOW',
    'LOWER',
    'UPPER',
    'LENGTH',
    'SUBSTR',
    'TRIM',
  ];

  /// Calcula as sugestões para [sql] na posição [cursorOffset].
  List<DbSqlCompletionItem> computeCompletions({
    required String sql,
    required int cursorOffset,
    required List<SchemaTable> tables,
    Map<String, List<SchemaColumn>> tableColumns = const {},
  }) {
    if (cursorOffset < 0 || cursorOffset > sql.length) {
      cursorOffset = sql.length;
    }

    final textBefore = sql.substring(0, cursorOffset);

    // Verifica se há qualificação direta tipo "minha_tabela."
    final dotMatch = RegExp(r'([A-Za-z0-9_]+)\.([A-Za-z0-9_]*)$').firstMatch(textBefore);
    if (dotMatch != null) {
      final tableName = dotMatch.group(1)!;
      final prefix = (dotMatch.group(2) ?? '').toLowerCase();
      final cols = tableColumns[tableName] ?? const [];
      return [
        for (final col in cols)
          if (prefix.isEmpty || col.name.toLowerCase().startsWith(prefix))
            DbSqlCompletionItem(
              label: col.name,
              kind: DbSqlCompletionKind.column,
              detail: col.type,
            ),
      ];
    }

    // Extrai o prefixo da palavra atual
    final wordMatch = RegExp(r'([A-Za-z0-9_]+)$').firstMatch(textBefore);
    final prefix = wordMatch?.group(1)?.toLowerCase() ?? '';

    // Contexto de cláusula anterior
    final clauseContext = _detectClause(textBefore);

    final results = <DbSqlCompletionItem>[];

    // Se está em cláusula FROM ou JOIN, prioriza tabelas
    if (clauseContext == 'FROM' || clauseContext == 'JOIN') {
      for (final t in tables) {
        if (prefix.isEmpty || t.name.toLowerCase().startsWith(prefix)) {
          results.add(
            DbSqlCompletionItem(
              label: t.name,
              kind: DbSqlCompletionKind.table,
              detail: t.isView ? 'view' : (t.schema ?? 'table'),
            ),
          );
        }
      }
    } else {
      // Sugere tabelas conhecidas
      for (final t in tables) {
        if (prefix.isNotEmpty && t.name.toLowerCase().startsWith(prefix)) {
          results.add(
            DbSqlCompletionItem(
              label: t.name,
              kind: DbSqlCompletionKind.table,
              detail: t.isView ? 'view' : (t.schema ?? 'table'),
            ),
          );
        }
      }

      // Sugere colunas de todas as tabelas conhecidas no mapa
      final seenCols = <String>{};
      for (final entry in tableColumns.entries) {
        for (final c in entry.value) {
          if (seenCols.add(c.name)) {
            if (prefix.isEmpty || c.name.toLowerCase().startsWith(prefix)) {
              results.add(
                DbSqlCompletionItem(
                  label: c.name,
                  kind: DbSqlCompletionKind.column,
                  detail: '${entry.key} · ${c.type}',
                ),
              );
            }
          }
        }
      }
    }

    // Palavras-chave SQL
    for (final kw in defaultKeywords) {
      if (prefix.isNotEmpty && kw.toLowerCase().startsWith(prefix)) {
        results.add(
          DbSqlCompletionItem(
            label: kw,
            kind: DbSqlCompletionKind.keyword,
            detail: 'keyword',
          ),
        );
      }
    }

    // Funções SQL comuns
    for (final fn in defaultFunctions) {
      if (prefix.isNotEmpty && fn.toLowerCase().startsWith(prefix)) {
        results.add(
          DbSqlCompletionItem(
            label: '$fn()',
            insertText: '$fn()',
            kind: DbSqlCompletionKind.function,
            detail: 'function',
          ),
        );
      }
    }

    return results;
  }

  static String? _detectClause(String textBefore) {
    final upper = textBefore.toUpperCase();
    final fromPos = upper.lastIndexOf(RegExp(r'\bFROM\s+'));
    final joinPos = upper.lastIndexOf(RegExp(r'\bJOIN\s+'));
    final wherePos = upper.lastIndexOf(RegExp(r'\bWHERE\s+'));
    final selectPos = upper.lastIndexOf(RegExp(r'\bSELECT\s+'));

    final maxPos = [fromPos, joinPos, wherePos, selectPos].reduce((a, b) => a > b ? a : b);
    if (maxPos == -1) return null;
    if (maxPos == fromPos) return 'FROM';
    if (maxPos == joinPos) return 'JOIN';
    if (maxPos == wherePos) return 'WHERE';
    if (maxPos == selectPos) return 'SELECT';
    return null;
  }
}
