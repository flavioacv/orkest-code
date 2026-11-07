import 'package:flutter/material.dart'
    show PopupMenuButton, PopupMenuItem;
import 'package:orkest_code/app/orkest/ui/widgets/ide_tab_surface.dart';
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
    this.badgeColor,
  });
  final String id;
  final String title;
  final IconData icon;
  final WidgetBuilder builder;
  final int badgeCount;
  final Color? badgeColor;
}

/// Visibility of a tool, including any containing tool host.
class WorkbenchToolVisibility extends InheritedWidget {
  const WorkbenchToolVisibility({
    super.key,
    required this.active,
    required super.child,
  });
  final bool active;
  static bool isActive(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<WorkbenchToolVisibility>()
          ?.active ??
      true;
  @override
  bool updateShouldNotify(WorkbenchToolVisibility oldWidget) =>
      active != oldWidget.active;
}

/// Hosts tools independently from file navigation. Visited tools remain mounted
/// while hidden, preserving scroll, drafts and connection inspection state.
class WorkbenchToolHost extends StatefulWidget {
  const WorkbenchToolHost({
    super.key,
    required this.tools,
    required this.selectedId,
    required this.onSelected,
    this.showActiveTitle = false,
    this.isMaximized = false,
    this.isCollapsed = false,
    this.onToggleMaximize,
    this.onToggleCollapse,
    this.actions,
  });
  final List<WorkbenchTool> tools;
  final String selectedId;
  final ValueChanged<String> onSelected;
  final bool showActiveTitle;
  final bool isMaximized;
  final bool isCollapsed;
  final VoidCallback? onToggleMaximize;
  final VoidCallback? onToggleCollapse;
  final List<Widget>? actions;

