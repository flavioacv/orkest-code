import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';

/// Resultado estruturado da comparação entre duas revisões Git (branches, tags ou commits).
class GitComparison {
  const GitComparison({
    required this.baseRef,
    required this.targetRef,
    required this.commits,
    required this.changedFiles,
  });

  /// Referência base da comparação (ex: `main` ou commit ancestral).
  final String baseRef;

  /// Referência de destino da comparação (ex: `feature/nova-tela` ou `HEAD`).
  final String targetRef;

  /// Lista de commits exclusivos de [targetRef] em relação a [baseRef].
  final List<GitHistoryCommit> commits;

  /// Arquivos modificados, adicionados ou removidos entre [baseRef] e [targetRef].
  final List<GitHistoryFileChange> changedFiles;

  /// Quantidade total de commits divergentes.
  int get commitCount => commits.length;

  /// Quantidade de arquivos com modificações.
  int get fileCount => changedFiles.length;
}
