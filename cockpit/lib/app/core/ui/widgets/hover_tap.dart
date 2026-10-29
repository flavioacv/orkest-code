import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/apple_glass_surface.dart';
import 'package:flutter/widgets.dart';

/// Substituto do Material `InkWell` para superfícies clicáveis custom (linhas de
/// lista, itens de menu, chips): hover + clique **sem depender de Material**.
///
/// Aplica as diretrizes de micro-interação do Apple HIG:
/// - Transição suave de cor no hover (`120ms` com [kAppleDecelerateCurve]);
/// - Feedback tátil sutil de pressão (`scale: 0.985` ao pressionar);
/// - Curvatura contínua (*squircle*) quando a borda permite.
class HoverTap extends StatefulWidget {
  const HoverTap({
    super.key,
    required this.child,
    this.onTap,
    this.padding,
    this.borderRadius = const BorderRadius.all(Radius.circular(8)),
    this.color,
    this.hoverColor,
    this.border,
    this.cursor = SystemMouseCursors.click,
  });

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;
  final BorderRadius borderRadius;

  /// Fundo base (sem hover). `null` = transparente.
  final Color? color;

  /// Fundo no hover. `null` → `context.colors.panel3`.
  final Color? hoverColor;

  /// Borda opcional (constante em hover e repouso).
  final BoxBorder? border;
  final MouseCursor cursor;

  @override
  State<HoverTap> createState() => _HoverTapState();
}

class _HoverTapState extends State<HoverTap> {
  bool _hover = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final hoverColor = widget.hoverColor ?? context.colors.panel3;
    final bg = (_hover && enabled ? hoverColor : widget.color) ??
        const Color(0x00000000);
    final inner = widget.padding == null
        ? widget.child
        : Padding(padding: widget.padding!, child: widget.child);

    // Se a borda for uniforme (Border.all) ou nula, usamos ContinuousRectangleBorder
    // (squircle Apple HIG); caso seja assimétrica (ex: Border(left: ...)),
    // mantemos BoxDecoration tradicional para suportar lados independentes.
    final boxBorder = widget.border;
    final bool canUseSquircle =
        boxBorder == null || (boxBorder is Border && boxBorder.isUniform);
    final BorderSide uniformSide = boxBorder is Border && boxBorder.isUniform
        ? boxBorder.top
        : BorderSide.none;

    final Decoration decoration = canUseSquircle
        ? ShapeDecoration(
            color: bg,
            shape: ContinuousRectangleBorder(
              borderRadius: widget.borderRadius * 2.1,
              side: uniformSide,
            ),
          )
        : BoxDecoration(
            color: bg,
            borderRadius: widget.borderRadius,
            border: boxBorder,
          );

    return MouseRegion(
      cursor: enabled ? widget.cursor : MouseCursor.defer,
      onEnter: enabled ? (_) => setState(() => _hover = true) : null,
      onExit: enabled
          ? (_) => setState(() {
              _hover = false;
              _pressed = false;
            })
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
        child: AnimatedScale(
          scale: _pressed && enabled ? 0.985 : 1.0,
          duration: const Duration(milliseconds: 110),
          curve: kAppleDecelerateCurve,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: kAppleDecelerateCurve,
            decoration: decoration,
            child: inner,
          ),
        ),
      ),
    );
  }
}
