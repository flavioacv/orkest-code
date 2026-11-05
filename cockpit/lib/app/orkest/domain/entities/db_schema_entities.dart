import 'package:flutter/foundation.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

/// Representação de um índice de banco de dados.
@immutable
class SchemaIndex {
  const SchemaIndex({
    required this.name,
    required this.table,
    required this.columns,
    this.isUnique = false,
    this.isPrimary = false,
  });

  final String name;
  final String table;
  final List<String> columns;
  final bool isUnique;
  final bool isPrimary;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaIndex &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          table == other.table &&
          listEquals(columns, other.columns) &&
          isUnique == other.isUnique &&
          isPrimary == other.isPrimary;

  @override
  int get hashCode => Object.hash(
        name,
        table,
        Object.hashAll(columns),
        isUnique,
        isPrimary,
      );
}

/// Representação de uma chave estrangeira (Foreign Key).
@immutable
class SchemaForeignKey {
  const SchemaForeignKey({
    required this.name,
    required this.table,
    required this.column,
    required this.referencedTable,
    required this.referencedColumn,
    this.onDelete = 'NO ACTION',
    this.onUpdate = 'NO ACTION',
  });

  final String name;
  final String table;
  final String column;
  final String referencedTable;
  final String referencedColumn;
  final String onDelete;
  final String onUpdate;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaForeignKey &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          table == other.table &&
          column == other.column &&
          referencedTable == other.referencedTable &&
          referencedColumn == other.referencedColumn &&
          onDelete == other.onDelete &&
          onUpdate == other.onUpdate;

  @override
  int get hashCode => Object.hash(
        name,
        table,
        column,
        referencedTable,
        referencedColumn,
        onDelete,
        onUpdate,
      );
}

/// Representação de uma rotina de banco de dados (função ou stored procedure).
@immutable
class SchemaRoutine {
  const SchemaRoutine({
    required this.name,
    this.schema,
    required this.type,
    this.returnType,
    this.definition,
  });

  final String name;
  final String? schema;

  /// Tipo da rotina: `function` ou `procedure`.
  final String type;

  /// Tipo de retorno (ex.: `integer`, `table`, `void`).
  final String? returnType;

  /// Corpo / definição SQL da função se disponível.
  final String? definition;

  bool get isFunction => type.toLowerCase() == 'function';
  bool get isProcedure => type.toLowerCase() == 'procedure';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchemaRoutine &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          schema == other.schema &&
          type == other.type &&
          returnType == other.returnType &&
          definition == other.definition;

  @override
  int get hashCode => Object.hash(name, schema, type, returnType, definition);
}

/// Detalhes enriquecidos de uma tabela com suas colunas, índices e foreign keys.
@immutable
class SchemaTableDetail {
  const SchemaTableDetail({
    required this.table,
    this.columns = const [],
    this.indexes = const [],
    this.foreignKeys = const [],
  });

  final SchemaTable table;
  final List<SchemaColumn> columns;
  final List<SchemaIndex> indexes;
  final List<SchemaForeignKey> foreignKeys;
}
