import 'package:flutter/widgets.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'package:orkest_code/app/core/terminal/xterm/xterm.dart';

import 'syntax_colors.dart';

/// Carrega os tokens bespoke do Orkest (cores, tipografia, syntax) na árvore.
///
/// Antes esses tokens eram Material `ThemeExtension`s lidos via
/// `Theme.of(context).extension<…>()`. Como a raiz agora é `ShadcnApp`, o
/// `ThemeData` do shadcn **não tem** `.extension<>()`, então ancoramos os tokens
/// neste `InheritedWidget` próprio. A API de leitura segue idêntica —
/// `context.colors` / `context.typo` / `context.syntax` (ver
/// `theme_extensions.dart`).
@immutable
class OrkestTheme extends InheritedWidget {
  const OrkestTheme({
    super.key,
    required this.colors,
    required this.typo,
    required this.syntax,
    required this.terminal,
    required super.child,
  });

  final AppColors colors;
  final AppTypography typo;
  final SyntaxColors syntax;
  final TerminalTheme terminal;

  static OrkestTheme? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<OrkestTheme>();

  static OrkestTheme of(BuildContext context) {
    final theme = maybeOf(context);
    assert(theme != null, 'OrkestTheme não encontrado na árvore de widgets.');
    return theme!;
  }

  @override
  bool updateShouldNotify(OrkestTheme oldWidget) =>
      colors != oldWidget.colors ||
      typo != oldWidget.typo ||
      syntax != oldWidget.syntax ||
      terminal != oldWidget.terminal;
}
