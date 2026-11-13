import 'package:orkest_code/app/orkest/domain/entities/git_command_log.dart';
import 'dart:async';
import 'dart:collection';
import 'dart:io'
    show
        Directory,
        File,
        FileSystemEntity,
        FileSystemEntityType,
        FileSystemEvent,
        Platform;

import 'package:orkest_code/app/orkest/domain/contracts/git_command_runner.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_status_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_stash_entry.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_tag_entry.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/domain/services/git_hunk_service.dart';
import 'package:orkest_code/app/orkest/domain/services/git_work_service.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/core/data/diagnostics/performance_diagnostics.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

typedef DirectoryWatch = Stream<FileSystemEvent> Function(String path);

/// Estado git do shell, extraído do `OrkestViewModel` (refactor 2026-07-19):
/// info/árvore por **root path**, roots derivadas por projeto, watcher de
/// filesystem do projeto selecionado, poll de segurança e comandos git.
///
/// Não conhece `Project` nem panes — o VM dono injeta o contexto que precisa
/// (path/gates/alvos de poll) pelos campos de callback abaixo, logo após a
/// construção. Worktrees e diff viewer seguem no VM (mexem em projeto/pane).
class GitController extends ChangeNotifier {
  GitController(
    this._reader,
    this._runner,
    this._activity, {
    GitHunkService? hunkService,
    DirectoryWatch? directoryWatch,
    this._watchRetryDelay = const Duration(milliseconds: 500),
    this._fileTreeDebounce = const Duration(milliseconds: 400),
    this._fileTreeMaxLatency = const Duration(seconds: 2),
  }) : _hunkService = hunkService ?? const GitHunkService(),
       _directoryWatch = directoryWatch ?? _defaultDirectoryWatch {
    _activity.addListener(_onActivityChanged);
  }

  bool _closed = false;
  final GitStatusReader _reader;
  final GitCommandRunner _runner;
  final WindowActivityController _activity;
  final DirectoryWatch _directoryWatch;
  final Duration _watchRetryDelay;

  /// Debounce do bump da árvore (junta a rajada) e o teto: com eventos
  /// estruturais chegando sem parar (build, `pub get`, agente escrevendo em
  /// `.dart_tool/`), um debounce puro era rearmado a cada evento e **nunca**
  /// disparava — arquivo criado na raiz só aparecia quando a rajada acabava.
  final Duration _fileTreeDebounce;
  final Duration _fileTreeMaxLatency;

  static Stream<FileSystemEvent> _defaultDirectoryWatch(String path) =>
      Directory(path).watch(recursive: true);

  // ---- contexto injetado pelo VM dono (mesma vida page-scoped) -------------

  /// Path do projeto, ou `null` se o projeto não existe.
  String? Function(String projectId)? resolvePath;

  /// `true` se o projeto é o workspace de sistema "Orkest" (sem pasta).
  bool Function(String projectId)? isSystemTerminal;

  /// Projeto atualmente selecionado (guia watcher/poll).
  String? Function()? selectedProjectId;

  /// Ids a re-ler no poll (família visível: raiz do selecionado + forks).
  List<String> Function()? pollTargets;

  /// Evento **estrutural** (create/delete/move) fora do `.git/` no working
  /// tree observado — o VM bumpa a revisão da árvore de arquivos.
  VoidCallback? onStructuralFsChange;

  /// Disparado uma vez por tick do poll — o VM dono reconcilia as worktrees
  /// (que o GitController não conhece) contra o git. Só notifica se a lista mudou.
  VoidCallback? onPoll;

  // ---- estado ---------------------------------------------------------------

  /// Estado git por **root path** (branch + sujos). Para workspace single-root
  /// a chave coincide com o `Project.id` (id == path), então o comportamento é
  /// o histórico. Num multi-root há uma entrada por root; a pasta-mãe não tem
  /// entrada própria. `null` = a root não é repo git.
  final Map<String, GitInfo?> _gitInfo = <String, GitInfo?>{};

  /// Status git por **caminho relativo à root** (arquivos + pastas agregadas),
  /// por root path. Derivado de [_gitInfo]; alimenta a coloração da árvore de
  /// arquivos. Pasta agrega o estado mais forte dos descendentes
  /// ([GitFileStatus.strongest]).
  final Map<String, Map<String, GitFileStatus>> _gitTree =
      <String, Map<String, GitFileStatus>>{};

  /// Roots git derivadas por projeto (**runtime, nunca persistido** — a
  /// existência mora no filesystem, mesmo espírito das worktrees/plano 42).
  /// Regra implícita: raiz com `.git` → `[path]` (single-root, caso histórico);
  /// raiz sem `.git` → filhas imediatas com `.git` (multi-root/multirepo);
  /// nenhuma → `[path]` (pasta comum). Reavaliado a cada [refresh].
  final Map<String, List<String>> _rootsByProject = <String, List<String>>{};

  /// Sobe quando uma leitura detecta mudanca git; consumidores read-only usam
  /// este token para recarregar dados derivados, como o historico de commits.
  int _revision = 0;
  int get revision => _revision;

  /// Invalida consumidores derivados quando uma operacao git concluiu mas o
  /// status por arquivos continuou igual (por exemplo, um fast-forward limpo).
  void markHistoryStale() {
    _revision++;
    notifyListeners();
  }

  /// Watcher do working tree do projeto **selecionado** (filesystem ao vivo).
  /// Recriado ao trocar de projeto; debounce junta rajadas de eventos.
  StreamSubscription<FileSystemEvent>? _gitWatch;
  Timer? _gitWatchDebounce;
  Timer? _gitWatchRetry;
  String? _gitWatchPath;

