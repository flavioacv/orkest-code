import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/services.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/core/ui/widgets/code_highlight.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Reviews an immutable full document snapshot with one editable draft per conflict block.
/// Once all conflicts are explicitly resolved, the complete document can be reviewed,
/// edited and applied back to the file buffer as a single atomic change.
Future<String?> showMergeDocumentEditor(
  BuildContext context, {
  required String text,
  int initialConflictIndex = 0,
  String? language,
  String? fileName,
  List<ConflictBlock>? blocks,
  GitConflictStages? stages,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  barrierColor: context.colors.scrim,
  builder: (_) => MergeDocumentEditor(
    text: text,
    blocks: blocks,
    stages: stages,
    initialConflictIndex: initialConflictIndex,
    language: language,
    fileName: fileName,
  ),
);

class MergeDocumentEditor extends StatefulWidget {
  const MergeDocumentEditor({
    super.key,
    required this.text,
    this.blocks,
    this.stages,
    this.initialConflictIndex = 0,
    this.language,
    this.fileName,
  });

  final String text;
  final List<ConflictBlock>? blocks;
  final GitConflictStages? stages;
  final int initialConflictIndex;
  final String? language;
  final String? fileName;

  @override
  State<MergeDocumentEditor> createState() => _MergeDocumentEditorState();
}

class _MergeDocumentEditorState extends State<MergeDocumentEditor> {
  final GitConflictService _conflictService = const GitConflictService();
  late final List<ConflictBlock> _blocks;
  late final List<CodeEditingController> _drafts;
  late final List<FocusNode> _focusNodes;
  late final List<bool> _resolved;
  late int _currentIndex;

  bool _showingFullDocument = false;
  CodeEditingController? _fullDocController;
  final FocusNode _fullDocFocus = FocusNode();
  String? _composedSnapshot;

  @override
  void initState() {
    super.initState();
    _blocks = widget.blocks ?? _conflictService.parseConflicts(widget.text);
    _drafts = _blocks
        .map(
          (b) =>
              CodeEditingController(text: b.ours, language: widget.language)
                ..addListener(_onDraftChanged),
        )
        .toList();
    _focusNodes = _blocks.map((_) => FocusNode()).toList();
    _resolved = List<bool>.filled(_blocks.length, false);
    _currentIndex = _blocks.isEmpty
        ? 0
        : widget.initialConflictIndex.clamp(0, _blocks.length - 1);
  }

  void _onDraftChanged() => setState(() {});

  @override
  void dispose() {
    for (final draft in _drafts) {
      draft.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    _fullDocController?.dispose();
    _fullDocFocus.dispose();
    super.dispose();
  }

  void _gotoIndex(int index) {
    if (index < 0 || index >= _blocks.length) return;
    setState(() => _currentIndex = index);
  }

  void _chooseCurrent(ConflictResolution resolution) {
    if (_currentIndex < 0 || _currentIndex >= _blocks.length) return;
    final value = _conflictService.resolutionText(
      _blocks[_currentIndex],
      resolution,
    );
    _drafts[_currentIndex].value = TextEditingValue(
      text: value,
      selection: const TextSelection.collapsed(offset: 0),
    );
    _resolved[_currentIndex] = true;
    setState(() {});
  }

  bool get _allResolved => _blocks.isNotEmpty && _resolved.every((r) => r);

  bool get _hasAnyUnresolvedMarkers =>
      _drafts.any((d) => _conflictService.hasUnresolvedMarkers(d.text));

  bool get _canOpenFullDocument => _allResolved && !_hasAnyUnresolvedMarkers;

  void _openFullDocument() {
    if (!_canOpenFullDocument) return;
    final results = _drafts.map((d) => d.text).toList();
    final composed = _conflictService.resolveDocument(
      text: widget.text,
      results: results,
    );
    _composedSnapshot = composed;
    _fullDocController?.dispose();
    _fullDocController = CodeEditingController(
      text: composed,
      language: widget.language,
    )..addListener(() => setState(() {}));
    setState(() {
      _showingFullDocument = true;
    });
  }

  Future<void> _backToBlocks() async {
    final tr = context.t.orkest.fileTreePanel;
    final currentFullText = _fullDocController?.text;
    if (_composedSnapshot != null && currentFullText != _composedSnapshot) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr.discardFinalEditsTitle),
          content: Text(tr.discardFinalEditsMessage),
          actions: [
            OutlineButton(
              key: const ValueKey('merge-cancel-discard'),
              onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(context.t.common.cancel),
            ),
            DestructiveButton(
              key: const ValueKey('merge-confirm-discard'),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(tr.discardEdits),
            ),
          ],
        ),
      );
      if (discard != true) return;
    }
    setState(() {
      _showingFullDocument = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final size = MediaQuery.sizeOf(context);

    if (_blocks.isEmpty) {
      return AlertDialog(
        title: Text(tr.reviewDocument),
        content: Text(tr.conflictsBanner(count: 0)),
        actions: [
          OutlineButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(context.t.common.cancel),
          ),
        ],
      );
    }

    final dialogWidth = size.width < 1220 ? size.width * .95 : 1150.0;
    final dialogHeight = size.height < 900 ? size.height * .75 : 680.0;

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.arrowUp, alt: true): () {
          if (!_showingFullDocument && _currentIndex > 0) {
            _gotoIndex(_currentIndex - 1);
          }
        },
        const SingleActivator(LogicalKeyboardKey.arrowDown, alt: true): () {
          if (!_showingFullDocument && _currentIndex < _blocks.length - 1) {
            _gotoIndex(_currentIndex + 1);
          }
        },
      },
      child: Focus(
        autofocus: true,
        child: AlertDialog(
          title: _buildTitle(context, tr),
          content: SizedBox(
            width: dialogWidth,
            height: dialogHeight,
            child: _showingFullDocument
                ? _buildFullDocumentView(context, tr)
                : _buildBlockReviewView(context, tr),
          ),
          actions: _showingFullDocument
              ? _buildFullDocumentActions(context, tr)
              : _buildBlockReviewActions(context, tr),
        ),
      ),
    );
  }

  Widget _buildTitle(BuildContext context, dynamic tr) {
    if (_showingFullDocument) {
      final label = widget.fileName != null
          ? '${tr.reviewFullDocument} • ${widget.fileName}'
          : tr.reviewFullDocument;
      return Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: context.typo.title.copyWith(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlineButton(
            key: const ValueKey('merge-back-to-blocks'),
            onPressed: _backToBlocks,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.arrowLeft, size: 13),
                const SizedBox(width: 4),
                Text(tr.backToBlocks),
              ],
            ),
          ),
        ],
      );
    }

    final label = widget.fileName != null
        ? '${tr.reviewDocument} • ${widget.fileName}'
        : tr.reviewDocument;
    final resolvedCount = _resolved.where((r) => r).length;
    final isCurrentResolved = _resolved[_currentIndex];

    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: context.typo.title.copyWith(fontSize: 15),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          tr.conflictProgress(
            current: _currentIndex + 1,
            total: _blocks.length,
            resolved: resolvedCount,
          ),
          style: context.typo.label.copyWith(
            fontSize: 12,
            color: context.colors.text2,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: isCurrentResolved
                ? context.colors.gitStaged.withValues(alpha: 0.15)
                : context.colors.error.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isCurrentResolved
                  ? context.colors.gitStaged.withValues(alpha: 0.4)
                  : context.colors.error.withValues(alpha: 0.4),
            ),
          ),
          child: Text(
            isCurrentResolved ? tr.resolvedBadge : tr.unresolvedBadge,
            style: context.typo.label.copyWith(
              fontSize: 11,
              color: isCurrentResolved
                  ? context.colors.gitStaged
                  : context.colors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlockReviewView(BuildContext context, dynamic tr) {
    final isCurrentResolved = _resolved[_currentIndex];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            OutlineButton(
              key: const ValueKey('merge-prev-block'),
              onPressed: _currentIndex > 0
                  ? () => _gotoIndex(_currentIndex - 1)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.arrowUp, size: 13),
                  const SizedBox(width: 4),
                  Text(tr.prevConflict),
                ],
              ),
            ),
            const SizedBox(width: 6),
            OutlineButton(
              key: const ValueKey('merge-next-block'),
              onPressed: _currentIndex < _blocks.length - 1
                  ? () => _gotoIndex(_currentIndex + 1)
                  : null,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(tr.nextConflict),
                  const SizedBox(width: 4),
                  const Icon(LucideIcons.arrowDown, size: 13),
                ],
              ),
            ),
            const SizedBox(width: 8),
            OutlineButton(
              key: const ValueKey('merge-toggle-resolved'),
              onPressed: () {
                setState(() {
                  _resolved[_currentIndex] = !_resolved[_currentIndex];
                });
              },
              child: Text(
                isCurrentResolved ? tr.markUnresolved : tr.markResolved,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: MergeConflictComparison(
            key: ValueKey('conflict-comparison-$_currentIndex'),
            block: _blocks[_currentIndex],
            result: _drafts[_currentIndex],
            focus: _focusNodes[_currentIndex],
            language: widget.language,
            onChoose: _chooseCurrent,
          ),
        ),
      ],
    );
  }

  Widget _buildFullDocumentView(BuildContext context, dynamic tr) {
    final invalid = _conflictService.hasUnresolvedMarkers(
      _fullDocController!.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.stages case final stages?) ...[
          Expanded(
            child: _MergeInputs(
              block: ConflictBlock(
                from: 0,
                to: 0,
                startLine: 1,
                endLine: 1,
                ours: stages.ours ?? '',
                theirs: stages.theirs ?? '',
                base: stages.base,
                oursLabel: _blocks.first.oursLabel,
                theirsLabel: _blocks.first.theirsLabel,
              ),
              language: widget.language,
            ),
          ),
          const SizedBox(height: 8),
          Text(tr.mergeResult, style: context.typo.label),
        ],
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.border),
            ),
            child: CodeEditor(
              key: const ValueKey('merge-full-doc-editor'),
              controller: _fullDocController!,
              focusNode: _fullDocFocus,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          invalid ? tr.mergeMarkers : tr.mergePendingSave,
          style: context.typo.label.copyWith(
            fontSize: 11,
            color: invalid ? context.colors.error : context.colors.text3,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildBlockReviewActions(BuildContext context, dynamic tr) {
    return [
      OutlineButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.t.common.cancel),
      ),
      PrimaryButton(
        key: const ValueKey('merge-open-full-doc'),
        onPressed: _canOpenFullDocument ? _openFullDocument : null,
        child: Text(tr.reviewFullDocument),
      ),
    ];
  }

  List<Widget> _buildFullDocumentActions(BuildContext context, dynamic tr) {
    final invalid = _conflictService.hasUnresolvedMarkers(
      _fullDocController!.text,
    );
    return [
      OutlineButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.t.common.cancel),
      ),
      PrimaryButton(
        key: const ValueKey('merge-apply-document'),
        onPressed: invalid
            ? null
            : () => Navigator.of(context).pop(_fullDocController!.text),
        child: Text(tr.mergeApply),
      ),
    ];
  }
}

