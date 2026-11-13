import 'dart:io';
import 'package:path/path.dart' as p;

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

enum GitResolutionErrorKind { stale, markers, commandFailed }

class GitResolutionError {
  const GitResolutionError(this.kind, {this.detail});
  final GitResolutionErrorKind kind;
  final String? detail;
}

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

  ConflictBlock copyWith({
    int? from,
    int? to,
    int? startLine,
    int? endLine,
    String? ours,
    String? base,
    String? theirs,
    String? oursLabel,
    String? theirsLabel,
  }) => ConflictBlock(
    from: from ?? this.from,
    to: to ?? this.to,
    startLine: startLine ?? this.startLine,
    endLine: endLine ?? this.endLine,
    ours: ours ?? this.ours,
    base: base ?? this.base,
    theirs: theirs ?? this.theirs,
    oursLabel: oursLabel ?? this.oursLabel,
    theirsLabel: theirsLabel ?? this.theirsLabel,
  );
}

/// Conteúdos das versões em conflito de um arquivo recuperadas diretamente
/// dos estágios do índice do Git (stage 1: base comum, stage 2: ours, stage 3: theirs).
class GitConflictStages {
  const GitConflictStages({this.base, this.ours, this.theirs});

  /// Versão do ancestral comum (Stage 1: `:1:<path>`).
  final String? base;

  /// Nossa versão / HEAD (Stage 2: `:2:<path>`).
  final String? ours;

  /// Versão entrante / remota (Stage 3: `:3:<path>`).
  final String? theirs;

