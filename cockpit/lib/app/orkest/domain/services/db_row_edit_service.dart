import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/services/db_ddl_generator.dart';

/// Exceção lançada quando uma edição de dados viola pré-condições de segurança.
class DbEditException implements Exception {
  const DbEditException(this.message);
  final String message;

  @override
  String toString() => 'DbEditException: $message';
}

/// Alvo de tabela identificado a partir de uma consulta SELECT direta.
class EditableTableTarget {
  const EditableTableTarget({required this.table, this.schema});
  final String table;
  final String? schema;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditableTableTarget &&
          runtimeType == other.runtimeType &&
          table == other.table &&
          schema == other.schema;

  @override
  int get hashCode => Object.hash(table, schema);

  @override
  String toString() => schema != null && schema!.isNotEmpty ? '$schema.$table' : table;
}

/// Representação literal de número de alta precisão (ex: DECIMAL/NUMERIC)
/// para evitar perda de precisão em conversões IEEE-754 via double.
class DbRawNumber {
  const DbRawNumber(this.value);
  final String value;

  @override
  String toString() => value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DbRawNumber && runtimeType == other.runtimeType && value == other.value;

  @override
  int get hashCode => value.hashCode;
}

/// Serviço de geração de instruções DML seguras para edição persistente de dados
/// com verificação de chave primária e controle de concorrência otimista (B02).
class DbRowEditService {
  const DbRowEditService();

  /// Identifica a tabela alvo caso [sql] seja uma consulta SELECT direta e
  /// passível de edição segura (sem JOINs, agregações, subqueries, aliases ou agrupamentos).
  ///
  /// Retorna `null` se a query não for um SELECT direto de tabela única.
  EditableTableTarget? extractEditableTable(String sql) {
    var cleaned = _stripComments(sql).trim();
    if (cleaned.endsWith(';')) {
      cleaned = cleaned.substring(0, cleaned.length - 1).trim();
    }
    if (cleaned.isEmpty) return null;

    // 1. Deve ser SELECT
    final selectMatch = RegExp(r'^select\b', caseSensitive: false).firstMatch(cleaned);
    if (selectMatch == null) {
      return null;
    }

    // 2. Rejeita múltiplos SELECTs (subqueries em qualquer trecho do SQL)
    if (RegExp(r'\bselect\b', caseSensitive: false).allMatches(cleaned).length > 1) {
      return null;
    }

    // 3. Não permite DISTINCT, JOIN, GROUP BY, HAVING, UNION, INTERSECT, EXCEPT
    if (RegExp(
      r'\b(distinct|join|group\s+by|having|union|intersect|except)\b',
      caseSensitive: false,
    ).hasMatch(cleaned)) {
      return null;
    }

    // 4. Rejeita parênteses (funções, agregações, subqueries ou expressões)
    if (cleaned.contains('(') || cleaned.contains(')')) {
      return null;
    }

    // 5. Localiza cláusula FROM
    final fromMatch = RegExp(r'\bfrom\b', caseSensitive: false).firstMatch(cleaned);
    if (fromMatch == null || fromMatch.start <= selectMatch.end) return null;

    // 6. Validação estrita da projeção entre SELECT e FROM:
    // Deve ser '*' ou lista de identificadores diretos sem alias ('AS') ou expressões.
    final projectionSection = cleaned.substring(selectMatch.end, fromMatch.start).trim();
    if (projectionSection.isEmpty) return null;

    if (projectionSection != '*') {
      final colItems = projectionSection.split(',');
      for (final rawItem in colItems) {
        if (!_isValidColumnProjection(rawItem)) {
          return null;
        }
      }
    }

    final afterFrom = cleaned.substring(fromMatch.end).trim();
    if (afterFrom.isEmpty) return null;

    // Isola o trecho do FROM até a próxima cláusula principal
    final nextClauseMatch = RegExp(
      r'\b(where|order\s+by|limit|offset|fetch|for\s+update)\b',
      caseSensitive: false,
    ).firstMatch(afterFrom);

    final fromTargetSection = nextClauseMatch == null
        ? afterFrom
        : afterFrom.substring(0, nextClauseMatch.start).trim();

    // Se houver vírgula, indica múltiplos alvos (implicit join)
    if (fromTargetSection.contains(',')) return null;

    final tokens = fromTargetSection.split(RegExp(r'\s+')).where((t) => t.isNotEmpty).toList();
    if (tokens.isEmpty) return null;

    final rawTableIdent = tokens.first;
    final parts = rawTableIdent.split('.');
    if (parts.length == 1) {
      final tbl = _unquote(parts[0]);
      if (tbl.isEmpty) return null;
      return EditableTableTarget(table: tbl);
    } else if (parts.length == 2) {
      final sch = _unquote(parts[0]);
      final tbl = _unquote(parts[1]);
      if (tbl.isEmpty) return null;
      return EditableTableTarget(table: tbl, schema: sch.isEmpty ? null : sch);
    }
    return null;
  }

  static bool _isValidColumnProjection(String raw) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return false;
    // Rejeita aliases explícitos com AS
    if (RegExp(r'\bas\b', caseSensitive: false).hasMatch(trimmed)) return false;
    // Rejeita operadores matemáticos ou de comparação
    if (RegExp(r'[\+\-\*\/\%\&\|\^\=\<\>\!]').hasMatch(trimmed)) return false;

