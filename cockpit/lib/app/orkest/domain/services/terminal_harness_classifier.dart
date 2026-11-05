import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_normalizer.dart';

abstract class TerminalHarnessClassifier {
  /// Classifies a process invocation as a supported interactive harness,
  /// or returns null if it is non-interactive, administrative, or unknown.
  static HarnessKind? classify({
    required String executable,
    required List<String> argv,
  }) {
    final normalized = TerminalHarnessNormalizer.normalize(
      executable: executable,
      argv: argv,
    );
    if (normalized == null) return null;

    final spec = _findMatchingSpec(normalized.entryPointName);
    if (spec == null) return null;

    final isInter = isInteractive(
      spec.kind,
      normalized.harnessArgs,
    );
    return isInter ? spec.kind : null;
  }

  static HarnessSpec? _findMatchingSpec(String entryPoint) {
    for (final spec in HarnessCatalog.specs.values) {
      if (spec.allEntryPoints.contains(entryPoint)) {
        return spec;
      }
    }
    return null;
  }

  /// Verifica se uma lista de argumentos para determinado harness configura modo interativo.
  static bool isInteractive(HarnessKind kind, List<String> args) {
    // 1. Universal admin/help/version flags
    for (final arg in args) {
      if (arg == '-h' ||
          arg == '--help' ||
          arg == '-v' ||
          arg == '--version' ||
          arg == '-V') {
        return false;
      }
    }

    final spec = HarnessCatalog.specs[kind];
    if (spec != null) {
      // 2. Flags não-interativas registradas na especificação do harness
      for (final arg in args) {
        if (spec.nonInteractiveFlags.contains(arg)) {
          return false;
        }
      }

      // 3. Subcomandos administrativos no primeiro argumento posicional
      if (args.isNotEmpty) {
        final firstArg = args[0].toLowerCase();
        if (spec.adminSubcommands.contains(firstArg)) {
          return false;
        }
      }
    }

    // 4. Regras especializadas por harness
    switch (kind) {
      case HarnessKind.antigravity:
        return _checkAntigravity(args);
      case HarnessKind.claudeCode:
        return _checkClaudeCode(args);
      case HarnessKind.codex:
        return _checkCodex(args);
      case HarnessKind.cursor:
        return _checkCursor(args);
      case HarnessKind.gitHubCopilot:
        return _checkGitHubCopilot(args);
      case HarnessKind.openCode:
        return _checkOpenCode(args);
      case HarnessKind.pi:
        return _checkPi(args);
      case HarnessKind.gemini:
        return _checkGemini(args);
      case HarnessKind.kimi:
        return _checkKimi(args);
      case HarnessKind.aider:
        return _checkAider(args);
      case HarnessKind.ollama:
        return _checkOllama(args);
    }
  }

  static bool _checkAntigravity(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-p' || arg == '--print') return false;
    }
    return true;
  }

  static bool _checkClaudeCode(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-p' || arg == '--print') return false;
    }
    return true;
  }

  static bool _checkCodex(List<String> args) {
    return true;
  }

  static bool _checkCursor(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-p' || arg == '--print') return false;
    }
    return true;
  }

  static bool _checkGitHubCopilot(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-p' || arg == '--prompt' || arg == '-i' || arg == '--input') {
        return false;
      }
    }
    return true;
  }

  static bool _checkOpenCode(List<String> args) {
    return true;
  }

  static bool _checkPi(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-p' || arg == '--print') return false;
      if (arg.startsWith('--mode=')) {
        final modeVal = arg.substring('--mode='.length).toLowerCase();
        if (modeVal == 'text' || modeVal == 'json' || modeVal == 'rpc') {
          return false;
        }
      }
      if (arg == '--mode' && i + 1 < args.length) {
        final modeVal = args[i + 1].toLowerCase();
        if (modeVal == 'text' || modeVal == 'json' || modeVal == 'rpc') {
          return false;
        }
      }
    }
    return true;
  }

  static bool _checkGemini(List<String> args) {
    for (final arg in args) {
      if (arg == '-p' || arg == '--prompt' || arg == '-q' || arg == '--quiet') {
        return false;
      }
    }
    return true;
  }

  static bool _checkKimi(List<String> args) {
    for (final arg in args) {
      if (arg == '-p' || arg == '--print' || arg == '-q' || arg == '--quiet') {
        return false;
      }
    }
    return true;
  }

  static bool _checkAider(List<String> args) {
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg == '-m' ||
          arg == '--message' ||
          arg.startsWith('--message=') ||
          arg == '--no-git' ||
          arg == '--exit') {
        return false;
      }
    }
    return true;
  }

  static bool _checkOllama(List<String> args) {
    // Ollama só entra em modo interativo de chat se invocado com subcomando `run <model>`
    if (args.isEmpty) return false;
    final first = args[0].toLowerCase();
    if (first != 'run') return false;
    // Precisa ter pelo menos o modelo especificado: `ollama run <model>`
    return args.length >= 2;
  }
}
