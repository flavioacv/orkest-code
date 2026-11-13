import 'dart:async';
import 'dart:math' as math;
import 'package:orkest_code/app/orkest/domain/entities/git_workbench_view_state.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';
import 'package:orkest_code/app/orkest/domain/entities/worktree.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_console_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_worktrees_panel.dart';
import 'package:flutter/material.dart' as m show TextField, InputDecoration;
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/activity_periodic_timer.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_menu.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/core/ui/widgets/context_menu_gesture.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_graph_layout.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/domain/utils/coalescing_single_flight.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_branch_picker.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_history_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GitWorkbenchPanel extends StatefulWidget {
  const GitWorkbenchPanel({
    super.key,
    required this.roots,
    required this.loadHistory,
    required this.loadFiles,
    required this.onOpenFileDiff,
    required this.refreshToken,
    this.git,
    this.historyBuilder,
    this.initialState = const GitWorkbenchViewState(),
    this.onStateChanged,
    this.loadFilteredHistory,
    this.loadWorktrees,
    this.onOpenWorktree,
    this.onCreateWorktree,
  });
  final List<GitHistoryRoot> roots;
  final GitController? git;
  final Widget Function(BuildContext context, String root)? historyBuilder;
  final int refreshToken;
  final GitWorkbenchViewState initialState;
  final ValueChanged<GitWorkbenchViewState>? onStateChanged;
  final Future<Result<List<GitHistoryCommit>, GitHistoryError>> Function(
    String root,
    GitHistoryQuery query,
  )?
  loadFilteredHistory;
  final Future<List<Worktree>> Function(String root)? loadWorktrees;
  final Future<void> Function(String path)? onOpenWorktree;
  final Future<void> Function(String root)? onCreateWorktree;
  final Future<Result<List<GitHistoryCommit>, GitHistoryError>> Function(
    String root,
    String? ref,
  )
  loadHistory;
  final Future<Result<List<GitHistoryFileChange>, GitHistoryError>> Function(
    String root,
    String hash,
  )
  loadFiles;
  final Future<void> Function(
    String root,
    String hash,
    GitHistoryFileChange file,
  )
  onOpenFileDiff;
  @override
  State<GitWorkbenchPanel> createState() => _GitWorkbenchPanelState();
}

class _GitWorkbenchPanelState extends State<GitWorkbenchPanel> {
  final _search = TextEditingController();
  final _loads = CoalescingSingleFlight<(String, String?, String, int)>();
  List<GitHistoryCommit> _commits = const [];
  List<GitHistoryFileChange>? _files;
  GitHistoryError? _error;
  GitHistoryError? _fileError;
  GitHistoryCommit? _selected;
  String? _root;
  String? _ref;
  int _generation = 0;
  int _fileGeneration = 0;
  bool _loading = false;
  bool _loadingFiles = false;
  bool _showBranches = true;
  late GitWorkbenchViewState _view;
  late GitWorkbenchTab _tab;
  final _visitedTabs = <GitWorkbenchTab>{GitWorkbenchTab.log};
  String _author = '';
  int _sinceDays = 0;
  String _restoreSelectedHash = '';
  bool _showHistory = false;
  ActivityPeriodicTimer? _poll;
  WindowActivityController? _fallback;

  @override
  void initState() {
    super.initState();
    _view = widget.initialState;
    _root = widget.roots.any((r) => r.path == _view.root)
        ? _view.root
        : widget.roots.firstOrNull?.path;
    _ref = _root == _view.root && _view.ref.isNotEmpty ? _view.ref : null;
    _author = _view.author;
    _sinceDays = _view.sinceDays;
    _search.text = _view.query;
    _restoreSelectedHash = _view.selectedHash;
    _tab = _view.tab;
    if ((_tab == GitWorkbenchTab.console && widget.git == null) ||
        (_tab == GitWorkbenchTab.worktrees && widget.loadWorktrees == null)) {
      _tab = GitWorkbenchTab.log;
    }
    _visitedTabs.add(_tab);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _poll?.dispose();
    if (WorkbenchToolVisibility.isActive(context)) {
      final activity =
          WindowActivityScope.maybeOf(context) ??
          (_fallback ??= WindowActivityController());
      _poll = ActivityPeriodicTimer(
        activity: activity,
        interval: const Duration(seconds: 5),
        onTick: _load,
      );
      if (_tab == GitWorkbenchTab.log && !_showHistory) _poll!.start();
    }
  }

