import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'debug_failure.dart';

import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/domain/entities/multi_language_debug_adapter.dart';

/// Status de conformidade operacional do adaptador DAP no ambiente (R04).
enum DebugAdapterStatus {
  /// Adaptador instalado e binário disponível no sistema.
  available,

  /// Adaptador suportado pelo catálogo, mas o executável não foi encontrado no PATH.
  missingExecutable,

  /// Linguagem ou runtime não possui adaptador DAP catalogado.
  unsupported,
}

/// Relatório de auditoria de conformidade de um adaptador de depuração (R04).
class DebugAdapterAuditReport {
  const DebugAdapterAuditReport({
    required this.adapterId,
    required this.name,
    required this.status,
    required this.license,
    required this.installHint,
    required this.capabilities,
    required this.executableCommand,
    required this.limitations,
  });

  final String adapterId;
  final String name;
  final DebugAdapterStatus status;
  final String license;
  final String installHint;
  final DebugAdapterCapabilities? capabilities;
  final String executableCommand;
  final List<String> limitations;

  Map<String, dynamic> toJson() => {
    'adapter_id': adapterId,
    'name': name,
    'status': status.name,
    'license': license,
    'install_hint': installHint,
    'capabilities': capabilities?.toJson(),
    'executable_command': executableCommand,
    'limitations': limitations,
  };

  @override
  String toString() =>
      'DebugAdapterAuditReport($adapterId: status=${status.name}, license=$license, '
      'limitations=${limitations.length})';
}

/// Orquestrador unificado para lançamento e configuração de adaptadores DAP multilinguagem (R04).
class MultiLanguageDebugAdapter {
  const MultiLanguageDebugAdapter._();

  /// Resolve a tupla `(executable, args)` para inicializar o adaptador DAP da linguagem.
  static (String executable, List<String> args)? resolveAdapterCommand({
    required String languageId,
    String? customExecutable,
    List<String>? customArgs,
  }) {
    final adapter = MultiLanguageDebugRegistry.adapterForLanguage(languageId);
    if (adapter == null) return null;

    final executable = customExecutable != null && customExecutable.isNotEmpty
        ? customExecutable
        : adapter.defaultExecutable;

    final args = customArgs ?? adapter.defaultArgs;
    return (executable, args);
  }

  /// Gera os argumentos formatados para o request `launch` do DAP de acordo com a linguagem.
  static Map<String, dynamic> buildLaunchArgs({
    required String languageId,
    required String program,
    required String cwd,
    List<String>? args,
    Map<String, dynamic>? extraArgs,
    bool noDebug = false,
  }) {
    final adapter = MultiLanguageDebugRegistry.adapterForLanguage(languageId);

    final baseConfig = <String, dynamic>{
      'noDebug': noDebug,
      'program': program,
      'cwd': cwd,
      if (args != null && args.isNotEmpty) 'args': args,
    };

    if (adapter != null) {
      // Mescla com as chaves específicas do template do adaptador
      for (final entry in adapter.sampleLaunchConfig.entries) {
        if (entry.key != 'program' &&
            entry.key != 'cwd' &&
            entry.key != 'noDebug') {
          baseConfig[entry.key] = entry.value;
        }
      }
    }

    if (extraArgs != null) {
      baseConfig.addAll(extraArgs);
    }

    return baseConfig;
  }

  /// Audita a disponibilidade, capacidades e limites documentados do adaptador.
  static DebugAdapterAuditReport auditAdapter({
    required String adapterId,
    bool isExecutableAvailable = true,
  }) {
    final adapter = MultiLanguageDebugRegistry.adapterById(adapterId);
    if (adapter == null) {
      return DebugAdapterAuditReport(
        adapterId: adapterId,
        name: 'Unknown Adapter',
        status: DebugAdapterStatus.unsupported,
        license: 'Unknown',
        installHint: 'Nenhum adaptador registrado para este identificador.',
        capabilities: null,
        executableCommand: '',
        limitations: const ['Adaptador não catalogado no ecossistema.'],
      );
    }

    final limitations = <String>[];
    if (!adapter.capabilities.supportsRestartFrame) {
      limitations.add(
        'Restart Frame (drop to frame) não suportado pelo runtime.',
      );
    }
    if (!adapter.capabilities.supportsSmartStep) {
      limitations.add('Smart Step não disponível para este runtime.');
    }
    if (!adapter.capabilities.supportsHotSwap) {
      limitations.add(
        'HotSwap / Hot Reload de código em execução indisponível.',
      );
    }
    if (!adapter.capabilities.supportsWatchpoints) {
      limitations.add('Data Watchpoints de hardware/variável não suportados.');
    }

    final fullCmd = [
      adapter.defaultExecutable,
      ...adapter.defaultArgs,
    ].join(' ');

    return DebugAdapterAuditReport(
      adapterId: adapter.adapterId,
      name: adapter.name,
      status: isExecutableAvailable
          ? DebugAdapterStatus.available
          : DebugAdapterStatus.missingExecutable,
      license: adapter.license,
      installHint: adapter.installHint,
      capabilities: adapter.capabilities,
      executableCommand: fullCmd,
      limitations: List.unmodifiable(limitations),
    );
  }