  /// Debounce próprio da árvore de arquivos: eventos **estruturais**
  /// (create/delete/move) fora do `.git/` disparam [onStructuralFsChange] pra
  /// árvore reler as pastas abertas — cobre arquivos criados/removidos por
  /// fora (Finder, agente, scripts) sem exigir Refresh manual. Separado do
  /// [_gitWatchDebounce] pra um modify (que não muda a árvore) não segurar
  /// o bump nem vice-versa.
  Timer? _fileTreeWatchDebounce;

  /// Quando a rajada estrutural em curso começou (pra aplicar o teto).
  DateTime? _fileTreeBurstStart;

  /// Poll de segurança do git. O `_gitWatch` só cobre o projeto **selecionado**
  /// e o `Directory.watch(recursive:)` do macOS coalesce/perde eventos (e forks
  /// de worktree, cujo `index`/`HEAD` moram fora do working tree, nem sempre
  /// disparam evento). Sem isso a rail fica desatualizada até o usuário trocar
  /// de workspace e voltar. Relê o git dos [pollTargets] periodicamente;
  /// [refresh] só notifica quando algo mudou, então o custo em UI é nulo em
  /// repos parados.
  Timer? _gitPoll;
  bool _pollRequested = false;
  String? _watchedProjectId;
  static const Duration _gitPollInterval = Duration(seconds: 3);
  final GitRefreshScheduler _refreshScheduler = GitRefreshScheduler();

  // ---- leitura --------------------------------------------------------------

  /// Roots git do projeto. Sempre não-vazio: single-root = `[path]`
  /// (comportamento histórico, N=1); multi-root = as filhas-repo derivadas.
  List<String> rootsOf(String projectId) {
    final derived = _rootsByProject[projectId];
    if (derived != null && derived.isNotEmpty) return derived;
    final p = resolvePath?.call(projectId);
    return p == null || p.isEmpty ? const [] : [p];
  }

  /// Estado git de uma **root** específica ([rootPath] absoluto).
  GitInfo? infoForRoot(String rootPath) => _gitInfo[rootPath];

  /// Estado git do projeto (branch + sujos), ou `null` se não for repo git.
  /// Em multi-root não existe "o" GitInfo do workspace — devolve `null` (a
  /// rail usa [rootsSummary] pro chip agregado).
  GitInfo? infoOf(String projectId) {
    final roots = rootsOf(projectId);
    if (roots.length != 1) return null;
    return _gitInfo[roots.first];
  }

  /// Agregado pro chip da rail em multi-root: (nº de roots, roots com
  /// **alteração de arquivo**). Conta só `isDirty` — divergência de upstream
  /// (ahead/behind) NÃO entra, senão o chip acende "· 1" numa root só com
  /// commits não enviados/não puxados, sem nenhuma mudança de arquivo.
  (int roots, int dirtyRoots) rootsSummary(String projectId) {
    final roots = rootsOf(projectId);
    var dirty = 0;
    for (final r in roots) {
      final info = _gitInfo[r];
      if (info != null && info.isDirty) dirty++;
    }
    return (roots.length, dirty);
  }

  /// `true` se o workspace [projectId] tem git — single-root: a raiz é repo;
  /// multi-root: qualquer root (habilita a aba Source Control).
  bool isGitRepo(String projectId) =>
      rootsOf(projectId).any((r) => _gitInfo[r] != null);

  /// Status git (relativo à **root**) dos arquivos com mudança de uma root.
  Map<String, GitFileStatus> changedFilesOfRoot(String rootPath) {
    final info = _gitInfo[rootPath];
    if (info == null) return const {};
    return info.files;
  }

  /// Entradas no index, separadas para a seção **Staged Changes**.
  Map<String, GitFileStatus> stagedFilesOfRoot(String rootPath) =>
      _gitInfo[rootPath]?.stagedFiles ?? const {};

  /// Mudanças no working tree, separadas para a seção **Changes**.
  Map<String, GitFileStatus> unstagedFilesOfRoot(String rootPath) =>
      _gitInfo[rootPath]?.changedFiles ?? const {};

  /// Estado agregado de uma **root inteira** — o mais forte entre os arquivos
  /// sujos dela (mesma regra de pasta, [GitFileStatus.strongest]). Colore a
  /// própria pasta da root na árvore de arquivos em multi-root, onde o `.git`
  /// mora dentro da pasta e o caminho relativo dela seria vazio. `null` =
  /// limpa ou sem git.
  GitFileStatus? statusForRoot(String rootPath) {
    final info = _gitInfo[rootPath];
    if (info == null) return null;
    GitFileStatus? out;
    for (final s in info.files.values) {
      out = GitFileStatus.strongestForFolder(out, s);
    }
    return out ??
        (info.untrackedDirs.isNotEmpty ? GitFileStatus.untracked : null);
  }

  /// Status (cor) do caminho [rel] (relativo à [root]): mudança real do mapa
  /// agregado vence; senão herda untracked/ignored da raiz colapsada.
  GitFileStatus? statusForRelPath(String root, String rel) {
    if (rel.isEmpty) return null;
    final dirty = _gitTree[root]?[rel];
    if (dirty != null) return dirty;
    final info = _gitInfo[root];
    if (info == null) return null;
    if (info.isUntracked(rel)) return GitFileStatus.untracked;
    if (info.isIgnored(rel)) return GitFileStatus.ignored;
    return null;
  }

  // ---- comandos -------------------------------------------------------------

  /// Sync = `git pull` e, se OK, `git push` no repo em [repoPath]. Stream ao vivo.
  GitRun sync(String repoPath) => _observeRun(
    repoPath,
    _loggedRun(repoPath, const [
      'pull',
      '→',
      'push',
    ], () => _runner.syncPullPush(repoPath)),
  );

