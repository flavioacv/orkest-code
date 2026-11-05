import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:path/path.dart' as p;

/// Definição de uma linguagem para o LSP: como detectá-la (extensões), onde
/// está a raiz do projeto (markers, ver [ProjectRootFinder]) e o comando padrão
/// do language server. O comando é **binário + args** separados — split ingênuo
/// de string quebra em caminhos com espaço.
///
/// Na Wave 2 a tela "Language" sobrescreve `defaultExecutable`/`defaultArgs` por
/// preferência do usuário; a detecção no PATH preenche o default.
class LanguageDef {
  const LanguageDef({
    required this.id,
    required this.label,
    required this.extensions,
    required this.markers,
    required this.defaultExecutable,
    this.defaultArgs = const <String>[],
    this.filenames = const <String>[],
  });

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

  final String defaultExecutable;
  final List<String> defaultArgs;

  LspServerSpec toSpec({String? executable, List<String>? args}) =>
      LspServerSpec(
        languageId: id,
        executable: executable ?? defaultExecutable,
        args: args ?? defaultArgs,
      );
}

/// Catálogo de linguagens suportadas. Dart é o caso campeão (servidor vem com o
/// Flutter SDK). As demais ficam prontas para a Wave 2 (config + status no PATH).
const List<LanguageDef> kLanguageDefs = <LanguageDef>[
  LanguageDef(
    id: 'dart',
    label: 'Dart',
    extensions: <String>['dart'],
    markers: <String>['pubspec.yaml'],
    defaultExecutable: 'dart',
    defaultArgs: <String>['language-server', '--client-id', 'orkest'],
  ),
  LanguageDef(
    id: 'typescript',
    label: 'TypeScript',
    extensions: <String>['ts', 'tsx', 'mts', 'cts'],
    markers: <String>['tsconfig.json', 'package.json'],
    defaultExecutable: 'typescript-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'javascript',
    label: 'JavaScript',
    extensions: <String>['js', 'jsx', 'mjs', 'cjs'],
    markers: <String>['jsconfig.json', 'package.json'],
    defaultExecutable: 'typescript-language-server',
    defaultArgs: <String>['--stdio'],
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
    defaultExecutable: 'pyright-langserver',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'go',
    label: 'Go',
    extensions: <String>['go'],
    markers: <String>['go.mod', 'go.work'],
    defaultExecutable: 'gopls',
  ),
  LanguageDef(
    id: 'rust',
    label: 'Rust',
    extensions: <String>['rs'],
    markers: <String>['Cargo.toml'],
    defaultExecutable: 'rust-analyzer',
  ),
  LanguageDef(
    id: 'php',
    label: 'PHP',
    extensions: <String>['php'],
    markers: <String>['composer.json'],
    defaultExecutable: 'intelephense',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'csharp',
    label: 'C#',
    extensions: <String>['cs'],
    markers: <String>['*.csproj', '*.sln'],
    defaultExecutable: 'csharp-ls',
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
    defaultExecutable: 'jdtls',
  ),
  LanguageDef(
    id: 'html',
    label: 'HTML',
    extensions: <String>['html', 'htm', 'xhtml', 'shtml'],
    markers: <String>['package.json'],
    defaultExecutable: 'vscode-html-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'css',
    label: 'CSS',
    extensions: <String>['css'],
    markers: <String>['package.json'],
    defaultExecutable: 'vscode-css-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'scss',
    label: 'SCSS',
    extensions: <String>['scss'],
    markers: <String>['package.json'],
    defaultExecutable: 'vscode-css-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'less',
    label: 'Less',
    extensions: <String>['less'],
    markers: <String>['package.json'],
    defaultExecutable: 'vscode-css-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'json',
    label: 'JSON',
    extensions: <String>['json', 'geojson', 'webmanifest', 'avsc'],
    filenames: <String>['.prettierrc', '.watchmanconfig', 'composer.lock'],
    markers: <String>['package.json', 'composer.json', 'pubspec.yaml'],
    defaultExecutable: 'vscode-json-language-server',
    defaultArgs: <String>['--stdio'],
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
    defaultExecutable: 'vscode-json-language-server',
    defaultArgs: <String>['--stdio'],
  ),
  LanguageDef(
    id: 'yaml',
    label: 'YAML',
    extensions: <String>['yaml', 'yml'],
    filenames: <String>['.clang-format', '.clang-tidy', '.clangd'],
    markers: <String>['package.json', 'pubspec.yaml'],
    defaultExecutable: 'yaml-language-server',
    defaultArgs: <String>['--stdio'],
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
    defaultExecutable: 'bash-language-server',
    defaultArgs: <String>['start'],
  ),
];

/// Resolve a [LanguageDef] de um caminho pela extensão, ou `null` se nenhuma
/// linguagem suportada bate.
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
