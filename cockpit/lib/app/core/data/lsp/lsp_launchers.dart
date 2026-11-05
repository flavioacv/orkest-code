import 'package:orkest_code/app/core/data/lsp/lsp_command.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:path/path.dart' as p;

/// Configuração declarativa de um language server (LSP).
///
/// Separa o executável/comando e seus argumentos das definições de debug e SDK,
/// permitindo documentar dicas de instalação sem acoplamento.
class LanguageServerConfig {
  const LanguageServerConfig({
    required this.name,
    required this.executable,
    this.args = const <String>[],
    this.installHint,
  });

  /// Identificador do servidor (ex.: 'dart', 'pyright', 'gopls').
  final String name;

  /// Binário padrão esperado no PATH.
  final String executable;

  /// Argumentos padrão da linha de comando do servidor.
  final List<String> args;

  /// Instrução orientativa de instalação caso o executável não seja encontrado.
  final String? installHint;
}

/// Configuração declarativa de um adaptador de depuração (DAP).
///
/// Mantém as definições de debug isoladas do LSP e de highlight.
class DebugAdapterConfig {
  const DebugAdapterConfig({
    required this.adapterId,
    required this.executable,
    this.args = const <String>[],
    this.installHint,
  });

  /// Identificador do adaptador (ex.: 'dart', 'debugpy', 'delve', 'codelldb').
  final String adapterId;

  /// Executável do adaptador de debug.
  final String executable;

  /// Argumentos padrão para iniciar a sessão DAP.
  final List<String> args;

  /// Dica de instalação caso o adaptador de depuração não esteja presente.
  final String? installHint;
}

/// Capacidades e níveis de suporte formalmente declarados para a linguagem.
class LanguageCapabilities {
  const LanguageCapabilities({
    this.lsp = true,
    this.debug = false,
    this.formatting = false,
    this.hover = true,
    this.completion = true,
    this.signatureHelp = true,
    this.semanticTokens = true,
  });

  final bool lsp;
  final bool debug;
  final bool formatting;
  final bool hover;
  final bool completion;
  final bool signatureHelp;
  final bool semanticTokens;
}

/// Metadados declarativos do SDK / runtime associado à linguagem.
class SdkConfig {
  const SdkConfig({
    this.name,
    this.installHint,
    this.documentationUrl,
  });

  final String? name;
  final String? installHint;
  final String? documentationUrl;
}

/// Definição declarativa completa de uma linguagem no catálogo.
///
/// Separa detecção de arquivos/comentários, marcadores de projeto, servidor LSP,
/// adaptador de debug, SDK e matriz de capacidades, preservando compatibilidade
/// total com as preferências do usuário e o pool de servidores existentes.
class LanguageDef {
  const LanguageDef({
    required this.id,
    required this.label,
    required this.extensions,
    required this.markers,
    String? defaultExecutable,
    List<String> defaultArgs = const <String>[],
    this.filenames = const <String>[],
    this.server,
    this.debugger,
    this.sdk,
    this.capabilities = const LanguageCapabilities(),
    this.lineComment,
    this.blockComment,
  })  : _customExecutable = defaultExecutable,
        _customArgs = defaultArgs;

  /// `languageId` do LSP (vai no `didOpen`) e chave de config/pool.
  final String id;

  /// Nome amigável pra UI (tela Language).
  final String label;

  /// Extensões (sem ponto, minúsculas) que mapeiam pra esta linguagem.
  final List<String> extensions;

  /// Nomes exatos com precedência sobre a extensão, como `tsconfig.json`.
  final List<String> filenames;

  /// Arquivos marcadores de raiz de projeto (nome exato ou `*.sufixo`).
  final List<String> markers;

  final String? _customExecutable;
  final List<String> _customArgs;

  /// Configuração declarativa do language server.
  final LanguageServerConfig? server;

  /// Configuração declarativa do adaptador de depuração DAP.
  final DebugAdapterConfig? debugger;

  /// Informações declarativas do SDK da linguagem.
  final SdkConfig? sdk;

  /// Matriz de capacidades suportadas no produto.
  final LanguageCapabilities capabilities;

  /// Delimitador de comentário de linha única (ex.: '//', '#').
  final String? lineComment;

  /// Delimitadores de comentário em bloco (ex.: ['/*', '*/']).
  final List<String>? blockComment;

  /// Executável padrão do servidor LSP.
  String get defaultExecutable =>
      _customExecutable ?? server?.executable ?? '';

  /// Argumentos padrão do servidor LSP.
  List<String> get defaultArgs =>
      _customArgs.isNotEmpty ? _customArgs : (server?.args ?? const <String>[]);

