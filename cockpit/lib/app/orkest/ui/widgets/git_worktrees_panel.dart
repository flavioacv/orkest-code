import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/activity_periodic_timer.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/orkest/domain/entities/worktree.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class GitWorktreesPanel extends StatefulWidget {
  const GitWorktreesPanel({
    super.key,
    required this.root,
    required this.load,
    required this.onOpen,
    this.onCreate,
  });
  final String root;
  final Future<List<Worktree>> Function(String root) load;
  final Future<void> Function(String path) onOpen;
  final Future<void> Function(String root)? onCreate;
  @override
  State<GitWorktreesPanel> createState() => _GitWorktreesPanelState();
}

class _GitWorktreesPanelState extends State<GitWorktreesPanel> {
  List<Worktree> _items = const [];
  String? _error;
  bool _loading = false;
  int _generation = 0;
  ActivityPeriodicTimer? _poll;
  WindowActivityController? _fallback;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _poll?.dispose();
    if (WorkbenchToolVisibility.isActive(context)) {
      _poll = ActivityPeriodicTimer(
        activity:
            WindowActivityScope.maybeOf(context) ??
            (_fallback ??= WindowActivityController()),
        interval: const Duration(seconds: 5),
        onTick: () {
          if (!_loading) _load();
        },
      )..start();
    }
  }

  @override
  void didUpdateWidget(GitWorktreesPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.root != widget.root) {
      _generation++;
      _items = const [];
      _load();
    }
  }

  @override
  void dispose() {
    _generation++;
    _poll?.dispose();
    _fallback?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await widget
          .load(widget.root)
          .timeout(const Duration(seconds: 20));
      if (mounted && generation == _generation) {
        setState(() {
          _items = items;
          _loading = false;
        });
      }
    } on Exception catch (error) {
      if (mounted && generation == _generation) {
        setState(() {
          _error = error.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _action(Future<void> Function() action) async {
    try {
      await action();
      if (mounted) await _load();
    } on Exception catch (error) {
      if (mounted) setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.root,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.typo.mono.copyWith(fontSize: 10),
              ),
            ),
            if (widget.onCreate != null)
              GhostButton(
                key: const ValueKey('git-worktrees-create'),
                onPressed: _loading
                    ? null
                    : () => _action(() => widget.onCreate!(widget.root)),
                child: Text(tr.projectsRail.createWorktree),
              ),
            GhostButton(
              key: const ValueKey('git-worktrees-refresh'),
              onPressed: _loading ? null : _load,
              child: const Icon(Icons.refresh, size: 14),
            ),
          ],
        ),
        Expanded(
          child: _loading && _items.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? SingleChildScrollView(
                  child: Text(
                    tr.gitDesktop.loadError(detail: _error!),
                    style: context.typo.label.copyWith(
                      color: context.colors.error,
                    ),
                  ),
                )
              : _items.isEmpty
              ? Center(
                  child: Text(
                    tr.gitDesktop.worktreesEmpty,
                    style: context.typo.label.copyWith(
                      color: context.colors.text3,
                    ),
                  ),
                )
              : ListView(
                  key: PageStorageKey('git-worktrees-${widget.root}'),
                  children: [
                    for (final worktree in _items)
                      GhostButton(
                        key: ValueKey('git-worktree-${worktree.path}'),
                        onPressed: () =>
                            _action(() => widget.onOpen(worktree.path)),
                        child: Row(
                          children: [
                            const Icon(Icons.account_tree_outlined, size: 14),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    worktree.branch,
                                    style: context.typo.label,
                                  ),
                                  Text(
                                    worktree.path,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: context.typo.mono.copyWith(
                                      fontSize: 10,
                                      color: context.colors.text3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.open_in_new,
                              size: 14,
                              semanticLabel: tr.gitDesktop.openWorktree,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}
