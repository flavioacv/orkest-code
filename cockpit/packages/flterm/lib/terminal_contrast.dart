import 'dart:ui';

/// Keeps terminal colors distinguishable against their effective backgrounds.
///
/// Colors are resolved after inverse and faint attributes. The bounded cache
/// avoids repeating luminance calculations for every glyph in a terminal row.
final class TerminalForegroundContrast {
  TerminalForegroundContrast({this.minimumRatio = 4.5});

  final double minimumRatio;
  final _cache = <(Color, Color), Color>{};

  Color resolve(Color foreground, Color background) {
    if (minimumRatio <= 1) return foreground;
    final key = (foreground, background);
    final cached = _cache[key];
    if (cached != null) return cached;
    final result = _resolve(foreground, background);
    if (_cache.length >= 1024) _cache.clear();
    return _cache[key] = result;
  }

  Color _resolve(Color foreground, Color background) {
    final luminance = background.computeLuminance();
    final visible = Color.alphaBlend(foreground, background);
    double ratio(Color color) {
      final other = color.computeLuminance();
      return luminance >= other
          ? (luminance + .05) / (other + .05)
          : (other + .05) / (luminance + .05);
    }

    if (ratio(visible) >= minimumRatio) return foreground;
    var low = 0.0;
    var high = 1.0;
    const black = Color(0xFF000000);
    const white = Color(0xFFFFFFFF);
    final target = ratio(black) >= ratio(white) ? black : white;
    var result = target;
    for (var i = 0; i < 12; i++) {
      final amount = (low + high) / 2;
      // Validate the same 8-bit color that the canvas/atlas will paint.
      final candidate = Color(Color.lerp(visible, target, amount)!.toARGB32());
      if (ratio(candidate) >= minimumRatio) {
        result = candidate;
        high = amount;
      } else {
        low = amount;
      }
    }
    return result;
  }
}
