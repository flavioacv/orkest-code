import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flterm/flterm.dart' as ghost;
import 'package:flterm/terminal_contrast.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/ui/themes/color_contrast.dart';

void main() {
  test(
    'light text is stronger without flattening colors or changing dark mode',
    () {
      const background = Color(0xFFFFFDF0);
      final contrast = TerminalForegroundContrast(
        minimumRatio: terminalLightTextMinimumContrast,
      );
      for (final original in [
        const Color(0xFF9CA3AF),
        const Color(0xFF82AAFF),
        const Color(0xFFAAE3A1),
        const Color(0x80A0A0A0),
      ]) {
        final resolved = contrast.resolve(original, background);
        expect(contrastRatio(resolved, background), greaterThanOrEqualTo(7));
        if (original.r != original.g || original.g != original.b) {
          expect(resolved.r == resolved.g && resolved.g == resolved.b, isFalse);
        }
        expect(
          TerminalForegroundContrast(
            minimumRatio: 1,
          ).resolve(original, const Color(0xFF18181B)),
          original,
        );
      }
    },
  );

  testWidgets(
    'light agent text and dark composer stay readable while the real logo remains colored',
    (tester) async {
      final controller = ghost.TerminalController();
      final boundary = GlobalKey();
      const background = Color(0xFFFFFDF0);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 700,
              height: 400,
              child: RepaintBoundary(
                key: boundary,
                child: ghost.TerminalView(
                  controller: controller,
                  padding: EdgeInsets.zero,
                  theme: ghost.TerminalTheme.light().copyWith(
                    palette: ghost.TerminalTheme.light().palette.copyWith(
                      background: background,
                    ),
                    minimumContrast: terminalLightTextMinimumContrast,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      Future<ui.Image> snapshot() async =>
          (boundary.currentContext!.findRenderObject()!
                  as RenderRepaintBoundary)
              .toImage(pixelRatio: 1);
      Future<void> check(
        String ansi, {
        required Color surface,
        required bool chromatic,
      }) async {
        controller.write(utf8.encode('\x1b[0m\x1b[H\x1b[2J$ansi\x1b[?25l'));
        await tester.pumpAndSettle();
        await tester.runAsync(() async {
          final image = await snapshot();
          final bytes = (await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          ))!;
          Color pixel(int x, int y) {
            final offset = (y * image.width + x) * 4;
            return Color.fromARGB(
              bytes.getUint8(offset + 3),
              bytes.getUint8(offset),
              bytes.getUint8(offset + 1),
              bytes.getUint8(offset + 2),
            );
          }

          // A full block supplies solid ink, and the following spaces the field.
          final ink = pixel(2, 5);
          expect(contrastRatio(ink, surface), greaterThanOrEqualTo(7));
          if (chromatic) expect(ink.b, greaterThan(ink.r));
          expect(pixel(25, 5), surface);
          image.dispose();
        });
      }

      await check(
        '\x1b[38;2;156;163;175m█    ',
        surface: background,
        chromatic: false,
      );
      await check(
        '\x1b[38;2;130;170;255m█    ',
        surface: background,
        chromatic: true,
      );
      await check(
        '\x1b[48;2;55;55;55m\x1b[30m█    ',
        surface: const Color(0xFF373737),
        chromatic: false,
      );
      await check(
        '\x1b[48;2;55;55;55m\x1b[30mX    ',
        surface: const Color(0xFF373737),
        chromatic: false,
      );
      await check(
        '\x1b[48;2;55;55;55m\x1b[2;38;2;80;80;80m█    ',
        surface: const Color(0xFF373737),
        chromatic: false,
      );
      controller.write(utf8.encode('\x1b[0m\x1b[H\x1b[2J'));
      controller.write(
        File('test/fixtures/antigravity_startup_logo.ansi').readAsBytesSync(),
      );
      controller.write(utf8.encode('\x1b[?25l'));
      controller.write(
        utf8.encode(
          '\x1b[1;24H\x1b[38;2;130;170;255mAntigravity CLI\x1b[0m'
          '\x1b[2;24H\x1b[38;2;156;163;175mAgent session / workspace'
          '\x1b[3;24HReadable secondary text in light mode'
          '\x1b[8;1H\x1b[38;2;170;227;161mColored commands and links remain colored'
          '\x1b[10;1H\x1b[0m\x1b[48;2;55;55;55m\x1b[30m'
          '> Entrada do terminal: texto legível sobre fundo escuro           '
          '\x1b[0m\x1b[12;1H\x1b[38;2;156;163;175mSecondary hints have stronger contrast',
        ),
      );
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final image = await snapshot();
        final bytes = (await image.toByteData(
          format: ui.ImageByteFormat.rawRgba,
        ))!;
        final colors = <int>{};
        var colored = 0;
        for (var i = 0; i < bytes.lengthInBytes; i += 4) {
          final r = bytes.getUint8(i),
              g = bytes.getUint8(i + 1),
              b = bytes.getUint8(i + 2);
          if ((r - g).abs() > 30 || (g - b).abs() > 30) {
            colored++;
            colors.add((r << 16) | (g << 8) | b);
          }
        }
        expect(colored, greaterThan(500));
        expect(colors.length, greaterThanOrEqualTo(8));
        final png = (await image.toByteData(format: ui.ImageByteFormat.png))!;
        await File(
          '${Directory.systemTemp.path}/orkest-terminal-light-readability.png',
        ).writeAsBytes(png.buffer.asUint8List());
        image.dispose();
      });
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      expect(tester.takeException(), isNull);
    },
  );
}
