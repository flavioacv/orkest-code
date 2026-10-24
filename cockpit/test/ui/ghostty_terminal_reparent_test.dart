import 'dart:typed_data';

import 'package:flterm/flterm.dart' as ghost;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('terminal survives GlobalKey moves and workspace removal', (
    tester,
  ) async {
    final controller = ghost.TerminalController();
    final key = GlobalKey();
    Widget app({required bool wrapped}) {
      final terminal = ghost.TerminalView(key: key, controller: controller);
      return MediaQuery(
        data: const MediaQueryData(size: Size(800, 400)),
        child: Directionality(
          textDirection: TextDirection.ltr,
          child: SizedBox(
            width: 800,
            height: 400,
            child: wrapped
                ? Stack(children: [Positioned.fill(child: terminal)])
                : terminal,
          ),
        ),
      );
    }

    await tester.pumpWidget(app(wrapped: false));
    final state = key.currentState;
    for (final wrapped in [true, false, true]) {
      await tester.pumpWidget(app(wrapped: wrapped));
      expect(tester.takeException(), isNull);
      expect(key.currentState, same(state));
      controller.write(Uint8List.fromList('still alive\r\n'.codeUnits));
      await tester.pump();
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
