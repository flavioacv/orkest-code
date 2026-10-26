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
    String name,
  ) async {
    roots.add(root);
    created = name;
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
}
