import 'dart:async' show Timer;

import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/apple_glass_surface.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Tooltip do app — substitui o `Tooltip` do shadcn onde a posição importa.
///
/// Por quê: os handlers de overlay do shadcn medem a âncora com
/// `localToGlobal` **global** (espaço da janela, já ampliado pelo `_AppZoom`),
/// mas inserem o balão no `Overlay` do Navigator, que vive **dentro** do zoom
/// (espaço lógico reduzido). Com zoom ≠ 1.0 o balão desloca proporcional à
/// distância do canto superior esquerdo. Aqui a âncora é convertida pro espaço
/// do próprio `Overlay` (`localToGlobal(..., ancestor: overlay)`) e passada
/// como `position` explícito → posição correta em qualquer escala.
class AppTooltip extends StatefulWidget {
  const AppTooltip({super.key, required this.message, required this.child});

  final String message;
  final Widget child;

  @override
  State<AppTooltip> createState() => _AppTooltipState();
}

class _AppTooltipState extends State<AppTooltip> {
  OverlayCompleter<void>? _entry;
  Timer? _wait;

  @override
  void dispose() {
    _wait?.cancel();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  void _show() {
    if (!mounted) return;
    _entry?.remove();
    final box = context.findRenderObject();
    if (box is! RenderBox) return;
    // Bottom-center do trigger. O handler do app converte pro espaço do
    // Overlay (imune ao zoom) — ver [AppPopoverOverlayHandler].
    final anchor = box.localToGlobal(
      Offset(box.size.width / 2, box.size.height),
    );
    _entry = showPopover<void>(
      context: context,
      position: anchor,
      // Balão logo abaixo do ponto de âncora, centralizado.
      alignment: Alignment.topCenter,
      anchorAlignment: Alignment.bottomCenter,
      modal: false,
      follow: false,
      consumeOutsideTaps: false,
      dismissBackdropFocus: false,
      builder: (context) {
        final colors = context.colors;
        return AppleGlassSurface(
          radius: 7,
          blurSigma: 20,
          surfaceColor: colors.panel2,
          opacity: 0.88,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          shadows: [
            BoxShadow(
              color: colors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          child: Text(
            widget.message,
            style: context.typo.label.copyWith(
              fontSize: 11.5,
              color: colors.text,
            ),
          ),
        );
      },
    );
  }

  void _hide() {
    _entry?.remove();
    _entry = null;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        _wait?.cancel();
        _wait = Timer(const Duration(milliseconds: 500), _show);
      },
      onExit: (_) {
        _wait?.cancel();
        _hide();
      },
      child: widget.child,
    );
  }
}