  /// Produz a especificação de inicialização do servidor respeitando overrides e
  /// tratando caminhos com espaços de forma segura.
  LspServerSpec toSpec({
    String? executable,
    List<String>? args,
    String? commandLine,
  }) {
    if (commandLine != null && commandLine.trim().isNotEmpty) {
      final parts = splitLspCommand(commandLine.trim());
      if (parts.isNotEmpty) {
        return LspServerSpec(
          languageId: id,
          executable: parts.first,
          args: parts.length > 1 ? parts.sublist(1) : const <String>[],
        );
      }
    }
    if (executable != null && args == null && executable.trim().contains(' ')) {
      final parts = splitLspCommand(executable.trim());
      if (parts.isNotEmpty) {
        return LspServerSpec(
          languageId: id,
          executable: parts.first,
          args: parts.length > 1 ? parts.sublist(1) : defaultArgs,
        );
      }
    }
    return LspServerSpec(
      languageId: id,
      executable: executable ?? defaultExecutable,
      args: args ?? defaultArgs,
    );
  }
}

/// Catálogo de linguagens suportadas declarativamente.
const List<LanguageDef> kLanguageDefs = <LanguageDef>[
  LanguageDef(
    id: 'dart',
    label: 'Dart',
    extensions: <String>['dart'],
    markers: <String>['pubspec.yaml'],
    server: LanguageServerConfig(
      name: 'dart',
      executable: 'dart',
      args: <String>['language-server', '--client-id', 'orkest'],
      installHint: 'Instale o Flutter SDK ou Dart SDK (https://dart.dev/get-dart)',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'dart',
      executable: 'dart',
      args: <String>['debug_adapter'],
      installHint: 'Utilize dart debug_adapter ou flutter debug_adapter',
    ),
    sdk: SdkConfig(
      name: 'Dart / Flutter',
      installHint: 'https://dart.dev/get-dart',
      documentationUrl: 'https://docs.flutter.dev',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'typescript',
    label: 'TypeScript',
    extensions: <String>['ts', 'tsx', 'mts', 'cts'],
    markers: <String>['tsconfig.json', 'package.json'],
    server: LanguageServerConfig(
      name: 'typescript-language-server',
      executable: 'typescript-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g typescript-language-server typescript',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'js-debug',
      executable: 'js-debug',
      installHint: 'Visual Studio Code js-debug DAP adapter',
    ),
    sdk: SdkConfig(
      name: 'Node.js / TypeScript',
      installHint: 'https://nodejs.org',
      documentationUrl: 'https://www.typescriptlang.org',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'javascript',
    label: 'JavaScript',
    extensions: <String>['js', 'jsx', 'mjs', 'cjs'],
    markers: <String>['jsconfig.json', 'package.json'],
    server: LanguageServerConfig(
      name: 'typescript-language-server',
      executable: 'typescript-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g typescript-language-server typescript',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'js-debug',
      executable: 'js-debug',
      installHint: 'Visual Studio Code js-debug DAP adapter',
    ),
    sdk: SdkConfig(
      name: 'Node.js',
      installHint: 'https://nodejs.org',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'python',
    label: 'Python',
    extensions: <String>['py', 'pyi'],
    markers: <String>[
      'pyproject.toml',
      'setup.py',
      'setup.cfg',
      'requirements.txt',
      'Pipfile',
    ],
    server: LanguageServerConfig(
      name: 'pyright',
      executable: 'pyright-langserver',
      args: <String>['--stdio'],
      installHint: 'npm install -g pyright ou pip install pyright',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'debugpy',
      executable: 'python',
      args: <String>['-m', 'debugpy.adapter'],
      installHint: 'pip install debugpy',
    ),
    sdk: SdkConfig(
      name: 'Python',
      installHint: 'https://www.python.org',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '#',
  ),
  LanguageDef(
    id: 'go',
    label: 'Go',
    extensions: <String>['go'],
    markers: <String>['go.mod', 'go.work'],
    server: LanguageServerConfig(
      name: 'gopls',
      executable: 'gopls',
      installHint: 'go install golang.org/x/tools/gopls@latest',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'delve',
      executable: 'dlv',
      args: <String>['dap'],
      installHint: 'go install github.com/go-delve/delve/cmd/dlv@latest',
    ),
    sdk: SdkConfig(
      name: 'Go',
      installHint: 'https://go.dev',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'rust',
    label: 'Rust',
    extensions: <String>['rs'],
    markers: <String>['Cargo.toml'],
    server: LanguageServerConfig(
      name: 'rust-analyzer',
      executable: 'rust-analyzer',
      installHint: 'rustup component add rust-analyzer',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'codelldb',
      executable: 'codelldb',
      installHint: 'CodeLLDB DAP adapter',
    ),
    sdk: SdkConfig(
      name: 'Rust / Cargo',
      installHint: 'https://rustup.rs',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'php',
    label: 'PHP',
    extensions: <String>['php'],
    markers: <String>['composer.json'],
    server: LanguageServerConfig(
      name: 'intelephense',
      executable: 'intelephense',
      args: <String>['--stdio'],
      installHint: 'npm install -g intelephense',
    ),
    sdk: SdkConfig(
      name: 'PHP / Composer',
      installHint: 'https://www.php.net',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'csharp',
    label: 'C#',
    extensions: <String>['cs'],
    markers: <String>['*.csproj', '*.sln'],
    server: LanguageServerConfig(
      name: 'csharp-ls',
      executable: 'csharp-ls',
      installHint: 'dotnet tool install -g csharp-ls',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'netcoredbg',
      executable: 'netcoredbg',
      installHint: 'netcoredbg DAP adapter',
    ),
    sdk: SdkConfig(
      name: '.NET SDK',
      installHint: 'https://dotnet.microsoft.com',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'java',
    label: 'Java',
    extensions: <String>['java'],
    markers: <String>[
      'pom.xml',
      'build.gradle',
      'build.gradle.kts',
      'settings.gradle',
    ],
    server: LanguageServerConfig(
      name: 'jdtls',
      executable: 'jdtls',
      installHint: 'Eclipse JDT Language Server',
    ),
    debugger: DebugAdapterConfig(
      adapterId: 'java-debug',
      executable: 'java-debug',
    ),
    sdk: SdkConfig(
      name: 'Java JDK',
      installHint: 'https://adoptium.net',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: true,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: true,
      semanticTokens: true,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'html',
    label: 'HTML',
    extensions: <String>['html', 'htm', 'xhtml', 'shtml'],
    markers: <String>['package.json'],
    server: LanguageServerConfig(
      name: 'vscode-html-language-server',
      executable: 'vscode-html-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    blockComment: <String>['<!--', '-->'],
  ),
  LanguageDef(
    id: 'css',
    label: 'CSS',
    extensions: <String>['css'],
    markers: <String>['package.json'],
    server: LanguageServerConfig(
      name: 'vscode-css-language-server',
      executable: 'vscode-css-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'scss',
    label: 'SCSS',
    extensions: <String>['scss'],
    markers: <String>['package.json'],
    server: LanguageServerConfig(
      name: 'vscode-css-language-server',
      executable: 'vscode-css-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'less',
    label: 'Less',
    extensions: <String>['less'],
    markers: <String>['package.json'],
    server: LanguageServerConfig(
      name: 'vscode-css-language-server',
      executable: 'vscode-css-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'json',
    label: 'JSON',
    extensions: <String>['json', 'geojson', 'webmanifest', 'avsc'],
    filenames: <String>['.prettierrc', '.watchmanconfig', 'composer.lock'],
    markers: <String>['package.json', 'composer.json', 'pubspec.yaml'],
    server: LanguageServerConfig(
      name: 'vscode-json-language-server',
      executable: 'vscode-json-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
  ),
  LanguageDef(
    id: 'jsonc',
    label: 'JSONC',
    extensions: <String>['jsonc', 'code-workspace', 'code-snippets'],
    filenames: <String>[
      'tsconfig.json',
      'jsconfig.json',
      '.eslintrc',
      '.eslintrc.json',
      '.babelrc',
      '.swcrc',
      'devcontainer.json',
      'launch.json',
      'tasks.json',
      'settings.json',
      'extensions.json',
      'keybindings.json',
      'deno.json',
      'biome.json',
    ],
    markers: <String>['package.json', 'deno.json'],
    server: LanguageServerConfig(
      name: 'vscode-json-language-server',
      executable: 'vscode-json-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g vscode-langservers-extracted',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    lineComment: '//',
    blockComment: <String>['/*', '*/'],
  ),
  LanguageDef(
    id: 'yaml',
    label: 'YAML',
    extensions: <String>['yaml', 'yml'],
    filenames: <String>['.clang-format', '.clang-tidy', '.clangd'],
    markers: <String>['package.json', 'pubspec.yaml'],
    server: LanguageServerConfig(
      name: 'yaml-language-server',
      executable: 'yaml-language-server',
      args: <String>['--stdio'],
      installHint: 'npm install -g yaml-language-server',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    lineComment: '#',
  ),
  LanguageDef(
    id: 'shellscript',
    label: 'Shell Script',
    extensions: <String>['sh', 'bash', 'bats'],
    filenames: <String>[
      '.bashrc',
      '.bash_profile',
      '.bash_aliases',
      '.profile',
      '.envrc',
    ],
    markers: <String>['package.json', 'Makefile'],
    server: LanguageServerConfig(
      name: 'bash-language-server',
      executable: 'bash-language-server',
      args: <String>['start'],
      installHint: 'npm install -g bash-language-server',
    ),
    capabilities: LanguageCapabilities(
      lsp: true,
      debug: false,
      formatting: true,
      hover: true,
      completion: true,
      signatureHelp: false,
      semanticTokens: false,
    ),
    lineComment: '#',
  ),
];

/// Obtém uma [LanguageDef] pelo identificador único [id].
LanguageDef? languageById(String id) {
  for (final def in kLanguageDefs) {
    if (def.id == id) return def;
  }
  return null;
}

/// Resolve a [LanguageDef] de um caminho pela extensão ou nome do arquivo,
/// ou `null` se nenhuma linguagem suportada bater.
LanguageDef? languageForPath(String path) {
  // Remote paths can use a different host style than the local OS.
  final name = p.posix.basename(p.windows.basename(path));
  for (final def in kLanguageDefs) {
    if (def.filenames.contains(name)) return def;
  }
  final suffix = p.posix.extension(name);
  if (suffix.isEmpty) return null;
  final ext = suffix.substring(1).toLowerCase();
  for (final def in kLanguageDefs) {
    if (def.extensions.contains(ext)) return def;
  }
  return null;
}
