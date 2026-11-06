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
}

enum SourceControlSection { changes, history }

class WorkbenchLayoutState {
  const WorkbenchLayoutState({
    this.activeTool = WorkbenchToolId.files,
    this.sourceControlSection = SourceControlSection.changes,
  });
  final WorkbenchToolId activeTool;
  final SourceControlSection sourceControlSection;

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
    );
  }

  Map<String, dynamic> toJson() => {
    'activeTool': activeTool.name,
    'sourceControlSection': sourceControlSection.name,
  };

  @override
  bool operator ==(Object other) =>
      other is WorkbenchLayoutState &&
      other.activeTool == activeTool &&
      other.sourceControlSection == sourceControlSection;
  @override
  int get hashCode => Object.hash(activeTool, sourceControlSection);
}
