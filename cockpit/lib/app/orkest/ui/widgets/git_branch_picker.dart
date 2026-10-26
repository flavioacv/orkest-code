import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Future<void> showGitBranchPicker(BuildContext context, String root) =>
    showDialog<void>(
      context: context,
      barrierColor: context.colors.scrim,
      builder: (_) => _GitBranchPicker(root: root),
    );

class _GitBranchPicker extends StatefulWidget {
  const _GitBranchPicker({required this.root});
  final String root;
  @override
  State<_GitBranchPicker> createState() => _GitBranchPickerState();
}

class _GitBranchPickerState extends State<_GitBranchPicker> {
  final _search = TextEditingController();
  final _newBranch = TextEditingController();
  List<GitBranch> _branches = const [];
  GitBranchError? _error;
  bool _loading = true;

  OrkestViewModel get _vm => context.read<OrkestViewModel>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    _newBranch.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _vm.git.branches(widget.root);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (result) {
        case Success(:final value):
          _branches = value;
        case Failure(:final error):
          _error = error;
      }
    });
  }

  Future<void> _finish(Result<void, GitBranchError> result) async {
    switch (result) {
      case Success():
        final project = _vm.selectedProject;
        if (project != null) await _vm.refreshGitProject(project.id);
        if (mounted) Navigator.of(context).pop();
      case Failure(:final error):
        if (mounted) setState(() => _error = error);
    }
  }

  String _message(BuildContext context, GitBranchError error) {
    final tr = context.t.orkest.branchPicker;
    return switch (error.kind) {
      GitBranchErrorKind.listFailed => tr.listFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.invalidName => tr.invalidName,
      GitBranchErrorKind.alreadyExists => tr.alreadyExists,
      GitBranchErrorKind.dirtyWorktree => tr.dirtyWorktree,
      GitBranchErrorKind.checkoutFailed => tr.checkoutFailed(
        detail: error.detail ?? '',
      ),
      GitBranchErrorKind.createFailed => tr.createFailed(
        detail: error.detail ?? '',
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final branches = _branches
        .where((b) => b.name.toLowerCase().contains(_search.text.toLowerCase()))
        .toList();
    return AlertDialog(
      title: Text(context.t.orkest.branchPicker.title),
      content: SizedBox(
        width: 440,
        height: 430,
        child: Column(
          children: [
            TextField(
              controller: _search,
              autofocus: true,
              placeholder: Text(
                context.t.orkest.branchPicker.searchPlaceholder,
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                color: colors.error.withValues(alpha: .12),
                child: Text(
                  _message(context, _error!),
                  style: context.typo.label.copyWith(color: colors.error),
                ),
              ),
            if (_error != null) const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : branches.isEmpty
                  ? Center(
                      child: Text(context.t.orkest.branchPicker.noBranches),
                    )
                  : ListView.builder(
                      itemCount: branches.length,
                      itemBuilder: (context, i) {
                        final branch = branches[i];
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: branch.isCurrent || branch.isUsedByWorktree
                              ? null
                              : () async => _finish(
                                  await _vm.git.checkoutBranch(
                                    widget.root,
                                    branch,
                                  ),
                                ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            child: Row(
                              children: [
                                Icon(
                                  branch.isRemote
                                      ? Icons.cloud_outlined
                                      : Icons.account_tree_outlined,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(branch.name)),
                                if (branch.isCurrent)
                                  Icon(Icons.check, color: colors.ok, size: 18),
                                if (branch.isUsedByWorktree &&
                                    !branch.isCurrent)
                                  AppTooltip(
                                    message: context
                                        .t
                                        .orkest
                                        .branchPicker
                                        .usedByWorktree,
                                    child: Icon(
                                      Icons.lock_outline,
                                      color: colors.text4,
                                      size: 16,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _newBranch,
                    placeholder: Text(
                      context.t.orkest.branchPicker.newBranchPlaceholder,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PrimaryButton(
                  onPressed: () async => _finish(
                    await _vm.git.createBranch(widget.root, _newBranch.text),
                  ),
                  child: Text(context.t.orkest.branchPicker.createBranch),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        OutlineButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(context.t.common.close),
        ),
      ],
    );
  }
}
