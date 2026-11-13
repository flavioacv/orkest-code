import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Barra flutuante de resolução de conflitos Git (Merge / Rebase / Cherry-pick).
///
/// Exibe a contagem de conflitos restantes no arquivo, navegação rápida entre
/// os blocos em conflito, botões para aplicar resoluções (Atual, Entrante, Ambos)
/// e, se detectada operação Git ativa no repositório, atalhos para continuar ou abortar.
class GitConflictBanner extends StatelessWidget {
  const GitConflictBanner({
    super.key,
    required this.conflictCount,
    required this.currentIndex,
    required this.onNext,
    required this.onPrev,
    required this.onAcceptOurs,
    required this.onAcceptTheirs,
    required this.onAcceptBoth,
    this.ongoingOperation = GitOngoingOperation.none,
    this.onContinueOperation,
    this.onAbortOperation,
    this.onReviewConflict,
    this.onStageResolved,
  });

  final int conflictCount;
  final int currentIndex;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onAcceptOurs;
  final VoidCallback onAcceptTheirs;
  final VoidCallback onAcceptBoth;
  final GitOngoingOperation ongoingOperation;
  final VoidCallback? onContinueOperation;
  final VoidCallback? onAbortOperation;
  final VoidCallback? onReviewConflict;
  final VoidCallback? onStageResolved;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.t.orkest.fileTreePanel;

    final hasOperation = ongoingOperation != GitOngoingOperation.none;
    final opName = ongoingOperation == GitOngoingOperation.merge
        ? 'Merge'
        : ongoingOperation == GitOngoingOperation.rebase
        ? 'Rebase'
        : ongoingOperation == GitOngoingOperation.cherryPick
        ? 'Cherry-pick'
        : 'Git';

    return Material(
      color: Colors.transparent,
      elevation: 4,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: colors.panel2,
          border: Border.all(
            color: colors.gitConflict.withValues(alpha: 0.5),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  sc.LucideIcons.gitMerge,
                  size: 15,
                  color: colors.gitConflict,
                ),
                const SizedBox(width: 6),
                Text(
                  tr.conflictsBanner(count: conflictCount),
                  style: context.typo.label.copyWith(
                    fontSize: 12,
                    color: colors.gitConflict,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (conflictCount > 0 && currentIndex >= 0) ...[
                  const SizedBox(width: 6),
                  Text(
                    '(${currentIndex + 1}/$conflictCount)',
                    style: context.typo.mono.copyWith(
                      fontSize: 11,
                      color: colors.text3,
                    ),
                  ),
                ],
              ],
            ),
            if (onStageResolved != null)
              _ConflictActionButton(
                label: context.t.orkest.gitEvolution.saveAndStage,
                icon: sc.LucideIcons.check,
                onPressed: onStageResolved!,
              ),
            // Navegação entre blocos de conflito
            if (onReviewConflict != null)
              _ConflictActionButton(
                label: tr.reviewConflict,
                icon: sc.LucideIcons.columns3,
                onPressed: onReviewConflict!,
              ),
            if (conflictCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConflictIconButton(
                    icon: sc.LucideIcons.arrowUp,
                    tooltip: tr.prevConflict,
                    onTap: onPrev,
                  ),
                  const SizedBox(width: 4),
                  _ConflictIconButton(
                    icon: sc.LucideIcons.arrowDown,
                    tooltip: tr.nextConflict,
                    onTap: onNext,
                  ),
                ],
              ),
            // Ações de resolução
            if (conflictCount > 0)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ConflictActionButton(
                    label: tr.acceptAllOurs,
                    icon: sc.LucideIcons.check,
                    tooltip: 'HEAD / Atual',
                    accentColor: colors.accent,
                    onPressed: onAcceptOurs,
                  ),
                  const SizedBox(width: 6),
                  _ConflictActionButton(
                    label: tr.acceptAllTheirs,
                    icon: sc.LucideIcons.download,
                    tooltip: 'Incoming / Entrante',
                    accentColor: colors.gitStaged,
                    onPressed: onAcceptTheirs,
                  ),
                  const SizedBox(width: 6),
                  _ConflictActionButton(
                    label: tr.acceptBoth,
                    icon: sc.LucideIcons.copy,
                    tooltip: 'Concatenar Atual + Entrante',
                    onPressed: onAcceptBoth,
                  ),
                ],
              ),
            // Operação Git em andamento (Continue / Abort)
            if (hasOperation) ...[
              Container(width: 1, height: 16, color: colors.border),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onContinueOperation != null)
                    _ConflictActionButton(
                      label: tr.continueGitOp(op: opName),
                      icon: sc.LucideIcons.play,
                      accentColor: colors.gitStaged,
                      onPressed: onContinueOperation!,
                    ),
                  if (onAbortOperation != null) ...[
                    const SizedBox(width: 6),
                    _ConflictActionButton(
                      label: tr.abortGitOp(op: opName),
                      icon: sc.LucideIcons.x,
                      accentColor: colors.error,
                      onPressed: onAbortOperation!,
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ConflictActionButton extends StatelessWidget {
  const _ConflictActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.accentColor,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = accentColor ?? colors.text;
    final bg = accentColor != null
        ? accentColor!.withValues(alpha: 0.12)
        : colors.bg;
    final border = accentColor != null
        ? accentColor!.withValues(alpha: 0.35)
        : colors.border;

    final button = GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: context.typo.label.copyWith(
                fontSize: 11,
                color: color,
                fontWeight: accentColor != null
                    ? FontWeight.w600
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip!, child: button);
    }
    return button;
  }
}

class _ConflictIconButton extends StatelessWidget {
  const _ConflictIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.bg,
            border: Border.all(color: colors.border),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: colors.text2),
        ),
      ),
    );
  }
}
