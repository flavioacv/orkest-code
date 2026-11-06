import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// A workspace tool with stable identity and content created on first use.
class WorkbenchTool {
  const WorkbenchTool({
    required this.id,
    required this.title,
    required this.icon,
    required this.builder,
    this.badgeCount = 0,
  });
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final int badgeCount;
}

/// Hosts tools independently from file navigation. Visited tools remain mounted
/// while hidden, preserving scroll, drafts and connection inspection state.
class WorkbenchToolHost extends StatefulWidget {
  const WorkbenchToolHost({
    super.key,
    required this.tools,
    required this.selectedId,
    required this.onSelected,
  });
  final List<WorkbenchTool> tools;
  final String selectedId;
  final ValueChanged<String> onSelected;
  @override
  State<WorkbenchToolHost> createState() => _WorkbenchToolHostState();
}

class _WorkbenchToolHostState extends State<WorkbenchToolHost> {
  final Set<String> _visited = {};
  @override
  Widget build(BuildContext context) {
    final tools = widget.tools;
    if (tools.isEmpty) return const SizedBox.shrink();
    final active = tools.any((t) => t.id == widget.selectedId)
        ? widget.selectedId
        : tools.first.id;
    _visited.retainAll(tools.map((t) => t.id));
    _visited.add(active);
    final colors = context.colors;
    return Column(
      children: [
        Container(
          height: 40,
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: [
                for (final tool in tools)
                  Semantics(
                    label: tool.title,
                    selected: tool.id == active,
                    button: true,
                    child: AppTooltip(
                      message: tool.title,
                      child: HoverTap(
                        key: ValueKey('${tool.id}-tab'),
                        color: tool.id == active
                            ? colors.panel2
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(5),
                        onTap: () => widget.onSelected(tool.id),
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              tool.icon,
                              size: 16,
                              color: tool.id == active
                                  ? colors.text
                                  : colors.text3,
                            ),
                            if (tool.badgeCount > 0) ...[
                              const SizedBox(width: 3),
                              Text(
                                tool.badgeCount > 99
                                    ? '99+'
                                    : '${tool.badgeCount}',
                                style: context.typo.mono.copyWith(
                                  fontSize: 9,
                                  color: colors.warn,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              for (final tool in tools)
                if (_visited.contains(tool.id))
                  Positioned.fill(
                    key: ValueKey(tool.id),
                    child: Offstage(
                      offstage: tool.id != active,
                      child: TickerMode(
                        enabled: tool.id == active,
                        child: ExcludeFocus(
                          excluding: tool.id != active,
                          child: Builder(builder: tool.builder),
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
}
