import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/git_blame_parser.dart';

void main() {
  group('GitBlameParser', () {
    test('retorna lista vazia para saída em branco ou somente espaços', () {
      expect(GitBlameParser.parse(''), isEmpty);
      expect(GitBlameParser.parse('   \n  \n'), isEmpty);
    });

    test('parseia formato porcelain completo com metadados de autor e linhas', () {
      const output = '''
41e97669d6756fdba056a2360f0653d9e8790cb9 1 1 2
author Ada Lovelace
author-mail <ada@example.com>
author-time 1700000000
author-tz +0000
committer Ada Lovelace
committer-mail <ada@example.com>
committer-time 1700000000
committer-tz +0000
summary Initial implementation
filename lib/service.dart
\tvoid startService() {
\t  print("Starting...");
8a7b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b 3 3 1
author Grace Hopper
author-mail <grace@example.com>
author-time 1700100000
author-tz +0000
committer Grace Hopper
committer-mail <grace@example.com>
committer-time 1700100000
committer-tz +0000
summary Add logging
filename lib/service.dart
\t  logDebug("Initialized");
''';

      final hunks = GitBlameParser.parse(output);
      expect(hunks.length, equals(2));

      final first = hunks[0];
      expect(first.commitHash, equals('41e97669d6756fdba056a2360f0653d9e8790cb9'));
      expect(first.shortHash, equals('41e97669'));
      expect(first.author, equals('Ada Lovelace'));
      expect(first.authorEmail, equals('ada@example.com'));
      expect(first.authorTime, equals(DateTime.fromMillisecondsSinceEpoch(1700000000 * 1000, isUtc: true)));
      expect(first.summary, equals('Initial implementation'));
      expect(first.originalLine, equals(1));
      expect(first.finalLine, equals(1));
      expect(first.lineCount, equals(2));
      expect(first.lines, equals(['void startService() {', '  print("Starting...");']));
      expect(first.containsLine(1), isTrue);
      expect(first.containsLine(2), isTrue);
      expect(first.containsLine(3), isFalse);

      final second = hunks[1];
      expect(second.commitHash, equals('8a7b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b'));
      expect(second.shortHash, equals('8a7b9c0d'));
      expect(second.author, equals('Grace Hopper'));
      expect(second.authorEmail, equals('grace@example.com'));
      expect(second.summary, equals('Add logging'));
      expect(second.finalLine, equals(3));
      expect(second.lineCount, equals(1));
      expect(second.lines, equals(['  logDebug("Initialized");']));
    });

    test('reaproveita metadados cacheados quando o Git omite repetições do mesmo commit', () {
      const output = '''
41e97669d6756fdba056a2360f0653d9e8790cb9 1 1 1
author Margaret Hamilton
author-mail <margaret@example.com>
author-time 1600000000
summary Apollo guidance code
filename guidance.dart
\tvoid launch() {
8a7b9c0d1e2f3a4b5c6d7e8f9a0b1c2d3e4f5a6b 2 2 1
author Katherine Johnson
author-mail <katherine@example.com>
author-time 1600000050
summary Trajectory calc
filename guidance.dart
\t  calculateTrajectory();
41e97669d6756fdba056a2360f0653d9e8790cb9 3 3 1
\t}
''';

      final hunks = GitBlameParser.parse(output);
      expect(hunks.length, equals(3));

      // O terceiro hunk não continha linhas author/summary na saída bruta, mas veio do cache
      final third = hunks[2];
      expect(third.commitHash, equals('41e97669d6756fdba056a2360f0653d9e8790cb9'));
      expect(third.author, equals('Margaret Hamilton'));
      expect(third.authorEmail, equals('margaret@example.com'));
      expect(third.summary, equals('Apollo guidance code'));
      expect(third.finalLine, equals(3));
      expect(third.lines, equals(['}']));
    });
  });
}
