import 'package:orkest_code/app/core/domain/entities/harness_signal.dart';
import 'package:orkest_code/app/core/domain/services/harness_state_coordinator.dart';
import 'package:path/path.dart' as p;

/// Tipo de ambiente de execução suportado pelo Orkest Code.
enum HarnessEnvironmentType {
  /// Execução local nativa na máquina host do cliente.
  local,

  /// Execução remota através de canal SSH autenticado.
  sshRemote,

  /// Execução dentro do subsistema Linux para Windows (WSL).
  wsl,
}

/// Contexto operacional e de transporte do ambiente de execução do terminal.
class HarnessEnvironmentContext {
  final HarnessEnvironmentType type;
  final String hostOrDistroId;
  final int generation;
  final bool isConnected;
  final String? workingDirectory;

  const HarnessEnvironmentContext({
    required this.type,
    required this.hostOrDistroId,
    this.generation = 0,
    this.isConnected = true,
    this.workingDirectory,
  });

  HarnessEnvironmentContext copyWith({
    HarnessEnvironmentType? type,
    String? hostOrDistroId,
    int? generation,
    bool? isConnected,
    String? workingDirectory,
  }) {
    return HarnessEnvironmentContext(
      type: type ?? this.type,
      hostOrDistroId: hostOrDistroId ?? this.hostOrDistroId,
      generation: generation ?? this.generation,
      isConnected: isConnected ?? this.isConnected,
      workingDirectory: workingDirectory ?? this.workingDirectory,
    );
  }
}

/// Serviço de paridade de estado e integridade de transporte entre Local, SSH e WSL (H04).
abstract class HarnessEnvironmentParity {
  /// Processa um sinal garantindo estrita paridade entre ambientes e proteção contra
  /// sinais defasados de conexões anteriores.
  static bool processSignal({
    required HarnessStateCoordinator coordinator,
    required HarnessEnvironmentContext context,
    required HarnessSignal signal,
  }) {
    // 1. Transporte desconectado: rejeita sinais de execução ou conclusão
    if (!context.isConnected) {
      return false;
    }

    // 2. Proteção de geração: descarta sinais de gerações antigas
    if (signal.generation < context.generation) {
      return false;
    }

    // 3. Processa no coordenador unificado
    return coordinator.processSignal(signal);
  }

  /// Trata a queda de conexão ou perda de transporte.
  ///
  /// Garante que a desconexão NUNCA seja apresentada como conclusão de turno
  /// ou como aprovação concedida.
  static HarnessStateSnapshot handleDisconnection({
    required HarnessStateCoordinator coordinator,
    required HarnessEnvironmentContext context,
    String reason = 'Transport disconnected',
  }) {
    // Desanexa imediatamente o harness e encerra fase ativa
    coordinator.detach();

    // Emite sinal explícito de fechamento de canal na geração atual
    coordinator.processSignal(
      HarnessSignal(
        source: HarnessSignalSource.structuredHook,
        phase: HarnessExecutionPhase.closed,
        timestamp: DateTime.now(),
        generation: context.generation,
        summary: reason,
      ),
    );

    return coordinator.snapshot;
  }

  /// Trata a reconexão do transporte (SSH ou WSL), avançando a geração e
  /// invalidando buffers residuais defasados.
  static HarnessEnvironmentContext handleReconnection({
    required HarnessStateCoordinator coordinator,
    required HarnessEnvironmentContext context,
    int? nextGeneration,
  }) {
    final newGen = nextGeneration ?? (context.generation + 1);
    coordinator.advanceGeneration(nextGeneration: newGen);

    return context.copyWith(
      generation: newGen,
      isConnected: true,
    );
  }

  /// Normaliza caminhos de sistema operacional de acordo com o ambiente de execução.
  static String normalizeEnvironmentPath({
    required String rawPath,
    required HarnessEnvironmentType type,
  }) {
    if (rawPath.isEmpty) return rawPath;

    switch (type) {
      case HarnessEnvironmentType.local:
        return p.normalize(rawPath);

      case HarnessEnvironmentType.wsl:
        // Converte drive Windows 'C:\...' para '/mnt/c/...' caso necessário
        if (RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(rawPath)) {
          final drive = rawPath[0].toLowerCase();
          final remainder = rawPath.substring(2).replaceAll('\\', '/');
          return p.posix.normalize('/mnt/$drive$remainder');
        }
        return p.posix.normalize(rawPath.replaceAll('\\', '/'));

      case HarnessEnvironmentType.sshRemote:
        // Preserva estritamente a raiz POSIX do host remoto sem contaminação local
        return p.posix.normalize(rawPath.replaceAll('\\', '/'));
    }
  }
}
