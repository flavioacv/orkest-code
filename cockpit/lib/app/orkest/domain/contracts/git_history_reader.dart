import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';

/// Le commits estruturados para a visualizacao History.
abstract class GitHistoryReader {
  /// Busca ate [limit] commits da branch atualmente aberta nessa worktree.
  /// Nunca interpreta a saida visual de `git log --graph`.
  Future<Result<List<GitHistoryCommit>, GitHistoryError>> read(
    String repoPath, {
    int limit = 100,
  });

  /// Lista os arquivos alterados por [commitHash], sob demanda.
  Future<Result<List<GitHistoryFileChange>, GitHistoryError>> readFiles(
    String repoPath,
    String commitHash,
  );
}
