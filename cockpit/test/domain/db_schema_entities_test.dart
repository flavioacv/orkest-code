import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_schema_entities.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

void main() {
  group('SchemaIndex - Entidade', () {
    test('igualdade estrutural por valor e colunas', () {
      const idx1 = SchemaIndex(
        name: 'idx_user_email',
        table: 'users',
        columns: ['email'],
        isUnique: true,
      );

      const idx2 = SchemaIndex(
        name: 'idx_user_email',
        table: 'users',
        columns: ['email'],
        isUnique: true,
      );

      const idx3 = SchemaIndex(
        name: 'idx_user_email',
        table: 'users',
        columns: ['email', 'active'],
        isUnique: true,
      );

      expect(idx1, equals(idx2));
      expect(idx1.hashCode, equals(idx2.hashCode));
      expect(idx1, isNot(equals(idx3)));
    });
  });

  group('SchemaForeignKey - Entidade', () {
    test('igualdade estrutural e campos', () {
      const fk1 = SchemaForeignKey(
        name: 'fk_order_user',
        table: 'orders',
        column: 'user_id',
        referencedTable: 'users',
        referencedColumn: 'id',
        onDelete: 'CASCADE',
      );

      const fk2 = SchemaForeignKey(
        name: 'fk_order_user',
        table: 'orders',
        column: 'user_id',
        referencedTable: 'users',
        referencedColumn: 'id',
        onDelete: 'CASCADE',
      );

      expect(fk1, equals(fk2));
      expect(fk1.hashCode, equals(fk2.hashCode));
      expect(fk1.onDelete, equals('CASCADE'));
    });
  });

  group('SchemaRoutine - Entidade', () {
    test('distingue function e procedure', () {
      const fn = SchemaRoutine(
        name: 'calculate_tax',
        schema: 'public',
        type: 'function',
        returnType: 'numeric',
      );

      const sp = SchemaRoutine(
        name: 'purge_logs',
        schema: 'public',
        type: 'procedure',
      );

      expect(fn.isFunction, isTrue);
      expect(fn.isProcedure, isFalse);
      expect(sp.isProcedure, isTrue);
      expect(sp.isFunction, isFalse);
    });
  });

  group('SchemaTableDetail - Agregação', () {
    test('armazena colunas, índices e foreign keys associadas', () {
      const table = SchemaTable('products', schema: 'public');
      const detail = SchemaTableDetail(
        table: table,
        columns: [
          SchemaColumn('id', 'integer', primaryKey: true),
          SchemaColumn('name', 'text'),
        ],
        indexes: [
          SchemaIndex(
            name: 'idx_products_name',
            table: 'products',
            columns: ['name'],
          ),
        ],
        foreignKeys: [],
      );

      expect(detail.table.name, equals('products'));
      expect(detail.columns.length, equals(2));
      expect(detail.indexes.length, equals(1));
      expect(detail.foreignKeys.isEmpty, isTrue);
    });
  });
}
