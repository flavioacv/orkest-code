/// Capacidades formais de execução e inspeção suportadas por um adaptador DAP (R04).
class DebugAdapterCapabilities {
  const DebugAdapterCapabilities({
    required this.supportsRestartFrame,
    required this.supportsSmartStep,
    required this.supportsHotSwap,
    required this.supportsWatchpoints,
    this.supportsConditionalBreakpoints = true,
    this.supportsHitConditionalBreakpoints = true,
    this.supportsLogPoints = true,
    this.supportsEvaluateForHovers = true,
  });

  /// Suporte a retornar o ponteiro de execução para um frame anterior na pilha (drop to frame).
  final bool supportsRestartFrame;

  /// Suporte a pular chamadas e closures não essenciais no avanço passo a passo.
  final bool supportsSmartStep;

  /// Suporte a recarga dinâmica de código em tempo de execução sem reiniciar o processo
  /// (Hot Reload no Flutter/Dart, HotSwap na JVM, V8 code reload no Node.js).
  final bool supportsHotSwap;

  /// Suporte a pontos de parada de monitoramento de alteração ou leitura de memória/variável
  /// (Hardware data watchpoints via LLDB ou GDB).
  final bool supportsWatchpoints;

  /// Suporte a breakpoints com expressão condicional.
  final bool supportsConditionalBreakpoints;

  /// Suporte a breakpoints disparados após N acertos.
  final bool supportsHitConditionalBreakpoints;

  /// Suporte a logpoints (mensagens no console sem interromper o processo).
  final bool supportsLogPoints;

  /// Suporte a avaliação rápida de expressões no hover do editor.
  final bool supportsEvaluateForHovers;

  Map<String, dynamic> toJson() => {
        'supports_restart_frame': supportsRestartFrame,
        'supports_smart_step': supportsSmartStep,
        'supports_hot_swap': supportsHotSwap,
        'supports_watchpoints': supportsWatchpoints,
        'supports_conditional_breakpoints': supportsConditionalBreakpoints,
        'supports_hit_conditional_breakpoints': supportsHitConditionalBreakpoints,
        'supports_log_points': supportsLogPoints,
        'supports_evaluate_for_hovers': supportsEvaluateForHovers,
      };
}

/// Definição declarativa de um adaptador de depuração DAP suportado (R04).
class DebugAdapterDefinition {
  const DebugAdapterDefinition({
    required this.adapterId,
    required this.name,
    required this.defaultExecutable,
    required this.defaultArgs,
    required this.supportedLanguages,
    required this.license,
    required this.installHint,
    required this.capabilities,
    required this.sampleLaunchConfig,
  });

  /// Identificador estável do adaptador DAP.
  final String adapterId;

  /// Nome legível do adaptador.
  final String name;

  /// Executável padrão utilizado para spawnar o servidor DAP via stdio.
  final String defaultExecutable;

  /// Argumentos padrão de inicialização do servidor DAP.
  final List<String> defaultArgs;

  /// Lista de linguagens que utilizam este adaptador.
  final List<String> supportedLanguages;

  /// Licença do software do adaptador (MIT, GPL-2.0, EPL-1.0, etc.).
  final String license;

  /// Instrução textual recomendada para instalação do adaptador.
  final String installHint;

  /// Matriz de capacidades suportadas.
  final DebugAdapterCapabilities capabilities;

  /// Exemplo de configuração `launch` JSON para este adaptador.
  final Map<String, dynamic> sampleLaunchConfig;

  Map<String, dynamic> toJson() => {
        'adapter_id': adapterId,
        'name': name,
        'default_executable': defaultExecutable,
        'default_args': defaultArgs,
        'supported_languages': supportedLanguages,
        'license': license,
        'install_hint': installHint,
        'capabilities': capabilities.toJson(),
        'sample_launch_config': sampleLaunchConfig,
      };

  @override
  String toString() => 'DebugAdapterDefinition($adapterId: $name [$license])';
}

/// Catálogo global de adaptadores de depuração multilinguagem do Orkest Code (R04).
class MultiLanguageDebugRegistry {
  const MultiLanguageDebugRegistry._();

  /// Catálogo formal de adaptadores cobrindo Dart/Flutter, TS/JS, Python, Rust, Go, Java e .NET.
  static const List<DebugAdapterDefinition> allAdapters = [
    // 1. Dart & Flutter SDK
    DebugAdapterDefinition(
      adapterId: 'dart',
      name: 'Dart & Flutter Debug Adapter',
      defaultExecutable: 'dart',
      defaultArgs: ['debug_adapter'],
      supportedLanguages: ['dart'],
      license: 'BSD-3-Clause',
      installHint: 'Embarcado nativamente no Dart/Flutter SDK.',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: true,
        supportsSmartStep: true,
        supportsHotSwap: true, // Hot Reload & Hot Restart
        supportsWatchpoints: false,
      ),
      sampleLaunchConfig: {
        'type': 'dart',
        'request': 'launch',
        'program': 'lib/main.dart',
        'cwd': r'${workspaceFolder}',
      },
    ),

