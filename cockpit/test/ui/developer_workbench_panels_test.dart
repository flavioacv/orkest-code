import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/developer_workbench_panels.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class _WorkbenchVm extends ChangeNotifier implements OrkestViewModel {
  final controller = DebugSessionController();
  final changes = StreamController<String>.broadcast();
  final Map<String, Future<List<LspDocumentSymbol>>> documents = {};
  (String, int, int)? navigation;
  @override
  Stream<String> get documentChanges => changes.stream;
  @override
  Future<List<LspDocumentSymbol>> documentSymbols(String path) =>
      documents[path] ?? Future.value([]);
  @override
  DebugSessionController debugForWorkspace(String workspaceId) => controller;
  @override
  Future<void> navigateToSource(String path, int line, int column) async {
    navigation = (path, line, column);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
  @override
  void dispose() {
    controller.dispose();
    unawaited(changes.close());
    super.dispose();
  }
}

Widget _wrap(Widget child) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: Scaffold(
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(width: 300, height: 550, child: child),
          ),
        ),
      ),
    ),
  );
}

LspDocumentSymbol _symbol(String name) => LspDocumentSymbol(
  name: name,
  kind: LspSymbolKind.classType,
  range: const LspRange(LspPosition(2, 3), LspPosition(4, 0)),
  selectionRange: const LspRange(LspPosition(2, 3), LspPosition(2, 8)),
);

void main() {
  testWidgets('collapsed host preserves Debug constraints and mounted state', (
    tester,
  ) async {
    final vm = _WorkbenchVm();
    addTearDown(vm.dispose);
    Widget host(bool collapsed) => _wrap(
      Align(
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: collapsed ? 44 : 300,
          child: WorkbenchToolHost(
            selectedId: 'debug',
            isCollapsed: collapsed,
            onSelected: (_) {},
            tools: [
              WorkbenchTool(
                id: 'debug',
                title: 'Debug',
                icon: LucideIcons.bug,
                builder: (_) => WorkspaceDebugPanel(
                  vm: vm,
                  workspaceId: 'workspace',
                  root: '',
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpWidget(host(false));
    await tester.pumpAndSettle();
    final state = tester.state(find.byType(WorkspaceDebugPanel));
    await tester.pumpWidget(host(true));
    await tester.pumpAndSettle();
    expect(
      tester.state(find.byType(WorkspaceDebugPanel, skipOffstage: false)),
      same(state),
    );
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(host(false));
    await tester.pumpAndSettle();
    expect(tester.state(find.byType(WorkspaceDebugPanel)), same(state));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
    'outline receives live document changes and rejects obsolete responses',
    (tester) async {
      final vm = _WorkbenchVm();
      addTearDown(vm.dispose);
      vm.documents['/a.dart'] = Future.value([_symbol('First')]);
      await tester.pumpWidget(
        _wrap(WorkspaceOutlinePanel(vm: vm, path: '/a.dart')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('First'));
      expect(vm.navigation, ('/a.dart', 3, 4));
      final stale = Completer<List<LspDocumentSymbol>>();
      vm.documents['/a.dart'] = stale.future;
      vm.changes.add('/a.dart');
      await tester.pump();
      vm.documents['/b.dart'] = Future.value([_symbol('Current')]);
      await tester.pumpWidget(
        _wrap(WorkspaceOutlinePanel(vm: vm, path: '/b.dart')),
      );
      await tester.pumpAndSettle();
      stale.complete([_symbol('Obsolete')]);
      await tester.pumpAndSettle();
      expect(find.text('Current'), findsOneWidget);
      expect(find.text('Obsolete'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'production debug wrapper loads contextual configuration at workbench width',
    (tester) async {
      final vm = _WorkbenchVm();
      final root = Directory.systemTemp.createTempSync('orkest-debug-panel-');
      addTearDown(() => root.deleteSync(recursive: true));
      addTearDown(vm.dispose);
      await tester.runAsync(() async {
        await tester.pumpWidget(
          _wrap(
            WorkspaceDebugPanel(
              vm: vm,
              workspaceId: 'workspace',
              root: root.path,
              path: '${root.path}/main.dart',
            ),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('Run: main.dart'), findsOneWidget);
      expect(find.text('Run / Test (terminal)'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
