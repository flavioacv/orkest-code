import 'dart:io';

import 'package:orkest_code/app/core/domain/result.dart';

/// Tipos de resolução para um bloco de conflito Git.
enum ConflictResolution {
  /// Aceita a versão atual / local ("Ours" / HEAD).
  ours,

  /// Aceita a versão que está entrando / remota ("Theirs" / Incoming).
  theirs,

  /// Aceita ambas as versões concatenadas.
  both,

  /// Reverte para a versão base (quando disponível no formato diff3).
  base,
}

/// Operações do Git que podem estar em andamento no repositório.
enum GitOngoingOperation { none, merge, rebase, cherryPick, revert }

/// Representa um bloco delimitado de conflito no arquivo:
/// <<<<<<< [oursLabel]
/// [ours]
/// ||||||| [baseLabel] (opcional)
/// [base]
/// =======
/// [theirs]
/// >>>>>>> [theirsLabel]
class ConflictBlock {
  final int from;
  final int to;
  final int startLine;
  final int endLine;
  final String ours;
  final String? base;
  final String theirs;
  final String oursLabel;
  final String theirsLabel;

  const ConflictBlock({
    required this.from,
    required this.to,
    required this.startLine,
    required this.endLine,
    required this.ours,
    this.base,
    required this.theirs,
    required this.oursLabel,
    required this.theirsLabel,
  });
}

/// Serviço de análise, navegação e resolução de conflitos de merge/rebase do Git.
class GitConflictService {
  const GitConflictService();

  static const String startMarker = '<<<<<<<';
  static const String baseMarker = '|||||||';
  static const String sepMarker = '=======';
  static const String endMarker = '>>>>>>>';
  static final _markerLines = RegExp(
    r'^(?:<{7}|={7}|>{7}|\|{7})(?:\s|$)',
    multiLine: true,
  );

  bool hasUnresolvedMarkers(String text) => _markerLines.hasMatch(text);

  /// Verifica rapidamente se a string contém marcadores de conflito.
  bool hasConflictMarkers(String text) {
    return text.contains(startMarker);
  }

  /// Parseia todos os blocos de conflito válidos presentes em [text].
  List<ConflictBlock> parseConflicts(String text) {
    if (!hasConflictMarkers(text)) return const [];

    final blocks = <ConflictBlock>[];
    final lines = text.split('\n');

    var currentOffset = 0;
    int? blockStartIndex;
    int? blockStartOffset;
    int? baseIndex;
    int? sepIndex;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineEndOffset =
          currentOffset + line.length + (i < lines.length - 1 ? 1 : 0);

      if (_isMarker(line, startMarker)) {
        blockStartIndex = i;
        blockStartOffset = currentOffset;
        baseIndex = null;
        sepIndex = null;
      } else if (blockStartIndex != null &&
          baseIndex == null &&
          sepIndex == null &&
          _isMarker(line, baseMarker)) {
        baseIndex = i;
      } else if (blockStartIndex != null &&
          sepIndex == null &&
          _isMarker(line, sepMarker)) {
        sepIndex = i;
      } else if (blockStartIndex != null &&
          sepIndex != null &&
          _isMarker(line, endMarker)) {
        // Encerramento do bloco de conflito
        final startLineText = lines[blockStartIndex];
        final endLineText = line;

        final oursStart = blockStartIndex + 1;
        final oursEnd = baseIndex ?? sepIndex;
        String content(int start, int end) => lines
            .sublist(start, end)
            .map(
              (line) => line.endsWith('\r')
                  ? line.substring(0, line.length - 1)
                  : line,
            )
            .join('\n');
        final oursText = content(oursStart, oursEnd);

        String? baseText;
        if (baseIndex != null) {
          baseText = content(baseIndex + 1, sepIndex);
        }

        final theirsStart = sepIndex + 1;
        final theirsEnd = i;
        final theirsText = content(theirsStart, theirsEnd);

        final oursLabel = _extractLabel(startLineText, startMarker);
        final theirsLabel = _extractLabel(endLineText, endMarker);

        blocks.add(
          ConflictBlock(
            from: blockStartOffset!,
            to: lineEndOffset,
            startLine: blockStartIndex + 1,
            endLine: i + 1,
            ours: oursText,
            base: baseText,
            theirs: theirsText,
            oursLabel: oursLabel.isNotEmpty ? oursLabel : 'HEAD (Atual)',
            theirsLabel: theirsLabel.isNotEmpty
                ? theirsLabel
                : 'Incoming (Entrante)',
          ),
        );

        blockStartIndex = null;
        blockStartOffset = null;
        baseIndex = null;
        sepIndex = null;
      }

      currentOffset = lineEndOffset;
    }

