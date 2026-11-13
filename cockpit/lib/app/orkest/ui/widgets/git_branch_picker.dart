import 'package:orkest_code/app/orkest/domain/entities/git_tag_entry.dart';
import 'dart:async';

import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/activity_periodic_timer.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> showGitBranchPicker(BuildContext context, String root) {
  final git = context.read<OrkestViewModel>().git;
  return _showGitBranchDialog(context, root, git);
}

Future<void> _showGitBranchDialog(
  BuildContext context,
  String root,
  GitController git, {
  bool includeTags = false,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    barrierColor: context.colors.scrim,
    builder: (dialogContext) => AlertDialog(
      title: Text(dialogContext.t.orkest.branchPicker.title),
      content: SizedBox(
        width: 520,
        height: (MediaQuery.sizeOf(dialogContext).height * .72).clamp(240, 580),
        child: GitBranchesPanel(
          root: root,
          git: git,
          includeTags: includeTags,
          onDone: () => Navigator.of(dialogContext).pop(),
          showClose: true,
        ),
      ),
    ),
  );
}

class GitBranchesPanel extends StatefulWidget {
  const GitBranchesPanel({
    super.key,
    required this.root,
    required this.git,
    this.onDone,
    this.onSelectRef,
    this.showClose = false,
    this.includeTags = false,
    this.initialCollapsed = const {},
    this.onCollapsedChanged,
  });
  final String root;
  final GitController git;
  final VoidCallback? onDone;
  final ValueChanged<String?>? onSelectRef;
  final bool showClose;
  final bool includeTags;
  final Set<String> initialCollapsed;
  final ValueChanged<Set<String>>? onCollapsedChanged;
  @override
  State<GitBranchesPanel> createState() => _GitBranchesPanelState();
}

class _GitBranchesPanelState extends State<GitBranchesPanel> {
  final _search = TextEditingController();
  final _newBranch = TextEditingController();
  List<GitBranch> _branches = const [];
  List<GitTagEntry> _tags = const [];
  late Set<String> _collapsed;
  GitBranchError? _error;
  bool _loading = true;
  bool _valid = false;
  bool _busy = false;
  bool _fetching = false;
  bool _choosingStartPoint = false;
  int _generation = 0;
  int _rootGeneration = 0;
  String? _startPoint;
  ActivityPeriodicTimer? _poll;
  WindowActivityController? _fallbackActivity;

  @override
  void initState() {
    super.initState();
    _collapsed = Set.of(widget.initialCollapsed);
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final activity =
        WindowActivityScope.maybeOf(context) ??
        (_fallbackActivity ??= WindowActivityController());
    _poll?.dispose();
    if (WorkbenchToolVisibility.isActive(context)) {
      _poll = ActivityPeriodicTimer(
        activity: activity,
        interval: const Duration(seconds: 5),
        onTick: () {
          if (!_busy && !_loading) unawaited(_load());
        },
      )..start();
    }
  }

