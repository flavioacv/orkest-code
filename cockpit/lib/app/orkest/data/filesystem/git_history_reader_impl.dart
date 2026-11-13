import 'dart:io';

import 'package:orkest_code/app/core/data/setup/remote_pi_resolver.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_history_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_comparison.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/domain/git_blame_parser.dart';
import 'package:orkest_code/app/orkest/domain/git_history_parsers.dart';

export 'package:orkest_code/app/orkest/domain/git_blame_parser.dart';
export 'package:orkest_code/app/orkest/domain/git_history_parsers.dart';

/// Leitor estruturado do `git log`, `git blame` e comparações entre revisões.
/// Os separadores de controle evitam depender de locale ou de caracteres visuais de `--graph`.
class GitHistoryReaderImpl implements GitHistoryReader {
  GitHistoryReaderImpl(this._gitBinary);

  final GitBinary _gitBinary;

  @override
  Future<Result<List<GitHistoryCommit>, GitHistoryError>> read(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    GitHistoryQuery? query,
  }) async {
    try {
      final git = await _gitBinary.resolve();
      final effectiveQuery = query ?? GitHistoryQuery(limit: limit, skip: skip);

      final args = [
        '-C',
        repoPath,
        'log',
        '--decorate=short',
        '--topo-order',
        '--date=iso-strict',
        '--format=%H%x1f%P%x1f%D%x1f%an%x1f%aI%x1f%s%x1e',
        ...effectiveQuery.toGitArgs(),
      ];

      final result = await Process.run(
        git,
        args,
        environment: await envWithNodeOnPath(),
      );

      if (result.exitCode != 0) {
        return Failure(
          GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: result.stderr.toString().trim(),
          ),
        );
      }
      return Success(GitHistoryParser.parse(result.stdout.toString()));
    } on ProcessException catch (error) {
      return Failure(
        GitHistoryError(
          GitHistoryErrorKind.commandFailed,
          detail: error.message,
        ),
      );
    }
  }

  @override
  Future<Result<List<GitHistoryFileChange>, GitHistoryError>> readFiles(
    String repoPath,
    String commitHash,
  ) async {
    try {
      final git = await _gitBinary.resolve();
      final result = await Process.run(
        git,
        [
          '-C',
          repoPath,
          'show',
          '--format=',
          '--name-status',
          '-z',
          '--find-renames',
          '--first-parent',
          commitHash,
          '--',
        ],
        environment: await envWithNodeOnPath(),
      );

      if (result.exitCode != 0) {
        return Failure(
          GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: result.stderr.toString().trim(),
          ),
        );
      }
      return Success(
        GitHistoryFileChangeParser.parse(result.stdout.toString()),
      );
    } on ProcessException catch (error) {
      return Failure(
        GitHistoryError(
          GitHistoryErrorKind.commandFailed,
          detail: error.message,
        ),
      );
    }
  }

  @override
  Future<Result<List<GitBlameHunk>, GitHistoryError>> readBlame(
    String repoPath,
    String filePath, {
    int? lineStart,
    int? lineEnd,
  }) async {
    try {
      final git = await _gitBinary.resolve();
      final args = [
        '-C',
        repoPath,
        'blame',
        '--porcelain',
        if (lineStart != null && lineEnd != null)
          '-L$lineStart,$lineEnd'
        else if (lineStart != null)
          '-L$lineStart,',
        '--',
        filePath,
      ];

      final result = await Process.run(
        git,
        args,
        environment: await envWithNodeOnPath(),
      );

      if (result.exitCode != 0) {
        return Failure(
          GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: result.stderr.toString().trim(),
          ),
        );
      }

      return Success(GitBlameParser.parse(result.stdout.toString()));
    } on ProcessException catch (error) {
      return Failure(
        GitHistoryError(
          GitHistoryErrorKind.commandFailed,
          detail: error.message,
        ),
      );
    }
  }

  @override
  Future<Result<GitComparison, GitHistoryError>> compareRefs(
    String repoPath,
    String baseRef,
    String targetRef,
  ) async {
    try {
      final git = await _gitBinary.resolve();

      // 1. Obtém lista de arquivos modificados entre baseRef e targetRef
      final diffResult = await Process.run(
        git,
        [
          '-C',
          repoPath,
          'diff',
          '--name-status',
          '-z',
          '--find-renames',
          '$baseRef..$targetRef',
        ],
        environment: await envWithNodeOnPath(),
      );

      if (diffResult.exitCode != 0) {
        return Failure(
          GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: diffResult.stderr.toString().trim(),
          ),
        );
      }

      final changedFiles = GitHistoryFileChangeParser.parse(
        diffResult.stdout.toString(),
      );

      // 2. Obtém lista de commits exclusivos de targetRef em relação a baseRef
      final logResult = await Process.run(
        git,
        [
          '-C',
          repoPath,
          'log',
          '--decorate=short',
        '--topo-order',
          '--date=iso-strict',
          '--format=%H%x1f%P%x1f%D%x1f%an%x1f%aI%x1f%s%x1e',
          '$baseRef..$targetRef',
        ],
        environment: await envWithNodeOnPath(),
      );

      if (logResult.exitCode != 0) {
        return Failure(
          GitHistoryError(
            GitHistoryErrorKind.commandFailed,
            detail: logResult.stderr.toString().trim(),
          ),
        );
      }

      final commits = GitHistoryParser.parse(logResult.stdout.toString());

      return Success(
        GitComparison(
          baseRef: baseRef,
          targetRef: targetRef,
          commits: commits,
          changedFiles: changedFiles,
        ),
      );
    } on ProcessException catch (error) {
      return Failure(
        GitHistoryError(
          GitHistoryErrorKind.commandFailed,
          detail: error.message,
        ),
      );
    }
  }
}
