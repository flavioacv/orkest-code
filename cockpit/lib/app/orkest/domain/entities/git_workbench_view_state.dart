enum GitWorkbenchTab { log, console, worktrees }

class GitWorkbenchViewState {
  const GitWorkbenchViewState({
    this.tab = GitWorkbenchTab.log,
    this.root = '',
    this.ref = '',
    this.query = '',
    this.author = '',
    this.sinceDays = 0,
    this.selectedHash = '',
    this.branchFraction = .18,
    this.detailsFraction = .28,
    this.collapsed = const {},
  });
  final GitWorkbenchTab tab;
  final String root;
  final String ref;
  final String query;
  final String author;
  final int sinceDays;
  final String selectedHash;
  final double branchFraction;
  final double detailsFraction;
  final Set<String> collapsed;

  GitWorkbenchViewState copyWith({
    GitWorkbenchTab? tab,
    String? root,
    String? ref,
    String? query,
    String? author,
    int? sinceDays,
    String? selectedHash,
    double? branchFraction,
    double? detailsFraction,
    Set<String>? collapsed,
  }) => GitWorkbenchViewState(
    tab: tab ?? this.tab,
    root: root ?? this.root,
    ref: ref ?? this.ref,
    query: query ?? this.query,
    author: author ?? this.author,
    sinceDays: sinceDays ?? this.sinceDays,
    selectedHash: selectedHash ?? this.selectedHash,
    branchFraction: branchFraction ?? this.branchFraction,
    detailsFraction: detailsFraction ?? this.detailsFraction,
    collapsed: collapsed == null ? this.collapsed : Set.unmodifiable(collapsed),
  );

  factory GitWorkbenchViewState.fromJson(Object? json) {
    if (json is! Map) return const GitWorkbenchViewState();
    double fraction(String key, double fallback) {
      final value = json[key];
      return value is num && value.isFinite
          ? value.toDouble().clamp(.12, .4)
          : fallback;
    }

    String text(String key) => json[key] is String ? json[key] as String : '';
    return GitWorkbenchViewState(
      tab: GitWorkbenchTab.values.firstWhere(
        (tab) => tab.name == json['tab'],
        orElse: () => GitWorkbenchTab.log,
      ),
      root: text('root'),
      ref: text('ref'),
      query: text('query'),
      author: text('author'),
      selectedHash: text('selectedHash'),
      sinceDays:
          json['sinceDays'] is int &&
              [0, 7, 30, 90, 365].contains(json['sinceDays'])
          ? json['sinceDays'] as int
          : 0,
      branchFraction: fraction('branchFraction', .18),
      detailsFraction: fraction('detailsFraction', .28),
      collapsed: json['collapsed'] is List
          ? Set.unmodifiable((json['collapsed'] as List).whereType<String>())
          : const {},
    );
  }
  Map<String, Object?> toJson() => {
    'tab': tab.name,
    'root': root,
    'ref': ref,
    'query': query,
    'author': author,
    'sinceDays': sinceDays,
    'selectedHash': selectedHash,
    'branchFraction': branchFraction,
    'detailsFraction': detailsFraction,
    'collapsed': collapsed.toList()..sort(),
  };
  @override
  bool operator ==(Object other) =>
      other is GitWorkbenchViewState &&
      other.tab == tab &&
      other.root == root &&
      other.ref == ref &&
      other.query == query &&
      other.author == author &&
      other.sinceDays == sinceDays &&
      other.selectedHash == selectedHash &&
      other.branchFraction == branchFraction &&
      other.detailsFraction == detailsFraction &&
      other.collapsed.length == collapsed.length &&
      other.collapsed.containsAll(collapsed);
  @override
  int get hashCode => Object.hash(
    tab,
    root,
    ref,
    query,
    author,
    sinceDays,
    selectedHash,
    branchFraction,
    detailsFraction,
    Object.hashAllUnordered(collapsed),
  );
}
