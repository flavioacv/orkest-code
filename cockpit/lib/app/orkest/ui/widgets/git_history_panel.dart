import 'package:orkest_code/app/orkest/domain/entities/git_comparison.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/domain/utils/coalescing_single_flight.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/activity_periodic_timer.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_menu.dart';
import 'package:orkest_code/app/core/ui/widgets/context_menu_gesture.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/orkest/ui/widgets/confirm_dialog.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;

/// Histórico estruturado de commits, com ações no menu de cada commit.
class GitHistoryPanel extends StatefulWidget {
  const GitHistoryPanel({
    super.key,
    required this.roots,
    required this.loadHistory,
    required this.loadFiles,
    required this.onOpenFileDiff,
    required this.refreshToken,
    this.onRevertCommit,
    this.onUndoLastCommit,
    this.compareRefs,
  });

  final List<GitHistoryRoot> roots;
  final Future<Result<List<GitHistoryCommit>, GitHistoryError>> Function(
    String root,
  )
  loadHistory;
  final Future<Result<List<GitHistoryFileChange>, GitHistoryError>> Function(
    String root,
    String commitHash,
  )
  loadFiles;
  final Future<void> Function(
    String root,
    String commitHash,
    GitHistoryFileChange change,
  )
  onOpenFileDiff;
  final Future<Result<void, GitHistoryError>> Function(
    String root,
    String hash,
  )?
  onRevertCommit;
  final Future<Result<void, GitHistoryError>> Function(
    String root,
    String hash,
  )?
  onUndoLastCommit;
  final Future<Result<GitComparison, GitHistoryError>> Function(
    String root,
    String baseRef,
    String targetRef,
  )?
  compareRefs;
  final int refreshToken;

  @override
  State<GitHistoryPanel> createState() => _GitHistoryPanelState();
}

class GitHistoryRoot {
  const GitHistoryRoot({required this.path, required this.name, this.branch});
  final String path;
  final String name;
  final String? branch;
}

class _GitHistoryPanelState extends State<GitHistoryPanel> {
  String? _root;
  List<GitHistoryCommit>? _commits;
  GitHistoryError? _error;
  final Map<String, List<GitHistoryFileChange>> _filesByHash = {};
  final Map<String, GitHistoryError> _fileErrorsByHash = {};
  GitHistoryCommit? _selectedCommit;
  String? _loadingFilesHash;
  ActivityPeriodicTimer? _autoRefresh;
  WindowActivityController? _activity;
  WindowActivityController? _fallbackActivity;
  var _loading = false;
  var _disposed = false;
  var _historyLoadGeneration = 0;
  final CoalescingSingleFlight<void> _historyLoads =
      CoalescingSingleFlight<void>();

  final _searchCtrl = TextEditingController();
  String _filterQuery = '';
  String? _comparisonBaseHash;
  GitComparison? _activeComparison;
  bool _loadingComparison = false;
  String? _comparisonError;

  @override
  void initState() {
    super.initState();
    _root = widget.roots.firstOrNull?.path;
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activity =
        WindowActivityScope.maybeOf(context) ??
        (_fallbackActivity ??= WindowActivityController());
    if (!WorkbenchToolVisibility.isActive(context)) {
      _autoRefresh?.dispose();
      _autoRefresh = null;
      _activity = activity;
      return;
    }
    if (identical(activity, _activity) && _autoRefresh != null) return;
    _autoRefresh?.dispose();
    _activity = activity;
    // `git log` e uma leitura local: atualiza commits feitos fora do Orkest
    // sem depender de watcher de refs ou de conexao com a internet.
    _autoRefresh = ActivityPeriodicTimer(
      activity: activity,
      interval: const Duration(seconds: 5),
      onTick: _load,
    )..start();
  }

  @override
  void dispose() {
    _disposed = true;
    _searchCtrl.dispose();
    _autoRefresh?.dispose();
    _fallbackActivity?.dispose();
    super.dispose();
  }

