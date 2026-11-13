/// Parâmetros de consulta, filtros e paginação para o histórico Git.
class GitHistoryQuery {
  const GitHistoryQuery({
    this.limit = 100,
    this.skip = 0,
    this.filePath,
    this.author,
    this.query,
    this.revisionRange,
    this.all = false,
    this.since,
  });

  /// Quantidade máxima de commits a retornar por página.
  final int limit;

  /// Quantidade de commits a pular (offset de paginação).
  final int skip;

  /// Caminho relativo de um arquivo para filtrar apenas commits que o alteraram.
  /// Quando informado, habilita acompanhamento de renomeações (`--follow`).
  final String? filePath;

  /// Filtro por nome ou email do autor (`--author`).
  final String? author;

  /// Filtro por mensagem de commit (`--grep`).
  final String? query;

  /// Intervalo explícito de revisões (ex.: `HEAD~10..HEAD` ou `main..feature`).
  final String? revisionRange;

  /// Se verdadeiro, lista commits de todas as branches e tags (`--all`).
  final bool all;
  final DateTime? since;

  /// Gera os argumentos correspondentes da linha de comando Git.
  List<String> toGitArgs() {
    return [
      '-n',
      '$limit',
      if (skip > 0) ...['--skip', '$skip'],
      if (author != null && author!.isNotEmpty) '--author=$author',
      if (query != null && query!.isNotEmpty) '--grep=$query',
      if (all) '--all',
      if (since != null) '--since=${since!.toUtc().toIso8601String()}',
      if (revisionRange != null && revisionRange!.isNotEmpty) revisionRange!,
      if (filePath != null && filePath!.isNotEmpty) ...['--follow', '--', filePath!],
    ];
  }
}
