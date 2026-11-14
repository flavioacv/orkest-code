import 'dart:convert';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:orkest_code/app/core/domain/entities/lsp_symbol.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_loader.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/tasks_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_panel.dart';
import 'package:orkest_code/app/orkest/domain/entities/task_definition.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
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
  StreamSubscription<({String workspaceId, bool noDebug})>? _launchRequests;

  @override
  void initState() {
    super.initState();
    _load();
    _launchRequests = widget.vm.debugLaunchRequests.listen((request) {
      if (request.workspaceId == widget.workspaceId) {
        unawaited(_startPreferred(noDebug: request.noDebug));
      }
    });
  }

  void _load() {
    _configurations = const RunConfigurationLoader().load(
      widget.root,
      widget.path,
      workspaceRoots: widget.workspaceRoots,
    );
    // Preserve the selected configuration while discovery refreshes.
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

  @override
  void dispose() {
    unawaited(_launchRequests?.cancel());
    super.dispose();
  }

  Future<void> _startPreferred({bool noDebug = false}) async {
    try {
      final configs = await _configurations;
      if (!mounted || widget.vm.selectedProjectId != widget.workspaceId) return;
      final id = widget.vm.debugConfigurationId(widget.workspaceId);
      final config =
          configs.where((c) => c.id == _selected?.id).firstOrNull ??
          configs.where((c) => c.id == id).firstOrNull ??
          configs.firstOrNull;
      if (config != null) await _start(config, debug: !noDebug);
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
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
        await widget.vm.startDebugConfiguration(
          widget.workspaceId,
          config,
          onReverseRequest: _runInTerminal,
        );
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

  Future<Map<String, dynamic>> _runInTerminal(
    String command,
    Map<String, dynamic> arguments,
  ) async {
    if (command != 'runInTerminal' ||
        !mounted ||
        widget.vm.selectedProjectId != widget.workspaceId) {
      throw UnsupportedError(command);
    }
    final argv = (arguments['args'] as List? ?? const []).cast<String>();
    if (argv.isEmpty || arguments['argsCanBeInterpretedByShell'] == true) {
      throw const FormatException('DAP terminal requires literal arguments');
    }
    final tasks = context.read<TasksViewModel>();
    final id = 'dap-terminal-${DateTime.now().microsecondsSinceEpoch}';
    final rawEnv = (arguments['env'] as Map? ?? const {})
        .cast<String, dynamic>();
    final def = TaskDefinition(
      id: id,
      label: arguments['title'] as String? ?? id,
      cwd: arguments['cwd'] as String? ?? widget.root,
      command: argv.first,
      args: argv.skip(1).toList(),
      kind: TaskKind.watch,
      profiles: [
        TaskProfile(
          name: 'dap',
          args: const [],
          env: rawEnv.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        ),
      ],
    );
    await tasks.start(def);
    await tasks.attachOutput(id);
    final pid = tasks.stateOf(id).pid;
    return {'shellProcessId': ?pid};
  }

  Future<void> _configure() async {
    try {
      await _openConfiguration();
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  Future<void> _openConfiguration() async {
    final path = p.join(widget.root, '.vscode', 'launch.json');
    final file = File(path);
    if (!await file.exists()) {
      await file.parent.create(recursive: true);
      final configurations = await _configurations;
      final selected =
          configurations.where((c) => c.id == _selected?.id).firstOrNull ??
          configurations.firstOrNull;
      await file.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'version': '0.2.0',
          'configurations': [
            if (selected != null)
              {
                'name': selected.name,
                'type': selected.type == 'flutter' ? 'dart' : selected.type,
                'request': selected.request,
                'program': selected.program,
                'cwd': selected.cwd,
                if (selected.args.isNotEmpty) 'args': selected.args,
                ...selected.launchArguments,
              },
          ],
        }),
      );
    }
    if (!mounted) return;
    await widget.vm.openFile(path);
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
        final restoredId = widget.vm.debugConfigurationId(widget.workspaceId);
        final selected =
            configs.where((c) => c.id == _selected?.id).firstOrNull ??
            configs.where((c) => c.id == restoredId).firstOrNull ??
            configs.firstOrNull;
        return DebugPanel(
          controller: controller,
          configurations: configs,
          selectedConfiguration: selected,
          isStarting:
              _starting || snapshot.connectionState != ConnectionState.done,
          configurationError: snapshot.hasError
              ? snapshot.error.toString()
              : _error,
          onSelectConfiguration: (configuration) {
            setState(() => _selected = configuration);
            widget.vm.selectDebugConfiguration(
              widget.workspaceId,
              configuration.id,
            );
          },
          onStartConfiguration: (configuration) => _start(configuration),
          onRunConfiguration: (configuration) =>
              _start(configuration, debug: false),
          onRestart: selected == null ? null : () => _start(selected),
          onConfigure: _configure,
          onReload: () => setState(_load),
          onNavigateToSource: widget.vm.navigateToSource,
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
