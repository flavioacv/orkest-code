import 'package:flutter/material.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_pull_request.dart';
import 'package:orkest_code/app/orkest/domain/services/git_pull_request_service.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;

/// Painel para revisão integrada de Pull Requests no contexto do código (G05).
class GitPrReviewPanel extends StatefulWidget {
  const GitPrReviewPanel({
    super.key,
    required this.repoRoot,
    required this.service,
    this.onSelectFileChange,
    this.onSelectReviewFile,
    this.onCheckoutSuccess,
    this.onMutationStateChanged,
  });

  final Future<void> Function(int number, GitHistoryFileChange change)?
  onSelectReviewFile;
  final ValueChanged<bool>? onMutationStateChanged;
  final String repoRoot;
  final GitPullRequestService service;
  final void Function(GitHistoryFileChange fileChange)? onSelectFileChange;
  final void Function(int prNumber)? onCheckoutSuccess;

  @override
  State<GitPrReviewPanel> createState() => _GitPrReviewPanelState();
}

class _GitPrReviewPanelState extends State<GitPrReviewPanel> {
  int _detailGeneration = 0;
  bool _showCompactDetail = false;
  bool _isLoadingList = false;
  bool _isLoadingDetail = false;
  bool _isSubmittingComment = false;
  bool _isCheckingOut = false;

  String? _listError;
  String? _detailError;
  String? _actionMessage;

  List<GitPullRequest> _prs = [];
  GitPullRequest? _selectedPr;
  GitPrDetail? _selectedPrDetail;

  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPrList();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadPrList() async {
    setState(() {
      _isLoadingList = true;
      _listError = null;
    });

    final res = await widget.service.listPullRequests(widget.repoRoot);
    if (!mounted) return;

    switch (res) {
      case Success(:final value):
        setState(() {
          _prs = value;
          _isLoadingList = false;
          if (_prs.isNotEmpty && _selectedPr == null) {
            _selectPr(_prs.first, reveal: false);
          }
        });
      case Failure(:final error):
        setState(() {
          _listError = error;
          _isLoadingList = false;
        });
    }
  }

  Future<void> _selectPr(GitPullRequest pr, {bool reveal = true}) async {
    if (_isCheckingOut || _isSubmittingComment) return;
    final generation = ++_detailGeneration;
    final root = widget.repoRoot;
    setState(() {
      _selectedPr = pr;
      if (reveal) _showCompactDetail = true;
      _isLoadingDetail = true;
      _detailError = null;
      _selectedPrDetail = null;
    });

    final res = await widget.service.getPullRequestDetail(root, pr.number);
    if (!mounted ||
        generation != _detailGeneration ||
        widget.repoRoot != root) {
      return;
    }

    switch (res) {
      case Success(:final value):
        setState(() {
          _selectedPrDetail = value;
          _isLoadingDetail = false;
        });
      case Failure(:final error):
        setState(() {
          _detailError = error;
          _isLoadingDetail = false;
        });
    }
  }

  Future<void> _checkoutSelectedPr() async {
    final pr = _selectedPr;
    if (pr == null || _isCheckingOut || _isSubmittingComment) return;

    setState(() {
      _isCheckingOut = true;
      _actionMessage = 'Criando branch local pr-${pr.number}...';
    });

    widget.onMutationStateChanged?.call(true);
    Result<void, String> res;
    try {
      res = await widget.service.checkoutPullRequest(
        widget.repoRoot,
        pr.number,
      );
    } catch (error) {
      res = Failure('$error');
    }
    if (!mounted) return;
    widget.onMutationStateChanged?.call(false);

    switch (res) {
      case Success():
        setState(() {
          _isCheckingOut = false;
          _actionMessage =
              'Checkout para pr-${pr.number} realizado com sucesso!';
        });
        widget.onCheckoutSuccess?.call(pr.number);
      case Failure(:final error):
        setState(() {
          _isCheckingOut = false;
          _actionMessage = 'Erro no checkout: $error';
        });
    }
  }

  Future<void> _openFile(GitHistoryFileChange change) async {
    final pr = _selectedPr;
    if (pr == null) return;
    try {
      if (widget.onSelectReviewFile != null) {
        await widget.onSelectReviewFile!(pr.number, change);
      } else {
        widget.onSelectFileChange?.call(change);
      }
    } catch (error) {
      if (mounted) setState(() => _actionMessage = '$error');
    }
  }

