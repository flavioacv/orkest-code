import 'dart:math' as math;
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';

/// Ocorrência de duplicação estrutural de código encontrada (L06).
class StructuralDuplication {
  const StructuralDuplication({
    required this.originalRange,
    required this.duplicateRange,
    required this.lineCount,
    required this.similarity,
    required this.snippet,
  });

  /// Intervalo onde ocorre o bloco original.
  final LspRange originalRange;

  /// Intervalo onde ocorre o bloco duplicado.
  final LspRange duplicateRange;

  /// Quantidade de linhas do bloco duplicado.
  final int lineCount;

  /// Grau de similaridade estrutural [0.0 - 1.0].
  final double similarity;

  /// Trecho representativo do bloco duplicado.
  final String snippet;

  Map<String, dynamic> toJson() => {
        'original_range': originalRange.toJson(),
        'duplicate_range': duplicateRange.toJson(),
        'line_count': lineCount,
        'similarity': similarity,
        'snippet': snippet,
      };

  @override
  String toString() =>
      'StructuralDuplication(lines: $lineCount, sim: ${(similarity * 100).toStringAsFixed(1)}%, '
      'orig: ${originalRange.start.line}, dup: ${duplicateRange.start.line})';
}

/// Ocorrência de casamento em busca estrutural (L06).
class StructuralMatch {
  const StructuralMatch({
    required this.range,
    required this.matchedText,
    required this.captures,
  });

  final LspRange range;
  final String matchedText;
  final Map<String, String> captures;

  @override
  String toString() => 'StructuralMatch(range: $range, text: "$matchedText")';
}

/// Relatório de auditoria de custo e viabilidade de recursos avançados por linguagem (L06).
class AdvancedIntelligenceAuditReport {
  const AdvancedIntelligenceAuditReport({
    required this.languageId,
    required this.supportsInlayHints,
    required this.supportsCallHierarchy,
    required this.supportsTypeHierarchy,
    required this.supportsCodeLens,
    required this.recommendedSubset,
    required this.averageLatencyMs,
    required this.overheadNotes,
  });

  final String languageId;
  final bool supportsInlayHints;
  final bool supportsCallHierarchy;
  final bool supportsTypeHierarchy;
  final bool supportsCodeLens;
  final List<String> recommendedSubset;
  final double averageLatencyMs;
  final String overheadNotes;

  Map<String, dynamic> toJson() => {
        'language_id': languageId,
        'supports_inlay_hints': supportsInlayHints,
        'supports_call_hierarchy': supportsCallHierarchy,
        'supports_type_hierarchy': supportsTypeHierarchy,
        'supports_code_lens': supportsCodeLens,
        'recommended_subset': recommendedSubset,
        'average_latency_ms': averageLatencyMs,
        'overhead_notes': overheadNotes,
      };

  @override
  String toString() =>
      'AdvancedIntelligenceAuditReport($languageId: subset=$recommendedSubset, '
      'latency=${averageLatencyMs.toStringAsFixed(1)}ms)';
}

/// Serviço de análise estrutural, busca por padrões e detecção de código duplicado (L06).
class StructuralAnalysisService {
  const StructuralAnalysisService();

  /// Detecta blocos de código duplicados ou quase duplicados em um documento.
  ///
  /// Ignora variações cosméticas de formatação, espaços em branco e linhas vazias,
  /// medindo a similaridade estrutural via coeficiente de Jaccard e normalização sintática.
  static List<StructuralDuplication> findDuplications(
    String source, {
    int minLines = 3,
    double similarityThreshold = 0.80,
  }) {
    final rawLines = source.split('\n');
    if (rawLines.length < minLines * 2) return const [];

    // Normaliza linhas preservando mapeamento de índice original
    final normalized = <_NormalizedLine>[];
    for (int i = 0; i < rawLines.length; i++) {
      final trimmed = rawLines[i].trim();
      if (trimmed.isEmpty || trimmed.startsWith('//') || trimmed.startsWith('#')) {
        continue;
      }
      // Tokenização estrutural simplificada (remove pontuações triviais)
      final tokenized = trimmed
          .replaceAll(RegExp(r'\s+'), ' ')
          .replaceAll(RegExp(r'[;,\(\)\{\}]'), '');
      normalized.add(_NormalizedLine(lineIndex: i, text: tokenized, raw: rawLines[i]));
    }

    if (normalized.length < minLines * 2) return const [];

    final duplications = <StructuralDuplication>[];
    final reportedPairs = <String>{};

    for (int i = 0; i <= normalized.length - minLines; i++) {
      final blockA = normalized.sublist(i, i + minLines);
      final setA = blockA.map((l) => l.text).toSet();

      for (int j = i + minLines; j <= normalized.length - minLines; j++) {
        final blockB = normalized.sublist(j, j + minLines);
        final setB = blockB.map((l) => l.text).toSet();

        final intersection = setA.intersection(setB).length;
        final union = setA.union(setB).length;
        if (union == 0) continue;

        final similarity = intersection / union;
        if (similarity >= similarityThreshold) {
          final pairKey = '${blockA.first.lineIndex}:${blockB.first.lineIndex}';
          if (!reportedPairs.contains(pairKey)) {
            reportedPairs.add(pairKey);

            final origStartLine = blockA.first.lineIndex;
            final origEndLine = blockA.last.lineIndex;
            final dupStartLine = blockB.first.lineIndex;
            final dupEndLine = blockB.last.lineIndex;

            duplications.add(
              StructuralDuplication(
                originalRange: LspRange(
                  LspPosition(origStartLine, 0),
                  LspPosition(origEndLine, rawLines[origEndLine].length),
                ),
                duplicateRange: LspRange(
                  LspPosition(dupStartLine, 0),
                  LspPosition(dupEndLine, rawLines[dupEndLine].length),
                ),
                lineCount: minLines,
                similarity: similarity,
                snippet: blockB.map((l) => l.raw).join('\n'),
              ),
            );
          }
        }
      }
    }

    return List.unmodifiable(duplications);
  }

