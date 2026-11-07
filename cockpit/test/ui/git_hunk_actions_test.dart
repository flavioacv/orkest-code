import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_command_runner.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_diff_reader.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_status_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_diff.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/domain/services/git_hunk_service.dart';
import 'package:orkest_code/app/orkest/ui/session/diff_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/diff_viewer.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class _NoopReader implements GitStatusReader {
  @override
  Future<GitInfo?> read(String path) async => null;
}

class _NoopRunner implements GitCommandRunner {
  @override
  GitRun run(String repoPath, List<String> args) => throw UnimplementedError();
  @override
  GitRun syncPullPush(String repoPath) => throw UnimplementedError();
  @override
  GitMergeOutcome mergeIntoParent(
    String parentPath,
    String worktreePath,
    String worktreeBranch,
  ) => throw UnimplementedError();
}

GitController _makeController() => GitController(
      _NoopReader(),
      _NoopRunner(),
      WindowActivityController(),
      hunkService: const GitHunkService(),
    );

Widget _wrap(Widget child) => TranslationProvider(
      child: ShadcnApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: Scaffold(
          child: SizedBox(
            width: 800,
            height: 600,
            child: child,
          ),
        ),
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P04 · UI DiffViewer e Hunk Action Buttons', () {
    const sampleHunk = DiffHunk(
      header: '@@ -1,3 +1,4 @@',
      lines: [
        DiffLine(kind: DiffLineKind.context, text: 'line 1'),
        DiffLine(kind: DiffLineKind.added, text: 'line added'),
        DiffLine(kind: DiffLineKind.context, text: 'line 2'),
        DiffLine(kind: DiffLineKind.context, text: 'line 3'),
      ],
    );

    final sampleDiff = FileDiff(
      path: '/repo/sample.txt',
      kind: FileDiffKind.modified,
      hunks: const [sampleHunk],
    );

    testWidgets('1. workingTree exibe botões Stage e Discard, mas não Unstage',
        (tester) async {
      final session = DiffViewerSession(
        id: 'session_1',
        projectId: 'proj_1',
        path: '/repo/sample.txt',
        diff: sampleDiff,
        target: GitDiffTarget.workingTree,
      );

      var stagedCalled = false;
      var discardCalled = false;
      var unstageCalled = false;

      session.onStageHunk = (hunk) async => stagedCalled = true;
      session.onDiscardHunk = (hunk) async => discardCalled = true;
      session.onUnstageHunk = (hunk) async => unstageCalled = true;

      await tester.pumpWidget(_wrap(DiffViewer(session: session)));
      await tester.pumpAndSettle();

      // Stage e Discard visíveis para workingTree
      expect(find.text(t.orkest.fileTreePanel.stageHunk), findsOneWidget);
      expect(find.text(t.orkest.fileTreePanel.discardHunk), findsOneWidget);
      // Unstage NÃO deve ser renderizado para workingTree
      expect(find.text(t.orkest.fileTreePanel.unstageHunk), findsNothing);

      // Clicar em Stage
      await tester.tap(find.text(t.orkest.fileTreePanel.stageHunk));
      await tester.pump();
      expect(stagedCalled, isTrue);
      expect(discardCalled, isFalse);
      expect(unstageCalled, isFalse);
    });

    testWidgets('2. staged exibe botão Unstage, mas não Stage nem Discard',
        (tester) async {
      final session = DiffViewerSession(
        id: 'session_2',
        projectId: 'proj_1',
        path: '/repo/sample.txt',
        diff: sampleDiff,
        target: GitDiffTarget.staged,
      );

      var unstageCalled = false;
      session.onUnstageHunk = (hunk) async => unstageCalled = true;

      await tester.pumpWidget(_wrap(DiffViewer(session: session)));
      await tester.pumpAndSettle();

      expect(find.text(t.orkest.fileTreePanel.unstageHunk), findsOneWidget);
      expect(find.text(t.orkest.fileTreePanel.stageHunk), findsNothing);
      expect(find.text(t.orkest.fileTreePanel.discardHunk), findsNothing);

      // Clicar em Unstage
      await tester.tap(find.text(t.orkest.fileTreePanel.unstageHunk));
      await tester.pump();
      expect(unstageCalled, isTrue);
    });

    testWidgets('3. head/histórico não exibe ações de mutação por hunk',
        (tester) async {
      final session = DiffViewerSession(
        id: 'session_3',
        projectId: 'proj_1',
        path: '/repo/sample.txt',
        diff: sampleDiff,
        target: GitDiffTarget.head,
      );

      session.onStageHunk = (hunk) async {};
      session.onDiscardHunk = (hunk) async {};
      session.onUnstageHunk = (hunk) async {};

      await tester.pumpWidget(_wrap(DiffViewer(session: session)));
      await tester.pumpAndSettle();

      expect(find.text(t.orkest.fileTreePanel.stageHunk), findsNothing);
      expect(find.text(t.orkest.fileTreePanel.unstageHunk), findsNothing);
      expect(find.text(t.orkest.fileTreePanel.discardHunk), findsNothing);
    });

    testWidgets('4. Diálogo de confirmação protege ação de descarte',
        (tester) async {
      final session = DiffViewerSession(
        id: 'session_4',
        projectId: 'proj_1',
        path: '/repo/sample.txt',
        diff: sampleDiff,
        target: GitDiffTarget.workingTree,
      );

      var discardConfirmed = false;
      session.onDiscardHunk = (hunk) async => discardConfirmed = true;

      await tester.pumpWidget(_wrap(DiffViewer(session: session)));
      await tester.pumpAndSettle();

      // Clica em Discard Hunk
      await tester.tap(find.text(t.orkest.fileTreePanel.discardHunk));
      await tester.pumpAndSettle();

      // Confirma que o diálogo destrutivo abriu
      expect(find.text(t.orkest.fileTreePanel.discardChangesTitle), findsOneWidget);

      // Clica em cancelar
      final cancelFinder = find.text(t.common.cancel);
      if (cancelFinder.evaluate().isNotEmpty) {
        await tester.tap(cancelFinder);
      } else {
        await tester.tap(find.byType(OutlineButton).first);
      }
      await tester.pumpAndSettle();
      expect(discardConfirmed, isFalse);

      // Clica em Discard novamente e confirma
      await tester.tap(find.text(t.orkest.fileTreePanel.discardHunk));
      await tester.pumpAndSettle();

      // Clica no botão de ação de confirmar descarte dentro do diálogo
      final confirmButtons = find.text(t.orkest.fileTreePanel.discard);
      expect(confirmButtons, findsWidgets);
      await tester.tap(confirmButtons.last);
      await tester.pumpAndSettle();

      expect(discardConfirmed, isTrue);
    });

    testWidgets('5. Exibição e fechamento do banner de hunkOperationError',
        (tester) async {
      final session = DiffViewerSession(
        id: 'session_5',
        projectId: 'proj_1',
        path: '/repo/sample.txt',
        diff: sampleDiff,
        target: GitDiffTarget.workingTree,
      );

      session.hunkOperationError = 'Falha ao aplicar patch: patch rejected.';

      await tester.pumpWidget(_wrap(DiffViewer(session: session)));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('diff-hunk-error-banner')), findsOneWidget);
      expect(find.text('Falha ao aplicar patch: patch rejected.'), findsOneWidget);

      // Clica no ícone de fechar do banner
      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('diff-hunk-error-banner')), findsNothing);
      expect(session.hunkOperationError, isNull);
    });
  });

  group('P04 · GitController e Hunk Staging / Unstage / Discard Real', () {
    test('6. Fluxo completo de stage, unstage e discard com Git real via GitController',
        () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_hunk_ctrl_test_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Tester'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'tester@example.com'], workingDirectory: tempDir.path);

        final file = File('${tempDir.path}/app.txt');
        await file.writeAsString('base line 1\nbase line 2\nbase line 3\n');
        await Process.run('git', ['add', 'app.txt'], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'Initial commit'], workingDirectory: tempDir.path);

        // Edita arquivo criando 1 hunk no working tree
        await file.writeAsString('base line 1\nline 1.5 added\nbase line 2\nbase line 3\n');

        final controller = _makeController();

        const hunk = DiffHunk(
          header: '@@ -1,3 +1,4 @@',
          lines: [
            DiffLine(kind: DiffLineKind.context, text: 'base line 1'),
            DiffLine(kind: DiffLineKind.added, text: 'line 1.5 added'),
            DiffLine(kind: DiffLineKind.context, text: 'base line 2'),
            DiffLine(kind: DiffLineKind.context, text: 'base line 3'),
          ],
        );

        // A. Stage Hunk
        final stageResult = await controller.stageHunk(
          root: tempDir.path,
          relativePath: 'app.txt',
          hunk: hunk,
        );
        expect(stageResult, isA<Success<void, String>>());

        // Verifica que o index tem a alteração staged
        var stagedDiff = await Process.run('git', ['diff', '--cached'], workingDirectory: tempDir.path);
        expect(stagedDiff.stdout as String, contains('+line 1.5 added'));

        // Verifica que o working tree agora está limpo
        var wtDiff = await Process.run('git', ['diff'], workingDirectory: tempDir.path);
        expect((wtDiff.stdout as String).trim(), isEmpty);

        // B. Unstage Hunk
        final unstageResult = await controller.unstageHunk(
          root: tempDir.path,
          relativePath: 'app.txt',
          hunk: hunk,
        );
        expect(unstageResult, isA<Success<void, String>>());

        // Verifica que o index voltou a ficar limpo
        stagedDiff = await Process.run('git', ['diff', '--cached'], workingDirectory: tempDir.path);
        expect((stagedDiff.stdout as String).trim(), isEmpty);

        // E o working tree voltou a ter a alteração unstaged
        wtDiff = await Process.run('git', ['diff'], workingDirectory: tempDir.path);
        expect(wtDiff.stdout as String, contains('+line 1.5 added'));

        // C. Discard Hunk
        final discardResult = await controller.discardHunk(
          root: tempDir.path,
          relativePath: 'app.txt',
          hunk: hunk,
        );
        expect(discardResult, isA<Success<void, String>>());

        // Verifica que o working tree foi descartado e voltou ao estado do HEAD
        wtDiff = await Process.run('git', ['diff'], workingDirectory: tempDir.path);
        expect((wtDiff.stdout as String).trim(), isEmpty);

        final diskContent = await file.readAsString();
        expect(diskContent, 'base line 1\nbase line 2\nbase line 3\n');
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });

    test('7. Corrida e conflito: rejeição segura de hunk obsoleto', () async {
      final tempDir = await Directory.systemTemp.createTemp('orkest_hunk_race_test_');

      try {
        await Process.run('git', ['init', '-b', 'main'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.name', 'Tester'], workingDirectory: tempDir.path);
        await Process.run('git', ['config', 'user.email', 'tester@example.com'], workingDirectory: tempDir.path);

        final file = File('${tempDir.path}/app.txt');
        await file.writeAsString('A\nB\nC\n');
        await Process.run('git', ['add', 'app.txt'], workingDirectory: tempDir.path);
        await Process.run('git', ['commit', '-m', 'Initial commit'], workingDirectory: tempDir.path);

        // Modificação no disco
        await file.writeAsString('A\nB_MODIFICADO\nC\n');

        final controller = _makeController();

        // Hunk obsoleto que tenta aplicar sobre um conteúdo que já não existe
        const staleHunk = DiffHunk(
          header: '@@ -10,3 +10,4 @@',
          lines: [
            DiffLine(kind: DiffLineKind.context, text: 'UNKNOWN_LINE_1'),
            DiffLine(kind: DiffLineKind.added, text: 'NEW_LINE'),
            DiffLine(kind: DiffLineKind.context, text: 'UNKNOWN_LINE_2'),
          ],
        );

        final result = await controller.stageHunk(
          root: tempDir.path,
          relativePath: 'app.txt',
          hunk: staleHunk,
        );

        // Deve falhar com mensagem segura sem quebrar a execução
        expect(result, isA<Failure<void, String>>());
        final error = (result as Failure<void, String>).error;
        expect(error, isNotEmpty);
      } finally {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      }
    });
  });
}
