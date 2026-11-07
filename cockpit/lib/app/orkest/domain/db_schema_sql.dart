import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';

/// SQL de introspecção de schema por engine (tabelas quando [table] é null;
/// colunas de [table] caso contrário). Compartilhado pelo driver local
/// ([AnakiDbDriver]) e pelo caminho remoto (plano 58, Wave 4). SQL-only.
String dbSchemaSql(DbEngine engine, {String? table, String? schema}) {
  final t = table == null ? null : _safeIdent(table);
  switch (engine) {
    case DbEngine.sqlite:
      return t == null
          ? 'SELECT name AS "table", NULL AS "schema", type '
                'FROM sqlite_master '
                "WHERE type IN ('table','view') AND name NOT LIKE 'sqlite_%' "
                'ORDER BY name'
          : 'SELECT name AS "column", type, '
                '(CASE "notnull" WHEN 0 THEN 1 ELSE 0 END) AS nullable, '
                'pk AS "primaryKey" FROM pragma_table_info(\'$t\')';
    case DbEngine.postgres:
      final s = _safeIdent(schema ?? 'public');
      return t == null
          ? 'SELECT table_name AS "table", table_schema AS "schema", '
                "CASE table_type WHEN 'VIEW' THEN 'view' ELSE 'table' END "
                'AS type FROM information_schema.tables '
                "WHERE table_schema NOT IN ('pg_catalog','information_schema')"
                ' ORDER BY table_schema, table_name'
          : 'SELECT c.column_name AS "column", c.data_type AS type, '
                "CASE WHEN c.is_nullable = 'YES' THEN 1 ELSE 0 END "
                'AS nullable, '
                'CASE WHEN pk.column_name IS NULL THEN 0 ELSE 1 END '
                'AS "primaryKey" '
                'FROM information_schema.columns c '
                'LEFT JOIN ('
                ' SELECT kcu.column_name '
                ' FROM information_schema.table_constraints tc '
                ' JOIN information_schema.key_column_usage kcu '
                '   ON kcu.constraint_name = tc.constraint_name '
                '  AND kcu.table_schema = tc.table_schema '
                " WHERE tc.constraint_type = 'PRIMARY KEY' "
                "  AND tc.table_schema = '$s' AND tc.table_name = '$t'"
                ') pk ON pk.column_name = c.column_name '
                "WHERE c.table_schema = '$s' AND c.table_name = '$t' "
                'ORDER BY c.ordinal_position';
    case DbEngine.mysql:
      return t == null
          ? 'SELECT table_name AS `table`, table_schema AS `schema`, '
                "CASE table_type WHEN 'VIEW' THEN 'view' ELSE 'table' END "
                'AS type FROM information_schema.tables '
                'WHERE table_schema = DATABASE() ORDER BY table_name'
          : 'SELECT column_name AS `column`, data_type AS type, '
                "CASE is_nullable WHEN 'YES' THEN 1 ELSE 0 END AS nullable, "
                "CASE column_key WHEN 'PRI' THEN 1 ELSE 0 END "
                'AS `primaryKey` FROM information_schema.columns '
                "WHERE table_schema = DATABASE() AND table_name = '$t' "
                'ORDER BY ordinal_position';
    case DbEngine.clickhouse:
      final s = _safeIdent(schema ?? 'default');
      return t == null
          ? 'SELECT name AS "table", database AS "schema", '
                "CASE WHEN is_temporary THEN 'view' ELSE 'table' END AS type "
                'FROM system.tables '
                "WHERE database NOT IN ('system', 'information_schema') "
                'ORDER BY database, name'
          : 'SELECT name AS "column", type, '
                'CASE WHEN startsWith(type, \'Nullable\') THEN 1 ELSE 0 END AS nullable, '
                'is_in_primary_key AS "primaryKey" '
                'FROM system.columns '
                "WHERE database = '$s' AND table = '$t' "
                'ORDER BY position';
    case DbEngine.mssql:
      final s = _safeIdent(schema ?? 'dbo');
      return t == null
          ? 'SELECT TABLE_NAME AS [table], TABLE_SCHEMA AS [schema], '
                "CASE TABLE_TYPE WHEN 'VIEW' THEN 'view' ELSE 'table' END "
                'AS type FROM INFORMATION_SCHEMA.TABLES '
                'ORDER BY TABLE_SCHEMA, TABLE_NAME'
          : 'SELECT c.COLUMN_NAME AS [column], c.DATA_TYPE AS type, '
                "CASE c.IS_NULLABLE WHEN 'YES' THEN 1 ELSE 0 END "
                'AS nullable, '
                'CASE WHEN pk.COLUMN_NAME IS NULL THEN 0 ELSE 1 END '
                'AS [primaryKey] '
                'FROM INFORMATION_SCHEMA.COLUMNS c '
                'LEFT JOIN ('
                ' SELECT ku.COLUMN_NAME '
                ' FROM INFORMATION_SCHEMA.TABLE_CONSTRAINTS tc '
                ' JOIN INFORMATION_SCHEMA.KEY_COLUMN_USAGE ku '
                '   ON ku.CONSTRAINT_NAME = tc.CONSTRAINT_NAME '
                '  AND ku.TABLE_SCHEMA = tc.TABLE_SCHEMA '
                " WHERE tc.CONSTRAINT_TYPE = 'PRIMARY KEY' "
                "  AND tc.TABLE_SCHEMA = '$s' AND tc.TABLE_NAME = '$t'"
                ') pk ON pk.COLUMN_NAME = c.COLUMN_NAME '
                "WHERE c.TABLE_SCHEMA = '$s' AND c.TABLE_NAME = '$t' "
                'ORDER BY c.ORDINAL_POSITION';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'Schema introspection is SQL-only.',
      );
  }
}

