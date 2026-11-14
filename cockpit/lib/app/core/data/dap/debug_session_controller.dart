import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/dart_debug_adapter.dart';
import 'package:orkest_code/app/core/data/dap/multi_language_debug_adapter.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'debug_failure.dart';

/// Controlador central e reativo de uma sessão de depuração DAP no Orkest Code.
/// Sessões, threads e inspeções têm identidades independentes: uma resposta de
/// um frame anterior nunca pode substituir o frame selecionado pelo usuário.
class DebugSessionController extends ChangeNotifier {
  DebugSessionController({
    this.onOutput,
    this.onSessionEnded,
    this.onStateEdited,
  });
  final void Function(String sessionId, DapOutputEvent event)? onOutput;
  final void Function(String sessionId, int? exitCode)? onSessionEnded;
  final VoidCallback? onStateEdited;
  Future<Map<String, dynamic>> Function(
    String command,
    Map<String, dynamic> arguments,
  )?
  onReverseRequest;
  bool _disposed = false;
  DapClient? _client;
  Future<void>? _stopping;
  StreamSubscription<DapEvent>? _eventsSub;
  StreamSubscription<DapStoppedEvent>? _stoppedSub;
  StreamSubscription<DapOutputEvent>? _outputSub;
  int _launchGeneration = 0;
  int _inspectionGeneration = 0;
  bool _busy = false;
  int? _exitCode;
  bool _attached = false;
  String _sessionName = '';
  String get sessionName => _sessionName;
  String get sessionId => _client?.sessionId ?? '';
  DapSessionState _state = DapSessionState.idle;
  DapSessionState get state => _state;
  bool get isRunning => _state == DapSessionState.running;
  bool get isStopped => _state == DapSessionState.stopped;
  bool get isActive => _state != DapSessionState.idle;
  int get inspectionVersion => _inspectionGeneration;
  bool get busy =>
      _busy ||
      _state == DapSessionState.initializing ||
      _state == DapSessionState.terminating;
  DapCapabilities get capabilities =>
      _client?.capabilities ?? const DapCapabilities();
  DebugFailure? lastError;
  int? _activeThreadId;
  int? get activeThreadId => _activeThreadId;
  DapStopReason? _lastStopReason;
  DapStopReason? get lastStopReason => _lastStopReason;
  String? stopDescription;
  List<DapThread> _threads = const [];
  List<DapThread> get threads => _threads;
  List<DapStackFrame> _stackFrames = const [];
  List<DapStackFrame> get stackFrames => _stackFrames;
  int? _selectedFrameId;
  DapStackFrame? get currentFrame =>
      _stackFrames.where((f) => f.id == _selectedFrameId).firstOrNull ??
      _stackFrames.firstOrNull;
  List<DapScope> _scopes = const [];
  List<DapScope> get scopes => _scopes;
  List<DapVariable> _variables = const [];
  List<DapVariable> get variables => _variables;
  final _variableCache = <int, List<DapVariable>>{};
  final _variableLoads = <(int, int), Future<List<DapVariable>>>{};
  final List<String> _watchExpressions = [];
  List<String> get watchExpressions => List.unmodifiable(_watchExpressions);
  final Map<String, List<SourceBreakpoint>> _breakpointsByPath = {};
  Map<String, List<SourceBreakpoint>> get breakpointsByPath =>
      Map.unmodifiable({
        for (final e in _breakpointsByPath.entries)
          e.key: List<SourceBreakpoint>.unmodifiable(e.value),
      });
  final _verified = <(String, int), DapBreakpoint>{};
  DapBreakpoint? breakpointStatus(String path, int line) =>
      _verified[(path, line)];
  int breakpointLine(String path, SourceBreakpoint point) =>
      _verified[(path, point.line)]?.line ?? point.line;
  Set<int> breakpointLines(
    String path, {
    bool disabled = false,
    bool unverified = false,
  }) => {
    for (final point in _breakpointsByPath[path] ?? const <SourceBreakpoint>[])
      if ((!disabled || !breakpointsEnabled || !point.enabled) &&
          (!unverified ||
              (isActive && _verified[(path, point.line)]?.verified != true)))
        breakpointLine(path, point),
  };
  bool breakpointsEnabled = true;
  final List<String> _consoleLogs = [];
  List<String> get consoleLogs => List.unmodifiable(_consoleLogs);
  DartDebugTarget? _activeTarget;
  DartDebugTarget? get activeTarget => _activeTarget;
  bool get isFlutter => _activeTarget?.isFlutter ?? false;
  final Set<String> _exceptionFilters = {};
  Set<String> get exceptionFilters => Set.unmodifiable(_exceptionFilters);
  bool _exceptionFiltersConfigured = false;
  String _exceptionMode = 'Unhandled';
  String get exceptionMode => _exceptionMode;

