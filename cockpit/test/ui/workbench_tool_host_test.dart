import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
  testWidgets(
    'selecting a collapsed tool expands exactly once when the owner also expands on selection',
    (tester) async {
      var collapsed = true;
      var selected = 'files';
      await tester.pumpWidget(
        ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: SizedBox(
              width: 300,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) => WorkbenchToolHost(
                  isCollapsed: collapsed,
                  selectedId: selected,
                  onSelected: (id) => setState(() {
                    selected = id;
                    collapsed = false;
                  }),
                  onToggleCollapse: () =>
                      setState(() => collapsed = !collapsed),
                  tools: [
                    WorkbenchTool(
                      id: 'files',
                      title: 'Files',
                      icon: Icons.folder,
                      builder: (_) => const Text('Files content'),
                    ),
                    WorkbenchTool(
                      id: 'debug',
                      title: 'Debug',
                      icon: Icons.bug_report,
                      builder: (_) => const Text('Debug content'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('debug-collapsed-tab')));
      await tester.pumpAndSettle();
      expect(collapsed, isFalse);
      expect(selected, 'debug');
      expect(find.byKey(const ValueKey('workbench-tool-expand')), findsNothing);
      expect(find.text('Debug content'), findsOneWidget);
    },
  );

  testWidgets('tools mount lazily and retain state while hidden', (
    tester,
  ) async {
    var selected = 'files';
    var showDatabase = true;
    var mounts = 0;
    var disposals = 0;
    late StateSetter rebuild;
    await tester.pumpWidget(
      ShadcnApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: Scaffold(
          child: SizedBox(
            width: 300,
            height: 400,
            child: StatefulBuilder(
              builder: (context, setState) {
                rebuild = setState;
                return WorkbenchToolHost(
                  selectedId: selected,
                  onSelected: (id) => setState(() => selected = id),
                  tools: [
                    WorkbenchTool(
                      id: 'files',
                      title: 'Files',
                      icon: Icons.folder,
                      builder: (_) => const Text('Files content'),
                    ),
                    if (showDatabase)
                      WorkbenchTool(
                        id: 'database',
                        title: 'Database',
                        icon: Icons.storage,
                        builder: (_) => _Probe(
                          onMount: () => mounts++,
                          onDispose: () => disposals++,
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
    expect(mounts, 0);
    await tester.tap(find.byKey(const ValueKey('database-tab')));
    await tester.pumpAndSettle();
    expect(mounts, 1);
    await tester.tap(find.byKey(const ValueKey('files-tab')));
    await tester.pumpAndSettle();
    expect(disposals, 0);
    expect(find.text('Database content'), findsNothing);
    await tester.tap(find.byKey(const ValueKey('database-tab')));
    await tester.pumpAndSettle();
    expect(mounts, 1);
    rebuild(() => showDatabase = false);
    await tester.pumpAndSettle();
    expect(disposals, 1);
    expect(find.text('Files content'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'header controls toggle maximize and collapse without disposing visited tools',
    (tester) async {
      var selected = 'files';
      var isMaximized = false;
      var isCollapsed = false;
      var probeDisposals = 0;
      var probeMounts = 0;

      await tester.pumpWidget(
        ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: SizedBox(
              width: 320,
              height: 400,
              child: StatefulBuilder(
                builder: (context, setState) {
                  return WorkbenchToolHost(
                    selectedId: selected,
                    isMaximized: isMaximized,
                    isCollapsed: isCollapsed,
                    onToggleMaximize: () =>
                        setState(() => isMaximized = !isMaximized),
                    onToggleCollapse: () =>
                        setState(() => isCollapsed = !isCollapsed),
                    onSelected: (id) => setState(() => selected = id),
                    tools: [
                      WorkbenchTool(
                        id: 'files',
                        title: 'Files',
                        icon: Icons.folder,
                        builder: (_) => const Text('Files view'),
                      ),
                      WorkbenchTool(
                        id: 'database',
                        title: 'Database',
                        icon: Icons.storage,
                        builder: (_) => _Probe(
                          onMount: () => probeMounts++,
                          onDispose: () => probeDisposals++,
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Monta database para registrar como visitado
      await tester.tap(find.byKey(const ValueKey('database-tab')));
      await tester.pumpAndSettle();
      expect(probeMounts, 1);
      expect(probeDisposals, 0);

      // Testar maximizar / restaurar
      expect(
        find.byKey(const ValueKey('workbench-tool-maximize')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('workbench-tool-maximize')));
      await tester.pumpAndSettle();
      expect(isMaximized, isTrue);

      await tester.tap(find.byKey(const ValueKey('workbench-tool-maximize')));
      await tester.pumpAndSettle();
      expect(isMaximized, isFalse);

      // Testar colapsar painel
      expect(
        find.byKey(const ValueKey('workbench-tool-collapse')),
        findsOneWidget,
      );
      await tester.tap(find.byKey(const ValueKey('workbench-tool-collapse')));
      await tester.pumpAndSettle();
      expect(isCollapsed, isTrue);

      // Na barra colapsada, os probes não foram descartados
      expect(probeDisposals, 0);
      expect(
        find.byKey(const ValueKey('workbench-tool-expand')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('files-collapsed-tab')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('database-collapsed-tab')),
        findsOneWidget,
      );

      // Clicar em files na barra recolhida reabre o painel e seleciona files
      await tester.tap(find.byKey(const ValueKey('files-collapsed-tab')));
      await tester.pumpAndSettle();
      expect(isCollapsed, isFalse);
      expect(selected, 'files');
      expect(find.text('Files view'), findsOneWidget);
      expect(probeDisposals, 0);
    },
  );
}

class _Probe extends StatefulWidget {
  const _Probe({required this.onMount, required this.onDispose});
  final VoidCallback onMount;
  final VoidCallback onDispose;
  @override
  State<_Probe> createState() => _ProbeState();
}

class _ProbeState extends State<_Probe> {
  @override
  void initState() {
    super.initState();
    widget.onMount();
  }

  @override
  void dispose() {
    widget.onDispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const Text('Database content');
}
