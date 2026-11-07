import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_schema_entities.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

/// Gerador determinístico de DDL (CREATE TABLE / CREATE VIEW / CREATE INDEX)
/// multi-dialeto para os engines suportados no Orkest Code (B01).
class DbDdlGenerator {
  const DbDdlGenerator();

  /// Envolve identificador com delimitadores adequados ao engine.
  static String quoteIdentifier(DbEngine engine, String identifier) {
    switch (engine) {
      case DbEngine.sqlite:
      case DbEngine.postgres:
      case DbEngine.clickhouse:
        return '"$identifier"';
      case DbEngine.mysql:
        return '`$identifier`';
      case DbEngine.mssql:
        return '[$identifier]';
      case DbEngine.redis:
      case DbEngine.mongo:
        return identifier;
    }
  }

  /// Gera a declaração `CREATE TABLE` completa com colunas, constraints e índices.
  String generateTableDdl({
    required DbEngine engine,
    required String table,
    String? schema,
    required List<SchemaColumn> columns,
    List<SchemaIndex> indexes = const [],
    List<SchemaForeignKey> foreignKeys = const [],
  }) {
    final buffer = StringBuffer();

    // 1. Nome qualificado da tabela
    final qTable = quoteIdentifier(engine, table);
    final tableName = schema != null && schema.isNotEmpty && engine != DbEngine.sqlite
        ? '${quoteIdentifier(engine, schema)}.$qTable'
        : qTable;

    buffer.writeln('CREATE TABLE $tableName (');

    final lines = <String>[];

    // 2. Colunas
    for (final col in columns) {
      final colName = quoteIdentifier(engine, col.name);
      final colType = col.type.toUpperCase();
      final nullable = col.primaryKey ? ' NOT NULL' : '';
      lines.add('  $colName $colType$nullable');
    }

    // 3. Primary Key
    final pkCols = columns.where((c) => c.primaryKey).map((c) => quoteIdentifier(engine, c.name)).toList();
    if (pkCols.isNotEmpty) {
      lines.add('  CONSTRAINT pk_$table PRIMARY KEY (${pkCols.join(', ')})');
    }

    // 4. Foreign Keys
    for (final fk in foreignKeys) {
      final col = quoteIdentifier(engine, fk.column);
      final refTable = quoteIdentifier(engine, fk.referencedTable);
      final refCol = quoteIdentifier(engine, fk.referencedColumn);
      final fkName = quoteIdentifier(engine, fk.name.isNotEmpty ? fk.name : 'fk_${table}_${fk.column}');

      var fkDef = '  CONSTRAINT $fkName FOREIGN KEY ($col) REFERENCES $refTable ($refCol)';
      if (fk.onDelete.isNotEmpty && fk.onDelete != 'NO ACTION') {
        fkDef += ' ON DELETE ${fk.onDelete}';
      }
      if (fk.onUpdate.isNotEmpty && fk.onUpdate != 'NO ACTION') {
        fkDef += ' ON UPDATE ${fk.onUpdate}';
      }
      lines.add(fkDef);
    }

    buffer.writeln(lines.join(',\n'));
    buffer.write(');');

    // 5. Índices adicionais (não primários)
    final secondaryIndexes = indexes.where((idx) => !idx.isPrimary).toList();
    if (secondaryIndexes.isNotEmpty) {
      buffer.writeln('\n');
      for (final idx in secondaryIndexes) {
        final unique = idx.isUnique ? 'UNIQUE ' : '';
        final idxName = quoteIdentifier(engine, idx.name);
        final cols = idx.columns.map((c) => quoteIdentifier(engine, c)).join(', ');
        buffer.writeln('CREATE ${unique}INDEX $idxName ON $tableName ($cols);');
      }
    }

    return buffer.toString().trim();
  }

  /// Gera a declaração `CREATE VIEW`.
  String generateViewDdl({
    required DbEngine engine,
    required String view,
    String? schema,
    required String definition,
  }) {
    final qView = quoteIdentifier(engine, view);
    final viewName = schema != null && schema.isNotEmpty && engine != DbEngine.sqlite
        ? '${quoteIdentifier(engine, schema)}.$qView'
        : qView;

    final cleanDef = definition.trim().replaceAll(RegExp(r';$'), '');
    return 'CREATE VIEW $viewName AS\n$cleanDef;';
  }
}