  void addWatch(String expression) {
    final value = expression.trim();
    if (value.isEmpty || _watchExpressions.contains(value)) return;
    _watchExpressions.add(value);
    _edited();
  }

  void removeWatch(String expression) {
    _watchExpressions.remove(expression);
    _edited();
  }

  void clearConsole() {
    _consoleLogs.clear();
    notifyListeners();
  }

  void _edited() {
    onStateEdited?.call();
    notifyListeners();
  }

  Map<String, dynamic> exportState() => {
    'breakpointsEnabled': breakpointsEnabled,
    'breakpoints': {
      for (final e in _breakpointsByPath.entries)
        e.key: e.value.map((b) => b.toState()).toList(),
    },
    'watches': _watchExpressions.toList(),
    'exceptionFilters': _exceptionFilters.toList(),
    'exceptionsConfigured': _exceptionFiltersConfigured,
  };
  void restoreState(Object? state) {
    if (state is! Map) return;
    breakpointsEnabled = state['breakpointsEnabled'] != false;
    _breakpointsByPath.clear();
    final raw = state['breakpoints'];
    if (raw is Map) {
      for (final e in raw.entries) {
        if (e.key is! String || e.value is! List) continue;
        final points = (e.value as List)
            .map(SourceBreakpoint.fromState)
            .whereType<SourceBreakpoint>()
            .toList();
        if (points.isNotEmpty) _breakpointsByPath[e.key as String] = points;
      }
    }
    _watchExpressions
      ..clear()
      ..addAll(
        (state['watches'] is List ? state['watches'] as List : const [])
            .whereType<String>()
            .where((s) => s.trim().isNotEmpty)
            .toSet(),
      );
    _exceptionFiltersConfigured = state['exceptionsConfigured'] == true;
    _exceptionFilters
      ..clear()
      ..addAll(
        (state['exceptionFilters'] is List
                ? state['exceptionFilters'] as List
                : const [])
            .whereType<String>(),
      );
    notifyListeners();
  }

  Future<void> setExceptionMode(String mode) async {
    _exceptionMode = mode;
    _exceptionFiltersConfigured = true;
    final filters = capabilities.exceptionBreakpointFilters;
    _exceptionFilters.clear();
    if (mode != 'None') {
      final exact = filters
          .where((f) => f.id.toLowerCase() == mode.toLowerCase())
          .toList();
      _exceptionFilters.addAll(
        (exact.isNotEmpty
                ? exact
                : filters.where((f) => mode == 'All' || f.defaultEnabled))
            .map((f) => f.id),
      );
    }
    await _sendExceptionFilters();
    _edited();
  }

  Future<void> toggleExceptionFilter(String id) async {
    if (!capabilities.exceptionBreakpointFilters.any((f) => f.id == id)) return;
    _exceptionFiltersConfigured = true;
    if (!_exceptionFilters.remove(id)) _exceptionFilters.add(id);
    await _sendExceptionFilters();
    _edited();
  }

