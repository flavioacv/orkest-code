import 'package:orkest_code/app/core/ui/file_icons/file_icons.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/app_menu.dart';
import 'package:orkest_code/app/core/ui/widgets/app_tooltip.dart';
import 'package:orkest_code/app/core/ui/widgets/context_menu_gesture.dart';
import 'package:orkest_code/app/core/ui/widgets/hover_tap.dart';
import 'package:orkest_code/app/orkest/ui/widgets/panel_resize_handle.dart';
import 'package:orkest_code/app/core/utils/path_utils.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/entities/workspace_root.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// Cor do nome conforme o status git da linha.
Color? gitStatusColor(AppColors colors, GitFileStatus? status) {
  switch (status) {
    case null:
      return null;
    case GitFileStatus.ignored:
      return colors.text4;
    case GitFileStatus.modified:
      return colors.warn;
    case GitFileStatus.staged:
      return colors.gitStaged;
    case GitFileStatus.untracked:
      return colors.gitUntracked;
    case GitFileStatus.deleted:
      return colors.gitDeleted;
    case GitFileStatus.conflict:
      return colors.gitConflict;
  }
}

/// Metadados de um arquivo alterado no Source Control.
class SourceControlChangedFile {
  const SourceControlChangedFile({
    required this.absPath,
    required this.name,
    required this.dir,
  });

  final String absPath;
  final String name;

  /// Diretório relativo à raiz (sem barra final), vazio quando na raiz.
  final String dir;
}

/// Botão de ação padronizado nos cabeçalhos de seções de Source Control.
class SourceControlPanelHeaderAction extends StatelessWidget {
  const SourceControlPanelHeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppTooltip(
      message: tooltip,
      child: HoverTap(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        padding: const EdgeInsets.all(3),
        child: Icon(icon, size: 15, color: context.colors.text3),
      ),
    );
  }
}

/// Árvore ou lista de arquivos alterados (staged e unstaged) do Source Control.
class SourceControlChangesTree extends StatelessWidget {
  const SourceControlChangesTree({
    super.key,
    required this.rootPath,
    required this.roots,
    required this.onFileContextMenu,
    required this.onStageToggle,
    required this.onStageAll,
    required this.onDiscard,
    required this.onDiscardAll,
    required this.isFolderExpanded,
    required this.onFolderExpansionChanged,
    required this.stagedPaths,
    required this.unstagedPaths,
    required this.gitStatusOf,
    required this.selectedPath,
    required this.onOpenDiff,
    required this.onOpenStagedDiff,
    required this.onTapStagedDiff,
    required this.onTapDiff,
    required this.onOpenFile,
    required this.viewAsTree,
    required this.onToggleViewMode,
  });

  final String rootPath;

  /// Roots do workspace (2+ = seções por root; senão fluxo plano).
  final List<WorkspaceRoot> roots;

  /// Botão-direito num arquivo → menu (stage/unstage/discard).
  final void Function(String absPath, Offset pos, {required bool staged})
  onFileContextMenu;
  final Future<void> Function(String absPath, bool staged) onStageToggle;
  final Future<void> Function(List<String> paths, bool staged) onStageAll;
  final Future<void> Function(String absPath) onDiscard;
  final Future<void> Function(List<String> paths) onDiscardAll;
  final bool Function(String path) isFolderExpanded;
  final void Function(String path, bool expanded) onFolderExpansionChanged;
  final List<String> stagedPaths;
  final List<String> unstagedPaths;
  final GitFileStatus? Function(String absolutePath) gitStatusOf;
  final String? selectedPath;
  final ValueChanged<String> onOpenStagedDiff;
  final ValueChanged<String> onTapStagedDiff;
  final ValueChanged<String> onOpenDiff;
  final ValueChanged<String> onTapDiff;
  final ValueChanged<String> onOpenFile;
  final bool viewAsTree;
  final VoidCallback onToggleViewMode;