    return blocks;
  }

  /// Resolve um único bloco de conflito aplicando a resolução selecionada.
  String resolveBlock({
    required String text,
    required ConflictBlock block,
    required ConflictResolution resolution,
    bool reversed = false,
  }) {
    final replacement = resolutionText(block, resolution, reversed: reversed);
    return replaceBlock(text: text, block: block, replacement: replacement);
  }

  /// Applies an edited result only to the selected block, retaining its EOL and
  /// whether its closing marker had a final newline.
  String replaceBlock({
    required String text,
    required ConflictBlock block,
    required String replacement,
  }) => text.replaceRange(
    block.from,
    block.to,
    _formatReplacement(text, block, replacement),
  );

  /// Composes independently reviewed blocks against one immutable document.
  /// Text outside conflicts is copied verbatim and no unreviewed block defaults
  /// silently to a side.
  String resolveDocument({
    required String text,
    required List<String> results,
  }) {
    final blocks = parseConflicts(text);
    if (results.length != blocks.length || results.any(hasUnresolvedMarkers)) {
      throw ArgumentError(
        'Every conflict requires a result without conflict markers.',
      );
    }
    final buffer = StringBuffer();
    var offset = 0;
    for (var index = 0; index < blocks.length; index++) {
      final block = blocks[index];
      buffer.write(text.substring(offset, block.from));
      buffer.write(_formatReplacement(text, block, results[index]));
      offset = block.to;
    }
    buffer.write(text.substring(offset));
    return buffer.toString();
  }

  String _formatReplacement(
    String text,
    ConflictBlock block,
    String replacement,
  ) {
    final original = text.substring(block.from, block.to);
    final eol = original.contains('\r\n') ? '\r\n' : '\n';
    var result = replacement.replaceAll('\r\n', '\n').replaceAll('\n', eol);
    if (result.isNotEmpty && original.endsWith('\n') && !result.endsWith(eol)) {
      result += eol;
    }
    return result;
  }

  /// Resolve todos os blocos de conflito do arquivo simultaneamente.
  String resolveAll({
    required String text,
    required ConflictResolution resolution,
    bool reversed = false,
  }) {
    final blocks = parseConflicts(text);
    if (blocks.isEmpty) return text;

    final buffer = StringBuffer();
    var lastOffset = 0;

    for (final block in blocks) {
      buffer.write(text.substring(lastOffset, block.from));
      final replacement = resolutionText(block, resolution, reversed: reversed);
      buffer.write(_formatReplacement(text, block, replacement));
      lastOffset = block.to;
    }

    buffer.write(text.substring(lastOffset));
    return buffer.toString();
  }

  /// Retorna o texto da resolução correspondente.
  String resolutionText(
    ConflictBlock block,
    ConflictResolution resolution, {
    bool reversed = false,
  }) {
    final yours = reversed ? block.theirs : block.ours;
    final theirs = reversed ? block.ours : block.theirs;

    switch (resolution) {
      case ConflictResolution.ours:
        return yours;
      case ConflictResolution.theirs:
        return theirs;
      case ConflictResolution.base:
        return block.base ?? '';
      case ConflictResolution.both:
        if (yours.isEmpty) return theirs;
        if (theirs.isEmpty) return yours;
        return yours.endsWith('\n') ? '$yours$theirs' : '$yours\n$theirs';
    }
  }

  /// Detecta se há uma operação Git em andamento (merge, rebase, cherry-pick ou revert).
  GitOngoingOperation detectOngoingOperation(String repoRoot) {
    try {
      final gitDir = Directory('$repoRoot/.git');
      if (!gitDir.existsSync()) return GitOngoingOperation.none;

      if (File('$repoRoot/.git/MERGE_HEAD').existsSync()) {
        return GitOngoingOperation.merge;
      }
      if (Directory('$repoRoot/.git/rebase-merge').existsSync() ||
          Directory('$repoRoot/.git/rebase-apply').existsSync()) {
        return GitOngoingOperation.rebase;
      }
      if (File('$repoRoot/.git/CHERRY_PICK_HEAD').existsSync()) {
        return GitOngoingOperation.cherryPick;
      }
      if (File('$repoRoot/.git/REVERT_HEAD').existsSync()) {
        return GitOngoingOperation.revert;
      }
    } catch (_) {}

    return GitOngoingOperation.none;
  }

  /// Continua a operação Git em andamento (`git <op> --continue`).
  Future<Result<void, String>> continueOperation({
    required String repoRoot,
    String gitExecutable = 'git',
  }) async {
    final op = detectOngoingOperation(repoRoot);
    if (op == GitOngoingOperation.none) {
      return const Failure('Nenhuma operação Git em andamento para continuar.');
    }

    final cmd = _operationCommandName(op);
    return _runGit(repoRoot, gitExecutable, [cmd, '--continue']);
  }

  /// Aborta a operação Git em andamento (`git <op> --abort`).
  Future<Result<void, String>> abortOperation({
    required String repoRoot,
    String gitExecutable = 'git',
  }) async {
    final op = detectOngoingOperation(repoRoot);
    if (op == GitOngoingOperation.none) {
      return const Failure('Nenhuma operação Git em andamento para abortar.');
    }

    final cmd = _operationCommandName(op);
    return _runGit(repoRoot, gitExecutable, [cmd, '--abort']);
  }

  String _operationCommandName(GitOngoingOperation op) {
    switch (op) {
      case GitOngoingOperation.merge:
        return 'merge';
      case GitOngoingOperation.rebase:
        return 'rebase';
      case GitOngoingOperation.cherryPick:
        return 'cherry-pick';
      case GitOngoingOperation.revert:
        return 'revert';
      case GitOngoingOperation.none:
        return '';
    }
  }

  Future<Result<void, String>> _runGit(
    String repoRoot,
    String gitExecutable,
    List<String> args,
  ) async {
    try {
      final res = await Process.run(
        gitExecutable,
        args,
        workingDirectory: repoRoot,
      );
      if (res.exitCode == 0) {
        return const Success(null);
      } else {
        final err = (res.stderr as String).trim();
        return Failure(
          err.isNotEmpty ? err : 'Git falhou com saída ${res.exitCode}',
        );
      }
    } catch (e) {
      return Failure('Erro ao executar git: $e');
    }
  }

  bool _isMarker(String line, String marker) {
    return line.startsWith(marker) &&
        (line.length == marker.length ||
            line[marker.length] == ' ' ||
            line[marker.length] == '\r');
  }

  String _extractLabel(String line, String marker) {
    if (line.length <= marker.length) return '';
    return line.substring(marker.length).trim();
  }
}
