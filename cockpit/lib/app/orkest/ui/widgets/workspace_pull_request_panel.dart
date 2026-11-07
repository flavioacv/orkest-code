import 'package:path/path.dart' as p;
import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_pr_review_panel.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

class WorkspacePullRequestPanel extends StatefulWidget {
  const WorkspacePullRequestPanel({
    super.key,
    required this.roots,
    required this.service,
    required this.onOpenDiff,
    this.onCheckoutSuccess,
  });
  final List<String> roots;
  final GitPullRequestService service;
  final Future<void> Function(
    String root,
    String ref,
    GitHistoryFileChange change,
  )
  onOpenDiff;
  final void Function(String root, int number)? onCheckoutSuccess;
  @override
  State<WorkspacePullRequestPanel> createState() =>
      _WorkspacePullRequestPanelState();
}

class _WorkspacePullRequestPanelState extends State<WorkspacePullRequestPanel> {
  String? _root;
  int _generation = 0;
  bool _mutating = false;

  @override
  void initState() {
    super.initState();
    _root = widget.roots.firstOrNull;
  }

  @override
  void didUpdateWidget(WorkspacePullRequestPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.roots.contains(_root)) {
      _root = widget.roots.firstOrNull;
      _generation++;
      _mutating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final root = _root;
    if (root == null) {
      return const Center(child: Text('Nenhum repositório Git disponível.'));
    }
    final generation = _generation;
    bool isCurrent() => mounted && _root == root && _generation == generation;
    final colors = context.colors;
    return Column(
      children: [
        Material(
          color: colors.panel,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Icon(sc.LucideIcons.gitBranch, size: 14, color: colors.text2),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButton<String>(
                    key: const ValueKey('pr-repository-selector'),
                    value: root,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    dropdownColor: colors.panel2,
                      icon: const Icon(sc.LucideIcons.chevronDown, size: 14),
                      iconEnabledColor: colors.text2,
                      iconDisabledColor: colors.text4,
                    style: context.typo.mono.copyWith(
                      fontSize: 11,
                      color: colors.text,
                    ),
                    onChanged: _mutating || widget.roots.toSet().length < 2
                        ? null
                        : (value) {
                            if (value == null || value == _root) return;
                            setState(() {
                              _root = value;
                              _generation++;
                            });
                          },
                    items: [
                      for (final path in widget.roots.toSet())
                        DropdownMenuItem(
                          value: path,
                          child: Tooltip(
                            message: path,
                            child: Text(
                              '${p.basename(path)} · $path',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: GitPrReviewPanel(
            key: ValueKey(root),
            repoRoot: root,
            service: widget.service,
            onMutationStateChanged: (busy) {
              if (isCurrent()) setState(() => _mutating = busy);
            },
            onSelectReviewFile: (number, change) async {
              final ref = await widget.service.fetchReviewRef(root, number);
              if (!isCurrent()) return;
              await widget.onOpenDiff(root, ref, change);
            },
            onCheckoutSuccess: (number) {
              if (isCurrent()) widget.onCheckoutSuccess?.call(root, number);
            },
          ),
        ),
      ],
    );
  }
}
