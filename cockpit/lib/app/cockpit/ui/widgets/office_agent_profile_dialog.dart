import 'dart:async';

import 'package:cockpit/app/cockpit/domain/entities/project.dart';
import 'package:cockpit/app/cockpit/ui/session/terminal_session.dart';
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
}) => shad.showDialog<void>(
  context: context,
  barrierColor: context.colors.scrim,
  builder: (dialogContext) => _OfficeAgentProfileDialog(
    session: session,
    project: project,
    onOpenTerminal: onOpenTerminal,
  ),
);

class _OfficeAgentProfileDialog extends StatefulWidget {
  const _OfficeAgentProfileDialog({
    required this.session,
    required this.project,
    required this.onOpenTerminal,
  });

  final TerminalSession session;
  final Project project;
  final VoidCallback onOpenTerminal;

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
    final displayName = session.title.trim().isNotEmpty
        ? session.title.trim()
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
        constraints: const BoxConstraints(maxWidth: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              displayName,
              style: context.typo.title.copyWith(
                fontSize: 18,
                color: colors.text,
              ),
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
            const SizedBox(height: 10),
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
      actions: [
        shad.OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.cancel),
        ),
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