  Future<void> _startComparison(String baseRef, String targetRef) async {
    final root = _root;
    if (root == null) return;
    setState(() {
      _loadingComparison = true;
      _comparisonError = null;
    });

    final compare = widget.compareRefs;
    if (compare == null) {
      setState(() {
        _loadingComparison = false;
        _comparisonError = 'Comparação não suportada nesta configuração.';
      });
      return;
    }

    final result = await compare(root, baseRef, targetRef);
    if (!mounted || root != _root) return;
    switch (result) {
      case Success(:final value):
        setState(() {
          _activeComparison = value;
          _loadingComparison = false;
          _comparisonError = null;
          _comparisonBaseHash = null;
        });
      case Failure(:final error):
        setState(() {
          _activeComparison = null;
          _loadingComparison = false;
          _comparisonError = error.detail ?? 'Falha ao comparar revisões.';
        });
    }
  }

  void _exitComparison() {
    setState(() {
      _activeComparison = null;
      _comparisonBaseHash = null;
      _comparisonError = null;
    });
  }

  @override
  void didUpdateWidget(GitHistoryPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.roots.any((root) => root.path == _root)) {
      _root = widget.roots.firstOrNull?.path;
      _clearSelectedFiles();
      _load();
    } else if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  Future<void> _load() {
    final root = _root;
    if (_disposed || root == null) return Future<void>.value();
    return _historyLoads.run(null, () async {
      if (!_disposed) await _loadOnce(root);
    });
  }

  Future<void> _loadOnce(String root) async {
    if (_disposed || !mounted) return;
    final generation = ++_historyLoadGeneration;
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await widget.loadHistory(root);
    if (!mounted || generation != _historyLoadGeneration || root != _root) {
      return;
    }
    setState(() {
      _loading = false;
      result.fold((commits) => _commits = commits, (error) => _error = error);
    });
  }

  void _clearSelectedFiles() {
    _selectedCommit = null;
    _filesByHash.clear();
    _fileErrorsByHash.clear();
    _loadingFilesHash = null;
  }

  Future<void> _toggleCommit(GitHistoryCommit commit) async {
    final root = _root;
    if (root == null) return;
    if (_selectedCommit?.hash == commit.hash) {
      setState(() => _selectedCommit = null);
      return;
    }
    setState(() => _selectedCommit = commit);
    if (_filesByHash.containsKey(commit.hash) ||
        _fileErrorsByHash.containsKey(commit.hash)) {
      return;
    }
    setState(() => _loadingFilesHash = commit.hash);
    final result = await widget.loadFiles(root, commit.hash);
    if (!mounted || root != _root || _selectedCommit?.hash != commit.hash) {
      return;
    }
    setState(() {
      _loadingFilesHash = null;
      result.fold(
        (files) => _filesByHash[commit.hash] = files,
        (error) => _fileErrorsByHash[commit.hash] = error,
      );
    });
  }

