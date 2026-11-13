import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flterm/flterm.dart' as ghost;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/color_contrast.dart';

void main() {
  testWidgets(
    'Ghostty preserves agent glyphs and distinguishes explicit logo/input backgrounds',
    (tester) async {
      final controller = ghost.TerminalController();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(240, 100)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: RepaintBoundary(
              key: boundary,
              child: ghost.TerminalView(
                padding: EdgeInsets.zero,
                controller: controller,
                theme: ghost.TerminalTheme.light().copyWith(
                  minimumContrast: 4.5,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      for (final (content, minimum) in [
        ('\x1b[38;2;255;255;255m█', 4.5),
        ('\x1b]10;#ffffff\x07\x1b[0m█', 4.5),
        ('\x1b[0m\x1b[48;2;250;250;250m ', 1.5),
        ('\x1b[0m\x1b[48;5;255m ', 1.5),
        ('\x1b[0m\x1b[48;2;255;255;170m ', 1.5),
      ]) {
        controller.write(utf8.encode('\x1b[0m\x1b[H\x1b[2J$content\x1b[?25l'));
        await tester.pumpAndSettle();
        final pixel = await tester.runAsync(() async {
          final render =
              boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary;
          final image = await render.toImage(pixelRatio: 1);
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          final offset = (5 * image.width + 2) * 4;
          final result = Color.fromARGB(
            bytes.getUint8(offset + 3),
            bytes.getUint8(offset),
            bytes.getUint8(offset + 1),
            bytes.getUint8(offset + 2),
          );
          image.dispose();
          return result;
        });
        expect(
          contrastRatio(pixel!, ghost.TerminalTheme.light().background),
          greaterThanOrEqualTo(minimum),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
