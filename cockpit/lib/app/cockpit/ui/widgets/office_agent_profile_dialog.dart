import 'dart:async';

import 'package:cockpit/app/cockpit/domain/entities/project.dart';
import 'package:cockpit/app/cockpit/ui/session/terminal_session.dart';
import 'package:cockpit/app/cockpit/ui/widgets/office_character_editor_dialog.dart';
import 'package:cockpit/app/core/domain/entities/harness.dart';
import 'package:cockpit/app/core/ui/themes/themes.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

Future<void> showOfficeAgentProfile(
  BuildContext context, {
  required TerminalSession session,
  required Project project,
  required VoidCallback onOpenTerminal,
  required ValueChanged<String> onRename,
  String? officeName,
  OfficeAppearanceLoader? loadAppearance,
  Map<String, String> initialAppearance = const <String, String>{},
  ValueChanged<Map<String, String>>? onSaveAppearance,
}) => shad.showDialog<void>(
  context: context,
  barrierColor: context.colors.scrim,
  builder: (dialogContext) => _OfficeAgentProfileDialog(
    session: session,
    project: project,
    onOpenTerminal: onOpenTerminal,
    onRename: onRename,
    officeName: officeName,
    loadAppearance: loadAppearance,
    initialAppearance: initialAppearance,
    onSaveAppearance: onSaveAppearance,
  ),
);

class _OfficeAgentProfileDialog extends StatefulWidget {
  const _OfficeAgentProfileDialog({
    required this.session,
    required this.project,
    required this.onOpenTerminal,
    required this.onRename,
    this.officeName,
    this.loadAppearance,
    this.initialAppearance = const <String, String>{},
    this.onSaveAppearance,
  });

  final TerminalSession session;
  final Project project;
  final VoidCallback onOpenTerminal;
  final ValueChanged<String> onRename;
  final String? officeName;
  final OfficeAppearanceLoader? loadAppearance;
  final Map<String, String> initialAppearance;
  final ValueChanged<Map<String, String>>? onSaveAppearance;

  @override
  State<_OfficeAgentProfileDialog> createState() =>
      _OfficeAgentProfileDialogState();
}