/// Reviews immutable conflict sides and returns an editable block result.
/// The caller validates the original buffer before applying the returned text.
Future<String?> showMergeConflictEditor(
  BuildContext context, {
  required ConflictBlock block,
  String? language,
}) => showDialog<String>(
  context: context,
  barrierDismissible: false,
  barrierColor: context.colors.scrim,
  builder: (_) => MergeConflictEditor(block: block, language: language),
);

class MergeConflictEditor extends StatefulWidget {
  const MergeConflictEditor({super.key, required this.block, this.language});
  final ConflictBlock block;
  final String? language;
  @override
  State<MergeConflictEditor> createState() => _MergeConflictEditorState();
}

class _MergeConflictEditorState extends State<MergeConflictEditor> {
  late final CodeEditingController _result;
  final FocusNode _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _result = CodeEditingController(
      text: widget.block.ours,
      language: widget.language,
    )..addListener(_changed);
  }

  void _changed() => setState(() {});
  @override
  void dispose() {
    _result.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _choose(ConflictResolution resolution) {
    final value = const GitConflictService().resolutionText(
      widget.block,
      resolution,
    );
    _result.value = TextEditingValue(
      text: value,
      selection: const TextSelection.collapsed(offset: 0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final size = MediaQuery.sizeOf(context);
    final invalid = const GitConflictService().hasUnresolvedMarkers(
      _result.text,
    );
    return AlertDialog(
      title: Text(
        tr.reviewConflict,
        style: context.typo.title.copyWith(fontSize: 15),
      ),
      content: SizedBox(
        width: size.width < 1220 ? size.width * .9 : 1100,
        height: size.height < 900 ? size.height * .68 : 620,
        child: MergeConflictComparison(
          block: widget.block,
          language: widget.language,
          result: _result,
          focus: _focus,
          onChoose: _choose,
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
        PrimaryButton(
          key: const ValueKey('merge-apply'),
          onPressed: invalid
              ? null
              : () => Navigator.of(context).pop(_result.text),
          child: Text(tr.mergeApply),
        ),
      ],
    );
  }
}

/// Reusable immutable side comparison and editable result, independent of routes.
class MergeConflictComparison extends StatefulWidget {
  const MergeConflictComparison({
    super.key,
    required this.block,
    required this.result,
    required this.focus,
    required this.onChoose,
    this.language,
  });
  final ConflictBlock block;
  final CodeEditingController result;
  final FocusNode focus;
  final ValueChanged<ConflictResolution> onChoose;
  final String? language;
  @override
  State<MergeConflictComparison> createState() =>
      _MergeConflictComparisonState();
}

class _MergeConflictComparisonState extends State<MergeConflictComparison> {
  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final invalid = const GitConflictService().hasUnresolvedMarkers(
      widget.result.text,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _MergeInputs(block: widget.block, language: widget.language),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              tr.mergeResult,
              style: context.typo.label.copyWith(color: context.colors.text2),
            ),
            OutlineButton(
              key: const ValueKey('merge-use-ours'),
              onPressed: () => widget.onChoose(ConflictResolution.ours),
              child: Text(tr.acceptAllOurs),
            ),
            OutlineButton(
              key: const ValueKey('merge-use-theirs'),
              onPressed: () => widget.onChoose(ConflictResolution.theirs),
              child: Text(tr.acceptAllTheirs),
            ),
            OutlineButton(
              key: const ValueKey('merge-use-both'),
              onPressed: () => widget.onChoose(ConflictResolution.both),
              child: Text(tr.acceptBoth),
            ),
            if (widget.block.base != null)
              OutlineButton(
                key: const ValueKey('merge-use-base'),
                onPressed: () => widget.onChoose(ConflictResolution.base),
                child: Text(tr.mergeBase),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: context.colors.border),
            ),
            child: CodeEditor(
              key: const ValueKey('merge-result-editor'),
              controller: widget.result,
              focusNode: widget.focus,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          invalid ? tr.mergeMarkers : tr.mergePendingSave,
          style: context.typo.label.copyWith(
            fontSize: 11,
            color: invalid ? context.colors.error : context.colors.text3,
          ),
        ),
      ],
    );
  }
}

