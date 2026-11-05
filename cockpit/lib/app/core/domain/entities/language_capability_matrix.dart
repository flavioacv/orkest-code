import 'package:orkest_code/app/core/data/lsp/lsp_launchers.dart';

/// Status operacional do suporte à linguagem inspecionado no ambiente atual.
enum LanguageSupportStatus {
  /// Todos os componentes declarados (LSP e DAP) estão disponíveis no host.
  fullySupported,

  /// Servidor LSP presente, mas adaptador DAP ausente (ou vice-versa).
  partiallySupported,

  /// Servidor LSP configurado não foi localizado no PATH ou executável ausente.
  missingServer,

  /// Nenhuma ferramenta externa encontrada; modo fallback léxico/sintaxe pura.
  syntaxOnly,
}

/// Relatório de auditoria e conformidade de uma linguagem na IDE.
class LanguageAuditReport {
  const LanguageAuditReport({
    required this.definition,
    required this.status,
    required this.hasServer,
    required this.hasDebugger,
    required this.activeCapabilities,
    required this.unsupportedCapabilities,
    this.serverExecutable,
    this.debuggerExecutable,
    this.sdkName,
  });

  final LanguageDef definition;
  final LanguageSupportStatus status;
  final bool hasServer;
  final bool hasDebugger;
  final List<String> activeCapabilities;
  final List<String> unsupportedCapabilities;
  final String? serverExecutable;
  final String? debuggerExecutable;
  final String? sdkName;

  String get id => definition.id;
  String get label => definition.label;
  LanguageTier get tier => definition.tier;

  Map<String, dynamic> toJson() => {
    'id': id,
    'label': label,
    'tier': tier.name,
    'status': status.name,
    'hasServer': hasServer,
    'hasDebugger': hasDebugger,
    'serverExecutable': serverExecutable,
    'debuggerExecutable': debuggerExecutable,
    'sdkName': sdkName,
    'activeCapabilities': activeCapabilities,
    'unsupportedCapabilities': unsupportedCapabilities,
  };
}

/// Matriz formal de homologação e auditoria de linguagens por níveis de capacidade (L05).
class LanguageCapabilityMatrix {
  const LanguageCapabilityMatrix._();

  /// Todas as linguagens catalogadas.
  static List<LanguageDef> get allLanguages => kLanguageDefs;

  /// Linguagens Tier 1 (Core / Primeira Classe: Dart, TS, JS, Python, Go, Rust).
  static List<LanguageDef> get tier1Languages =>
      kLanguageDefs.where((l) => l.tier == LanguageTier.tier1Core).toList();

  /// Linguagens Tier 2 (Enterprise / Sistemas: Java, C#, PHP).
  static List<LanguageDef> get tier2Languages =>
      kLanguageDefs.where((l) => l.tier == LanguageTier.tier2Enterprise).toList();

  /// Linguagens Tier 3 (Web, Dados, Scripts sob demanda: HTML, CSS, JSON, YAML, SQL, Vue, Svelte, etc.).
  static List<LanguageDef> get tier3Languages =>
      kLanguageDefs.where((l) => l.tier == LanguageTier.tier3WebData).toList();

  /// Executa a auditoria de capacidades de uma linguagem individual.
  static LanguageAuditReport audit(
    LanguageDef def, {
    bool Function(String executable)? executableChecker,
  }) {
    final checker = executableChecker ?? (_) => false;

    final serverExec = def.server?.executable ?? (def.defaultExecutable.isNotEmpty ? def.defaultExecutable : null);
    final hasServer = serverExec != null && checker(serverExec);

    final debugExec = def.debugger?.executable;
    final hasDebugger = debugExec != null && checker(debugExec);

    final activeCaps = <String>[];
    final unsupportedCaps = <String>[];

    void checkCap(String name, bool supported) {
      if (supported) {
        activeCaps.add(name);
      } else {
        unsupportedCaps.add(name);
      }
    }

    checkCap('lsp', def.capabilities.lsp);
    checkCap('debug', def.capabilities.debug);
    checkCap('formatting', def.capabilities.formatting);
    checkCap('hover', def.capabilities.hover);
    checkCap('completion', def.capabilities.completion);
    checkCap('signatureHelp', def.capabilities.signatureHelp);
    checkCap('semanticTokens', def.capabilities.semanticTokens);

    LanguageSupportStatus status;
    if (def.capabilities.lsp && !hasServer) {
      status = LanguageSupportStatus.missingServer;
    } else if (def.capabilities.debug && !hasDebugger) {
      status = hasServer ? LanguageSupportStatus.partiallySupported : LanguageSupportStatus.missingServer;
    } else if (hasServer) {
      status = LanguageSupportStatus.fullySupported;
    } else {
      status = LanguageSupportStatus.syntaxOnly;
    }

    return LanguageAuditReport(
      definition: def,
      status: status,
      hasServer: hasServer,
      hasDebugger: hasDebugger,
      activeCapabilities: activeCaps,
      unsupportedCapabilities: unsupportedCaps,
      serverExecutable: serverExec,
      debuggerExecutable: debugExec,
      sdkName: def.sdk?.name,
    );
  }

  /// Audita todo o catálogo e retorna a lista de relatórios.
  static List<LanguageAuditReport> auditAll({
    bool Function(String executable)? executableChecker,
  }) {
    return [
      for (final def in kLanguageDefs)
        audit(def, executableChecker: executableChecker),
    ];
  }

  /// Exporta o resumo estruturado da matriz para auditoria e relatórios.
  static Map<String, dynamic> exportMatrix({
    bool Function(String executable)? executableChecker,
  }) {
    final reports = auditAll(executableChecker: executableChecker);
    return {
      'totalLanguages': kLanguageDefs.length,
      'tier1Count': tier1Languages.length,
      'tier2Count': tier2Languages.length,
      'tier3Count': tier3Languages.length,
      'languages': [for (final r in reports) r.toJson()],
    };
  }
}
