import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/orkest/domain/services/log_sanitizer.dart';

/// Estados do ciclo de vida de um serviço nativo supervisionado (A05).
enum NativeServiceState {
  unstarted,
  starting,
  running,
  stopping,
  stopped,
  degraded,
}

/// Exceção lançada quando o handshake de protocolo entre o cliente e o serviço falha.
class IncompatibleProtocolException implements Exception {
  const IncompatibleProtocolException(this.serviceName, this.expectedVersion, this.actualVersion);

  final String serviceName;
  final int expectedVersion;
  final int actualVersion;

  @override
  String toString() =>
      'IncompatibleProtocolException: service "$serviceName" protocol mismatch. Expected: $expectedVersion, received: $actualVersion.';
}

/// Exceção lançada quando um serviço entra em loop de quedas sucessivas.
class NativeServiceCrashLoopException implements Exception {
  const NativeServiceCrashLoopException(this.serviceName, this.crashCount);

  final String serviceName;
  final int crashCount;

  @override
  String toString() =>
      'NativeServiceCrashLoopException: service "$serviceName" crashed $crashCount times within the crash window.';
}

/// Configuração de inicialização e tolerância a falhas do serviço nativo.
class NativeServiceConfig {
  const NativeServiceConfig({
    required this.serviceName,
    required this.binaryPath,
    this.args = const [],
    this.expectedProtocolVersion,
    this.maxCrashesInWindow = 3,
    this.crashWindow = const Duration(seconds: 30),
    this.killTimeout = const Duration(seconds: 2),
    this.fallbackBinaryPath,
  });

  final String serviceName;
  final String binaryPath;
  final List<String> args;
  final int? expectedProtocolVersion;
  final int maxCrashesInWindow;
  final Duration crashWindow;
  final Duration killTimeout;
  final String? fallbackBinaryPath;

  NativeServiceConfig copyWith({
    String? serviceName,
    String? binaryPath,
    List<String>? args,
    int? expectedProtocolVersion,
    int? maxCrashesInWindow,
    Duration? crashWindow,
    Duration? killTimeout,
    String? fallbackBinaryPath,
    bool clearFallback = false,
  }) {
    return NativeServiceConfig(
      serviceName: serviceName ?? this.serviceName,
      binaryPath: binaryPath ?? this.binaryPath,
      args: args ?? this.args,
      expectedProtocolVersion: expectedProtocolVersion ?? this.expectedProtocolVersion,
      maxCrashesInWindow: maxCrashesInWindow ?? this.maxCrashesInWindow,
      crashWindow: crashWindow ?? this.crashWindow,
      killTimeout: killTimeout ?? this.killTimeout,
      fallbackBinaryPath: clearFallback ? null : (fallbackBinaryPath ?? this.fallbackBinaryPath),
    );
  }
}

/// Supervisor de processos e serviços nativos auxiliares (A05).
class NativeServiceSupervisor {
  NativeServiceSupervisor({
    required this.config,
    LogSanitizer? sanitizer,
    Future<Process> Function(String executable, List<String> arguments)? processStarter,
  })  : _sanitizer = sanitizer ?? const LogSanitizer(),
        _processStarter = processStarter ?? Process.start;

  NativeServiceConfig config;
  final LogSanitizer _sanitizer;
  final Future<Process> Function(String executable, List<String> arguments) _processStarter;

  Process? _process;
  NativeServiceState _state = NativeServiceState.unstarted;
  final List<DateTime> _recentCrashes = [];
  final List<String> _sanitizedLogs = [];
  bool _intentionalStop = false;

  NativeServiceState get state => _state;
  int? get pid => _process?.pid;
  List<String> get sanitizedLogs => List.unmodifiable(_sanitizedLogs);