  /// `git pull` no repo em [repoPath].
  GitRun pull(String repoPath) => run(repoPath, const ['pull']);

  /// `git push` no repo em [repoPath].
  GitRun push(String repoPath) => run(repoPath, const ['push']);

  /// Atualiza refs remotas sem alterar o working tree.
  GitRun fetch(String repoPath) =>
      run(repoPath, const ['fetch', '--all', '--prune']);

  /// Executa uma operação Git estruturada pela interface avançada.
  GitRun run(String repoPath, List<String> args) => _observeRun(
    repoPath,
    _loggedRun(repoPath, args, () => _runner.run(repoPath, args)),
  );

  final List<GitCommandLog> _commandLogs = [];
  int _nextCommandId = 0;
  Timer? _consoleNotify;
  List<GitCommandLog> get commandLogs => List.unmodifiable(_commandLogs);

  void clearCommandLogs({String? root}) {
    if (root == null) {
      _commandLogs.clear();
    } else {
      _commandLogs.removeWhere((entry) => entry.root == root);
    }
    notifyListeners();
  }

  String _redactGitLog(String value) => value.replaceAllMapped(
    RegExp(r'(https?://)[^/\s@]+@'),
    (match) => '${match[1]}***@',
  );

  void _updateCommand(int id, GitCommandLog Function(GitCommandLog) update) {
    if (_closed) return;
    final index = _commandLogs.indexWhere((entry) => entry.id == id);
    if (index < 0) return;
    _commandLogs[index] = update(_commandLogs[index]);
    _consoleNotify ??= Timer(const Duration(milliseconds: 100), () {
      _consoleNotify = null;
      if (!_closed) notifyListeners();
    });
  }

  GitRun _loggedRun(String root, List<String> args, GitRun Function() start) {
    final id = ++_nextCommandId;
    if (_commandLogs.length >= 60) _commandLogs.removeAt(0);
    _commandLogs.add(
      GitCommandLog(
        id: id,
        root: root,
        command: _redactGitLog('git ${args.join(' ')}'),
        startedAt: DateTime.now(),
      ),
    );
    final forwarded = StreamController<String>();
    try {
      final process = start();
      process.output.listen(
        (line) {
          _updateCommand(
            id,
            (entry) => entry.copyWith(
              lines: [
                ...entry.lines.skip(entry.lines.length >= 500 ? 1 : 0),
                _redactGitLog(line),
              ],
            ),
          );
          forwarded.add(line);
        },
        onError: (Object error, StackTrace stack) {
          forwarded.addError(error, stack);
        },
        onDone: forwarded.close,
      );
      final completed = process.exitCode.then(
        (code) {
          _updateCommand(
            id,
            (entry) =>
                entry.copyWith(exitCode: code, finishedAt: DateTime.now()),
          );
          return code;
        },
        onError: (Object error, StackTrace stack) {
          _updateCommand(
            id,
            (entry) => entry.copyWith(
              exitCode: -1,
              finishedAt: DateTime.now(),
              lines: [...entry.lines, _redactGitLog(error.toString())],
            ),
          );
          return -1;
        },
      );
      _updateCommand(id, (entry) => entry);
      return GitRun(output: forwarded.stream, exitCode: completed);
    } on Exception catch (error) {
      forwarded.add(error.toString());
      unawaited(forwarded.close());
      _updateCommand(
        id,
        (entry) => entry.copyWith(exitCode: -1, finishedAt: DateTime.now()),
      );
      return GitRun(output: forwarded.stream, exitCode: Future.value(-1));
    }
  }

  GitRun _observeRun(String root, GitRun process) {
    // Refresh on completion, including conflicts, without waiting for the log dialog.
    final completed = process.exitCode.then((code) async {
      if (_closed) return code;
      markHistoryStale();
      for (final entry in _rootsByProject.entries.toList()) {
        if (entry.value.contains(root)) await refresh(entry.key);
      }
      return code;
    });
    return GitRun(output: process.output, exitCode: completed);
  }

  /// Roda um comando e coleta a saída para consumidores que precisam ler o
  /// resultado (por exemplo, o seletor de commits de amend).
  Future<(int code, String output)> output(
    String root,
    List<String> args,
  ) async {
    final run = _runner.run(root, args);
    final lines = <String>[];
    final sub = run.output.listen(lines.add);
    final code = await run.exitCode;
    await sub.cancel();
    return (code, lines.join('\n'));
  }

  /// Roda um git rápido e devolve `null` (exit 0) ou a saída como erro.
  Future<String?> collect(String root, List<String> args) async {
    final run = _loggedRun(root, args, () => _runner.run(root, args));
    final lines = <String>[];
    final sub = run.output.listen(lines.add);
    final code = await run.exitCode;
    await sub.cancel();
    return code == 0 ? null : lines.join('\n');
  }

  Future<void> refreshRepository(String root) async {
    final info = await _reader.read(root);
    if (_closed) return;
    _gitInfo[root] = info;
    _gitTree[root] = _buildGitTree(info?.files);
    markHistoryStale();
  }

