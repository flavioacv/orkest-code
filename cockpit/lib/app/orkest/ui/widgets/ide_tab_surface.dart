import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Shared tab chrome for editor documents and workbench tools. Colors follow
/// the selected Orkest theme, including custom accent and light variants.
class IdeTabSurface extends StatefulWidget {
  const IdeTabSurface({
    super.key,
    required this.selected,
    this.focused = true,
    required this.child,
  });

  static const double height = 28;
  static const double headerHeight = 40;
  static const double iconSize = 16;
  static const BorderRadius radius = BorderRadius.all(Radius.circular(6));

  final bool selected;
  final bool focused;
  final Widget child;

  @override
  State<IdeTabSurface> createState() => _IdeTabSurfaceState();
}

class _IdeTabSurfaceState extends State<IdeTabSurface> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final active = widget.selected && widget.focused;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 120),
        height: IdeTabSurface.height,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: widget.selected
              ? active
                    ? Color.alphaBlend(
                        colors.accent.withValues(alpha: .22),
                        colors.panel,
                      )
                    : colors.panel2
              : _hovered
              ? colors.panel3
              : Colors.transparent,
          borderRadius: IdeTabSurface.radius,
          border: Border.all(
            color: widget.selected
                ? active
                      ? colors.accent.withValues(alpha: .55)
                      : colors.border2
                : Colors.transparent,
          ),
        ),
        alignment: Alignment.center,
        child: widget.child,
      ),
    );
  }
}
