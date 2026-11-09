import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/menu/editor_menu_bridge.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/contracts/db_connection_store.dart';
import 'package:orkest_code/app/orkest/domain/contracts/db_driver.dart';
import 'package:orkest_code/app/orkest/domain/contracts/nosql_runner.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_connection.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_view.dart';
import 'package:orkest_code/app/orkest/domain/services/db_export_service.dart';
import 'package:orkest_code/app/orkest/domain/services/db_query_service.dart';
import 'package:orkest_code/app/orkest/domain/services/db_row_edit_service.dart';
import 'package:orkest_code/app/orkest/ui/session/file_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/database_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:orkest_code/app/orkest/ui/widgets/db_query_view.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../domain/fakes/mongo_database_store_fake.dart';
import '../domain/fakes/ssh_fakes.dart';

class _FakeConnectionStore implements DbConnectionStore {
  _FakeConnectionStore(this.conns);
  final List<DbConnection> conns;
  @override
  Future<List<DbConnection>> load(String root) async => conns;
  @override
  Future<void> save(String root, List<DbConnection> connections) async {}
}

class _FakeDbSecrets implements DbSecrets {
  final Map<String, String> map = {};
  @override
  Future<void> delete(String key) async => map.remove(key);
  @override
  Future<String?> read(String key, {String? legacyKey}) async => map[key];
  @override
  Future<void> write(String key, String value) async => map[key] = value;
}

class _FakeDriverRegistry implements DbDriverRegistry {
  _FakeDriverRegistry(this.driver);
  final DbDriver driver;
  @override
  DbDriver? forEngine(DbEngine engine) => driver;
}

class _FakeDbDriver implements DbDriver {
  _FakeDbDriver({
    required this.onQuery,
    required this.onExecute,
    required this.onSchema,
  });

  final Future<DbResult> Function(DbConnection conn, String sql, int limit) onQuery;
  final Future<DbResult> Function(DbConnection conn, String sql) onExecute;
  final Future<DbResult> Function(DbConnection conn, String? table, String? schema) onSchema;

  @override
  Future<DbResult> query(
    DbConnection conn,
    String sql, {
    required int limit,
    Duration timeout = const Duration(seconds: 15),
    String? password,
  }) =>
      onQuery(conn, sql, limit);

  @override
  Future<DbResult> execute(
    DbConnection conn,
    String sql, {
    Duration timeout = const Duration(seconds: 15),
    String? password,
  }) =>
      onExecute(conn, sql);

  @override
  Future<DbResult> schema(
    DbConnection conn, {
    String? table,
    String? schema,
    Duration timeout = const Duration(seconds: 15),
    String? password,
  }) =>
      onSchema(conn, table, schema);
}

class _FakeNoSqlRunner implements NoSqlRunner {
  @override
  Future<Object?> mongo(
    DbConnection conn,
    Map<String, dynamic> command, {
    String? password,
    String? database,
    String workspaceRoot = '',
  }) async =>
      null;

  @override
  Future<Object?> redis(
    DbConnection conn,
    List<String> command, {
    String? password,
    String workspaceRoot = '',
  }) async =>
      null;

  @override
  Future<List<Object?>> redisMany(
    DbConnection conn,
    List<List<String>> commands, {
    String? password,
    String workspaceRoot = '',
  }) async =>
      [];
}

DatabaseViewModel _createTestDatabaseVm({
  required DbConnection conn,
  required Future<DbResult> Function(DbConnection conn, String sql, int limit) onQuery,
  required Future<DbResult> Function(DbConnection conn, String sql) onExecute,
  required Future<DbResult> Function(DbConnection conn, String? table, String? schema) onSchema,
}) {
  final store = _FakeConnectionStore([conn]);
  final secrets = _FakeDbSecrets();
  final driver = _FakeDbDriver(
    onQuery: onQuery,
    onExecute: onExecute,
    onSchema: onSchema,
  );
  final service = DbQueryService(
    store,
    secrets,
    _FakeDriverRegistry(driver),
    _FakeNoSqlRunner(),
    FakeSshTunnel(),
    FakeSshKeyInspector(),
    FakeMongoDatabaseStore(),
  );
  return DatabaseViewModel(
    store,
    secrets,
    service,
    FakeSshKeyInspector(),
    FakeSshHostKeyStore(),
  );
}