  Future<void> _sendExceptionFilters() async {
    final client = _client;
    if (client == null || !isActive) return;
    try {
      _check(await client.setExceptionBreakpoints(_exceptionFilters.toList()));
    } on Exception catch (error) {
      _error(error);
    }
  }

  Future<void> startDartSession({
    required DartDebugTarget target,
    String? sdkPath,
    DapClient? clientOverride,
  }) async {
    final token = ++_launchGeneration;
    await _stopActive();
    final client =
        clientOverride ??
        await DartDebugAdapter.spawnClient(target: target, sdkPath: sdkPath);
    await _begin(
      client: client,
      token: token,
      program: target.program,
      cwd: target.cwd,
      args: target.args,
      target: target,
      noDebug: target.noDebug,
      launchArguments: target.toDapLaunchArgs(),
    );
  }

  Future<void> startFromRunConfiguration({
    required RunConfiguration config,
    DapClient? clientOverride,
    Map<String, String> extraEnv = const {},
  }) async {
    final token = ++_launchGeneration;
    await _stopActive();
    lastError = null;
    _sessionName = config.name;
    final dart = ['dart', 'flutter'].contains(config.type);
    final language = switch (config.type) {
      'node' || 'pwa-node' || 'node-terminal' => 'javascript',
      'debugpy' => 'python',
      'coreclr' => 'csharp',
      'cargo' || 'lldb' || 'cppdbg' || 'cppvsdbg' => 'rust',
      'dlv' => 'go',
      _ => config.type,
    };
    final target = dart ? config.toDartDebugTarget() : null;
    try {
      final server = config.launchArguments['debugServer'];
      if (server != null && (server is! int || server <= 0 || server > 65535)) {
        throw const DebugFailure(DebugFailureKind.configuration, 'debugServer');
      }
      final client =
          clientOverride ??
          (server is int
              ? await DapClient.connectSocket(
                  host: '127.0.0.1',
                  port: server,
                  sessionId: '${config.id}-$token',
                )
              : dart
              ? await DartDebugAdapter.spawnClient(
                  target: target!,
                  sdkPath: config.sdkPath,
                )
              : await MultiLanguageDebugAdapter.spawnClient(
                  languageId: language,
                  cwd: config.cwd,
                  configuration: config.launchArguments,
                ));
      if (client == null) {
        throw DebugFailure(DebugFailureKind.adapter, config.type);
      }
      await _begin(
        client: client,
        token: token,
        program: config.program,
        cwd: config.cwd,
        args: config.args,
        target: target,
        env: {...config.env, ...extraEnv},
        request: config.request,
        launchArguments: {
          if (target != null) ...target.toDapLaunchArgs(),
          if (!dart)
            ...MultiLanguageDebugAdapter.buildLaunchArgs(
              languageId: language,
              program: config.program,
              cwd: config.cwd,
              args: config.args,
            ),
          ...config.launchArguments,
          'env': {...config.env, ...extraEnv},
        },
      );
    } on Exception catch (error) {
      if (token == _launchGeneration && !_disposed) {
        _error(error);
        await _stopActive();
      }
    }
  }

  /// Inicia uma nova sessão de depuração associada ao [client].
  Future<void> startSession({
    required DapClient client,
    required String program,
    List<String> args = const [],
    String? cwd,
    Map<String, dynamic>? env,
    bool noDebug = false,
    String request = 'launch',
    Map<String, dynamic> launchArguments = const {},
    DartDebugTarget? target,
  }) async {
    final token = ++_launchGeneration;
    await _stopActive();
    await _begin(
      client: client,
      token: token,
      program: program,
      args: args,
      cwd: cwd,
      env: env,
      noDebug: noDebug,
      request: request,
      launchArguments: launchArguments,
      target: target,
    );
  }

