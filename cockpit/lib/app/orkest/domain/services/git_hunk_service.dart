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
  }) {
    final buffer = StringBuffer();
    // O Git espera caminhos com barras normais (POSIX) no cabeçalho do diff
    final normalizedPath = relativePath.replaceAll('\\', '/');

    buffer.writeln('diff --git a/$normalizedPath b/$normalizedPath');
    buffer.writeln('--- a/$normalizedPath');
    buffer.writeln('+++ b/$normalizedPath');
    buffer.writeln(hunk.header);

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
    }

    return buffer.toString();
  }

  /// Aplica o hunk no index do Git (`git apply --cached -`).
  Future<Result<void, String>> stageHunk({
    required String repoRoot,
    required String relativePath,
    required DiffHunk hunk,
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(relativePath: relativePath, hunk: hunk);
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
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(relativePath: relativePath, hunk: hunk);
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
    String gitExecutable = 'git',
  }) async {
    final patchText = buildHunkPatch(relativePath: relativePath, hunk: hunk);
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