  @override
  Widget build(BuildContext context) {
    if (stagedPaths.isEmpty && unstagedPaths.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle_outline,
                size: 28,
                color: context.colors.gitStaged,
              ),
              const SizedBox(height: 12),
              Text(
                context.t.orkest.fileTreePanel.noChanges,
                textAlign: TextAlign.center,
                style: context.typo.label.copyWith(color: context.colors.text3),
              ),
            ],
          ),
        ),
      );
    }

    if (roots.length > 1) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final root in roots) ...[
              ..._rootSection(
                context,
                root,
                _filesUnder(root, stagedPaths),
                _filesUnder(root, unstagedPaths),
              ),
            ],
          ],
        ),
      );
    }

    final singleRoot = roots.isNotEmpty
        ? roots.first
        : WorkspaceRoot(path: rootPath, name: rootPath.split('/').last);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _changeSection(context, _filesUnder(singleRoot, stagedPaths), true),
          _changeSection(context, _filesUnder(singleRoot, unstagedPaths), false),
        ],
      ),
    );
  }

  List<SourceControlChangedFile> _filesUnder(
    WorkspaceRoot root,
    List<String> paths,
  ) {
    final base = root.path;
    final normalized = base.endsWith('/') ? base : '$base/';
    final files = <SourceControlChangedFile>[];
    for (final abs in paths) {
      if (!abs.startsWith(normalized) && abs != base) continue;
      if (roots.length > 1) {
        final owner = _ownerRoot(abs);
        if (owner != null && owner.path != root.path) continue;
      }
      final rel = abs == base ? '' : abs.substring(normalized.length);
      final slash = rel.lastIndexOf('/');
      files.add(
        SourceControlChangedFile(
          absPath: abs,
          name: slash >= 0 ? rel.substring(slash + 1) : rel,
          dir: slash >= 0 ? rel.substring(0, slash) : '',
        ),
      );
    }
    files.sort((a, b) {
      final ap = a.dir.isEmpty ? a.name : '${a.dir}/${a.name}';
      final bp = b.dir.isEmpty ? b.name : '${b.dir}/${b.name}';
      return ap.toLowerCase().compareTo(bp.toLowerCase());
    });
    return files;
  }

  WorkspaceRoot? _ownerRoot(String path) {
    final matches = roots.where((r) => isUnderPath(path, r.path)).toList();
    if (matches.isEmpty) return null;
    matches.sort((a, b) => b.path.length.compareTo(a.path.length));
    return matches.first;
  }

  Widget _changeSection(
    BuildContext context,
    List<SourceControlChangedFile> files,
    bool staged,
  ) {
    if (files.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, right: 2, top: 4, bottom: 4),
          child: Row(
            children: [
              Icon(
                staged ? Icons.check_circle_outline : Icons.edit_outlined,
                size: 13,
                color: staged ? context.colors.gitStaged : context.colors.warn,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  staged
                      ? context.t.orkest.fileTreePanel.stagedChangesHeader(
                          count: files.length,
                        )
                      : context.t.orkest.fileTreePanel.changesHeader(
                          count: files.length,
                        ),
                  style: context.typo.label.copyWith(
                    color: context.colors.text3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SourceControlPanelHeaderAction(
                key: ValueKey(
                  staged
                      ? 'source-control-view-toggle-staged'
                      : 'source-control-view-toggle',
                ),
                icon: viewAsTree
                    ? Icons.view_list_outlined
                    : Icons.account_tree_outlined,
                tooltip: viewAsTree
                    ? context.t.orkest.fileTreePanel.viewAsList
                    : context.t.orkest.fileTreePanel.viewAsTree,
                onTap: onToggleViewMode,
              ),
              AppTooltip(
                message: context.t.orkest.fileTreePanel.discardAllChanges,
                child: HoverTap(
                  key: ValueKey(
                    staged ? 'discard-all-staged' : 'discard-all-changes',
                  ),
                  onTap: () =>
                      onDiscardAll(files.map((file) => file.absPath).toList()),
                  borderRadius: BorderRadius.circular(4),
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    Icons.undo,
                    size: 15,
                    color: context.colors.text3,
                  ),
                ),
              ),
              AppTooltip(
                message: staged
                    ? context.t.orkest.fileTreePanel.unstageAllChanges
                    : context.t.orkest.fileTreePanel.stageAllChanges,
                child: HoverTap(
                  key: ValueKey(
                    staged ? 'unstage-all-changes' : 'stage-all-changes',
                  ),
                  onTap: () => onStageAll(
                    files.map((file) => file.absPath).toList(),
                    staged,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  padding: const EdgeInsets.all(3),
                  child: Icon(
                    staged ? Icons.remove : Icons.add,
                    size: 15,
                    color: context.colors.text3,
                  ),
                ),
              ),
            ],
          ),
        ),
        viewAsTree
            ? _buildTree(files, staged)
            : Column(children: _buildRows(context, files, staged)),
      ],
    );
  }

  Widget _buildTree(List<SourceControlChangedFile> files, bool staged) {
    final root = SourceControlChangedDirectory('');
    for (final file in files) {
      root.add(file);
    }
    final first = files.first;
    final relative = first.dir.isEmpty
        ? first.name
        : '${first.dir}/${first.name}';
    final rootPath = first.absPath
        .substring(0, first.absPath.length - relative.length)
        .replaceFirst(RegExp(r'/$'), '');
    return SourceControlChangedDirectoryView(
      directory: root,
      path: rootPath,
      gitStatusOf: (path) => staged ? GitFileStatus.staged : gitStatusOf(path),
      selectedPath: selectedPath,
      onOpenDiff: staged ? onOpenStagedDiff : onOpenDiff,
      onTapDiff: staged ? onTapStagedDiff : onTapDiff,
      onOpenFile: onOpenFile,
      onFileContextMenu: (path, pos) =>
          onFileContextMenu(path, pos, staged: staged),
      onStageToggle: (path) => onStageToggle(path, staged),
      onStageAll: (paths) => onStageAll(paths, staged),
      onDiscard: onDiscard,
      onDiscardAll: onDiscardAll,
      isExpanded: isFolderExpanded,
      onExpansionChanged: onFolderExpansionChanged,
      staged: staged,
    );
  }

  List<Widget> _buildRows(
    BuildContext context,
    List<SourceControlChangedFile> files,
    bool staged,
  ) {
    final tr = context.t.orkest.fileTreePanel;
    return [
      for (final f in files)
        SourceControlChangedRow(
          file: f,
          gitStatus: staged ? GitFileStatus.staged : gitStatusOf(f.absPath),
          selected: f.absPath == selectedPath,
          onTap: () => (staged ? onTapStagedDiff : onTapDiff)(f.absPath),
          onDoubleTap: () =>
              (staged ? onOpenStagedDiff : onOpenDiff)(f.absPath),
          onOpenFileTap: () => onOpenFile(f.absPath),
          onSecondaryTap: (pos) =>
              onFileContextMenu(f.absPath, pos, staged: staged),
          onTrailingTap: () => onStageToggle(f.absPath, staged),
          onDiscardTap: () => onDiscard(f.absPath),
          trailingTooltip: staged ? tr.unstage : tr.stageChanges,
          trailingIcon: staged ? Icons.remove : Icons.add,
        ),
    ];
  }

  List<Widget> _rootSection(
    BuildContext context,
    WorkspaceRoot root,
    List<SourceControlChangedFile> stagedFiles,
    List<SourceControlChangedFile> unstagedFiles,
  ) {
    if (stagedFiles.isEmpty && unstagedFiles.isEmpty) return const [];
    return [
      SourceControlRootSection(
        root: root,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _changeSection(context, stagedFiles, true),
            _changeSection(context, unstagedFiles, false),
          ],
        ),
      ),
    ];
  }
}