    // 2. TypeScript & JavaScript (js-debug / Node)
    DebugAdapterDefinition(
      adapterId: 'pwa-node',
      name: 'Node.js / TypeScript Debug Adapter (js-debug)',
      defaultExecutable: 'node',
      defaultArgs: ['--inspect-brk'],
      supportedLanguages: ['typescript', 'javascript'],
      license: 'MIT',
      installHint: 'Instalar via npm: npm install -g @vscode/js-debug',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: true,
        supportsSmartStep: true,
        supportsHotSwap: true, // V8 Hot code replacement
        supportsWatchpoints: false,
      ),
      sampleLaunchConfig: {
        'type': 'pwa-node',
        'request': 'launch',
        'program': 'src/index.ts',
        'cwd': r'${workspaceFolder}',
        'runtimeArgs': ['-r', 'ts-node/register'],
      },
    ),

    // 3. Python (debugpy)
    DebugAdapterDefinition(
      adapterId: 'debugpy',
      name: 'Python Debug Adapter (debugpy)',
      defaultExecutable: 'python3',
      defaultArgs: ['-m', 'debugpy.adapter'],
      supportedLanguages: ['python'],
      license: 'MIT',
      installHint: 'Instalar via pip: pip install debugpy',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: false, // Python stack frame unwinding restrito
        supportsSmartStep: false,
        supportsHotSwap: false,
        supportsWatchpoints: false,
      ),
      sampleLaunchConfig: {
        'type': 'debugpy',
        'request': 'launch',
        'program': 'main.py',
        'cwd': r'${workspaceFolder}',
      },
    ),

    // 4. Rust, C & C++ (codelldb)
    DebugAdapterDefinition(
      adapterId: 'lldb',
      name: 'CodeLLDB / Native LLVM Debug Adapter',
      defaultExecutable: 'codelldb',
      defaultArgs: [],
      supportedLanguages: ['rust', 'c', 'cpp'],
      license: 'GPL-2.0',
      installHint: 'Baixar binário oficial CodeLLDB no GitHub ou via gerenciador de pacotes.',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: false,
        supportsSmartStep: false,
        supportsHotSwap: false,
        supportsWatchpoints: true, // Hardware Data Watchpoints do LLDB
      ),
      sampleLaunchConfig: {
        'type': 'lldb',
        'request': 'launch',
        'program': r'${workspaceFolder}/target/debug/app',
        'cwd': r'${workspaceFolder}',
      },
    ),

    // 5. Go (delve)
    DebugAdapterDefinition(
      adapterId: 'dlv',
      name: 'Go Delve DAP',
      defaultExecutable: 'dlv',
      defaultArgs: ['dap'],
      supportedLanguages: ['go'],
      license: 'MIT',
      installHint: 'Instalar via Go: go install github.com/go-delve/delve/cmd/dlv@latest',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: false,
        supportsSmartStep: false,
        supportsHotSwap: false,
        supportsWatchpoints: true, // Hardware watchpoints do Delve
      ),
      sampleLaunchConfig: {
        'type': 'dlv',
        'request': 'launch',
        'program': '.',
        'cwd': r'${workspaceFolder}',
      },
    ),

    // 6. Java / JVM (java-debug)
    DebugAdapterDefinition(
      adapterId: 'java',
      name: 'Java Debug Server (JDWP)',
      defaultExecutable: 'java-debug-server',
      defaultArgs: [],
      supportedLanguages: ['java', 'kotlin'],
      license: 'EPL-1.0',
      installHint: 'Instalar extensão Eclipse JDT Language Server / java-debug.',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: true, // Drop to frame
        supportsSmartStep: true,
        supportsHotSwap: true, // JVM HotSwap
        supportsWatchpoints: true, // Field modification watchpoints
      ),
      sampleLaunchConfig: {
        'type': 'java',
        'request': 'launch',
        'mainClass': 'com.example.Main',
        'cwd': r'${workspaceFolder}',
      },
    ),

    // 7. .NET / C# (netcoredbg)
    DebugAdapterDefinition(
      adapterId: 'coreclr',
      name: '.NET Core Debugger (netcoredbg)',
      defaultExecutable: 'netcoredbg',
      defaultArgs: ['--interpreter=vscode'],
      supportedLanguages: ['csharp'],
      license: 'MIT',
      installHint: 'Baixar release oficial do netcoredbg no GitHub.',
      capabilities: DebugAdapterCapabilities(
        supportsRestartFrame: false,
        supportsSmartStep: false,
        supportsHotSwap: true, // Edit and Continue no .NET 6+
        supportsWatchpoints: false,
      ),
      sampleLaunchConfig: {
        'type': 'coreclr',
        'request': 'launch',
        'program': r'${workspaceFolder}/bin/Debug/net8.0/app.dll',
        'cwd': r'${workspaceFolder}',
      },
    ),
  ];

  /// Localiza o adaptador configurado para a linguagem informada.
  static DebugAdapterDefinition? adapterForLanguage(String languageId) {
    final normalized = languageId.trim().toLowerCase();
    for (final adapter in allAdapters) {
      if (adapter.supportedLanguages.contains(normalized)) {
        return adapter;
      }
    }
    return null;
  }

  /// Localiza o adaptador pelo identificador oficial (ex.: `debugpy`, `lldb`).
  static DebugAdapterDefinition? adapterById(String adapterId) {
    for (final adapter in allAdapters) {
      if (adapter.adapterId == adapterId) {
        return adapter;
      }
    }
    return null;
  }
}
