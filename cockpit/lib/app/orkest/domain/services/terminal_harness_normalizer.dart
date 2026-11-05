import 'package:path/path.dart' as p;

class NormalizedHarnessInvocation {
  final String entryPointName;
  final List<String> harnessArgs;

  const NormalizedHarnessInvocation({
    required this.entryPointName,
    required this.harnessArgs,
  });
}

abstract class TerminalHarnessNormalizer {
  static const Set<String> _knownRuntimes = {
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

  static const Map<String, String> _scriptPackageAlias = {
    'pi-coding-agent': 'pi',
    'claude-code': 'claude',
    'cursor-agent': 'cursor-agent',
    'gemini-cli': 'gemini',
    '@google/gemini-cli': 'gemini',
    'aider-chat': 'aider',
    'kimi-cli': 'kimi',
  };

  /// Normalizes an executable path and process argument list into a candidate
  /// entry point name and harness arguments.
  static NormalizedHarnessInvocation? normalize({
    required String executable,
    required List<String> argv,
  }) {
    final execBase = _cleanBinaryName(executable);
    if (execBase.isEmpty) return null;

    final args = argv.length > 1 ? argv.sublist(1) : <String>[];

    if (_knownRuntimes.contains(execBase)) {
      return _normalizeRuntime(execBase, args);
    }

    return NormalizedHarnessInvocation(
      entryPointName: execBase,
      harnessArgs: args,
    );
  }

  static String _cleanBinaryName(String pathOrName) {
    var name = p.basename(pathOrName).toLowerCase();
    if (name.endsWith('.exe') ||
        name.endsWith('.cmd') ||
        name.endsWith('.bat')) {
      name = p.basenameWithoutExtension(name);
    }
    return name;
  }

  static NormalizedHarnessInvocation? _normalizeRuntime(
    String runtime,
    List<String> args,
  ) {
    // 1. Trata 'python -m <module>'
    if (runtime == 'python' || runtime == 'python3') {
      final mIdx = args.indexOf('-m');
      if (mIdx != -1 && mIdx + 1 < args.length) {
        final moduleName = args[mIdx + 1].toLowerCase();
        final targetEntry = _scriptPackageAlias[moduleName] ?? moduleName;
        final remainingArgs = args.sublist(mIdx + 2);
        return NormalizedHarnessInvocation(
          entryPointName: targetEntry,
          harnessArgs: remainingArgs,
        );
      }
    }

    int scriptIdx = -1;
    for (int i = 0; i < args.length; i++) {
      final arg = args[i];
      if (arg.startsWith('-')) {
        // Skip flags to runtime e.g. --max-old-space-size=4096 or -y in npx
        continue;
      }
      scriptIdx = i;
      break;
    }

    if (scriptIdx == -1) return null;

    final scriptPath = args[scriptIdx];
    final harnessArgs = args.sublist(scriptIdx + 1);

    var scriptBase = p.basename(scriptPath).toLowerCase();
    if (scriptBase.endsWith('.js') ||
        scriptBase.endsWith('.py') ||
        scriptBase.endsWith('.ts')) {
      scriptBase = p.basenameWithoutExtension(scriptBase);
    }

    // Verifica se scriptBase é genérico (cli, index, main) ou já é o pacote
    for (final entry in _scriptPackageAlias.entries) {
      if (scriptBase == entry.key || scriptBase == p.basename(entry.key)) {
        return NormalizedHarnessInvocation(
          entryPointName: entry.value,
          harnessArgs: harnessArgs,
        );
      }
    }

    if (scriptBase == 'cli' || scriptBase == 'index' || scriptBase == 'main') {
      // Check package directory in path
      final normalizedPath = p.normalize(scriptPath).toLowerCase();
      for (final entry in _scriptPackageAlias.entries) {
        if (normalizedPath.contains(entry.key)) {
          return NormalizedHarnessInvocation(
            entryPointName: entry.value,
            harnessArgs: harnessArgs,
          );
        }
      }
    }

    return NormalizedHarnessInvocation(
      entryPointName: scriptBase,
      harnessArgs: harnessArgs,
    );
  }
}
