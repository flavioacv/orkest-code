import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';

enum GitDiffTarget {
  head,
  workingTree,
  staged;

  static GitDiffTarget fromName(Object? name) =>
      values.firstWhere((target) => target.name == name, orElse: () => head);
}

/// Lê comparações de HEAD, Index e Working Tree para o viewer de diffs.
///
/// A implementação que executa Git mora em `data/`.
abstract class GitDiffReader {
  /// Diff de [absPath] em [repoPath], conforme a comparação [target].
  /// Trata novo (tudo adicionado), deletado (tudo removido), binário e sem
  /// mudança. Nunca lança — falhas do Git devolvem [FileDiffKind.error].
  Future<FileDiff> read(
    String repoPath,
    String absPath, {
    GitDiffTarget target = GitDiffTarget.head,
  });

  /// Diff de [relativePath] introduzido por [commitHash].
  Future<FileDiff> readCommit(
    String repoPath,
    String commitHash,
    String relativePath, {
    String? previousRelativePath,
  });
}
