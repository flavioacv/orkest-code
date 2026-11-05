import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_stash_entry.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_tag_entry.dart';

/// Serviço de gerenciamento avançado de trabalho Git:
/// Stash (shelf), Tags, Patches unificados e operações de Cherry-pick/Revert/Rebase.
class GitWorkService {
  GitWorkService([GitBinary? gitBinary])
      : _gitBinary = gitBinary ?? GitBinary();

  final GitBinary _gitBinary;

  // ===========================================================================
  // 1. GESTÃO DE STASH (SHELF)
  // ===========================================================================

  /// Lista todos os stashes disponíveis no repositório ordenados do mais recente ao mais antigo.
  Future<Result<List<GitStashEntry>, String>> listStashes(String repoRoot) async {
    final res = await _runGit(repoRoot, [
      'stash',
      'list',
      '--format=%gd%x1f%h%x1f%cr%x1f%gs',
    ]);

    switch (res) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        final entries = <GitStashEntry>[];
        final output = value.trim();
        if (output.isEmpty) return Success(entries);

        final lines = output.split('\n');
        for (final line in lines) {
          if (line.isEmpty) continue;
          final parts = line.split('\u001f');
          if (parts.length >= 4) {
            final refStr = parts[0]; // ex: stash@{0}
            final match = RegExp(r'stash@\{(\d+)\}').firstMatch(refStr);
            final index = match != null ? int.tryParse(match.group(1)!) ?? 0 : 0;

            entries.add(
              GitStashEntry(
                index: index,
                commitHash: parts[1].trim(),
                relativeTime: parts[2].trim(),
                message: parts[3].trim(),
              ),
            );
          }
        }
        return Success(entries);
    }
  }

  /// Salva as modificações do working tree no stash.
  Future<Result<void, String>> stashPush(
    String repoRoot, {
    String? message,
    bool includeUntracked = false,
    bool keepIndex = false,
  }) async {
    final args = [
      'stash',
      'push',
      if (includeUntracked) '--include-untracked',
      if (keepIndex) '--keep-index',
      if (message != null && message.trim().isNotEmpty) ...['-m', message.trim()],
    ];

    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Aplica o stash no índice/working tree sem removê-lo da lista.
  Future<Result<void, String>> stashApply(String repoRoot, {int index = 0}) async {
    final res = await _runGit(repoRoot, ['stash', 'apply', 'stash@{$index}']);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Aplica o stash no índice/working tree e o remove da lista.
  Future<Result<void, String>> stashPop(String repoRoot, {int index = 0}) async {
    final res = await _runGit(repoRoot, ['stash', 'pop', 'stash@{$index}']);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Remove um stash específico da lista.
  Future<Result<void, String>> stashDrop(String repoRoot, {int index = 0}) async {
    final res = await _runGit(repoRoot, ['stash', 'drop', 'stash@{$index}']);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Obtém o diff textual completo das alterações guardadas no stash.
  Future<Result<String, String>> stashDiff(String repoRoot, {int index = 0}) async {
    final res = await _runGit(repoRoot, ['stash', 'show', '-p', 'stash@{$index}']);
    switch (res) {
      case Success(:final value):
        return Success(value);
      case Failure(:final error):
        return Failure(error);
    }
  }

  // ===========================================================================
  // 2. GESTÃO DE TAGS
  // ===========================================================================

  /// Lista todas as tags locais ordenadas por versão.
  Future<Result<List<GitTagEntry>, String>> listTags(String repoRoot) async {
    final res = await _runGit(repoRoot, [
      'tag',
      '-l',
      '--format=%(refname:short)|%(objectname:short)|%(creatordate:iso-strict)|%(subject)',
    ]);

    switch (res) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        final entries = <GitTagEntry>[];
        final output = value.trim();
        if (output.isEmpty) return Success(entries);

        final lines = output.split('\n');
        for (final line in lines) {
          if (line.isEmpty) continue;
          final parts = line.split('|');
          if (parts.isNotEmpty) {
            final name = parts[0].trim();
            final hash = parts.length > 1 ? parts[1].trim() : '';
            DateTime? date;
            if (parts.length > 2 && parts[2].trim().isNotEmpty) {
              date = DateTime.tryParse(parts[2].trim());
            }
            final msg = parts.length > 3 ? parts[3].trim() : '';

            entries.add(
              GitTagEntry(
                name: name,
                commitHash: hash,
                createdAt: date,
                message: msg,
              ),
            );
          }
        }
        return Success(entries);
    }
  }

  /// Cria uma nova tag no commit indicado ou no HEAD.
  Future<Result<void, String>> createTag(
    String repoRoot, {
    required String name,
    String? commitHash,
    String? message,
    bool annotated = false,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Failure('Nome da tag não pode ser vazio');

    final isAnnotated = annotated || (message != null && message.trim().isNotEmpty);
    final args = [
      'tag',
      if (isAnnotated) ...[
        '-a',
        trimmedName,
        '-m',
        (message != null && message.trim().isNotEmpty) ? message.trim() : trimmedName,
      ] else
        trimmedName,
      if (commitHash != null && commitHash.trim().isNotEmpty) commitHash.trim(),
    ];

    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Remove uma tag local existente.
  Future<Result<void, String>> deleteTag(String repoRoot, {required String name}) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) return const Failure('Nome da tag não pode ser vazio');

    final res = await _runGit(repoRoot, ['tag', '-d', trimmedName]);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  // ===========================================================================
  // 3. OPERAÇÕES DE PATCH UNIFICADO
  // ===========================================================================

  /// Cria um patch unificado com base nas alterações não commitadas ou entre revisões.
  Future<Result<String, String>> createPatch(
    String repoRoot, {
    String? fromCommit,
    String? toCommit,
    List<String>? filePaths,
    bool staged = false,
  }) async {
    final args = <String>['diff'];
    if (staged) args.add('--cached');

    if (fromCommit != null && fromCommit.isNotEmpty) {
      if (toCommit != null && toCommit.isNotEmpty) {
        args.add('$fromCommit..$toCommit');
      } else {
        args.add(fromCommit);
      }
    }

    if (filePaths != null && filePaths.isNotEmpty) {
      args.add('--');
      args.addAll(filePaths);
    }

    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success(:final value):
        return Success(value);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Aplica um patch unificado no working tree ou apenas valida (`checkOnly`).
  Future<Result<void, String>> applyPatch(
    String repoRoot, {
    required String patchContent,
    bool checkOnly = false,
    bool reverse = false,
  }) async {
    if (patchContent.trim().isEmpty) {
      return const Failure('Conteúdo do patch está vazio');
    }

    final gitExe = await _gitBinary.resolve();
    final args = [
      '-C',
      repoRoot,
      'apply',
      if (checkOnly) '--check',
      if (reverse) '--reverse',
      '--unidiff-zero',
      '-',
    ];

    try {
      final process = await Process.start(gitExe, args);
      process.stdin.write(patchContent);
      await process.stdin.flush();
      await process.stdin.close();

      final exitCode = await process.exitCode;
      final stderr = await process.stderr.transform(utf8.decoder).join();

      if (exitCode != 0) {
        return Failure(
          stderr.trim().isNotEmpty
              ? stderr.trim()
              : 'Falha ao aplicar patch (código $exitCode)',
        );
      }
      return const Success(null);
    } catch (e) {
      return Failure('Erro ao executar git apply: $e');
    }
  }

  // ===========================================================================
  // 4. OPERAÇÕES AVANÇADAS: CHERRY-PICK, REVERT E REBASE COM GUARDRAILS
  // ===========================================================================

  /// Aplica um commit de outra branch na branch ativa via cherry-pick.
  Future<Result<void, String>> cherryPick(
    String repoRoot, {
    required String commitHash,
    bool noCommit = false,
  }) async {
    final cleanCheck = await _ensureCleanWorkingTree(repoRoot);
    if (!cleanCheck.isSuccess) return cleanCheck;

    final branchName = await _getCurrentBranch(repoRoot);
    if (branchName == 'main' || branchName == 'master') {
      return const Failure(
        'Guardrail: Operações de alteração direta na branch main são bloqueadas.',
      );
    }

    final args = [
      'cherry-pick',
      if (noCommit) '-n',
      commitHash.trim(),
    ];

    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Reverte um commit criando um novo commit inverso.
  Future<Result<void, String>> revertCommit(
    String repoRoot, {
    required String commitHash,
    bool noCommit = false,
  }) async {
    final cleanCheck = await _ensureCleanWorkingTree(repoRoot);
    if (!cleanCheck.isSuccess) return cleanCheck;

    final branchName = await _getCurrentBranch(repoRoot);
    if (branchName == 'main' || branchName == 'master') {
      return const Failure(
        'Guardrail: Operações de alteração direta na branch main são bloqueadas.',
      );
    }

    final args = [
      'revert',
      '--no-edit',
      if (noCommit) '-n',
      commitHash.trim(),
    ];

    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  /// Inicia o rebase da branch ativa sobre a branch upstream indicada.
  Future<Result<void, String>> rebase(
    String repoRoot, {
    required String upstreamBranch,
  }) async {
    final cleanCheck = await _ensureCleanWorkingTree(repoRoot);
    if (!cleanCheck.isSuccess) return cleanCheck;

    final currentBranch = await _getCurrentBranch(repoRoot);
    if (currentBranch == 'main' || currentBranch == 'master') {
      return const Failure(
        'Guardrail: Operações de rebase diretamente na branch main são bloqueadas.',
      );
    }

    final args = ['rebase', upstreamBranch.trim()];
    final res = await _runGit(repoRoot, args);
    switch (res) {
      case Success():
        return const Success(null);
      case Failure(:final error):
        return Failure(error);
    }
  }

  // ===========================================================================
  // HELPERS PRIVADOS
  // ===========================================================================

  Future<Result<String, String>> _runGit(String repoRoot, List<String> args) async {
    try {
      final gitExe = await _gitBinary.resolve();
      final proc = await Process.run(gitExe, ['-C', repoRoot, ...args]);
      if (proc.exitCode == 0) {
        return Success(proc.stdout.toString());
      }
      final stderr = proc.stderr.toString().trim();
      final stdout = proc.stdout.toString().trim();
      return Failure(stderr.isNotEmpty ? stderr : (stdout.isNotEmpty ? stdout : 'Erro desconhecido'));
    } catch (e) {
      return Failure('Erro ao executar Git: $e');
    }
  }

  Future<String> _getCurrentBranch(String repoRoot) async {
    final res = await _runGit(repoRoot, ['branch', '--show-current']);
    switch (res) {
      case Success(:final value):
        return value.trim();
      case Failure():
        return '';
    }
  }

  Future<Result<void, String>> _ensureCleanWorkingTree(String repoRoot) async {
    final res = await _runGit(repoRoot, ['status', '--porcelain']);
    switch (res) {
      case Failure(:final error):
        return Failure(error);
      case Success(:final value):
        if (value.trim().isNotEmpty) {
          return const Failure(
            'O working tree possui alterações pendentes. Faça commit ou stash antes de prosseguir.',
          );
        }
        return const Success(null);
    }
  }
}
