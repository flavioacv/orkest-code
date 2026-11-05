/// Catálogo único dos agentes de CLI que o Orkest conhece.
///
/// Mesma lista serve a dois consumidores: a **detecção de processo** (ícone na
/// aba do terminal, via [HarnessSpec.allEntryPoints]) e as **automações** (gerar
/// mensagem de commit, ver `automation.dart`).
enum HarnessKind {
  antigravity,
  claudeCode,
  codex,
  cursor,
  gitHubCopilot,
  openCode,
  pi,
  gemini,
  kimi,
  aider,
  ollama,
}

class HarnessSpec {
  final HarnessKind kind;
  final String label;
  final String primaryEntryPoint;
  final List<String> aliases;
  final String assetPath;
  final bool isMonochrome;
  final bool supportsStructuredHooks;
  final bool supportsPtyMarkers;
  final bool supportsResume;
  final String? resumeSyntax;
  final Set<String> nonInteractiveFlags;
  final Set<String> adminSubcommands;
  final List<String> knownWrappers;

  const HarnessSpec({
    required this.kind,
    required this.label,
    required this.primaryEntryPoint,
    required this.aliases,
    required this.assetPath,
    required this.isMonochrome,
    this.supportsStructuredHooks = false,
    this.supportsPtyMarkers = true,
    this.supportsResume = false,
    this.resumeSyntax,
    this.nonInteractiveFlags = const {},
    this.adminSubcommands = const {},
    this.knownWrappers = const [],
  });

  /// All entry point names that can trigger this harness.
  List<String> get allEntryPoints => [primaryEntryPoint, ...aliases];
}

