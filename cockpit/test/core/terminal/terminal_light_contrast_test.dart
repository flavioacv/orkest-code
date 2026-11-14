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
    final contrast = TerminalForegroundContrast(
      minimumRatio: terminalLightTextMinimumContrast,
    );
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
          greaterThanOrEqualTo(terminalLightTextMinimumContrast),
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
          int codepoint = 0x2588,
          bool sampleInk = false,
        }) async {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawColor(orkestTerminalThemeLight.background, BlendMode.src);
          final cell = CellData(
            foreground: foreground,
            background: background,
            flags: flags,
            content: codepoint | (1 << CellContent.widthShift),
          );
          if (legacy) {
            original.paintCell(canvas, Offset.zero, cell);
          } else {
            modern.paintCell(canvas, Offset.zero, cell);
          }
          final picture = recorder.endRecording();
          final size = legacy ? original.cellSize : modern.cellSize;
          final image = await picture.toImage(
            size.width.ceil(),
            size.height.ceil(),
          );
          final bytes = (await image.toByteData())!;
          var color = Color.fromARGB(
            bytes.getUint8(3),
            bytes.getUint8(0),
            bytes.getUint8(1),
            bytes.getUint8(2),
          );
          if (sampleInk) {
            for (var offset = 0; offset < bytes.lengthInBytes; offset += 4) {
              final pixel = Color.fromARGB(
                bytes.getUint8(offset + 3),
                bytes.getUint8(offset),
                bytes.getUint8(offset + 1),
                bytes.getUint8(offset + 2),
              );
              if (contrastRatio(pixel, orkestTerminalThemeLight.background) >
                  contrastRatio(color, orkestTerminalThemeLight.background)) {
                color = pixel;
              }
            }
          }
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
            greaterThanOrEqualTo(terminalLightTextMinimumContrast),
          );
        }
        for (final codepoint in [
          0x2500,
          0x2502,
          0x250C,
          0x2580,
          0x2584,
          0x28FF,
        ]) {
          final graphic = await render(
            CellColor.rgb | 0xEEEEEE,
            codepoint: codepoint,
            sampleInk: true,
          );
          expect(
            contrastRatio(graphic, orkestTerminalThemeLight.background),
            greaterThanOrEqualTo(1.5),
            reason:
                'agent logo/border U+${codepoint.toRadixString(16)} must remain visible',
          );
        }
        final faint = await render(CellColor.normal, flags: CellFlags.faint);
        expect(
          contrastRatio(faint, orkestTerminalThemeLight.background),
          greaterThanOrEqualTo(terminalLightTextMinimumContrast),
        );
        for (final background in [
          CellColor.rgb | 0xFFFFFF,
          CellColor.palette | 255,
          CellColor.rgb | 0xFFFFAA,
        ]) {
          final field = await render(
            CellColor.normal,
            background: background,
            codepoint: 0x20,
          );
          expect(
            contrastRatio(field, orkestTerminalThemeLight.background),
            greaterThanOrEqualTo(1.5),
          );
          final ink = await render(
            CellColor.rgb | 0xEEEEEE,
            background: background,
          );
          expect(
            contrastRatio(ink, field),
            greaterThanOrEqualTo(terminalLightTextMinimumContrast),
          );
        }
        expect(
          await render(CellColor.normal, codepoint: 0x20),
          orkestTerminalThemeLight.background,
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
        expect(
          await render(
            CellColor.normal,
            background: CellColor.rgb | 0xFFFFFF,
            codepoint: 0x20,
          ),
          const Color(0xFFFFFFFF),
        );
        expect(await render(CellColor.palette | 255), const Color(0xFFEEEEEE));
        modern.theme = orkestTerminalThemeLight;
        original.theme = orkestTerminalThemeLight;
        expect(
          contrastRatio(
            await render(CellColor.palette | 255),
            orkestTerminalThemeLight.background,
          ),
          greaterThanOrEqualTo(terminalLightTextMinimumContrast),
        );
      },
    );
  }
}