/// Seção colapsável de uma root no Source Control multi-root.
class SourceControlRootSection extends StatefulWidget {
  const SourceControlRootSection({
    super.key,
    required this.root,
    required this.body,
  });

  final WorkspaceRoot root;
  final Widget body;

  @override
  State<SourceControlRootSection> createState() =>
      _SourceControlRootSectionState();
}

class _SourceControlRootSectionState extends State<SourceControlRootSection> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final root = widget.root;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoverTap(
          hoverColor: colors.panel,
          borderRadius: BorderRadius.circular(5),
          onTap: () => setState(() => _expanded = !_expanded),
          padding: const EdgeInsets.only(left: 2, right: 6),
          child: SizedBox(
            height: 26,
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 15,
                  color: colors.text3,
                ),
                const SizedBox(width: 2),
                Text(
                  root.name,
                  style: typo.body.copyWith(
                    fontSize: 12.5,
                    color: colors.text,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (root.git != null) ...[
                  const SizedBox(width: 8),
                  Icon(Icons.call_split, size: 10, color: colors.warn),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      root.git!.branch,
                      overflow: TextOverflow.ellipsis,
                      style: typo.mono.copyWith(
                        fontSize: 10,
                        color: colors.warn,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_expanded) widget.body,
        const SizedBox(height: 6),
      ],
    );
  }
}

/// Nó em memória da visualização hierárquica de mudanças.
class SourceControlChangedDirectory {
  SourceControlChangedDirectory(this.name);

