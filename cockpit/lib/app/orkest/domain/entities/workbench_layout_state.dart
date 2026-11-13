import 'git_workbench_view_state.dart';

/// Tool selection persisted inside the existing workspace layout document.
/// Aba ativa do painel direito: árvore de arquivos, busca por conteúdo,
/// source control ou conexões de banco (plano 51). Ordem visual no header:
/// Files · Search · Source Control · Database.
enum WorkbenchToolId {
  files,
  search,
  sourceControl,
  database,
  gallery,
  telemetry,
  debug,
  problems,
  outline,
}

enum SourceControlSection { changes, history, pullRequests }

class WorkbenchLayoutState {
  const WorkbenchLayoutState({
    this.activeTool = WorkbenchToolId.files,
    this.sourceControlSection = SourceControlSection.changes,
    this.isToolWindowCollapsed = false,
    this.isToolWindowMaximized = false,
    this.gitView = const GitWorkbenchViewState(),
  });
  final WorkbenchToolId activeTool;
  final SourceControlSection sourceControlSection;
  final bool isToolWindowCollapsed;
  final bool isToolWindowMaximized;
  final GitWorkbenchViewState gitView;

  WorkbenchLayoutState copyWith({
    WorkbenchToolId? activeTool,
    SourceControlSection? sourceControlSection,
    bool? isToolWindowCollapsed,
    bool? isToolWindowMaximized,
    GitWorkbenchViewState? gitView,
  }) => WorkbenchLayoutState(
    activeTool: activeTool ?? this.activeTool,
    gitView: gitView ?? this.gitView,
    sourceControlSection: sourceControlSection ?? this.sourceControlSection,
    isToolWindowCollapsed:
        isToolWindowCollapsed ?? this.isToolWindowCollapsed,
    isToolWindowMaximized:
        isToolWindowMaximized ?? this.isToolWindowMaximized,
  );

  factory WorkbenchLayoutState.fromJson(Object? value) {
    if (value is! Map) return const WorkbenchLayoutState();
    return WorkbenchLayoutState(
      activeTool: WorkbenchToolId.values.firstWhere(
        (tool) => tool.name == value['activeTool'],
        orElse: () => WorkbenchToolId.files,
      ),
      sourceControlSection: SourceControlSection.values.firstWhere(
        (section) => section.name == value['sourceControlSection'],
        orElse: () => SourceControlSection.changes,
      ),
      isToolWindowCollapsed: value['isToolWindowCollapsed'] == true,
      isToolWindowMaximized: value['isToolWindowMaximized'] == true,
      gitView: GitWorkbenchViewState.fromJson(value['gitView']),
    );
  }

  Map<String, dynamic> toJson() => {
    'activeTool': activeTool.name,
    'gitView': gitView.toJson(),
    'sourceControlSection': sourceControlSection.name,
    'isToolWindowCollapsed': isToolWindowCollapsed,
    'isToolWindowMaximized': isToolWindowMaximized,
  };

  @override
  bool operator ==(Object other) =>
      other is WorkbenchLayoutState &&
      other.activeTool == activeTool &&
      other.sourceControlSection == sourceControlSection &&
      other.isToolWindowCollapsed == isToolWindowCollapsed &&
      other.isToolWindowMaximized == isToolWindowMaximized && other.gitView == gitView;
  @override
  int get hashCode => Object.hash(
    activeTool,
    sourceControlSection,
    isToolWindowCollapsed,
    isToolWindowMaximized,
    gitView,
  );
}