  bool get hasBase => base != null && base!.isNotEmpty;
  bool get hasOurs => ours != null;
  bool get hasTheirs => theirs != null;
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
    final marker = p.join(repoRoot, '.git');
    var gitPath = marker;
    if (File(marker).existsSync()) {
      final pointer = File(marker).readAsStringSync().trim();
      if (!pointer.startsWith('gitdir: ')) {
        throw const FormatException('Invalid gitdir pointer');
      }
      gitPath = p.normalize(p.join(repoRoot, pointer.substring(8).trim()));
    }
    if (!Directory(gitPath).existsSync()) return GitOngoingOperation.none;
    if (File(p.join(gitPath, 'MERGE_HEAD')).existsSync()) {
      return GitOngoingOperation.merge;
    }
    if (Directory(p.join(gitPath, 'rebase-merge')).existsSync() ||
        Directory(p.join(gitPath, 'rebase-apply')).existsSync()) {
      return GitOngoingOperation.rebase;
    }
    if (File(p.join(gitPath, 'CHERRY_PICK_HEAD')).existsSync()) {
      return GitOngoingOperation.cherryPick;
    }
    if (File(p.join(gitPath, 'REVERT_HEAD')).existsSync()) {
      return GitOngoingOperation.revert;
    }
    return GitOngoingOperation.none;
  }

  Future<Result<void, GitResolutionError>> markResolved({
    required String repoRoot,
    required String relativePath,
    required String expectedText,
  }) async {
    try {
      final disk = await File(p.join(repoRoot, relativePath)).readAsString();
      if (disk.replaceAll('\r\n', '\n') !=
          expectedText.replaceAll('\r\n', '\n')) {
        return const Failure(GitResolutionError(GitResolutionErrorKind.stale));
      }
      if (hasUnresolvedMarkers(disk)) {
        return const Failure(
          GitResolutionError(GitResolutionErrorKind.markers),
        );
      }
      final result = await _runGit(repoRoot, 'git', [
        'add',
        '--',
        p.posix.joinAll(p.split(relativePath)),
      ]);
      return result.fold<Result<void, GitResolutionError>>(
        (_) => const Success(null),
        (detail) => Failure(
          GitResolutionError(
            GitResolutionErrorKind.commandFailed,
            detail: detail,
          ),
        ),
      );
    } on FileSystemException catch (error) {
      return Failure(
        GitResolutionError(
          GitResolutionErrorKind.commandFailed,
          detail: error.toString(),
        ),
      );
    }
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

    final pending = await Process.run(gitExecutable, [
      'diff',
      '--name-only',
      '--diff-filter=U',
      '-z',
    ], workingDirectory: repoRoot);
    if (pending.exitCode != 0) return Failure(pending.stderr.toString());
    if (pending.stdout.toString().isNotEmpty) {
      return Failure(pending.stdout.toString().replaceAll('\u0000', '\n'));
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
        environment: {'GIT_EDITOR': 'true', 'GIT_SEQUENCE_EDITOR': 'true'},
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

  /// Lê as versões de um arquivo diretamente dos estágios do índice do Git:
  /// - Estágio 1 (`:1:<path>`): ancestral comum (Base)
  /// - Estágio 2 (`:2:<path>`): nosso lado (Ours / HEAD)
  /// - Estágio 3 (`:3:<path>`): lado entrante (Theirs / Incoming)
  Future<Result<GitConflictStages, String>> readConflictStages({
    required String repoRoot,
    required String relativePath,
    String gitExecutable = 'git',
  }) async {
    final cleanPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;

    Future<String?> readStage(int stage) async {
      try {
        final res = await Process.run(gitExecutable, [
          'show',
          ':$stage:$cleanPath',
        ], workingDirectory: repoRoot);
        if (res.exitCode == 0) {
          return res.stdout as String;
        }
        return null;
      } catch (_) {
        return null;
      }
    }

    final base = await readStage(1);
    final ours = await readStage(2);
    final theirs = await readStage(3);

    return Success(GitConflictStages(base: base, ours: ours, theirs: theirs));
  }

  Future<List<ConflictBlock>> reviewBlocks({
    required String text,
    required String repoRoot,
    required String relativePath,
    String gitExecutable = 'git',
  }) async {
    final blocks = parseConflicts(text);
    if (blocks.every((block) => block.base != null)) return blocks;
    final result = await readConflictStages(
      repoRoot: repoRoot,
      relativePath: relativePath,
      gitExecutable: gitExecutable,
    );
    final stages = result.fold((value) => value, (_) => null);
    if (stages == null ||
        stages.base == null ||
        stages.ours == null ||
        stages.theirs == null) {
      return blocks;
    }
    final temp = await Directory.systemTemp.createTemp('orkest-merge-base-');
    try {
      final ours = File(p.join(temp.path, 'ours'));
      final base = File(p.join(temp.path, 'base'));
      final theirs = File(p.join(temp.path, 'theirs'));
      await Future.wait([
        ours.writeAsString(stages.ours!),
        base.writeAsString(stages.base!),
        theirs.writeAsString(stages.theirs!),
      ]);
      final merge = await Process.run(gitExecutable, [
        'merge-file',
        '-p',
        '--diff3',
        ours.path,
        base.path,
        theirs.path,
      ]);
      if (merge.exitCode < 0 || merge.exitCode > 127) return blocks;
      final generated = parseConflicts(merge.stdout as String);
      // A whole-file base is never a block base. Match exact side pairs only;
      // repeated ambiguous pairs remain unavailable rather than guessing spans.
      return blocks.map((block) {
        if (block.base != null) return block;
        final matches = generated
            .where(
              (candidate) =>
                  candidate.ours == block.ours &&
                  candidate.theirs == block.theirs,
            )
            .toList();
        return matches.length == 1
            ? block.copyWith(base: matches.single.base)
            : block;
      }).toList();
    } finally {
      await temp.delete(recursive: true);
    }
  }

  /// Enriquece blocos de conflito com o ancestral comum obtido dos estágios do índice,
  /// caso o bloco original seja padrão de 2 vias (sem marcador diff3 `|||||||`).
  List<ConflictBlock> enrichBlocksWithBase({
    required List<ConflictBlock> blocks,
    required GitConflictStages stages,
  }) {
    if (!stages.hasBase || blocks.length != 1) return blocks;
    final block = blocks.single;
    // Only safe without a diff3 reconstruction if the entire sides are this block.
    if (block.base != null ||
        stages.ours?.trimRight() != block.ours ||
        stages.theirs?.trimRight() != block.theirs) {
      return blocks;
    }
    return [block.copyWith(base: stages.base)];
  }
}
