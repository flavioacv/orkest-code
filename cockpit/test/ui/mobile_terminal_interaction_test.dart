import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/ui/widgets/terminal_key_bar.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

void main() {
  testWidgets(
    'MobileTerminalInputDock renderiza na base e dispara callback ao tocar',
    (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        sc.ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: sc.Scaffold(
            child: SizedBox(
              width: 380,
              height: 600,
              child: Column(
                children: [
                  const Expanded(child: Text('Terminal content')),
                  MobileTerminalInputDock(
                    onTap: () => tapped = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('mobile-terminal-input-dock')), findsOneWidget);
      expect(find.text('Toque para digitar no terminal…'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_outlined), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mobile-terminal-input-dock')));
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
    },
  );

  testWidgets(
    'TerminalKeyBar envia teclas acessorias e aciona copiar/colar',
    (tester) async {
      List<int>? sentBytes;
      var copied = false;
      var pasted = false;

      await tester.pumpWidget(
        sc.ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: sc.Scaffold(
            child: SizedBox(
              width: 380,
              height: 200,
              child: TerminalKeyBar(
                onKeys: (bytes) => sentBytes = bytes,
                onCopy: () => copied = true,
                onPaste: () => pasted = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('esc'), findsOneWidget);
      expect(find.text('tab'), findsOneWidget);
      expect(find.text('⌃C'), findsOneWidget);

      await tester.tap(find.text('esc'));
      await tester.pumpAndSettle();
      expect(sentBytes, [0x1b]);

      await tester.tap(find.text('⌃C'));
      await tester.pumpAndSettle();
      expect(sentBytes, [0x03]);

      await tester.tap(find.byIcon(Icons.content_copy_outlined));
      await tester.pumpAndSettle();
      expect(copied, isTrue);

      await tester.tap(find.byIcon(Icons.content_paste_outlined));
      await tester.pumpAndSettle();
      expect(pasted, isTrue);
    },
  );
}