abstract class HarnessCatalog {
  static const Map<HarnessKind, HarnessSpec> specs = {
    HarnessKind.antigravity: HarnessSpec(
      kind: HarnessKind.antigravity,
      label: 'Antigravity',
      primaryEntryPoint: 'agy',
      aliases: ['antigravity'],
      assetPath: 'assets/harness_icons/antigravity.svg',
      isMonochrome: false,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: true,
      resumeSyntax: 'agy resume {id}',
      nonInteractiveFlags: {'-p', '--print'},
      adminSubcommands: {
        'help',
        'version',
        'config',
        'auth',
        'models',
        'update',
      },
      knownWrappers: ['agy'],
    ),
    HarnessKind.claudeCode: HarnessSpec(
      kind: HarnessKind.claudeCode,
      label: 'Claude Code',
      primaryEntryPoint: 'claude',
      aliases: ['claude-code'],
      assetPath: 'assets/harness_icons/claudecode.svg',
      isMonochrome: true,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: true,
      resumeSyntax: 'claude --resume {id}',
      nonInteractiveFlags: {'-p', '--print'},
      adminSubcommands: {
        'mcp',
        'plugin',
        'config',
        'auth',
        'doctor',
        'update',
        'version',
        'help',
      },
      knownWrappers: ['node', 'bun', 'npx'],
    ),
    HarnessKind.codex: HarnessSpec(
      kind: HarnessKind.codex,
      label: 'Codex',
      primaryEntryPoint: 'codex',
      aliases: [],
      assetPath: 'assets/harness_icons/codex.svg',
      isMonochrome: false,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: true,
      resumeSyntax: 'codex resume {id}',
      nonInteractiveFlags: {'-e', '--eval'},
      adminSubcommands: {
        'exec',
        'auth',
        'config',
        'version',
        'help',
        'models',
      },
    ),
    HarnessKind.cursor: HarnessSpec(
      kind: HarnessKind.cursor,
      label: 'Cursor',
      primaryEntryPoint: 'cursor-agent',
      aliases: ['cursor', 'agent'],
      assetPath: 'assets/harness_icons/cursor.svg',
      isMonochrome: true,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-p', '--print'},
      adminSubcommands: {
        'auth',
        'login',
        'logout',
        'list',
        'version',
        'help',
      },
      knownWrappers: ['node', 'bun'],
    ),
    HarnessKind.gitHubCopilot: HarnessSpec(
      kind: HarnessKind.gitHubCopilot,
      label: 'GitHub Copilot',
      primaryEntryPoint: 'copilot',
      aliases: ['github-copilot'],
      assetPath: 'assets/harness_icons/githubcopilot.svg',
      isMonochrome: true,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-p', '--prompt', '-i', '--input'},
      adminSubcommands: {'auth', 'config', 'alias', 'version', 'help'},
    ),
    HarnessKind.openCode: HarnessSpec(
      kind: HarnessKind.openCode,
      label: 'OpenCode',
      primaryEntryPoint: 'opencode',
      aliases: [],
      assetPath: 'assets/harness_icons/opencode.svg',
      isMonochrome: true,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'--batch'},
      adminSubcommands: {
        'run',
        'auth',
        'config',
        'models',
        'version',
        'help',
      },
    ),
    HarnessKind.pi: HarnessSpec(
      kind: HarnessKind.pi,
      label: 'Pi',
      primaryEntryPoint: 'pi',
      aliases: [],
      assetPath: 'assets/harness_icons/pi.svg',
      isMonochrome: true,
      supportsStructuredHooks: true,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-p', '--print'},
      adminSubcommands: {
        'export',
        'auth',
        'config',
        'models',
        'version',
        'help',
        'doctor',
      },
      knownWrappers: ['node', 'bun'],
    ),
    HarnessKind.gemini: HarnessSpec(
      kind: HarnessKind.gemini,
      label: 'Gemini CLI',
      primaryEntryPoint: 'gemini',
      aliases: ['gemini-cli'],
      assetPath: 'assets/harness_icons/gemini.svg',
      isMonochrome: false,
      supportsStructuredHooks: false,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-p', '--prompt', '-q', '--quiet', '--json'},
      adminSubcommands: {'auth', 'config', 'models', 'version', 'help'},
      knownWrappers: ['node', 'npx', 'bun', 'bunx'],
    ),
    HarnessKind.kimi: HarnessSpec(
      kind: HarnessKind.kimi,
      label: 'Kimi CLI',
      primaryEntryPoint: 'kimi',
      aliases: ['kimi-cli'],
      assetPath: 'assets/harness_icons/kimi.svg',
      isMonochrome: true,
      supportsStructuredHooks: false,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-p', '--print', '-q', '--quiet'},
      adminSubcommands: {
        'auth',
        'config',
        'version',
        'help',
        'login',
        'logout',
      },
    ),
    HarnessKind.aider: HarnessSpec(
      kind: HarnessKind.aider,
      label: 'Aider',
      primaryEntryPoint: 'aider',
      aliases: ['aider-chat'],
      assetPath: 'assets/harness_icons/aider.svg',
      isMonochrome: true,
      supportsStructuredHooks: false,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-m', '--message', '--no-git', '--exit'},
      adminSubcommands: {'check-update', 'install-git', 'version', 'help'},
      knownWrappers: ['python', 'python3', 'uvx', 'pipx'],
    ),
    HarnessKind.ollama: HarnessSpec(
      kind: HarnessKind.ollama,
      label: 'Ollama',
      primaryEntryPoint: 'ollama',
      aliases: [],
      assetPath: 'assets/harness_icons/ollama.svg',
      isMonochrome: true,
      supportsStructuredHooks: false,
      supportsPtyMarkers: true,
      supportsResume: false,
      nonInteractiveFlags: {'-v', '--version', '-h', '--help'},
      adminSubcommands: {
        'serve',
        'pull',
        'list',
        'ps',
        'rm',
        'create',
        'cp',
        'push',
        'stop',
        'help',
        'version',
      },
    ),
  };

  static HarnessSpec? getSpec(HarnessKind kind) => specs[kind];
}