/// SQL de introspecção de índices para uma tabela específica (B01).
String dbIndexesSql(DbEngine engine, {required String table, String? schema}) {
  final t = _safeIdent(table);
  switch (engine) {
    case DbEngine.sqlite:
      return 'PRAGMA index_list(\'$t\')';
    case DbEngine.postgres:
      final s = _safeIdent(schema ?? 'public');
      return 'SELECT indexname AS "name", '
          'CASE WHEN indisunique THEN 1 ELSE 0 END AS "isUnique", '
          'CASE WHEN indisprimary THEN 1 ELSE 0 END AS "isPrimary", '
          'indkey::text AS "columns" '
          'FROM pg_indexes '
          'JOIN pg_class c ON c.relname = indexname '
          'JOIN pg_index i ON i.indexrelid = c.oid '
          "WHERE schemaname = '$s' AND tablename = '$t' "
          'ORDER BY indexname';
    case DbEngine.mysql:
      return 'SHOW INDEX FROM `$t`';
    case DbEngine.mssql:
      final s = _safeIdent(schema ?? 'dbo');
      return 'SELECT i.name AS [name], '
          'i.is_unique AS [isUnique], '
          'i.is_primary_key AS [isPrimary] '
          'FROM sys.indexes i '
          'INNER JOIN sys.tables t ON t.object_id = i.object_id '
          'INNER JOIN sys.schemas s ON s.schema_id = t.schema_id '
          "WHERE s.name = '$s' AND t.name = '$t' AND i.name IS NOT NULL "
          'ORDER BY i.name';
    case DbEngine.clickhouse:
      return 'SELECT \'\' AS "name", 0 AS "isUnique", 0 AS "isPrimary", \'\' AS "columns" WHERE 1=0';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'Indexes introspection is SQL-only.',
      );
  }
}

