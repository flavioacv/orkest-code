import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_menu.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

import 'debug_toolbar.dart';
import 'debug_variable_tree.dart';

/// Launcher, inspection views and REPL share one workspace session. The layout
/// follows VS Code's separation of Variables, Watch, Call Stack and Breakpoints.
class DebugPanel extends StatefulWidget {
  const DebugPanel({
    super.key,
    required this.controller,
    this.configurations = const [],
    this.selectedConfiguration,
    this.onSelectConfiguration,
    this.onStartConfiguration,
    this.onRunConfiguration,
    this.onConfigure,
    this.onReload,
    this.onRestart,
    this.isStarting = false,
    this.configurationError,
    this.onNavigateToSource,
  });
  final DebugSessionController controller;
  final List<RunConfiguration> configurations;
  final RunConfiguration? selectedConfiguration;
  final ValueChanged<RunConfiguration>? onSelectConfiguration;
  final ValueChanged<RunConfiguration>? onStartConfiguration;
  final ValueChanged<RunConfiguration>? onRunConfiguration;
  final VoidCallback? onConfigure;
  final VoidCallback? onReload;
  final VoidCallback? onRestart;
  final bool isStarting;
  final String? configurationError;
  final void Function(String path, int line, int column)? onNavigateToSource;
  @override
  State<DebugPanel> createState() => _DebugPanelState();
}

class _DebugPanelState extends State<DebugPanel> {
  final _watchInput = TextEditingController();
  final _evaluateInput = TextEditingController();
  final _filter = TextEditingController();
  final _watchValues = <String, DapEvaluateResult?>{};
  final _collapsed = <String>{};
  Object? _watchFrame;
  int _watchGeneration = 0;
  bool _console = false;
  bool _launching = false;
  RunConfiguration? _localConfiguration;
  double _leftFraction = .32;
  double _rightFraction = .30;
  DebugSessionController get c => widget.controller;
  @override
  void initState() {
    super.initState();
    c.addListener(_changed);
    _changed();
  }

