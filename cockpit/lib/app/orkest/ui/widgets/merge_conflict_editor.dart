import 'package:flutter/material.dart' show SelectionArea;
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/core/ui/widgets/code_highlight.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

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
  int _source = 0;
  static final _markers = RegExp(
    r'^(?:<{7}|={7}|>{7}|\|{7})(?:\s|$)',
    multiLine: true,
  );

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
    final labels = [
      '${tr.mergeOurs}: ${widget.block.oursLabel}',
      if (widget.block.base != null) tr.mergeBase,
      '${tr.mergeTheirs}: ${widget.block.theirsLabel}',
    ];
    final contents = [
      widget.block.ours,
      if (widget.block.base != null) widget.block.base!,
      widget.block.theirs,
    ];
    final sections = [
      tr.mergeOurs,
      if (widget.block.base != null) tr.mergeBase,
      tr.mergeTheirs,
    ];
    final invalid = _markers.hasMatch(_result.text);
    Widget source(int index) => _MergeSource(
      title: labels[index],
      text: contents[index],
      language: widget.language,
    );
    return AlertDialog(
      title: Text(
        tr.reviewConflict,
        style: context.typo.title.copyWith(fontSize: 15),
      ),
      content: SizedBox(
        width: size.width < 1220 ? size.width * .9 : 1100,
        height: size.height < 900 ? size.height * .68 : 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                            OutlineButton(
                              onPressed: () => setState(() => _source = i),
                              child: Text(
                                sections[i],
                                style: context.typo.label.copyWith(
                                  color: _source == i
                                      ? context.colors.accent
                                      : context.colors.text3,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Expanded(child: source(_source)),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  tr.mergeResult,
                  style: context.typo.label.copyWith(
                    color: context.colors.text2,
                  ),
                ),
                OutlineButton(
                  key: const ValueKey('merge-use-ours'),
                  onPressed: () => _choose(ConflictResolution.ours),
                  child: Text(tr.acceptAllOurs),
                ),
                OutlineButton(
                  key: const ValueKey('merge-use-theirs'),
                  onPressed: () => _choose(ConflictResolution.theirs),
                  child: Text(tr.acceptAllTheirs),
                ),
                OutlineButton(
                  key: const ValueKey('merge-use-both'),
                  onPressed: () => _choose(ConflictResolution.both),
                  child: Text(tr.acceptBoth),
                ),
                if (widget.block.base != null)
                  OutlineButton(
                    key: const ValueKey('merge-use-base'),
                    onPressed: () => _choose(ConflictResolution.base),
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
                  controller: _result,
                  focusNode: _focus,
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

class _MergeSource extends StatelessWidget {
  const _MergeSource({required this.title, required this.text, this.language});
  final String title;
  final String text;
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
        Padding(
          padding: const EdgeInsets.all(8),
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
                child: SelectionArea(
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
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
