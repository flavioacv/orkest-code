import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

void main() {
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
