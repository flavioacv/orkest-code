import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/dart_debug_adapter.dart';
import 'package:orkest_code/app/core/data/dap/multi_language_debug_adapter.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';

/// Controlador central e reativo de uma sessão de depuração DAP no Orkest Code.
///
/// Gerencia a máquina de estados (idle, initializing, running, stopped),
/// sincroniza breakpoints, pilha de execução, variáveis inspecionadas e
/// rejeita respostas/eventos obsoletos de sessões antigas.
class DebugSessionController extends ChangeNotifier {
  DebugSessionController();
  bool _disposed = false;
  StreamSubscription<DapEvent>? _eventsSub;

  DapClient? _client;
  String _activeSessionId = '';
  StreamSubscription<DapStoppedEvent>? _stoppedSub;
  StreamSubscription<DapOutputEvent>? _outputSub;

  DapSessionState _state = DapSessionState.idle;
  DapSessionState get state => _state;

  bool get isRunning => _state == DapSessionState.running;
  bool get isStopped => _state == DapSessionState.stopped;
  bool get isActive => _state != DapSessionState.idle;

  int? _activeThreadId;
  int? get activeThreadId => _activeThreadId;

  DapStopReason? _lastStopReason;
  DapStopReason? get lastStopReason => _lastStopReason;

  List<DapThread> _threads = const [];
  List<DapThread> get threads => _threads;

  List<DapStackFrame> _stackFrames = const [];
  List<DapStackFrame> get stackFrames => _stackFrames;

  /// Retorna o frame superior da pilha de execução quando pausado, ou `null`.
  int? _selectedFrameId;
  DapStackFrame? get currentFrame =>
      _stackFrames.where((frame) => frame.id == _selectedFrameId).firstOrNull ??
      _stackFrames.firstOrNull;

  List<DapScope> _scopes = const [];
  List<DapScope> get scopes => _scopes;

  List<DapVariable> _variables = const [];
  List<DapVariable> get variables => _variables;

  final List<String> _watchExpressions = [];
  List<String> get watchExpressions => List.unmodifiable(_watchExpressions);

  /// Adiciona uma expressão para observação contínua.
  void addWatch(String expression) {
    final clean = expression.trim();
    if (clean.isNotEmpty && !_watchExpressions.contains(clean)) {
      _watchExpressions.add(clean);
      notifyListeners();
    }
  }

  /// Remove uma expressão observada.
  void removeWatch(String expression) {
    if (_watchExpressions.remove(expression)) {
      notifyListeners();
    }
  }

  final Map<String, List<SourceBreakpoint>> _breakpointsByPath = {};
  Map<String, List<SourceBreakpoint>> get breakpointsByPath =>
      Map.unmodifiable(_breakpointsByPath);

  final List<String> _consoleLogs = [];
  List<String> get consoleLogs => List.unmodifiable(_consoleLogs);

  DartDebugTarget? _activeTarget;
  DartDebugTarget? get activeTarget => _activeTarget;

  /// Indica se a sessão atual é uma aplicação ou teste Flutter.
  bool get isFlutter => _activeTarget?.isFlutter ?? false;

  String _exceptionMode = 'Unhandled';
  String get exceptionMode => _exceptionMode;

  /// Atualiza o modo de captura de exceções ('None', 'Unhandled', 'All').
  Future<void> setExceptionMode(String mode) async {
    _exceptionMode = mode;
    final client = _client;
    if (client != null && isActive) {
      await client.setExceptionBreakpoints([mode]);
    }
    notifyListeners();
  }

  /// Dispara Hot Reload na sessão Flutter ativa.
  Future<bool> hotReload() async {
    final client = _client;
    if (client == null || !isActive) return false;

    _logConsole('[DAP Flutter]: Disparando Hot Reload...');
    final res = await client.hotReload();
    if (res.success) {
      _logConsole('[DAP Flutter]: Hot Reload concluído com sucesso.');
      return true;
    } else {
      _logConsole(
        '[DAP Flutter Erro]: Falha no Hot Reload: ${res.message ?? 'Desconhecida'}',
      );
      return false;
    }
  }

  /// Dispara Hot Restart na sessão Flutter ativa.
  Future<bool> hotRestart() async {
    final client = _client;
    if (client == null || !isActive) return false;

    _logConsole('[DAP Flutter]: Disparando Hot Restart...');
    final res = await client.hotRestart();
    if (res.success) {
      _logConsole('[DAP Flutter]: Hot Restart concluído com sucesso.');
      return true;
    } else {
      _logConsole(
        '[DAP Flutter Erro]: Falha no Hot Restart: ${res.message ?? 'Desconhecida'}',
      );
      return false;
    }
  }

