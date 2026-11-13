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
  });
  final List<GitHistoryRoot> roots;
  final GitController? git;
  final Widget Function(BuildContext context, String root)? historyBuilder;
  final int refreshToken;
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
  final _loads = CoalescingSingleFlight<(String, String?)>();
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
  bool _showHistory = false;
  ActivityPeriodicTimer? _poll;
  WindowActivityController? _fallback;

  @override
  void initState() {
    super.initState();
    _root = widget.roots.firstOrNull?.path;
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
      )..start();
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
    _selected = null;
    _files = null;
    _fileError = null;
    _loadingFiles = false;
  }

  Future<void> _load() {
    final requestRoot = _root;
    final requestRef = _ref;
    if (requestRoot == null) return Future<void>.value();
    return _loads.run((requestRoot, requestRef), () async {
      if (!mounted || requestRoot != _root || requestRef != _ref) return;
      final root = requestRoot;
      final ref = requestRef;
      final generation = ++_generation;
      setState(() {
        _loading = true;
        _error = null;
      });
      try {
        final result = await widget
            .loadHistory(root, ref)
            .timeout(const Duration(seconds: 20));
        if (!mounted ||
            generation != _generation ||
            root != _root ||
            ref != _ref) {
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
    });
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

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest;
    if (_root == null) {
      return Center(child: Text(tr.fileTreePanel.historyNoRepository));
    }
    if (_showHistory && widget.historyBuilder != null) {
      return Column(
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: GhostButton(
              key: const ValueKey('git-log-back'),
              onPressed: () => setState(() => _showHistory = false),
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
        final wide = constraints.maxWidth >= 850;
        final sidebar =
            wide &&
            _showBranches &&
            widget.git != null &&
            constraints.maxHeight >= 230;
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
                      child: Icon(
                        Icons.account_tree_outlined,
                        size: 15,
                        semanticLabel: tr.branchPicker.title,
                      ),
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
                            _load();
                          },
                    child: constraints.maxWidth < 600
                        ? Icon(
                            Icons.folder_outlined,
                            size: 14,
                            semanticLabel: widget.roots
                                .where((r) => r.path == _root)
                                .firstOrNull
                                ?.name,
                          )
                        : SizedBox(
                            width: 130,
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
                      child: Icon(
                        Icons.account_tree_outlined,
                        size: 15,
                        semanticLabel: tr.branchPicker.title,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: m.TextField(
                        key: const ValueKey('git-log-search'),
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        style: context.typo.label.copyWith(fontSize: 11),
                        decoration: m.InputDecoration.collapsed(
                          hintText: tr.fileTreePanel.historyFilterPlaceholder,
                        ),
                      ),
                    ),
                  ),
                  GhostButton(
                    key: const ValueKey('git-log-scope'),
                    onPressed: _ref == null ? null : () => _selectRef(null),
                    child: SizedBox(
                      width: constraints.maxWidth < 600 ? 85 : 140,
                      child: Text(
                        _ref == null
                            ? tr.gitBranches.all
                            : _ref!.replaceFirst(
                                RegExp(r'^refs/(heads|remotes)/'),
                                '',
                              ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.label.copyWith(fontSize: 10),
                      ),
                    ),
                  ),
                  if (_loading) const CircularProgressIndicator(size: 12),
                  if (widget.historyBuilder != null)
                    GhostButton(
                      key: const ValueKey('git-log-history'),
                      onPressed: () => setState(() => _showHistory = true),
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
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (sidebar)
                    SizedBox(
                      width: 230,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: GitBranchesPanel(
                          key: ValueKey(_root),
                          root: _root!,
                          git: widget.git!,
                          onSelectRef: _selectRef,
                        ),
                      ),
                    ),
                  if (sidebar)
                    Container(width: 1, color: context.colors.border),
                  Expanded(
                    child:
                        _selected != null &&
                            !wide &&
                            constraints.maxHeight < 260
                        ? _details(context)
                        : LayoutBuilder(
                            builder: (context, tableConstraints) => _table(
                              context,
                              showAuthor: tableConstraints.maxWidth >= 650,
                              availableWidth: tableConstraints.maxWidth,
                            ),
                          ),
                  ),
                  if (_selected != null && wide) ...[
                    Container(width: 1, color: context.colors.border),
                    SizedBox(width: 270, child: _details(context)),
                  ],
                ],
              ),
            ),
            if (_selected != null && !wide && constraints.maxHeight >= 260)
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
              query.isEmpty ||
              '${c.subject} ${c.author} ${c.hash} ${c.refs.join(' ')}'
                  .toLowerCase()
                  .contains(query),
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
    final commit = _selected!;
    final tr = context.t.orkest;
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
                onPressed: () => setState(_clearSelection),
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
