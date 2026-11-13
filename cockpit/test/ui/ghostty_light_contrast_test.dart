import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flterm/flterm.dart' as ghost;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/color_contrast.dart';

void main() {
  testWidgets(
    'Ghostty paints RGB and default white text legibly on a light surface',
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
      for (final prefix in [
        '\x1b[38;2;255;255;255m',
        '\x1b]10;#ffffff\x07\x1b[0m',
      ]) {
        controller.write(utf8.encode('\x1b[H\x1b[2J$prefix█\x1b[?25l'));
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
          greaterThanOrEqualTo(4.5),
        );
      }
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