  Future<void> _showCommitMenu(Offset at, GitHistoryCommit commit) async {
    final tr = context.t.orkest.fileTreePanel;
    final root = _root;
    if (root == null) return;
    final choice = await showAppMenu<String>(
      context,
      globalPosition: at,
      items: [
        AppMenuItem(
          value: 'copy',
          label: tr.historyCopyHash,
          icon: Icons.content_copy,
        ),
        if (widget.compareRefs != null) ...[
          AppMenuItem(
            value: 'compare-head',
            label: tr.historyCompareWithHead,
            icon: Icons.compare_arrows,
          ),
          if (_comparisonBaseHash != null && _comparisonBaseHash != commit.hash)
            AppMenuItem(
              value: 'compare-marked',
              label: tr.historyCompareWithMarked(
                hash: _comparisonBaseHash!.length > 7
                    ? _comparisonBaseHash!.substring(0, 7)
                    : _comparisonBaseHash!,
              ),
              icon: Icons.compare,
            )
          else
            AppMenuItem(
              value: 'mark-compare',
              label: tr.historyMarkForCompare,
              icon: Icons.bookmark_border,
            ),
        ],
        if (widget.onRevertCommit != null && commit.parents.length <= 1)
          AppMenuItem(
            value: 'revert',
            label: tr.historyRevertCommit,
            icon: Icons.undo,
          ),
        if (widget.onUndoLastCommit != null &&
            commit.isHead &&
            commit.parents.length == 1)
          AppMenuItem(
            value: 'undo',
            label: tr.historyUndoLastCommit,
            icon: Icons.history,
          ),
      ],
    );
    if (!mounted || choice == null || root != _root) return;
    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: commit.hash));
      return;
    }
    if (choice == 'compare-head') {
      await _startComparison(commit.hash, 'HEAD');
      return;
    }
    if (choice == 'mark-compare') {
      setState(() => _comparisonBaseHash = commit.hash);
      return;
    }
    if (choice == 'compare-marked') {
      await _startComparison(_comparisonBaseHash!, commit.hash);
      return;
    }
    final confirmed = await showConfirmDialog(
      context,
      title: choice == 'revert'
          ? tr.historyRevertCommit
          : tr.historyUndoLastCommit,
      message: choice == 'revert'
          ? tr.historyRevertConfirm(hash: commit.shortHash)
          : tr.historyUndoConfirm(hash: commit.shortHash),
      danger: true,
    );
    if (!confirmed || !mounted || root != _root) return;
    final result = choice == 'revert'
        ? await widget.onRevertCommit!(root, commit.hash)
        : await widget.onUndoLastCommit!(root, commit.hash);
    if (!mounted) return;
    switch (result) {
      case Success():
        _clearSelectedFiles();
        await _load();
      case Failure(:final error):
        await showInfoDialog(
          context,
          title: tr.historyGitActionFailed,
          message: error.detail?.trim().isNotEmpty == true
              ? error.detail!
              : tr.historyGitActionFailed,
        );
        await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final colors = context.colors;
    final roots = widget.roots;
    if (roots.isEmpty) return _EmptyHistory(message: tr.historyNoRepository);
    return Column(
      children: [
        if (roots.length > 1)
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 8, 10, 4),
            child: DropdownButtonFormField<String>(
              initialValue: _root,
              isExpanded: true,
              decoration: InputDecoration(labelText: tr.historyRepository),
              items: [
                for (final root in roots)
                  DropdownMenuItem(value: root.path, child: Text(root.name)),
              ],
              onChanged: (root) {
                if (root == null || root == _root) return;
                setState(() {
                  _root = root;
                  _commits = null;
                  _clearSelectedFiles();
                });
                _load();
              },
            ),
          ),
        if (_root case final root?)
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 6, 6),
            child: Row(
              children: [
                Icon(
                  Icons.account_tree_outlined,
                  size: 14,
                  color: colors.text3,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    roots
                            .where((candidate) => candidate.path == root)
                            .firstOrNull
                            ?.branch ??
                        '',
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.label.copyWith(color: colors.text2),
                  ),
                ),
              ],
            ),
          ),
        if (_root != null && _activeComparison == null) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 6),
            child: Container(
              height: 28,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: colors.panel2,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 14, color: colors.text3),
                  const SizedBox(width: 6),
                  Expanded(
                    child: TextField(
                      key: const ValueKey('git-history-search-input'),
                      controller: _searchCtrl,
                      onChanged: (val) =>
                          setState(() => _filterQuery = val.trim()),
                      style: context.typo.body.copyWith(
                        fontSize: 12,
                        color: colors.text,
                      ),
                      decoration: InputDecoration.collapsed(
                        hintText: tr.historyFilterPlaceholder,
                        hintStyle: context.typo.body.copyWith(
                          fontSize: 12,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
                  if (_filterQuery.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _searchCtrl.clear();
                        setState(() => _filterQuery = '');
                      },
                      child: Icon(Icons.close, size: 14, color: colors.text3),
                    ),
                ],
              ),
            ),
          ),
          if (_comparisonBaseHash != null)
            Container(
              margin: const EdgeInsets.fromLTRB(10, 0, 10, 6),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colors.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: colors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.bookmark, size: 14, color: colors.accent),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      tr.historyComparing(
                        hash: _comparisonBaseHash!.length > 7
                            ? _comparisonBaseHash!.substring(0, 7)
                            : _comparisonBaseHash!,
                      ),
                      style: context.typo.label.copyWith(
                        fontSize: 11,
                        color: colors.accent,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => setState(() => _comparisonBaseHash = null),
                    child: Text(
                      tr.historyCancelCompare,
                      style: context.typo.label.copyWith(
                        fontSize: 11,
                        color: colors.text3,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
        Expanded(child: _body(context)),
      ],
    );
  }

  Widget _body(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    if (_loadingComparison) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_comparisonError != null) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, size: 16),
                  onPressed: _exitComparison,
                ),
                Text(tr.historyBackToTimeline),
              ],
            ),
          ),
          Expanded(
            child: _EmptyHistory(
              message: tr.historyComparisonTitle,
              detail: _comparisonError,
            ),
          ),
        ],
      );
    }
    if (_activeComparison != null) {
      return _buildComparisonView(context, _activeComparison!);
    }
    if (_loading && _commits == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _EmptyHistory(
        message: tr.historyLoadFailed,
        detail: _error!.detail,
      );
    }
    final commits = _commits;
    if (commits == null || commits.isEmpty) {
      return _EmptyHistory(message: tr.historyEmpty);
    }
    final filteredCommits = commits.where((c) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return c.subject.toLowerCase().contains(q) ||
          c.author.toLowerCase().contains(q) ||
          c.hash.toLowerCase().contains(q) ||
          c.shortHash.toLowerCase().contains(q);
    }).toList();
    if (filteredCommits.isEmpty) {
      return _EmptyHistory(message: tr.historyEmpty);
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: filteredCommits.length,
      itemBuilder: (context, index) {
        final commit = filteredCommits[index];
        final selected = _selectedCommit?.hash == commit.hash;
        return _TimelineCommit(
          commit: commit,
          first: index == 0,
          last: index == filteredCommits.length - 1,
          selected: selected,
          files: _filesByHash[commit.hash],
          error: _fileErrorsByHash[commit.hash],
          loadingFiles: _loadingFilesHash == commit.hash,
          onTap: () => _toggleCommit(commit),
          onMenu: (at) => _showCommitMenu(at, commit),
          onOpenFile: (change) =>
              widget.onOpenFileDiff(_root!, commit.hash, change),
        );
      },
    );
  }

  Widget _buildComparisonView(BuildContext context, GitComparison comparison) {
    final tr = context.t.orkest.fileTreePanel;
    final colors = context.colors;
    final typo = context.typo;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: colors.panel2,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Row(
            children: [
              InkWell(
                onTap: _exitComparison,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_back, size: 16, color: colors.text2),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.historyComparisonTitle,
                      style: typo.label.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colors.text,
                      ),
                    ),
                    Text(
                      '${comparison.baseRef.length > 7 ? comparison.baseRef.substring(0, 7) : comparison.baseRef} ↔ ${comparison.targetRef.length > 7 ? comparison.targetRef.substring(0, 7) : comparison.targetRef}',
                      style: typo.mono.copyWith(fontSize: 11, color: colors.text3),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${comparison.commitCount} commits · ${comparison.fileCount} files',
                  style: typo.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.accent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 6),
            children: [
              if (comparison.commits.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                  child: Text(
                    tr.historyComparisonCommits(count: comparison.commits.length),
                    style: typo.label.copyWith(fontSize: 11, color: colors.text3),
                  ),
                ),
                for (final commit in comparison.commits)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colors.panel,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: colors.border),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                commit.shortHash,
                                style: typo.mono.copyWith(
                                  fontSize: 11,
                                  color: colors.accent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  commit.author,
                                  style: typo.body.copyWith(
                                    fontSize: 11,
                                    color: colors.text2,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            commit.subject,
                            style: typo.body.copyWith(fontSize: 12, color: colors.text),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
                child: Text(
                  tr.historyComparisonFiles(count: comparison.fileCount),
                  style: typo.label.copyWith(fontSize: 11, color: colors.text3),
                ),
              ),
              if (comparison.changedFiles.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    tr.historyFilesEmpty,
                    style: typo.body.copyWith(fontSize: 12, color: colors.text3),
                  ),
                )
              else
                for (final change in comparison.changedFiles)
                  _HistoryFileChangeRow(
                    change: change,
                    onTap: () => widget.onOpenFileDiff(
                      _root!,
                      comparison.targetRef,
                      change,
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyHistory extends StatelessWidget {
  const _EmptyHistory({required this.message, this.detail});
  final String message;
  final String? detail;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.history, color: context.colors.text3),
          const SizedBox(height: 8),
          Text(
            message,
            style: context.typo.label.copyWith(color: context.colors.text2),
          ),
          if (detail?.isNotEmpty ?? false) ...[
            const SizedBox(height: 6),
            Text(
              detail!,
              style: context.typo.mono.copyWith(color: context.colors.text3),
            ),
          ],
        ],
      ),
    ),
  );
}