  @override
  State<WorkbenchToolHost> createState() => _WorkbenchToolHostState();
}

class _WorkbenchToolHostState extends State<WorkbenchToolHost> {
  final Set<String> _visited = {};
  Size? _lastContentSize;
  @override
  Widget build(BuildContext context) {
    final tools = widget.tools;
    final parentActive = WorkbenchToolVisibility.isActive(context);
    if (tools.isEmpty) return const SizedBox.shrink();
    final active = tools.any((t) => t.id == widget.selectedId)
        ? widget.selectedId
        : tools.first.id;
    _visited.retainAll(tools.map((t) => t.id));
    _visited.add(active);
    final colors = context.colors;

    final header = widget.isCollapsed
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: colors.border)),
                ),
                child: AppTooltip(
                  message: 'Expandir painel',
                  child: HoverTap(
                    key: const ValueKey('workbench-tool-expand'),
                    onTap: widget.onToggleCollapse,
                    padding: const EdgeInsets.all(6),
                    borderRadius: BorderRadius.circular(4),
                    child: Icon(
                      LucideIcons.panelRightOpen,
                      size: 15,
                      color: colors.text2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              for (final tool in tools)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 2,
                    horizontal: 4,
                  ),
                  child: AppTooltip(
                    message: tool.title,
                    child: HoverTap(
                      key: ValueKey('${tool.id}-collapsed-tab'),
                      color: Colors.transparent,
                      hoverColor: Colors.transparent,
                      borderRadius: IdeTabSurface.radius,
                      onTap: () {
                        widget.onToggleCollapse?.call();
                        widget.onSelected(tool.id);
                      },
                      padding: EdgeInsets.zero,
                      child: IdeTabSurface(
                        selected: tool.id == active,
                        child: Icon(
                          tool.icon,
                          size: IdeTabSurface.iconSize,
                          color: tool.id == active
                              ? colors.accentText
                              : colors.text2,
                        ),
                      ),
                    ),
                  ),
                ),
              if (widget.actions != null && widget.actions!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  width: 24,
                  height: 1,
                  color: colors.border,
                ),
                const SizedBox(height: 6),
                for (final action in widget.actions!)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 2,
                      horizontal: 4,
                    ),
                    child: Center(child: action),
                  ),
              ],
            ],
          )
        : Container(
            height: IdeTabSurface.headerHeight,
            decoration: BoxDecoration(
              color: colors.bg,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 6),
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
                                      color: Colors.transparent,
                                      hoverColor: Colors.transparent,
                                      borderRadius: IdeTabSurface.radius,
                                      onTap: () => widget.onSelected(tool.id),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 1,
                                      ),
                                      child: IdeTabSurface(
                                        selected: tool.id == active,
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              tool.icon,
                                              size: IdeTabSurface.iconSize,
                                              color: tool.id == active
                                                  ? colors.accentText
                                                  : colors.text2,
                                            ),
                                            if (widget.showActiveTitle &&
                                                tool.id == active) ...[
                                              const SizedBox(width: 5),
                                              Text(
                                                tool.title,
                                                style: context.typo.label.copyWith(
                                                  fontSize: 11,
                                                  color: colors.text,
                                                ),
                                              ),
                                            ],
                                            if (tool.badgeCount > 0) ...[
                                              const SizedBox(width: 3),
                                              Text(
                                                tool.badgeCount > 99
                                                    ? '99+'
                                                    : '${tool.badgeCount}',
                                                style: context.typo.mono.copyWith(
                                                  fontSize: 9,
                                                  color:
                                                      tool.badgeColor ??
                                                      colors.accentText,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      // Dropdown de ferramentas excedentes para garantir 100% de visibilidade (Open IDEA)
                      PopupMenuButton<String>(
                        tooltip: 'Mais ferramentas',
                        icon: Icon(
                          LucideIcons.chevronDown,
                          size: 13,
                          color: colors.text3,
                        ),
                        color: colors.panel2,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 140),
                        onSelected: widget.onSelected,
                        itemBuilder: (context) => [
                          for (final tool in tools)
                            PopupMenuItem<String>(
                              value: tool.id,
                              height: 32,
                              child: Row(
                                children: [
                                  Icon(
                                    tool.icon,
                                    size: 14,
                                    color: tool.id == active
                                        ? colors.accent
                                        : colors.text2,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      tool.title,
                                      style: context.typo.body.copyWith(
                                        fontSize: 12,
                                        fontWeight: tool.id == active
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                        color: tool.id == active
                                            ? colors.text
                                            : colors.text2,
                                      ),
                                    ),
                                  ),
                                  if (tool.badgeCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Text(
                                      '${tool.badgeCount}',
                                      style: context.typo.mono.copyWith(
                                        fontSize: 10,
                                        color: tool.badgeColor ?? colors.accentText,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.actions != null) ...widget.actions!,
                if (widget.onToggleMaximize != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: AppTooltip(
                      message: widget.isMaximized ? 'Restaurar' : 'Maximizar',
                      child: HoverTap(
                        key: const ValueKey('workbench-tool-maximize'),
                        onTap: widget.onToggleMaximize,
                        padding: const EdgeInsets.all(6),
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(
                          widget.isMaximized
                              ? LucideIcons.minimize2
                              : LucideIcons.maximize2,
                          size: 14,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
                if (widget.onToggleCollapse != null)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppTooltip(
                      message: 'Ocultar painel',
                      child: HoverTap(
                        key: const ValueKey('workbench-tool-collapse'),
                        onTap: widget.onToggleCollapse,
                        padding: const EdgeInsets.all(6),
                        borderRadius: BorderRadius.circular(4),
                        child: Icon(
                          LucideIcons.panelRightClose,
                          size: 14,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );

    return Column(
      children: [
        header,
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hidden = widget.isCollapsed || !parentActive;
              if (!hidden) _lastContentSize = constraints.biggest;
              // Offstage still lays out its children. Keep their last usable
              // bounds instead of squeezing editors into the collapsed icon rail.
              final size = hidden
                  ? _lastContentSize ?? const Size(320, 400)
                  : constraints.biggest;
              return OverflowBox(
                alignment: Alignment.topLeft,
                minWidth: size.width,
                maxWidth: size.width,
                minHeight: size.height,
                maxHeight: size.height,
                child: Stack(
                  children: [
                    for (final tool in tools)
                      if (_visited.contains(tool.id))
                        Positioned.fill(
                          key: ValueKey(tool.id),
                          child: Offstage(
                            offstage: widget.isCollapsed || tool.id != active,
                            child: TickerMode(
                              enabled: !widget.isCollapsed && tool.id == active,
                              child: ExcludeFocus(
                                excluding:
                                    widget.isCollapsed || tool.id != active,
                                child: WorkbenchToolVisibility(
                                  active:
                                      parentActive &&
                                      !widget.isCollapsed &&
                                      tool.id == active,
                                  child: Builder(builder: tool.builder),
                                ),
                              ),
                            ),
                          ),
                        ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
