import 'dart:io';

import 'package:orkest_code/app/core/ui/menu/app_menu_bar.dart';
import 'package:orkest_code/app/core/ui/menu/editor_menu_bridge.dart';
import 'package:orkest_code/app/core/ui/menu/workspace_menu_bridge.dart';
import 'package:orkest_code/app/core/ui/settings_controller.dart';
import 'package:orkest_code/app/core/ui/widgets/window_controls.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/core/utils/platform_kind.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Top bar (~46px) customizada — substitui a barra nativa da janela. Semáforo
/// macOS **funcional** (fecha/minimiza/maximiza) · toggle da rail · nome do
/// projeto. A barra inteira arrasta a janela (via [WindowTitleBar]).
class OrkestTopbar extends StatelessWidget {
  const OrkestTopbar({
    super.key,
    required this.projectName,
    required this.railVisible,
    required this.treeVisible,
    required this.onToggleRail,
    required this.onToggleTree,
    required this.officeAvailable,
    required this.officeView,
    required this.onToggleOffice,
    this.filesEnabled = true,
  });

  final String projectName;
  final bool railVisible;
  final bool treeVisible;
  final VoidCallback onToggleRail;
  final VoidCallback onToggleTree;
  final bool officeAvailable;
  final bool officeView;
  final VoidCallback onToggleOffice;

  /// Habilita o botão de árvore de arquivos. `false` no workspace de sistema
  /// "Orkest" (sem pasta → sem árvore): o botão fica visível porém inerte.
  final bool filesEnabled;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return WindowTitleBar(
      children: [
        const WindowControls(),
        // Folga do semáforo — só onde ele existe. No Windows/Linux o
        // [WindowControls] é `SizedBox.shrink()`, então isto separaria o
        // primeiro item de coisa nenhuma.
        if (Platform.isMacOS) const SizedBox(width: 12),
        // Windows/Linux: barra de menu desenhada na janela (estilo VS Code), ao
        // lado do título. No macOS o [WindowMenuBar] é no-op (barra é a nativa).
        if (!Platform.isMacOS) ...[
          WindowMenuBar(
            menus: buildAppMenus(
              context.t,
              context.watch<SettingsController>(),
              context.watch<EditorMenuBridge>(),
              context.watch<WorkspaceMenuBridge>(),
            ),
          ),
          const SizedBox(width: 8),
        ],
        // No Mobile: botão para abrir a gaveta de projetos (workspaces)
        if (isMobilePlatform) ...[
          AppTooltip(
            message: 'Menu de projetos',
            child: HoverTap(
              key: const ValueKey('mobile-toggle-rail'),
              onTap: onToggleRail,
              padding: const EdgeInsets.all(6),
              borderRadius: BorderRadius.circular(5),
              child: Icon(
                LucideIcons.panelLeft,
                size: 18,
                color: railVisible ? colors.accentText : colors.text2,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
        Text(
          projectName,
          style: context.typo.title.copyWith(fontSize: 14, color: colors.text),
        ),
        const Spacer(),
        // No Mobile: botão para abrir a gaveta de arquivos/árvore
        if (isMobilePlatform && filesEnabled) ...[
          AppTooltip(
            message: 'Arquivos do projeto',
            child: HoverTap(
              key: const ValueKey('mobile-toggle-tree'),
              onTap: onToggleTree,
              padding: const EdgeInsets.all(6),
              borderRadius: BorderRadius.circular(5),
              child: Icon(
                LucideIcons.folderClosed,
                size: 18,
                color: treeVisible ? colors.accentText : colors.text2,
              ),
            ),
          ),
          const SizedBox(width: 6),
        ],
        const WindowControlsTrailing(),
      ],
    );
  }
}
