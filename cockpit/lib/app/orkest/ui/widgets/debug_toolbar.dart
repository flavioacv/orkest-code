import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';

String debugStateLabel(BuildContext context, DapSessionState state) {
  final tr = context.t.orkest.debugWorkbench;
  return switch (state) {
    DapSessionState.idle => tr.idle,
    DapSessionState.initializing => tr.initializing,
    DapSessionState.running => tr.running,
    DapSessionState.stopped => tr.stopped,
    DapSessionState.terminating => tr.terminating,
  };
}

/// Session controls reflect live adapter capabilities, never a catalog guess.
class DebugToolbar extends StatelessWidget {
  const DebugToolbar({super.key, required this.controller, this.onRestart});
  final DebugSessionController controller;
  final VoidCallback? onRestart;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: controller,
    builder: (context, _) {
      if (!controller.isActive) return const SizedBox.shrink();
      final tr = context.t.orkest.debugWorkbench;
      final ready = !controller.busy;
      Widget action(
        String id,
        IconData icon,
        String label,
        VoidCallback? callback, {
        Color? color,
      }) => SizedBox(
        width: 28,
        height: 26,
        child: IconButton(
          key: ValueKey(id),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          tooltip: label,
          onPressed: callback,
          icon: Icon(
            icon,
            size: 15,
            color: callback == null
                ? context.colors.text4
                : color ?? context.colors.text,
          ),
        ),
      );
      return Material(
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (controller.isStopped)
              action(
                'debug-resume',
                Icons.play_arrow,
                tr.resume,
                ready ? controller.resume : null,
                color: context.colors.gitStaged,
              )
            else
              action(
                'debug-pause',
                Icons.pause,
                tr.pause,
                ready && controller.isRunning ? controller.pause : null,
              ),
            action(
              'debug-step-over',
              Icons.redo,
              tr.stepOver,
              ready && controller.isStopped ? controller.stepOver : null,
            ),
            action(
              'debug-step-in',
              Icons.south,
              tr.stepIn,
              ready && controller.isStopped ? controller.stepIn : null,
            ),
            action(
              'debug-step-out',
              Icons.north,
              tr.stepOut,
              ready && controller.isStopped ? controller.stepOut : null,
            ),
            action(
              'debug-restart',
              Icons.refresh,
              tr.restart,
              ready
                  ? onRestart ??
                        (controller.capabilities.supportsRestartRequest
                            ? controller.restart
                            : null)
                  : null,
            ),
            if (controller.isFlutter) ...[
              action(
                'debug-hot-reload',
                Icons.bolt,
                tr.hotReload,
                ready ? controller.hotReload : null,
                color: context.colors.warn,
              ),
              action(
                'debug-hot-restart',
                Icons.restart_alt,
                tr.hotRestart,
                ready ? controller.hotRestart : null,
              ),
            ],
            action(
              'debug-stop',
              Icons.stop,
              tr.stop,
              controller.state == DapSessionState.terminating
                  ? null
                  : controller.stop,
              color: context.colors.error,
            ),
          ],
        ),
      );
    },
  );
}
