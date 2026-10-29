import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show immutable, listEquals;
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tipografia do Orkest — segue o padrão Apple HIG (San Francisco / SF Pro
/// Display / SF Pro Text como fonte primária no macOS/iOS, com fallback para
/// Space Grotesk / Hanken Grotesk em outras plataformas e JetBrains Mono / SF
/// Mono para código).
@immutable
class AppTypography {
  const AppTypography({
    required this.display,
    required this.title,
    required this.body,
    required this.label,
    required this.tab,
    required this.mono,
  });

  /// SF Pro Display / Space Grotesk — títulos grandes (heading do transcript).
  final TextStyle display;

  /// SF Pro Text / Space Grotesk — nomes de workspace/aba/seção.
  final TextStyle title;

  /// SF Pro Text / Hanken Grotesk — corpo do transcript e inputs.
  final TextStyle body;

  /// SF Pro Text / Hanken Grotesk — rótulos pequenos.
  final TextStyle label;

  /// SF Pro Text / Space Grotesk — texto das abas.
  final TextStyle tab;

  /// JetBrains Mono / SF Mono — código, args de tool, métricas.
  final TextStyle mono;

  /// Igualdade por valor, pela mesma razão do [AppColors]: o `OrkestTheme`
  /// compara estes objetos para decidir se repinta a árvore.
  List<Object?> get _props => [display, title, body, label, tab, mono];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppTypography && listEquals(_props, other._props);

  @override
  int get hashCode => Object.hashAll(_props);

  /// Monta a tipografia segundo a escala e tracking óptico do Apple HIG.
  /// Sem args = defaults do sistema (SF Pro no macOS/iOS com fallback para
  /// Space Grotesk/Hanken; JetBrains Mono com fallback SF Mono no código).
  /// [uiFont]/[monoFont] preenchidos trocam a família (resolução pelo SO).
  /// [codeSize] define o tamanho do mono. O "tamanho da interface" NÃO escala
  /// aqui — é aplicado globalmente via `MediaQuery.textScaler`.
  factory AppTypography.build({
    String? uiFont,
    String? monoFont,
    double codeSize = 13,
  }) {
    final hasUi = uiFont != null && uiFont.trim().isNotEmpty;
    final hasMono = monoFont != null && monoFont.trim().isNotEmpty;
    final isApple = Platform.isMacOS || Platform.isIOS;

    final TextStyle displayBase = hasUi
        ? TextStyle(fontFamily: uiFont)
        : isApple
        ? const TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontFamilyFallback: [
              'SF Pro Display',
              'SF Pro Text',
              '-apple-system',
              'Helvetica Neue',
            ],
          )
        : GoogleFonts.spaceGrotesk();

    final TextStyle ui = hasUi
        ? TextStyle(fontFamily: uiFont)
        : isApple
        ? const TextStyle(
            fontFamily: '.AppleSystemUIFont',
            fontFamilyFallback: [
              'SF Pro Text',
              'SF Pro Display',
              '-apple-system',
              'Helvetica Neue',
            ],
          )
        : GoogleFonts.hankenGrotesk();

    final TextStyle mono = hasMono
        ? TextStyle(fontFamily: monoFont)
        : GoogleFonts.jetBrainsMono().copyWith(
            fontFamilyFallback: const ['SF Mono', 'Menlo', 'Monaco'],
          );

    return AppTypography(
      display: displayBase.copyWith(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        height: 1.22,
        letterSpacing: -0.4,
      ),
      title: displayBase.copyWith(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.12,
      ),
      body: ui.copyWith(
        fontSize: 13.5,
        height: 1.48,
        letterSpacing: -0.08,
      ),
      label: ui.copyWith(
        fontSize: 11.5,
        height: 1.3,
        letterSpacing: -0.04,
      ),
      tab: displayBase.copyWith(
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.08,
      ),
      mono: mono.copyWith(fontSize: codeSize, height: 1.52),
    );
  }

  AppTypography copyWith({
    TextStyle? display,
    TextStyle? title,
    TextStyle? body,
    TextStyle? label,
    TextStyle? tab,
    TextStyle? mono,
  }) {
    return AppTypography(
      display: display ?? this.display,
      title: title ?? this.title,
      body: body ?? this.body,
      label: label ?? this.label,
      tab: tab ?? this.tab,
      mono: mono ?? this.mono,
    );
  }
}