String? _relativeCommitDate(BuildContext context, DateTime? date) {
  if (date == null) return null;

  final localDate = date.toLocal();
  final now = DateTime.now();
  final elapsed = now.difference(localDate);
  final tr = context.t.orkest.fileTreePanel;
  if (elapsed < const Duration(minutes: 1)) return tr.historyNow;
  if (elapsed < const Duration(hours: 1)) {
    return tr.historyMinutesAgo(count: elapsed.inMinutes);
  }
  if (elapsed < const Duration(days: 1)) {
    return tr.historyHoursAgo(count: elapsed.inHours);
  }

  final today = DateTime(now.year, now.month, now.day);
  final commitDay = DateTime(localDate.year, localDate.month, localDate.day);
  if (commitDay == today.subtract(const Duration(days: 1))) {
    return tr.historyYesterday;
  }
  if (elapsed.inDays == 1) return tr.historyDayAgo;
  if (elapsed < const Duration(days: 7)) {
    return tr.historyDaysAgo(count: elapsed.inDays);
  }
  return MaterialLocalizations.of(context).formatShortDate(localDate);
}

/// Uma timeline deliberadamente linear: relacoes de parentesco nao sao desenhadas
/// ate que exista um grafo real, em vez de sugerir ligacoes imprecisas.
class _TimelineCommit extends StatelessWidget {
  const _TimelineCommit({
    required this.commit,
    required this.first,
    required this.last,
    required this.selected,
    required this.files,
    required this.error,
    required this.loadingFiles,
    required this.onTap,
    required this.onMenu,
    required this.onOpenFile,
  });

