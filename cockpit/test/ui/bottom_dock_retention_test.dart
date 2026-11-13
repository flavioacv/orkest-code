import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/ui/widgets/bottom_dock_host.dart';

void main() {
  testWidgets('Git input survives dock collapse and switching to debug', (
    tester,
  ) async {
    Widget host(bool open, BottomDockTab tab) => MaterialApp(
      home: Scaffold(
        body: BottomDockHost(
          isOpen: open,
          selectedTab: tab,
          onTabSelected: (_) {},
          onClose: () {},
          height: 250,
          gitContent: const TextField(key: ValueKey('git-persistent-input')),
          debugContent: const Text('debug'),
        ),
      ),
    );
    await tester.pumpWidget(host(true, BottomDockTab.git));
    await tester.enterText(
      find.byKey(const ValueKey('git-persistent-input')),
      'feature/test',
    );
    await tester.pumpWidget(host(false, BottomDockTab.git));
    await tester.pumpAndSettle();
    await tester.pumpWidget(host(true, BottomDockTab.debug));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('git-persistent-input')), findsNothing);
    await tester.pumpWidget(host(true, BottomDockTab.git));
    await tester.pumpAndSettle();
    expect(find.text('feature/test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