  /// Inicia uma nova sessão de depuração especializada para Dart ou Flutter.
  Future<void> startDartSession({
    required DartDebugTarget target,
    String? sdkPath,
    DapClient? clientOverride,
  }) async {
    final client =
        clientOverride ??
        await DartDebugAdapter.spawnClient(target: target, sdkPath: sdkPath);

    _activeTarget = target;
    final launchArgs = target.toDapLaunchArgs();

    await startSession(
      client: client,
      program: target.program,
      args: (launchArgs['args'] as List?)?.cast<String>() ?? const [],
      cwd: target.cwd,
      noDebug: target.noDebug,
      launchArguments: launchArgs,
      target: target,
    );
  }

  /// Inicia uma nova sessão de depuração a partir de uma [RunConfiguration].
  Future<void> startFromRunConfiguration({
    required RunConfiguration config,
    DapClient? clientOverride,
  }) async {
    final dart = ['dart', 'flutter'].contains(config.type);
    final language = switch (config.type) {
      'node' || 'pwa-node' || 'node-terminal' => 'javascript',
      'debugpy' => 'python',
      'coreclr' => 'csharp',
      'cargo' || 'lldb' => 'rust',
      _ => config.type,
    };

    final target = dart ? config.toDartDebugTarget() : null;
    final client =
        clientOverride ??
        (dart
            ? await DartDebugAdapter.spawnClient(
                target: target!,
                sdkPath: config.sdkPath,
              )
            : await MultiLanguageDebugAdapter.spawnClient(
                languageId: language,
                cwd: config.cwd,
              ));
    if (client == null) throw StateError('No DAP adapter for ${config.type}');
    await startSession(
      client: client,
      program: config.program,
      cwd: config.cwd,
      args: config.args,
      env: config.env,
      target: target,
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
      },
    );
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
    await stop();

    if (_disposed) {
      await client.close();
      return;
    }
    _activeTarget = target;
    _client = client;
    _activeSessionId = client.sessionId;
    _setState(DapSessionState.initializing);
    _consoleLogs.clear();

    _stoppedSub = client.stoppedEvents.listen(_handleStopped);
    _outputSub = client.outputEvents.listen(_handleOutput);
    final initialized = Completer<void>();
    _eventsSub = client.events.listen(
      (event) {
        if (_client != client) return;
        if (event.event == 'initialized' && !initialized.isCompleted) {
          initialized.complete();
        }
        if (event.event == 'continued') {
          _stackFrames = const [];
          _scopes = const [];
          _variables = const [];
          _setState(DapSessionState.running);
        }
        if (event.event == 'terminated' || event.event == 'exited') {
          unawaited(stop());
        }
      },
      onDone: () {
        if (_client == client) unawaited(stop());
      },
    );