  final GitHistoryCommit commit;
  final bool first;
  final bool last;
  final bool selected;
  final List<GitHistoryFileChange>? files;
  final GitHistoryError? error;
  final bool loadingFiles;
  final VoidCallback onTap;
  final ValueChanged<Offset> onMenu;
  final ValueChanged<GitHistoryFileChange> onOpenFile;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final subject = commit.subject.trim();
    final relativeDate = _relativeCommitDate(context, commit.authoredAt);
    final metadata = <String>[?relativeDate, commit.author, commit.shortHash];
    return ContextMenuGesture(
      onMenu: onMenu,
      child: HoverTap(
        onTap: onTap,
        color: selected ? colors.accentSoft : Colors.transparent,
        hoverColor: selected ? colors.accentSoft : colors.panel3,
        borderRadius: BorderRadius.zero,
        padding: const EdgeInsets.fromLTRB(8, 4, 10, 5),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _TimelineMarker(first: first, last: last, head: commit.isHead),
                const SizedBox(width: 7),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        subject.isEmpty
                            ? context
                                  .t
                                  .orkest
                                  .fileTreePanel
                                  .historyUntitledCommit
                            : subject,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.label.copyWith(
                          color: colors.text,
                          fontWeight: commit.isHead ? FontWeight.w700 : null,
                        ),
                      ),
                      if (commit.refs.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 4,
                          runSpacing: 3,
                          children: [
                            for (final ref in commit.refs)
                              _RefChip(
                                label: ref,
                                head:
                                    ref == 'HEAD' || ref.startsWith('HEAD -> '),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        metadata.join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.mono.copyWith(
                          fontSize: 10,
                          color: colors.text3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (selected)
              _CommitFiles(
                files: files,
                error: error,
                loading: loadingFiles,
                onFileTap: onOpenFile,
              ),
          ],
        ),
      ),
    );
  }
}

