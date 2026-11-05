import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/services/db_ddl_generator.dart';

/// Exceção lançada quando uma edição de dados viola pré-condições de segurança.
class DbEditException implements Exception {
  const DbEditException(this.message);
  final String message;

  @override
  String toString() => 'DbEditException: $message';
}

/// Serviço de geração de instruções DML seguras para edição persistente de dados
/// com verificação de chave primária e controle de concorrência otimista (B02).
class DbRowEditService {
  const DbRowEditService();

  /// Formata um valor de dado para expressão SQL segura.
  static String formatLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is num || value is bool) return value.toString();
    final str = value.toString();
    return "'${str.replaceAll("'", "''")}'";
  }

  /// Gera um `UPDATE` seguro com concorrência otimista.
  ///
  /// Exige que [pkColumns] e [pkValues] não estejam vazios.
  /// Inclui [oldValue] no `WHERE` para evitar sobrescrever edições concorrentes.
  String generateOptimisticUpdateSql({
    required DbEngine engine,
    required String table,
    String? schema,
    required List<String> pkColumns,
    required List<Object?> pkValues,
    required String modifiedColumn,
    required Object? oldValue,
    required Object? newValue,
  }) {
    if (pkColumns.isEmpty || pkColumns.length != pkValues.length) {
      throw const DbEditException(
        'Edição recusada: a tabela precisa ter chave primária (PK) definida para atualização segura.',
      );
    }

    final qTable = DbDdlGenerator.quoteIdentifier(engine, table);
    final tableName = schema != null && schema.isNotEmpty && engine != DbEngine.sqlite
        ? '${DbDdlGenerator.quoteIdentifier(engine, schema)}.$qTable'
        : qTable;

    final qCol = DbDdlGenerator.quoteIdentifier(engine, modifiedColumn);
    final valNew = formatLiteral(newValue);

    final whereClauses = <String>[];

    // 1. Condições de Primary Key
    for (var i = 0; i < pkColumns.length; i++) {
      final col = DbDdlGenerator.quoteIdentifier(engine, pkColumns[i]);
      final val = formatLiteral(pkValues[i]);
      whereClauses.add('$col = $val');
    }

    // 2. Concorrência otimista: valida se o valor anterior ainda é o mesmo
    if (oldValue == null) {
      whereClauses.add('$qCol IS NULL');
    } else {
      whereClauses.add('$qCol = ${formatLiteral(oldValue)}');
    }

    return 'UPDATE $tableName SET $qCol = $valNew WHERE ${whereClauses.join(' AND ')};';
  }

  /// Gera um `DELETE` seguro de linha exigindo a chave primária.
  String generateRowDeleteSql({
    required DbEngine engine,
    required String table,
    String? schema,
    required List<String> pkColumns,
    required List<Object?> pkValues,
  }) {
    if (pkColumns.isEmpty || pkColumns.length != pkValues.length) {
      throw const DbEditException(
        'Exclusão recusada: a tabela precisa ter chave primária (PK) definida para deleção segura.',
      );
    }

    final qTable = DbDdlGenerator.quoteIdentifier(engine, table);
    final tableName = schema != null && schema.isNotEmpty && engine != DbEngine.sqlite
        ? '${DbDdlGenerator.quoteIdentifier(engine, schema)}.$qTable'
        : qTable;

    final whereClauses = <String>[];
    for (var i = 0; i < pkColumns.length; i++) {
      final col = DbDdlGenerator.quoteIdentifier(engine, pkColumns[i]);
      final val = formatLiteral(pkValues[i]);
      whereClauses.add('$col = $val');
    }

    return 'DELETE FROM $tableName WHERE ${whereClauses.join(' AND ')};';
  }

  /// Gera um `INSERT` seguro para inserção de novo registro.
  String generateRowInsertSql({
    required DbEngine engine,
    required String table,
    String? schema,
    required Map<String, Object?> columnValues,
  }) {
    if (columnValues.isEmpty) {
      throw const DbEditException('Inserção recusada: nenhum valor fornecido.');
    }

    final qTable = DbDdlGenerator.quoteIdentifier(engine, table);
    final tableName = schema != null && schema.isNotEmpty && engine != DbEngine.sqlite
        ? '${DbDdlGenerator.quoteIdentifier(engine, schema)}.$qTable'
        : qTable;

    final cols = columnValues.keys
        .map((c) => DbDdlGenerator.quoteIdentifier(engine, c))
        .join(', ');
    final vals = columnValues.values.map(formatLiteral).join(', ');

    return 'INSERT INTO $tableName ($cols) VALUES ($vals);';
  }
}