    try {
      // 1. Initialize
      await client.initialize();

      final launch = client.sendRequest(request, {
        'program': program,
        'args': args,
        'cwd': ?cwd,
        'env': ?env,
        'noDebug': noDebug,
        ...launchArguments,
      });
      // Observe early failures while waiting for the initialized event.
      final ready = launch.then<void>((response) {
        if (!response.success) {
          throw StateError(response.message ?? 'DAP launch failed');
        }
        return initialized.future;
      });
      await Future.any([
        initialized.future,
        ready,
      ]).timeout(const Duration(seconds: 20));
      for (final entry in _breakpointsByPath.entries) {
        await client.setBreakpoints(
          sourcePath: entry.key,
          breakpoints: entry.value,
        );
      }
      if (client.capabilities.supportsConfigurationDoneRequest) {
        await client.configurationDone();
      }
      final response = await launch.timeout(const Duration(seconds: 30));
      if (!response.success) {
        throw StateError(response.message ?? 'DAP launch failed');
      }
      if (_client == client && _state == DapSessionState.initializing) {
        _setState(DapSessionState.running);
      }
    } catch (e) {
      _logConsole('[DAP Exceção]: $e');
      await stop();
    }
  }

  /// Adiciona ou remove um breakpoint no arquivo [path] e linha [line].
  Future<void> toggleBreakpoint(String path, int line) async {
    final list = _breakpointsByPath.putIfAbsent(path, () => []);
    final existingIndex = list.indexWhere((b) => b.line == line);

    if (existingIndex >= 0) {
      list.removeAt(existingIndex);
    } else {
      list.add(SourceBreakpoint(line: line));
    }

    if (list.isEmpty) {
      _breakpointsByPath.remove(path);
    }

    notifyListeners();

    // Sincroniza com o cliente ativo se houver sessão em execução
    final client = _client;
    if (client != null && isActive) {
      await client.setBreakpoints(
        sourcePath: path,
        breakpoints: _breakpointsByPath[path] ?? const [],
      );
    }
  }

  /// Pausa a execução da thread ativa.
  Future<void> pause() async {
    final client = _client;
    final tid = _activeThreadId ?? 1;
    if (client != null && isRunning) {
      await client.pause(tid);
    }
  }

  /// Retoma a execução (Continue / F5).
  Future<void> resume() async {
    final client = _client;
    final tid = _activeThreadId ?? 1;
    if (client != null && isStopped) {
      _setState(DapSessionState.running);
      _stackFrames = const [];
      _scopes = const [];
      _variables = const [];
      await client.resume(tid);
    }
  }

  /// Executa o próximo passo sobre funções (Next / Step Over / F10).
  Future<void> stepOver() async {
    final client = _client;
    final tid = _activeThreadId ?? 1;
    if (client != null && isStopped) {
      _setState(DapSessionState.running);
      await client.stepOver(tid);
    }
  }

  /// Entra na chamada de função (Step In / F11).
  Future<void> stepIn() async {
    final client = _client;
    final tid = _activeThreadId ?? 1;
    if (client != null && isStopped) {
      _setState(DapSessionState.running);
      await client.stepIn(tid);
    }
  }

  /// Sai da função atual (Step Out / Shift+F11).
  Future<void> stepOut() async {
    final client = _client;
    final tid = _activeThreadId ?? 1;
    if (client != null && isStopped) {
      _setState(DapSessionState.running);
      await client.stepOut(tid);
    }
  }

  /// Avalia uma expressão no contexto do frame selecionado.
  Future<String?> evaluate(String expression, {int? frameId}) async {
    final client = _client;
    if (client == null || !isStopped) return null;
    final targetFrame =
        frameId ?? (_stackFrames.isNotEmpty ? _stackFrames.first.id : null);
    final res = await client.evaluate(expression, frameId: targetFrame);
    return res?.result;
  }

  /// Seleciona um frame de pilha e carrega seus escopos e variáveis.
  Future<void> selectFrame(int frameId) async {
    final client = _client;
    if (client == null || !isStopped) return;

    _selectedFrameId = frameId;
    final scopesList = await client.scopes(frameId);
    if (_client != client || !isStopped || _selectedFrameId != frameId) return;
    _scopes = scopesList;

    if (scopesList.isNotEmpty) {
      final firstScope = scopesList.first;
      final values = await client.variables(firstScope.variablesReference);
      if (_client != client || !isStopped || _selectedFrameId != frameId) {
        return;
      }
      _variables = values;
    } else {
      _variables = const [];
    }
    notifyListeners();
  }

  /// Encerra a sessão ativa de depuração e limpa processos.
  Future<void> stop() async {
    if (_state == DapSessionState.idle ||
        _state == DapSessionState.terminating) {
      return;
    }
    _setState(DapSessionState.terminating);

    await _eventsSub?.cancel();
    _eventsSub = null;
    await _stoppedSub?.cancel();
    await _outputSub?.cancel();
    _stoppedSub = null;
    _outputSub = null;

    final client = _client;
    _client = null;
    _activeSessionId = '';

    if (client != null) {
      await client.disconnect();
    }

    _selectedFrameId = null;
    _activeThreadId = null;
    _lastStopReason = null;
    _activeTarget = null;
    _threads = const [];
    _stackFrames = const [];
    _scopes = const [];
    _variables = const [];
    _setState(DapSessionState.idle);
  }

  Future<void> _handleStopped(DapStoppedEvent event) async {
    // Rejeita eventos obsoletos
    if (_client?.sessionId != _activeSessionId) return;

    _lastStopReason = event.reason;
    _activeThreadId = event.threadId ?? 1;
    _setState(DapSessionState.stopped);

    final client = _client;
    if (client != null) {
      final thread = _activeThreadId!;
      final threads = await client.threads();
      if (_client != client || !isStopped) return;
      final frames = await client.stackTrace(thread);
      if (_client != client || !isStopped) return;
      _threads = threads;
      _stackFrames = frames;
      if (_stackFrames.isNotEmpty) {
        await selectFrame(_stackFrames.first.id);
      }
    }
  }

  void _handleOutput(DapOutputEvent event) {
    if (_client?.sessionId != _activeSessionId) return;
    _logConsole(event.output);
  }

  void _logConsole(String text) {
    final clean = text.trimRight();
    if (clean.isNotEmpty) {
      _consoleLogs.add(clean);
      notifyListeners();
    }
  }

  @override
  void notifyListeners() {
    if (!_disposed) super.notifyListeners();
  }

  void _setState(DapSessionState newState) {
    if (_state != newState) {
      _state = newState;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    unawaited(stop());
    super.dispose();
  }
}