  @override
  void didUpdateWidget(DebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != c) {
      oldWidget.controller.removeListener(_changed);
      c.addListener(_changed);
      _watchFrame = null;
      _watchGeneration++;
      _watchValues.clear();
      _changed();
    }
  }

  void _changed() {
    final frame = c.isStopped && c.currentFrame != null
        ? (
            c.sessionId,
            c.activeThreadId,
            c.currentFrame?.id,
            c.inspectionVersion,
          )
        : null;
    if (frame == _watchFrame) return;
    _watchFrame = frame;
    _watchGeneration++;
    _watchValues.clear();
    if (frame != null) unawaited(_refreshWatches());
  }

  Future<void> _refreshWatches() async {
    final generation = ++_watchGeneration;
    final controller = c;
    final values = <String, DapEvaluateResult?>{};
    for (final expression in controller.watchExpressions) {
      values[expression] = await controller.evaluateValue(expression);
      if (!mounted ||
          controller != c ||
          generation != _watchGeneration ||
          !c.isStopped) {
        return;
      }
    }
    if (mounted && generation == _watchGeneration) {
      setState(() {
        _watchValues
          ..clear()
          ..addAll(values);
      });
    }
  }

  @override
  void dispose() {
    c.removeListener(_changed);
    _watchGeneration++;
    _watchInput.dispose();
    _evaluateInput.dispose();
    _filter.dispose();
    super.dispose();
  }

  void _addWatch() {
    final expression = _watchInput.text.trim();
    if (expression.isEmpty) return;
    c.addWatch(expression);
    _watchInput.clear();
    if (c.isStopped) unawaited(_refreshWatches());
  }

  Future<void> _evaluate() async {
    final expression = _evaluateInput.text.trim();
    if (expression.isEmpty || !c.isStopped) return;
    _evaluateInput.clear();
    await c.evaluateInConsole(expression);
  }

  Future<void> _start(RunConfiguration configuration) async {
    if (widget.onStartConfiguration != null) {
      widget.onStartConfiguration!(configuration);
      return;
    }
    setState(() => _launching = true);
    try {
      await c.startFromRunConfiguration(config: configuration);
    } finally {
      if (mounted) setState(() => _launching = false);
    }
  }

  Widget _action(
    String id,
    IconData icon,
    String tooltip,
    VoidCallback? callback, {
    Color? color,
  }) => SizedBox(
    width: 28,
    height: 28,
    child: IconButton(
      key: ValueKey(id),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      tooltip: tooltip,
      onPressed: callback,
      icon: Icon(
        icon,
        size: 15,
        color: callback == null
            ? context.colors.text4
            : color ?? context.colors.text2,
      ),
    ),
  );
  Widget _hint(String text) => Padding(
    padding: const EdgeInsets.all(12),
    child: Text(
      text,
      style: context.typo.label.copyWith(
        color: context.colors.text3,
        fontSize: 11,
      ),
    ),
  );
  Widget _section(
    String id,
    String title,
    List<Widget> children, {
    List<Widget> actions = const [],
  }) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Container(
        color: context.colors.panel2,
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                key: ValueKey('debug-section-$id'),
                onTap: () => setState(() {
                  if (!_collapsed.remove(id)) _collapsed.add(id);
                }),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 7,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _collapsed.contains(id)
                            ? Icons.chevron_right
                            : Icons.expand_more,
                        size: 14,
                        color: context.colors.text3,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typo.label.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ...actions,
          ],
        ),
      ),
      if (!_collapsed.contains(id)) ...children,
    ],
  );

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: c,
    builder: (context, _) {
      final tr = context.t.orkest.debugWorkbench;
      final current =
          widget.selectedConfiguration ??
          widget.configurations
              .where((v) => v.id == _localConfiguration?.id)
              .firstOrNull ??
          widget.configurations.firstOrNull;
      final busy = widget.isStarting || _launching || c.busy;
      final failure = widget.configurationError ?? c.lastError?.toString();
      return Material(
        color: context.colors.panel,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: context.colors.border),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.bug_report_outlined,
                    size: 17,
                    color: context.colors.accent,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Builder(
                      builder: (anchor) => InkWell(
                        key: const ValueKey('debug-configuration-picker'),
                        onTap:
                            widget.configurations.length < 2 ||
                                busy ||
                                c.isActive
                            ? null
                            : () async {
                                final selected =
                                    await showAppMenu<RunConfiguration>(
                                      anchor,
                                      items: [
                                        for (final config
                                            in widget.configurations)
                                          AppMenuItem(
                                            value: config,
                                            label: config.name,
                                            selected: config.id == current?.id,
                                          ),
                                      ],
                                    );
                                if (!mounted || selected == null) return;
                                setState(() => _localConfiguration = selected);
                                widget.onSelectConfiguration?.call(selected);
                              },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5),
                          child: Row(
                            children: [
                              Expanded(
                                child: Tooltip(
                                  message: current == null
                                      ? tr.emptyConfiguration
                                      : '${current.name}\n${current.cwd}',
                                  child: Text(
                                    current?.name ?? tr.noConfiguration,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.typo.label.copyWith(
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                              if (widget.configurations.length > 1)
                                const Icon(Icons.expand_more, size: 14),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  _action(
                    'run-config-start',
                    Icons.play_arrow,
                    tr.start,
                    current != null && !busy && !c.isActive
                        ? () => _start(current)
                        : null,
                    color: context.colors.gitStaged,
                  ),
                  if (widget.onRunConfiguration != null)
                    _action(
                      'debug-run-terminal',
                      Icons.terminal,
                      tr.run,
                      current != null && !busy && !c.isActive
                          ? () => widget.onRunConfiguration!(current)
                          : null,
                    ),
                  if (widget.onConfigure != null)
                    _action(
                      'debug-configure',
                      Icons.settings_outlined,
                      tr.configure,
                      widget.onConfigure,
                    ),
                  if (widget.onReload != null)
                    _action(
                      'debug-reload-configurations',
                      Icons.refresh,
                      tr.reload,
                      busy ? null : widget.onReload,
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 30,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _tab(
                      'debug-inspector-tab',
                      tr.inspector,
                      !_console,
                      () => setState(() => _console = false),
                    ),
                    _tab(
                      'debug-console-tab',
                      tr.console,
                      _console,
                      () => setState(() => _console = true),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        debugStateLabel(context, c.state),
                        style: context.typo.label.copyWith(
                          fontSize: 10,
                          color: c.isStopped
                              ? context.colors.warn
                              : context.colors.text3,
                        ),
                      ),
                    ),
                    DebugToolbar(controller: c, onRestart: widget.onRestart),
                  ],
                ),
              ),
            ),
            if (failure != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 58),
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: SelectableText(
                      tr.failure(detail: failure),
                      style: context.typo.label.copyWith(
                        fontSize: 11,
                        color: context.colors.error,
                      ),
                    ),
                  ),
                ),
              ),
            Expanded(
              child: IndexedStack(
                index: _console ? 1 : 0,
                children: [_inspector(), _consoleView()],
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _tab(String id, String label, bool selected, VoidCallback action) =>
      InkWell(
        key: ValueKey(id),
        onTap: action,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected ? context.colors.accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            style: context.typo.label.copyWith(
              fontSize: 11,
              color: selected ? context.colors.text : context.colors.text3,
            ),
          ),
        ),
      );

  Widget _inspector() => LayoutBuilder(
    builder: (context, constraints) {
      final tr = context.t.orkest.debugWorkbench;
      final variables = _section('variables', tr.variables, [
        if (!c.isStopped)
          _hint(c.isActive ? tr.pausedHint : tr.startHint)
        else if (c.scopes.isEmpty)
          _hint(tr.noVariables)
        else
          for (var index = 0; index < c.scopes.length; index++)
            DebugVariableTree(
              key: ValueKey(
                '${c.sessionId}:${c.inspectionVersion}:scope:${c.scopes[index].variablesReference}',
              ),
              controller: c,
              name: c.scopes[index].name,
              reference: c.scopes[index].variablesReference,
              initiallyExpanded: index == 0 && !c.scopes[index].expensive,
            ),
      ]);
      final watches = _section('watches', tr.watches, [
        if (c.watchExpressions.isEmpty) _hint(tr.noWatches),
        for (final expression in c.watchExpressions)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DebugVariableTree(
                  key: ValueKey(
                    '${c.sessionId}:${c.inspectionVersion}:watch:$expression:${_watchValues[expression]?.result}',
                  ),
                  controller: c,
                  name: expression,
                  value: _watchValues[expression]?.result ?? '—',
                  reference: _watchValues[expression]?.variablesReference ?? 0,
                ),
              ),
              _action(
                'debug-remove-watch-$expression',
                Icons.close,
                tr.remove,
                () => c.removeWatch(expression),
              ),
            ],
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 4, 4, 8),
          child: Row(
            children: [
              Expanded(
                child: _field(
                  _watchInput,
                  tr.watchPlaceholder,
                  key: 'debug-watch-input',
                  onSubmitted: (_) => _addWatch(),
                ),
              ),
              _action('debug-add-watch', Icons.add, tr.add, _addWatch),
            ],
          ),
        ),
      ]);
      final stack = _section('stack', tr.callStack, [
        if (c.threads.isNotEmpty)
          Builder(
            builder: (anchor) => InkWell(
              key: const ValueKey('debug-thread-picker'),
              onTap: c.isStopped && c.threads.length > 1
                  ? () async {
                      final id = await showAppMenu<int>(
                        anchor,
                        items: [
                          for (final thread in c.threads)
                            AppMenuItem(
                              value: thread.id,
                              label: thread.name,
                              selected: thread.id == c.activeThreadId,
                            ),
                        ],
                      );
                      if (mounted && id != null) await c.selectThread(id);
                    }
                  : null,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: [
                    const Icon(Icons.account_tree_outlined, size: 13),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        c.threads
                                .where((t) => t.id == c.activeThreadId)
                                .firstOrNull
                                ?.name ??
                            tr.selectThread,
                        style: context.typo.label.copyWith(fontSize: 11),
                      ),
                    ),
                    const Icon(Icons.expand_more, size: 14),
                  ],
                ),
              ),
            ),
          ),
        if (c.stackFrames.isEmpty) _hint(tr.noFrames),
        for (final frame in c.stackFrames)
          InkWell(
            key: ValueKey('debug-frame-${frame.id}'),
            onTap: () async {
              await c.selectFrame(frame.id);
              if (!mounted || c.currentFrame?.id != frame.id) return;
              if (frame.sourcePath != null) {
                widget.onNavigateToSource?.call(
                  frame.sourcePath!,
                  frame.line,
                  frame.column,
                );
              }
            },
            child: Container(
              color: c.currentFrame?.id == frame.id
                  ? context.colors.accent.withValues(alpha: .12)
                  : null,
              padding: const EdgeInsets.fromLTRB(10, 7, 6, 7),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          frame.name,
                          style: context.typo.label.copyWith(fontSize: 11),
                        ),
                        Text(
                          '${frame.sourcePath == null ? '' : p.basename(frame.sourcePath!)}:${frame.line}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.typo.mono.copyWith(
                            fontSize: 10,
                            color: context.colors.text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (c.capabilities.supportsRestartFrame)
                    _action(
                      'debug-restart-frame-${frame.id}',
                      Icons.replay,
                      tr.restartFrame,
                      c.busy ? null : () => c.restartFrame(frame.id),
                    ),
                ],
              ),
            ),
          ),
      ]);
      final breakpoints = _breakpointSection();
      if (constraints.maxWidth < 1000) {
        return ListView(
          key: const PageStorageKey('debug-inspection-sections'),
          children: [variables, watches, stack, breakpoints],
        );
      }
      final left = (constraints.maxWidth * _leftFraction).clamp(
        220.0,
        constraints.maxWidth * .4,
      );
      final right = (constraints.maxWidth * _rightFraction).clamp(
        220.0,
        constraints.maxWidth * .4,
      );
      return Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: left,
            child: ListView(children: [variables, watches]),
          ),
          _divider(
            'debug-resize-variables',
            (delta) => setState(
              () => _leftFraction = ((left + delta) / constraints.maxWidth)
                  .clamp(.2, .4),
            ),
          ),
          Expanded(child: ListView(children: [stack])),
          _divider(
            'debug-resize-breakpoints',
            (delta) => setState(
              () => _rightFraction = ((right - delta) / constraints.maxWidth)
                  .clamp(.2, .4),
            ),
          ),
          SizedBox(
            width: right,
            child: ListView(children: [breakpoints]),
          ),
        ],
      );
    },
  );
  Widget _divider(String key, ValueChanged<double> update) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      key: ValueKey(key),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (event) => update(event.delta.dx),
      child: Container(
        width: 5,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: context.colors.border)),
        ),
      ),
    ),
  );

  Widget _breakpointSection() {
    final tr = context.t.orkest.debugWorkbench;
    final points = c.breakpointsByPath;
    return _section(
      'breakpoints',
      tr.breakpoints,
      [
        if (points.isEmpty) _hint(tr.noBreakpoints),
        for (final file in points.entries) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 8, 4),
            child: Tooltip(
              message: file.key,
              child: Text(
                p.basename(file.key),
                style: context.typo.label.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ),
          for (final point in file.value)
            Builder(
              builder: (context) {
                final status = c.breakpointStatus(file.key, point.line);
                final enabled = c.breakpointsEnabled && point.enabled;
                final label = !enabled
                    ? tr.disabled
                    : status == null
                    ? tr.pending
                    : status.verified
                    ? tr.verified
                    : tr.unverified;
                return Row(
                  children: [
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: Checkbox(
                        value: point.enabled,
                        onChanged: (value) => c.updateBreakpoint(
                          file.key,
                          point.copyWith(enabled: value),
                        ),
                      ),
                    ),
                    Tooltip(
                      message: status?.message ?? label,
                      child: Icon(
                        point.logMessage?.isNotEmpty == true
                            ? Icons.diamond_outlined
                            : Icons.circle,
                        size: 10,
                        color: !enabled
                            ? context.colors.text4
                            : status?.verified == false
                            ? context.colors.warn
                            : context.colors.error,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Expanded(
                      child: InkWell(
                        onTap: () => widget.onNavigateToSource?.call(
                          file.key,
                          point.line,
                          point.column ?? 1,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Text(
                            '${point.line}${point.condition?.isNotEmpty == true ? ' · ${point.condition}' : ''}${point.hitCondition?.isNotEmpty == true ? ' · ${point.hitCondition}' : ''}${point.logMessage?.isNotEmpty == true ? ' · ${point.logMessage}' : ''}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: context.typo.mono.copyWith(
                              fontSize: 10,
                              color: context.colors.text,
                            ),
                          ),
                        ),
                      ),
                    ),
                    _action(
                      'debug-edit-breakpoint-${file.key}-${point.line}',
                      Icons.edit_outlined,
                      tr.edit,
                      () => _editBreakpoint(file.key, point),
                    ),
                    _action(
                      'debug-remove-breakpoint-${file.key}-${point.line}',
                      Icons.close,
                      tr.remove,
                      () => c.toggleBreakpoint(file.key, point.line),
                    ),
                  ],
                );
              },
            ),
        ],
        if (c.capabilities.exceptionBreakpointFilters.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 8, 4),
            child: Text(
              tr.exceptions,
              style: context.typo.label.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          for (final filter in c.capabilities.exceptionBreakpointFilters)
            Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: Checkbox(
                    value: c.exceptionFilters.contains(filter.id),
                    onChanged: (_) => c.toggleExceptionFilter(filter.id),
                  ),
                ),
                Expanded(
                  child: Tooltip(
                    message: filter.description ?? filter.label,
                    child: Text(
                      filter.label,
                      style: context.typo.label.copyWith(fontSize: 11),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ],
      actions: [
        _action(
          'debug-toggle-breakpoints',
          c.breakpointsEnabled
              ? Icons.check_box_outlined
              : Icons.check_box_outline_blank,
          tr.enabled,
          () => c.setBreakpointsEnabled(!c.breakpointsEnabled),
        ),
        _action(
          'debug-remove-all-breakpoints',
          Icons.delete_outline,
          tr.removeAll,
          points.isEmpty ? null : c.removeAllBreakpoints,
        ),
      ],
    );
  }

  Future<void> _editBreakpoint(String path, SourceBreakpoint point) async {
    final tr = context.t.orkest.debugWorkbench;
    var condition = point.condition ?? '';
    var hit = point.hitCondition ?? '';
    var log = point.logMessage ?? '';
    Widget field(
      String value,
      String hint,
      String key,
      bool enabled,
      ValueChanged<String> onChanged,
    ) => TextFormField(
      key: ValueKey(key),
      initialValue: value,
      enabled: enabled,
      onChanged: onChanged,
      style: context.typo.mono.copyWith(
        fontSize: 11,
        color: context.colors.text,
      ),
      decoration: InputDecoration(labelText: hint, isDense: true),
    );
    final result = await sc.showDialog<bool>(
      context: context,
      builder: (dialog) => sc.AlertDialog(
        title: Text('${tr.edit} · ${p.basename(path)}:${point.line}'),
        content: SizedBox(
          width: 400,
          child: Material(
            color: Colors.transparent,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field(
                  condition,
                  tr.condition,
                  'debug-breakpoint-condition',
                  !c.isActive || c.capabilities.supportsConditionalBreakpoints,
                  (value) => condition = value,
                ),
                const SizedBox(height: 8),
                field(
                  hit,
                  tr.hitCondition,
                  'debug-breakpoint-hit',
                  !c.isActive ||
                      c.capabilities.supportsHitConditionalBreakpoints,
                  (value) => hit = value,
                ),
                const SizedBox(height: 8),
                field(
                  log,
                  tr.logMessage,
                  'debug-breakpoint-log',
                  !c.isActive || c.capabilities.supportsLogPoints,
                  (value) => log = value,
                ),
              ],
            ),
          ),
        ),
        actions: [
          sc.GhostButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(tr.cancel),
          ),
          sc.PrimaryButton(
            key: const ValueKey('debug-breakpoint-apply'),
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(tr.apply),
          ),
        ],
      ),
    );
    final updated = SourceBreakpoint(
      line: point.line,
      column: point.column,
      enabled: point.enabled,
      condition: condition.trim(),
      hitCondition: hit.trim(),
      logMessage: log.trim(),
    );
    if (mounted && result == true) await c.updateBreakpoint(path, updated);
  }

  Widget _field(
    TextEditingController controller,
    String hint, {
    String? key,
    bool enabled = true,
    ValueChanged<String>? onSubmitted,
    ValueChanged<String>? onChanged,
  }) => TextField(
    key: key == null ? null : ValueKey(key),
    controller: controller,
    enabled: enabled,
    onSubmitted: onSubmitted,
    onChanged: onChanged,
    style: context.typo.mono.copyWith(fontSize: 11, color: context.colors.text),
    decoration: InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 7),
      hintText: hint,
      hintStyle: context.typo.label.copyWith(
        fontSize: 11,
        color: context.colors.text3,
      ),
      border: InputBorder.none,
    ),
  );
  Widget _consoleView() {
    final tr = context.t.orkest.debugWorkbench;
    final query = _filter.text.toLowerCase();
    final logs = c.consoleLogs
        .where((line) => line.toLowerCase().contains(query))
        .toList();
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Expanded(
                child: _field(
                  _filter,
                  tr.filterConsole,
                  key: 'debug-console-filter',
                  onChanged: (_) => setState(() {}),
                ),
              ),
              _action(
                'debug-console-copy',
                Icons.copy_outlined,
                tr.copy,
                logs.isEmpty
                    ? null
                    : () => Clipboard.setData(
                        ClipboardData(text: logs.join('\n')),
                      ),
              ),
              _action(
                'debug-console-clear',
                Icons.clear_all,
                tr.clear,
                logs.isEmpty ? null : c.clearConsole,
              ),
            ],
          ),
        ),
        Expanded(
          child: logs.isEmpty
              ? Center(child: _hint(tr.emptyConsole))
              : ListView.builder(
                  key: const PageStorageKey('debug-console-output'),
                  itemCount: logs.length,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    child: SelectableText(
                      logs[index],
                      style: context.typo.mono.copyWith(
                        fontSize: 11,
                        color: context.colors.text,
                      ),
                    ),
                  ),
                ),
        ),
        Container(
          height: 32,
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: context.colors.border)),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Icon(Icons.chevron_right, size: 14, color: context.colors.accent),
              Expanded(
                child: _field(
                  _evaluateInput,
                  c.isStopped ? tr.evaluatePlaceholder : tr.pausedHint,
                  key: 'debug-console-evaluate',
                  enabled: c.isStopped,
                  onSubmitted: (_) => _evaluate(),
                ),
              ),
              _action(
                'debug-console-submit',
                Icons.arrow_upward,
                tr.apply,
                c.isStopped ? _evaluate : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
