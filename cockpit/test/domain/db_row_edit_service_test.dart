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

    test('formatLiteral escapa aspas simples de forma segura e valida números estritos', () {
      expect(DbRowEditService.formatLiteral("O'Reilly"), equals("'O''Reilly'"));
      expect(DbRowEditService.formatLiteral(null), equals('NULL'));
      expect(DbRowEditService.formatLiteral(123), equals('123'));
      expect(DbRowEditService.formatLiteral(true), equals('true'));
      expect(DbRowEditService.formatLiteral(const DbRawNumber('123.456')), equals('123.456'));

      // Validação defensiva de DbRawNumber contra injeções SQL
      expect(
        () => DbRowEditService.formatLiteral(const DbRawNumber('123; DROP TABLE users;')),
        throwsA(isA<DbEditException>()),
      );

      // Rejeição de floats NaN / Infinity
      expect(
        () => DbRowEditService.formatLiteral(double.nan),
        throwsA(isA<DbEditException>()),
      );
      expect(
        () => DbRowEditService.formatLiteral(double.infinity),
        throwsA(isA<DbEditException>()),
      );
    });

    test('extractEditableTable extrai tabela e schema de consultas SELECT diretas', () {
      expect(
        service.extractEditableTable('SELECT * FROM users'),
        equals(const EditableTableTarget(table: 'users')),
      );
      expect(
        service.extractEditableTable('SELECT id, name FROM "public"."users" WHERE id = 1'),
        equals(const EditableTableTarget(table: 'users', schema: 'public')),
      );
      expect(
        service.extractEditableTable('select col1 from [dbo].[customers] order by id limit 10;'),
        equals(const EditableTableTarget(table: 'customers', schema: 'dbo')),
      );
      expect(
        service.extractEditableTable('SELECT * FROM `db`.`items` AS i WHERE i.active = 1'),
        equals(const EditableTableTarget(table: 'items', schema: 'db')),
      );
    });

    test('extractEditableTable rejeita consultas não editáveis (joins, agregacoes, distinct, unioes, aliases, expressoes)', () {
      expect(service.extractEditableTable('SELECT DISTINCT name FROM users'), isNull);
      expect(service.extractEditableTable('SELECT u.id, o.id FROM users u JOIN orders o ON u.id = o.user_id'), isNull);
      expect(service.extractEditableTable('SELECT * FROM users, orders'), isNull);
      expect(service.extractEditableTable('SELECT count(*) FROM users GROUP BY department'), isNull);
      expect(service.extractEditableTable('SELECT * FROM users HAVING count(*) > 1'), isNull);
      expect(service.extractEditableTable('SELECT * FROM (SELECT * FROM users)'), isNull);
      expect(service.extractEditableTable('SELECT id FROM a UNION SELECT id FROM b'), isNull);
      expect(service.extractEditableTable('UPDATE users SET name = "a"'), isNull);
      // Rejeita projeções com aliases (risco de mascarar colunas/PK)
      expect(service.extractEditableTable('SELECT other AS id, val AS username FROM users'), isNull);
      expect(service.extractEditableTable('SELECT id, name AS apelido FROM users'), isNull);
      // Rejeita funções ou expressões agregadas
      expect(service.extractEditableTable('SELECT upper(name) FROM users'), isNull);
      expect(service.extractEditableTable('SELECT a + b, name FROM users'), isNull);
      // Rejeita subqueries na projeção ou cláusula WHERE
      expect(service.extractEditableTable('SELECT id, (SELECT 1) FROM users'), isNull);
      // Rejeita literais em aspas simples como identificadores de coluna
      expect(service.extractEditableTable("SELECT 'id', name FROM users"), isNull);
    });

    test('parseValueForColumn realiza tipagem adequada, preserva decimais de alta precisao e distingue literal NULL', () {
      expect(
        service.parseValueForColumn(
          rawInput: '42',
          columnType: 'INTEGER',
          isNull: false,
        ),
        equals(42),
      );
      // DECIMAL/NUMERIC retorna DbRawNumber para preservar precisão exata
      expect(
        service.parseValueForColumn(
          rawInput: '99.5',
          columnType: 'NUMERIC',
          isNull: false,
        ),
        equals(const DbRawNumber('99.5')),
      );
      expect(
        service.parseValueForColumn(
          rawInput: '12345678901234567890.12345678901234567890',
          columnType: 'DECIMAL(38, 20)',
          isNull: false,
        ),
        equals(const DbRawNumber('12345678901234567890.12345678901234567890')),
      );
      expect(
        service.parseValueForColumn(
          rawInput: 'true',
          columnType: 'BOOLEAN',
          isNull: false,
        ),
        isTrue,
      );
      expect(
        service.parseValueForColumn(
          rawInput: 'qualquer coisa',
          columnType: 'TEXT',
          isNull: true,
        ),
        isNull,
      );
      // Literal 'NULL' com isNull = false é tratado como string literal 'NULL', não null
      expect(
        service.parseValueForColumn(
          rawInput: 'NULL',
          columnType: 'VARCHAR',
          isNull: false,
        ),
        equals('NULL'),
      );
    });

    test('parseValueForColumn lanca DbEditException com mensagem clara para entradas invalidas', () {
      expect(
        () => service.parseValueForColumn(
          rawInput: 'abc',
          columnType: 'INTEGER',
          isNull: false,
        ),
        throwsA(
          isA<DbEditException>().having(
            (e) => e.message,
            'message',
            contains('inválido para coluna numérica inteira'),
          ),
        ),
      );

      expect(
        () => service.parseValueForColumn(
          rawInput: '12.3.4',
          columnType: 'DECIMAL',
          isNull: false,
        ),
        throwsA(
          isA<DbEditException>().having(
            (e) => e.message,
            'message',
            contains('inválido para coluna numérica/decimal'),
          ),
        ),
      );

      expect(
        () => service.parseValueForColumn(
          rawInput: 'invalido',
          columnType: 'BOOLEAN',
          isNull: false,
        ),
        throwsA(
          isA<DbEditException>().having(
            (e) => e.message,
            'message',
            contains('inválido para coluna booleana'),
          ),
        ),
      );
    });
  });
}