  /// Starts a real DAP transport. Runtime inspector protocols are not DAP.
  static Future<DapClient?> spawnClient({
    required String languageId,
    required String cwd,
    String? customExecutable,
    List<String>? customArgs,
    String? sessionId,
    Map<String, dynamic> configuration = const {},
  }) async {
    final id =
        sessionId ?? '$languageId-${DateTime.now().microsecondsSinceEpoch}';
    final server = configuration['debugServer'];
    if (server != null && (server is! int || server <= 0 || server > 65535)) {
      throw const DebugFailure(DebugFailureKind.configuration, 'debugServer');
    }
    if (server is int && server > 0 && server <= 65535) {
      return DapClient.connectSocket(
        host: '127.0.0.1',
        port: server,
        sessionId: id,
      );
    }
    final raw = configuration['adapter'];
    final adapter = raw is Map
        ? raw.cast<String, dynamic>()
        : <String, dynamic>{};
    if (adapter['command'] != null && adapter['command'] is! String) {
      throw const DebugFailure(
        DebugFailureKind.configuration,
        'adapter.command',
      );
    }
    if (adapter['args'] != null &&
        (adapter['args'] is! List ||
            !(adapter['args'] as List).every((arg) => arg is String))) {
      throw const DebugFailure(DebugFailureKind.configuration, 'adapter.args');
    }
    if (adapter['transport'] != null &&
        !['stdio', 'tcp'].contains(adapter['transport'])) {
      throw const DebugFailure(
        DebugFailureKind.configuration,
        'adapter.transport',
      );
    }
    final configuredCommand = adapter['command'];
    customExecutable ??= configuredCommand is String ? configuredCommand : null;
    if (adapter['args'] is List) {
      customArgs ??= (adapter['args'] as List).cast<String>();
    }
    final python = configuration['python'] ?? configuration['pythonPath'];
    if (languageId == 'python' &&
        customExecutable == null &&
        python is String &&
        python.isNotEmpty) {
      customExecutable = python;
    }
    final resolved = resolveAdapterCommand(
      languageId: languageId,
      customExecutable: customExecutable,
      customArgs: customArgs,
    );
    if (resolved == null && customExecutable == null) return null;
    final executable = customExecutable ?? resolved!.$1;
    final baseArgs = customArgs ?? resolved?.$2 ?? const <String>[];
    final tcp =
        adapter['transport'] == 'tcp' ||
        (adapter['transport'] != 'stdio' &&
            [
              'javascript',
              'typescript',
              'go',
              'rust',
              'c',
              'cpp',
            ].contains(languageId));
    if (languageId == 'java' && customExecutable == null) {
      throw const DebugFailure(
        DebugFailureKind.adapter,
        'Java: configure adapter.command or debugServer from the language server DAP endpoint',
      );
    }
    try {
      if (!tcp) {
        return await DapClient.startProcess(
          executable: executable,
          args: baseArgs,
          workingDirectory: cwd,
          sessionId: id,
        );
      }
      final reservation = await ServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      final port = reservation.port;
      await reservation.close();
      final args = [
        for (final arg in baseArgs) arg.replaceAll(r'${port}', '$port'),
      ];
      if (!baseArgs.any((arg) => arg.contains(r'${port}'))) {
        switch (languageId) {
          case 'go':
            args.add('--listen=127.0.0.1:$port');
          case 'rust' || 'c' || 'cpp':
            args.addAll(['--port', '$port']);
          default:
            args.add('$port');
        }
      }
      final process = await Process.start(
        executable,
        args,
        workingDirectory: cwd,
        runInShell: Platform.isWindows,
      );
      final diagnostics = process.stderr
          .transform(utf8.decoder)
          .asBroadcastStream();
      final detail = StringBuffer();
      final stderr = diagnostics.listen((line) {
        if (detail.length < 8192) detail.write(line);
      });
      final stdout = process.stdout.listen((_) {});
      int? exited;
      unawaited(process.exitCode.then((value) => exited = value));
      final deadline = DateTime.now().add(const Duration(seconds: 8));
      try {
        while (DateTime.now().isBefore(deadline) && exited == null) {
          try {
            final client = await DapClient.connectSocket(
              host: '127.0.0.1',
              port: port,
              process: process,
              sessionId: id,
              diagnostics: diagnostics,
            );
            await stderr.cancel();
            // Server stdout is diagnostic, never DAP. Drain until process exit.
            unawaited(process.exitCode.then((_) => stdout.cancel()));
            return client;
          } on SocketException {
            await Future<void>.delayed(const Duration(milliseconds: 80));
          }
        }
        throw DebugFailure(
          DebugFailureKind.transport,
          '$executable: ${detail.toString()} (exit: $exited, port: $port)',
        );
      } on Object {
        process.kill();
        await stderr.cancel();
        await stdout.cancel();
        rethrow;
      }
    } on ProcessException catch (error) {
      throw DebugFailure(
        DebugFailureKind.adapter,
        '$executable: ${error.message}',
      );
    }
  }
}
