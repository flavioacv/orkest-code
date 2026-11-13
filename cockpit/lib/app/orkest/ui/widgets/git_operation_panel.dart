import 'dart:async';
import 'dart:io';

import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';
import 'package:orkest_code/app/orkest/ui/widgets/confirm_dialog.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:path/path.dart' as p;
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Repository-level integration state survives resolving or closing a file.
class GitOperationPanel extends StatefulWidget {
  const GitOperationPanel({
    super.key,
    required this.root,
    required this.info,
    required this.onCommand,
    required this.onOpenFile,
  });
  final String root;
  final GitInfo info;
  final Future<void> Function(List<String> args, String title) onCommand;
  final ValueChanged<String> onOpenFile;

  @override
  State<GitOperationPanel> createState() => _GitOperationPanelState();
}

class _GitOperationPanelState extends State<GitOperationPanel> {
  static const _service = GitConflictService();
  Timer? _timer;
  GitOngoingOperation _operation = GitOngoingOperation.none;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _read();
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _read());
  }

  @override
  void didUpdateWidget(GitOperationPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    _read();
  }

  void _read() {
    var operation = GitOngoingOperation.none;
    String? error;
    try {
      operation = _service.detectOngoingOperation(widget.root);
    } on FileSystemException catch (e) {
      error = e.toString();
    } on FormatException catch (e) {
      error = e.toString();
    }
    if (operation != _operation || error != _error) {
      setState(() {
        _operation = operation;
        _error = error;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _command => switch (_operation) {
    GitOngoingOperation.merge => 'merge',
    GitOngoingOperation.rebase => 'rebase',
    GitOngoingOperation.cherryPick => 'cherry-pick',
    GitOngoingOperation.revert => 'revert',
    GitOngoingOperation.none => '',
  };

  Future<void> _run(bool abort) async {
    if (_busy || _command.isEmpty) return;
    final command = _command;
    final tr = context.t.orkest;
    if (abort) {
      final confirmed = await showConfirmDialog(
        context,
        title: tr.gitEvolution.abortTitle(operation: command),
        message: tr.gitEvolution.abortMessage,
        confirmLabel: tr.fileTreePanel.abortGitOp(op: command),
        danger: true,
      );
      if (!mounted || !confirmed) return;
    }
    setState(() => _busy = true);
    try {
      await widget.onCommand(
        [command, abort ? '--abort' : '--continue'],
        abort
            ? tr.fileTreePanel.abortGitOp(op: command)
            : tr.fileTreePanel.continueGitOp(op: command),
      );
    } finally {
      if (mounted) {
        setState(() => _busy = false);
        _read();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final conflicts = widget.info.files.entries
        .where((e) => e.value == GitFileStatus.conflict)
        .map((e) => e.key)
        .toList();
    if (_operation == GitOngoingOperation.none &&
        conflicts.isEmpty &&
        _error == null) {
      return const SizedBox.shrink();
    }
    final tr = context.t.orkest;
    return Container(
      key: const ValueKey('git-integration-state'),
      margin: const EdgeInsets.all(6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: context.colors.gitConflict.withValues(alpha: .08),
        border: Border.all(
          color: context.colors.gitConflict.withValues(alpha: .4),
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            p.basename(widget.root),
            style: context.typo.mono.copyWith(fontSize: 11),
          ),
          if (_operation != GitOngoingOperation.none)
            Text(
              tr.gitEvolution.operationPending(operation: _command),
              style: context.typo.label,
            ),
          if (_error != null)
            Text(
              tr.gitEvolution.resolutionError(detail: _error!),
              style: context.typo.label.copyWith(color: context.colors.error),
            ),
          Text(
            tr.gitEvolution.remainingFiles(count: conflicts.length),
            style: context.typo.label,
          ),
          if (conflicts.isNotEmpty)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 140),
              child: ListView(
                shrinkWrap: true,
                children: [
                  for (final file in conflicts)
                    GhostButton(
                      key: ValueKey('git-conflict-$file'),
                      onPressed: () => widget.onOpenFile(
                        p.joinAll([widget.root, ...p.posix.split(file)]),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          file,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          if (_operation != GitOngoingOperation.none)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                PrimaryButton(
                  key: const ValueKey('git-integration-continue'),
                  onPressed: _busy || conflicts.isNotEmpty
                      ? null
                      : () => _run(false),
                  child: Text(tr.fileTreePanel.continueGitOp(op: _command)),
                ),
                OutlineButton(
                  key: const ValueKey('git-integration-abort'),
                  onPressed: _busy ? null : () => _run(true),
                  child: Text(tr.fileTreePanel.abortGitOp(op: _command)),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
