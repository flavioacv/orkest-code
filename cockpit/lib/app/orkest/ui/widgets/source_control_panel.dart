import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/ui/widgets/workbench_tool_host.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Owns Git tool navigation and view lifecycle independently of file browsing.
class SourceControlPanel extends StatelessWidget {
  const SourceControlPanel({
    super.key,
    required this.section,
    required this.onSectionChanged,
    required this.changesBuilder,
    required this.historyBuilder,
    this.pullRequestsBuilder,
    required this.composerBuilder,
    required this.onMenuRequested,
    required this.changeCount,
    this.repositoryLabel,
  });
  final SourceControlSection section;
  final ValueChanged<SourceControlSection> onSectionChanged;
  final WidgetBuilder changesBuilder;
  final WidgetBuilder historyBuilder;
  final WidgetBuilder? pullRequestsBuilder;
  final WidgetBuilder composerBuilder;
  final ValueChanged<BuildContext> onMenuRequested;
  final int changeCount;
  final String? repositoryLabel;

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 6, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  repositoryLabel ?? tr.sectionSourceControl,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.typo.label.copyWith(
                    fontSize: 11,
                    color: context.colors.text2,
                  ),
                ),
              ),
              AppTooltip(
                message: tr.sectionSourceControl,
                child: HoverTap(
                  key: const ValueKey('source-control-menu'),
                  onTap: () => onMenuRequested(context),
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    LucideIcons.ellipsis,
                    size: 16,
                    color: context.colors.text3,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: WorkbenchToolHost(
            showActiveTitle: true,
            selectedId: switch (section) {
              SourceControlSection.history => 'source-control-history',
              SourceControlSection.pullRequests =>
                'source-control-pull-requests',
              _ => 'source-control-changes',
            },
            onSelected: (id) => onSectionChanged(switch (id) {
              'source-control-history' => SourceControlSection.history,
              'source-control-pull-requests' =>
                SourceControlSection.pullRequests,
              _ => SourceControlSection.changes,
            }),
            tools: [
              WorkbenchTool(
                id: 'source-control-changes',
                title: tr.changes,
                icon: LucideIcons.fileDiff,
                badgeCount: changeCount,
                builder: (context) => Column(
                  children: [
                    Expanded(child: changesBuilder(context)),
                    composerBuilder(context),
                  ],
                ),
              ),
              WorkbenchTool(
                id: 'source-control-history',
                title: tr.history,
                icon: LucideIcons.gitCommitHorizontal,
                builder: historyBuilder,
              ),
              if (pullRequestsBuilder != null)
                WorkbenchTool(
                  id: 'source-control-pull-requests',
                  title: 'Pull Requests',
                  icon: LucideIcons.gitPullRequest,
                  builder: pullRequestsBuilder!,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
