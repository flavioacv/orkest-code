import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';

class _CommitMetadata {
  _CommitMetadata({
    required this.author,
    required this.authorEmail,
    required this.authorTime,
    required this.summary,
  });

  final String author;
  final String authorEmail;
  final DateTime authorTime;
  final String summary;
}

/// Parser estruturado para a saída de `git blame --porcelain`.
class GitBlameParser {
  const GitBlameParser._();

  /// Converte a saída de `git blame --porcelain` em uma lista tipada de [GitBlameHunk].
  static List<GitBlameHunk> parse(String porcelainOutput) {
    if (porcelainOutput.trim().isEmpty) return const [];

    final hunks = <GitBlameHunk>[];
    final commitCache = <String, _CommitMetadata>{};

    final lines = porcelainOutput.split('\n');
    var i = 0;

    while (i < lines.length) {
      final line = lines[i];
      if (line.isEmpty) {
        i++;
        continue;
      }

      // Linha de cabeçalho do bloco: <hash> <origLine> <finalLine> <lineCount>
      final parts = line.split(' ');
      if (parts.length < 4 || parts[0].length != 40) {
        i++;
        continue;
      }

      final hash = parts[0];
      final origLine = int.tryParse(parts[1]) ?? 1;
      final finalLine = int.tryParse(parts[2]) ?? 1;
      final lineCount = int.tryParse(parts[3]) ?? 1;

      var author = 'Unknown';
      var authorEmail = '';
      var authorTime = DateTime.fromMillisecondsSinceEpoch(0);
      var summary = '';

      // Se já temos metadados cacheados para esse commit, usamos como fallback
      final cached = commitCache[hash];
      if (cached != null) {
        author = cached.author;
        authorEmail = cached.authorEmail;
        authorTime = cached.authorTime;
        summary = cached.summary;
      }

      i++;

      // Lê metadados até encontrar a linha de código (começa com \t)
      final contentLines = <String>[];
      while (i < lines.length) {
        final current = lines[i];
        if (current.startsWith('\t')) {
          contentLines.add(current.substring(1));
          i++;
          break;
        }

        if (current.startsWith('author ')) {
          author = current.substring('author '.length).trim();
        } else if (current.startsWith('author-mail ')) {
          authorEmail = current
              .substring('author-mail '.length)
              .trim()
              .replaceAll(RegExp(r'[<>]'), '');
        } else if (current.startsWith('author-time ')) {
          final epochSec = int.tryParse(current.substring('author-time '.length).trim()) ?? 0;
          authorTime = DateTime.fromMillisecondsSinceEpoch(epochSec * 1000, isUtc: true);
        } else if (current.startsWith('summary ')) {
          summary = current.substring('summary '.length).trim();
        }

        i++;
      }

      // Atualiza cache de metadados deste commit
      commitCache[hash] = _CommitMetadata(
        author: author,
        authorEmail: authorEmail,
        authorTime: authorTime,
        summary: summary,
      );

      // Lê as linhas adicionais do mesmo hunk se lineCount > 1
      while (contentLines.length < lineCount && i < lines.length) {
        final current = lines[i];
        if (current.startsWith('\t')) {
          contentLines.add(current.substring(1));
          i++;
        } else {
          // Se encontrou outro cabeçalho sem tab, o formato foi interrompido
          break;
        }
      }

      hunks.add(
        GitBlameHunk(
          commitHash: hash,
          author: author,
          authorEmail: authorEmail,
          authorTime: authorTime,
          summary: summary,
          originalLine: origLine,
          finalLine: finalLine,
          lineCount: lineCount,
          lines: contentLines,
        ),
      );
    }

    return hunks;
  }
}
