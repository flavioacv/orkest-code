import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Pede uma referência Git curta para ações que exigem um destino.
Future<String?> showGitTextInputDialog(
  BuildContext context, {
  required String title,
  required String placeholder,
  required String confirmLabel,
  String? initialValue,
  bool allowEmpty = false,
}) => showDialog<String>(
  context: context,
  barrierColor: context.colors.scrim,
  builder: (_) => _GitTextInputDialog(
    title: title,
    placeholder: placeholder,
    confirmLabel: confirmLabel,
    initialValue: initialValue,
    allowEmpty: allowEmpty,
  ),
);

class _GitTextInputDialog extends StatefulWidget {
  const _GitTextInputDialog({
    required this.title,
    required this.placeholder,
    required this.confirmLabel,
    this.initialValue,
    required this.allowEmpty,
  });

  final String title, placeholder, confirmLabel;
  final String? initialValue;
  final bool allowEmpty;

  @override
  State<_GitTextInputDialog> createState() => _GitTextInputDialogState();
}

class _GitTextInputDialogState extends State<_GitTextInputDialog> {
  late final _input = TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _input.text.trim();
    if ((!widget.allowEmpty && value.isEmpty) || value.startsWith('-')) return;
    Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(widget.title),
    content: SizedBox(
      width: 360,
      child: TextField(
        controller: _input,
        autofocus: true,
        onSubmitted: (_) => _submit(),
        placeholder: Text(widget.placeholder),
      ),
    ),
    actions: [
      OutlineButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(context.t.common.cancel),
      ),
      PrimaryButton(onPressed: _submit, child: Text(widget.confirmLabel)),
    ],
  );
}