class _MergeSource extends StatelessWidget {
  const _MergeSource({
    required this.title,
    required this.text,
    this.language,
    this.accent,
  });
  final String title;
  final String text;
  final Color? accent;
  final String? language;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: context.colors.panel,
      border: Border.all(color: context.colors.border),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          color: accent?.withValues(alpha: .12),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.typo.label.copyWith(
              fontSize: 11,
              color: context.colors.text2,
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: Text(
                        List.generate(
                          text.split('\n').length,
                          (i) => '${i + 1}',
                        ).join('\n'),
                        textAlign: TextAlign.right,
                        style: context.typo.mono.copyWith(
                          fontSize: 12,
                          color: context.colors.text4,
                        ),
                      ),
                    ),
                    SelectionArea(
                      child: Text.rich(
                        buildCodeSpan(
                              context,
                              source: text,
                              language: language,
                              baseStyle: context.typo.mono.copyWith(
                                fontSize: 12,
                                color: context.colors.text,
                              ),
                            ) ??
                            TextSpan(text: text),
                        softWrap: false,
                        style: context.typo.mono.copyWith(
                          fontSize: 12,
                          color: context.colors.text,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

/// Two immutable inputs above the result; the common ancestor is optional.
class _MergeInputs extends StatefulWidget {
  const _MergeInputs({required this.block, this.language});
  final ConflictBlock block;
  final String? language;
  @override
  State<_MergeInputs> createState() => _MergeInputsState();
}

class _MergeInputsState extends State<_MergeInputs> {
  bool _showBase = false;
  int _source = 0;
  @override
  Widget build(BuildContext context) {
    final tr = context.t.orkest.fileTreePanel;
    final labels = [
      '${tr.mergeOurs}: ${widget.block.oursLabel}',
      '${tr.mergeTheirs}: ${widget.block.theirsLabel}',
      if (_showBase && widget.block.base != null) tr.mergeBase,
    ];
    final contents = [
      widget.block.ours,
      widget.block.theirs,
      if (_showBase && widget.block.base != null) widget.block.base!,
    ];
    Widget source(int i) => _MergeSource(
      title: labels[i],
      text: contents[i],
      language: widget.language,
      accent: i == 0
          ? context.colors.accent
          : i == 1
          ? context.colors.gitStaged
          : context.colors.text3,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.block.base != null)
          Align(
            alignment: Alignment.centerRight,
            child: GhostButton(
              key: const ValueKey('merge-toggle-base'),
              onPressed: () => setState(() {
                _showBase = !_showBase;
                _source = 0;
              }),
              child: Text(
                _showBase
                    ? context.t.orkest.gitEvolution.hideBase
                    : context.t.orkest.gitEvolution.showBase,
              ),
            ),
          ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 720) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < labels.length; i++) ...[
                      if (i > 0) const SizedBox(width: 8),
                      Expanded(child: source(i)),
                    ],
                  ],
                );
              }
              return Column(
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      for (var i = 0; i < labels.length; i++)
                        GhostButton(
                          onPressed: () => setState(() => _source = i),
                          child: Text(
                            i == 0
                                ? tr.mergeOurs
                                : i == 1
                                ? tr.mergeTheirs
                                : tr.mergeBase,
                          ),
                        ),
                    ],
                  ),
                  Expanded(child: source(_source.clamp(0, labels.length - 1))),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
