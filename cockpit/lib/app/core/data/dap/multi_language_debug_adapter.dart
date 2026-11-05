import 'dart:io';

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
        if (entry.key != 'program' && entry.key != 'cwd' && entry.key != 'noDebug') {
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
      limitations.add('Restart Frame (drop to frame) não suportado pelo runtime.');
    }
    if (!adapter.capabilities.supportsSmartStep) {
      limitations.add('Smart Step não disponível para este runtime.');
    }
    if (!adapter.capabilities.supportsHotSwap) {
      limitations.add('HotSwap / Hot Reload de código em execução indisponível.');
    }
    if (!adapter.capabilities.supportsWatchpoints) {
      limitations.add('Data Watchpoints de hardware/variável não suportados.');
    }

    final fullCmd = [adapter.defaultExecutable, ...adapter.defaultArgs].join(' ');

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

  /// Inicia o processo do adaptador DAP multilinguagem e retorna o cliente conectado.
  static Future<DapClient?> spawnClient({
    required String languageId,
    required String cwd,
    String? customExecutable,
    List<String>? customArgs,
    String? sessionId,
  }) async {
    final resolved = resolveAdapterCommand(
      languageId: languageId,
      customExecutable: customExecutable,
      customArgs: customArgs,
    );
    if (resolved == null) return null;

    final (executable, args) = resolved;

    final process = await Process.start(
      executable,
      args,
      workingDirectory: cwd,
      runInShell: Platform.isWindows,
    );

    return DapClient.fromProcess(
      process: process,
      sessionId: sessionId ?? '$languageId-debug-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
