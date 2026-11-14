import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as sc;
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';

/// Children are requested only when expanded, scoped to one inspection epoch.
class DebugVariableTree extends StatefulWidget {
  const DebugVariableTree({
    super.key,
    required this.controller,
    required this.name,
    this.value,
    required this.reference,
    this.depth = 0,
    this.parentReference = 0,
    this.initiallyExpanded = false,
  });
  final DebugSessionController controller;
  final String name;
  final String? value;
  final int reference;
  final int depth;
  final int parentReference;
  final bool initiallyExpanded;
  @override
  State<DebugVariableTree> createState() => _DebugVariableTreeState();
}

class _DebugVariableTreeState extends State<DebugVariableTree> {
  bool _expanded = false;
  Future<List<DapVariable>>? _children;

  Future<void> _edit() async {
    var value = widget.value ?? '';
    final tr = context.t.orkest.debugWorkbench;
    final result = await sc.showDialog<bool>(
      context: context,
      builder: (dialog) => sc.AlertDialog(
        title: Text(widget.name),
        content: SizedBox(
          width: 360,
          child: Material(
            color: Colors.transparent,
            child: TextFormField(
              initialValue: value,
              onChanged: (text) => value = text,
              autofocus: true,
              onFieldSubmitted: (_) => Navigator.of(dialog).pop(true),
            ),
          ),
        ),
        actions: [
          sc.GhostButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(tr.cancel),
          ),
          sc.PrimaryButton(
            onPressed: () => Navigator.of(dialog).pop(true),
            child: Text(tr.apply),
          ),
        ],
      ),
    );
    if (mounted && result == true) {
      await widget.controller.setVariable(
        widget.parentReference,
        widget.name,
        value,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded && widget.reference > 0;
    if (_expanded) _children = widget.controller.variablesFor(widget.reference);
  }

  @override
  Widget build(BuildContext context) {
    final expandable = widget.reference > 0 && widget.depth < 20;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: expandable
              ? () => setState(() {
                  _expanded = !_expanded;
                  _children ??= widget.controller.variablesFor(
                    widget.reference,
                  );
                })
              : null,
          child: Padding(
            padding: EdgeInsets.fromLTRB(4 + widget.depth * 12, 4, 8, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 16,
                  child: expandable
                      ? Icon(
                          _expanded ? Icons.expand_more : Icons.chevron_right,
                          size: 14,
                          color: context.colors.text3,
                        )
                      : null,
                ),
                Expanded(
                  child: SelectableText.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: widget.name,
                          style: context.typo.mono.copyWith(
                            color: context.colors.accent,
                            fontSize: 11,
                          ),
                        ),
                        if (widget.value != null)
                          TextSpan(
                            text: ': ${widget.value}',
                            style: context.typo.mono.copyWith(
                              color: context.colors.text,
                              fontSize: 11,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (widget.parentReference > 0 &&
                    widget.controller.capabilities.supportsSetVariable)
                  SizedBox(
                    width: 24,
                    height: 22,
                    child: IconButton(
                      padding: EdgeInsets.zero,
                      tooltip: context.t.orkest.debugWorkbench.editValue,
                      onPressed: _edit,
                      icon: Icon(
                        Icons.edit_outlined,
                        size: 12,
                        color: context.colors.text3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (_expanded)
          FutureBuilder<List<DapVariable>>(
            future: _children,
            builder: (context, snapshot) =>
                snapshot.connectionState != ConnectionState.done
                ? Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      context.t.orkest.debugWorkbench.loading,
                      style: context.typo.label,
                    ),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final variable
                          in snapshot.data ?? const <DapVariable>[])
                        DebugVariableTree(
                          key: ValueKey('${widget.reference}:${variable.name}'),
                          controller: widget.controller,
                          name: variable.name,
                          value: variable.value,
                          reference: variable.variablesReference,
                          depth: widget.depth + 1,
                          parentReference: widget.reference,
                        ),
                      if ((snapshot.data ?? const []).isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text(
                            context.t.orkest.debugWorkbench.noVariables,
                            style: context.typo.label.copyWith(
                              color: context.colors.text3,
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