  /// Realiza busca estrutural por correspondência de padrões de código com curingas.
  ///
  /// Curingas no formato `$ID` casam com qualquer identificador ou expressão simples.
  static List<StructuralMatch> searchPattern(String source, String pattern) {
    if (source.isEmpty || pattern.isEmpty) return const [];

    final lines = source.split('\n');
    final matches = <StructuralMatch>[];

    // Converte o padrão simples em uma regex de busca com grupos nomeados
    final escaped = RegExp.escape(pattern.trim());
    final regexPattern = escaped.replaceAllMapped(
      RegExp(r'\\\$([a-zA-Z0-9_]+)'),
      (m) => '(?<${m.group(1)}>[a-zA-Z0-9_]+)',
    );

    final regex = RegExp(regexPattern);

    for (int lineIdx = 0; lineIdx < lines.length; lineIdx++) {
      final lineText = lines[lineIdx];
      for (final match in regex.allMatches(lineText)) {
        final captures = <String, String>{};
        for (final groupName in match.groupNames) {
          final val = match.namedGroup(groupName);
          if (val != null) {
            captures[groupName] = val;
          }
        }

        matches.add(
          StructuralMatch(
            range: LspRange(
              LspPosition(lineIdx, match.start),
              LspPosition(lineIdx, match.end),
            ),
            matchedText: match.group(0) ?? '',
            captures: Map.unmodifiable(captures),
          ),
        );
      }
    }

    return List.unmodifiable(matches);
  }

  /// Gera a auditoria de viabilidade e escolha do subset útil de inteligência por linguagem.
  static AdvancedIntelligenceAuditReport auditLanguageSubset({
    required String languageId,
    required bool serverAvailable,
    double measuredLatencyMs = 25.0,
  }) {
    if (!serverAvailable) {
      return AdvancedIntelligenceAuditReport(
        languageId: languageId,
        supportsInlayHints: false,
        supportsCallHierarchy: false,
        supportsTypeHierarchy: false,
        supportsCodeLens: false,
        recommendedSubset: const [],
        averageLatencyMs: 0.0,
        overheadNotes: 'Server indisponível; fallback seguro para modo semântico básico.',
      );
    }

    return switch (languageId) {
      'dart' => AdvancedIntelligenceAuditReport(
          languageId: languageId,
          supportsInlayHints: true,
          supportsCallHierarchy: true,
          supportsTypeHierarchy: true,
          supportsCodeLens: true,
          recommendedSubset: const ['inlayHints', 'callHierarchy', 'typeHierarchy', 'codeLens'],
          averageLatencyMs: measuredLatencyMs,
          overheadNotes: 'Análise nativa Dart Analysis Server com cache em memória excelente.',
        ),
      'typescript' || 'javascript' => AdvancedIntelligenceAuditReport(
          languageId: languageId,
          supportsInlayHints: true,
          supportsCallHierarchy: true,
          supportsTypeHierarchy: true,
          supportsCodeLens: false,
          recommendedSubset: const ['inlayHints', 'callHierarchy', 'typeHierarchy'],
          averageLatencyMs: math.max(measuredLatencyMs, 35.0),
          overheadNotes: 'CodeLens desabilitado por custo de I/O em projetos grandes (subset útil focado em inlays).',
        ),
      'rust' => AdvancedIntelligenceAuditReport(
          languageId: languageId,
          supportsInlayHints: true,
          supportsCallHierarchy: true,
          supportsTypeHierarchy: true,
          supportsCodeLens: true,
          recommendedSubset: const ['inlayHints', 'callHierarchy', 'typeHierarchy'],
          averageLatencyMs: math.max(measuredLatencyMs, 40.0),
          overheadNotes: 'rust-analyzer fornece inlays ricos de tipos encadeados.',
        ),
      'python' || 'go' => AdvancedIntelligenceAuditReport(
          languageId: languageId,
          supportsInlayHints: true,
          supportsCallHierarchy: true,
          supportsTypeHierarchy: false,
          supportsCodeLens: false,
          recommendedSubset: const ['inlayHints', 'callHierarchy'],
          averageLatencyMs: math.max(measuredLatencyMs, 30.0),
          overheadNotes: 'Call hierarchy confiável; type hierarchy limitada pelo modelo dinâmico do Python.',
        ),
      _ => AdvancedIntelligenceAuditReport(
          languageId: languageId,
          supportsInlayHints: false,
          supportsCallHierarchy: false,
          supportsTypeHierarchy: false,
          supportsCodeLens: false,
          recommendedSubset: const [],
          averageLatencyMs: 0.0,
          overheadNotes: 'Linguagem em tier 3 ou sem suporte a AST estendida; recursos mantidos desligados.',
        ),
    };
  }
}

class _NormalizedLine {
  const _NormalizedLine({
    required this.lineIndex,
    required this.text,
    required this.raw,
  });

  final int lineIndex;
  final String text;
  final String raw;
}