  Future<void> _begin({
    required DapClient client,
    required int token,
    required String program,
    List<String> args = const [],
    String? cwd,
    Map<String, dynamic>? env,
    bool noDebug = false,
    String request = 'launch',
    Map<String, dynamic> launchArguments = const {},
    DartDebugTarget? target,
  }) async {
    if (_disposed || token != _launchGeneration) {
      await client.close();
      return;
    }
    _client = client;
    client.onReverseRequest = onReverseRequest;
    _activeTarget = target;
    _attached = request == 'attach';
    _exitCode = null;
    lastError = null;
    _consoleLogs.clear();
    _verified.clear();
    _setState(DapSessionState.initializing);
    final initialized = Completer<void>();
    _stoppedSub = client.stoppedEvents.listen((event) {
      if (_client == client) unawaited(_handleStopped(event));
    });
    _outputSub = client.outputEvents.listen((event) {
      if (_client != client) return;
      _logConsole(event.output);
      onOutput?.call(client.sessionId, event);
    });
    _eventsSub = client.events.listen(
      (event) {
        if (_client != client) return;
        switch (event.event) {
          case 'initialized':
            if (!initialized.isCompleted) initialized.complete();
          case 'continued':
            _clearInspection();
            _setState(DapSessionState.running);
          case 'exited':
            _exitCode = event.body?['exitCode'] as int?;
          case 'terminated':
            unawaited(stop());
          case 'capabilities':
            notifyListeners();
          case 'breakpoint':
            final raw = event.body?['breakpoint'];
            if (raw is Map) {
              final value = DapBreakpoint.fromJson(raw.cast<String, dynamic>());
              final match = _verified.entries
                  .where((e) => value.id != null && e.value.id == value.id)
                  .firstOrNull;
              if (match != null) _verified[match.key] = value;
              notifyListeners();
            }
        }
      },
      onDone: () {
        if (_client == client) unawaited(stop());
      },
    );
    try {
      await client.initialize();
      if (_client != client) return;
      final available = capabilities.exceptionBreakpointFilters;
      _exceptionFilters.removeWhere(
        (id) => !available.any((filter) => filter.id == id),
      );
      if (!_exceptionFiltersConfigured) {
        _exceptionFilters.addAll(
          available.where((f) => f.defaultEnabled).map((f) => f.id),
        );
      }
      _exceptionFiltersConfigured = true;
      final launch = client.sendRequest(request, {
        'program': program,
        'args': args,
        'cwd': ?cwd,
        'env': ?env,
        'noDebug': noDebug,
        ...launchArguments,
      });
      final ready = launch.then<void>((response) {
        _check(response);
        return initialized.future;
      });
      await Future.any([
        initialized.future,
        ready,
      ]).timeout(const Duration(seconds: 20));
      if (_client != client) return;
      for (final path in _breakpointsByPath.keys.toList()) {
        await _syncBreakpoints(path);
      }
      if (available.isNotEmpty) {
        _check(
          await client.setExceptionBreakpoints(_exceptionFilters.toList()),
        );
      }
      if (client.capabilities.supportsConfigurationDoneRequest) {
        _check(await client.configurationDone());
      }
      _check(await launch);
      if (_client == client && _state == DapSessionState.initializing) {
        _setState(DapSessionState.running);
      }
    } on Exception catch (error) {
      if (_client == client) {
        _error(error);
        await _stopActive();
      }
    }
  }

  Future<void> toggleBreakpoint(String path, int line) async {
    final list = _breakpointsByPath.putIfAbsent(path, () => []);
    final index = list.indexWhere(
      (b) => b.line == line || breakpointLine(path, b) == line,
    );
    if (index >= 0) {
      list.removeAt(index);
    } else {
      list.add(SourceBreakpoint(line: line));
    }
    if (list.isEmpty) _breakpointsByPath.remove(path);
    _edited();
    await _syncBreakpoints(path);
  }

