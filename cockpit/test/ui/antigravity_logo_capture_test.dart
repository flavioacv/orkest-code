import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flterm/flterm.dart' as ghost;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  testWidgets(
    'real Antigravity startup retains its 16 RGB background logo blocks in light mode',
    (tester) async {
      final controller = ghost.TerminalController();
      final boundary = GlobalKey();
      await tester.pumpWidget(
        MediaQuery(
          data: const MediaQueryData(size: Size(220, 150)),
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: Align(
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: 220,
                height: 150,
                child: RepaintBoundary(
                  key: boundary,
                  child: ghost.TerminalView(
                    controller: controller,
                    padding: EdgeInsets.zero,
                    theme: ghost.TerminalTheme.light().copyWith(
                      minimumContrast: 4.5,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final capture = File(
        'test/fixtures/antigravity_startup_logo.ansi',
      ).readAsBytesSync();
      controller.write(capture);
      controller.write(Uint8List.fromList([27, 91, 63, 50, 53, 108]));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final render =
            boundary.currentContext!.findRenderObject()!
                as RenderRepaintBoundary;
        final image = await render.toImage(pixelRatio: 1);
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final colors = <int>{};
        var coloredPixels = 0;
        for (var offset = 0; offset < bytes.lengthInBytes; offset += 4) {
          final r = bytes.getUint8(offset);
          final g = bytes.getUint8(offset + 1);
          final b = bytes.getUint8(offset + 2);
          if ((r - g).abs() > 20 || (g - b).abs() > 20) {
            coloredPixels++;
            colors.add((r << 16) | (g << 8) | b);
          }
        }
        expect(coloredPixels, greaterThan(500));
        expect(colors.length, greaterThanOrEqualTo(8));
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File(
          p.join(
            Directory.systemTemp.path,
            'orkest-antigravity-logo-light.png',
          ),
        ).writeAsBytes(png.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
