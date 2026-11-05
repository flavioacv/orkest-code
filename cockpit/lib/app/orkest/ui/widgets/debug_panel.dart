import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Painel de inspeção de depuração exibindo Call Stack, Variáveis e Breakpoints.
class DebugPanel extends StatelessWidget {
  const DebugPanel({
    super.key,
    required this.controller,
    this.onNavigateToSource,
  });

  final DebugSessionController controller;
  final void Function(String filePath, int line, int column)? onNavigateToSource;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final colors = context.colors;

        return Container(
          color: colors.panel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: colors.panel2,
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Icon(sc.LucideIcons.bug, size: 14, color: colors.warn),
                    const SizedBox(width: 8),
                    Text(
                      'DEPURAÇÃO',
                      style: context.typo.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.text2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      controller.isStopped
                          ? 'PAUSADO (${controller.lastStopReason?.name ?? 'stop'})'
                          : controller.isRunning
                              ? 'EXECUTANDO'
                              : 'OCIOSO',
                      style: context.typo.mono.copyWith(
                        fontSize: 10,
                        color: controller.isStopped ? colors.warn : colors.text3,
                      ),
                    ),
                  ],
                ),
              ),

              // Conteúdo: Dividido em Call Stack e Variáveis
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Seção Call Stack
                    _SectionHeader(title: 'CALL STACK (${controller.stackFrames.length})'),
                    if (controller.stackFrames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          controller.isRunning
                              ? 'Aplicação em execução...'
                              : 'Nenhuma pilha disponível',
                          style: context.typo.mono.copyWith(fontSize: 11, color: colors.text4),
                        ),
                      )
                    else
                      for (final frame in controller.stackFrames)
                        _FrameRow(
                          frame: frame,
                          onTap: () {
                            if (frame.sourcePath != null && onNavigateToSource != null) {
                              onNavigateToSource!(frame.sourcePath!, frame.line, frame.column);
                            }
                            controller.selectFrame(frame.id);
                          },
                        ),

                    const SizedBox(height: 12),

                    // Seção Variáveis
                    _SectionHeader(title: 'VARIÁVEIS (${controller.variables.length})'),
                    if (controller.variables.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          'Nenhuma variável no escopo atual',
                          style: context.typo.mono.copyWith(fontSize: 11, color: colors.text4),
                        ),
                      )
                    else
                      for (final variable in controller.variables)
                        _VariableRow(variable: variable),

                    const SizedBox(height: 12),

                    // Seção Breakpoints
                    _SectionHeader(
                      title: 'BREAKPOINTS (${controller.breakpointsByPath.values.fold(0, (acc, list) => acc + list.length)})',
                    ),
                    if (controller.breakpointsByPath.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                        child: Text(
                          'Nenhum breakpoint registrado',
                          style: context.typo.mono.copyWith(fontSize: 11, color: colors.text4),
                        ),
                      )
                    else
                      for (final entry in controller.breakpointsByPath.entries)
                        for (final bp in entry.value)
                          _BreakpointRow(
                            filePath: entry.key,
                            line: bp.line,
                            onRemove: () => controller.toggleBreakpoint(entry.key, bp.line),
                            onTap: () {
                              if (onNavigateToSource != null) {
                                onNavigateToSource!(entry.key, bp.line, 1);
                              }
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 4),
      child: Text(
        title,
        style: context.typo.label.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: colors.text3,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _FrameRow extends StatelessWidget {
  const _FrameRow({required this.frame, required this.onTap});
  final DapStackFrame frame;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: Row(
          children: [
            Icon(sc.LucideIcons.chevronRight, size: 11, color: colors.accent),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                '${frame.name} (${frame.sourcePath ?? 'unknown'}:${frame.line})',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.mono.copyWith(fontSize: 11, color: colors.text),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableRow extends StatelessWidget {
  const _VariableRow({required this.variable});
  final DapVariable variable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Text(
            variable.name,
            style: context.typo.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '=',
            style: context.typo.mono.copyWith(fontSize: 11, color: colors.text3),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              variable.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.mono.copyWith(fontSize: 11, color: colors.text),
            ),
          ),
          if (variable.type != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${variable.type})',
              style: context.typo.mono.copyWith(fontSize: 10, color: colors.text4),
            ),
          ],
        ],
      ),
    );
  }
}

class _BreakpointRow extends StatelessWidget {
  const _BreakpointRow({
    required this.filePath,
    required this.line,
    required this.onTap,
    required this.onRemove,
  });

  final String filePath;
  final int line;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.error,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                '$filePath:$line',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.mono.copyWith(fontSize: 11, color: colors.text),
              ),
            ),
            GestureDetector(
              onTap: onRemove,
              child: Icon(sc.LucideIcons.x, size: 12, color: colors.text3),
            ),
          ],
        ),
      ),
    );
  }
}
