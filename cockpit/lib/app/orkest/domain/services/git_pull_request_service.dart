import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_pull_request.dart';

/// Tipo de função para requisições HTTP customizadas (injetável em testes).
typedef HttpRequester = Future<(int statusCode, String body)> Function(
  String method,
  Uri uri,
  Map<String, String> headers,
  String? body,
);

/// Serviço de integração e revisão de Pull Requests no contexto do código (G05).
class GitPullRequestService {
  GitPullRequestService({
    GitBinary? gitBinary,
    HttpRequester? httpRequester,
    this.tokenOverride,
    this.originUrlOverride,
  })  : _gitBinary = gitBinary ?? GitBinary(),
        _httpRequester = httpRequester ?? _defaultHttpRequester;

  final GitBinary _gitBinary;
  final HttpRequester _httpRequester;
  final String? tokenOverride;
  final String? originUrlOverride;

  /// Extrai `owner` e `repo` a partir da URL do remote Git.
  static (String owner, String repo)? parseOwnerRepo(String remoteUrl) {
    final clean = remoteUrl.trim();
    if (clean.isEmpty) return null;

    // Formato SSH: git@github.com:owner/repo.git
    final sshMatch = RegExp(r'git@[^:]+:([^/]+)/(.+?)(?:\.git)?$').firstMatch(clean);
    if (sshMatch != null) {
      return (sshMatch.group(1)!, sshMatch.group(2)!);
    }

    // Formato HTTPS: https://github.com/owner/repo.git
    final httpMatch = RegExp(r'https?://[^/]+/([^/]+)/(.+?)(?:\.git)?$').firstMatch(clean);
    if (httpMatch != null) {
      return (httpMatch.group(1)!, httpMatch.group(2)!);
    }

    return null;
  }

  /// Obtém o token de autenticação do ambiente ou override.
  String? _resolveToken() {
    return tokenOverride ??
        Platform.environment['GITHUB_TOKEN'] ??
        Platform.environment['GH_TOKEN'];
  }

  /// Resolve o remote origin de [repoRoot].
  Future<String?> _getOriginUrl(String repoRoot) async {
    if (originUrlOverride != null) return originUrlOverride;
    final gitExe = await _gitBinary.resolve();
    try {
      final res = await Process.run(
        gitExe,
        ['-C', repoRoot, 'remote', 'get-url', 'origin'],
      );
      if (res.exitCode == 0) return res.stdout.toString().trim();
    } catch (_) {}
    return null;
  }

  // ===========================================================================
  // 1. LISTAGEM DE PULL REQUESTS
  // ===========================================================================

  /// Lista Pull Requests do repositório remoto.
  Future<Result<List<GitPullRequest>, String>> listPullRequests(
    String repoRoot, {
    String state = 'open',
    int limit = 30,
  }) async {
    final origin = await _getOriginUrl(repoRoot);
    if (origin == null) {
      return const Failure('Nenhum remote "origin" configurado no repositório.');
    }

    final parsed = parseOwnerRepo(origin);
    if (parsed == null) {
      return Failure('Não foi possível identificar owner/repo da URL: $origin');
    }

    final (owner, repo) = parsed;
    final token = _resolveToken();

    final uri = Uri.parse(
      'https://api.github.com/repos/$owner/$repo/pulls?state=$state&per_page=$limit',
    );

    final headers = {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'OrkestCode-IDE',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      final (code, body) = await _httpRequester('GET', uri, headers, null);
      if (code == 401 || code == 403) {
        return const Failure(
          'Autenticação necessária: configure a variável GITHUB_TOKEN ou faça login via gh CLI.',
        );
      }
      if (code != 200) {
        return Failure('Falha ao listar PRs (HTTP $code): $body');
      }

      final dynamic decoded = jsonDecode(body);
      if (decoded is! List) return const Success([]);

      final prs = decoded
          .map((item) => GitPullRequest.fromJson(item as Map<String, dynamic>))
          .toList();

      return Success(prs);
    } catch (e) {
      return Failure('Erro na requisição de Pull Requests: $e');
    }
  }

  // ===========================================================================
  // 2. DETALHAMENTO DE PULL REQUEST
  // ===========================================================================

