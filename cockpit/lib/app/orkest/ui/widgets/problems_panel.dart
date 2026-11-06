import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/services/problems_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Painel da ferramenta **Problems** no Workbench (plano estrutural 73, FE-E5).
///
/// Exibe os diagnósticos do LSP e inspeções agrupados por arquivo com contadores,
/// filtros rápidos por severidade e pesquisa textual por mensagem/código.
class ProblemsPanel extends StatefulWidget {
  const ProblemsPanel({
    super.key,
    required this.controller,
    required this.onNavigateToSource,
  });

  final ProblemsController controller;
  final void Function(String filePath, int line, int column) onNavigateToSource;

  @override
  State<ProblemsPanel> createState() => _ProblemsPanelState();
}

class _ProblemsPanelState extends State<ProblemsPanel> {
  final TextEditingController _searchCtrl = TextEditingController();
  final Set<String> _collapsedFiles = {};

  @override
  void initState() {
    super.initState();
    _searchCtrl.text = widget.controller.filterQuery;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _toggleFile(String path) {
    setState(() {
      if (!_collapsedFiles.remove(path)) {
        _collapsedFiles.add(path);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        final ctrl = widget.controller;
        final filtered = ctrl.filteredDiagnostics;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de filtros e contadores
            Container(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: colors.panel2,
                border: Border(bottom: BorderSide(color: colors.border)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      _SeverityFilterBadge(
                        label: 'Erros',
                        count: ctrl.errorCount,
                        color: colors.error,
                        icon: Icons.cancel,
                        active: ctrl.severityFilter == LspSeverity.error,
                        onTap: () {
                          ctrl.setSeverityFilter(
                            ctrl.severityFilter == LspSeverity.error ? null : LspSeverity.error,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      _SeverityFilterBadge(
                        label: 'Avisos',
                        count: ctrl.warningCount,
                        color: colors.warn,
                        icon: Icons.warning_amber_rounded,
                        active: ctrl.severityFilter == LspSeverity.warning,
                        onTap: () {
                          ctrl.setSeverityFilter(
                            ctrl.severityFilter == LspSeverity.warning ? null : LspSeverity.warning,
                          );
                        },
                      ),
                      const SizedBox(width: 6),
                      _SeverityFilterBadge(
                        label: 'Infos',
                        count: ctrl.infoCount + ctrl.hintCount,
                        color: colors.accent,
                        icon: Icons.info_outline,
                        active: ctrl.severityFilter == LspSeverity.info,
                        onTap: () {
                          ctrl.setSeverityFilter(
                            ctrl.severityFilter == LspSeverity.info ? null : LspSeverity.info,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.panel3,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: colors.border),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      children: [
                        Icon(Icons.search, size: 13, color: colors.text4),
                        const SizedBox(width: 4),
                        Expanded(
                          child: TextField(
                            key: const ValueKey('problems-filter-input'),
                            controller: _searchCtrl,
                            style: typo.mono.copyWith(fontSize: 11),
                            placeholder: Text(
                              'Filtrar problemas por mensagem, código ou arquivo...',
                              style: typo.mono.copyWith(fontSize: 11, color: colors.text4),
                            ),
                            padding: EdgeInsets.zero,
                            onChanged: (val) => ctrl.setFilterQuery(val),
                          ),
                        ),
                        if (_searchCtrl.text.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _searchCtrl.clear();
                              ctrl.setFilterQuery('');
                            },
                            child: Icon(Icons.close, size: 12, color: colors.text3),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de diagnósticos agrupados por arquivo
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          ctrl.totalCount == 0
                              ? 'Nenhum problema detectado no workspace.'
                              : 'Nenhum problema corresponde aos filtros ativos.',
                          textAlign: TextAlign.center,
                          style: typo.label.copyWith(fontSize: 11.5, color: colors.text4),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      children: [
                        for (final entry in filtered.entries)
                          _ProblemFileGroup(
                            filePath: entry.key,
                            diagnostics: entry.value,
                            collapsed: _collapsedFiles.contains(entry.key),
                            onToggle: () => _toggleFile(entry.key),
                            onNavigateToSource: widget.onNavigateToSource,
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SeverityFilterBadge extends StatelessWidget {
  const _SeverityFilterBadge({
    required this.label,
    required this.count,
    required this.color,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final int count;
  final Color color;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    return HoverTap(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      color: active ? color.withValues(alpha: 0.15) : null,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: typo.mono.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: count > 0 ? color : colors.text4,
            ),
          ),
          const SizedBox(width: 3),
          Text(
            label,
            style: typo.label.copyWith(fontSize: 10, color: colors.text3),
          ),
        ],
      ),
    );
  }
}

class _ProblemFileGroup extends StatelessWidget {
  const _ProblemFileGroup({
    required this.filePath,
    required this.diagnostics,
    required this.collapsed,
    required this.onToggle,
    required this.onNavigateToSource,
  });

  final String filePath;
  final List<LspDiagnostic> diagnostics;
  final bool collapsed;
  final VoidCallback onToggle;
  final void Function(String filePath, int line, int column) onNavigateToSource;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final fileName = p.basename(filePath);
    final dirName = p.dirname(filePath);

    final errorCount = diagnostics.where((d) => d.severity == LspSeverity.error).length;
    final warnCount = diagnostics.where((d) => d.severity == LspSeverity.warning).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverTap(
          onTap: onToggle,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              Icon(
                collapsed ? Icons.chevron_right : Icons.expand_more,
                size: 14,
                color: colors.text4,
              ),
              const SizedBox(width: 4),
              Icon(Icons.description_outlined, size: 13, color: colors.text3),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  fileName,
                  overflow: TextOverflow.ellipsis,
                  style: typo.mono.copyWith(fontSize: 11.5, fontWeight: FontWeight.w600, color: colors.text),
                ),
              ),
              if (dirName != '.') ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    dirName,
                    overflow: TextOverflow.ellipsis,
                    style: typo.mono.copyWith(fontSize: 10, color: colors.text4),
                  ),
                ),
              ],
              const Spacer(),
              if (errorCount > 0) ...[
                Text(
                  '$errorCount',
                  style: typo.mono.copyWith(fontSize: 10.5, color: colors.error, fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 4),
              ],
              if (warnCount > 0)
                Text(
                  '$warnCount',
                  style: typo.mono.copyWith(fontSize: 10.5, color: colors.warn, fontWeight: FontWeight.bold),
                ),
            ],
          ),
        ),
        if (!collapsed)
          Padding(
            padding: const EdgeInsets.only(left: 20, right: 6, bottom: 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final diag in diagnostics)
                  _ProblemItem(
                    diagnostic: diag,
                    onTap: () {
                      onNavigateToSource(
                        filePath,
                        diag.range.start.line + 1, // 1-based para navegação de editor
                        diag.range.start.character + 1,
                      );
                    },
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _ProblemItem extends StatelessWidget {
  const _ProblemItem({
    required this.diagnostic,
    required this.onTap,
  });

  final LspDiagnostic diagnostic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    final IconData icon;
    final Color iconColor;
    switch (diagnostic.severity) {
      case LspSeverity.error:
        icon = Icons.cancel;
        iconColor = colors.error;
        break;
      case LspSeverity.warning:
        icon = Icons.warning_amber_rounded;
        iconColor = colors.warn;
        break;
      case LspSeverity.info:
        icon = Icons.info_outline;
        iconColor = colors.accent;
        break;
      case LspSeverity.hint:
        icon = Icons.lightbulb_outline;
        iconColor = colors.online;
        break;
    }

    final line = diagnostic.range.start.line + 1;
    final col = diagnostic.range.start.character + 1;

    return HoverTap(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      borderRadius: BorderRadius.circular(4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(icon, size: 12, color: iconColor),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: typo.mono.copyWith(fontSize: 11, color: colors.text2, height: 1.3),
                children: [
                  TextSpan(text: diagnostic.message),
                  if (diagnostic.code != null) ...[
                    TextSpan(
                      text: ' (${diagnostic.code})',
                      style: typo.mono.copyWith(fontSize: 10, color: colors.text4),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '[$line:$col]',
            style: typo.mono.copyWith(fontSize: 10, color: colors.text4),
          ),
        ],
      ),
    );
  }
}