class _CommitFiles extends StatelessWidget {
  const _CommitFiles({
    required this.files,
    required this.error,
    required this.loading,
    required this.onFileTap,
  });

  final List<GitHistoryFileChange>? files;
  final GitHistoryError? error;
  final bool loading;
  final ValueChanged<GitHistoryFileChange> onFileTap;

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.only(left: 23, top: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.panel3,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.all(7),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                tr.historyFiles,
                style: context.typo.label.copyWith(color: colors.text2),
              ),
              const SizedBox(height: 4),
              if (loading)
                const LinearProgressIndicator()
              else if (error != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr.historyFilesLoadFailed,
                      style: context.typo.mono.copyWith(
                        fontSize: 10,
                        color: colors.text3,
                      ),
                    ),
                    if (error!.detail?.isNotEmpty == true)
                      Text(
                        error!.detail!,
                        style: context.typo.mono.copyWith(
                          fontSize: 10,
                          color: colors.text3,
                        ),
                      ),
                  ],
                )
              else if (files?.isEmpty ?? true)
                Text(
                  tr.historyFilesEmpty,
                  style: context.typo.mono.copyWith(
                    fontSize: 10,
                    color: colors.text3,
                  ),
                )
              else
                for (final change in files!)
                  _HistoryFileChangeRow(
                    change: change,
                    onTap: () => onFileTap(change),
                  ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HistoryFileChangeRow extends StatelessWidget {
  const _HistoryFileChangeRow({required this.change, required this.onTap});

  final GitHistoryFileChange change;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final changeColor = _historyChangeColor(colors, change.status);
    return HoverTap(
      onTap: onTap,
      hoverColor: colors.accentSoft,
      borderRadius: BorderRadius.circular(3),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.only(left: 4),
              width: 32,
              child: Text(
                change.status,
                style: context.typo.mono.copyWith(
                  fontSize: 10,
                  color: changeColor,
                ),
              ),
            ),
            Expanded(
              child: Text(
                change.displayLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.mono.copyWith(
                  fontSize: 10,
                  color: changeColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color _historyChangeColor(AppColors colors, String status) {
  if (status.isEmpty) return colors.text3;
  return switch (status[0]) {
    'A' => colors.gitUntracked,
    'D' => colors.gitDeleted,
    'R' || 'C' => colors.accentText,
    _ => colors.text3,
  };
}

class _TimelineMarker extends StatelessWidget {
  const _TimelineMarker({
    required this.first,
    required this.last,
    required this.head,
  });

  final bool first;
  final bool last;
  final bool head;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return SizedBox(
      width: 16,
      height: 44,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: first ? 14 : 0,
            bottom: last ? 30 : 0,
            child: Container(width: 1, color: colors.border2),
          ),
          Positioned(
            top: 10,
            child: Container(
              key: const ValueKey('git-history-timeline-node'),
              width: head ? 10 : 8,
              height: head ? 10 : 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: head ? colors.accent : colors.text3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RefChip extends StatelessWidget {
  const _RefChip({required this.label, required this.head});
  final String label;
  final bool head;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: head ? context.colors.accentSoft : context.colors.panel3,
      borderRadius: BorderRadius.circular(3),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      child: Text(
        label,
        style: context.typo.mono.copyWith(
          fontSize: 9,
          color: head ? context.colors.accentText : context.colors.text2,
        ),
      ),
    ),
  );
}