  @override
  void didUpdateWidget(GitWorkbenchPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.roots.any((r) => r.path == _root)) {
      _root = widget.roots.firstOrNull?.path;
      _ref = null;
      _commits = const [];
      _clearSelection();
      _generation++;
      _load();
    } else if (oldWidget.refreshToken != widget.refreshToken) {
      _load();
    }
  }

  @override
  void dispose() {
    _generation++;
    _fileGeneration++;
    _search.dispose();
    _poll?.dispose();
    _fallback?.dispose();
    super.dispose();
  }

  void _clearSelection() {
    _fileGeneration++;
    _restoreSelectedHash = '';
    _selected = null;
    _files = null;
    _fileError = null;
    _loadingFiles = false;
  }

  Future<void> _load() {
    final requestRoot = _root;
    final requestRef = _ref;
    final requestAuthor = _author;
    final requestDays = _sinceDays;
    if (requestRoot == null) return Future<void>.value();
    return _loads.run(
      (requestRoot, requestRef, requestAuthor, requestDays),
      () async {
        if (!mounted ||
            requestRoot != _root ||
            requestRef != _ref ||
            requestAuthor != _author ||
            requestDays != _sinceDays) {
          return;
        }
        final root = requestRoot;
        final ref = requestRef;
        final generation = ++_generation;
        setState(() {
          _loading = true;
          _error = null;
        });
        try {
          final query = GitHistoryQuery(
            all: ref == null,
            revisionRange: ref,
            author: requestAuthor.isEmpty ? null : requestAuthor,
            since: requestDays == 0
                ? null
                : DateTime.now().subtract(Duration(days: requestDays)),
          );
          final result =
              await (widget.loadFilteredHistory?.call(root, query) ??
                      widget.loadHistory(root, ref))
                  .timeout(const Duration(seconds: 20));
          if (!mounted ||
              generation != _generation ||
              root != _root ||
              ref != _ref ||
              requestAuthor != _author ||
              requestDays != _sinceDays) {
            return;
          }
          setState(() {
            _loading = false;
            result.fold((commits) {
              _commits = commits;
              if (_selected != null &&
                  !commits.any((c) => c.hash == _selected!.hash)) {
                _clearSelection();
              }
            }, (error) => _error = error);
          });
          if (_selected == null && _restoreSelectedHash.isNotEmpty) {
            final restored = _commits
                .where((c) => c.hash == _restoreSelectedHash)
                .firstOrNull;
            _restoreSelectedHash = '';
            if (restored != null) unawaited(_select(restored));
          }
        } on Exception catch (error) {
          if (mounted && generation == _generation) {
            setState(() {
              _loading = false;
              _error = GitHistoryError(
                GitHistoryErrorKind.commandFailed,
                detail: error.toString(),
              );
            });
          }
        }
      },
    );
  }

  Future<void> _select(GitHistoryCommit commit) async {
    if (_root == null) return;
    final root = _root!;
    final generation = ++_fileGeneration;
    setState(() {
      _selected = commit;
      _files = null;
      _fileError = null;
      _loadingFiles = true;
    });
    _persist();
    try {
      final result = await widget
          .loadFiles(root, commit.hash)
          .timeout(const Duration(seconds: 15));
      if (!mounted || generation != _fileGeneration || root != _root) return;
      setState(() {
        _loadingFiles = false;
        result.fold((files) => _files = files, (error) => _fileError = error);
      });
    } on Exception catch (error) {
      if (mounted && generation == _fileGeneration) {
        setState(() {
          _loadingFiles = false;
          _fileError = GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: error.toString(),
          );
        });
      }
    }
  }

  void _selectRef(String? ref) {
    setState(() {
      _ref = ref;
      _commits = const [];
      _clearSelection();
      _generation++;
    });
    _persist();
    _load();
  }

  Future<void> _commitMenu(Offset at, GitHistoryCommit commit) async {
    final choice = await showAppMenu<String>(
      context,
      globalPosition: at,
      items: [
        AppMenuItem(
          value: 'copy',
          label: context.t.orkest.fileTreePanel.historyCopyHash,
          icon: Icons.copy,
        ),
      ],
    );
    if (choice == 'copy') {
      await Clipboard.setData(ClipboardData(text: commit.hash));
    }
  }

  void _persist() {
    final next = _view.copyWith(
      tab: _tab,
      root: _root ?? '',
      ref: _ref ?? '',
      query: _search.text,
      author: _author,
      sinceDays: _sinceDays,
      selectedHash: _selected?.hash ?? _restoreSelectedHash,
    );
    if (next != widget.initialState) widget.onStateChanged?.call(next);
    _view = next;
  }

  void _selectTab(GitWorkbenchTab tab) {
    setState(() {
      _tab = tab;
      _visitedTabs.add(tab);
    });
    if (tab == GitWorkbenchTab.log && !_showHistory) {
      _poll?.start();
    } else {
      _poll?.stop();
    }
    _persist();
  }

  void _applyFilters(String author, int days) {
    setState(() {
      _author = author;
      _sinceDays = days;
      _generation++;
      _clearSelection();
    });
    _persist();
    _load();
  }

  Future<void> _editFilters() async {
    final tr = context.t.orkest.gitDesktop;
    final author = TextEditingController(text: _author);
    var days = _sinceDays;
    final result = await showDialog<(String, int)>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, update) => AlertDialog(
          title: Text(tr.filters),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  key: const ValueKey('git-author-input'),
                  controller: author,
                  placeholder: Text(tr.author),
                ),
                const SizedBox(height: 12),
                Text(tr.date),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final value in [0, 7, 30, 90, 365])
                      OutlineButton(
                        key: ValueKey('git-date-$value'),
                        onPressed: () => update(() => days = value),
                        child: Text(
                          value == 0 ? tr.anyDate : tr.lastDays(count: value),
                          style: context.typo.label.copyWith(
                            color: value == days
                                ? context.colors.accent
                                : context.colors.text2,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            GhostButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(context.t.common.cancel),
            ),
            PrimaryButton(
              key: const ValueKey('git-filters-apply'),
              onPressed: () =>
                  Navigator.of(dialogContext).pop((author.text.trim(), days)),
              child: Text(tr.apply),
            ),
          ],
        ),
      ),
    );
    author.dispose();
    if (mounted && result != null) _applyFilters(result.$1, result.$2);
  }

  Widget _chip(String key, String label, VoidCallback clear) => Container(
    padding: const EdgeInsets.only(left: 7),
    margin: const EdgeInsets.only(right: 6),
    decoration: BoxDecoration(
      color: context.colors.accentSoft,
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 200),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typo.label.copyWith(
              fontSize: 10,
              color: context.colors.accent,
            ),
          ),
        ),
        GhostButton(
          key: ValueKey(key),
          onPressed: clear,
          child: const Icon(Icons.close, size: 12),
        ),
      ],
    ),
  );

  Widget _divider(
    String key,
    VoidCallback? onEnd,
    ValueChanged<double> onDelta,
  ) => MouseRegion(
    cursor: SystemMouseCursors.resizeColumn,
    child: GestureDetector(
      key: ValueKey(key),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: (details) => onDelta(details.delta.dx),
      onHorizontalDragEnd: (_) => onEnd?.call(),
      child: Container(
        width: 6,
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: context.colors.border)),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest;
    if (_root == null) {
      return Center(child: Text(tr.fileTreePanel.historyNoRepository));
    }
    return Column(
      children: [
        SizedBox(
          height: 30,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text('Git', style: context.typo.label),
              ),
              for (final tab in GitWorkbenchTab.values)
                GhostButton(
                  key: ValueKey('git-tab-${tab.name}'),
                  onPressed:
                      tab == GitWorkbenchTab.console && widget.git == null ||
                          tab == GitWorkbenchTab.worktrees &&
                              (widget.loadWorktrees == null ||
                                  widget.onOpenWorktree == null)
                      ? null
                      : () => _selectTab(tab),
                  child: Text(
                    switch (tab) {
                      GitWorkbenchTab.log => tr.gitDesktop.log,
                      GitWorkbenchTab.console => tr.gitDesktop.console,
                      GitWorkbenchTab.worktrees => tr.gitDesktop.worktrees,
                    },
                    style: context.typo.label.copyWith(
                      fontSize: 11,
                      color: _tab == tab
                          ? context.colors.accent
                          : context.colors.text3,
                    ),
                  ),
                ),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              for (final tab in _visitedTabs)
                WorkbenchToolVisibility(
                  active:
                      WorkbenchToolVisibility.isActive(context) && _tab == tab,
                  child: Offstage(
                    offstage: _tab != tab,
                    child: ExcludeFocus(
                      excluding: _tab != tab,
                      child: TickerMode(
                        enabled: _tab == tab,
                        child: switch (tab) {
                          GitWorkbenchTab.log => _logView(context),
                          GitWorkbenchTab.console => GitConsolePanel(
                            git: widget.git!,
                            root: _root!,
                          ),
                          GitWorkbenchTab.worktrees => GitWorktreesPanel(
                            key: ValueKey('git-worktrees-$_root'),
                            root: _root!,
                            load: widget.loadWorktrees!,
                            onOpen: widget.onOpenWorktree!,
                            onCreate: widget.onCreateWorktree,
                          ),
                        },
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _logView(BuildContext context) {
    final tr = context.t.orkest;
    if (_showHistory && widget.historyBuilder != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              key: const ValueKey('git-log-back'),
              onPressed: () {
                setState(() => _showHistory = false);
                _poll?.start();
              },
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.arrow_back, size: 13),
                  const SizedBox(width: 6),
                  Text(tr.fileTreePanel.history),
                ],
              ),
            ),
          ),
          Expanded(child: widget.historyBuilder!(context, _root!)),
        ],
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= 850;
        final sidebar =
            wide &&
            _showBranches &&
            widget.git != null &&
            constraints.maxHeight >= 190;
        final double branchWidth = sidebar
            ? (width * _view.branchFraction).clamp(150.0, width * .35)
            : 0.0;
        final double detailsWidth = wide
            ? (width * _view.detailsFraction).clamp(
                200.0,
                math.max(200.0, width - branchWidth - 272),
              )
            : 0.0;
        return Column(
          children: [
            SizedBox(
              height: 34,
              child: Row(
                children: [
                  if (widget.git != null && wide)
                    GhostButton(
                      key: const ValueKey('git-log-toggle-branches'),
                      onPressed: () =>
                          setState(() => _showBranches = !_showBranches),
                      child: const Icon(Icons.account_tree_outlined, size: 14),
                    ),
                  GhostButton(
                    key: const ValueKey('git-log-repository'),
                    onPressed: widget.roots.length < 2
                        ? null
                        : () async {
                            final root = await showAppMenu<String>(
                              context,
                              items: [
                                for (final r in widget.roots)
                                  AppMenuItem(value: r.path, label: r.name),
                              ],
                            );
                            if (!mounted || root == null || root == _root) {
                              return;
                            }
                            setState(() {
                              _root = root;
                              _ref = null;
                              _commits = const [];
                              _clearSelection();
                              _generation++;
                            });
                            _persist();
                            _load();
                          },
                    child: width < 600
                        ? const Icon(Icons.folder_outlined, size: 14)
                        : SizedBox(
                            width: 100,
                            child: Text(
                              widget.roots
                                      .where((r) => r.path == _root)
                                      .firstOrNull
                                      ?.name ??
                                  '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                  ),
                  if (widget.git != null && !sidebar)
                    GhostButton(
                      onPressed: () => showGitBranchPicker(context, _root!),
                      child: const Icon(Icons.account_tree_outlined, size: 14),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: m.TextField(
                        key: const ValueKey('git-log-search'),
                        controller: _search,
                        onChanged: (_) {
                          setState(() {});
                          _persist();
                        },
                        style: context.typo.label.copyWith(fontSize: 11),
                        decoration: m.InputDecoration.collapsed(
                          hintText: tr.fileTreePanel.historyFilterPlaceholder,
                        ),
                      ),
                    ),
                  ),
                  GhostButton(
                    key: const ValueKey('git-log-filters'),
                    onPressed: _editFilters,
                    child: width < 600
                        ? Icon(
                            Icons.filter_list,
                            size: 14,
                            semanticLabel: tr.gitDesktop.filters,
                          )
                        : Text(
                            '${tr.gitDesktop.author} · ${tr.gitDesktop.date}',
                            style: context.typo.label.copyWith(fontSize: 10),
                          ),
                  ),
                  if (_loading) const CircularProgressIndicator(size: 12),
                  if (widget.historyBuilder != null)
                    GhostButton(
                      key: const ValueKey('git-log-history'),
                      onPressed: () {
                        setState(() => _showHistory = true);
                        _poll?.stop();
                      },
                      child: Icon(
                        Icons.history,
                        size: 14,
                        semanticLabel: tr.fileTreePanel.history,
                      ),
                    ),
                  GhostButton(
                    key: const ValueKey('git-log-refresh'),
                    onPressed: _loading ? null : _load,
                    child: Icon(
                      Icons.refresh,
                      size: 14,
                      semanticLabel: tr.gitBranches.refresh,
                    ),
                  ),
                ],
              ),
            ),
            if (_ref != null || _author.isNotEmpty || _sinceDays > 0)
              SizedBox(
                height: 28,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (_ref != null)
                        _chip(
                          'git-filter-ref-clear',
                          '${tr.branchPicker.title}: ${_ref!.replaceFirst(RegExp(r'^refs/(heads|remotes|tags)/'), '')}',
                          () => _selectRef(null),
                        ),
                      if (_author.isNotEmpty)
                        _chip(
                          'git-filter-author-clear',
                          '${tr.gitDesktop.author}: $_author',
                          () => _applyFilters('', _sinceDays),
                        ),
                      if (_sinceDays > 0)
                        _chip(
                          'git-filter-date-clear',
                          tr.gitDesktop.lastDays(count: _sinceDays),
                          () => _applyFilters(_author, 0),
                        ),
                    ],
                  ),
                ),
              ),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebar) ...[
                    SizedBox(
                      width: branchWidth,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: GitBranchesPanel(
                          key: ValueKey(_root),
                          root: _root!,
                          git: widget.git!,
                          onSelectRef: _selectRef,
                          includeTags: true,
                          initialCollapsed: _view.collapsed,
                          onCollapsedChanged: (collapsed) {
                            _view = _view.copyWith(collapsed: collapsed);
                            _persist();
                          },
                        ),
                      ),
                    ),
                    _divider(
                      'git-resize-branches',
                      _persist,
                      (delta) => setState(
                        () => _view = _view.copyWith(
                          branchFraction:
                              ((branchWidth + delta).clamp(150.0, width * .35) /
                              width),
                        ),
                      ),
                    ),
                  ],
                  Expanded(
                    child:
                        _selected != null &&
                            !wide &&
                            constraints.maxHeight < 230
                        ? _details(context)
                        : LayoutBuilder(
                            builder: (context, table) => _table(
                              context,
                              showAuthor: table.maxWidth >= 650,
                              availableWidth: table.maxWidth,
                            ),
                          ),
                  ),
                  if (wide) ...[
                    _divider(
                      'git-resize-details',
                      _persist,
                      (delta) => setState(
                        () => _view = _view.copyWith(
                          detailsFraction:
                              ((detailsWidth - delta).clamp(
                                200.0,
                                math.max(200.0, width - branchWidth - 272),
                              ) /
                              width),
                        ),
                      ),
                    ),
                    SizedBox(
                      key: const ValueKey('git-details-pane'),
                      width: detailsWidth,
                      child: _details(context),
                    ),
                  ],
                ],
              ),
            ),
            if (_selected != null && !wide && constraints.maxHeight >= 230)
              SizedBox(height: 100, child: _details(context)),
          ],
        );
      },
    );
  }

  Widget _table(
    BuildContext context, {
    required bool showAuthor,
    required double availableWidth,
  }) {
    final tr = context.t.orkest;
    if (_error != null) {
      return Center(
        child: Text(
          '${tr.fileTreePanel.historyLoadFailed}\n${_error!.detail ?? ''}',
        ),
      );
    }
    if (_loading && _commits.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    final query = _search.text.trim().toLowerCase();
    final commits = _commits
        .where(
          (c) =>
              (widget.loadFilteredHistory != null ||
                  ((_author.isEmpty ||
                          c.author.toLowerCase().contains(
                            _author.toLowerCase(),
                          )) &&
                      (_sinceDays == 0 ||
                          c.authoredAt != null &&
                              c.authoredAt!.isAfter(
                                DateTime.now().subtract(
                                  Duration(days: _sinceDays),
                                ),
                              )))) &&
              (query.isEmpty ||
                  '${c.subject} ${c.author} ${c.hash} ${c.refs.join(' ')}'
                      .toLowerCase()
                      .contains(query)),
        )
        .toList();
    if (commits.isEmpty) {
      return Center(child: Text(tr.fileTreePanel.historyEmpty));
    }
    final rows = layoutGitGraph(commits);
    final lanes = rows.map((r) => r.width).reduce((a, b) => a > b ? a : b);
    final graphWidth = (lanes * 14.0 + 16).clamp(
      46.0,
      (availableWidth * .25).clamp(46.0, 150.0),
    );
    return Column(
      children: [
        Container(
          height: 24,
          color: context.colors.panel2,
          padding: EdgeInsets.only(left: graphWidth + 8, right: 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  tr.gitBranches.commit,
                  style: context.typo.label.copyWith(
                    fontSize: 10,
                    color: context.colors.text3,
                  ),
                ),
              ),
              if (showAuthor)
                SizedBox(
                  width: 110,
                  child: Text(
                    tr.gitBranches.author,
                    style: context.typo.label.copyWith(
                      fontSize: 10,
                      color: context.colors.text3,
                    ),
                  ),
                ),
              Text(
                tr.gitBranches.hash,
                style: context.typo.label.copyWith(
                  fontSize: 10,
                  color: context.colors.text3,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: const ValueKey('git-log-commits'),
            itemExtent: 32,
            itemCount: commits.length,
            itemBuilder: (context, i) {
              final commit = commits[i];
              return ContextMenuGesture(
                onMenu: (at) => _commitMenu(at, commit),
                child: HoverTap(
                  key: ValueKey('git-log-commit-${commit.hash}'),
                  borderRadius: BorderRadius.zero,
                  color: _selected?.hash == commit.hash
                      ? context.colors.accentSoft
                      : null,
                  onTap: () => _select(commit),
                  child: Row(
                    children: [
                      SizedBox(
                        width: graphWidth,
                        height: 32,
                        child: CustomPaint(
                          key: ValueKey('git-graph-${commit.hash}'),
                          painter: _GitGraphPainter(
                            row: rows[i],
                            lanes: lanes,
                            colors: [
                              context.colors.accent,
                              context.colors.gitStaged,
                              context.colors.warn,
                              context.colors.gitConflict,
                            ],
                            head: commit.isHead,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          children: [
                            for (final ref
                                in (availableWidth >= 500
                                    ? commit.refs.take(2)
                                    : <String>[]))
                              Container(
                                margin: const EdgeInsets.only(right: 5),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 4,
                                  vertical: 2,
                                ),
                                constraints: const BoxConstraints(
                                  maxWidth: 130,
                                ),
                                decoration: BoxDecoration(
                                  color: context.colors.accentSoft,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  ref.replaceFirst('HEAD -> ', ''),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.typo.mono.copyWith(
                                    fontSize: 9,
                                    color: context.colors.accent,
                                  ),
                                ),
                              ),
                            Expanded(
                              child: Text(
                                commit.subject,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: context.typo.label.copyWith(
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (showAuthor)
                        SizedBox(
                          width: 110,
                          child: Text(
                            commit.author,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.typo.label.copyWith(
                              fontSize: 10,
                              color: context.colors.text3,
                            ),
                          ),
                        ),
                      SizedBox(
                        width: 74,
                        child: Text(
                          commit.shortHash,
                          style: context.typo.mono.copyWith(
                            fontSize: 10,
                            color: context.colors.text3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _details(BuildContext context) {
    final tr = context.t.orkest;
    if (_selected == null) {
      return Center(
        key: const ValueKey('git-details-empty'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            tr.gitDesktop.selectCommit,
            textAlign: TextAlign.center,
            style: context.typo.label.copyWith(color: context.colors.text3),
          ),
        ),
      );
    }
    final commit = _selected!;
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  commit.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.label.copyWith(fontSize: 12),
                ),
              ),
              GhostButton(
                key: const ValueKey('git-log-close-details'),
                onPressed: () {
                  setState(_clearSelection);
                  _persist();
                },
                child: const Icon(Icons.close, size: 13),
              ),
            ],
          ),
          Text(
            '${commit.shortHash} · ${commit.author}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typo.mono.copyWith(
              fontSize: 10,
              color: context.colors.text3,
            ),
          ),
          if (commit.authoredAt != null)
            Text(
              commit.authoredAt!.toLocal().toString(),
              style: context.typo.mono.copyWith(
                fontSize: 10,
                color: context.colors.text3,
              ),
            ),
          Expanded(
            child: _loadingFiles
                ? const Center(child: CircularProgressIndicator())
                : _fileError != null
                ? Center(
                    child: Text(
                      '${tr.fileTreePanel.historyLoadFailed}\n${_fileError!.detail ?? ''}',
                    ),
                  )
                : ListView(
                    children: [
                      for (final file in _files ?? <GitHistoryFileChange>[])
                        GhostButton(
                          key: ValueKey('git-log-file-${file.path}'),
                          onPressed: () =>
                              widget.onOpenFileDiff(_root!, commit.hash, file),
                          child: Row(
                            children: [
                              Text(
                                file.status,
                                style: context.typo.mono.copyWith(
                                  fontSize: 10,
                                  color: file.status.startsWith('D')
                                      ? context.colors.error
                                      : context.colors.gitStaged,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  file.displayPath,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: context.typo.label.copyWith(
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GitGraphPainter extends CustomPainter {
  const _GitGraphPainter({
    required this.row,
    required this.lanes,
    required this.colors,
    required this.head,
  });
  final GitGraphRow row;
  final int lanes;
  final List<Color> colors;
  final bool head;
  @override
  void paint(Canvas canvas, Size size) {
    double x(int lane) => 8 + (lane + .5) * (size.width - 16) / lanes;
    void line(GitGraphSegment edge, bool up) {
      final paint = Paint()
        ..color = colors[edge.from % colors.length]
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      final start = Offset(x(edge.from), up ? 0 : size.height / 2);
      final end = Offset(x(edge.to), up ? size.height / 2 : size.height);
      canvas.drawPath(
        Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            start.dx,
            (start.dy + end.dy) / 2,
            end.dx,
            (start.dy + end.dy) / 2,
            end.dx,
            end.dy,
          ),
        paint,
      );
    }

    for (final edge in row.up) {
      line(edge, true);
    }
    for (final edge in row.down) {
      line(edge, false);
    }
    final point = Offset(x(row.lane), size.height / 2);
    final paint = Paint()..color = colors[row.lane % colors.length];
    canvas.drawCircle(point, head ? 4.5 : 3, paint);
    if (head) {
      canvas.drawCircle(
        point,
        6,
        Paint()
          ..color = paint.color
          ..strokeWidth = 1
          ..style = PaintingStyle.stroke,
      );
    }
  }

  @override
  bool shouldRepaint(_GitGraphPainter oldDelegate) =>
      oldDelegate.row != row ||
      oldDelegate.lanes != lanes ||
      oldDelegate.head != head ||
      oldDelegate.colors != colors;
}
