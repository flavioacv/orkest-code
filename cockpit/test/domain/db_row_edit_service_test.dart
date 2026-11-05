import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/services/db_row_edit_service.dart';

void main() {
  group('DbRowEditService - Edição Persistente Otimista (B02)', () {
    const service = DbRowEditService();

    test('generateOptimisticUpdateSql gera UPDATE com PK e cláusula de concorrência', () {
      final sql = service.generateOptimisticUpdateSql(
        engine: DbEngine.postgres,
        table: 'users',
        schema: 'public',
        pkColumns: ['id'],
        pkValues: [42],
        modifiedColumn: 'email',
        oldValue: 'antigo@exemplo.com',
        newValue: 'novo@exemplo.com',
      );

      expect(sql, contains('UPDATE "public"."users" SET "email" = \'novo@exemplo.com\''));
      expect(sql, contains('WHERE "id" = 42 AND "email" = \'antigo@exemplo.com\';'));
    });

    test('generateOptimisticUpdateSql trata valor antigo nulo com IS NULL', () {
      final sql = service.generateOptimisticUpdateSql(
        engine: DbEngine.sqlite,
        table: 'profiles',
        pkColumns: ['id'],
        pkValues: [1],
        modifiedColumn: 'bio',
        oldValue: null,
        newValue: 'Minha nova bio',
      );

      expect(sql, contains('UPDATE "profiles" SET "bio" = \'Minha nova bio\''));
      expect(sql, contains('WHERE "id" = 1 AND "bio" IS NULL;'));
    });

    test('generateOptimisticUpdateSql suporta chave primária composta', () {
      final sql = service.generateOptimisticUpdateSql(
        engine: DbEngine.mysql,
        table: 'order_items',
        pkColumns: ['order_id', 'item_id'],
        pkValues: [100, 5],
        modifiedColumn: 'quantity',
        oldValue: 2,
        newValue: 3,
      );

      expect(sql, contains('UPDATE `order_items` SET `quantity` = 3'));
      expect(sql, contains('WHERE `order_id` = 100 AND `item_id` = 5 AND `quantity` = 2;'));
    });

    test('generateOptimisticUpdateSql recusa edição em tabelas sem PK definida', () {
      expect(
        () => service.generateOptimisticUpdateSql(
          engine: DbEngine.postgres,
          table: 'logs',
          pkColumns: [],
          pkValues: [],
          modifiedColumn: 'message',
          oldValue: 'a',
          newValue: 'b',
        ),
        throwsA(isA<DbEditException>()),
      );
    });

    test('generateRowDeleteSql exige PK e gera DELETE seguro', () {
      final sql = service.generateRowDeleteSql(
        engine: DbEngine.postgres,
        table: 'customers',
        schema: 'crm',
        pkColumns: ['id'],
        pkValues: [99],
      );

      expect(sql, equals('DELETE FROM "crm"."customers" WHERE "id" = 99;'));

      expect(
        () => service.generateRowDeleteSql(
          engine: DbEngine.sqlite,
          table: 'unkeyed',
          pkColumns: [],
          pkValues: [],
        ),
        throwsA(isA<DbEditException>()),
      );
    });

    test('generateRowInsertSql formata colunas e valores corretamente', () {
      final sql = service.generateRowInsertSql(
        engine: DbEngine.sqlite,
        table: 'products',
        columnValues: {
          'name': 'Teclado Mecânico',
          'price': 299.90,
          'active': true,
        },
      );

      expect(sql, contains('INSERT INTO "products" ("name", "price", "active")'));
      expect(sql, contains("VALUES ('Teclado Mecânico', 299.9, true);"));
    });

    test('formatLiteral escapa aspas simples de forma segura', () {
      expect(DbRowEditService.formatLiteral("O'Reilly"), equals("'O''Reilly'"));
      expect(DbRowEditService.formatLiteral(null), equals('NULL'));
      expect(DbRowEditService.formatLiteral(123), equals('123'));
      expect(DbRowEditService.formatLiteral(true), equals('true'));
    });
  });
}