    // Pode ser `coluna` ou `tabela.coluna`
    final parts = trimmed.split('.');
    if (parts.length > 2) return false;
    for (final part in parts) {
      final p = part.trim();
      if (p.isEmpty) return false;
      if ((p.startsWith('"') && p.endsWith('"')) ||
          (p.startsWith('`') && p.endsWith('`')) ||
          (p.startsWith('[') && p.endsWith(']'))) {
        final inner = p.substring(1, p.length - 1);
        if (inner.isEmpty) return false;
      } else {
        // Identificador puro: sem espaços ou caracteres de expressão
        if (!RegExp(r'^[a-zA-Z_][a-zA-Z0-9_]*$').hasMatch(p)) return false;
      }
    }
    return true;
  }

  /// Converte a entrada bruta do usuário em valor tipado de acordo com [columnType]
  /// ou o tipo em tempo de execução de [currentValue], tratando `NULL` explicitamente via toggle.
  /// Lança [DbEditException] para formatos inválidos sem executar query.
  Object? parseValueForColumn({
    required String? rawInput,
    required String columnType,
    required bool isNull,
    Object? currentValue,
  }) {
    if (isNull || rawInput == null) return null;
    final trimmed = rawInput.trim();

    final type = columnType.toUpperCase();
    if (type.contains('INT') || type.contains('SERIAL')) {
      final parsed = int.tryParse(trimmed);
      if (parsed == null) {
        throw DbEditException("Valor '$trimmed' inválido para coluna numérica inteira.");
      }
      return parsed;
    }
    if (type.contains('DECIMAL') || type.contains('NUMERIC')) {
      if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(trimmed)) {
        throw DbEditException("Valor '$trimmed' inválido para coluna numérica/decimal.");
      }
      return DbRawNumber(trimmed);
    }
    if (type.contains('REAL') ||
        type.contains('FLOAT') ||
        type.contains('DOUBLE')) {
      final parsed = num.tryParse(trimmed);
      if (parsed == null) {
        throw DbEditException("Valor '$trimmed' inválido para coluna de ponto flutuante.");
      }
      return parsed;
    }
    if (type.contains('BOOL')) {
      final lower = trimmed.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      throw DbEditException("Valor '$trimmed' inválido para coluna booleana (use true ou false).");
    }

    // Inferência secundária caso o tipo do schema seja genérico/ausente
    if (currentValue is int) {
      final parsed = int.tryParse(trimmed);
      if (parsed == null) {
        throw DbEditException("Valor '$trimmed' inválido para coluna numérica inteira.");
      }
      return parsed;
    } else if (currentValue is DbRawNumber) {
      if (!RegExp(r'^-?\d+(\.\d+)?$').hasMatch(trimmed)) {
        throw DbEditException("Valor '$trimmed' inválido para coluna decimal.");
      }
      return DbRawNumber(trimmed);
    } else if (currentValue is num) {
      final parsed = num.tryParse(trimmed);
      if (parsed == null) {
        throw DbEditException("Valor '$trimmed' inválido para coluna numérica.");
      }
      return parsed;
    } else if (currentValue is bool) {
      final lower = trimmed.toLowerCase();
      if (lower == 'true' || lower == '1') return true;
      if (lower == 'false' || lower == '0') return false;
      throw DbEditException("Valor '$trimmed' inválido para coluna booleana.");
    }

    return rawInput;
  }

  static String _unquote(String s) {
    var str = s.trim();
    if ((str.startsWith('"') && str.endsWith('"')) ||
        (str.startsWith('`') && str.endsWith('`'))) {
      return str.substring(1, str.length - 1);
    }
    if (str.startsWith('[') && str.endsWith(']')) {
      return str.substring(1, str.length - 1);
    }
    return str;
  }

  static String _stripComments(String sql) {
    final sb = StringBuffer();
    var i = 0;
    while (i < sql.length) {
      final c = sql[i];
      if (c == "'" || c == '"' || c == '`') {
        final quote = c;
        sb.write(quote);
        i++;
        while (i < sql.length) {
          final qc = sql[i];
          sb.write(qc);
          if (qc == quote) {
            if (quote == "'" && i + 1 < sql.length && sql[i + 1] == "'") {
              i++;
              sb.write(sql[i]);
            } else {
              break;
            }
          }
          i++;
        }
        i++;
        continue;
      }
      if (c == '-' && i + 1 < sql.length && sql[i + 1] == '-') {
        final nl = sql.indexOf('\n', i);
        i = nl < 0 ? sql.length : nl + 1;
        sb.write(' ');
        continue;
      }
      if (c == '/' && i + 1 < sql.length && sql[i + 1] == '*') {
        final close = sql.indexOf('*/', i + 2);
        i = close < 0 ? sql.length : close + 2;
        sb.write(' ');
        continue;
      }
      sb.write(c);
      i++;
    }
    return sb.toString();
  }

  static final _rawNumberRegex = RegExp(r'^-?\d+(\.\d+)?$');

  /// Formata um valor de dado para expressão SQL segura.
  static String formatLiteral(Object? value) {
    if (value == null) return 'NULL';
    if (value is DbRawNumber) {
      if (!_rawNumberRegex.hasMatch(value.value)) {
        throw DbEditException('DbRawNumber inválido para literal SQL: "${value.value}".');
      }
      return value.value;
    }
    if (value is double) {
      if (value.isNaN || value.isInfinite) {
        throw const DbEditException('Valores NaN ou Infinity não são suportados como literais SQL.');
      }
      return value.toString();
    }
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
