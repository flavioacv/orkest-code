/// Tipos de eventos Git observados no terminal.
enum GitTerminalEventKind {
  prOpened,
  prMerged,
  release,
  ciFailed,
  ciPassed,
  push,
}

/// Representa um evento Git identificado nas saídas de comando do terminal.
class GitTerminalEvent {
  const GitTerminalEvent({
    required this.kind,
    required this.summary,
    required this.banner,
    required this.icon,
    this.isError = false,
    this.number,
    this.branch,
    this.url,
  });

  final GitTerminalEventKind kind;
  final String summary;
  final String banner;
  final String icon;
  final bool isError;
  final int? number;
  final String? branch;
  final String? url;
}

/// Detector agnóstico a harness para capturar eventos de Git/GitHub a partir das linhas do terminal.
///
/// Funciona com qualquer harness (Antigravity, Claude Code, Codex, Cursor, shell puro),
/// analisando saídas padrão emitidas por comandos como `gh pr`, `gh run`, `git push` e `gh release`.
class GitTerminalEventDetector {
  const GitTerminalEventDetector();

  static final RegExp _prUrlPattern = RegExp(
    r'^https?://github\.com/([\w.-]+/[\w.-]+)/pull/(\d+)$',
    caseSensitive: false,
  );

  static final RegExp _releaseUrlPattern = RegExp(
    r'^https?://github\.com/([\w.-]+/[\w.-]+)/releases/tag/([^\s]+)$',
    caseSensitive: false,
  );

  static final RegExp _prCreatedPattern = RegExp(
    r'^(?:created|opened)\s+pull\s+request\s+#(\d+)$',
    caseSensitive: false,
  );

  static final RegExp _prMergedPattern = RegExp(
    r'^(?:✓\s*merged\s+pull\s+request\s+#(\d+)(?:\s+into\s+\S+)?|✓\s*(?:squashed and |rebase and )?merged pull request [\w.-]+/[\w.-]+#(\d+)(?:\s+\(.+\))?)$',
    caseSensitive: false,
  );

  static final RegExp _ciFailPattern = RegExp(
    r'^(?:Some checks were not successful|[1-9]\d* failing(?:\b.*)?|[✗X]\s+([^\s]+)\s+(.+?)\s+·\s+\d+|[✗X]\s+Run\s+.+?\s+\(\d+\)\s+completed with .failure.)$',
    caseSensitive: false,
  );

  static final RegExp _ciPassPattern = RegExp(
    r'^(?:All checks were successful|[✓✔]\s+[^\s]+\s+.+?\s+·\s+\d+|[✓✔]\s+Run\s+.+?\s+\(\d+\)\s+completed with .success.)$',
    caseSensitive: false,
  );

  static final RegExp _pushPattern = RegExp(
    r'^(?:[+*]?\s*(?:[0-9a-f]{4,40}\.\.{1,2}[0-9a-f]{4,40}|\[new branch\])\s+\S+\s+->\s+([a-zA-Z0-9_./-]+)(?:\s+\(forced update\))?)$',
    caseSensitive: false,
  );

  /// Tenta identificar um evento Git na linha especificada.
  /// Retorna `null` se a linha não contiver um evento reconhecido.
  GitTerminalEvent? detect(String line, {bool isPushOutput = false}) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    // 1. Detecção de PR Mergeado
    final mergeMatch = _prMergedPattern.firstMatch(trimmed);
    if (mergeMatch != null) {
      final prNumberStr = mergeMatch.group(1) ?? mergeMatch.group(2);
      final prNum = prNumberStr != null ? int.tryParse(prNumberStr) : null;
      final prLabel = prNum != null ? 'PR #$prNum' : 'PR';
      return GitTerminalEvent(
        kind: GitTerminalEventKind.prMerged,
        summary: 'Mergeou o $prLabel',
        banner: '$prLabel mergeado!',
        icon: '🎉',
        number: prNum,
      );
    }

    // 2. Detecção de PR Criado / Aberto por URL ou mensagem
    final prUrlMatch = _prUrlPattern.firstMatch(trimmed);
    if (prUrlMatch != null) {
      final prNum = int.tryParse(prUrlMatch.group(2) ?? '');
      final prLabel = prNum != null ? 'PR #$prNum' : 'PR';
      return GitTerminalEvent(
        kind: GitTerminalEventKind.prOpened,
        summary: 'Abriu o $prLabel',
        banner: '$prLabel aberto!',
        icon: '🎉',
        number: prNum,
        url: prUrlMatch.group(0),
      );
    }

    final prCreatedMatch = _prCreatedPattern.firstMatch(trimmed);
    if (prCreatedMatch != null) {
      final prNum = int.tryParse(prCreatedMatch.group(1) ?? '');
      final prLabel = prNum != null ? 'PR #$prNum' : 'PR';
      return GitTerminalEvent(
        kind: GitTerminalEventKind.prOpened,
        summary: 'Abriu o $prLabel',
        banner: '$prLabel aberto!',
        icon: '🎉',
        number: prNum,
      );
    }

    // 3. Detecção de Release Publicada
    final releaseMatch = _releaseUrlPattern.firstMatch(trimmed);
    if (releaseMatch != null) {
      final tag = releaseMatch.group(2) ?? '';
      return GitTerminalEvent(
        kind: GitTerminalEventKind.release,
        summary: tag.isNotEmpty ? 'Publicou release $tag' : 'Publicou release',
        banner: tag.isNotEmpty ? 'Release $tag no ar!' : 'Release no ar!',
        icon: '🎉',
        url: releaseMatch.group(0),
      );
    }

    // 4. Detecção de CI com Falha
    final ciFailMatch = _ciFailPattern.firstMatch(trimmed);
    if (ciFailMatch != null) {
      final where = ciFailMatch.group(1)?.trim();
      final banner = where != null && where.isNotEmpty
          ? 'CI falhou ($where)'
          : 'CI falhou';
      return GitTerminalEvent(
        kind: GitTerminalEventKind.ciFailed,
        summary: 'CI falhou${where != null ? ': $where' : ''}',
        banner: banner,
        icon: '🚨',
        isError: true,
      );
    }

    // 5. Detecção de CI com Sucesso
    final ciPassMatch = _ciPassPattern.firstMatch(trimmed);
    if (ciPassMatch != null) {
      return const GitTerminalEvent(
        kind: GitTerminalEventKind.ciPassed,
        summary: 'CI passou',
        banner: 'CI verde de novo!',
        icon: '✅',
      );
    }

    // 6. Detecção de Push
    final pushMatch = isPushOutput ? _pushPattern.firstMatch(trimmed) : null;
    if (pushMatch != null) {
      final branch = pushMatch.group(1);
      return GitTerminalEvent(
        kind: GitTerminalEventKind.push,
        summary: branch != null && branch.isNotEmpty
            ? 'Enviou commits para $branch'
            : 'Enviou commits ao Git',
        banner: '',
        icon: '🚀',
        branch: branch,
      );
    }

    return null;
  }
}
