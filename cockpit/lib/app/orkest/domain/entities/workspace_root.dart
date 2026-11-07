import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';

/// Uma pasta-raiz de um projeto no workspace. Projetos simples têm 1;
/// monorepos / workspaces multi-pasta têm 2+. O git é independente por root.
class WorkspaceRoot {
  const WorkspaceRoot({
    required this.path,
    required this.name,
    this.git,
  });

  /// Caminho absoluto da pasta no disco (ou no host remoto).
  final String path;

  /// Nome de exibição (normalmente o basename da pasta).
  final String name;

  /// Estado do repositório Git sob esta pasta, ou `null` se não for repo.
  final GitInfo? git;
}