Widget _wrapWithTheme(Widget child) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: SizedBox(width: 800, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('Database Workbench & Grid Enhancements (FE-E4)', () {
    const editService = DbRowEditService();
    const exportService = DbExportService();

    final sampleResult = DbResult(
      columns: const [
        DbColumn('id', 'INTEGER'),
        DbColumn('username', 'TEXT'),
        DbColumn('email', 'TEXT'),
      ],
      rows: [
        [1, 'flavio', 'flavio@example.com'],
        [2, 'arthur', 'arthur@example.com'],
      ],
      elapsed: const Duration(milliseconds: 14),
    );

    testWidgets('DbQueryView executa Explain sem ANALYZE e mantém resultado somente leitura', (tester) async {
      final conn = DbConnection.sqlite('appdb', '/tmp/test.db');
      String? executedSql;
      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async {
          executedSql = sql;
          return const DbResult(
            columns: [DbColumn('detail', 'TEXT')],
            rows: [['SCAN CONSTANT ROW']],
            elapsed: Duration(milliseconds: 2),
          );
        },
        onExecute: (c, sql) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
        onSchema: (c, table, schema) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );
      final session = FileViewerSession(
        id: 'session_explain',
        projectId: 'proj-explain',
        path: '/ws/explain.dbq',
        view: const FileViewText('-- db: appdb\nSELECT 1;'),
      );

      await tester.pumpWidget(_wrapWithTheme(DbQueryView(
        session: session,
        active: true,
        focused: true,
        workspaceRoot: '/ws',
        onSave: (content) async => true,
        databaseViewModel: vm,
        menuBridge: EditorMenuBridge(),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('db-query-explain-button')));
      await tester.pumpAndSettle();

      expect(executedSql, 'EXPLAIN QUERY PLAN SELECT 1;');
      expect(executedSql, isNot(contains('ANALYZE')));
      expect(vm.tabStateFor(session.id).lastExecutedSql, isNull);
      expect(vm.queryHistory(workspaceId: 'proj-explain', connName: 'appdb').single.sql, 'SELECT 1');
    });

    testWidgets('DbQueryView filtra histórico por workspace e restaura a consulta selecionada', (tester) async {
      final conn = DbConnection.sqlite('appdb', '/tmp/test.db');
      final capturedSql = <String>[];
      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async {
          capturedSql.add(sql);
          return const DbResult(
            columns: [DbColumn('detail', 'TEXT')],
            rows: [['SCAN CONSTANT ROW']],
            elapsed: Duration(milliseconds: 2),
          );
        },
        onExecute: (c, sql) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
        onSchema: (c, table, schema) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );
      final entry = vm.recordQueryHistory(
        workspaceId: 'proj-history',
        connName: 'appdb',
        sql: 'SELECT 42;',
        elapsed: const Duration(milliseconds: 4),
      );
      vm.recordQueryHistory(
        workspaceId: 'other-workspace',
        connName: 'appdb',
        sql: 'SELECT 99;',
        elapsed: const Duration(milliseconds: 3),
      );
      final session = FileViewerSession(
        id: 'session_history',
        projectId: 'proj-history',
        path: '/ws/history.dbq',
        view: const FileViewText('-- db: appdb\nSELECT 1;'),
      );

      await tester.pumpWidget(_wrapWithTheme(DbQueryView(
        session: session,
        active: true,
        focused: true,
        workspaceRoot: '/ws',
        onSave: (content) async {
          session.adoptDisk(FileViewText(content));
          return true;
        },
        databaseViewModel: vm,
        menuBridge: EditorMenuBridge(),
      )));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('db-query-history-button')));
      await tester.pumpAndSettle();

      expect(find.byKey(ValueKey('db-query-history-entry:${entry.id}')), findsOneWidget);
      expect(find.textContaining('SELECT 99;'), findsNothing);
      await tester.tap(find.byKey(ValueKey('db-query-history-entry:${entry.id}')));
      await tester.pumpAndSettle();
      expect(find.text('Query history'), findsNothing);
      expect(tester.widget<CodeEditor>(find.byType(CodeEditor)).controller.text, 'SELECT 42;');
      await tester.tap(find.byKey(const ValueKey('db-query-explain-button')));
      await tester.pumpAndSettle();

      expect(capturedSql, ['EXPLAIN QUERY PLAN SELECT 42;']);
    });

    test('DbExportService exporta CSV formatado com delimitador e escapamento', () {
      final csv = exportService.exportCsv(sampleResult);
      expect(csv, contains('id,username,email'));
      expect(csv, contains('1,flavio,flavio@example.com'));
      expect(csv, contains('2,arthur,arthur@example.com'));
    });

    test('DbExportService exporta JSON estruturado com chave e valores', () {
      final json = exportService.exportJson(sampleResult, pretty: true);
      expect(json, contains('"username": "flavio"'));
      expect(json, contains('"email": "arthur@example.com"'));
    });

    test('DbRowEditService gera UPDATE seguro com concorrência otimista e proteção por PK', () {
      final sql = editService.generateOptimisticUpdateSql(
        engine: DbEngine.postgres,
        table: 'users',
        schema: 'public',
        pkColumns: const ['id'],
        pkValues: const [1],
        modifiedColumn: 'username',
        oldValue: 'flavio',
        newValue: 'flavio_valdez',
      );

      expect(sql, equals('UPDATE "public"."users" SET "username" = \'flavio_valdez\' WHERE "id" = 1 AND "username" = \'flavio\';'));
    });

    test('DbRowEditService protege contra atualização com oldValue nulo', () {
      final sql = editService.generateOptimisticUpdateSql(
        engine: DbEngine.sqlite,
        table: 'profiles',
        pkColumns: const ['id'],
        pkValues: const [10],
        modifiedColumn: 'bio',
        oldValue: null,
        newValue: 'Software Architect',
      );

      expect(sql, equals('UPDATE "profiles" SET "bio" = \'Software Architect\' WHERE "id" = 10 AND "bio" IS NULL;'));
    });

    test('DbRowEditService rejeita atualização sem chave primária para evitar corrupção em cascata', () {
      expect(
        () => editService.generateOptimisticUpdateSql(
          engine: DbEngine.postgres,
          table: 'logs',
          pkColumns: const [],
          pkValues: const [],
          modifiedColumn: 'message',
          oldValue: 'old',
          newValue: 'new',
        ),
        throwsA(isA<DbEditException>()),
      );
    });

    testWidgets('DbQueryView real: edição de célula com duplo-clique executa introspecção de PK, UPDATE otimista e persiste no grid', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );
      String? executedDmlSql;

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          executedDmlSql = sql;
          return const DbResult(
            columns: [],
            rows: [],
            elapsed: Duration(milliseconds: 5),
            affectedRows: 1,
          );
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
              ['email', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_1',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username, email FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
          DbColumn('email', 'TEXT'),
        ],
        rows: [
          [1, 'flavio', 'flavio@example.com'],
          [2, 'arthur', 'arthur@example.com'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('flavio'), findsOneWidget);

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('db-grid-cell-edit-input')), findsOneWidget);
      expect(find.byKey(const ValueKey('db-grid-cell-edit-save')), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'flavio_valdez');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(executedDmlSql, isNotNull);
      expect(executedDmlSql, contains('UPDATE "users" SET "username" = \'flavio_valdez\''));
      expect(executedDmlSql, contains('WHERE "id" = 1 AND "username" = \'flavio\';'));

      expect(find.text('flavio_valdez'), findsOneWidget);
    });

    testWidgets('DbQueryView real: concorrência otimista rejeita alteração quando 0 linhas afetadas', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          return const DbResult(
            columns: [],
            rows: [],
            elapsed: Duration(milliseconds: 5),
            affectedRows: 0,
          );
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
              ['email', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_2',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username, email FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
          DbColumn('email', 'TEXT'),
        ],
        rows: [
          [1, 'flavio', 'flavio@example.com'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'novo_flavio');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('Falha na concorrência'), findsOneWidget);

      expect(find.text('flavio'), findsOneWidget);
      expect(find.text('novo_flavio'), findsNothing);
    });

    testWidgets('DbQueryView real: cancelamento honesto abandona resultado tardio e bloqueia novas execuções até encerramento', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final queryCompleter = Completer<DbResult>();

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) => queryCompleter.future,
        onExecute: (c, sql) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
        onSchema: (c, table, schema) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );

      final session = FileViewerSession(
        id: 'session_query_3',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT * FROM users;'),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Run'));
      await tester.pump();

      expect(find.byKey(const ValueKey('db-query-cancel')), findsOneWidget);
      expect(find.text('Descartar resultado'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('db-query-cancel')));
      await tester.pump();

      expect(find.text('Descartando...'), findsWidgets);

      queryCompleter.complete(
        DbResult(
          columns: const [DbColumn('id', 'INTEGER')],
          rows: [
            [999],
          ],
          elapsed: const Duration(milliseconds: 20),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('999'), findsNothing);
      expect(find.byKey(const ValueKey('db-query-cancel')), findsNothing);
    });

    testWidgets('DbQueryView real: affectedRows nulo gera mensagem de resultado indeterminado instruindo recarga', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          return const DbResult(
            columns: [],
            rows: [],
            elapsed: Duration(milliseconds: 5),
            affectedRows: null,
          );
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
              ['email', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_null_affected',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username, email FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
          DbColumn('email', 'TEXT'),
        ],
        rows: [
          [1, 'flavio', 'flavio@example.com'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'novo_nome');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('Resultado indeterminado'), findsOneWidget);
      expect(find.textContaining('driver não confirmou'), findsOneWidget);
      expect(find.textContaining('recarregue a consulta antes de tentar novamente'), findsOneWidget);
      expect(find.textContaining('Operação abortada'), findsNothing);
      expect(find.textContaining('não persistida'), findsNothing);
    });

    testWidgets('DbQueryView real: affectedRows maior que 1 gera mensagem de alerta sem fingir rollback', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          return const DbResult(
            columns: [],
            rows: [],
            elapsed: Duration(milliseconds: 5),
            affectedRows: 3,
          );
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
              ['email', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_multi_affected',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username, email FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
          DbColumn('email', 'TEXT'),
        ],
        rows: [
          [1, 'flavio', 'flavio@example.com'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'novo_nome');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('driver reportou mais de uma linha alterada (3)'), findsOneWidget);
      expect(find.textContaining('Verifique o banco de dados'), findsOneWidget);
      expect(find.textContaining('Operação abortada'), findsNothing);
    });

    testWidgets('DbQueryView real: valor inválido para coluna inteira impede envio de query DML ao driver', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );
      var queryExecuted = false;

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          queryExecuted = true;
          return const DbResult(columns: [], rows: [], elapsed: Duration.zero, affectedRows: 1);
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_invalid_type',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
        ],
        rows: [
          [42, 'flavio'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Clica duas vezes na célula da coluna 'id' (INTEGER com valor 42)
      await tester.tap(find.text('42'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('42'));
      await tester.pumpAndSettle();

      // Digita string inválida para inteiro
      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'texto_nao_inteiro');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(queryExecuted, isFalse);
      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('inválido para coluna numérica inteira'), findsOneWidget);
    });

    testWidgets('DbQueryView real: recusa edição quando resultado não possui registro de proveniência', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
        onSchema: (c, table, schema) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );

      final session = FileViewerSession(
        id: 'session_query_no_provenance',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = null;
      tabState.executedConnName = null;
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
        ],
        rows: [
          [42, 'flavio'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('sem registro de proveniência'), findsOneWidget);
    });

    testWidgets('DbQueryView real: recusa edição quando conexão selecionada diverge da conexão utilizada na consulta', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
        onSchema: (c, table, schema) async => const DbResult(columns: [], rows: [], elapsed: Duration.zero),
      );

      final session = FileViewerSession(
        id: 'session_query_conn_mismatch',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        view: const FileViewText('-- db: appdb\nSELECT id, username FROM users;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'outra_conexao';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
        ],
        rows: [
          [42, 'flavio'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      expect(find.text('Não foi possível editar'), findsOneWidget);
      expect(find.textContaining('diverge da conexão utilizada na consulta'), findsOneWidget);
    });

    testWidgets('DbQueryView real: sobrevive a remount e ignora alteração de SQL não executado no editor, usando proveniência de lastExecutedSql', (tester) async {
      final conn = DbConnection.sqlite(
        'appdb',
        '/tmp/test.db',
      );
      String? executedDmlSql;

      final vm = _createTestDatabaseVm(
        conn: conn,
        onQuery: (c, sql, limit) async => sampleResult,
        onExecute: (c, sql) async {
          executedDmlSql = sql;
          return const DbResult(columns: [], rows: [], elapsed: Duration.zero, affectedRows: 1);
        },
        onSchema: (c, table, schema) async {
          return const DbResult(
            columns: [
              DbColumn('column', 'TEXT'),
              DbColumn('type', 'TEXT'),
              DbColumn('nullable', 'INTEGER'),
              DbColumn('primaryKey', 'INTEGER'),
            ],
            rows: [
              ['id', 'INTEGER', 0, 1],
              ['username', 'TEXT', 1, 0],
            ],
            elapsed: Duration(milliseconds: 1),
          );
        },
      );

      final session = FileViewerSession(
        id: 'session_query_remount',
        projectId: 'proj1',
        path: '/ws/query.dbq',
        // O texto do editor foi alterado para outra tabela não executada, mas o resultado é da tabela users
        view: const FileViewText('-- db: appdb\nSELECT other AS id, val FROM tabela_nao_executada;'),
      );

      final tabState = vm.tabStateFor(session.id);
      tabState.lastExecutedSql = 'SELECT id, username FROM users;';
      tabState.executedConnName = 'appdb';
      tabState.result = DbResult(
        columns: const [
          DbColumn('id', 'INTEGER'),
          DbColumn('username', 'TEXT'),
        ],
        rows: [
          [42, 'flavio'],
        ],
        elapsed: const Duration(milliseconds: 10),
      );

      // Simula montagem do widget (remount de tab)
      await tester.pumpWidget(
        _wrapWithTheme(
          DbQueryView(
            session: session,
            active: true,
            focused: true,
            workspaceRoot: '/ws',
            onSave: (c) async => true,
            databaseViewModel: vm,
            menuBridge: EditorMenuBridge(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('flavio'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('flavio'));
      await tester.pumpAndSettle();

      // Confirma que abriu o diálogo de edição usando a tabela 'users' (proveniente de lastExecutedSql)
      // e não recusou pelo SQL não executado no editor
      expect(find.byKey(const ValueKey('db-grid-cell-edit-input')), findsOneWidget);
      await tester.enterText(find.byKey(const ValueKey('db-grid-cell-edit-input')), 'flavio_remount');
      await tester.tap(find.byKey(const ValueKey('db-grid-cell-edit-save')));
      await tester.pumpAndSettle();

      expect(executedDmlSql, isNotNull);
      expect(executedDmlSql, contains('UPDATE "users" SET "username" = \'flavio_remount\''));
      expect(executedDmlSql, contains('WHERE "id" = 42 AND "username" = \'flavio\';'));
      expect(find.text('flavio_remount'), findsOneWidget);
    });
  });
}