  /// Inicia o serviço nativo com monitoramento de ciclo de vida.
  Future<void> start() async {
    if (_state == NativeServiceState.running || _state == NativeServiceState.starting) {
      return;
    }

    _state = NativeServiceState.starting;
    _intentionalStop = false;

    try {
      final proc = await _processStarter(config.binaryPath, config.args);
      _process = proc;
      _state = NativeServiceState.running;

      // Monitoramento de stdout e stderr com sanitização
      proc.stdout.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        final sanitized = _sanitizer.sanitize(line);
        _recordLog('[OUT] $sanitized');
      });

      proc.stderr.transform(utf8.decoder).transform(const LineSplitter()).listen((line) {
        final sanitized = _sanitizer.sanitize(line);
        _recordLog('[ERR] $sanitized');
      });

      // Monitoramento de saída do processo
      proc.exitCode.then(_onProcessExited);
    } catch (e) {
      _state = NativeServiceState.degraded;
      _recordLog('[START_ERROR] ${_sanitizer.sanitize(e.toString())}');
      rethrow;
    }
  }

  /// Executa handshake inicial com verificação de compatibilidade de protocolo.
  Future<void> performHandshake(Future<int> Function(Process process) probeProtocolVersion) async {
    final proc = _process;
    if (proc == null || _state != NativeServiceState.running) {
      throw StateError('Service "${config.serviceName}" is not running.');
    }

    final expected = config.expectedProtocolVersion;
    if (expected == null) return;

    final actual = await probeProtocolVersion(proc);
    if (actual != expected) {
      await stop();
      throw IncompatibleProtocolException(config.serviceName, expected, actual);
    }
  }

  /// Interrompe o processo garantindo encerramento de filhos (SIGTERM seguido de SIGKILL se necessário).
  Future<void> stop() async {
    final proc = _process;
    if (proc == null || _state == NativeServiceState.stopped) {
      _state = NativeServiceState.stopped;
      return;
    }

    _intentionalStop = true;
    _state = NativeServiceState.stopping;

    proc.kill(ProcessSignal.sigterm);

    var exited = false;
    final exitWatcher = proc.exitCode.then((_) => exited = true);

    await Future.any([
      exitWatcher,
      Future.delayed(config.killTimeout),
    ]);

    if (!exited) {
      proc.kill(ProcessSignal.sigkill);
      await proc.exitCode;
    }

    _process = null;
    _state = NativeServiceState.stopped;
  }

  /// Reinicia o serviço supervisionado.
  Future<void> restart() async {
    await stop();
    await start();
  }

  /// Reverte para o binário anterior (rollback) e reinicia o serviço.
  Future<bool> rollback() async {
    final fallback = config.fallbackBinaryPath;
    if (fallback == null || fallback.isEmpty) {
      return false;
    }

    await stop();
    config = config.copyWith(
      binaryPath: fallback,
      clearFallback: true,
    );
    await start();
    return true;
  }

  void _onProcessExited(int exitCode) {
    if (_intentionalStop) {
      _state = NativeServiceState.stopped;
      _process = null;
      return;
    }

    // Processo caiu inesperadamente
    _recordLog('[CRASH] Process exited unexpectedly with code $exitCode');
    _process = null;

    final now = DateTime.now();
    _recentCrashes.add(now);

    // Remove quedas fora da janela
    _recentCrashes.removeWhere((ts) => now.difference(ts) > config.crashWindow);

    if (_recentCrashes.length >= config.maxCrashesInWindow) {
      _state = NativeServiceState.degraded;
      _recordLog('[CRASH_LOOP] Max crashes exceeded. Marking service as degraded.');
    } else {
      _state = NativeServiceState.stopped;
      // Reinicia com auto-restart
      start();
    }
  }

  void _recordLog(String entry) {
    _sanitizedLogs.add(entry);
    if (_sanitizedLogs.length > 200) {
      _sanitizedLogs.removeAt(0);
    }
  }

  /// Descarte com liberação obrigatória de processos filhos.
  Future<void> dispose() async {
    await stop();
  }
}
