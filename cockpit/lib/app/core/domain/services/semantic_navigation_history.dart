/// Localização no histórico de navegação semântica do editor (L03).
class NavigationLocation {
  const NavigationLocation({
    required this.uri,
    required this.line,
    required this.character,
    this.symbolName,
  });

  final String uri;
  final int line;
  final int character;
  final String? symbolName;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NavigationLocation &&
          runtimeType == other.runtimeType &&
          uri == other.uri &&
          line == other.line &&
          character == other.character;

  @override
  int get hashCode => Object.hash(uri, line, character);
}

/// Histórico de navegação semântica no código (Go Back / Go Forward) (L03).
class SemanticNavigationHistory {
  SemanticNavigationHistory({this.maxHistory = 50});

  final int maxHistory;
  final List<NavigationLocation> _backStack = [];
  final List<NavigationLocation> _forwardStack = [];

  bool get canGoBack => _backStack.isNotEmpty;
  bool get canGoForward => _forwardStack.isNotEmpty;
  int get backCount => _backStack.length;
  int get forwardCount => _forwardStack.length;

  /// Registra uma localização antes de realizar um salto de definição/referência.
  void push(String uri, int line, int character, {String? symbolName}) {
    final loc = NavigationLocation(
      uri: uri,
      line: line,
      character: character,
      symbolName: symbolName,
    );

    if (_backStack.isNotEmpty && _backStack.last == loc) {
      return;
    }

    _backStack.add(loc);
    _forwardStack.clear();

    if (_backStack.length > maxHistory) {
      _backStack.removeAt(0);
    }
  }

  /// Retorna à localização anterior, guardando a [current] na pilha de avanço.
  NavigationLocation? goBack(NavigationLocation current) {
    if (_backStack.isEmpty) return null;
    final target = _backStack.removeLast();
    _forwardStack.add(current);
    return target;
  }

  /// Avança para a próxima localização na pilha de avanço.
  NavigationLocation? goForward(NavigationLocation current) {
    if (_forwardStack.isEmpty) return null;
    final target = _forwardStack.removeLast();
    _backStack.add(current);
    return target;
  }

  /// Limpa o histórico de navegação.
  void clear() {
    _backStack.clear();
    _forwardStack.clear();
  }
}
