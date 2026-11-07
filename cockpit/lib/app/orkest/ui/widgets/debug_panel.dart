import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Painel de inspeção de depuração exibindo Launcher de Configurações,
/// Watches, Call Stack, Variáveis, Breakpoints e Console DAP.
class DebugPanel extends StatefulWidget {
  const DebugPanel({
    super.key,
    required this.controller,
    this.configurations = const [],
    this.selectedConfiguration,
    this.onSelectConfiguration,
    this.onStartConfiguration,
    this.onNavigateToSource,
  });

  final DebugSessionController controller;
  final List<RunConfiguration> configurations;
  final RunConfiguration? selectedConfiguration;
  final ValueChanged<RunConfiguration>? onSelectConfiguration;
  final ValueChanged<RunConfiguration>? onStartConfiguration;
  final void Function(String filePath, int line, int column)?
  onNavigateToSource;

  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final TextEditingController _watchInputCtrl = TextEditingController();
  final TextEditingController _evalInputCtrl = TextEditingController();
  bool _addingWatch = false;
  final Map<String, String> _watchValues = {};

  Object? _watchFrame;
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onDebugChanged);
  }

  @override
  void didUpdateWidget(DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onDebugChanged);
      widget.controller.addListener(_onDebugChanged);
      _watchFrame = null;
    }
  }

  void _onDebugChanged() {
    final frame = widget.controller.isStopped
        ? widget.controller.currentFrame
        : null;
    if (frame == _watchFrame) return;
    _watchFrame = frame;
    if (frame != null) _refreshWatches();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onDebugChanged);
    _watchInputCtrl.dispose();
    _evalInputCtrl.dispose();
    super.dispose();
  }

  Future<void> _refreshWatches() async {
    if (!widget.controller.isStopped) return;
    final frame = widget.controller.currentFrame;
    for (final expr in widget.controller.watchExpressions) {
      final res = await widget.controller.evaluate(expr);
      if (mounted &&
          widget.controller.isStopped &&
          widget.controller.currentFrame == frame) {
        setState(() {
          _watchValues[expr] = res ?? 'undefined';
        });
      }
    }
  }

  void _submitWatch() {
    final text = _watchInputCtrl.text.trim();
    if (text.isNotEmpty) {
      widget.controller.addWatch(text);
      _watchInputCtrl.clear();
      setState(() => _addingWatch = false);
      _refreshWatches();
    }
  }

  Future<void> _submitEvaluate() async {
    final text = _evalInputCtrl.text.trim();
    if (text.isNotEmpty && widget.controller.isStopped) {
      _evalInputCtrl.clear();
      await widget.controller.evaluate(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final colors = context.colors;
        final isStopped = widget.controller.isStopped;
        final isRunning = widget.controller.isRunning;

        final currentConfig =
            widget.selectedConfiguration ??
            (widget.configurations.isNotEmpty
                ? widget.configurations.first
                : null);

        return Container(
          color: colors.panel,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho Principal
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: colors.panel2,
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Row(
                  children: [
                    Icon(sc.LucideIcons.bug, size: 14, color: colors.warn),
                    const SizedBox(width: 8),
                    Text(
                      'RUN & DEBUG',
                      style: context.typo.label.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.text2,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      isStopped
                          ? 'PAUSADO (${widget.controller.lastStopReason?.name ?? 'stop'})'
                          : isRunning
                          ? 'EXECUTANDO'
                          : 'OCIOSO',
                      style: context.typo.mono.copyWith(
                        fontSize: 10,
                        color: isStopped ? colors.warn : colors.text3,
                      ),
                    ),
                  ],
                ),
              ),

              // Seletor de Configuração e Launcher
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: colors.panel,
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Botão Iniciar (Play)
                        AppTooltip(
                          message: currentConfig != null
                              ? 'Iniciar ${currentConfig.name} (F5)'
                              : 'Selecione uma configuração',
                          child: HoverTap(
                            key: const ValueKey('run-config-start'),
                            onTap: currentConfig != null
                                ? () {
                                    if (widget.onStartConfiguration != null) {
                                      widget.onStartConfiguration!(currentConfig);
                                    } else {
                                      widget.controller.startFromRunConfiguration(
                                        config: currentConfig,
                                      );
                                    }
                                  }
                                : null,
                            padding: const EdgeInsets.all(6),
                            borderRadius: BorderRadius.circular(4),
                            color: colors.gitStaged.withValues(alpha: 0.15),
                            child: Icon(
                              sc.LucideIcons.play,
                              size: 14,
                              color: colors.gitStaged,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Dropdown ou Nome da Configuração
                        Expanded(
                          child: widget.configurations.isEmpty
                              ? Text(
                                  'Nenhum alvo detectado',
                                  style: context.typo.body.copyWith(
                                    fontSize: 11,
                                    color: colors.text4,
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.panel2,
                                    border: Border.all(color: colors.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        currentConfig?.isTest == true
                                            ? Icons.check_box_outlined
                                            : sc.LucideIcons.cpu,
                                        size: 12,
                                        color: colors.accent,
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          currentConfig?.name ?? 'Configuração',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: context.typo.body.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: colors.text,
                                          ),
                                        ),
                                      ),
                                      if (widget.configurations.length > 1) ...[
                                        const SizedBox(width: 4),
                                        Icon(
                                          sc.LucideIcons.chevronDown,
                                          size: 12,
                                          color: colors.text3,
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),

                    // Barra de Ações Rápidas de Debugging (Padrão Open IDEA)
                    if (isRunning || isStopped) ...[
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colors.panel2,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: colors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            // Resume (F9) ou Pause
                            if (isStopped)
                              AppTooltip(
                                message: 'Resume (F9)',
                                child: HoverTap(
                                  key: const ValueKey('debug-action-resume'),
                                  onTap: widget.controller.resume,
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.play_arrow,
                                    size: 16,
                                    color: colors.gitStaged,
                                  ),
                                ),
                              )
                            else
                              AppTooltip(
                                message: 'Pause',
                                child: HoverTap(
                                  key: const ValueKey('debug-action-pause'),
                                  onTap: widget.controller.pause,
                                  padding: const EdgeInsets.all(4),
                                  child: Icon(
                                    Icons.pause,
                                    size: 16,
                                    color: colors.warn,
                                  ),
                                ),
                              ),

                            // Step Over (F8)
                            AppTooltip(
                              message: 'Step Over (F8)',
                              child: HoverTap(
                                key: const ValueKey('debug-action-step-over'),
                                onTap: isStopped ? widget.controller.stepOver : null,
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.redo,
                                  size: 16,
                                  color: isStopped ? colors.text : colors.text4,
                                ),
                              ),
                            ),

                            // Step Into (F7)
                            AppTooltip(
                              message: 'Step Into (F7)',
                              child: HoverTap(
                                key: const ValueKey('debug-action-step-into'),
                                onTap: isStopped ? widget.controller.stepIn : null,
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.south,
                                  size: 16,
                                  color: isStopped ? colors.text : colors.text4,
                                ),
                              ),
                            ),

                            // Step Out (Shift+F8)
                            AppTooltip(
                              message: 'Step Out (Shift+F8)',
                              child: HoverTap(
                                key: const ValueKey('debug-action-step-out'),
                                onTap: isStopped ? widget.controller.stepOut : null,
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.north,
                                  size: 16,
                                  color: isStopped ? colors.text : colors.text4,
                                ),
                              ),
                            ),

                            // Stop
                            AppTooltip(
                              message: 'Stop Session',
                              child: HoverTap(
                                key: const ValueKey('debug-action-stop'),
                                onTap: widget.controller.stop,
                                padding: const EdgeInsets.all(4),
                                child: Icon(
                                  Icons.stop,
                                  size: 16,
                                  color: colors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Conteúdo Rolável: Watches, Call Stack, Variáveis, Breakpoints, Console
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    // Seção Watches
                    _SectionHeader(
                      title:
                          'WATCHES (${widget.controller.watchExpressions.length})',
                      action: AppTooltip(
                        message: 'Adicionar expressão',
                        child: HoverTap(
                          key: const ValueKey('run-config-add-watch'),
                          onTap: () =>
                              setState(() => _addingWatch = !_addingWatch),
                          padding: const EdgeInsets.all(2),
                          borderRadius: BorderRadius.circular(3),
                          child: Icon(
                            sc.LucideIcons.plus,
                            size: 12,
                            color: colors.text3,
                          ),
                        ),
                      ),
                    ),
                    if (_addingWatch)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                key: const ValueKey('run-config-watch-input'),
                                controller: _watchInputCtrl,
                                style: context.typo.mono.copyWith(fontSize: 11),
                                decoration: InputDecoration(
                                  hintText: 'Expressão para vigiar...',
                                  hintStyle: context.typo.mono.copyWith(
                                    fontSize: 11,
                                    color: colors.text4,
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 4,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                onSubmitted: (_) => _submitWatch(),
                              ),
                            ),
                            const SizedBox(width: 4),
                            HoverTap(
                              key: const ValueKey('run-config-watch-confirm'),
                              onTap: _submitWatch,
                              padding: const EdgeInsets.all(4),
                              borderRadius: BorderRadius.circular(3),
                              child: Icon(
                                sc.LucideIcons.check,
                                size: 12,
                                color: colors.gitStaged,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (widget.controller.watchExpressions.isEmpty &&
                        !_addingWatch)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Text(
                          'Nenhuma expressão observada',
                          style: context.typo.mono.copyWith(
                            fontSize: 11,
                            color: colors.text4,
                          ),
                        ),
                      )
                    else
                      for (final expr in widget.controller.watchExpressions)
                        _WatchRow(
                          expression: expr,
                          value:
                              _watchValues[expr] ??
                              (isStopped ? '...' : 'não disponível'),
                          onRemove: () => widget.controller.removeWatch(expr),
                        ),

                    const SizedBox(height: 12),

                    // Seção Call Stack
                    _SectionHeader(
                      title:
                          'CALL STACK (${widget.controller.stackFrames.length})',
                    ),
                    if (widget.controller.stackFrames.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Text(
                          isRunning
                              ? 'Aplicação em execução...'
                              : 'Nenhuma pilha disponível',
                          style: context.typo.mono.copyWith(
                            fontSize: 11,
                            color: colors.text4,
                          ),
                        ),
                      )
                    else
                      for (final frame in widget.controller.stackFrames)
                        _FrameRow(
                          frame: frame,
                          onTap: () {
                            if (frame.sourcePath != null &&
                                widget.onNavigateToSource != null) {
                              widget.onNavigateToSource!(
                                frame.sourcePath!,
                                frame.line,
                                frame.column,
                              );
                            }
                            widget.controller.selectFrame(frame.id);
                          },
                        ),

                    const SizedBox(height: 12),

                    // Seção Variáveis
                    _SectionHeader(
                      title:
                          'VARIÁVEIS (${widget.controller.variables.length})',
                    ),
                    if (widget.controller.variables.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Text(
                          'Nenhuma variável no escopo atual',
                          style: context.typo.mono.copyWith(
                            fontSize: 11,
                            color: colors.text4,
                          ),
                        ),
                      )
                    else
                      for (final variable in widget.controller.variables)
                        _VariableRow(variable: variable),

                    const SizedBox(height: 12),

                    // Seção Breakpoints
                    _SectionHeader(
                      title:
                          'BREAKPOINTS (${widget.controller.breakpointsByPath.values.fold(0, (acc, list) => acc + list.length)})',
                    ),
                    if (widget.controller.breakpointsByPath.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 8,
                        ),
                        child: Text(
                          'Nenhum breakpoint registrado',
                          style: context.typo.mono.copyWith(
                            fontSize: 11,
                            color: colors.text4,
                          ),
                        ),
                      )
                    else
                      for (final entry
                          in widget.controller.breakpointsByPath.entries)
                        for (final bp in entry.value)
                          _BreakpointRow(
                            filePath: entry.key,
                            line: bp.line,
                            onRemove: () => widget.controller.toggleBreakpoint(
                              entry.key,
                              bp.line,
                            ),
                            onTap: () {
                              if (widget.onNavigateToSource != null) {
                                widget.onNavigateToSource!(
                                  entry.key,
                                  bp.line,
                                  1,
                                );
                              }
                            },
                          ),

                    const SizedBox(height: 12),

                    // Seção Console de Depuração
                    _SectionHeader(
                      title:
                          'CONSOLE DE DEPURAÇÃO (${widget.controller.consoleLogs.length})',
                    ),
                    Container(
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.panel2,
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: widget.controller.consoleLogs.isEmpty
                                ? Center(
                                    child: Text(
                                      'Saída de logs DAP vazia',
                                      style: context.typo.mono.copyWith(
                                        fontSize: 10,
                                        color: colors.text4,
                                      ),
                                    ),
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.all(4),
                                    itemCount:
                                        widget.controller.consoleLogs.length,
                                    itemBuilder: (context, i) => Text(
                                      widget.controller.consoleLogs[i],
                                      style: context.typo.mono.copyWith(
                                        fontSize: 10,
                                        color: colors.text2,
                                      ),
                                    ),
                                  ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: colors.panel,
                              border: Border(
                                top: BorderSide(color: colors.border),
                              ),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '>',
                                  style: context.typo.mono.copyWith(
                                    fontSize: 11,
                                    color: colors.accent,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: TextField(
                                    controller: _evalInputCtrl,
                                    enabled: isStopped,
                                    style: context.typo.mono.copyWith(
                                      fontSize: 11,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: isStopped
                                          ? 'Avaliar expressão (Enter)...'
                                          : 'Pausado para avaliar',
                                      hintStyle: context.typo.mono.copyWith(
                                        fontSize: 10,
                                        color: colors.text4,
                                      ),
                                      isDense: true,
                                      border: InputBorder.none,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                    ),
                                    onSubmitted: (_) => _submitEvaluate(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
  const _SectionHeader({required this.title, this.action});
  final String title;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 4, right: 4),
      child: Row(
        children: [
          Text(
            title,
            style: context.typo.label.copyWith(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: colors.text3,
              letterSpacing: 0.5,
            ),
          ),
          if (action != null) ...[const Spacer(), action!],
        ],
      ),
    );
  }
}

class _WatchRow extends StatelessWidget {
  const _WatchRow({
    required this.expression,
    required this.value,
    required this.onRemove,
  });

  final String expression;
  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      child: Row(
        children: [
          Icon(sc.LucideIcons.eye, size: 11, color: colors.accent),
          const SizedBox(width: 4),
          Text(
            expression,
            style: context.typo.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            ':',
            style: context.typo.mono.copyWith(
              fontSize: 11,
              color: colors.text3,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.mono.copyWith(
                fontSize: 11,
                color: colors.gitStaged,
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Icon(sc.LucideIcons.x, size: 12, color: colors.text3),
          ),
        ],
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
                style: context.typo.mono.copyWith(
                  fontSize: 11,
                  color: colors.text,
                ),
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
            style: context.typo.mono.copyWith(
              fontSize: 11,
              color: colors.text3,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              variable.value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.mono.copyWith(
                fontSize: 11,
                color: colors.text,
              ),
            ),
          ),
          if (variable.type != null) ...[
            const SizedBox(width: 4),
            Text(
              '(${variable.type})',
              style: context.typo.mono.copyWith(
                fontSize: 10,
                color: colors.text4,
              ),
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
                style: context.typo.mono.copyWith(
                  fontSize: 11,
                  color: colors.text,
                ),
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
