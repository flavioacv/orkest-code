import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Barra flutuante de controles de depuração DAP (Play, Pause, Step Over, Step In, Step Out, Stop).
class DebugToolbar extends StatelessWidget {
  const DebugToolbar({
    super.key,
    required this.controller,
  });

  final DebugSessionController controller;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (!controller.isActive) return const SizedBox.shrink();

        final colors = context.colors;
        final isStopped = controller.isStopped;

        return CallbackShortcuts(
          bindings: {
            const SingleActivator(LogicalKeyboardKey.f5): () {
              if (isStopped) controller.resume();
            },
            const SingleActivator(LogicalKeyboardKey.f10): () {
              if (isStopped) controller.stepOver();
            },
            const SingleActivator(LogicalKeyboardKey.f11): () {
              if (isStopped) controller.stepIn();
            },
            const SingleActivator(LogicalKeyboardKey.f11, shift: true): () {
              if (isStopped) controller.stepOut();
            },
            const SingleActivator(LogicalKeyboardKey.f5, shift: true): controller.stop,
          },
          child: Material(
            elevation: 6,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.panel2,
                border: Border.all(color: colors.border2, width: 1.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isStopped
                          ? colors.warn.withValues(alpha: 0.15)
                          : colors.gitStaged.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isStopped ? 'PAUSADO' : 'RODANDO',
                      style: context.typo.label.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isStopped ? colors.warn : colors.gitStaged,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Continue / Pause
                  if (isStopped)
                    _ToolbarButton(
                      icon: sc.LucideIcons.play,
                      tooltip: 'Continuar (F5)',
                      color: colors.gitStaged,
                      onPressed: controller.resume,
                    )
                  else
                    _ToolbarButton(
                      icon: sc.LucideIcons.pause,
                      tooltip: 'Pausar',
                      color: colors.warn,
                      onPressed: controller.pause,
                    ),

                  const SizedBox(width: 4),

                  // Step Over
                  _ToolbarButton(
                    icon: sc.LucideIcons.stepForward,
                    tooltip: 'Passar Sobre / Next (F10)',
                    enabled: isStopped,
                    onPressed: controller.stepOver,
                  ),

                  const SizedBox(width: 4),

                  // Step Into
                  _ToolbarButton(
                    icon: sc.LucideIcons.cornerDownRight,
                    tooltip: 'Entrar / Step In (F11)',
                    enabled: isStopped,
                    onPressed: controller.stepIn,
                  ),

                  const SizedBox(width: 4),

                  // Step Out
                  _ToolbarButton(
                    icon: sc.LucideIcons.cornerUpRight,
                    tooltip: 'Sair / Step Out (Shift+F11)',
                    enabled: isStopped,
                    onPressed: controller.stepOut,
                  ),

                  const SizedBox(width: 6),
                  Container(width: 1, height: 16, color: colors.border),
                  const SizedBox(width: 6),

                  // Stop
                  _ToolbarButton(
                    icon: sc.LucideIcons.square,
                    tooltip: 'Parar Depuração (Shift+F5)',
                    color: colors.error,
                    onPressed: controller.stop,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.enabled = true,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;
  final Color? color;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final effectiveColor = enabled ? (color ?? colors.text) : colors.text4;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: enabled ? onPressed : null,
        child: Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.border),
          ),
          child: Icon(
            icon,
            size: 13,
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}
