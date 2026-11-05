import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Visualizador estruturado de anotação de autoria (`git blame`) para arquivos.
class GitBlameView extends StatefulWidget {
  const GitBlameView({
    super.key,
    required this.filePath,
    required this.hunks,
    this.onNavigateToLine,
    this.onViewCommit,
    this.onClose,
  });

  /// Caminho relativo ou absoluto do arquivo inspecionado.
  final String filePath;

  /// Lista de blocos de autoria identificados pelo parser `git blame`.
  final List<GitBlameHunk> hunks;

  /// Callback para navegação direta até a linha correspondente no editor de código.
  final void Function(int lineNumber)? onNavigateToLine;

  /// Callback para inspecionar os detalhes do commit associado.
  final void Function(String commitHash)? onViewCommit;

  /// Callback para fechar a visualização de autoria.
  final VoidCallback? onClose;

  @override
  State<GitBlameView> createState() => _GitBlameViewState();
}

class _GitBlameViewState extends State<GitBlameView> {
  String _filterQuery = '';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    final filteredHunks = widget.hunks.where((h) {
      if (_filterQuery.isEmpty) return true;
      final q = _filterQuery.toLowerCase();
      return h.author.toLowerCase().contains(q) ||
          h.summary.toLowerCase().contains(q) ||
          h.shortHash.toLowerCase().contains(q);
    }).toList();

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(left: BorderSide(color: colors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Cabeçalho da barra de blame
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: colors.panel2,
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: Row(
              children: [
                Icon(sc.LucideIcons.gitBranch, size: 14, color: colors.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AUTORIA (BLAME) — ${widget.filePath.split('/').last}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: typo.label.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.text2,
                    ),
                  ),
                ),
                if (widget.onClose != null)
                  InkWell(
                    onTap: widget.onClose,
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.all(4),
                      child: Icon(sc.LucideIcons.x, size: 14, color: colors.text3),
                    ),
                  ),
              ],
            ),
          ),

          // Campo de busca e filtro
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: colors.border)),
            ),
            child: TextField(
              onChanged: (val) => setState(() => _filterQuery = val.trim()),
              style: typo.mono.copyWith(fontSize: 12, color: colors.text),
              decoration: InputDecoration(
                isDense: true,
                hintText: 'Filtrar autor, commit ou mensagem...',
                hintStyle: typo.label.copyWith(fontSize: 11, color: colors.text4),
                prefixIcon: Icon(sc.LucideIcons.search, size: 13, color: colors.text3),
                prefixIconConstraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                filled: true,
                fillColor: colors.bg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: colors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(4),
                  borderSide: BorderSide(color: colors.border),
                ),
              ),
            ),
          ),

          // Lista de blocos de autoria
          Expanded(
            child: filteredHunks.isEmpty
                ? Center(
                    child: Text(
                      'Nenhum bloco de autoria encontrado.',
                      style: typo.label.copyWith(color: colors.text3, fontSize: 12),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredHunks.length,
                    itemBuilder: (context, index) {
                      final hunk = filteredHunks[index];
                      return _BlameHunkCard(
                        hunk: hunk,
                        onNavigate: () => widget.onNavigateToLine?.call(hunk.finalLine),
                        onViewCommit: () => widget.onViewCommit?.call(hunk.commitHash),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _BlameHunkCard extends StatelessWidget {
  const _BlameHunkCard({
    required this.hunk,
    this.onNavigate,
    this.onViewCommit,
  });

  final GitBlameHunk hunk;
  final VoidCallback? onNavigate;
  final VoidCallback? onViewCommit;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    final lineLabel = hunk.lineCount == 1
        ? 'L${hunk.finalLine}'
        : 'L${hunk.finalLine}-${hunk.finalLine + hunk.lineCount - 1}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.border.withValues(alpha: 0.5))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Badge de linhas
              InkWell(
                onTap: onNavigate,
                borderRadius: BorderRadius.circular(3),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: colors.panel2,
                    borderRadius: BorderRadius.circular(3),
                    border: Border.all(color: colors.border),
                  ),
                  child: Text(
                    lineLabel,
                    style: typo.mono.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: colors.accent,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),

              // Hash do commit
              InkWell(
                onTap: onViewCommit,
                borderRadius: BorderRadius.circular(3),
                child: Text(
                  hunk.shortHash,
                  style: typo.mono.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
              const Spacer(),

              // Copiar hash
              IconButton(
                icon: Icon(sc.LucideIcons.copy, size: 12, color: colors.text3),
                tooltip: 'Copiar Hash',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: hunk.commitHash));
                },
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Autor e data
          Row(
            children: [
              Icon(sc.LucideIcons.user, size: 11, color: colors.text3),
              const SizedBox(width: 4),
              Text(
                hunk.author,
                style: typo.label.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.text2,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• ${_formatDate(hunk.authorTime)}',
                style: typo.label.copyWith(fontSize: 10, color: colors.text4),
              ),
            ],
          ),
          const SizedBox(height: 3),

          // Mensagem do commit
          Text(
            hunk.summary,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: typo.body.copyWith(fontSize: 11, color: colors.text),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().toUtc().difference(dt.toUtc());
    if (diff.inDays > 365) return '${(diff.inDays / 365).floor()}a atrás';
    if (diff.inDays > 30) return '${(diff.inDays / 30).floor()}m atrás';
    if (diff.inDays > 0) return '${diff.inDays}d atrás';
    if (diff.inHours > 0) return '${diff.inHours}h atrás';
    if (diff.inMinutes > 0) return '${diff.inMinutes}min atrás';
    return 'agora';
  }
}