  Future<void> updateBreakpoint(
    String path,
    SourceBreakpoint breakpoint,
  ) async {
    final list = _breakpointsByPath.putIfAbsent(path, () => []);
    final index = list.indexWhere((b) => b.line == breakpoint.line);
    if (index < 0) {
      list.add(breakpoint);
    } else {
      list[index] = breakpoint;
    }
    _edited();
    await _syncBreakpoints(path);
  }

  Future<void> setBreakpointsEnabled(bool enabled) async {
    breakpointsEnabled = enabled;
    _edited();
    for (final path in _breakpointsByPath.keys.toList()) {
      await _syncBreakpoints(path);
    }
  }

  Future<void> removeAllBreakpoints() async {
    final paths = _breakpointsByPath.keys.toList();
    _breakpointsByPath.clear();
    _verified.clear();
    _edited();
    for (final path in paths) {
      await _syncBreakpoints(path);
    }
  }

  final _breakpointVersions = <String, int>{};
  Future<void> _syncBreakpoints(String path) async {
    final client = _client;
    if (client == null || !isActive) return;
    final version = (_breakpointVersions[path] ?? 0) + 1;
    _breakpointVersions[path] = version;
    final points = breakpointsEnabled
        ? (_breakpointsByPath[path] ?? const <SourceBreakpoint>[])
              .where((b) => b.enabled)
              .toList()
        : <SourceBreakpoint>[];
    final unsupported = <SourceBreakpoint, String>{};
    for (final point in points) {
      if (point.condition?.isNotEmpty == true &&
          !capabilities.supportsConditionalBreakpoints) {
        unsupported[point] = 'supportsConditionalBreakpoints=false';
      }
      if (point.hitCondition?.isNotEmpty == true &&
          !capabilities.supportsHitConditionalBreakpoints) {
        unsupported[point] = 'supportsHitConditionalBreakpoints=false';
      }
      if (point.logMessage?.isNotEmpty == true &&
          !capabilities.supportsLogPoints) {
        unsupported[point] = 'supportsLogPoints=false';
      }
    }
    final accepted = points
        .where((point) => !unsupported.containsKey(point))
        .toList();
    try {
      final result = await client.setBreakpoints(
        sourcePath: path,
        breakpoints: accepted,
      );
      if (_client != client || version != _breakpointVersions[path]) return;
      _verified.removeWhere((key, _) => key.$1 == path);
      for (var i = 0; i < accepted.length && i < result.length; i++) {
        _verified[(path, accepted[i].line)] = result[i];
      }
      for (final entry in unsupported.entries) {
        _verified[(path, entry.key.line)] = DapBreakpoint(
          verified: false,
          line: entry.key.line,
          message: entry.value,
        );
      }
      notifyListeners();
    } on Exception catch (error) {
      _error(error);
    }
  }