/// SQL de introspecção de chaves estrangeiras para uma tabela específica (B01).
String dbForeignKeysSql(DbEngine engine, {required String table, String? schema}) {
  final t = _safeIdent(table);
  switch (engine) {
    case DbEngine.sqlite:
      return 'PRAGMA foreign_key_list(\'$t\')';
    case DbEngine.postgres:
      final s = _safeIdent(schema ?? 'public');
      return 'SELECT tc.constraint_name AS "name", '
          'kcu.column_name AS "column", '
          'ccu.table_name AS "referencedTable", '
          'ccu.column_name AS "referencedColumn", '
          'rc.delete_rule AS "onDelete", '
          'rc.update_rule AS "onUpdate" '
          'FROM information_schema.table_constraints tc '
          'JOIN information_schema.key_column_usage kcu '
          '  ON tc.constraint_name = kcu.constraint_name '
          '  AND tc.table_schema = kcu.table_schema '
          'JOIN information_schema.referential_constraints rc '
          '  ON rc.constraint_name = tc.constraint_name '
          '  AND rc.constraint_schema = tc.table_schema '
          'JOIN information_schema.constraint_column_usage ccu '
          '  ON ccu.constraint_name = tc.constraint_name '
          '  AND ccu.table_schema = tc.table_schema '
          "WHERE tc.constraint_type = 'FOREIGN KEY' "
          "  AND tc.table_schema = '$s' AND tc.table_name = '$t'";
    case DbEngine.mysql:
      return 'SELECT CONSTRAINT_NAME AS `name`, '
          'COLUMN_NAME AS `column`, '
          'REFERENCED_TABLE_NAME AS `referencedTable`, '
          'REFERENCED_COLUMN_NAME AS `referencedColumn` '
          'FROM information_schema.KEY_COLUMN_USAGE '
          'WHERE TABLE_SCHEMA = DATABASE() '
          "  AND TABLE_NAME = '$t' AND REFERENCED_TABLE_NAME IS NOT NULL";
    case DbEngine.mssql:
      final s = _safeIdent(schema ?? 'dbo');
      return 'SELECT fk.name AS [name], '
          'c1.name AS [column], '
          't2.name AS [referencedTable], '
          'c2.name AS [referencedColumn], '
          'fk.delete_referential_action_desc AS [onDelete], '
          'fk.update_referential_action_desc AS [onUpdate] '
          'FROM sys.foreign_keys fk '
          'INNER JOIN sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id '
          'INNER JOIN sys.tables t1 ON t1.object_id = fkc.parent_object_id '
          'INNER JOIN sys.schemas s ON s.schema_id = t1.schema_id '
          'INNER JOIN sys.columns c1 ON c1.object_id = fkc.parent_object_id AND c1.column_id = fkc.parent_column_id '
          'INNER JOIN sys.tables t2 ON t2.object_id = fkc.referenced_object_id '
          'INNER JOIN sys.columns c2 ON c2.object_id = fkc.referenced_object_id AND c2.column_id = fkc.referenced_column_id '
          "WHERE s.name = '$s' AND t1.name = '$t'";
    case DbEngine.clickhouse:
      return 'SELECT \'\' AS "name", \'\' AS "column", \'\' AS "referencedTable", \'\' AS "referencedColumn", \'\' AS "onDelete", \'\' AS "onUpdate" WHERE 1=0';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'Foreign keys introspection is SQL-only.',
      );
  }
}

/// SQL de introspecção de rotinas (funções e procedures) por engine (B01).
String dbRoutinesSql(DbEngine engine, {String? schema}) {
  switch (engine) {
    case DbEngine.sqlite:
      // SQLite não tem rotinas/stored procedures nativas
      return "SELECT '' AS \"name\", '' AS \"schema\", '' AS \"type\" WHERE 1=0";
    case DbEngine.postgres:
      final s = schema != null ? _safeIdent(schema) : null;
      final schemaFilter = s != null
          ? "routine_schema = '$s'"
          : "routine_schema NOT IN ('pg_catalog', 'information_schema')";
      return 'SELECT routine_name AS "name", '
          'routine_schema AS "schema", '
          'LOWER(routine_type) AS "type", '
          'data_type AS "returnType" '
          'FROM information_schema.routines '
          'WHERE $schemaFilter '
          'ORDER BY routine_schema, routine_name';
    case DbEngine.mysql:
      return 'SELECT ROUTINE_NAME AS `name`, '
          'ROUTINE_SCHEMA AS `schema`, '
          'LOWER(ROUTINE_TYPE) AS `type`, '
          'DATA_TYPE AS `returnType` '
          'FROM information_schema.ROUTINES '
          'WHERE ROUTINE_SCHEMA = DATABASE() '
          'ORDER BY ROUTINE_NAME';
    case DbEngine.mssql:
      final s = schema != null ? _safeIdent(schema) : null;
      final schemaFilter = s != null ? "ROUTINE_SCHEMA = '$s'" : '1=1';
      return 'SELECT ROUTINE_NAME AS [name], '
          'ROUTINE_SCHEMA AS [schema], '
          'LOWER(ROUTINE_TYPE) AS [type], '
          'DATA_TYPE AS [returnType] '
          'FROM INFORMATION_SCHEMA.ROUTINES '
          'WHERE $schemaFilter '
          'ORDER BY ROUTINE_SCHEMA, ROUTINE_NAME';
    case DbEngine.clickhouse:
      return 'SELECT name AS "name", \'system\' AS "schema", \'function\' AS "type", \'\' AS "returnType" FROM system.functions ORDER BY name';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'Routines introspection is SQL-only.',
      );
  }
}

