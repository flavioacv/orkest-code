import 'dart:async';
import 'package:orkest_code/i18n/strings.g.dart';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_loader.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/tasks_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_toolbar.dart';
import 'package:orkest_code/app/orkest/ui/widgets/outline_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:flutter_modular/flutter_modular.dart';

class WorkspaceDebugPanel extends StatefulWidget {
  const WorkspaceDebugPanel({
    super.key,
    required this.vm,
    required this.workspaceId,
    required this.root,
    this.path,
    this.workspaceRoots = const [],
  });
  final OrkestViewModel vm;
  final String workspaceId;
  final String root;
  final List<String> workspaceRoots;
  final String? path;
  @override
  State<WorkspaceDebugPanel> createState() => _WorkspaceDebugPanelState();
}

class _WorkspaceDebugPanelState extends State<WorkspaceDebugPanel> {
  late Future<List<RunConfiguration>> _configurations;
  RunConfiguration? _selected;
  String? _error;
  bool _starting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    _configurations = const RunConfigurationLoader().load(
      widget.root,
      widget.path,
      workspaceRoots: widget.workspaceRoots,
    );
    _selected = null;
  }

  @override
  void didUpdateWidget(WorkspaceDebugPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.root != widget.root ||
        !listEquals(oldWidget.workspaceRoots, widget.workspaceRoots)) {
      _load();
    }
  }

  Future<void> _start(RunConfiguration config, {bool debug = true}) async {
    if (_starting) return;
    setState(() {
      _starting = true;
      _error = null;
    });
    try {
      if (debug) {
        await widget.vm
            .debugForWorkspace(widget.workspaceId)
            .startFromRunConfiguration(config: config);
      } else {
        final tasks = context.read<TasksViewModel>();
        final task = config.toTaskDefinition();
        await tasks.start(task);
        await tasks.attachOutput(task.id);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.vm.debugForWorkspace(widget.workspaceId);
    return FutureBuilder<List<RunConfiguration>>(
      future: _configurations,
      builder: (context, snapshot) {
        final configs = snapshot.connectionState == ConnectionState.done
            ? snapshot.data ?? const <RunConfiguration>[]
            : const <RunConfiguration>[];
        final selected = _selected ?? configs.firstOrNull;
        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DebugToolbar(controller: controller),
            ),
            if (snapshot.hasError || _error != null)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SelectableText('${_error ?? snapshot.error}'),
              ),
            if (snapshot.connectionState != ConnectionState.done)
              const LinearProgressIndicator(),
            if (selected != null)
              sc.GhostButton(
                onPressed: _starting
                    ? null
                    : () => _start(selected, debug: false),
                child: Text(
                  context.t.orkest.fileTreePanel.workbenchRunTerminal,
                ),
              ),
            Expanded(
              child: DebugPanel(
                controller: controller,
                configurations: configs,
                selectedConfiguration: selected,
                onSelectConfiguration: (config) =>
                    setState(() => _selected = config),
                onStartConfiguration: _starting
                    ? null
                    : (config) => _start(config),
                onNavigateToSource: widget.vm.navigateToSource,
              ),
            ),
          ],
        );
      },
    );
  }
}

class WorkspaceOutlinePanel extends StatefulWidget {
  const WorkspaceOutlinePanel({super.key, required this.vm, this.path});
  final OrkestViewModel vm;
  final String? path;
  @override
  State<WorkspaceOutlinePanel> createState() => _WorkspaceOutlinePanelState();
}

class _WorkspaceOutlinePanelState extends State<WorkspaceOutlinePanel> {
  StreamSubscription<String>? _changes;
  List<LspDocumentSymbol> _symbols = const [];
  String? _error;
  int _generation = 0;
  bool _active = false;
  bool _loading = false;
  @override
  void initState() {
    super.initState();
    _changes = widget.vm.documentChanges.listen((path) {
      if (path == widget.path && _active) _load();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = WorkbenchToolVisibility.isActive(context);
    if (active && !_active) _load();
    _active = active;
  }

  @override
  void didUpdateWidget(WorkspaceOutlinePanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _generation++;
      _symbols = const [];
      _error = null;
      if (_active) _load();
    }
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final path = widget.path;
    if (path == null) {
      _symbols = const [];
      _loading = false;
      _error = null;
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await widget.vm.documentSymbols(path);
      if (mounted && generation == _generation) {
        setState(() => _symbols = result);
      }
    } catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _error = '$error');
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _generation++;
    unawaited(_changes?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (_loading) const LinearProgressIndicator(),
      if (_error != null) Text(_error!),
      sc.GhostButton(
        onPressed: widget.path == null ? null : _load,
        child: const Icon(Icons.refresh, size: 16),
      ),
      Expanded(
        child: OutlinePanel(
          symbols: _symbols,
          currentFilePath: widget.path,
          onNavigateToSource: (line, column) {
            final path = widget.path;
            if (path != null) widget.vm.navigateToSource(path, line, column);
          },
        ),
      ),
    ],
  );
}