  final String name;
  final Map<String, SourceControlChangedDirectory> directories =
      <String, SourceControlChangedDirectory>{};
  final List<SourceControlChangedFile> files = <SourceControlChangedFile>[];

  List<String> get descendantPaths => [
    for (final file in files) file.absPath,
    for (final directory in directories.values) ...directory.descendantPaths,
  ];

  void add(SourceControlChangedFile file) {
    var current = this;
    for (final part in file.dir.split('/').where((part) => part.isNotEmpty)) {
      current = current.directories.putIfAbsent(
        part,
        () => SourceControlChangedDirectory(part),
      );
    }
    current.files.add(file);
  }
}

/// Conteúdo de uma pasta da árvore de Source Control.
class SourceControlChangedDirectoryView extends StatefulWidget {
  const SourceControlChangedDirectoryView({
    super.key,
    required this.directory,
    required this.path,
    required this.gitStatusOf,
    required this.selectedPath,
    required this.onOpenDiff,
    required this.onTapDiff,
    required this.onOpenFile,
    required this.onFileContextMenu,
    required this.onStageToggle,
    required this.onStageAll,
    required this.onDiscard,
    required this.onDiscardAll,
    required this.isExpanded,
    required this.onExpansionChanged,
    required this.staged,
    this.depth = 0,
    this.isRoot = true,
  });

  final SourceControlChangedDirectory directory;
  final String path;
  final GitFileStatus? Function(String absolutePath) gitStatusOf;
  final String? selectedPath;
  final ValueChanged<String> onOpenDiff;
  final ValueChanged<String> onTapDiff;
  final ValueChanged<String> onOpenFile;
  final void Function(String absPath, Offset pos) onFileContextMenu;
  final Future<void> Function(String absPath) onStageToggle;
  final Future<void> Function(List<String> paths) onStageAll;
  final Future<void> Function(String absPath) onDiscard;
  final Future<void> Function(List<String> paths) onDiscardAll;
  final bool Function(String path) isExpanded;
  final void Function(String path, bool expanded) onExpansionChanged;
  final bool staged;
  final int depth;
  final bool isRoot;

  @override
  State<SourceControlChangedDirectoryView> createState() =>
      _SourceControlChangedDirectoryViewState();
}

