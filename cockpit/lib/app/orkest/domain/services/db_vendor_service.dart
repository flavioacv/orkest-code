import '../entities/db_vendor.dart';

/// Serviço que gerencia catálogo de provedores, detecção de schemas e URLs (Open IDEA).
class DbVendorService {
  const DbVendorService();

  /// Resolve o `DbVendorKind` apropriado para uma URL ou scheme informado.
  DbVendorKind? resolveVendorFromUrl(String url) {
    if (url.trim().isEmpty) return null;
    final uri = Uri.tryParse(url);
    final scheme = uri?.scheme.toLowerCase() ?? '';

    return switch (scheme) {
      'postgres' || 'postgresql' || 'pgsql' => DbVendorKind.postgres,
      'redshift' => DbVendorKind.redshift,
      'cockroach' || 'cockroachdb' => DbVendorKind.cockroachdb,
      'greenplum' => DbVendorKind.greenplum,
      'neon' => DbVendorKind.neon,
      'supabase' => DbVendorKind.supabase,
      'timescale' || 'timescaledb' => DbVendorKind.timescaledb,
      'yugabyte' || 'yugabytedb' => DbVendorKind.yugabytedb,
      'mysql' => DbVendorKind.mysql,
      'aurora-mysql' || 'aurora' => DbVendorKind.auroraMysql,
      'mariadb' => DbVendorKind.mariadb,
      'singlestore' || 'memsql' => DbVendorKind.singlestore,
      'tidb' => DbVendorKind.tidb,
      'oceanbase' => DbVendorKind.oceanbase,
      'sqlserver' || 'mssql' => DbVendorKind.mssql,
      'clickhouse' => DbVendorKind.clickhouse,
      'sqlite' => DbVendorKind.sqlite,
      'redis' || 'rediss' => DbVendorKind.redis,
      'mongodb' || 'mongodb+srv' => DbVendorKind.mongo,
      _ => null,
    };
  }

  /// Retorna a lista de todos os vendors agrupados por categoria.
  List<DbVendorKind> listAllVendors() => DbVendorKind.values;

  /// Retorna os vendors recomendados para exibição em menus rápidos.
  List<DbVendorKind> getPopularVendors() => [
    DbVendorKind.postgres,
    DbVendorKind.mysql,
    DbVendorKind.sqlite,
    DbVendorKind.mssql,
    DbVendorKind.clickhouse,
    DbVendorKind.supabase,
    DbVendorKind.redis,
    DbVendorKind.mongo,
  ];
}
