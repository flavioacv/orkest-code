import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_text_edit.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_completion.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_semantic_tokens.dart';
import 'package:orkest_code/app/core/domain/result.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/orkest/domain/contracts/git_history_reader.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_view.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_blame_hunk.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_comparison.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_commit.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_file_change.dart';
import 'package:orkest_code/app/orkest/domain/entities/git_history_query.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/git_history_error.dart';
import 'package:orkest_code/app/orkest/ui/session/file_viewer_session.dart';
import 'package:orkest_code/app/orkest/ui/session/document_host.dart';
import 'package:orkest_code/app/orkest/ui/widgets/file_viewer.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' hide Scaffold, TextField;

class FakeGitHistoryReader implements GitHistoryReader {
  FakeGitHistoryReader({this.blameResult});

  Result<List<GitBlameHunk>, GitHistoryError>? blameResult;
  String? lastRepoPath;
  String? lastFilePath;

  @override
  Future<Result<List<GitBlameHunk>, GitHistoryError>> readBlame(
    String repoPath,
    String filePath, {
    int? lineStart,
    int? lineEnd,
  }) async {
    lastRepoPath = repoPath;
    lastFilePath = filePath;
    return blameResult ??
        Success(const <GitBlameHunk>[]);
  }

  @override
  Future<Result<List<GitHistoryCommit>, GitHistoryError>> read(
    String repoPath, {
    int limit = 100,
    int skip = 0,
    GitHistoryQuery? query,
  }) async =>
      Success(const <GitHistoryCommit>[]);

  @override
  Future<Result<List<GitHistoryFileChange>, GitHistoryError>> readFiles(
    String repoPath,
    String commitHash,
  ) async =>
      Success(const <GitHistoryFileChange>[]);

  @override
  Future<Result<GitComparison, GitHistoryError>> compareRefs(
    String repoPath,
    String baseRef,
    String targetRef,
  ) async =>
      Failure(
        GitHistoryError(
          GitHistoryErrorKind.commandFailed,
          detail: 'unsupported in fake',
        ),
      );
}

class FakeDocumentHost implements DocumentHost {
  @override
  String displayPath(String projectId, String path) => path;

  @override
  void ensureScmCoordinator(FileViewerSession session) {}

  @override
  Stream<LspDiagnosticsBatch> get lspDiagnostics => const Stream.empty();

  @override
  Future<void> lspOpenDocument(String path, String text, String projectId) async {}

  @override
  Future<void> lspChangeDocument(String path, String text) async {}

  @override
  Future<void> lspCloseDocument(String path) async {}

  @override
  void lspCancelRequest(String path, String method) {}

  @override
  Future<SemanticTokens> lspSemanticTokensFull(String path) async =>
      const SemanticTokens(tokens: []);

  @override
  Future<String?> lspHover(String path, String text, int line, int character) async => null;

  @override
  Future<String?> lspSignatureHelp(String path, String text, int line, int character) async => null;

  @override
  Future<List<LspCompletionItem>> lspCompletions(String path, String text, int line, int character) async => const [];

  @override
  Future<LspCompletionItem?> lspResolveCompletion(String path, LspCompletionItem item) async => null;

  @override
  Future<void> goToDefinition(String path, int line, int character) async {}

  @override
  Future<List<LspTextEdit>> lspFormat(String path, String text) async => const [];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWithTheme({required Widget child}) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: DocumentHostScope(
          host: FakeDocumentHost(),
          child: Scaffold(
            body: SizedBox(width: 900, height: 700, child: child),
          ),
        ),
      ),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late File sampleFile;

  setUp(() {
    LocaleSettings.setLocale(AppLocale.en);
    tempDir = Directory.systemTemp.createTempSync('orkest_blame_test_');
    Directory('${tempDir.path}/.git').createSync();
    sampleFile = File('${tempDir.path}/main.dart');
    sampleFile.writeAsStringSync('void main() {\n  print("hello");\n}\n');
  });

  tearDown(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('FileViewer exibe botao Blame na toolbar e alterna painel GitBlameView', (tester) async {
    final hunks = [
      GitBlameHunk(
        commitHash: 'abcdef1234567890abcdef1234567890abcdef12',
        author: 'Linus Torvalds',
        authorEmail: 'linus@kernel.org',
        authorTime: DateTime(2026, 1, 1),
        summary: 'initial commit with hello world',
        originalLine: 1,
        finalLine: 1,
        lineCount: 3,
        lines: const ['void main() {', '  print("hello");', '}'],
      ),
    ];

    final fakeReader = FakeGitHistoryReader(blameResult: Success(hunks));
    final session = FileViewerSession(
      id: 'tab-test-1',
      projectId: tempDir.path,
      path: sampleFile.path,
      view: FileViewText(
        sampleFile.readAsStringSync(),
        language: 'dart',
      ),
    );

    await tester.pumpWidget(
      _wrapWithTheme(
        child: FileViewer(
          session: session,
          onSave: (_) async => true,
          gitHistoryReader: fakeReader,
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verifica se o botão "Blame" está presente na toolbar
    expect(find.text('Blame'), findsOneWidget);
    expect(find.text('Linus Torvalds'), findsNothing);

    // 2. Clica no botão Blame para abrir o painel lateral
    await tester.tap(find.text('Blame'));
    await tester.pumpAndSettle();

    // 3. Verifica se o leitor foi chamado e os hunks renderizados no GitBlameView
    expect(fakeReader.lastRepoPath, equals(tempDir.path));
    expect(fakeReader.lastFilePath, equals('main.dart'));
    expect(find.text('Linus Torvalds'), findsOneWidget);
    expect(find.text('initial commit with hello world'), findsOneWidget);
    expect(find.text('L1-3'), findsOneWidget);
    expect(find.text('abcdef12'), findsOneWidget);

    // 4. Clica na linha para disparar reveal
    await tester.tap(find.text('L1-3'));
    await tester.pump();
    expect(session.revealLine, equals(1));
    expect(session.revealSelect, isTrue);

    // 5. Clica no botão fechar (x) do painel de Blame
    final closeButtonFinder = find.byIcon(LucideIcons.x);
    expect(closeButtonFinder, findsOneWidget);
    await tester.tap(closeButtonFinder);
    await tester.pumpAndSettle();

    // 6. Confirma que o painel lateral foi fechado
    expect(find.text('Linus Torvalds'), findsNothing);
  });
}
