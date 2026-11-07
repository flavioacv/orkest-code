import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_options_and_introspection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_table_page.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_vendor.dart';
import 'package:orkest_code/app/orkest/domain/services/db_vendor_service.dart';

void main() {
  group('DbVendor & DbVendorService (Migração Open IDEA)', () {
    const service = DbVendorService();

    test('resolve corretamente vendors por URL e scheme', () {
      expect(
        service.resolveVendorFromUrl('postgres://user@localhost:5432/db'),
        DbVendorKind.postgres,
      );
      expect(
        service.resolveVendorFromUrl('postgresql://user@localhost:5432/db'),
        DbVendorKind.postgres,
      );
      expect(
        service.resolveVendorFromUrl('redshift://user@cluster.redshift.amazonaws.com:5439/db'),
        DbVendorKind.redshift,
      );
      expect(
        service.resolveVendorFromUrl('supabase://postgres:pass@db.supabase.co:5432/postgres'),
        DbVendorKind.supabase,
      );
      expect(
        service.resolveVendorFromUrl('mysql://root@127.0.0.1:3306/app'),
        DbVendorKind.mysql,
      );
      expect(
        service.resolveVendorFromUrl('mariadb://root@127.0.0.1:3306/app'),
        DbVendorKind.mariadb,
      );
      expect(
        service.resolveVendorFromUrl('clickhouse://default@localhost:8123/default'),
        DbVendorKind.clickhouse,
      );
      expect(
        service.resolveVendorFromUrl('sqlserver://sa:Pass@host:1433/db'),
        DbVendorKind.mssql,
      );
      expect(
        service.resolveVendorFromUrl('mongodb+srv://user@cluster.mongodb.net/test'),
        DbVendorKind.mongo,
      );
    });

    test('associa portas padrão e engine subjacente aos wire-protocols', () {
      expect(DbVendorKind.redshift.engine, DbEngine.postgres);
      expect(DbVendorKind.redshift.defaultPort, 5439);
      expect(DbVendorKind.redshift.requiresSsl, isTrue);

      expect(DbVendorKind.supabase.engine, DbEngine.postgres);
      expect(DbVendorKind.supabase.requiresSsl, isTrue);

      expect(DbVendorKind.cockroachdb.engine, DbEngine.postgres);
      expect(DbVendorKind.cockroachdb.defaultPort, 26257);

      expect(DbVendorKind.auroraMysql.engine, DbEngine.mysql);
      expect(DbVendorKind.tidb.engine, DbEngine.mysql);
      expect(DbVendorKind.tidb.defaultPort, 4000);

      expect(DbVendorKind.clickhouse.engine, DbEngine.clickhouse);
      expect(DbVendorKind.clickhouse.defaultPort, 8123);
    });
  });

  group('DbOptions & DbIntrospection (Governança e Filtros)', () {
    test('serializa e deserializa DbOptions com integridade', () {
      const options = DbOptions(
        transaction: DbTransactionMode.manual,
        defaultSchema: 'analytics',
        timeZone: 'UTC',
        startupScript: 'SET TIME ZONE "UTC";',
        keepAliveSecs: 30,
        autoDisconnectSecs: 300,
        singleDatabase: true,
      );

      final json = options.toJson();
      final restored = DbOptions.fromJson(json);

      expect(restored.transaction, DbTransactionMode.manual);
      expect(restored.defaultSchema, 'analytics');
      expect(restored.timeZone, 'UTC');
      expect(restored.startupScript, 'SET TIME ZONE "UTC";');
      expect(restored.keepAliveSecs, 30);
      expect(restored.autoDisconnectSecs, 300);
      expect(restored.singleDatabase, isTrue);
    });

    test('filtra schemas e objetos de sistema via DbIntrospection', () {
      const introspection = DbIntrospection(
        allDatabases: false,
        databases: ['prod_db'],
        allSchemas: false,
        schemas: ['public', 'analytics'],
        showSystem: false,
        objectFilter: 'users_*, tbl_?',
      );

      // Schemas de sistema devem ser ocultados quando showSystem é false
      expect(introspection.shouldShowSchema('pg_catalog'), isFalse);
      expect(introspection.shouldShowSchema('information_schema'), isFalse);
      expect(introspection.shouldShowSchema('performance_schema'), isFalse);

      // Schemas explícitos permitidos
      expect(introspection.shouldShowSchema('public'), isTrue);
      expect(introspection.shouldShowSchema('analytics'), isTrue);
      expect(introspection.shouldShowSchema('auth'), isFalse);

      // Filtro de objetos glob (* e ?)
      expect(introspection.matchesObjectFilter('users_profile'), isTrue);
      expect(introspection.matchesObjectFilter('users_orders'), isTrue);
      expect(introspection.matchesObjectFilter('tbl_1'), isTrue);
      expect(introspection.matchesObjectFilter('tbl_abc'), isFalse);
      expect(introspection.matchesObjectFilter('accounts'), isFalse);
    });
  });

  group('DbTablePage & DbTablePageRequest (Paginação e Leitura)', () {
    test('DbTablePageRequest gera cláusula SQL canônica correta', () {
      const request = DbTablePageRequest(
        connectionName: 'prod',
        schema: 'public',
        table: 'users',
        filter: 'status = 1 AND active IS TRUE',
        sort: [
          SortKey(column: 'created_at', ascending: false),
          SortKey(column: 'id', ascending: true),
        ],
        offset: 50,
        limit: 25,
      );

      final sql = request.toSql(quoteIdentifier: (id) => '"$id"');
      expect(
        sql,
        'SELECT * FROM "public"."users" WHERE status = 1 AND active IS TRUE ORDER BY "created_at" DESC, "id" ASC LIMIT 25 OFFSET 50',
      );
    });

    test('serializa e deserializa DbTablePage', () {
      const page = DbTablePage(
        columns: ['id', 'email', 'name'],
        rows: [
          [1, 'alice@example.com', 'Alice'],
          [2, 'bob@example.com', 'Bob'],
        ],
        totalRows: 100,
        offset: 0,
        limit: 2,
        hasMore: true,
      );

      final json = page.toJson();
      final restored = DbTablePage.fromJson(json);

      expect(restored.columns, ['id', 'email', 'name']);
      expect(restored.rows.length, 2);
      expect(restored.totalRows, 100);
      expect(restored.hasMore, isTrue);
    });
  });

  group('DbConnection com capacidades migradas', () {
    test('mantém e persiste vendorId, readOnly, options e introspection', () {
      final conn = DbConnection(
        name: 'Supabase Prod',
        engine: DbEngine.postgres,
        url: 'postgres://postgres:pass@db.supabase.co:5432/postgres?sslmode=require',
        vendorId: 'supabase',
        readOnly: true,
        options: const DbOptions(
          transaction: DbTransactionMode.manual,
          defaultSchema: 'public',
        ),
        introspection: const DbIntrospection(
          showSystem: false,
          objectFilter: 'app_*',
        ),
      );

      final json = conn.toJson();
      expect(json['vendorId'], 'supabase');
      expect(json['readOnly'], isTrue);
      expect((json['options'] as Map)['defaultSchema'], 'public');
      expect((json['introspection'] as Map)['objectFilter'], 'app_*');

      final restored = DbConnection.fromJson(json);
      expect(restored.vendorId, 'supabase');
      expect(restored.readOnly, isTrue);
      expect(restored.options.defaultSchema, 'public');
      expect(restored.introspection.objectFilter, 'app_*');
      expect(restored.useTls, isTrue);
    });
  });
}
