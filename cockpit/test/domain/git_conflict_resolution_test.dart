import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/orkest/domain/services/git_conflict_service.dart';

void main() {
  const service = GitConflictService();

  test('edited block preserves CRLF and unrelated content', () {
    const text =
        'before\r\n<<<<<<< HEAD\r\nours\r\n||||||| base\r\n\r\n=======\r\ntheirs\r\n>>>>>>> branch\r\nafter\r\n';
    final block = service.parseConflicts(text).single;
    expect(block.ours, 'ours');
    expect(block.base, '');
    expect(
      service.replaceBlock(
        text: text,
        block: block,
        replacement: 'edited\nresult',
      ),
      'before\r\nedited\r\nresult\r\nafter\r\n',
    );
    expect(
      service.resolveAll(text: text, resolution: ConflictResolution.theirs),
      'before\r\ntheirs\r\nafter\r\n',
    );
  });

  test('resolution at EOF does not introduce an unrequested newline', () {
    const text = 'before\n<<<<<<< HEAD\nours\n=======\ntheirs\n>>>>>>> branch';
    final block = service.parseConflicts(text).single;
    expect(
      service.resolveBlock(
        text: text,
        block: block,
        resolution: ConflictResolution.ours,
      ),
      'before\nours',
    );
    expect(
      service.replaceBlock(text: text, block: block, replacement: ''),
      'before\n',
    );
  });

  test('empty diff3 base is available as an explicit resolution', () {
    const text =
        '<<<<<<< HEAD\nours\n||||||| base\n=======\ntheirs\n>>>>>>> branch\n';
    final block = service.parseConflicts(text).single;
    expect(block.base, '');
    expect(
      service.resolveBlock(
        text: text,
        block: block,
        resolution: ConflictResolution.base,
      ),
      '',
    );
  });

  group('GitConflictService - Document Resolution & Unresolved Markers', () {
    test('hasUnresolvedMarkers detects all git conflict marker patterns', () {
      expect(service.hasUnresolvedMarkers('<<<<<<< HEAD\ncode\n======='), isTrue);
      expect(service.hasUnresolvedMarkers('======='), isTrue);
      expect(service.hasUnresolvedMarkers('>>>>>>> branch'), isTrue);
      expect(service.hasUnresolvedMarkers('||||||| base'), isTrue);
      expect(service.hasUnresolvedMarkers('final validCode = 123;'), isFalse);
      expect(service.hasUnresolvedMarkers('if (a << 7 > 0) return;'), isFalse);
    });

    test('resolveDocument resolves multiple conflicts preserving outside text and CRLF', () {
      const text =
          'header\r\n'
          '<<<<<<< HEAD\r\n'
          'ours 1\r\n'
          '=======\r\n'
          'theirs 1\r\n'
          '>>>>>>> incoming\r\n'
          'middle text\r\n'
          '<<<<<<< HEAD\r\n'
          'ours 2\r\n'
          '||||||| base\r\n'
          'base 2\r\n'
          '=======\r\n'
          'theirs 2\r\n'
          '>>>>>>> incoming\r\n'
          'footer\r\n';

      final resolved = service.resolveDocument(
        text: text,
        results: ['custom 1', 'custom 2'],
      );

      expect(
        resolved,
        'header\r\n'
        'custom 1\r\n'
        'middle text\r\n'
        'custom 2\r\n'
        'footer\r\n',
      );
    });

    test('resolveDocument preserves EOF without newline', () {
      const text =
          'start\n'
          '<<<<<<< HEAD\n'
          'left\n'
          '=======\n'
          'right\n'
          '>>>>>>> branch';

      final resolved = service.resolveDocument(
        text: text,
        results: ['chosen'],
      );

      expect(resolved, 'start\nchosen');
    });

    test('resolveDocument rejects unresolved markers or mismatched result count', () {
      const text =
          '<<<<<<< HEAD\n'
          'ours\n'
          '=======\n'
          'theirs\n'
          '>>>>>>> branch\n';

      expect(
        () => service.resolveDocument(text: text, results: []),
        throwsArgumentError,
      );

      expect(
        () => service.resolveDocument(
          text: text,
          results: ['<<<<<<< HEAD\nnot resolved'],
        ),
        throwsArgumentError,
      );
    });
  });

  group('GitConflictService - Parsing', () {
    test('detecta ausência de marcadores de conflito', () {
      const cleanText = '''
void main() {
  print('Hello world');
}
''';
      expect(service.hasConflictMarkers(cleanText), isFalse);
      expect(service.parseConflicts(cleanText), isEmpty);
    });

    test('parseia bloco de conflito simples (2-way / standard)', () {
      const conflictText = '''
int calculate() {
<<<<<<< HEAD
  return 42;
=======
  return 100;
>>>>>>> feature-calc
}
''';

      expect(service.hasConflictMarkers(conflictText), isTrue);
      final blocks = service.parseConflicts(conflictText);
      expect(blocks.length, equals(1));

      final block = blocks.first;
      expect(block.startLine, equals(2));
      expect(block.endLine, equals(6));
      expect(block.ours, equals('  return 42;'));
      expect(block.base, isNull);
      expect(block.theirs, equals('  return 100;'));
      expect(block.oursLabel, equals('HEAD'));
      expect(block.theirsLabel, equals('feature-calc'));
    });

    test('parseia bloco com ancestral comum (3-way / diff3)', () {
      const diff3Text = '''
<<<<<<< HEAD
final greeting = 'Olá mundo!';
||||||| merged common ancestors
final greeting = 'Hello';
=======
final greeting = 'Hello world!';
>>>>>>> feature-i18n
''';

      final blocks = service.parseConflicts(diff3Text);
      expect(blocks.length, equals(1));

      final block = blocks.first;
      expect(block.ours, equals("final greeting = 'Olá mundo!';"));
      expect(block.base, equals("final greeting = 'Hello';"));
      expect(block.theirs, equals("final greeting = 'Hello world!';"));
      expect(block.oursLabel, equals('HEAD'));
      expect(block.theirsLabel, equals('feature-i18n'));
    });

    test('parseia múltiplos blocos de conflito no mesmo arquivo', () {
      const multiConflict = '''
<<<<<<< HEAD
const a = 1;
=======
const a = 10;
>>>>>>> branch-a

const middle = true;

<<<<<<< HEAD
const b = 2;
=======
const b = 20;
>>>>>>> branch-b
''';

      final blocks = service.parseConflicts(multiConflict);
      expect(blocks.length, equals(2));
      expect(blocks[0].ours, equals('const a = 1;'));
      expect(blocks[0].theirs, equals('const a = 10;'));
      expect(blocks[1].ours, equals('const b = 2;'));
      expect(blocks[1].theirs, equals('const b = 20;'));
    });
  });

  group('GitConflictService - Resolução de Blocos', () {
    const sample = '''
start
<<<<<<< HEAD
line-ours
=======
line-theirs
>>>>>>> incoming
end
''';

    test('resolve bloco para ours', () {
      final blocks = service.parseConflicts(sample);
      final result = service.resolveBlock(
        text: sample,
        block: blocks.first,
        resolution: ConflictResolution.ours,
      );

      expect(
        result,
        equals('''
start
line-ours
end
'''),
      );
    });

    test('resolve bloco para theirs', () {
      final blocks = service.parseConflicts(sample);
      final result = service.resolveBlock(
        text: sample,
        block: blocks.first,
        resolution: ConflictResolution.theirs,
      );

      expect(
        result,
        equals('''
start
line-theirs
end
'''),
      );
    });

    test('resolve bloco para both (ambos)', () {
      final blocks = service.parseConflicts(sample);
      final result = service.resolveBlock(
        text: sample,
        block: blocks.first,
        resolution: ConflictResolution.both,
      );

      expect(
        result,
        equals('''
start
line-ours
line-theirs
end
'''),
      );
    });

    test('resolve múltiplos blocos em lote (resolveAll)', () {
      const multi = '''
<<<<<<< HEAD
alpha
=======
beta
>>>>>>> incoming
middle
<<<<<<< HEAD
gamma
=======
delta
>>>>>>> incoming
''';

      final resolvedTheirs = service.resolveAll(
        text: multi,
        resolution: ConflictResolution.theirs,
      );

      expect(
        resolvedTheirs,
        equals('''
beta
middle
delta
'''),
      );
    });
  });

  group('GitConflictService - Detecção de Operação Git', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('git_op_test_');
      Directory('${tempDir.path}/.git').createSync(recursive: true);
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('detecta repositório sem operação em andamento', () {
      expect(
        service.detectOngoingOperation(tempDir.path),
        equals(GitOngoingOperation.none),
      );
    });

    test('detecta merge em andamento (MERGE_HEAD)', () {
      File('${tempDir.path}/.git/MERGE_HEAD').writeAsStringSync('dummy_sha');
      expect(
        service.detectOngoingOperation(tempDir.path),
        equals(GitOngoingOperation.merge),
      );
    });

    test('detecta rebase em andamento (rebase-merge)', () {
      Directory('${tempDir.path}/.git/rebase-merge').createSync();
      expect(
        service.detectOngoingOperation(tempDir.path),
        equals(GitOngoingOperation.rebase),
      );
    });

    test('detecta cherry-pick em andamento (CHERRY_PICK_HEAD)', () {
      File(
        '${tempDir.path}/.git/CHERRY_PICK_HEAD',
      ).writeAsStringSync('dummy_sha');
      expect(
        service.detectOngoingOperation(tempDir.path),
        equals(GitOngoingOperation.cherryPick),
      );
    });

    test('detecta revert em andamento (REVERT_HEAD)', () {
      File('${tempDir.path}/.git/REVERT_HEAD').writeAsStringSync('dummy_sha');
      expect(
        service.detectOngoingOperation(tempDir.path),
        equals(GitOngoingOperation.revert),
      );
    });
  });

  group('GitConflictService - Estágios do Índice Git (Stages :1:, :2:, :3:)', () {
    test('enrichBlocksWithBase preenche ancestral quando bloco não possui diff3', () {
      const block2Way = ConflictBlock(
        from: 0,
        to: 10,
        startLine: 1,
        endLine: 5,
        ours: 'alpha',
        theirs: 'beta',
        oursLabel: 'HEAD',
        theirsLabel: 'incoming',
      );
      const stages = GitConflictStages(
        base: 'common ancestor code',
        ours: 'alpha',
        theirs: 'beta',
      );

      final enriched = service.enrichBlocksWithBase(
        blocks: [block2Way],
        stages: stages,
      );

      expect(enriched.single.base, 'common ancestor code');
      expect(enriched.single.ours, 'alpha');
      expect(enriched.single.theirs, 'beta');
    });

    test('readConflictStages recupera base, ours e theirs de conflito real no índice', () async {
      final tempDir = Directory.systemTemp.createTempSync('git_stages_test_');
      try {
        void runGit(List<String> args) {
          final res = Process.runSync(
            'git',
            args,
            workingDirectory: tempDir.path,
          );
          if (res.exitCode != 0) {
            throw Exception('Git failed: ${res.stderr}');
          }
        }

        runGit(['init', '-b', 'main']);
        runGit(['config', 'user.name', 'Test']);
        runGit(['config', 'user.email', 'test@test.com']);

        // 1. Commit base (ancestral)
        final testFile = File('${tempDir.path}/conflict_file.txt');
        testFile.writeAsStringSync('common ancestor content\n');
        runGit(['add', 'conflict_file.txt']);
        runGit(['commit', '-m', 'commit base']);

        // 2. Branch feature (theirs)
        runGit(['checkout', '-b', 'feature']);
        testFile.writeAsStringSync('theirs incoming content\n');
        runGit(['add', 'conflict_file.txt']);
        runGit(['commit', '-m', 'commit feature']);

        // 3. Voltar para main e alterar o mesmo arquivo (ours)
        runGit(['checkout', 'main']);
        testFile.writeAsStringSync('ours local content\n');
        runGit(['add', 'conflict_file.txt']);
        runGit(['commit', '-m', 'commit main']);

        // 4. Merge provocando conflito
        final mergeRes = Process.runSync(
          'git',
          ['merge', 'feature'],
          workingDirectory: tempDir.path,
        );
        // O merge deve falhar com conflito (exitCode != 0)
        expect(mergeRes.exitCode, isNot(0));

        // 5. Ler os estágios reais do índice através de readConflictStages
        final result = await service.readConflictStages(
          repoRoot: tempDir.path,
          relativePath: 'conflict_file.txt',
        );

        expect(result.isSuccess, isTrue);
        final stages = (result as Success<GitConflictStages, String>).value;
        expect(stages.hasBase, isTrue);
        expect(stages.hasOurs, isTrue);
        expect(stages.hasTheirs, isTrue);
        expect(stages.base?.trim(), 'common ancestor content');
        expect(stages.ours?.trim(), 'ours local content');
        expect(stages.theirs?.trim(), 'theirs incoming content');
      } finally {
        if (tempDir.existsSync()) {
          tempDir.deleteSync(recursive: true);
        }
      }
    });
  });
}
