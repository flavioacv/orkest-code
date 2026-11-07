import 'db_connection.dart';

/// Vendors e wire-protocols suportados pelo gerenciador de dados do Orkest Code,
/// migrados e compatíveis com o ecossistema Open IDEA.
enum DbVendorKind {
  // Postgres wire
  postgres,
  redshift,
  cockroachdb,
  greenplum,
  neon,
  supabase,
  timescaledb,
  yugabytedb,

  // MySQL wire
  mysql,
  auroraMysql,
  mariadb,
  singlestore,
  tidb,
  oceanbase,

  // SQL Server
  mssql,

  // SQLite
  sqlite,

  // ClickHouse
  clickhouse,

  // Não-SQL / Documentos
  redis,
  mongo;

  String get id => switch (this) {
    DbVendorKind.postgres => 'postgres',
    DbVendorKind.redshift => 'redshift',
    DbVendorKind.cockroachdb => 'cockroachdb',
    DbVendorKind.greenplum => 'greenplum',
    DbVendorKind.neon => 'neon',
    DbVendorKind.supabase => 'supabase',
    DbVendorKind.timescaledb => 'timescaledb',
    DbVendorKind.yugabytedb => 'yugabytedb',
    DbVendorKind.mysql => 'mysql',
    DbVendorKind.auroraMysql => 'aurora-mysql',
    DbVendorKind.mariadb => 'mariadb',
    DbVendorKind.singlestore => 'singlestore',
    DbVendorKind.tidb => 'tidb',
    DbVendorKind.oceanbase => 'oceanbase',
    DbVendorKind.mssql => 'sqlServer',
    DbVendorKind.sqlite => 'sqlite',
    DbVendorKind.clickhouse => 'clickhouse',
    DbVendorKind.redis => 'redis',
    DbVendorKind.mongo => 'mongo',
  };

  String get label => switch (this) {
    DbVendorKind.postgres => 'PostgreSQL',
    DbVendorKind.redshift => 'Amazon Redshift',
    DbVendorKind.cockroachdb => 'CockroachDB',
    DbVendorKind.greenplum => 'Greenplum',
    DbVendorKind.neon => 'Neon',
    DbVendorKind.supabase => 'Supabase',
    DbVendorKind.timescaledb => 'TimescaleDB',
    DbVendorKind.yugabytedb => 'YugabyteDB',
    DbVendorKind.mysql => 'MySQL',
    DbVendorKind.auroraMysql => 'Amazon Aurora MySQL',
    DbVendorKind.mariadb => 'MariaDB',
    DbVendorKind.singlestore => 'SingleStore',
    DbVendorKind.tidb => 'TiDB',
    DbVendorKind.oceanbase => 'OceanBase (MySQL mode)',
    DbVendorKind.mssql => 'Microsoft SQL Server',
    DbVendorKind.sqlite => 'SQLite',
    DbVendorKind.clickhouse => 'ClickHouse',
    DbVendorKind.redis => 'Redis',
    DbVendorKind.mongo => 'MongoDB',
  };

  DbEngine get engine => switch (this) {
    DbVendorKind.postgres ||
    DbVendorKind.redshift ||
    DbVendorKind.cockroachdb ||
    DbVendorKind.greenplum ||
    DbVendorKind.neon ||
    DbVendorKind.supabase ||
    DbVendorKind.timescaledb ||
    DbVendorKind.yugabytedb => DbEngine.postgres,

    DbVendorKind.mysql ||
    DbVendorKind.auroraMysql ||
    DbVendorKind.mariadb ||
    DbVendorKind.singlestore ||
    DbVendorKind.tidb ||
    DbVendorKind.oceanbase => DbEngine.mysql,

    DbVendorKind.mssql => DbEngine.mssql,
    DbVendorKind.sqlite => DbEngine.sqlite,
    DbVendorKind.clickhouse => DbEngine.clickhouse,
    DbVendorKind.redis => DbEngine.redis,
    DbVendorKind.mongo => DbEngine.mongo,
  };

  int get defaultPort => switch (this) {
    DbVendorKind.postgres => 5432,
    DbVendorKind.redshift => 5439,
    DbVendorKind.cockroachdb => 26257,
    DbVendorKind.greenplum => 5432,
    DbVendorKind.neon => 5432,
    DbVendorKind.supabase => 5432,
    DbVendorKind.timescaledb => 5432,
    DbVendorKind.yugabytedb => 5433,
    DbVendorKind.mysql => 3306,
    DbVendorKind.auroraMysql => 3306,
    DbVendorKind.mariadb => 3306,
    DbVendorKind.singlestore => 3306,
    DbVendorKind.tidb => 4000,
    DbVendorKind.oceanbase => 2881,
    DbVendorKind.mssql => 1433,
    DbVendorKind.sqlite => 0,
    DbVendorKind.clickhouse => 8123,
    DbVendorKind.redis => 6379,
    DbVendorKind.mongo => 27017,
  };

  bool get requiresSsl => switch (this) {
    DbVendorKind.redshift ||
    DbVendorKind.neon ||
    DbVendorKind.supabase => true,
    _ => false,
  };

  String get scheme => switch (this) {
    DbVendorKind.redshift => 'redshift',
    DbVendorKind.cockroachdb => 'cockroachdb',
    DbVendorKind.mariadb => 'mariadb',
    DbVendorKind.clickhouse => 'clickhouse',
    DbVendorKind.mongo => 'mongodb',
    _ => engine.scheme,
  };

  static DbVendorKind? fromId(String? id) {
    if (id == null || id.isEmpty) return null;
    for (final v in DbVendorKind.values) {
      if (v.id.toLowerCase() == id.toLowerCase()) return v;
    }
    return null;
  }

  static DbVendorKind fromEngine(DbEngine engine) {
    return switch (engine) {
      DbEngine.sqlite => DbVendorKind.sqlite,
      DbEngine.postgres => DbVendorKind.postgres,
      DbEngine.mysql => DbVendorKind.mysql,
      DbEngine.mssql => DbVendorKind.mssql,
      DbEngine.clickhouse => DbVendorKind.clickhouse,
      DbEngine.redis => DbVendorKind.redis,
      DbEngine.mongo => DbVendorKind.mongo,
    };
  }
}
