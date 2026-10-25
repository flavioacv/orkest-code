import 'dart:async';

import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

/// Shows a read-only mirror of the existing terminal and forwards typed input
/// to its PTY. No second terminal controller/view is created.
Future<void> showOfficeTerminalInteraction(
  BuildContext context,
  TerminalSession session,
) => shad.showDialog<void>(
  context: context,
  barrierColor: context.colors.scrim,
  builder: (_) => _OfficeTerminalInteractionDialog(session: session),
);

class _OfficeTerminalInteractionDialog extends StatefulWidget {
  const _OfficeTerminalInteractionDialog({required this.session});

  final TerminalSession session;

  @override
  State<_OfficeTerminalInteractionDialog> createState() =>
      _OfficeTerminalInteractionDialogState();
}

class _OfficeTerminalInteractionDialogState
    extends State<_OfficeTerminalInteractionDialog> {
  final _input = TextEditingController();
  final _inputFocus = FocusNode();
  Timer? _refresh;
  List<String> _lines = const [];

  @override
  void initState() {
    super.initState();
    _readScreen();
    _refresh = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) _readScreen();
    });
  }

  void _readScreen() {
    try {
      final next = widget.session.terminal.plainLines(limit: 28);
      if (!listEquals(next, _lines) && mounted) setState(() => _lines = next);
    } on StateError {
      // A tab can be closed while this dialog is open.
    }
  }

  void _sendKey(List<int> bytes) {
    try {
      widget.session.sendKeys(bytes);
      _inputFocus.requestFocus();
    } on StateError {
      // The session may have closed concurrently.
    }
  }

  void _sendArrow({required bool up}) {
    try {
      widget.session.sendArrow(up: up);
      _inputFocus.requestFocus();
    } on StateError {
      // The session may have closed concurrently.
    }
  }

  void _submit() {
    final text = _input.text;
    if (text.isEmpty) {
      _sendKey(const [13]);
    } else {
      try {
        widget.session.insertText('$text\r');
      } on StateError {
        // The session may have closed concurrently.
      }
      _input.clear();
    }
    _inputFocus.requestFocus();
  }

  @override
  void dispose() {
    _refresh?.cancel();
    _input.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.t.orkest.officeWorld;
    return shad.AlertDialog(
      title: Text('${tr.liveTerminal} · ${widget.session.displayTitle}'),
      content: SizedBox(
        width: 820,
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: const Color(0xFF101216),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.all(12),
                child: SingleChildScrollView(
                  reverse: true,
                  child: SelectableText(
                    _lines.join('\n'),
                    style: const TextStyle(
                      color: Color(0xFFE2E7EF),
                      fontFamily: 'Menlo',
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: shad.TextField(
                    controller: _input,
                    focusNode: _inputFocus,
                    placeholder: Text(tr.terminalInputPlaceholder),
                    onSubmitted: (_) => _submit(),
                  ),
                ),
                const SizedBox(width: 8),
                shad.PrimaryButton(
                  onPressed: _submit,
                  child: Text(context.t.common.send),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              children: [
                _key('↑', () => _sendArrow(up: true)),
                _key('↓', () => _sendArrow(up: false)),
                _key('Tab', () => _sendKey(const [9])),
                _key('Esc', () => _sendKey(const [27])),
                _key('Ctrl+C', () => _sendKey(const [3])),
                _key('Enter', () => _sendKey(const [13])),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                tr.terminalOfficeHint,
                style: TextStyle(color: colors.text3, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
      actions: [
        shad.OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.close),
        ),
      ],
    );
  }

  Widget _key(String label, VoidCallback onPressed) =>
      shad.OutlineButton(onPressed: onPressed, child: Text(label));
}