class _SourceControlChangedDirectoryViewState
    extends State<SourceControlChangedDirectoryView> {
  bool _hovered = false;

  bool get _expanded => widget.isExpanded(widget.path);

  Widget _folderRow(BuildContext context) {
    final colors = context.colors;
    final paths = widget.directory.descendantPaths;
    final actionKey = widget.path;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: HoverTap(
        key: ValueKey('source-control-folder:$actionKey'),
        hoverColor: colors.panel,
        borderRadius: BorderRadius.circular(5),
        onTap: () => widget.onExpansionChanged(widget.path, !_expanded),
        padding: EdgeInsets.only(left: 6 + widget.depth * 14, right: 6),
        child: SizedBox(
          height: 26,
          child: Stack(
            children: [
              Positioned.fill(
                right: _hovered ? 54 : 0,
                child: Row(
                  children: [
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_down
                          : Icons.keyboard_arrow_right,
                      size: 15,
                      color: colors.text3,
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      _expanded
                          ? Icons.folder_open_outlined
                          : Icons.folder_outlined,
                      size: 16,
                      color: colors.text3,
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        widget.directory.name,
                        overflow: TextOverflow.ellipsis,
                        style: context.typo.body.copyWith(
                          fontSize: 13,
                          color: colors.text2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_hovered) ...[
                Positioned(
                  right: 27,
                  top: 1,
                  bottom: 1,
                  child: AppTooltip(
                    message:
                        context.t.orkest.fileTreePanel.discardFolderChanges,
                    child: HoverTap(
                      key: ValueKey('discard-folder:$actionKey'),
                      onTap: () => widget.onDiscardAll(paths),
                      padding: const EdgeInsets.all(4),
                      child: Icon(Icons.undo, size: 15, color: colors.text3),
                    ),
                  ),
                ),
                Positioned(
                  right: 0,
                  top: 1,
                  bottom: 1,
                  child: AppTooltip(
                    message: widget.staged
                        ? context.t.orkest.fileTreePanel.unstageFolderChanges
                        : context.t.orkest.fileTreePanel.stageFolderChanges,
                    child: HoverTap(
                      key: ValueKey('toggle-stage-folder:$actionKey'),
                      onTap: () => widget.onStageAll(paths),
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        widget.staged ? Icons.remove : Icons.add,
                        size: 15,
                        color: colors.text3,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final directories = widget.directory.directories.values.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final files = widget.directory.files.toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!widget.isRoot) _folderRow(context),
        if (widget.isRoot || _expanded) ...[
          for (final directory in directories)
            SourceControlChangedDirectoryView(
              key: ValueKey('${widget.path}/${directory.name}'),
              directory: directory,
              path: '${widget.path}/${directory.name}',
              gitStatusOf: widget.gitStatusOf,
              selectedPath: widget.selectedPath,
              onOpenDiff: widget.onOpenDiff,
              onTapDiff: widget.onTapDiff,
              onOpenFile: widget.onOpenFile,
              onFileContextMenu: widget.onFileContextMenu,
              onStageToggle: widget.onStageToggle,
              onStageAll: widget.onStageAll,
              onDiscard: widget.onDiscard,
              onDiscardAll: widget.onDiscardAll,
              isExpanded: widget.isExpanded,
              onExpansionChanged: widget.onExpansionChanged,
              staged: widget.staged,
              depth: widget.isRoot ? 0 : widget.depth + 1,
              isRoot: false,
            ),
          for (final file in files)
            SourceControlChangedRow(
              key: ValueKey('source-control-file:${file.absPath}'),
              file: file,
              gitStatus: widget.gitStatusOf(file.absPath),
              selected: file.absPath == widget.selectedPath,
              depth: widget.isRoot ? 0 : widget.depth + 1,
              showDirectory: false,
              onTap: () => widget.onTapDiff(file.absPath),
              onDoubleTap: () => widget.onOpenDiff(file.absPath),
              onOpenFileTap: () => widget.onOpenFile(file.absPath),
              onSecondaryTap: (pos) =>
                  widget.onFileContextMenu(file.absPath, pos),
              onTrailingTap: () => widget.onStageToggle(file.absPath),
              onDiscardTap: () => widget.onDiscard(file.absPath),
              trailingTooltip: widget.staged
                  ? context.t.orkest.fileTreePanel.unstage
                  : context.t.orkest.fileTreePanel.stageChanges,
              trailingIcon: widget.staged ? Icons.remove : Icons.add,
            ),
        ],
      ],
    );
  }
}

/// Uma linha da lista de source control.
class SourceControlChangedRow extends StatefulWidget {
  const SourceControlChangedRow({
    super.key,
    required this.file,
    required this.gitStatus,
    required this.selected,
    required this.onTap,
    required this.onDoubleTap,
    this.onOpenFileTap,
    this.onSecondaryTap,
    this.onTrailingTap,
    this.onDiscardTap,
    this.trailingTooltip,
    this.trailingIcon,
    this.depth = 0,
    this.showDirectory = true,
  });

  final SourceControlChangedFile file;
  final GitFileStatus? gitStatus;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onDoubleTap;
  final VoidCallback? onOpenFileTap;
  final void Function(Offset globalPos)? onSecondaryTap;
  final VoidCallback? onTrailingTap;
  final VoidCallback? onDiscardTap;
  final String? trailingTooltip;
  final IconData? trailingIcon;
  final int depth;
  final bool showDirectory;

  @override
  State<SourceControlChangedRow> createState() =>
      _SourceControlChangedRowState();
}

class _SourceControlChangedRowState extends State<SourceControlChangedRow> {
  DateTime? _lastTap;
  bool _hovered = false;

  void _handleTap() {
    if (widget.onDoubleTap == null) {
      widget.onTap?.call();
      return;
    }
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!).inMilliseconds < 350) {
      _lastTap = null;
      widget.onDoubleTap!();
    } else {
      _lastTap = now;
      widget.onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final typo = context.typo;
    final file = widget.file;
    final nameColor =
        gitStatusColor(colors, widget.gitStatus) ??
        (widget.selected ? colors.text : colors.text2);
    final actionWidth = _hovered
        ? (widget.onTrailingTap == null ? 0.0 : 27.0) +
              (widget.onDiscardTap == null ? 0.0 : 27.0) +
              (widget.onOpenFileTap == null ? 0.0 : 27.0)
        : 0.0;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: ContextMenuGesture(
        enabled: widget.onSecondaryTap != null,
        longPressOnMobile: false,
        onMenu: (pos) => widget.onSecondaryTap?.call(pos),
        child: HoverTap(
          color: widget.selected ? colors.panel2 : Colors.transparent,
          hoverColor: colors.panel,
          borderRadius: BorderRadius.circular(5),
          onTap: _handleTap,
          padding: EdgeInsets.only(left: 6 + widget.depth * 14, right: 6),
          child: SizedBox(
            height: 26,
            child: Stack(
              children: [
                Positioned.fill(
                  right: actionWidth,
                  child: Row(
                    children: [
                      FileTypeIcon.file(file.name, size: 16),
                      const SizedBox(width: 7),
                      Flexible(
                        child: Text(
                          file.name,
                          overflow: TextOverflow.ellipsis,
                          style: typo.body.copyWith(
                            fontSize: 13,
                            color: nameColor,
                            decoration:
                                widget.gitStatus == GitFileStatus.deleted
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: nameColor,
                          ),
                        ),
                      ),
                      if (widget.showDirectory && file.dir.isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            file.dir,
                            overflow: TextOverflow.ellipsis,
                            style: typo.label.copyWith(
                              fontSize: 11,
                              color: colors.text4,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (_hovered && widget.onOpenFileTap != null)
                  Positioned(
                    right:
                        (widget.onTrailingTap == null ? 0 : 27) +
                        (widget.onDiscardTap == null ? 0 : 27),
                    top: 1,
                    bottom: 1,
                    child: AppTooltip(
                      message: context.t.orkest.fileTreePanel.open,
                      child: HoverTap(
                        key: ValueKey(
                          'source-control-file-open:${file.absPath}',
                        ),
                        onTap: widget.onOpenFileTap,
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          Icons.description_outlined,
                          size: 15,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
                if (_hovered && widget.onDiscardTap != null)
                  Positioned(
                    right: widget.onTrailingTap == null ? 0 : 27,
                    top: 1,
                    bottom: 1,
                    child: AppTooltip(
                      message: context.t.orkest.fileTreePanel.discardChanges,
                      child: HoverTap(
                        key: ValueKey(
                          'source-control-file-discard:${file.absPath}',
                        ),
                        onTap: widget.onDiscardTap,
                        padding: const EdgeInsets.all(4),
                        child: Icon(Icons.undo, size: 15, color: colors.text3),
                      ),
                    ),
                  ),
                if (_hovered && widget.onTrailingTap != null)
                  Positioned(
                    right: 0,
                    top: 1,
                    bottom: 1,
                    child: AppTooltip(
                      message:
                          widget.trailingTooltip ??
                          context.t.orkest.fileTreePanel.stageChanges,
                      child: HoverTap(
                        key: ValueKey(
                          'source-control-file-stage:${file.absPath}',
                        ),
                        onTap: widget.onTrailingTap,
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          widget.trailingIcon ?? Icons.add,
                          size: 15,
                          color: colors.text3,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Composer fixado no rodapé do Source Control.
class SourceControlCommitComposer extends StatelessWidget {
  const SourceControlCommitComposer({
    super.key,
    required this.controller,
    required this.height,
    required this.onResize,
    required this.submitting,
    required this.generating,
    required this.amend,
    required this.onAmendChanged,
    required this.onChanged,
    required this.onCancelGenerate,
    required this.onCommit,
    this.amendHash,
    this.amendSubject,
    this.loadCommits,
    this.loadMessage,
    this.onGenerate,
    this.generatorLabel,
    this.error,
  });

  final TextEditingController controller;
  final double height;
  final ValueChanged<double> onResize;
  final bool submitting, generating, amend;
  final String? amendHash, amendSubject, error;
  final Future<List<GitCommit>> Function()? loadCommits;
  final Future<String?> Function(String hash)? loadMessage;
  final void Function(bool, String?, String?, String?) onAmendChanged;
  final VoidCallback onChanged, onCancelGenerate, onCommit;
  final VoidCallback? onGenerate;
  final String? generatorLabel;

  static String _truncate(String value, int max) =>
      value.length > max ? '${value.substring(0, max)}...' : value;

  Future<void> _pickCommit(BuildContext context) async {
    if (loadCommits == null) return;
    final commits = await loadCommits!();
    if (!context.mounted) return;
    final picked = await showAppMenu<GitCommit>(
      context,
      items: [
        for (final (index, commit) in commits.take(5).indexed)
          AppMenuItem(
            value: commit,
            label: commit.subject,
            labelWidget: index == 0
                ? RichText(
                    text: TextSpan(
                      style: context.typo.body.copyWith(
                        fontSize: 13,
                        color: context.colors.text,
                      ),
                      children: [
                        TextSpan(
                          text: 'last commit ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        TextSpan(text: commit.subject),
                      ],
                    ),
                  )
                : null,
          ),
      ],
    );
    if (picked == null || !context.mounted) return;
    final message = await loadMessage?.call(picked.hash);
    if (!context.mounted) return;
    onAmendChanged(true, picked.hash, message, picked.subject);
  }

  Widget _commitPicker(BuildContext context) {
    final colors = context.colors;
    final label = amendSubject == null
        ? context.t.orkest.fileTreePanel.lastCommit
        : _truncate(amendSubject!, 20);

    return HoverTap(
      key: const ValueKey('amend-commit-picker'),
      onTap: submitting || generating ? null : () => _pickCommit(context),
      borderRadius: BorderRadius.circular(4),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: context.typo.label.copyWith(
              color: submitting || generating ? colors.text4 : colors.accent,
              fontSize: 11,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(width: 2),
          Icon(
            Icons.keyboard_arrow_down,
            size: 14,
            color: submitting || generating ? colors.text4 : colors.accent,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tr = context.t.orkest.fileTreePanel;
    return SizedBox(
      height: height,
      child: Container(
        decoration: BoxDecoration(
          color: colors.bg,
          border: Border(top: BorderSide(color: colors.border)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PanelResizeHandle(onResizeDelta: onResize),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 8,
                  bottom: 16.0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(
                      height: 34.0,
                      child: Row(
                        key: const ValueKey('commit-composer-toolbar'),
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            spacing: 4.0,
                            children: [
                              Checkbox(
                                state: amend
                                    ? CheckboxState.checked
                                    : CheckboxState.unchecked,
                                onChanged: submitting || generating
                                    ? null
                                    : (v) async {
                                        if (v != CheckboxState.checked) {
                                          onAmendChanged(
                                            false,
                                            null,
                                            null,
                                            null,
                                          );
                                          return;
                                        }
                                        final commits =
                                            await loadCommits?.call() ??
                                            const <GitCommit>[];
                                        if (commits.isEmpty ||
                                            !context.mounted) {
                                          return;
                                        }
                                        final first = commits.first;
                                        final message = await loadMessage?.call(
                                          first.hash,
                                        );
                                        if (context.mounted) {
                                          onAmendChanged(
                                            true,
                                            first.hash,
                                            message,
                                            first.subject,
                                          );
                                        }
                                      },
                              ),
                              Text(
                                tr.amend,
                                style: context.typo.label.copyWith(
                                  color: colors.text,
                                  fontSize: 11,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              _commitPicker(context),
                            ],
                          ),
                          AppTooltip(
                            message: amend
                                ? tr.generateUnavailableWhileAmending
                                : generating
                                ? tr.cancelGeneration
                                : generatorLabel == null
                                ? tr.generateCommitMessage
                                : tr.generateWith(harness: generatorLabel!),
                            child: IconButton.outline(
                              key: const ValueKey(
                                'generate-staged-commit-message',
                              ),
                              onPressed: submitting || amend
                                  ? null
                                  : generating
                                  ? onCancelGenerate
                                  : onGenerate,
                              icon: generating
                                  ? const CircularProgressIndicator(size: 14)
                                  : const Icon(Icons.auto_awesome, size: 15),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        enabled: !submitting && !generating,
                        maxLines: null,
                        expands: true,
                        textAlignVertical: TextAlignVertical.top,
                        onChanged: (_) => onChanged(),
                        placeholder: Text(tr.commitMessagePlaceholder),
                        style: context.typo.mono.copyWith(
                          fontSize: 12,
                          color: colors.text,
                        ),
                        border: Border.all(color: colors.border),
                        borderRadius: BorderRadius.circular(4),
                        padding: const EdgeInsets.all(9),
                      ),
                    ),
                    if (error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Text(
                          error!,
                          style: context.typo.label.copyWith(
                            color: colors.error,
                          ),
                        ),
                      ),
                    const SizedBox(height: 7),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        PrimaryButton(
                          onPressed: submitting || generating ? null : onCommit,
                          child: submitting
                              ? CircularProgressIndicator(
                                  size: 16,
                                  color: onColor(context.colors.accent),
                                )
                              : Text(amend ? tr.amendCommit : tr.commit),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
