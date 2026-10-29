import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';

/// Curva de desaceleração padrão do Apple HIG (`cubic-bezier(0.16, 1, 0.3, 1)`).
///
/// Usada em transições de popovers, menus, command palette e estados de hover
/// para reproduzir a física elástica e responsiva do macOS/iOS.
const Curve kAppleDecelerateCurve = Cubic(0.16, 1.0, 0.3, 1.0);

/// Fator de conversão entre um raio circular nominal (`BorderRadius.circular(r)`)
/// e o raio equivalente de uma superelipse (`ContinuousRectangleBorder`) no
/// Flutter. O `ContinuousRectangleBorder` suaviza a tangente antes do vértice,
/// exigindo ~2.2x o raio circular para aparentar a mesma curvatura óptica dos
/// *squircles* da Apple (`cornerCurve = .continuous`).
const double _kSquircleFactor = 2.2;

/// Constrói um [ShapeBorder] com curvatura contínua (*squircle* Apple HIG) para
/// um raio visual equivalente a [radius] pixels.
ContinuousRectangleBorder appleSquircleBorder({
  double radius = 10,
  BorderSide side = BorderSide.none,
}) {
  return ContinuousRectangleBorder(
    borderRadius: BorderRadius.circular(radius * _kSquircleFactor),
    side: side,
  );
}

/// Superfície translúcida no padrão **Liquid Glass / Vibrancy** do Apple HIG.
///
/// Combina:
/// - Geometria de curvatura contínua ([ClipRSuperellipse] / [ContinuousRectangleBorder]);
/// - Desfoque gaussiano de fundo ([BackdropFilter] com [blurSigma] configurável);
/// - Preenchimento translúcido calibrado para Dark Mode e Light Mode;
/// - Borda especular *hairline* de `1px` (`rgba(255,255,255,0.12)` no escuro,
///   `rgba(0,0,0,0.08)` no claro) + sombra difusa multicamada opcional.
class AppleGlassSurface extends StatelessWidget {
  const AppleGlassSurface({
    super.key,
    required this.child,
    this.radius = 10,
    this.blurSigma = 24,
    this.surfaceColor,
    this.opacity,
    this.borderColor,
    this.shadows,
    this.padding,
    this.constraints,
    this.width,
    this.height,
  });

  final Widget child;

  /// Raio visual nominal em pontos (ex: `8` para tooltips, `10` para menus,
  /// `14` para modais/palettes).
  final double radius;

  /// Intensidade do `BackdropFilter` (`sigmaX` e `sigmaY`). `0` desativa o blur.
  final double blurSigma;

  /// Cor base da superfície antes de aplicar [opacity]. Por padrão usa
  /// `context.colors.panel2`.
  final Color? surfaceColor;

  /// Opacidade do fundo translúcido. Por padrão usa `0.84` no escuro e `0.86`
  /// no claro para preservar legibilidade de texto sobre fundos complexos
  /// (código/terminal) enquanto deixa passar a cor e a luz subjacentes.
  final double? opacity;

  /// Cor da borda *hairline* de `1px`. Se omitida, calcula uma borda especular
  /// translúcida a partir de `context.colors.border2`.
  final Color? borderColor;

  /// Sombras projetadas pela superfície flutuante.
  final List<BoxShadow>? shadows;

  final EdgeInsetsGeometry? padding;
  final BoxConstraints? constraints;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.bg.computeLuminance() < 0.5;
    final baseColor = surfaceColor ?? colors.panel2;
    final effectiveOpacity = opacity ?? (isDark ? 0.84 : 0.86);
    final fill = baseColor.withValues(alpha: effectiveOpacity);

    // Borda especular de precisão (1px): sutil brilho superior/contorno no
    // escuro e traço translúcido no claro.
    final effectiveBorder =
        borderColor ??
        (isDark
            ? Color.lerp(colors.border2, const Color(0xFFFFFFFF), 0.14)!
                  .withValues(alpha: 0.72)
            : colors.border2.withValues(alpha: 0.78));

    final shape = appleSquircleBorder(
      radius: radius,
      side: BorderSide(color: effectiveBorder, width: 1),
    );

    Widget content = Container(
      width: width,
      height: height,
      constraints: constraints,
      padding: padding,
      decoration: ShapeDecoration(shape: shape, color: fill),
      child: child,
    );

    if (blurSigma > 0) {
      content = ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    } else {
      content = ClipRSuperellipse(
        borderRadius: BorderRadius.circular(radius),
        child: content,
      );
    }

    if (shadows == null || shadows!.isEmpty) {
      return content;
    }

    return DecoratedBox(
      decoration: ShapeDecoration(
        shape: appleSquircleBorder(radius: radius),
        shadows: shadows,
      ),
      child: content,
    );
  }
}
