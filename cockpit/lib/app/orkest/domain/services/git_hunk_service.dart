import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';

/// Serviço desacoplado responsável por operações granulares de staging e unstage por hunk (trecho)
/// utilizando o mecanismo nativo `git apply --cached` e `git apply --cached --reverse`.
class GitHunkService {
  const GitHunkService();

  /// Constrói o texto do patch unificado formatado estritamente para o git apply.
  String buildHunkPatch({
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
  }) {
    final buffer = StringBuffer();
    // O Git espera caminhos com barras normais (POSIX) no cabeçalho do diff
    final normalizedPath = relativePath.replaceAll('\\', '/');
    final needsQuotes = normalizedPath.contains(' ') ||
        normalizedPath.contains('\t') ||
        normalizedPath.contains('"');
    final pathA = needsQuotes ? '"a/$normalizedPath"' : 'a/$normalizedPath';
    final pathB = needsQuotes ? '"b/$normalizedPath"' : 'b/$normalizedPath';

    buffer.writeln('diff --git $pathA $pathB');

    final isNew = kind == FileDiffKind.added ||
        hunk.header.contains(' -0,0 ') ||
        hunk.header.startsWith('@@ +');
    final isDeleted =
        kind == FileDiffKind.deleted || hunk.header.contains(' +0,0 ');

    if (isNew) {
      buffer.writeln('new file mode 100644');
      buffer.writeln('--- /dev/null');
      buffer.writeln('+++ $pathB');
    } else if (isDeleted) {
      buffer.writeln('deleted file mode 100644');
      buffer.writeln('--- $pathA');
      buffer.writeln('+++ /dev/null');
    } else {
      buffer.writeln('--- $pathA');
      buffer.writeln('+++ $pathB');
    }

    var header = hunk.header;
    if (header.startsWith('@@ +')) {
      header = header.replaceFirst('@@ +', '@@ -0,0 +');
    }
    buffer.writeln(header);

    for (final line in hunk.lines) {
      switch (line.kind) {
        case DiffLineKind.added:
          buffer.writeln('+${line.text}');
          break;
        case DiffLineKind.removed:
          buffer.writeln('-${line.text}');
          break;
        case DiffLineKind.context:
          buffer.writeln(' ${line.text}');
          break;
      }
      if (line.noNewline) {
        buffer.writeln(r'\ No newline at end of file');
      }
    }

    return buffer.toString();
  }

  /// Aplica o hunk no index do Git (`git apply --cached -`).
  Future<Result<void, String>> stageHunk({
    required String repoRoot,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    return _applyPatch(
      repoRoot: repoRoot,
      patchText: patchText,
      args: const ['apply', '--cached', '-'],
      gitExecutable: gitExecutable,
    );
  }

  /// Remove o hunk do index do Git (`git apply --cached --reverse -`).
  Future<Result<void, String>> unstageHunk({
    required String repoRoot,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    return _applyPatch(
      repoRoot: repoRoot,
      patchText: patchText,
      args: const ['apply', '--cached', '--reverse', '-'],
      gitExecutable: gitExecutable,
    );
  }

  /// Descarta as mudanças do hunk diretamente no working tree (`git apply --reverse -`).
  Future<Result<void, String>> discardHunk({
    required String repoRoot,
    required String relativePath,
    required DiffHunk hunk,
    FileDiffKind kind = FileDiffKind.modified,
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(
      relativePath: relativePath,
      hunk: hunk,
      kind: kind,
    );
    return _applyPatch(
      repoRoot: repoRoot,
      patchText: patchText,
      args: const ['apply', '--reverse', '-'],
      gitExecutable: gitExecutable,
    );
  }

  Future<Result<void, String>> _applyPatch({
    required String repoRoot,
    required String patchText,
    required List<String> args,
    required String gitExecutable,
  }) async {
    try {
      final process = await Process.start(
        gitExecutable,
        args,
        workingDirectory: repoRoot,
      );

      process.stdin.write(patchText);
      await process.stdin.flush();
      await process.stdin.close();

      final stderrFuture = process.stderr.transform(utf8.decoder).join();
      final exitCode = await process.exitCode;
      final errorOutput = await stderrFuture;

      if (exitCode == 0) {
        return const Success(null);
      } else {
        final message = errorOutput.trim().isNotEmpty
            ? errorOutput.trim()
            : 'Git apply falhou com código de saída $exitCode';
        return Failure(message);
      }
    } catch (e) {
      return Failure('Falha ao executar git apply: $e');
    }
  }
}
