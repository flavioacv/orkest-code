import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';

/// Representação estruturada de um Pull Request no GitHub / GitLab.
class GitPullRequest {
  const GitPullRequest({
    required this.number,
    required this.title,
    this.body = '',
    required this.state,
    required this.author,
    required this.headRef,
    required this.baseRef,
    required this.htmlUrl,
    required this.createdAt,
    this.updatedAt,
    this.isDraft = false,
  });

  /// Número identificador do PR (ex.: `#42`).
  final int number;

  /// Título do Pull Request.
  final String title;

  /// Descrição ou corpo em Markdown.
  final String body;

  /// Estado: `open`, `closed`, `merged`.
  final String state;

  /// Nome de usuário do autor do PR.
  final String author;

  /// Branch de origem que contém as alterações.
  final String headRef;

  /// Branch de destino (ex.: `main`).
  final String baseRef;

  /// URL web do PR.
  final String htmlUrl;

  /// Data de criação.
  final DateTime createdAt;

  /// Data da última atualização.
  final DateTime? updatedAt;

  /// Se o PR está marcado como rascunho (Draft).
  final bool isDraft;

  bool get isOpen => state.toLowerCase() == 'open';
  bool get isMerged => state.toLowerCase() == 'merged';
  bool get isClosed => state.toLowerCase() == 'closed';

  factory GitPullRequest.fromJson(Map<String, dynamic> json) {
    return GitPullRequest(
      number: json['number'] as int? ?? (json['id'] as int? ?? 0),
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      state: (json['state'] as String? ?? 'open').toLowerCase(),
      author: (json['user'] is Map)
          ? (json['user']['login'] as String? ?? 'desconhecido')
          : (json['author'] is Map
              ? (json['author']['login'] as String? ?? 'desconhecido')
              : json['author'] as String? ?? 'desconhecido'),
      headRef: (json['head'] is Map)
          ? (json['head']['ref'] as String? ?? '')
          : (json['headRefName'] as String? ?? json['headRef'] as String? ?? ''),
      baseRef: (json['base'] is Map)
          ? (json['base']['ref'] as String? ?? 'main')
          : (json['baseRefName'] as String? ?? json['baseRef'] as String? ?? 'main'),
      htmlUrl: json['html_url'] as String? ?? (json['url'] as String? ?? ''),
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : (json['createdAt'] != null
              ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
              : DateTime.now()),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String)
          : (json['updatedAt'] != null
              ? DateTime.tryParse(json['updatedAt'] as String)
              : null),
      isDraft: json['draft'] as bool? ?? (json['isDraft'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
        'number': number,
        'title': title,
        'body': body,
        'state': state,
        'author': author,
        'headRef': headRef,
        'baseRef': baseRef,
        'htmlUrl': htmlUrl,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'isDraft': isDraft,
      };
}

/// Comentário de revisão em um Pull Request.
class GitPrComment {
  const GitPrComment({
    required this.id,
    required this.author,
    required this.body,
    this.path,
    this.line,
    required this.createdAt,
  });

  final int id;
  final String author;
  final String body;
  final String? path;
  final int? line;
  final DateTime createdAt;

  factory GitPrComment.fromJson(Map<String, dynamic> json) {
    return GitPrComment(
      id: json['id'] as int? ?? 0,
      author: (json['user'] is Map)
          ? (json['user']['login'] as String? ?? 'autor')
          : (json['author'] is Map
              ? (json['author']['login'] as String? ?? 'autor')
              : json['author'] as String? ?? 'autor'),
      body: json['body'] as String? ?? '',
      path: json['path'] as String?,
      line: json['line'] as int? ?? json['original_line'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

/// Detalhes completos de um Pull Request com lista de alterações e comentários.
class GitPrDetail {
  const GitPrDetail({
    required this.pr,
    this.comments = const [],
    this.changedFiles = const [],
    this.diff = '',
  });

  final GitPullRequest pr;
  final List<GitPrComment> comments;
  final List<GitHistoryFileChange> changedFiles;
  final String diff;
}