/// SQL de introspecção da definição textual de uma view (B01).
String dbViewDefinitionSql(DbEngine engine, {required String view, String? schema}) {
  final v = _safeIdent(view);
  switch (engine) {
    case DbEngine.sqlite:
      return 'SELECT sql AS "definition" FROM sqlite_master WHERE type = \'view\' AND name = \'$v\'';
    case DbEngine.postgres:
      final s = _safeIdent(schema ?? 'public');
      return 'SELECT view_definition AS "definition" FROM information_schema.views '
          "WHERE table_schema = '$s' AND table_name = '$v'";
    case DbEngine.mysql:
      return 'SELECT VIEW_DEFINITION AS `definition` FROM information_schema.VIEWS '
          "WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = '$v'";
    case DbEngine.mssql:
      final s = _safeIdent(schema ?? 'dbo');
      return 'SELECT VIEW_DEFINITION AS [definition] FROM INFORMATION_SCHEMA.VIEWS '
          "WHERE TABLE_SCHEMA = '$s' AND TABLE_NAME = '$v'";
    case DbEngine.clickhouse:
      final s = _safeIdent(schema ?? 'default');
      return 'SELECT create_table_query AS "definition" FROM system.tables WHERE database = \'$s\' AND name = \'$v\'';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'View definition introspection is SQL-only.',
      );
  }
}

/// Gera a query de plano de execução (EXPLAIN) contextual para [query] (B03).
///
/// Se [analyze] for true, requisita execução real com métricas detalhadas
/// onde suportado nativamente (PostgreSQL, MySQL).
String dbExplainSql(DbEngine engine, String query, {bool analyze = false}) {
  final clean = query.trim().replaceAll(RegExp(r';\s*$'), '');
  if (clean.isEmpty) {
    throw const DbQueryException('invalid_query', 'Query cannot be empty for explain.');
  }
  switch (engine) {
    case DbEngine.sqlite:
      return 'EXPLAIN QUERY PLAN $clean;';
    case DbEngine.postgres:
      return analyze
          ? 'EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS) $clean;'
          : 'EXPLAIN $clean;';
    case DbEngine.mysql:
      return analyze ? 'EXPLAIN ANALYZE $clean;' : 'EXPLAIN $clean;';
    case DbEngine.mssql:
      return analyze
          ? 'SET STATISTICS PROFILE ON;\n$clean;\nSET STATISTICS PROFILE OFF;'
          : 'SET SHOWPLAN_TEXT ON;\n$clean;\nSET SHOWPLAN_TEXT OFF;';
    case DbEngine.clickhouse:
      return 'EXPLAIN $clean;';
    case DbEngine.redis:
    case DbEngine.mongo:
      throw const DbQueryException(
        'unsupported_engine',
        'Explain plan is SQL-only.',
      );
  }
}

/// Identificador seguro pra interpolar (tabela/schema): só
/// palavra/dígito/underscore/ponto/cifrão.
String _safeIdent(String name) {
  if (!RegExp(r'^[A-Za-z0-9_.$]+$').hasMatch(name)) {
    throw DbQueryException('query_failed', 'Invalid table name: "$name"');
  }
  return name;
}
