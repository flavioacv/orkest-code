import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/ui/widgets/bottom_dock_host.dart';

void main() {
  group('BottomStripeBar & BottomDockHost Tests', () {
    testWidgets('LeftToolStripe renderiza workspaces no topo e ferramentas no canto inferior esquerdo', (tester) async {
      bool railToggled = false;
      BottomDockTab? bottomTab;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: LeftToolStripe(
              isRailOpen: true,
              onToggleRail: () => railToggled = true,
              isBottomDockOpen: false,
              bottomDockTab: BottomDockTab.debug,
              onToggleBottomDock: (tab) => bottomTab = tab,
              problemsCount: 3,
              isDebugging: true,
            ),
          ),
        ),
      );

      // Topo: workspaces
      expect(find.byKey(const ValueKey('left-stripe-workspaces')), findsOneWidget);

      // Base: Git, Debug, Problems
      expect(find.byKey(const ValueKey('left-stripe-git')), findsOneWidget);
      expect(find.byKey(const ValueKey('left-stripe-debug')), findsOneWidget);
      expect(find.byKey(const ValueKey('left-stripe-problems')), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      // Clica em Workspaces
      await tester.tap(find.byKey(const ValueKey('left-stripe-workspaces')));
      await tester.pump();
      expect(railToggled, isTrue);

      // Clica em Git
      await tester.tap(find.byKey(const ValueKey('left-stripe-git')));
      await tester.pump();
      expect(bottomTab, equals(BottomDockTab.git));
    });

    testWidgets('RailBottomDockTools renderiza no canto esquerdo e responde aos cliques', (tester) async {
      BottomDockTab? clickedTab;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: RailBottomDockTools(
              isOpen: false,
              selectedTab: BottomDockTab.debug,
              onToggleTab: (tab) => clickedTab = tab,
              problemsCount: 2,
              isDebugging: true,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('rail-tool-btn-git')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-tool-btn-debug')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-tool-btn-problems')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rail-tool-btn-git')));
      await tester.pump();
      expect(clickedTab, equals(BottomDockTab.git));
    });

    testWidgets('BottomDockHost exibe conteúdo correto conforme selectedTab e permite fechar', (tester) async {
      bool closed = false;
      BottomDockTab currentTab = BottomDockTab.debug;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BottomDockHost(
              isOpen: true,
              selectedTab: currentTab,
              onTabSelected: (tab) => currentTab = tab,
              onClose: () => closed = true,
              height: 250,
              gitContent: const Text('CONTEUDO_GIT'),
              debugContent: const Text('CONTEUDO_DEBUG'),
              problemsContent: const Text('CONTEUDO_PROBLEMS'),
            ),
          ),
        ),
      );

      // Com selectedTab = debug, CONTEUDO_DEBUG deve estar visível
      expect(find.text('CONTEUDO_DEBUG'), findsOneWidget);
      expect(find.text('CONTEUDO_GIT'), findsNothing);
      expect(find.text('CONTEUDO_PROBLEMS'), findsNothing);

      // Clica no botão de fechar (×)
      final closeButton = find.byKey(const ValueKey('bottom-dock-close'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      expect(closed, isTrue);
    });

    testWidgets('BottomDockHost exibe git quando selectedTab é git', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BottomDockHost(
              isOpen: true,
              selectedTab: BottomDockTab.git,
              onTabSelected: (_) {},
              onClose: () {},
              height: 250,
              gitContent: const Text('CONTEUDO_GIT'),
              debugContent: const Text('CONTEUDO_DEBUG'),
              problemsContent: const Text('CONTEUDO_PROBLEMS'),
            ),
          ),
        ),
      );

      expect(find.text('CONTEUDO_GIT'), findsOneWidget);
      expect(find.text('CONTEUDO_DEBUG'), findsNothing);
    });

    testWidgets('BottomDockHost exibe problems quando selectedTab é problems', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BottomDockHost(
              isOpen: true,
              selectedTab: BottomDockTab.problems,
              onTabSelected: (_) {},
              onClose: () {},
              height: 250,
              gitContent: const Text('CONTEUDO_GIT'),
              debugContent: const Text('CONTEUDO_DEBUG'),
              problemsContent: const Text('CONTEUDO_PROBLEMS'),
            ),
          ),
        ),
      );

      expect(find.text('CONTEUDO_PROBLEMS'), findsOneWidget);
      expect(find.text('CONTEUDO_DEBUG'), findsNothing);
    });
  });
}
