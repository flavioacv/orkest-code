import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/window_activity_controller.dart';
import 'package:orkest_code/app/core/utils/path_utils.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_binary.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_command_runner_impl.dart';
import 'package:orkest_code/app/orkest/data/filesystem/git_status_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_file_status.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_info.dart';
import 'package:orkest_code/app/orkest/domain/entities/workbench_layout_state.dart';
import 'package:orkest_code/app/orkest/domain/services/git_hunk_service.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/file_tree_panel.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

Widget _wrap(Widget child) => TranslationProvider(
      child: ShadcnApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: Scaffold(
          child: SizedBox(
            width: 800,
            height: 700,
            child: child,
          ),
        ),
      ),
    );

Widget _buildPanel({
  required String rootPath,
  required List<WorkspaceRoot> roots,
  List<String> stagedPaths = const [],
  List<String> unstagedPaths = const [],
  GitFileStatus? Function(String)? gitStatusOf,
}) =>
    _wrap(
      FileTreePanel(
        rootPath: rootPath,
        roots: roots,
        revision: 0,
        sourceControlViewMode: SourceControlViewMode.list,
        workbenchLayout: const WorkbenchLayoutState(
          activeTool: WorkbenchToolId.sourceControl,
        ),
        listChildren: (_) async => const [],
        gitStatusOf: gitStatusOf ?? (_) => null,
        onOpenFile: (_) {},
        onOpenDiff: (_) {},
        onTapDiff: (_) {},
        onOpenStagedDiff: (_) {},
        onTapStagedDiff: (_) {},
        isGitRepo: true,
        changedPaths: [...stagedPaths, ...unstagedPaths],
        stagedPaths: stagedPaths,
        unstagedPaths: unstagedPaths,
        onOpenWith: (_) {},
        onCreateInFolder: (_, {command}) {},
        onCreate: (_, _, _) async => const Success(null),
        onRename: (_, _) async => const Success(null),
        onDelete: (_) async => const Success(null),
        onMove: (_, _) async => const Success(null),
        onCopy: (_) {},
        onCut: (_) {},
        onPaste: (_) async => const Success(null),
        canPaste: false,
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('P05 · Multifolder Git no SourceControl e Resolução Determinística', () {
    late Directory tempDir;
    late Directory repoADir;
    late Directory repoBDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('orkest_multifolder_test_');
      repoADir = Directory('${tempDir.path}/repo_alpha')..createSync(recursive: true);
      repoBDir = Directory('${tempDir.path}/repo_beta')..createSync(recursive: true);

      // Inicializa repositório Git real A
      Process.runSync('git', ['init', '-b', 'main'], workingDirectory: repoADir.path);
      Process.runSync('git', ['config', 'user.name', 'Tester'], workingDirectory: repoADir.path);
      Process.runSync('git', ['config', 'user.email', 'test@orkest.dev'], workingDirectory: repoADir.path);
      File('${repoADir.path}/alpha.txt').writeAsStringSync('alpha v1\n');
      Process.runSync('git', ['add', '.'], workingDirectory: repoADir.path);
      Process.runSync('git', ['commit', '-m', 'Initial commit A'], workingDirectory: repoADir.path);

      // Inicializa repositório Git real B
      Process.runSync('git', ['init', '-b', 'feature-b'], workingDirectory: repoBDir.path);
      Process.runSync('git', ['config', 'user.name', 'Tester'], workingDirectory: repoBDir.path);
      Process.runSync('git', ['config', 'user.email', 'test@orkest.dev'], workingDirectory: repoBDir.path);
      File('${repoBDir.path}/beta.txt').writeAsStringSync('beta v1\n');
      Process.runSync('git', ['add', '.'], workingDirectory: repoBDir.path);
      Process.runSync('git', ['commit', '-m', 'Initial commit B'], workingDirectory: repoBDir.path);
    });

    tearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } catch (_) {}
    });

    testWidgets('Header do SourceControlPanel exibe contagem e branches em múltiplos repositórios', (tester) async {
      final roots = [
        WorkspaceRoot(
          path: repoADir.path,
          name: 'repo_alpha',
          git: const GitInfo(branch: 'main'),
        ),
        WorkspaceRoot(
          path: repoBDir.path,
          name: 'repo_beta',
          git: const GitInfo(branch: 'feature-b'),
        ),
      ];

      await tester.pumpWidget(
        _buildPanel(
          rootPath: tempDir.path,
          roots: roots,
        ),
      );
      await tester.pumpAndSettle();

      // Valida que o cabeçalho mostra ambos os repositórios e suas respectivas branches
      expect(find.text('2 repos · repo_alpha:main, repo_beta:feature-b'), findsOneWidget);
    });

    testWidgets('Header do SourceControlPanel com 1 repo Git e 1 pasta comum preserva nome e branch do repo', (tester) async {
      final nonGitDir = Directory('${tempDir.path}/plain_docs')..createSync();
      final roots = [
        WorkspaceRoot(
          path: repoADir.path,
          name: 'repo_alpha',
          git: const GitInfo(branch: 'main'),
        ),
        WorkspaceRoot(
          path: nonGitDir.path,
          name: 'plain_docs',
          git: null, // Sem Git
        ),
      ];

      await tester.pumpWidget(
        _buildPanel(
          rootPath: tempDir.path,
          roots: roots,
        ),
      );
      await tester.pumpAndSettle();

      // Não deve mostrar null ou omitir a branch quando só há 1 repositório Git em workspace misto
      expect(find.text('repo_alpha · main'), findsOneWidget);
    });

    testWidgets('Renderiza seções colapsáveis separadas para cada root no Source Control multifolder', (tester) async {
      final fileA = '${repoADir.path}/alpha_modified.txt';
      final fileB = '${repoBDir.path}/beta_staged.txt';
      File(fileA).writeAsStringSync('alpha v2\n');
      File(fileB).writeAsStringSync('beta v2\n');

      final roots = [
        WorkspaceRoot(
          path: repoADir.path,
          name: 'repo_alpha',
          git: const GitInfo(branch: 'main'),
        ),
        WorkspaceRoot(
          path: repoBDir.path,
          name: 'repo_beta',
          git: const GitInfo(branch: 'feature-b'),
        ),
      ];

      await tester.pumpWidget(
        _buildPanel(
          rootPath: tempDir.path,
          roots: roots,
          stagedPaths: [fileB],
          unstagedPaths: [fileA],
          gitStatusOf: (path) => path == fileB ? GitFileStatus.staged : GitFileStatus.modified,
        ),
      );
      await tester.pumpAndSettle();

      // Ambas as raízes devem aparecer nos cabeçalhos de seção colapsáveis
      expect(find.text('repo_alpha'), findsOneWidget);
      expect(find.text('repo_beta'), findsOneWidget);
      expect(find.text('alpha_modified.txt'), findsOneWidget);
      expect(find.text('beta_staged.txt'), findsOneWidget);
    });

    test('GitController e GitCommandRunner executam operações atômicas isoladas em cada repo', () async {
      final binary = GitBinary();
      final runner = GitCommandRunnerImpl(binary);
      final statusReader = GitStatusReaderImpl(binary);
      final activity = WindowActivityController();
      final controller = GitController(
        statusReader,
        runner,
        activity,
        hunkService: const GitHunkService(),
      );

      // Modifica arquivo em repoA e em repoB
      final fileA = File('${repoADir.path}/alpha.txt');
      fileA.writeAsStringSync('alpha changed\n');
      final fileB = File('${repoBDir.path}/beta.txt');
      fileB.writeAsStringSync('beta changed\n');

      // Executa git add em repoA
      final addA = await controller.collect(repoADir.path, ['add', '--', 'alpha.txt']);
      expect(addA, isNull);

      // Verifica status de repoA (staged)
      final statusA = await statusReader.read(repoADir.path);
      expect(statusA, isNotNull);
      expect(statusA!.files['alpha.txt'], equals(GitFileStatus.staged));

      // Verifica status de repoB (permanece unstaged / modified, intocado)
      final statusB = await statusReader.read(repoBDir.path);
      expect(statusB, isNotNull);
      expect(statusB!.files['beta.txt'], equals(GitFileStatus.modified));

      // Executa git add em repoB
      final addB = await controller.collect(repoBDir.path, ['add', '--', 'beta.txt']);
      expect(addB, isNull);

      final statusBAfter = await statusReader.read(repoBDir.path);
      expect(statusBAfter!.files['beta.txt'], equals(GitFileStatus.staged));

      // Desfaz stage apenas em repoA
      final unstageA = await controller.collect(repoADir.path, ['restore', '--staged', '--', 'alpha.txt']);
      expect(unstageA, isNull);

      final statusARestored = await statusReader.read(repoADir.path);
      expect(statusARestored!.files['alpha.txt'], equals(GitFileStatus.modified));
      // RepoB continua staged
      final statusBMaintained = await statusReader.read(repoBDir.path);
      expect(statusBMaintained!.files['beta.txt'], equals(GitFileStatus.staged));
    });

    test('Resolução determinística de raiz mais específica evita conflito em raízes aninhadas', () {
      final parentRoot = '${tempDir.path}/workspace';
      final childRoot = '${tempDir.path}/workspace/subproject';
      final candidateRoots = [parentRoot, childRoot]
        ..sort((a, b) => b.length.compareTo(a.length));

      String? resolve(String path) {
        for (final r in candidateRoots) {
          if (isUnderPath(path, r)) return r;
        }
        return null;
      }

      // Arquivo dentro do subproject deve resolver deterministicamente para childRoot
      final childFile = '$childRoot/lib/sub.dart';
      expect(resolve(childFile), equals(childRoot));

      // Arquivo fora do subproject mas dentro do workspace deve resolver para parentRoot
      final parentFile = '$parentRoot/lib/main.dart';
      expect(resolve(parentFile), equals(parentRoot));

      // Arquivo fora de ambos deve resolver null
      final outsideFile = '${tempDir.path}/other/file.dart';
      expect(resolve(outsideFile), isNull);
    });
  });
}
