/// Modo de controle transacional da sessão de banco de dados.
enum DbTransactionMode {
  auto,
  manual;

  static DbTransactionMode fromName(String? name) =>
      name == 'manual' ? DbTransactionMode.manual : DbTransactionMode.auto;
}

/// Modo de verificação SSL/TLS.
enum DbSslMode {
  disable,
  prefer,
  require,
  verifyCa,
  verifyFull;

  static DbSslMode fromName(String? name) => switch (name?.toLowerCase()) {
    'disable' => DbSslMode.disable,
    'require' => DbSslMode.require,
    'verifyca' || 'verify-ca' => DbSslMode.verifyCa,
    'verifyfull' || 'verify-full' => DbSslMode.verifyFull,
    _ => DbSslMode.prefer,
  };
}

/// Opções avançadas de conexão e sessão de banco de dados (migrado do Open IDEA).
class DbOptions {
  final DbTransactionMode transaction;
  final String defaultSchema;
  final String timeZone;
  final String startupScript;
  final int? keepAliveSecs;
  final int? autoDisconnectSecs;
  final bool singleDatabase;

  const DbOptions({
    this.transaction = DbTransactionMode.auto,
    this.defaultSchema = '',
    this.timeZone = '',
    this.startupScript = '',
    this.keepAliveSecs,
    this.autoDisconnectSecs,
    this.singleDatabase = false,
  });

  Map<String, dynamic> toJson() => {
    'transaction': transaction.name,
    if (defaultSchema.isNotEmpty) 'defaultSchema': defaultSchema,
    if (timeZone.isNotEmpty) 'timeZone': timeZone,
    if (startupScript.isNotEmpty) 'startupScript': startupScript,
    if (keepAliveSecs != null) 'keepAliveSecs': keepAliveSecs,
    if (autoDisconnectSecs != null) 'autoDisconnectSecs': autoDisconnectSecs,
    if (singleDatabase) 'singleDatabase': singleDatabase,
  };

  factory DbOptions.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DbOptions();
    return DbOptions(
      transaction: DbTransactionMode.fromName(json['transaction'] as String?),
      defaultSchema: (json['defaultSchema'] as String?) ?? '',
      timeZone: (json['timeZone'] as String?) ?? '',
      startupScript: (json['startupScript'] as String?) ?? '',
      keepAliveSecs: json['keepAliveSecs'] as int?,
      autoDisconnectSecs: json['autoDisconnectSecs'] as int?,
      singleDatabase: (json['singleDatabase'] as bool?) ?? false,
    );
  }
}

/// Configuração de introspecção do catálogo de banco de dados (migrado do Open IDEA).
class DbIntrospection {
  final bool allDatabases;
  final List<String> databases;
  final bool allSchemas;
  final List<String> schemas;
  final bool showSystem;
  final bool showTemplates;
  final String objectFilter;

  const DbIntrospection({
    this.allDatabases = true,
    this.databases = const [],
    this.allSchemas = true,
    this.schemas = const [],
    this.showSystem = false,
    this.showTemplates = false,
    this.objectFilter = '',
  });

  Map<String, dynamic> toJson() => {
    'allDatabases': allDatabases,
    if (databases.isNotEmpty) 'databases': databases,
    'allSchemas': allSchemas,
    if (schemas.isNotEmpty) 'schemas': schemas,
    'showSystem': showSystem,
    'showTemplates': showTemplates,
    if (objectFilter.isNotEmpty) 'objectFilter': objectFilter,
  };

  factory DbIntrospection.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const DbIntrospection();
    return DbIntrospection(
      allDatabases: (json['allDatabases'] as bool?) ?? true,
      databases: (json['databases'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      allSchemas: (json['allSchemas'] as bool?) ?? true,
      schemas: (json['schemas'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [],
      showSystem: (json['showSystem'] as bool?) ?? false,
      showTemplates: (json['showTemplates'] as bool?) ?? false,
      objectFilter: (json['objectFilter'] as String?) ?? '',
    );
  }

  /// Verifica se um schema deve ser exibido de acordo com as regras de introspecção.
  bool shouldShowSchema(String schemaName) {
    if (!showSystem) {
      final s = schemaName.toLowerCase();
      if (s == 'pg_catalog' ||
          s == 'information_schema' ||
          s == 'mysql' ||
          s == 'performance_schema' ||
          s == 'sys') {
        return false;
      }
    }
    if (allSchemas) return true;
    return schemas.contains(schemaName);
  }

  /// Verifica se um objeto (tabela/view/função) atende ao filtro configurado (`*`, `?`).
  bool matchesObjectFilter(String objectName) {
    if (objectFilter.trim().isEmpty) return true;
    final patterns = objectFilter
        .split(RegExp(r'[,;\s]+'))
        .where((p) => p.isNotEmpty);
    if (patterns.isEmpty) return true;

    for (final pattern in patterns) {
      if (_matchesGlob(pattern, objectName)) return true;
    }
    return false;
  }

  static bool _matchesGlob(String pattern, String input) {
    final regexPattern = '^${pattern
        .replaceAll('.', r'\.')
        .replaceAll('*', '.*')
        .replaceAll('?', '.')}\$';
    return RegExp(regexPattern, caseSensitive: false).hasMatch(input);
  }
}
