import 'package:orkest_code/app/orkest/domain/contracts/git_command_runner.dart';
import 'dart:async';

import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_branch.dart';
import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_branch_error.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/git_controller.dart';
import 'package:orkest_code/app/orkest/ui/viewmodels/orkest_viewmodel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/git_branch_picker.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

const _main = GitBranch(name: 'main', isRemote: false, isCurrent: true);
const _feature = GitBranch(name: 'feature', isRemote: false, isCurrent: false);

class _Git extends Fake implements GitController {
  Future<Result<List<GitBranch>, GitBranchError>> Function() load = () async =>
      const Success([_main, _feature]);
  final roots = <String>[];
  String? checkedOut;
  String? created;
  String? createdFrom;
  int fetchExit = 0;
  @override
  GitRun fetch(String root) => GitRun(
    output: Stream.fromIterable(['remote unavailable']),
    exitCode: Future.value(fetchExit),
  );
  final refreshed = <String>[];

  @override
  Future<void> refreshRepository(String root) async {
    refreshed.add(root);
  }

  @override
  Future<Result<List<GitBranch>, GitBranchError>> branches(String root) {
    roots.add(root);
    return load();
  }

  @override
  Future<Result<void, GitBranchError>> checkoutBranch(
    String root,
    GitBranch branch,
  ) async {
    roots.add(root);
    checkedOut = branch.name;
    return const Success(null);
  }

  @override
  Future<Result<void, GitBranchError>> createBranch(
    String root,
    String name, {
    String? startPoint,
  }) async {
    roots.add(root);
    created = name;
    createdFrom = startPoint;
    return const Success(null);
  }
}

class _ViewModel extends Fake implements OrkestViewModel {
  _ViewModel(this.git);

  @override
  final GitController git;

  @override
  Project? get selectedProject => null;
}

void main() {
  late _Git git;

  setUp(() => git = _Git());

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    LocaleSettings.setLocale(AppLocale.en);
    final vm = _ViewModel(git);
    final scoped = Scoped()..add<OrkestViewModel>(() => vm);
    final tokens = buildTokens(brightness: Brightness.dark);
    await tester.pumpWidget(
      TranslationProvider(
        child: ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: OrkestTheme(
            colors: tokens.colors,
            typo: tokens.typo,
            syntax: tokens.syntax,
            terminal: tokens.terminal,
            child: scoped.specs.single.wrap(
              vm,
              Builder(
                builder: (context) => Center(
                  child: PrimaryButton(
                    onPressed: () => showGitBranchPicker(context, '/repo'),
                    child: const Text('Open picker'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open picker'));
    await tester.pump();
  }

  testWidgets('root dialog loads branches from the page-scoped view model', (
    tester,
  ) async {
    final pending = Completer<Result<List<GitBranch>, GitBranchError>>();
    git.load = () => pending.future;
    await open(tester);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    pending.complete(const Success([_main, _feature]));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('main'), findsOneWidget);
    expect(find.text('feature'), findsOneWidget);
    expect(git.roots, ['/repo']);
    await tester.enterText(find.byType(TextField).first, 'feat');
    await tester.pump();
    expect(find.text('main'), findsNothing);
    expect(find.text('feature'), findsOneWidget);
  });

  testWidgets('checkout uses the page view model and closes the dialog', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('feature'));
    await tester.pumpAndSettle();
    expect(git.checkedOut, 'feature');
    expect(git.roots, ['/repo', '/repo']);
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('create uses the page view model and closes the dialog', (
    tester,
  ) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'new-feature');
    await tester.tap(find.text('Create branch'));
    await tester.pumpAndSettle();
    expect(git.created, 'new-feature');
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final throwsException in [false, true]) {
    testWidgets(
      'loading stops on ${throwsException ? 'exception' : 'failure'}',
      (tester) async {
        git.load = () async {
          if (throwsException) throw Exception('git unavailable');
          return const Failure(
            GitBranchError(
              GitBranchErrorKind.listFailed,
              detail: 'git unavailable',
            ),
          );
        };
        await open(tester);
        await tester.pumpAndSettle();
        expect(find.byType(CircularProgressIndicator), findsNothing);
        expect(find.textContaining('Could not list branches:'), findsOneWidget);
        expect(find.textContaining('git unavailable'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('an unresponsive listing stops loading after the timeout', (
    tester,
  ) async {
    final pending = Completer<Result<List<GitBranch>, GitBranchError>>();
    git.load = () => pending.future;
    await open(tester);
    await tester.pump(const Duration(seconds: 16));
    await tester.pumpAndSettle();
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.textContaining('Could not list branches:'), findsOneWidget);
    pending.complete(const Success([_main]));
    await tester.pump();
    expect(find.text('main'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('closing during loading does not update a disposed dialog', (
    tester,
  ) async {
    final pending = Completer<Result<List<GitBranch>, GitBranchError>>();
    git.load = () => pending.future;
    await open(tester);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    pending.complete(const Success([_main]));
    await tester.pump();
    expect(find.byType(AlertDialog), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'manual refresh sees a branch created while the dialog was open',
    (tester) async {
      await open(tester);
      await tester.pumpAndSettle();
      git.load = () async => const Success([
        _main,
        _feature,
        GitBranch(name: 'added', isRemote: false, isCurrent: false),
      ]);
      await tester.tap(find.byKey(const ValueKey('branches-refresh')));
      await tester.pumpAndSettle();
      expect(find.text('added'), findsOneWidget);
      await tester.tap(find.text('added'));
      await tester.pumpAndSettle();
      expect(git.refreshed, ['/repo']);
    },
  );

  testWidgets('list follows external changes during polling', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    git.load = () async => const Success([_main]);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text('feature'), findsNothing);
    expect(find.text('main'), findsOneWidget);
  });

  testWidgets(
    'late results from another repository cannot replace the visible branches',
    (tester) async {
      final pending = Completer<Result<List<GitBranch>, GitBranchError>>();
      git.load = () => git.roots.last == '/first'
          ? pending.future
          : Future.value(const Success([_feature]));
      Widget panel(String root) => TranslationProvider(
        child: ShadcnApp(
          theme: buildTheme(brightness: Brightness.dark),
          home: Scaffold(
            child: SizedBox(
              width: 500,
              height: 550,
              child: GitBranchesPanel(root: root, git: git),
            ),
          ),
        ),
      );
      await tester.pumpWidget(panel('/first'));
      await tester.pump();
      await tester.pumpWidget(panel('/second'));
      await tester.pumpAndSettle();
      pending.complete(const Success([_main]));
      await tester.pumpAndSettle();
      expect(find.text('main'), findsNothing);
      expect(find.text('feature'), findsOneWidget);
    },
  );
  testWidgets('fetch errors stay visible while local refresh still works', (
    tester,
  ) async {
    git.fetchExit = 1;
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('branches-fetch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('remote unavailable'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.textContaining('remote unavailable'), findsOneWidget);
    expect(find.text('feature'), findsOneWidget);
    git.fetchExit = 0;
    await tester.tap(find.byKey(const ValueKey('branches-fetch')));
    await tester.pumpAndSettle();
    expect(find.textContaining('remote unavailable'), findsNothing);
  });

  testWidgets('creation uses the selected starting reference', (tester) async {
    await open(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('branch-start-point')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('feature').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'new-topic');
    await tester.tap(find.byKey(const ValueKey('branches-create')));
    await tester.pumpAndSettle();
    expect(git.createdFrom, 'refs/heads/feature');
    expect(git.created, 'new-topic');
    expect(git.refreshed, ['/repo']);
  });
}
