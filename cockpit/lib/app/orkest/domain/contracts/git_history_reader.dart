import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_comparison.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';

/// Lê commits estruturados, autoria (blame) e comparações para a visualização History.
abstract class GitHistoryReader {
  /// Busca até [limit] commits com suporte a paginação e filtros via [query].
  /// Nunca interpreta a saída visual de `git log --graph`.
  Future<Result<List<GitHistoryCommit>, GitHistoryError>> read(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    GitHistoryQuery? query,
  });

  /// Lista os arquivos alterados por [commitHash], sob demanda.
  Future<Result<List<GitHistoryFileChange>, GitHistoryError>> readFiles(
    String repoPath,
    String commitHash,
  );

  /// Lê as informações de autoria (`git blame`) de um arquivo ou intervalo de linhas.
  Future<Result<List<GitBlameHunk>, GitHistoryError>> readBlame(
    String repoPath,
    String filePath, {
    int? lineStart,
    int? lineEnd,
  });

  /// Compara duas referências Git (branches, tags ou revisões), retornando commits e arquivos divergentes.
  Future<Result<GitComparison, GitHistoryError>> compareRefs(
    String repoPath,
    String baseRef,
    String targetRef,
  );
}