  /// Obtém detalhes completos de um PR, incluindo comentários e arquivos alterados.
  Future<Result<GitPrDetail, String>> getPullRequestDetail(
    String repoRoot,
    int number,
  ) async {
    final origin = await _getOriginUrl(repoRoot);
    if (origin == null) {
      return const Failure('Nenhum remote "origin" configurado no repositório.');
    }

    final parsed = parseOwnerRepo(origin);
    if (parsed == null) {
      return Failure('Não foi possível identificar owner/repo da URL: $origin');
    }

    final (owner, repo) = parsed;
    final token = _resolveToken();

    final headers = {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'OrkestCode-IDE',
      if (token != null) 'Authorization': 'Bearer $token',
    };

    try {
      // 1. Busca PR
      final prUri = Uri.parse('https://api.github.com/repos/$owner/$repo/pulls/$number');
      final (prCode, prBody) = await _httpRequester('GET', prUri, headers, null);
      if (prCode != 200) {
        return Failure('Falha ao obter PR #$number (HTTP $prCode)');
      }
      final pr = GitPullRequest.fromJson(jsonDecode(prBody) as Map<String, dynamic>);

      // 2. Busca comentários
      final commentsUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/pulls/$number/comments',
      );
      final (cCode, cBody) = await _httpRequester('GET', commentsUri, headers, null);
      final comments = <GitPrComment>[];
      if (cCode == 200) {
        final dynamic rawComments = jsonDecode(cBody);
        if (rawComments is List) {
          comments.addAll(
            rawComments.map((c) => GitPrComment.fromJson(c as Map<String, dynamic>)),
          );
        }
      }

      // 3. Busca lista de arquivos alterados
      final filesUri = Uri.parse(
        'https://api.github.com/repos/$owner/$repo/pulls/$number/files',
      );
      final (fCode, fBody) = await _httpRequester('GET', filesUri, headers, null);
      final changedFiles = <GitHistoryFileChange>[];
      if (fCode == 200) {
        final dynamic rawFiles = jsonDecode(fBody);
        if (rawFiles is List) {
          for (final f in rawFiles) {
            if (f is Map<String, dynamic>) {
              final filename = f['filename'] as String? ?? '';
              final status = f['status'] as String? ?? 'modified';
              final shortStatus = status.startsWith('added')
                  ? 'A'
                  : (status.startsWith('removed')
                      ? 'D'
                      : (status.startsWith('renamed') ? 'R' : 'M'));
              changedFiles.add(
                GitHistoryFileChange(
                  status: shortStatus,
                  path: filename,
                  previousPath: f['previous_filename'] as String?,
                ),
              );
            }
          }
        }
      }

      // 4. Busca diff bruto
      final diffHeaders = {
        ...headers,
        'Accept': 'application/vnd.github.v3.diff',
      };
      final (diffCode, diffBody) = await _httpRequester('GET', prUri, diffHeaders, null);
      final diff = diffCode == 200 ? diffBody : '';

      return Success(
        GitPrDetail(
          pr: pr,
          comments: comments,
          changedFiles: changedFiles,
          diff: diff,
        ),
      );
    } catch (e) {
      return Failure('Erro ao obter detalhes do PR: $e');
    }
  }

  // ===========================================================================
  // 3. CRIAÇÃO DE PULL REQUEST
  // ===========================================================================

  /// Cria um novo Pull Request a partir da branch [headBranch].
  Future<Result<GitPullRequest, String>> createPullRequest(
    String repoRoot, {
    required String title,
    String body = '',
    required String headBranch,
    String baseBranch = 'main',
    bool draft = false,
  }) async {
    final origin = await _getOriginUrl(repoRoot);
    if (origin == null) {
      return const Failure('Nenhum remote "origin" configurado no repositório.');
    }

    final parsed = parseOwnerRepo(origin);
    if (parsed == null) {
      return Failure('Não foi possível identificar owner/repo da URL: $origin');
    }

    final (owner, repo) = parsed;
    final token = _resolveToken();
    if (token == null) {
      return const Failure(
        'Autenticação necessária para criar Pull Request: configure GITHUB_TOKEN.',
      );
    }

    final uri = Uri.parse('https://api.github.com/repos/$owner/$repo/pulls');
    final headers = {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'OrkestCode-IDE',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final payload = jsonEncode({
      'title': title,
      'body': body,
      'head': headBranch,
      'base': baseBranch,
      'draft': draft,
    });

    try {
      final (code, respBody) = await _httpRequester('POST', uri, headers, payload);
      if (code == 201) {
        final pr = GitPullRequest.fromJson(jsonDecode(respBody) as Map<String, dynamic>);
        return Success(pr);
      }
      return Failure('Falha ao criar PR (HTTP $code): $respBody');
    } catch (e) {
      return Failure('Erro na criação do PR: $e');
    }
  }

  // ===========================================================================
  // 4. CHECKOUT LOCAL DE PULL REQUEST
  // ===========================================================================

  /// Faz o fetch e checkout da branch de um Pull Request para revisão local no editor.
  Future<Result<void, String>> checkoutPullRequest(
    String repoRoot,
    int number,
  ) async {
    final gitExe = await _gitBinary.resolve();
    final localBranch = 'pr-$number';

    try {
      // 1. Fetch da ref do PR
      final fetchRes = await Process.run(
        gitExe,
        ['-C', repoRoot, 'fetch', 'origin', 'pull/$number/head:$localBranch', '--force'],
      );

      if (fetchRes.exitCode != 0) {
        return Failure(
          'Falha ao obter dados do PR remoto: ${fetchRes.stderr.toString().trim()}',
        );
      }

      // 2. Checkout da branch local
      final checkoutRes = await Process.run(
        gitExe,
        ['-C', repoRoot, 'checkout', localBranch],
      );

      if (checkoutRes.exitCode != 0) {
        return Failure(
          'Falha no checkout da branch $localBranch: ${checkoutRes.stderr.toString().trim()}',
        );
      }

      return const Success(null);
    } catch (e) {
      return Failure('Erro ao realizar checkout do PR: $e');
    }
  }

  // ===========================================================================
  // 5. ADICIONAR COMENTÁRIO DE REVISÃO
  // ===========================================================================

  /// Adiciona um comentário no Pull Request.
  Future<Result<GitPrComment, String>> addComment(
    String repoRoot, {
    required int number,
    required String body,
    String? commitId,
    String? path,
    int? line,
  }) async {
    final origin = await _getOriginUrl(repoRoot);
    if (origin == null) {
      return const Failure('Nenhum remote "origin" configurado no repositório.');
    }

    final parsed = parseOwnerRepo(origin);
    if (parsed == null) {
      return Failure('Não foi possível identificar owner/repo da URL: $origin');
    }

    final (owner, repo) = parsed;
    final token = _resolveToken();
    if (token == null) {
      return const Failure('Autenticação necessária para comentar: configure GITHUB_TOKEN.');
    }

    final isInline = path != null && line != null && commitId != null;
    final endpoint = isInline
        ? 'https://api.github.com/repos/$owner/$repo/pulls/$number/comments'
        : 'https://api.github.com/repos/$owner/$repo/issues/$number/comments';

    final headers = {
      'Accept': 'application/vnd.github+json',
      'User-Agent': 'OrkestCode-IDE',
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    };

    final payloadMap = <String, dynamic>{'body': body};
    if (isInline) {
      payloadMap['commit_id'] = commitId;
      payloadMap['path'] = path;
      payloadMap['line'] = line;
    }

    try {
      final (code, respBody) = await _httpRequester(
        'POST',
        Uri.parse(endpoint),
        headers,
        jsonEncode(payloadMap),
      );

      if (code == 201) {
        final comment = GitPrComment.fromJson(
          jsonDecode(respBody) as Map<String, dynamic>,
        );
        return Success(comment);
      }
      return Failure('Falha ao adicionar comentário (HTTP $code): $respBody');
    } catch (e) {
      return Failure('Erro ao enviar comentário: $e');
    }
  }

  // ===========================================================================
  // IMPLEMENTAÇÃO HTTP DEFAULT VIA DART:IO HTTPCLIENT
  // ===========================================================================

  static Future<(int, String)> _defaultHttpRequester(
    String method,
    Uri uri,
    Map<String, String> headers,
    String? body,
  ) async {
    final client = HttpClient();
    try {
      final req = await client.openUrl(method, uri);
      headers.forEach(req.headers.set);

      if (body != null) {
        req.write(body);
      }

      final resp = await req.close();
      final respBody = await resp.transform(utf8.decoder).join();
      return (resp.statusCode, respBody);
    } finally {
      client.close();
    }
  }
}