class _OfficeAgentProfileDialogState extends State<_OfficeAgentProfileDialog> {
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSessionChanged);
    _clock = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _onSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text:
          widget.session.manualLabel ??
          widget.officeName ??
          widget.session.title,
    );
    final name = await shad.showDialog<String>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (dialogContext) => shad.AlertDialog(
        title: Text(context.t.cockpit.officeWorld.editAgentName),
        content: SizedBox(
          width: 340,
          child: shad.TextField(
            controller: controller,
            placeholder: Text(context.t.cockpit.officeWorld.agentName),
            autofocus: true,
            maxLength: 40,
          ),
        ),
        actions: [
          shad.OutlineButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(context.t.common.cancel),
          ),
          shad.PrimaryButton(
            onPressed: () => Navigator.of(dialogContext).pop(controller.text),
            child: Text(context.t.common.save),
          ),
        ],
      ),
    );
    controller.dispose();
    final trimmed = name?.trim();
    if (trimmed != null && trimmed.isNotEmpty) widget.onRename(trimmed);
  }

  Future<void> _editAppearance() async {
    final load = widget.loadAppearance;
    final save = widget.onSaveAppearance;
    if (load == null || save == null) return;
    await showOfficeCharacterEditor(
      context,
      load: load,
      initialParts: widget.initialAppearance,
      onSave: save,
    );
  }

  @override
  void dispose() {
    _clock?.cancel();
    widget.session.removeListener(_onSessionChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.t.cockpit.officeWorld;
    final colors = context.colors;
    final session = widget.session;
    final project = widget.project;
    final harness = session.activeHarness;
    final displayName =
        (session.manualLabel ?? widget.officeName ?? session.title)
            .trim()
            .isNotEmpty
        ? (session.manualLabel ?? widget.officeName ?? session.title).trim()
        : harness == null
        ? 'Cockpit'
        : HarnessCatalog.specs[harness]?.label ?? 'Cockpit';
    final status = switch (session.status) {
      TerminalStatus.working => tr.working,
      TerminalStatus.waiting => tr.waiting,
      TerminalStatus.idle => tr.idle,
    };
    final elapsed = DateTime.now().difference(session.createdAt);
    final duration = _formatDuration(elapsed);

    return shad.AlertDialog(
      title: Text(
        tr.agentProfile,
        style: context.typo.title.copyWith(fontSize: 16, color: colors.text),
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 460,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: context.typo.title.copyWith(
                        fontSize: 18,
                        color: colors.text,
                      ),
                    ),
                  ),
                  shad.IconButton.ghost(
                    icon: const Text('✎'),
                    onPressed: _editName,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _ProfileValue(label: tr.project, value: project.name),
              _ProfileValue(
                label: tr.provider,
                value: harness == null
                    ? 'Cockpit'
                    : HarnessCatalog.specs[harness]?.label ?? 'Cockpit',
              ),
              _ProfileValue(label: tr.currentStatus, value: status),
              _ProfileValue(label: tr.sessionDuration, value: duration),
              _ProfileValue(
                label: tr.workingDirectory,
                value: session.currentDirectory ?? session.workingDirectory,
                monospace: true,
              ),
              const SizedBox(height: 12),
              Text(
                tr.recentActivity,
                style: context.typo.label.copyWith(color: colors.text2),
              ),
              const SizedBox(height: 4),
              if (session.officeStatusHistory.isEmpty)
                _TimelineRow(
                  icon: session.status == TerminalStatus.waiting ? '✋' : '⚙️',
                  text: _statusEventLabel(
                    session.status,
                    working: tr.workingInTerminal,
                    waiting: tr.waitingInTerminal,
                    idle: tr.turnCompleted,
                  ),
                  time: '—',
                )
              else
                for (final event in session.officeStatusHistory.reversed.take(
                  8,
                ))
                  _TimelineRow(
                    icon: switch (event.status) {
                      TerminalStatus.working => '⚙️',
                      TerminalStatus.waiting => '✋',
                      TerminalStatus.idle => '✅',
                    },
                    text: _statusEventLabel(
                      event.status,
                      working: tr.workingInTerminal,
                      waiting: tr.waitingInTerminal,
                      idle: tr.turnCompleted,
                    ),
                    time: _formatClock(event.at),
                  ),
              const SizedBox(height: 8),
              Text(
                tr.statsPending,
                style: context.typo.body.copyWith(
                  fontSize: 12,
                  color: colors.text3,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (widget.loadAppearance != null && widget.onSaveAppearance != null)
          shad.OutlineButton(
            onPressed: _editAppearance,
            child: Text(tr.editAppearance),
          ),
        shad.OutlineButton(onPressed: _editName, child: Text(tr.editAgentName)),
        shad.PrimaryButton(
          onPressed: () {
            Navigator.of(context).pop();
            widget.onOpenTerminal();
          },
          child: Text(tr.openTerminal),
        ),
      ],
    );
  }
}

class _ProfileValue extends StatelessWidget {
  const _ProfileValue({
    required this.label,
    required this.value,
    this.monospace = false,
  });

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: context.typo.body.copyWith(
                fontSize: 12,
                color: colors.text3,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: (monospace ? context.typo.mono : context.typo.body)
                  .copyWith(fontSize: 12, color: colors.text),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    required this.icon,
    required this.text,
    required this.time,
  });

  final String icon;
  final String text;
  final String time;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Text(icon),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: context.typo.body.copyWith(
              fontSize: 12,
              color: context.colors.text,
            ),
          ),
        ),
        Text(
          time,
          style: context.typo.label.copyWith(color: context.colors.text3),
        ),
      ],
    ),
  );
}

String _statusEventLabel(
  TerminalStatus status, {
  required String working,
  required String waiting,
  required String idle,
}) => switch (status) {
  TerminalStatus.working => working,
  TerminalStatus.waiting => waiting,
  TerminalStatus.idle => idle,
};

String _formatClock(DateTime dateTime) =>
    '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

String _formatDuration(Duration duration) {
  final totalMinutes = duration.inMinutes;
  if (totalMinutes < 1) return '< 1 min';
  final hours = totalMinutes ~/ 60;
  final minutes = totalMinutes % 60;
  if (hours < 1) return '$minutes min';
  if (hours < 24) return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
  final days = hours ~/ 24;
  final leftHours = hours % 24;
  return '${days}d ${leftHours}h';
}
