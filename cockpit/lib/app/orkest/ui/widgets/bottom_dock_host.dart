import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Identificadores das abas suportadas no Bottom Dock (Painel Inferior)
enum BottomDockTab {
  git('Git', sc.LucideIcons.gitBranch),
  debug('Debug', sc.LucideIcons.bug),
  problems('Problems', sc.LucideIcons.circleAlert);

  const BottomDockTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

/// Host de painel inferior expansível/retrátil inspirado no Open IDEA / IntelliJ.
class BottomDockHost extends StatefulWidget {
  const BottomDockHost({
    super.key,
    required this.isOpen,
    required this.selectedTab,
    required this.onTabSelected,
    required this.onClose,
    required this.debugContent,
    this.gitContent,
    this.problemsContent,
    this.height = 280.0,
    this.onHeightChanged,
    this.problemsCount = 0,
    this.isDebugging = false,
  });

  final bool isOpen;
  final BottomDockTab selectedTab;
  final ValueChanged<BottomDockTab> onTabSelected;
  final VoidCallback onClose;
  final Widget debugContent;
  final Widget? gitContent;
  final Widget? problemsContent;
  final double height;
  final ValueChanged<double>? onHeightChanged;
  final int problemsCount;
  final bool isDebugging;

  @override
  State<BottomDockHost> createState() => _BottomDockHostState();
}

class _BottomDockHostState extends State<BottomDockHost> {
  bool _isMaximized = false;
  double _dragStartY = 0;
  double _initialHeight = 280;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final currentHeight = _isMaximized
        ? (MediaQuery.of(context).size.height * 0.75).clamp(300.0, 800.0)
        : widget.height.clamp(140.0, 600.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      height: widget.isOpen ? currentHeight : 0,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(
          top: BorderSide(
            color: widget.isOpen ? colors.border : Colors.transparent,
          ),
        ),
      ),
      child: ClipRect(
        child: widget.isOpen
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Alça de Redimensionamento Superior
                  MouseRegion(
                    cursor: SystemMouseCursors.resizeUpDown,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onVerticalDragStart: (details) {
                        _dragStartY = details.globalPosition.dy;
                        _initialHeight = widget.height;
                      },
                      onVerticalDragUpdate: (details) {
                        final delta = _dragStartY - details.globalPosition.dy;
                        widget.onHeightChanged?.call(_initialHeight + delta);
                      },
                      child: Container(
                        height: 5,
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  // Cabeçalho do Dock (Tabs estilo Open IDEA)
                  Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: colors.panel2,
                      border: Border(
                        bottom: BorderSide(color: colors.border),
                      ),
                    ),
                    child: Row(
                      children: [
                        for (final tab in BottomDockTab.values)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: HoverTap(
                              key: ValueKey('bottom-dock-tab-${tab.name}'),
                              onTap: () => widget.onTabSelected(tab),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              borderRadius: BorderRadius.circular(4),
                              color: widget.selectedTab == tab
                                  ? colors.accent.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tab.icon,
                                    size: 13,
                                    color: widget.selectedTab == tab
                                        ? (tab == BottomDockTab.debug && widget.isDebugging
                                            ? colors.warn
                                            : colors.accent)
                                        : colors.text3,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    tab.label,
                                    style: context.typo.label.copyWith(
                                      fontSize: 11,
                                      fontWeight: widget.selectedTab == tab
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                      color: widget.selectedTab == tab
                                          ? colors.text
                                          : colors.text3,
                                    ),
                                  ),
                                  if (tab == BottomDockTab.problems &&
                                      widget.problemsCount > 0) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: colors.warn.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${widget.problemsCount}',
                                        style: context.typo.mono.copyWith(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: colors.warn,
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),

                        const Spacer(),

                        // Botão Maximizar / Restaurar
                        AppTooltip(
                          message: _isMaximized ? 'Restaurar Altura' : 'Maximizar Painel',
                          child: HoverTap(
                            key: const ValueKey('bottom-dock-maximize'),
                            onTap: () => setState(() => _isMaximized = !_isMaximized),
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(3),
                            child: Icon(
                              _isMaximized
                                  ? sc.LucideIcons.minimize2
                                  : sc.LucideIcons.maximize2,
                              size: 12,
                              color: colors.text3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),

                        // Botão Fechar Dock
                        AppTooltip(
                          message: 'Fechar Painel Inferior',
                          child: HoverTap(
                            key: const ValueKey('bottom-dock-close'),
                            onTap: widget.onClose,
                            padding: const EdgeInsets.all(4),
                            borderRadius: BorderRadius.circular(3),
                            child: Icon(
                              sc.LucideIcons.x,
                              size: 14,
                              color: colors.text3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Conteúdo do Painel Ativo
                  Expanded(
                    child: switch (widget.selectedTab) {
                      BottomDockTab.git =>
                        widget.gitContent ??
                            Center(
                              child: Text(
                                'Git Log indisponível',
                                style: context.typo.body.copyWith(
                                  color: colors.text4,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                      BottomDockTab.debug => widget.debugContent,
                      BottomDockTab.problems =>
                        widget.problemsContent ??
                            Center(
                              child: Text(
                                'Nenhum problema detectado',
                                style: context.typo.body.copyWith(
                                  color: colors.text4,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                    },
                  ),
                ],
              )
            : const SizedBox.shrink(),
      ),
    );
  }
}

/// Barra de ferramentas inferior (Bottom Stripe Bar) posicionada no rodapé da janela,
/// idêntica à stripe bar do Open IDEA.
class BottomStripeBar extends StatelessWidget {
  const BottomStripeBar({
    super.key,
    required this.isOpen,
    required this.selectedTab,
    required this.onToggleTab,
    this.problemsCount = 0,
    this.isDebugging = false,
    this.rightWidget,
  });

  final bool isOpen;
  final BottomDockTab selectedTab;
  final ValueChanged<BottomDockTab> onToggleTab;
  final int problemsCount;
  final bool isDebugging;
  final Widget? rightWidget;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.panel2,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          // Botões de Ferramentas Inferiores (Canto Esquerdo)
          for (final tab in BottomDockTab.values) ...[
            HoverTap(
              key: ValueKey('bottom-stripe-btn-${tab.name}'),
              onTap: () => onToggleTab(tab),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              borderRadius: BorderRadius.circular(3),
              color: isOpen && selectedTab == tab
                  ? colors.accent.withValues(alpha: 0.18)
                  : Colors.transparent,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    tab.icon,
                    size: 12,
                    color: isOpen && selectedTab == tab
                        ? colors.accent
                        : (tab == BottomDockTab.debug && isDebugging
                            ? colors.warn
                            : colors.text3),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    tab.label,
                    style: context.typo.label.copyWith(
                      fontSize: 10,
                      fontWeight: isOpen && selectedTab == tab
                          ? FontWeight.w600
                          : FontWeight.normal,
                      color: isOpen && selectedTab == tab
                          ? colors.text
                          : colors.text3,
                    ),
                  ),
                  if (tab == BottomDockTab.problems && problemsCount > 0) ...[
                    const SizedBox(width: 4),
                    Text(
                      '$problemsCount',
                      style: context.typo.mono.copyWith(
                        fontSize: 9,
                        color: colors.warn,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 2),
          ],

          const Spacer(),

          // Conteúdo do Canto Direito (Status, LSP, etc.)
          ?rightWidget,
        ],
      ),
    );
  }
}

/// Botões de ferramentas do Bottom Dock posicionados no canto inferior esquerdo (Open IDEA style).
class RailBottomDockTools extends StatelessWidget {
  const RailBottomDockTools({
    super.key,
    required this.isOpen,
    required this.selectedTab,
    required this.onToggleTab,
    this.problemsCount = 0,
    this.isDebugging = false,
  });

  final bool isOpen;
  final BottomDockTab selectedTab;
  final ValueChanged<BottomDockTab> onToggleTab;
  final int problemsCount;
  final bool isDebugging;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: colors.panel2,
        border: Border(
          top: BorderSide(color: colors.border),
        ),
      ),
      child: Row(
        children: [
          for (final tab in BottomDockTab.values) ...[
            AppTooltip(
              message: tab.label,
              child: HoverTap(
                key: ValueKey('rail-tool-btn-${tab.name}'),
                onTap: () => onToggleTab(tab),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                borderRadius: BorderRadius.circular(4),
                color: isOpen && selectedTab == tab
                    ? colors.accent.withValues(alpha: 0.18)
                    : Colors.transparent,
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Icon(
                      tab.icon,
                      size: 14,
                      color: isOpen && selectedTab == tab
                          ? (tab == BottomDockTab.debug && isDebugging
                              ? colors.warn
                              : colors.accent)
                          : colors.text3,
                    ),
                    if (tab == BottomDockTab.problems && problemsCount > 0)
                      Positioned(
                        top: -5,
                        right: -7,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: colors.warn,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '$problemsCount',
                            style: context.typo.mono.copyWith(
                              fontSize: 8,
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }
}

/// Barra de ferramentas vertical da extrema esquerda (Activity Bar / Tool Stripe),
/// espelhando fielmente o padrão do Open IDE / JetBrains.
class LeftToolStripe extends StatelessWidget {
  const LeftToolStripe({
    super.key,
    required this.isRailOpen,
    required this.onToggleRail,
    required this.isBottomDockOpen,
    required this.bottomDockTab,
    required this.onToggleBottomDock,
    this.problemsCount = 0,
    this.isDebugging = false,
    this.onOpenSettings,
  });

  final bool isRailOpen;
  final VoidCallback onToggleRail;
  final bool isBottomDockOpen;
  final BottomDockTab bottomDockTab;
  final ValueChanged<BottomDockTab> onToggleBottomDock;
  final int problemsCount;
  final bool isDebugging;
  final VoidCallback? onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: 42,
      decoration: BoxDecoration(
        color: colors.panel2,
        border: Border(
          right: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 6),
          // Botão Workspaces (Topo da Stripe)
          _StripeIconButton(
            key: const ValueKey('left-stripe-workspaces'),
            icon: sc.LucideIcons.folderKanban,
            tooltip: 'Workspaces (Projetos)',
            isSelected: isRailOpen,
            onTap: onToggleRail,
          ),
          const Spacer(),

          // Ferramentas Inferiores (Canto Inferior Esquerdo)
          // 🌿 Git (Histórico / Commits / Branches)
          _StripeIconButton(
            key: const ValueKey('left-stripe-git'),
            icon: sc.LucideIcons.gitBranch,
            tooltip: 'Git (Log & Commits)',
            isSelected: isBottomDockOpen && bottomDockTab == BottomDockTab.git,
            onTap: () => onToggleBottomDock(BottomDockTab.git),
          ),
          const SizedBox(height: 4),

          // 🐛 Debug (DAP)
          _StripeIconButton(
            key: const ValueKey('left-stripe-debug'),
            icon: sc.LucideIcons.bug,
            tooltip: 'Debug (F5)',
            isSelected: isBottomDockOpen && bottomDockTab == BottomDockTab.debug,
            highlightColor: isDebugging ? colors.warn : null,
            onTap: () => onToggleBottomDock(BottomDockTab.debug),
          ),
          const SizedBox(height: 4),

          // ⚠️ Problems (LSP)
          _StripeIconButton(
            key: const ValueKey('left-stripe-problems'),
            icon: sc.LucideIcons.circleAlert,
            tooltip: 'Problems & Diagnostics',
            isSelected: isBottomDockOpen && bottomDockTab == BottomDockTab.problems,
            badgeCount: problemsCount,
            onTap: () => onToggleBottomDock(BottomDockTab.problems),
          ),
          const SizedBox(height: 4),

          if (onOpenSettings != null) ...[
            _StripeIconButton(
              key: const ValueKey('left-stripe-settings'),
              icon: sc.LucideIcons.settings,
              tooltip: 'Configurações',
              isSelected: false,
              onTap: onOpenSettings!,
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

class _StripeIconButton extends StatelessWidget {
  const _StripeIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
    this.highlightColor,
  });

  final IconData icon;
  final String tooltip;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AppTooltip(
      message: tooltip,
      child: HoverTap(
        onTap: onTap,
        padding: const EdgeInsets.all(7),
        borderRadius: BorderRadius.circular(5),
        color: isSelected
            ? colors.accent.withValues(alpha: 0.22)
            : Colors.transparent,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Icon(
              icon,
              size: 17,
              color: isSelected
                  ? (highlightColor ?? colors.accent)
                  : (highlightColor ?? colors.text3),
            ),
            if (badgeCount > 0)
              Positioned(
                top: -5,
                right: -7,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(
                    color: colors.warn,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '$badgeCount',
                    style: context.typo.mono.copyWith(
                      fontSize: 8,
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