  Future<void> _submitComment() async {
    final pr = _selectedPr;
    final text = _commentController.text.trim();
    if (pr == null || text.isEmpty || _isCheckingOut || _isSubmittingComment) {
      return;
    }

    setState(() {
      _isSubmittingComment = true;
      _actionMessage = null;
    });

    widget.onMutationStateChanged?.call(true);
    Result<GitPrComment, String> res;
    try {
      res = await widget.service.addComment(
        widget.repoRoot,
        number: pr.number,
        body: text,
      );
    } catch (error) {
      res = Failure('$error');
    }
    if (!mounted) return;
    widget.onMutationStateChanged?.call(false);

    switch (res) {
      case Success(:final value):
        _commentController.clear();
        setState(() {
          _isSubmittingComment = false;
          if (_selectedPrDetail != null) {
            _selectedPrDetail = GitPrDetail(
              pr: _selectedPrDetail!.pr,
              comments: [..._selectedPrDetail!.comments, value],
              changedFiles: _selectedPrDetail!.changedFiles,
              diff: _selectedPrDetail!.diff,
            );
          }
          _actionMessage = 'Comentário enviado com sucesso!';
        });
      case Failure(:final error):
        setState(() {
          _isSubmittingComment = false;
          _actionMessage = 'Falha ao enviar comentário: $error';
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;

    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildListHeader(colors, typo),
        Expanded(child: _buildPrList(colors, typo)),
      ],
    );
    final detail = _selectedPr == null
        ? Center(
            child: Text(
              'Selecione um Pull Request para revisar',
              style: typo.body.copyWith(color: colors.text3, fontSize: 13),
            ),
          )
        : _buildDetailPanel(colors, typo);
    return Container(
      color: colors.bg,
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 640) {
            if (!_showCompactDetail || _selectedPr == null) return list;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    key: const ValueKey('pr-review-back'),
                    onPressed: () => setState(() => _showCompactDetail = false),
                    icon: const Icon(sc.LucideIcons.arrowLeft, size: 14),
                    label: const Text('Pull Requests'),
                  ),
                ),
                Expanded(child: detail),
              ],
            );
          }
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Painel Esquerdo: Lista de PRs
              SizedBox(
                width: 280,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: colors.border)),
                  ),
                  child: list,
                ),
              ),
              // 2. Painel Direito: Detalhe do PR selecionado
              Expanded(child: detail),
            ],
          );
        },
      ),
    );
  }

  Widget _buildListHeader(AppColors colors, AppTypography typo) {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colors.panel,
        border: Border(bottom: BorderSide(color: colors.border)),
      ),
      child: Row(
        children: [
          const Icon(sc.LucideIcons.gitPullRequest, size: 14),
          const SizedBox(width: 8),
          Text(
            'Pull Requests',
            style: typo.label.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.text,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(sc.LucideIcons.refreshCw, size: 14),
            tooltip: 'Atualizar PRs',
            onPressed: _isLoadingList ? null : _loadPrList,
            splashRadius: 16,
          ),
        ],
      ),
    );
  }

  Widget _buildPrList(AppColors colors, AppTypography typo) {
    if (_isLoadingList) {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }

    if (_listError != null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(sc.LucideIcons.triangleAlert, size: 24, color: colors.error),
            const SizedBox(height: 8),
            Text(
              _listError!,
              style: typo.body.copyWith(color: colors.error, fontSize: 12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loadPrList,
              child: const Text('Tentar novamente'),
            ),
          ],
        ),
      );
    }

    if (_prs.isEmpty) {
      return Center(
        child: Text(
          'Nenhum Pull Request encontrado.',
          style: typo.body.copyWith(color: colors.text3, fontSize: 13),
        ),
      );
    }

    return ListView.separated(
      itemCount: _prs.length,
      separatorBuilder: (context, index) =>
          Divider(height: 1, color: colors.border),
      itemBuilder: (context, index) {
        final pr = _prs[index];
        final isSelected = pr.number == _selectedPr?.number;

        return InkWell(
          onTap: _isCheckingOut || _isSubmittingComment
              ? null
              : () => _selectPr(pr),
          child: Container(
            padding: const EdgeInsets.all(10),
            color: isSelected ? colors.accent.withValues(alpha: 0.12) : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      pr.isOpen
                          ? sc.LucideIcons.gitPullRequest
                          : (pr.isMerged
                                ? sc.LucideIcons.gitMerge
                                : sc.LucideIcons.circleSlash),
                      size: 13,
                      color: pr.isOpen
                          ? colors.accent
                          : (pr.isMerged ? Colors.purple : colors.text3),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '#${pr.number}',
                      style: typo.mono.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colors.accent,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    if (pr.isDraft)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: colors.panel2,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          'DRAFT',
                          style: typo.mono.copyWith(fontSize: 9),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  pr.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: typo.body.copyWith(
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.normal,
                    color: colors.text,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'por ${pr.author} · ${pr.headRef} ➔ ${pr.baseRef}',
                  style: typo.mono.copyWith(fontSize: 10, color: colors.text2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailPanel(AppColors colors, AppTypography typo) {
    final pr = _selectedPr!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Cabeçalho do Detalhe
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colors.panel,
            border: Border(bottom: BorderSide(color: colors.border)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '#${pr.number} - ${pr.title}',
                      style: typo.title.copyWith(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    icon: _isCheckingOut
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(sc.LucideIcons.gitBranch, size: 14),
                    label: Text(
                      _isCheckingOut ? 'Checkout...' : 'Checkout Local',
                    ),
                    onPressed: _isCheckingOut ? null : _checkoutSelectedPr,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Criado por ${pr.author} · ${pr.headRef} ➔ ${pr.baseRef} · Status: ${pr.state.toUpperCase()}',
                style: typo.mono.copyWith(color: colors.text2, fontSize: 11),
              ),
              if (_actionMessage != null) ...[
                const SizedBox(height: 6),
                Text(
                  _actionMessage!,
                  style: typo.mono.copyWith(color: colors.accent, fontSize: 11),
                ),
              ],
            ],
          ),
        ),

        // Corpo do Detalhe
        Expanded(
          child: _isLoadingDetail
              ? const Center(child: CircularProgressIndicator())
              : _detailError != null
              ? Center(
                  child: Text(
                    'Erro ao carregar detalhes: $_detailError',
                    style: typo.body.copyWith(
                      color: colors.error,
                      fontSize: 12,
                    ),
                  ),
                )
              : _buildDetailContent(colors, typo),
        ),
      ],
    );
  }

  Widget _buildDetailContent(AppColors colors, AppTypography typo) {
    final detail = _selectedPrDetail;
    if (detail == null) {
      return const SizedBox.shrink();
    }

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          LayoutBuilder(
            builder: (context, constraints) => TabBar(
              isScrollable: constraints.maxWidth < 480,
              labelColor: colors.accent,
              unselectedLabelColor: colors.text2,
              indicatorColor: colors.accent,
              tabs: [
                Tab(text: 'Descrição (${detail.pr.body.isEmpty ? 0 : 1})'),
                Tab(text: 'Arquivos Alterados (${detail.changedFiles.length})'),
                Tab(text: 'Comentários (${detail.comments.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // 1. Descrição
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: SelectableText(
                    detail.pr.body.isEmpty
                        ? 'Nenhuma descrição fornecida.'
                        : detail.pr.body,
                    style: typo.body.copyWith(color: colors.text, fontSize: 13),
                  ),
                ),

                // 2. Arquivos alterados
                detail.changedFiles.isEmpty
                    ? Center(
                        child: Text(
                          'Nenhum arquivo listado.',
                          style: typo.body.copyWith(
                            color: colors.text3,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: detail.changedFiles.length,
                        itemBuilder: (context, idx) {
                          final f = detail.changedFiles[idx];
                          return InkWell(
                            onTap: () => _openFile(f),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 5,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: colors.panel2,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: Text(
                                      f.status,
                                      style: typo.mono.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: f.status == 'A'
                                            ? Colors.green
                                            : (f.status == 'D'
                                                  ? colors.error
                                                  : colors.accent),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          f.path,
                                          style: typo.mono.copyWith(
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (f.previousPath != null)
                                          Text(
                                            'De: ${f.previousPath}',
                                            style: typo.mono.copyWith(
                                              fontSize: 11,
                                              color: colors.text2,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                // 3. Comentários e Formulário de Adicionar Comentário
                Column(
                  children: [
                    Expanded(
                      child: detail.comments.isEmpty
                          ? Center(
                              child: Text(
                                'Nenhum comentário na revisão.',
                                style: typo.body.copyWith(
                                  color: colors.text3,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(12),
                              itemCount: detail.comments.length,
                              separatorBuilder: (context, index) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, idx) {
                                final c = detail.comments[idx];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: colors.panel,
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: colors.border),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            c.author,
                                            style: typo.label.copyWith(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          if (c.path != null)
                                            Expanded(
                                              child: Text(
                                                '${c.path}${c.line != null ? ':${c.line}' : ''}',
                                                style: typo.mono.copyWith(
                                                  color: colors.accent,
                                                  fontSize: 11,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                        c.body,
                                        style: typo.body.copyWith(
                                          color: colors.text,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                    Divider(height: 1, color: colors.border),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentController,
                              enabled: !_isCheckingOut && !_isSubmittingComment,
                              maxLines: 2,
                              decoration: const InputDecoration(
                                hintText: 'Escreva um comentário de revisão...',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _isSubmittingComment
                                ? null
                                : _submitComment,
                            child: _isSubmittingComment
                                ? const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Comentar'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