  /// Lista refs locais e remotas que podem ser selecionadas no checkout.
  Future<Result<List<GitBranch>, GitBranchError>> branches(String root) async {
    final result = await output(root, const [
      'for-each-ref',
      '--format=%(refname)\t%(HEAD)\t%(upstream:short)\t%(upstream:track)',
      'refs/heads',
      'refs/remotes',
    ]);
    if (result.$1 != 0) {
      return Failure(
        GitBranchError(GitBranchErrorKind.listFailed, detail: result.$2),
      );
    }
    final branches = <GitBranch>[];
    final worktrees = await output(root, const [
      'worktree',
      'list',
      '--porcelain',
      '-z',
    ]);
    if (worktrees.$1 != 0) {
      return Failure(
        GitBranchError(GitBranchErrorKind.listFailed, detail: worktrees.$2),
      );
    }
    final used = <String, String>{};
    String? worktreePath;
    for (final line in worktrees.$2.split('\u0000')) {
      if (line.startsWith('worktree ')) worktreePath = line.substring(9);
      if (line.startsWith('branch refs/heads/') && worktreePath != null) {
        used[line.substring('branch refs/heads/'.length)] = worktreePath;
      }
    }
    for (final line in result.$2.split('\n')) {
      final fields = line.split('\t');
      if (fields.isEmpty ||
          fields.first.isEmpty ||
          fields.first.endsWith('/HEAD')) {
        continue;
      }
      final isRemote = fields.first.startsWith('refs/remotes/');
      final name = fields.first.replaceFirst(
        RegExp(r'^refs/(heads|remotes)/'),
        '',
      );
      branches.add(
        GitBranch(
          name: name,
          isRemote: isRemote,
          isCurrent: fields.length > 1 && fields[1] == '*',
          isUsedByWorktree: !isRemote && used.containsKey(name),
          worktreePath: isRemote ? null : used[name],
          upstream: fields.length > 2 && fields[2].isNotEmpty
              ? fields[2]
              : null,
          trackingStatus: fields.length > 3 && fields[3].isNotEmpty
              ? fields[3]
              : null,
        ),
      );
    }
    branches.sort((a, b) {
      if (a.isCurrent != b.isCurrent) return a.isCurrent ? -1 : 1;
      if (a.isRemote != b.isRemote) return a.isRemote ? 1 : -1;
      return a.name.compareTo(b.name);
    });
    return Success(branches);
  }

  /// Troca de branch sem forçar mudanças locais. Para refs remotas, cria a
  /// branch local rastreada quando ela ainda não existe.
  Future<Result<void, GitBranchError>> checkoutBranch(
    String root,
    GitBranch branch,
  ) async {
    // Re-read the actual refs/worktrees instead of trusting a dialog snapshot.
    final listed = await branches(root);
    if (listed case Failure(:final error)) return Failure(error);
    final refs = listed.fold((value) => value, (_) => <GitBranch>[]);
    final selected = refs.where((ref) => ref.ref == branch.ref).firstOrNull;
    if (selected == null) {
      return const Failure(GitBranchError(GitBranchErrorKind.missingRef));
    }
    if (selected.isCurrent) return const Success(null);
    if (selected.isUsedByWorktree) {
      return Failure(
        GitBranchError(GitBranchErrorKind.inUse, detail: selected.worktreePath),
      );
    }
    if (selected.isRemote) {
      final tracking = refs
          .where((b) => !b.isRemote && b.upstream == selected.name)
          .toList();
      if (tracking.length > 1) {
        return Failure(
          GitBranchError(
            GitBranchErrorKind.ambiguousTracking,
            detail: tracking.map((b) => b.name).join(', '),
          ),
        );
      }
      if (tracking.length == 1) return checkoutBranch(root, tracking.single);
      final localName = selected.name.substring(selected.name.indexOf('/') + 1);
      if (refs.any((b) => !b.isRemote && b.name == localName)) {
        return Failure(
          GitBranchError(
            GitBranchErrorKind.localNameCollision,
            detail: localName,
          ),
        );
      }
    }
    final args = branch.isRemote
        ? [
            'switch',
            '--track',
            '-c',
            branch.name.substring(branch.name.indexOf('/') + 1),
            branch.name,
          ]
        : ['switch', '--', branch.name];
    final error = await collect(root, args);
    if (error == null) return const Success(null);
    return Failure(_branchError(error, create: false));
  }

  /// Cria uma branch local a partir do HEAD e já a seleciona.
  Future<Result<void, GitBranchError>> createBranch(
    String root,
    String name, {
    String? startPoint,
  }) async {
    final normalized = name.trim();
    if (normalized.isEmpty ||
        normalized.startsWith('-') ||
        normalized.contains(' ') ||
        normalized.contains('..')) {
      return const Failure(GitBranchError(GitBranchErrorKind.invalidName));
    }
    final validation = await output(root, [
      'check-ref-format',
      '--branch',
      normalized,
    ]);
    if (validation.$1 != 0) {
      return const Failure(GitBranchError(GitBranchErrorKind.invalidName));
    }
    if (startPoint != null &&
        (startPoint.startsWith('-') || startPoint.isEmpty)) {
      return const Failure(GitBranchError(GitBranchErrorKind.invalidName));
    }
    final error = await collect(root, [
      'switch',
      '-c',
      normalized,
      ?startPoint,
    ]);
    if (error == null) return const Success(null);
    return Failure(_branchError(error, create: true));
  }

  GitBranchError _branchError(String detail, {required bool create}) {
    final lower = detail.toLowerCase();
    if (lower.contains('would be overwritten') ||
        lower.contains('local changes')) {
      return GitBranchError(GitBranchErrorKind.dirtyWorktree, detail: detail);
    }
    if (lower.contains('already exists')) {
      return GitBranchError(GitBranchErrorKind.alreadyExists, detail: detail);
    }
    return GitBranchError(
      create
          ? GitBranchErrorKind.createFailed
          : GitBranchErrorKind.checkoutFailed,
      detail: detail,
    );
  }

  // ---- staging e unstage por hunk (G01) -------------------------------------

  final GitHunkService _hunkService;

