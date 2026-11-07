import 'package:orkest_code/app/orkest/domain/contracts/git_diff_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/ui/session/pane_item.dart';
import 'package:path/path.dart' as p;

/// Uma aba de **diff** read-only (split, estilo VSCode): mostra o arquivo em
/// [path] comparado com HEAD, Index ou Working Tree. O conteúdo
/// ([diff]) já vem parseado pela VM.
class DiffViewerSession extends PaneItem {
  DiffViewerSession({
    required this.id,
    required this.projectId,
    required this.path,
    required this.diff,
    this.commitHash,
    this.repoRoot,
    this.previousRelativePath,
    this.isPreview = false,
    bool isStaged = false,
    GitDiffTarget? target,
    this.onStageHunk,
    this.onUnstageHunk,
    this.onDiscardHunk,
  }) : target =
           target ?? (isStaged ? GitDiffTarget.staged : GitDiffTarget.head);

  @override
  final String id;
  @override
  final String projectId;

  /// Caminho absoluto do arquivo comparado. **Mutável** pra reutilizar a aba de
  /// preview (a VM re-lê o diff e reatribui).
  String path;

  /// O diff parseado — **mutável** (preview reuse).
  FileDiff diff;

  /// `null` para comparações locais; hash para um diff histórico.
  String? commitHash;

  /// Raiz dona do arquivo, preservada para restaurar a comparação fielmente.
  String? repoRoot;

  /// Caminho anterior de um rename/copy, relativo a [repoRoot].
  String? previousRelativePath;

  GitDiffTarget target;

  /// `true` se este diff representa alterações preparadas no index (`git diff --cached`).
  bool get isStaged => target == GitDiffTarget.staged;
  set isStaged(bool value) =>
      target = value ? GitDiffTarget.staged : GitDiffTarget.head;

  /// Ações interativas granulares por hunk (G01).
  Future<void> Function(DiffHunk hunk)? onStageHunk;
  Future<void> Function(DiffHunk hunk)? onUnstageHunk;
  Future<void> Function(DiffHunk hunk)? onDiscardHunk;

  // `package:path`, não corte no `/`: no Windows o path pode vir com `\`.
  @override
  String get title =>
      '${p.basename(path)} (${target == GitDiffTarget.head
          ? 'diff'
          : target == GitDiffTarget.staged
          ? 'Index diff'
          : 'Working tree diff'})';

  @override
  String get workingDirectory => p.dirname(path);

  /// `true` se é aba de preview (sobrescrita ao abrir outro diff; duplo-clique
  /// fixa).
  bool isPreview;

  void pin() {
    if (!isPreview) return;
    isPreview = false;
    notifyListeners();
  }
}