  Future<void> _control(
    Future<DapResponse> Function(DapClient client, int thread) command, {
    bool running = false,
  }) async {
    final client = _client;
    if (client == null || _busy || (running ? !isRunning : !isStopped)) return;
    final generation = _inspectionGeneration;
    _busy = true;
    lastError = null;
    notifyListeners();
    try {
      var thread = _activeThreadId;
      thread ??= (await client.threads()).firstOrNull?.id;
      if (thread == null) {
        throw const DebugFailure(DebugFailureKind.request, 'No active thread');
      }
      _check(await command(client, thread));
      if (_client == client &&
          !running &&
          generation == _inspectionGeneration) {
        _clearInspection();
        _setState(DapSessionState.running);
      }
    } on Exception catch (error) {
      if (_client == client) _error(error);
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> pause() => _control((c, t) => c.pause(t), running: true);
  Future<void> resume() => _control((c, t) => c.resume(t));
  Future<void> stepOver() => _control((c, t) => c.stepOver(t));
  Future<void> stepIn() => _control((c, t) => c.stepIn(t));
  Future<void> stepOut() => _control((c, t) => c.stepOut(t));
  Future<void> restartFrame(int id) async {
    if (!capabilities.supportsRestartFrame) return;
    await _control((c, _) => c.restartFrame(id));
  }

  Future<void> restart() async {
    final client = _client;
    if (client == null || !capabilities.supportsRestartRequest || busy) return;
    try {
      _check(await client.restart());
    } on Exception catch (error) {
      _error(error);
    }
  }

  Future<bool> hotReload() =>
      _flutterCommand((c) => c.hotReload(), 'Hot Reload');
  Future<bool> hotRestart() =>
      _flutterCommand((c) => c.hotRestart(), 'Hot Restart');
  Future<bool> _flutterCommand(
    Future<DapResponse> Function(DapClient) command,
    String label,
  ) async {
    final client = _client;
    if (client == null || !isActive || !isFlutter || busy) return false;
    try {
      _check(await command(client));
      _logConsole('[DAP Flutter]: $label concluído com sucesso.');
      return true;
    } on Exception catch (error) {
      _error(error);
      return false;
    }
  }

  Future<String?> evaluate(String expression, {int? frameId}) async =>
      (await evaluateValue(expression, frameId: frameId))?.result;
  Future<DapEvaluateResult?> evaluateValue(
    String expression, {
    int? frameId,
    String context = 'watch',
  }) async {
    final client = _client;
    final generation = _inspectionGeneration;
    if (client == null || !isStopped) return null;
    try {
      final result = await client.evaluate(
        expression,
        frameId: frameId ?? currentFrame?.id,
        context: context,
      );
      return _client == client &&
              isStopped &&
              generation == _inspectionGeneration
          ? result
          : null;
    } on Exception catch (error) {
      if (_client == client) _error(error);
      return null;
    }
  }

  Future<void> evaluateInConsole(String expression) async {
    final result = await evaluateValue(expression, context: 'repl');
    if (result != null) _logConsole('> $expression\n${result.result}');
  }

  Future<List<DapVariable>> variablesFor(int reference) async {
    final client = _client;
    final generation = _inspectionGeneration;
    if (client == null || !isStopped || reference == 0) return const [];
    final cached = _variableCache[reference];
    if (cached != null) return cached;
    try {
      final key = (generation, reference);
      final pending = _variableLoads.putIfAbsent(
        key,
        () => client.variables(reference),
      );
      final values = await pending;
      _variableLoads.remove(key);
      if (_client != client ||
          !isStopped ||
          generation != _inspectionGeneration) {
        return const [];
      }
      _variableCache[reference] = values;
      return values;
    } on Exception catch (error) {
      _variableLoads.remove((generation, reference));
      if (_client == client) _error(error);
      return const [];
    }
  }

  Future<void> setVariable(int reference, String name, String value) async {
    final client = _client;
    final frame = currentFrame?.id;
    final generation = _inspectionGeneration;
    if (client == null || !isStopped || !capabilities.supportsSetVariable) {
      return;
    }
    try {
      _check(await client.setVariable(reference, name, value));
      if (_client == client &&
          isStopped &&
          generation == _inspectionGeneration &&
          frame != null) {
        await selectFrame(frame);
      }
    } on Exception catch (error) {
      if (_client == client) _error(error);
    }
  }

  Future<void> selectFrame(int frameId) async {
    final client = _client;
    if (client == null || !isStopped) return;
    final generation = ++_inspectionGeneration;
    _selectedFrameId = frameId;
    _scopes = const [];
    _variables = const [];
    _variableCache.clear();
    _variableLoads.clear();
    notifyListeners();
    try {
      final scopes = await client.scopes(frameId);
      if (_client != client ||
          !isStopped ||
          generation != _inspectionGeneration) {
        return;
      }
      _scopes = scopes;
      notifyListeners();
      if (scopes.isNotEmpty) {
        final values = await variablesFor(scopes.first.variablesReference);
        if (_client != client ||
            !isStopped ||
            generation != _inspectionGeneration) {
          return;
        }
        _variables = values;
      }
      notifyListeners();
    } on Exception catch (error) {
      if (_client == client) _error(error);
    }
  }

  Future<void> selectThread(int threadId) async {
    final client = _client;
    if (client == null || !isStopped) return;
    final generation = ++_inspectionGeneration;
    _activeThreadId = threadId;
    _stackFrames = const [];
    _selectedFrameId = null;
    _scopes = const [];
    _variables = const [];
    _variableCache.clear();
    _variableLoads.clear();
    notifyListeners();
    try {
      final frames = await client.stackTrace(threadId);
      if (_client != client ||
          !isStopped ||
          generation != _inspectionGeneration) {
        return;
      }
      _stackFrames = frames;
      if (frames.isNotEmpty) {
        await selectFrame(frames.first.id);
      } else {
        notifyListeners();
      }
    } on Exception catch (error) {
      if (_client == client) _error(error);
    }
  }

  Future<void> _handleStopped(DapStoppedEvent event) async {
    final client = _client;
    if (client == null) return;
    _clearInspection();
    _lastStopReason = event.reason;
    stopDescription = event.description ?? event.text;
    _setState(DapSessionState.stopped);
    final generation = _inspectionGeneration;
    try {
      final threads = await client.threads();
      if (_client != client ||
          !isStopped ||
          generation != _inspectionGeneration) {
        return;
      }
      _threads = threads;
      final thread = event.threadId ?? threads.firstOrNull?.id;
      if (thread != null) {
        await selectThread(thread);
      } else {
        notifyListeners();
      }
    } on Exception catch (error) {
      if (_client == client) _error(error);
    }
  }

  void _clearInspection() {
    _inspectionGeneration++;
    _selectedFrameId = null;
    _stackFrames = const [];
    _scopes = const [];
    _variables = const [];
    _variableCache.clear();
    _variableLoads.clear();
  }

  Future<void> stop() async {
    _launchGeneration++;
    await _stopActive();
  }

  Future<void> _stopActive() {
    final pending = _stopping;
    if (pending != null) return pending;
    final client = _client;
    if (client == null) {
      _setState(DapSessionState.idle);
      return Future<void>.value();
    }
    return _stopping = _finishStopActive(client).whenComplete(() {
      _stopping = null;
    });
  }

  Future<void> _finishStopActive(DapClient client) async {
    final attached = _attached;
    final exitCode = _exitCode;
    _client = null;
    _clearInspection();
    _setState(DapSessionState.terminating);
    await _eventsSub?.cancel();
    await _stoppedSub?.cancel();
    await _outputSub?.cancel();
    _eventsSub = null;
    _stoppedSub = null;
    _outputSub = null;
    await client.disconnect(terminateDebuggee: !attached);
    onSessionEnded?.call(client.sessionId, exitCode);
    _activeThreadId = null;
    _lastStopReason = null;
    stopDescription = null;
    _activeTarget = null;
    _threads = const [];
    _verified.clear();
    _busy = false;
    _setState(DapSessionState.idle);
  }

  void _check(DapResponse response) {
    if (!response.success) {
      throw DebugFailure(
        DebugFailureKind.request,
        response.message ?? '',
        command: response.command,
      );
    }
  }

  void _error(Object error) {
    lastError = error is DebugFailure
        ? error
        : DebugFailure(DebugFailureKind.request, error.toString());
    _logConsole(lastError.toString());
  }

  void _logConsole(String text) {
    final clean = text.trimRight();
    if (clean.isEmpty) return;
    _consoleLogs.add(clean);
    if (_consoleLogs.length > 1000) {
      _consoleLogs.removeRange(0, _consoleLogs.length - 1000);
    }
    notifyListeners();
  }

  void _setState(DapSessionState state) {
    _state = state;
    notifyListeners();
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _launchGeneration++;
    unawaited(_stopActive());
    super.dispose();
  }
}
