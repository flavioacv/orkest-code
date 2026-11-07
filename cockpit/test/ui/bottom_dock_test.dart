import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/ui/widgets/bottom_dock_host.dart';

void main() {
  group('BottomStripeBar & BottomDockHost Tests', () {
    testWidgets('BottomStripeBar renderiza abas Debug, Terminal, Problems e responde a cliques', (tester) async {
      BottomDockTab? toggledTab;

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: BottomStripeBar(
              isOpen: true,
              selectedTab: BottomDockTab.debug,
              onToggleTab: (tab) {
                toggledTab = tab;
              },
              problemsCount: 5,
              rightWidget: const Text('LSP Ready'),
            ),
          ),
        ),
      );

      // Verifica itens do canto esquerdo
      expect(find.text('Debug'), findsOneWidget);
      expect(find.text('Terminal'), findsOneWidget);
      expect(find.text('Problems'), findsOneWidget);
      expect(find.text('5'), findsOneWidget); // Badge de problems
      expect(find.text('LSP Ready'), findsOneWidget); // Status do lado direito

      // Clica no Terminal
      await tester.tap(find.text('Terminal'));
      await tester.pump();
      expect(toggledTab, equals(BottomDockTab.terminal));

      // Clica em Problems
      await tester.tap(find.text('Problems'));
      await tester.pump();
      expect(toggledTab, equals(BottomDockTab.problems));
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

      expect(find.byKey(const ValueKey('rail-tool-btn-debug')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-tool-btn-terminal')), findsOneWidget);
      expect(find.byKey(const ValueKey('rail-tool-btn-problems')), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('rail-tool-btn-debug')));
      await tester.pump();
      expect(clickedTab, equals(BottomDockTab.debug));
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
              debugContent: const Text('CONTEUDO_DEBUG'),
              terminalContent: const Text('CONTEUDO_TERMINAL'),
              problemsContent: const Text('CONTEUDO_PROBLEMS'),
            ),
          ),
        ),
      );

      // Com selectedTab = debug, CONTEUDO_DEBUG deve estar visível
      expect(find.text('CONTEUDO_DEBUG'), findsOneWidget);
      expect(find.text('CONTEUDO_TERMINAL'), findsNothing);
      expect(find.text('CONTEUDO_PROBLEMS'), findsNothing);

      // Clica no botão de fechar (×)
      final closeButton = find.byKey(const ValueKey('bottom-dock-close'));
      expect(closeButton, findsOneWidget);
      await tester.tap(closeButton);
      await tester.pump();
      expect(closed, isTrue);
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
              debugContent: const Text('CONTEUDO_DEBUG'),
              terminalContent: const Text('CONTEUDO_TERMINAL'),
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