  @override
  void didUpdateWidget(GitBranchesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root || oldWidget.git != widget.git) {
      _generation++;
      _rootGeneration++;
      _busy = false;
      _fetching = false;
      _loading = false;
      _valid = false;
      _branches = const [];
      _tags = const [];
      _collapsed = Set.of(widget.initialCollapsed);
      _startPoint = null;
      _choosingStartPoint = false;
      _error = null;
      _search.clear();
      _newBranch.clear();
      _load();
    }
  }

  @override
  void dispose() {
    _generation++;
    _poll?.dispose();
    _fallbackActivity?.dispose();
    _search.dispose();
    _newBranch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    final root = widget.root;
    setState(() => _loading = true);
    try {
      final result = await widget.git
          .branches(root)
          .timeout(const Duration(seconds: 15));
      List<GitTagEntry> tags = const [];
      if (widget.includeTags && result.isSuccess) {
        final tagResult = await widget.git
            .listTags(root)
            .timeout(const Duration(seconds: 15));
        if (tagResult case Failure(:final error)) throw FormatException(error);
        tags = tagResult.fold((value) => value, (_) => <GitTagEntry>[]);
      }
      if (!mounted || generation != _generation || root != widget.root) return;
      switch (result) {
        case Success(:final value):
          _branches = value;
          _tags = tags;
          _valid = true;
          if (_error?.kind == GitBranchErrorKind.listFailed) _error = null;
          if (_startPoint != null &&
              !value.any((b) => b.ref == _startPoint) &&
              !_tags.any((tag) => 'refs/tags/${tag.name}' == _startPoint)) {
            _startPoint = null;
          }
        case Failure(:final error):
          _valid = false;
          _error = error;
      }
    } on Exception catch (error) {
      if (!mounted || generation != _generation) return;
      _valid = false;
      _error = GitBranchError(
        GitBranchErrorKind.listFailed,
        detail: error.toString(),
      );
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _execute(
    Future<Result<void, GitBranchError>> Function() operation,
  ) async {
    if (_busy || _loading || !_valid) return;
    final root = widget.root;
    final generation = _rootGeneration;
    setState(() {
      _busy = true;
      _error = null;
    });
    var completed = false;
    try {
      final result = await operation();
      // Refresh the repository that was clicked, regardless of current selection.
      await widget.git.refreshRepository(root);
      if (!mounted || root != widget.root || generation != _rootGeneration) {
        return;
      }
      switch (result) {
        case Success():
          _newBranch.clear();
          completed = true;
          widget.onDone?.call();
        case Failure(:final error):
          _error = error;
      }
    } on Exception catch (error) {
      if (mounted && generation == _rootGeneration) {
        _error = GitBranchError(
          GitBranchErrorKind.checkoutFailed,
          detail: error.toString(),
        );
      }
    } finally {
      if (mounted && generation == _rootGeneration) {
        setState(() => _busy = false);
        if (!completed || !widget.showClose) await _load();
      }
    }
  }

  Future<void> _fetch() async {
    if (_busy || _loading) return;
    final generation = _rootGeneration;
    final root = widget.root;
    setState(() {
      _busy = true;
      _fetching = true;
      _error = null;
    });
    GitBranchError? fetchError;
    try {
      final run = widget.git.fetch(root);
      final output = await run.output.toList();
      final code = await run.exitCode;
      if (!mounted || generation != _rootGeneration) return;
      if (code != 0) {
        fetchError = GitBranchError(
          GitBranchErrorKind.fetchFailed,
          detail: output.join('\n'),
        );
      }
    } on Exception catch (error) {
      if (mounted && generation == _rootGeneration) {
        fetchError = GitBranchError(
          GitBranchErrorKind.fetchFailed,
          detail: error.toString(),
        );
      }
    } finally {
      if (mounted && generation == _rootGeneration) {
        setState(() {
          _busy = false;
          _fetching = false;
        });
        await _load();
        if (mounted && generation == _rootGeneration && fetchError != null) {
          setState(() => _error = fetchError);
        }
      }
    }
  }

  void _pick(GitBranch branch) {
    if (_choosingStartPoint) {
      setState(() {
        _startPoint = branch.ref;
        _choosingStartPoint = false;
        _search.clear();
      });
    } else if (widget.onSelectRef != null) {
      widget.onSelectRef!(branch.ref);
    } else {
      _execute(() => widget.git.checkoutBranch(widget.root, branch));
    }
  }

  bool _expanded(String path) =>
      _search.text.isNotEmpty || !_collapsed.contains('${widget.root}|$path');

  Widget _folder(String path, String label, int depth) => GhostButton(
    key: ValueKey('git-folder-$path'),
    onPressed: _search.text.isNotEmpty
        ? null
        : () {
            setState(() {
              final id = '${widget.root}|$path';
              if (!_collapsed.remove(id)) _collapsed.add(id);
            });
            widget.onCollapsedChanged?.call(Set.unmodifiable(_collapsed));
          },
    child: Padding(
      padding: EdgeInsets.only(left: depth * 12.0),
      child: Row(
        children: [
          Icon(
            _expanded(path)
                ? Icons.keyboard_arrow_down
                : Icons.keyboard_arrow_right,
            size: 14,
          ),
          const Icon(Icons.folder_outlined, size: 13),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.typo.label.copyWith(
                fontSize: 11,
                color: context.colors.text2,
              ),
            ),
          ),
        ],
      ),
    ),
  );

  List<Widget> _groupRows(
    String id,
    String label,
    List<GitBranch> branches,
    bool canAct,
  ) => branches.isEmpty
      ? []
      : [
          _folder(id, label, 0),
          if (_expanded(id)) ..._branchRows(branches, id, '', 1, canAct),
        ];

  List<Widget> _branchRows(
    List<GitBranch> branches,
    String id,
    String prefix,
    int depth,
    bool canAct,
  ) {
    final folders = <String, List<GitBranch>>{};
    final leaves = <GitBranch>[];
    for (final branch in branches) {
      final tail = branch.name.substring(prefix.length);
      final slash = tail.indexOf('/');
      if (slash < 0) {
        leaves.add(branch);
      } else {
        folders.putIfAbsent(tail.substring(0, slash), () => []).add(branch);
      }
    }
    return [
      for (final branch in leaves) _branchButton(branch, depth, prefix, canAct),
      for (final folder in folders.entries) ...[
        _folder('$id/$prefix${folder.key}', folder.key, depth),
        if (_expanded('$id/$prefix${folder.key}'))
          ..._branchRows(
            folder.value,
            id,
            '$prefix${folder.key}/',
            depth + 1,
            canAct,
          ),
      ],
    ];
  }

  Widget _branchButton(
    GitBranch branch,
    int depth,
    String prefix,
    bool canAct,
  ) {
    final tr = context.t.orkest;
    return GhostButton(
      key: ValueKey('branch-${branch.ref}'),
      onPressed: canAct ? () => _pick(branch) : null,
      child: Padding(
        padding: EdgeInsets.only(left: depth * 12.0),
        child: Row(
          children: [
            Icon(
              branch.isCurrent ? Icons.check : Icons.account_tree_outlined,
              size: 13,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    branch.name.substring(prefix.length),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.typo.label.copyWith(fontSize: 11),
                  ),
                  if (branch.upstream != null)
                    Text(
                      '${branch.upstream} ${branch.trackingStatus ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.typo.mono.copyWith(
                        fontSize: 9,
                        color: context.colors.text3,
                      ),
                    ),
                  if (branch.isUsedByWorktree && !branch.isCurrent)
                    Text(
                      tr.gitBranches.inUse(path: branch.worktreePath ?? ''),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: context.typo.label.copyWith(
                        fontSize: 9,
                        color: context.colors.warn,
                      ),
                    ),
                ],
              ),
            ),
            if (branch.isUsedByWorktree && !branch.isCurrent)
              const Icon(Icons.lock_outline, size: 12),
            if (widget.onSelectRef != null &&
                !branch.isCurrent &&
                !_choosingStartPoint)
              GhostButton(
                key: ValueKey('checkout-${branch.ref}'),
                onPressed: canAct
                    ? () => _execute(
                        () => widget.git.checkoutBranch(widget.root, branch),
                      )
                    : null,
                child: Icon(
                  Icons.login,
                  size: 13,
                  semanticLabel: tr.gitBranches.checkout,
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tagRows(bool canAct) => [
    _folder('tags', context.t.orkest.gitDesktop.tags, 0),
    if (_expanded('tags'))
      for (final tag in _tags.where(
        (tag) => tag.name.toLowerCase().contains(_search.text.toLowerCase()),
      ))
        GhostButton(
          key: ValueKey('git-tag-${tag.name}'),
          onPressed: !canAct
              ? null
              : () {
                  if (_choosingStartPoint) {
                    setState(() {
                      _startPoint = 'refs/tags/${tag.name}';
                      _choosingStartPoint = false;
                      _search.clear();
                    });
                  } else {
                    widget.onSelectRef?.call('refs/tags/${tag.name}');
                  }
                },
          child: Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Row(
              children: [
                const Icon(Icons.sell_outlined, size: 13),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    tag.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
  ];

  String _message(GitBranchError error) {
    final tr = context.t.orkest.branchPicker;
    final ux = context.t.orkest.gitBranches;
    return switch (error.kind) {
      GitBranchErrorKind.listFailed => tr.listFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.fetchFailed => ux.fetchFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.invalidName => tr.invalidName,
      GitBranchErrorKind.alreadyExists => tr.alreadyExists,
      GitBranchErrorKind.dirtyWorktree => tr.dirtyWorktree,
      GitBranchErrorKind.checkoutFailed => tr.checkoutFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.createFailed => tr.createFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.inUse => ux.inUse(path: error.detail ?? ''),
      GitBranchErrorKind.missingRef => ux.missingRef,
      GitBranchErrorKind.ambiguousTracking => ux.ambiguousTracking(
        branches: error.detail ?? '',
      ),
      GitBranchErrorKind.localNameCollision => ux.localNameCollision(
        branch: error.detail ?? '',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest;
    final canAct = !_busy && !_loading && _valid;
    final filtered = _branches
        .where(
          (b) => '${b.name} ${b.upstream ?? ''}'.toLowerCase().contains(
            _search.text.toLowerCase(),
          ),
        )
        .toList();
    final groups = [
      (tr.gitBranches.current, filtered.where((b) => b.isCurrent).toList()),
      (
        tr.gitBranches.local,
        filtered.where((b) => !b.isCurrent && !b.isRemote).toList(),
      ),
      (tr.gitBranches.remote, filtered.where((b) => b.isRemote).toList()),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.root,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.mono.copyWith(
                  fontSize: 10,
                  color: context.colors.text3,
                ),
              ),
            ),
            if (_busy || (_loading && _branches.isNotEmpty))
              const Padding(
                padding: EdgeInsets.all(4),
                child: CircularProgressIndicator(size: 12),
              ),
            GhostButton(
              key: const ValueKey('branches-refresh'),
              onPressed: _busy || _loading ? null : _load,
              child: Icon(
                Icons.refresh,
                size: 16,
                semanticLabel: tr.gitBranches.refresh,
              ),
            ),
            GhostButton(
              key: const ValueKey('branches-fetch'),
              onPressed: _busy || _loading ? null : _fetch,
              child: Icon(
                Icons.cloud_download_outlined,
                size: 16,
                semanticLabel: tr.branchPicker.fetch,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: _search,
          autofocus: widget.showClose,
          placeholder: Text(
            widget.includeTags
                ? tr.gitDesktop.branchOrTag
                : tr.branchPicker.searchPlaceholder,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (canAct && filtered.length == 1) {
              _pick(filtered.single);
            }
          },
        ),
        if (_error != null)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 84),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Text(
                  _message(_error!),
                  style: context.typo.label.copyWith(
                    fontSize: 11,
                    color: context.colors.error,
                  ),
                ),
              ),
            ),
          ),
        Expanded(
          child: _branches.isEmpty && _loading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty &&
                    (!widget.includeTags ||
                        !_tags.any(
                          (tag) => tag.name.toLowerCase().contains(
                            _search.text.toLowerCase(),
                          ),
                        ))
              ? Center(child: Text(tr.branchPicker.noBranches))
              : ListView(
                  key: PageStorageKey('git-branch-tree-${widget.root}'),
                  children: [
                    if (_choosingStartPoint)
                      GhostButton(
                        key: const ValueKey('branch-source-head'),
                        onPressed: canAct
                            ? () => setState(() {
                                _startPoint = null;
                                _choosingStartPoint = false;
                                _search.clear();
                              })
                            : null,
                        child: Text(tr.gitEvolution.createFromHead),
                      ),
                    if (widget.onSelectRef != null)
                      GhostButton(
                        key: const ValueKey('branches-all'),
                        onPressed: () => widget.onSelectRef!(null),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(tr.gitBranches.all),
                        ),
                      ),
                    if (widget.onSelectRef != null && !_choosingStartPoint)
                      GhostButton(
                        key: const ValueKey('branches-head'),
                        onPressed: () => widget.onSelectRef!('HEAD'),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(tr.gitDesktop.head),
                        ),
                      ),
                    for (final group in groups)
                      ..._groupRows(
                        'g${groups.indexOf(group)}',
                        group.$1,
                        group.$2,
                        canAct,
                      ),
                    if (widget.includeTags && _tags.isNotEmpty)
                      ..._tagRows(canAct),
                  ],
                ),
        ),
        if (widget.showClose) ...[
          const SizedBox(height: 6),
          OutlineButton(
            key: const ValueKey('branch-start-point'),
            onPressed: !canAct
                ? null
                : () => setState(() {
                    _choosingStartPoint = !_choosingStartPoint;
                    _search.clear();
                  }),
            child: Text(
              _startPoint ?? tr.gitEvolution.createFromHead,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _newBranch,
                  placeholder: Text(tr.branchPicker.newBranchPlaceholder),
                  onSubmitted: (_) {
                    if (canAct && !_choosingStartPoint) {
                      _execute(
                        () => widget.git.createBranch(
                          widget.root,
                          _newBranch.text,
                          startPoint: _startPoint,
                        ),
                      );
                    }
                  },
                ),
              ),
              const SizedBox(width: 6),
              PrimaryButton(
                key: const ValueKey('branches-create'),
                onPressed: !canAct || _choosingStartPoint
                    ? null
                    : () => _execute(
                        () => widget.git.createBranch(
                          widget.root,
                          _newBranch.text,
                          startPoint: _startPoint,
                        ),
                      ),
                child: Text(tr.branchPicker.createBranch),
              ),
            ],
          ),
        ] else
          GhostButton(
            key: const ValueKey('branches-show-create'),
            onPressed: canAct
                ? () => _showGitBranchDialog(
                    context,
                    widget.root,
                    widget.git,
                    includeTags: widget.includeTags,
                  )
                : null,
            child: Text(tr.branchPicker.createBranch),
          ),
        if (widget.showClose)
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton(
              onPressed: _busy && !_fetching ? null : widget.onDone,
              child: Text(context.t.common.close),
            ),
          ),
      ],
    );
  }
}
