import 'dart:io';

import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_classifier.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_normalizer.dart';
import 'package:path/path.dart' as p;

/// Relatório de evidência inspecionada para uma invocação de processo de harness.
class HarnessEvidenceReport {
  /// Indica se a invocação corresponde a um harness catalogado oficialmente.
  final bool isKnownHarness;

  /// Indica se a invocação foi identificada como interativa (chat/TUI/REPL).
  final bool isInteractive;

  /// Indica se o processo foi lançado via wrapper/runtime (ex: node, npx, python, uvx).
  final bool isWrapperInvocation;

  /// Kind do harness identificado, ou null se não catalogado.
  final HarnessKind? kind;

  /// Especificação e metadados formais do harness identificado.
  final HarnessSpec? spec;

  /// Nome normalizado do ponto de entrada (ex: 'claude', 'agy', 'aider').
  final String? entryPoint;

  /// Argumentos limpos passados para o harness (sem flags do runtime intermediário).
  final List<String> effectiveArgs;

  /// Nível de confiança da evidência (1.0 = binário direto interativo, 0.85 = wrapper).
  final double confidence;

  /// Razão técnica ou diagnóstico da classificação.
  final String reason;

  const HarnessEvidenceReport({
    required this.isKnownHarness,
    required this.isInteractive,
    required this.isWrapperInvocation,
    this.kind,
    this.spec,
    this.entryPoint,
    this.effectiveArgs = const [],
    required this.confidence,
    required this.reason,
  });

  /// Relatório padrão para processos e comandos de shell não catalogados.
  static const HarnessEvidenceReport genericShell = HarnessEvidenceReport(
    isKnownHarness: false,
    isInteractive: false,
    isWrapperInvocation: false,
    confidence: 0.0,
    reason: 'Comando de terminal comum ou fornecedor de agente não catalogado.',
  );
}

/// Serviço de inspeção e validação de evidências de harness no host.
abstract class HarnessHostEvidence {
  /// Inspeciona executável e lista de argumentos gerando relatório objetivo de evidência.
  ///
  /// Fornecedores não reconhecidos são categorizados estritamente como contrato genérico
  /// de terminal, sem inventar parsers ou suposições de presença de agente.
  static HarnessEvidenceReport inspect({
    required String executable,
    required List<String> argv,
  }) {
    final normalized = TerminalHarnessNormalizer.normalize(
      executable: executable,
      argv: argv,
    );

    if (normalized == null) {
      return HarnessEvidenceReport.genericShell;
    }

    final spec = _findSpec(normalized.entryPointName);
    if (spec == null) {
      return HarnessEvidenceReport(
        isKnownHarness: false,
        isInteractive: false,
        isWrapperInvocation: _isWrapper(executable),
        entryPoint: normalized.entryPointName,
        effectiveArgs: normalized.harnessArgs,
        confidence: 0.0,
        reason:
            'Executável "${normalized.entryPointName}" não pertence ao catálogo oficial.',
      );
    }

    final isInteractive = TerminalHarnessClassifier.isInteractive(
      spec.kind,
      normalized.harnessArgs,
    );

    final isWrapper = _isWrapper(executable);
    final confidence = isInteractive ? (isWrapper ? 0.85 : 1.0) : 0.0;

    return HarnessEvidenceReport(
      isKnownHarness: true,
      isInteractive: isInteractive,
      isWrapperInvocation: isWrapper,
      kind: spec.kind,
      spec: spec,
      entryPoint: normalized.entryPointName,
      effectiveArgs: normalized.harnessArgs,
      confidence: confidence,
      reason: isInteractive
          ? (isWrapper
              ? 'Harness ${spec.label} detectado via wrapper com modo interativo.'
              : 'Harness ${spec.label} detectado via binário direto interativo.')
          : 'Harness ${spec.label} invocado em modo administrativo, batch ou não-interativo.',
    );
  }

  /// Verifica se um executável existe no host físico ou pode ser resolvido via PATH.
  static bool isExecutableAvailable(
    String executableName, {
    List<String>? extraSearchPaths,
  }) {
    // 1. Caminho absoluto ou relativo explícito
    if (executableName.contains('/') || executableName.contains('\\')) {
      final file = File(executableName);
      if (file.existsSync()) return true;
      if (Platform.isWindows) {
        if (File('$executableName.exe').existsSync() ||
            File('$executableName.cmd').existsSync() ||
            File('$executableName.bat').existsSync()) {
          return true;
        }
      }
      return false;
    }

    // 2. Procura em diretórios adicionais configurados
    if (extraSearchPaths != null) {
      for (final dir in extraSearchPaths) {
        final target = p.join(dir, executableName);
        if (File(target).existsSync()) return true;
        if (Platform.isWindows &&
            (File('$target.exe').existsSync() ||
                File('$target.cmd').existsSync() ||
                File('$target.bat').existsSync())) {
          return true;
        }
      }
    }

    // 3. Procura no PATH do sistema operacional
    final pathEnv = Platform.environment['PATH'];
    if (pathEnv != null) {
      final separator = Platform.isWindows ? ';' : ':';
      final parts = pathEnv.split(separator);
      for (final part in parts) {
        final target = p.join(part, executableName);
        if (File(target).existsSync()) return true;
        if (Platform.isWindows &&
            (File('$target.exe').existsSync() ||
                File('$target.cmd').existsSync() ||
                File('$target.bat').existsSync())) {
          return true;
        }
      }
    }

    return false;
  }

  static HarnessSpec? _findSpec(String entryPoint) {
    for (final spec in HarnessCatalog.specs.values) {
      if (spec.allEntryPoints.contains(entryPoint)) {
        return spec;
      }
    }
    return null;
  }

  static bool _isWrapper(String executable) {
    final base = p.basename(executable).toLowerCase();
    const wrappers = {
      'node',
      'bun',
      'deno',
      'python',
      'python3',
      'npx',
      'bunx',
      'uvx',
      'pipx',
      'pnpm',
      'yarn',
    };
    return wrappers.contains(p.basenameWithoutExtension(base));
  }
}
