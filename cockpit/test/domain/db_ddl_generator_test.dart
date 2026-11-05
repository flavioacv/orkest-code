import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_schema_entities.dart';
import 'package:orkest_code/app/orkest/domain/services/db_ddl_generator.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';

void main() {
  group('DbDdlGenerator - Geração de DDL (B01)', () {
    const generator = DbDdlGenerator();

    test('gera CREATE TABLE para SQLite com primary key e índices', () {
      final columns = [
        const SchemaColumn('id', 'INTEGER', primaryKey: true),
        const SchemaColumn('username', 'TEXT'),
        const SchemaColumn('email', 'TEXT'),
      ];

      final indexes = [
        const SchemaIndex(
          name: 'idx_users_email',
          table: 'users',
          columns: ['email'],
          isUnique: true,
        ),
      ];

      final ddl = generator.generateTableDdl(
        engine: DbEngine.sqlite,
        table: 'users',
        columns: columns,
        indexes: indexes,
      );

      expect(ddl, contains('CREATE TABLE "users" ('));
      expect(ddl, contains('  "id" INTEGER NOT NULL'));
      expect(ddl, contains('  "username" TEXT'));
      expect(ddl, contains('  CONSTRAINT pk_users PRIMARY KEY ("id")'));
      expect(ddl, contains('CREATE UNIQUE INDEX "idx_users_email" ON "users" ("email");'));
    });

    test('gera CREATE TABLE para PostgreSQL com foreign keys e schema qualificado', () {
      final columns = [
        const SchemaColumn('id', 'BIGINT', primaryKey: true),
        const SchemaColumn('user_id', 'BIGINT'),
        const SchemaColumn('total', 'NUMERIC(10,2)'),
      ];

      final fks = [
        const SchemaForeignKey(
          name: 'fk_orders_user',
          table: 'orders',
          column: 'user_id',
          referencedTable: 'users',
          referencedColumn: 'id',
          onDelete: 'CASCADE',
        ),
      ];

      final ddl = generator.generateTableDdl(
        engine: DbEngine.postgres,
        table: 'orders',
        schema: 'sales',
        columns: columns,
        foreignKeys: fks,
      );

      expect(ddl, contains('CREATE TABLE "sales"."orders" ('));
      expect(ddl, contains('  CONSTRAINT "fk_orders_user" FOREIGN KEY ("user_id") REFERENCES "users" ("id") ON DELETE CASCADE'));
    });

    test('gera CREATE TABLE para MySQL com delimitadores backtick', () {
      final columns = [
        const SchemaColumn('id', 'INT', primaryKey: true),
        const SchemaColumn('title', 'VARCHAR(255)'),
      ];

      final ddl = generator.generateTableDdl(
        engine: DbEngine.mysql,
        table: 'posts',
        columns: columns,
      );

      expect(ddl, contains('CREATE TABLE `posts` ('));
      expect(ddl, contains('  `id` INT NOT NULL'));
      expect(ddl, contains('  CONSTRAINT pk_posts PRIMARY KEY (`id`)'));
    });

    test('gera CREATE VIEW qualificada', () {
      final ddl = generator.generateViewDdl(
        engine: DbEngine.postgres,
        view: 'active_customers',
        schema: 'analytics',
        definition: 'SELECT id, name FROM customers WHERE active = true;',
      );

      expect(
        ddl,
        equals('CREATE VIEW "analytics"."active_customers" AS\nSELECT id, name FROM customers WHERE active = true;'),
      );
    });
  });
}