  /// Aplica o hunk no index do Git (`git apply --cached -`).
  Future<Result<void, String>> stageHunk({
    required String root,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
  }) async {
    final result = await _hunkService.stageHunk(
      repoRoot: root,
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Remove o hunk do index do Git (`git apply --cached --reverse -`).
  Future<Result<void, String>> unstageHunk({
    required String root,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
  }) async {
    final result = await _hunkService.unstageHunk(
      repoRoot: root,
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Descarta as mudanças do hunk diretamente no working tree (`git apply --reverse -`).
  Future<Result<void, String>> discardHunk({
    required String root,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
  }) async {
    final result = await _hunkService.discardHunk(
      repoRoot: root,
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  // ---- resolução de conflitos e operações Git (G02) -------------------------

  final GitConflictService _conflictService = const GitConflictService();

  /// Detecta se há uma operação Git em andamento (merge, rebase, cherry-pick ou revert).
  GitOngoingOperation detectOngoingOperation(String root) =>
      _conflictService.detectOngoingOperation(root);

  /// Continua a operação Git em andamento (`git merge --continue`, `git rebase --continue`, etc).
  Future<Result<void, String>> continueOperation(String root) async {
    final result = await _conflictService.continueOperation(repoRoot: root);
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Aborta a operação Git em andamento (`git merge --abort`, `git rebase --abort`, etc).
  Future<Result<void, String>> abortOperation(String root) async {
    final result = await _conflictService.abortOperation(repoRoot: root);
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  // ---- gestão avançada de trabalho Git (G04) --------------------------------

  final GitWorkService _workService = GitWorkService();

  /// Lista stashes disponíveis no repositório.
  Future<Result<List<GitStashEntry>, String>> listStashes(String root) =>
      _workService.listStashes(root);

  /// Salva alterações não commitadas no stash (shelf).
  Future<Result<void, String>> stashPush(
    String root, {
    String? message,
    bool includeUntracked = false,
    bool keepIndex = false,
  }) async {
    final result = await _workService.stashPush(
      root,
      message: message,
      includeUntracked: includeUntracked,
      keepIndex: keepIndex,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Aplica o stash e o remove da lista.
  Future<Result<void, String>> stashPop(String root, {int index = 0}) async {
    final result = await _workService.stashPop(root, index: index);
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Aplica o stash preservando-o na lista.
  Future<Result<void, String>> stashApply(String root, {int index = 0}) async {
    final result = await _workService.stashApply(root, index: index);
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Descarta um stash permanentemente.
  Future<Result<void, String>> stashDrop(String root, {int index = 0}) =>
      _workService.stashDrop(root, index: index);

  /// Visualiza o diff textual do stash indicado.
  Future<Result<String, String>> stashDiff(String root, {int index = 0}) =>
      _workService.stashDiff(root, index: index);

  /// Lista todas as tags locais.
  Future<Result<List<GitTagEntry>, String>> listTags(String root) =>
      _workService.listTags(root);

  /// Cria uma tag local anotada ou leve.
  Future<Result<void, String>> createTag(
    String root, {
    required String name,
    String? commitHash,
    String? message,
    bool annotated = false,
  }) async {
    final result = await _workService.createTag(
      root,
      name: name,
      commitHash: commitHash,
      message: message,
      annotated: annotated,
    );
    if (result.isSuccess) {
      markHistoryStale();
    }
    return result;
  }

  /// Remove uma tag local.
  Future<Result<void, String>> deleteTag(
    String root, {
    required String name,
  }) async {
    final result = await _workService.deleteTag(root, name: name);
    if (result.isSuccess) {
      markHistoryStale();
    }
    return result;
  }

  /// Cria um patch unificado com as alterações do repositório.
  Future<Result<String, String>> createPatch(
    String root, {
    String? fromCommit,
    String? toCommit,
    List<String>? filePaths,
    bool staged = false,
  }) => _workService.createPatch(
    root,
    fromCommit: fromCommit,
    toCommit: toCommit,
    filePaths: filePaths,
    staged: staged,
  );

  /// Aplica um patch unificado no repositório com suporte a verificação prévia (`checkOnly`).
  Future<Result<void, String>> applyPatch(
    String root, {
    required String patchContent,
    bool checkOnly = false,
    bool reverse = false,
  }) async {
    final result = await _workService.applyPatch(
      root,
      patchContent: patchContent,
      checkOnly: checkOnly,
      reverse: reverse,
    );
    if (result.isSuccess && !checkOnly) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Executa cherry-pick de um commit isolado na branch atual.
  Future<Result<void, String>> cherryPick(
    String root, {
    required String commitHash,
    bool noCommit = false,
  }) async {
    final result = await _workService.cherryPick(
      root,
      commitHash: commitHash,
      noCommit: noCommit,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Reverte um commit criando um novo commit inverso.
  Future<Result<void, String>> revertCommit(
    String root, {
    required String commitHash,
    bool noCommit = false,
  }) async {
    final result = await _workService.revertCommit(
      root,
      commitHash: commitHash,
      noCommit: noCommit,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  /// Executa rebase da branch atual sobre o upstream especificado.
  Future<Result<void, String>> rebase(
    String root, {
    required String upstreamBranch,
  }) async {
    final result = await _workService.rebase(
      root,
      upstreamBranch: upstreamBranch,
    );
    if (result.isSuccess) {
      markHistoryStale();
      final pid = selectedProjectId?.call();
      if (pid != null) unawaited(refresh(pid));
    }
    return result;
  }

  // ---- ciclo de vida --------------------------------------------------------

  /// (Re)lê o estado git de um projeto e notifica se mudou. Chamado no boot
  /// (todos), ao selecionar e no fim de turno do agente (que pode ter mexido
  /// em arquivos). Reavalia as **roots** (implícitas, do filesystem) e lê o
  /// git de cada uma — single-root é o caso N=1 e se comporta como sempre.
  Future<void> refresh(String projectId) => _refreshScheduler.schedule(
    projectId,
    () => _refreshOnce(projectId),
    priority: selectedProjectId?.call() == projectId,
  );

  Future<void> _refreshOnce(String projectId) async {
    final path = resolvePath?.call(projectId);
    // Sink único de git — barra o Orkest (sem pasta) de uma vez: cobre o
    // watcher, o poll e o refresh manual/fim-de-turno.
    if (path == null || (isSystemTerminal?.call(projectId) ?? false)) return;

    final roots = deriveRoots(path);
    final oldRoots = _rootsByProject[projectId];
    final rootsChanged = !listEquals(oldRoots, roots);
    if (rootsChanged) {
      // Roots que sumiram (repo removido / .git criado na mãe) → limpa estado.
      for (final gone in (oldRoots ?? const <String>[]).where(
        (r) => !roots.contains(r),
      )) {
        _gitInfo.remove(gone);
        _gitTree.remove(gone);
      }
      _rootsByProject[projectId] = roots;
    }

    var changed = rootsChanged;
    for (final root in roots) {
      final info = await _reader.read(root);
      // Evita rebuild se nada mudou (branch + ahead/behind + mapa de arquivos).
      final old = _gitInfo[root];
      if (old == info) {
        _gitInfo[root] = info; // garante a chave mesmo sem mudança visível
        continue;
      }
      _gitInfo[root] = info;
      _gitTree[root] = _buildGitTree(info?.files);
      changed = true;
    }
    if (changed) {
      _revision++;
      notifyListeners();
    }
  }

  /// Descarta o estado git de um projeto removido (chaveado por root path).
  void forget(String projectId) {
    for (final root in _rootsByProject[projectId] ?? [projectId]) {
      _gitInfo.remove(root);
      _gitTree.remove(root);
    }
    _rootsByProject.remove(projectId);
  }

  /// (Re)inicia o watcher de filesystem do projeto **selecionado** → mantém a
  /// árvore/branch atualizadas ao vivo conforme o disco muda (o agente edita
  /// arquivos, troca de branch, comita). No-op se já observa esse mesmo path.
  void watchProject(String? projectId) {
    _watchedProjectId = projectId;
    if (!_activity.isActive) {
      _cancelWatch();
      return;
    }
    // Orkest não tem pasta → nunca observa (evita `Directory('').watch`).
    if (projectId != null && (isSystemTerminal?.call(projectId) ?? false)) {
      _gitWatch?.cancel();
      _gitWatchDebounce?.cancel();
      _gitWatchRetry?.cancel();
      _gitWatch = null;
      _gitWatchPath = null;
      return;
    }
    final path = projectId == null ? null : resolvePath?.call(projectId);
    if (path == _gitWatchPath) return; // já observando este projeto
    _gitWatch?.cancel();
    _gitWatchDebounce?.cancel();
    _gitWatchRetry?.cancel();
    _gitWatch = null;
    _gitWatchPath = path;
    if (path == null || projectId == null) return;
    try {
      _gitWatch = _directoryWatch(path).listen(
        (event) => _onFsEvent(projectId, event),
        // A subscription pode morrer sozinha (erro de FSEvents/inotify, limite
        // de FDs, dir recriada). O retry é atrasado: reabrir imediatamente uma
        // pasta removida cria um loop de erro/re-arm que monopoliza o event loop
        // (caso exato de remover a worktree selecionada no Linux release).
        onError: (_) => _scheduleWatchRetry(path),
        onDone: () => _scheduleWatchRetry(path),
        cancelOnError: true,
      );
    } catch (_) {
      _scheduleWatchRetry(path);
    }
  }

  /// Re-arma o watcher com backoff se a subscription do projeto [path] morreu.
  ///
  /// No Linux, observar uma pasta inexistente falha de forma assíncrona e
  /// imediata. Sem o atraso, `onError → watchProject → onError` vira um loop
  /// apertado que impede a UI e até a continuação de `git worktree remove` de
  /// rodarem. No disparo também recalculamos a seleção: durante o atraso a
  /// worktree removida pode ter devolvido o foco ao workspace pai.
  void _scheduleWatchRetry(String path) {
    if (_gitWatchPath != path) return; // já trocaram de projeto → ignora
    _gitWatch = null;
    _gitWatchRetry?.cancel();
    _gitWatchRetry = Timer(_watchRetryDelay, () {
      _gitWatchRetry = null;
      if (_gitWatchPath != path) return;
      final selected = selectedProjectId?.call();
      _gitWatchPath = null; // libera o guard de [watchProject]
      watchProject(selected);
      // O que aconteceu no disco entre a morte do watcher e o re-arm se
      // perdeu: relê a árvore pra não ficar com a raiz desatualizada.
      onStructuralFsChange?.call();
    });
  }

  /// (Re)inicia o poll periódico de git dos [pollTargets]. Ver [_gitPoll].
  void startPoll() {
    _pollRequested = true;
    _armPoll();
  }

  void _armPoll() {
    _gitPoll?.cancel();
    _gitPoll = null;
    if (!_pollRequested || !_activity.isActive) return;
    _gitPoll = Timer.periodic(_gitPollInterval, (_) => _pollTick());
  }

  void _pollTick() {
    if (!_activity.isActive) return;
    for (final id in pollTargets?.call() ?? const <String>[]) {
      unawaited(refresh(id));
    }
    onPoll?.call();
  }

  void _onActivityChanged() {
    if (!_activity.isActive) {
      _gitPoll?.cancel();
      _gitPoll = null;
      _cancelWatch();
      return;
    }
    watchProject(_watchedProjectId ?? selectedProjectId?.call());
    _armPoll();
    if (_pollRequested) _pollTick();
    // Enquanto a janela esteve sem foco o watcher ficou desligado: tudo que
    // nasceu/sumiu no disco nesse intervalo passou batido. Relê a árvore ao
    // voltar — era a causa clássica do "criei na raiz e não apareceu".
    onStructuralFsChange?.call();
  }

  void _cancelWatch() {
    _gitWatch?.cancel();
    _gitWatchDebounce?.cancel();
    _gitWatchRetry?.cancel();
    _fileTreeWatchDebounce?.cancel();
    _fileTreeBurstStart = null;
    _gitWatch = null;
    _gitWatchPath = null;
  }

  /// Evento de filesystem do watcher. Filtra o ruído interno do `.git/` (o
  /// próprio `git status` mexe em `index.lock` etc. → loop), exceto `HEAD` e
  /// `index`, que sinalizam checkout/commit/staging. Debounce junta rajadas.
  void _onFsEvent(String projectId, FileSystemEvent event) {
    final p = event.path.replaceAll('\\', '/');
    final gitIdx = p.indexOf('/.git/');
    if (gitIdx != -1) {
      final rest = p.substring(gitIdx + 6); // depois de '/.git/'
      if (rest != 'HEAD' && rest != 'index') return;
    } else if (event.type == FileSystemEvent.create ||
        event.type == FileSystemEvent.delete ||
        event.type == FileSystemEvent.move) {
      // Mudança estrutural no working tree → árvore de arquivos relê as
      // pastas abertas (modify não muda a estrutura, só o conteúdo).
      _scheduleFileTreeBump();
    }
    _gitWatchDebounce?.cancel();
    _gitWatchDebounce = Timer(const Duration(milliseconds: 400), () {
      unawaited(refresh(projectId));
    });
  }

  /// Debounce com teto: rearma a cada evento, mas se a rajada já dura
  /// [_fileTreeMaxLatency] dispara agora e começa uma rajada nova.
  void _scheduleFileTreeBump() {
    final now = DateTime.now();
    final start = _fileTreeBurstStart ??= now;
    if (now.difference(start) >= _fileTreeMaxLatency) {
      _fireFileTreeBump();
      return;
    }
    _fileTreeWatchDebounce?.cancel();
    _fileTreeWatchDebounce = Timer(_fileTreeDebounce, _fireFileTreeBump);
  }

  void _fireFileTreeBump() {
    _fileTreeWatchDebounce?.cancel();
    _fileTreeWatchDebounce = null;
    _fileTreeBurstStart = null;
    onStructuralFsChange?.call();
  }

  /// Deriva as roots git de uma pasta (síncrono, raso — só `existsSync`):
  /// - `path/.git` existe (dir **ou arquivo** — worktrees usam arquivo) →
  ///   `[path]` (single-root; monorepo é isso, N=1).
  /// - senão, filhas imediatas com `.git` → multi-root (assinatura de multirepo).
  /// - nenhuma → `[path]` (pasta comum, sem git — comportamento atual).
  ///
  /// Filha que é **worktree linkada de um repo-irmão** NÃO vira root: ela já
  /// aparece como fork da irmã (via `git worktree list`); promovê-la a root
  /// fazia o mesmo worktree ser descoberto duas vezes e duplicava o fork na
  /// rail. Worktree de repo de **fora** do workspace segue sendo root (é a
  /// única presença daquele repo aqui).
  @visibleForTesting
  static List<String> deriveRoots(String path) {
    if (path.isEmpty) return const [];
    if (FileSystemEntity.typeSync('$path/.git') !=
        FileSystemEntityType.notFound) {
      return [path];
    }
    // O porcelain retorna paths relativos ao repositório, mesmo com -C numa
    // subpasta. Usar essa subpasta como root duplicaria o prefixo no restore.
    var ancestor = p.dirname(p.normalize(p.absolute(path)));
    while (true) {
      if (FileSystemEntity.typeSync(p.join(ancestor, '.git')) !=
          FileSystemEntityType.notFound) {
        return [p.posix.joinAll(p.split(ancestor))];
      }
      final parent = p.dirname(ancestor);
      if (parent == ancestor) break;
      ancestor = parent;
    }
    final roots = <String>[];
    try {
      for (final entry in Directory(path).listSync(followLinks: false)) {
        if (entry is! Directory) continue;
        final name = entry.path.split(Platform.pathSeparator).last;
        if (name.startsWith('.')) continue;
        if (FileSystemEntity.typeSync('${entry.path}/.git') !=
            FileSystemEntityType.notFound) {
          roots.add(entry.path.replaceAll('\\', '/'));
        }
      }
    } catch (_) {
      return [path]; // pasta ilegível → trata como comum
    }
    if (roots.isEmpty) return [path];
    final linked = roots.where((r) => _isWorktreeOfSibling(r, roots)).toSet();
    roots.removeWhere(linked.contains);
    roots.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return roots;
  }

  /// `true` se [candidate] é worktree linkada de outra entrada de [candidates]:
  /// `.git` é **arquivo** (`gitdir: <path>`) e o `<path>` mora sob o `.git/`
  /// de uma irmã. Comparação textual sobre paths normalizados com `/` — cobre
  /// o layout que o próprio git escreve (gitdir absoluto por default).
  static bool _isWorktreeOfSibling(String candidate, List<String> candidates) {
    final gitPath = '$candidate/.git';
    if (FileSystemEntity.typeSync(gitPath) != FileSystemEntityType.file) {
      return false;
    }
    String content;
    try {
      content = File(gitPath).readAsStringSync();
    } catch (_) {
      return false;
    }
    final match = RegExp(
      r'^gitdir:\s*(.+)$',
      multiLine: true,
    ).firstMatch(content);
    if (match == null) return false;
    var gitdir = match.group(1)!.trim().replaceAll('\\', '/');
    final isAbsolute =
        gitdir.startsWith('/') || RegExp(r'^[A-Za-z]:/').hasMatch(gitdir);
    if (!isAbsolute) gitdir = _normalizePath('$candidate/$gitdir');
    for (final other in candidates) {
      if (other == candidate) continue;
      if (gitdir == '$other/.git' || gitdir.startsWith('$other/.git/')) {
        return true;
      }
    }
    return false;
  }

  /// Resolve `.`/`..` de um path com separador `/` (pro gitdir relativo do
  /// `--relative-paths`); não toca no filesystem.
  static String _normalizePath(String path) {
    final out = <String>[];
    for (final seg in path.split('/')) {
      if (seg == '.' || seg.isEmpty && out.isNotEmpty) continue;
      if (seg == '..' && out.isNotEmpty && out.last != '..') {
        out.removeLast();
      } else {
        out.add(seg);
      }
    }
    return out.join('/');
  }

  /// Expande o mapa path→status (só arquivos) num índice que também cobre as
  /// **pastas ancestrais**, cada uma com o estado mais forte dos descendentes.
  static Map<String, GitFileStatus> _buildGitTree(
    Map<String, GitFileStatus>? files,
  ) {
    if (files == null || files.isEmpty) return const <String, GitFileStatus>{};
    final tree = <String, GitFileStatus>{};
    for (final entry in files.entries) {
      final path = entry.key; // relativo, separador '/'
      tree[path] = GitFileStatus.strongest(tree[path], entry.value)!;
      // Propaga pros ancestrais: 'a/b/c.dart' → 'a/b', 'a'. Deleção sobe
      // como mudança comum (ver [GitFileStatus.strongestForFolder]).
      var slash = path.lastIndexOf('/');
      while (slash > 0) {
        final dir = path.substring(0, slash);
        tree[dir] = GitFileStatus.strongestForFolder(tree[dir], entry.value)!;
        slash = dir.lastIndexOf('/');
      }
    }
    return tree;
  }

  @override
  void dispose() {
    _closed = true;
    _consoleNotify?.cancel();
    _activity.removeListener(_onActivityChanged);
    _cancelWatch();
    _gitPoll?.cancel();
    super.dispose();
  }
}

/// Fila global, limitada e coalescida para leituras Git. O limite evita que o
/// restore de muitos workspaces dispute CPU/I/O com builds e com o isolate de
/// UI. Requisições repetidas compartilham o mesmo Future e uma requisição do
/// workspace selecionado pode promover uma entrada ainda não iniciada.
@visibleForTesting
final class GitRefreshScheduler {
  GitRefreshScheduler({this.maxConcurrent = 2}) : assert(maxConcurrent > 0);

  final int maxConcurrent;
  final LinkedHashSet<String> _priority = LinkedHashSet<String>();
  final LinkedHashSet<String> _normal = LinkedHashSet<String>();
  final Map<String, Future<void> Function()> _jobs = {};
  final Map<String, Future<void> Function()> _rerunJobs = {};
  final Map<String, Completer<void>> _completers = {};
  final Set<String> _activeKeys = {};
  final Set<String> _priorityReruns = {};
  final Set<String> _rerunConsumed = {};
  int _active = 0;

  @visibleForTesting
  int get activeCount => _active;

  @visibleForTesting
  int get queuedCount => _jobs.length;

  Future<void> schedule(
    String key,
    Future<void> Function() job, {
    bool priority = false,
  }) {
    final existing = _completers[key];
    if (existing != null) {
      if (_activeKeys.contains(key)) {
        if (!_rerunConsumed.contains(key)) {
          _rerunJobs[key] = job;
          if (priority) _priorityReruns.add(key);
        }
      } else {
        _jobs[key] = job;
        if (priority && _normal.remove(key)) _priority.add(key);
      }
      return existing.future;
    }
    final completer = Completer<void>();
    _completers[key] = completer;
    _jobs[key] = job;
    (priority ? _priority : _normal).add(key);
    _drain();
    return completer.future;
  }

  void _drain() {
    while (_active < maxConcurrent && _jobs.isNotEmpty) {
      final key = _takeNext();
      final job = _jobs.remove(key)!;
      _active++;
      _activeKeys.add(key);
      final stopwatch = Stopwatch()..start();
      Future<void>.sync(job).then<void>(
        (_) => _complete(key, stopwatch: stopwatch),
        onError: (Object error, StackTrace stack) {
          _active--;
          _activeKeys.remove(key);
          _rerunJobs.remove(key);
          _priorityReruns.remove(key);
          _rerunConsumed.remove(key);
          _recordMetric(stopwatch, failed: true);
          _completers.remove(key)?.completeError(error, stack);
          _drain();
        },
      );
    }
  }

  String _takeNext() {
    final queue = _priority.isNotEmpty ? _priority : _normal;
    final key = queue.first;
    queue.remove(key);
    return key;
  }

  void _complete(String key, {required Stopwatch stopwatch}) {
    _active--;
    _activeKeys.remove(key);
    _recordMetric(stopwatch, failed: false);
    final rerun = _rerunJobs.remove(key);
    if (rerun != null) {
      _rerunConsumed.add(key);
      _jobs[key] = rerun;
      final priority = _priorityReruns.remove(key);
      (priority ? _priority : _normal).add(key);
      _drain();
      return;
    }
    _rerunConsumed.remove(key);
    _completers.remove(key)?.complete();
    _drain();
  }

  void _recordMetric(Stopwatch stopwatch, {required bool failed}) {
    PerformanceDiagnostics.instance.record(PerfMetric.gitRefresh, {
      PerfField.durationUs: stopwatch.elapsedMicroseconds,
      PerfField.active: _active,
      PerfField.queued: _jobs.length,
      PerfField.failed: failed ? 1 : 0,
    });
  }
}
