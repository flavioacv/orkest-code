import 'dart:ui' as ui;

import 'package:flterm/terminal_contrast.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/terminal/orkest_terminal_painter.dart';
import 'package:orkest_code/app/core/terminal/xterm/src/ui/painter.dart';
import 'package:orkest_code/app/core/terminal/xterm/xterm.dart';
import 'package:orkest_code/app/core/ui/themes/color_contrast.dart';
import 'package:orkest_code/app/core/ui/themes/terminal_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('light backgrounds retain readable RGB, grayscale and faint text', () {
    final contrast = TerminalForegroundContrast();
    for (final background in [
      const Color(0xFFFFFFFF),
      const Color(0xFFF0EBDD),
    ]) {
      for (final foreground in [
        const Color(0xFFFFFFFF),
        const Color(0xFFEEEEEE),
        const Color(0xFF87D7FF),
        const Color(0xFFFFFF00),
        const Color(0x8024292F),
      ]) {
        final result = contrast.resolve(foreground, background);
        expect(
          contrastRatio(Color.alphaBlend(result, background), background),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
    const dark = Color(0xFF24292F);
    const white = Color(0xFFFFFFFF);
    expect(contrast.resolve(dark, white), dark);
    expect(contrast.resolve(white, dark), white);
    expect(
      TerminalForegroundContrast(minimumRatio: 1).resolve(white, white),
      white,
    );
  });

  for (final legacy in [false, true]) {
    test(
      'actual ${legacy ? 'xterm' : 'Orkest'} painter fixes light palette/RGB and preserves explicit dark backgrounds',
      () async {
        final modern = OrkestTerminalPainter(
          theme: orkestTerminalThemeLight,
          textStyle: const TerminalStyle(),
          textScaler: TextScaler.noScaling,
          devicePixelRatio: 1,
        );
        final original = TerminalPainter(
          theme: orkestTerminalThemeLight,
          textStyle: const TerminalStyle(),
          textScaler: TextScaler.noScaling,
        );
        Future<Color> render(
          int foreground, {
          int background = 0,
          int flags = 0,
        }) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawColor(orkestTerminalThemeLight.background, BlendMode.src);
          final cell = CellData(
            foreground: foreground,
            background: background,
            flags: flags,
            content: 0x2588 | (1 << CellContent.widthShift),
          );
          if (legacy) {
            original.paintCell(canvas, Offset.zero, cell);
          } else {
            modern.paintCell(canvas, Offset.zero, cell);
          }
          final picture = recorder.endRecording();
          final image = await picture.toImage(4, 4);
          final bytes = (await image.toByteData())!;
          final color = Color.fromARGB(
            bytes.getUint8(3),
            bytes.getUint8(0),
            bytes.getUint8(1),
            bytes.getUint8(2),
          );
          image.dispose();
          picture.dispose();
          return color;
        }

        for (final foreground in [
          CellColor.palette | 255,
          CellColor.rgb | 0xFFFFFF,
          CellColor.palette | 159,
        ]) {
          final color = await render(foreground);
          expect(
            contrastRatio(color, orkestTerminalThemeLight.background),
            greaterThanOrEqualTo(4.5),
          );
        }
        final faint = await render(CellColor.normal, flags: CellFlags.faint);
        expect(
          contrastRatio(faint, orkestTerminalThemeLight.background),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          await render(
            CellColor.rgb | 0xFFFFFF,
            background: CellColor.rgb | 0x101010,
          ),
          const Color(0xFFFFFFFF),
        );
        expect(
          await render(
            CellColor.rgb | 0xFFFFFF,
            background: CellColor.rgb | 0x101010,
            flags: CellFlags.inverse,
          ),
          const Color(0xFF101010),
        );
        modern.theme = orkestTerminalThemeDark;
        original.theme = orkestTerminalThemeDark;
        expect(await render(CellColor.palette | 255), const Color(0xFFEEEEEE));
        modern.theme = orkestTerminalThemeLight;
        original.theme = orkestTerminalThemeLight;
        expect(
          contrastRatio(
            await render(CellColor.palette | 255),
            orkestTerminalThemeLight.background,
          ),
          greaterThanOrEqualTo(4.5),
        );
      },
    );
  }
}
