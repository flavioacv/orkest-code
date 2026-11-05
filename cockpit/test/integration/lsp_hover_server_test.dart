import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_client_impl.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_hover.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_signature_help.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:path/path.dart' as p;

void main() {
  const executable = String.fromEnvironment('ORKEST_TEST_DART');
  test(
    'real Dart server returns hover and signature information through the client',
    () async {
      final root = Directory.systemTemp.createTempSync('orkest_hover_');
      final client = LspClientImpl(
        spec: const LspServerSpec(
          languageId: 'dart',
          executable: executable,
          args: ['language-server', '--client-id', 'orkest'],
        ),
        rootPath: root.path,
      );
      addTearDown(() async {
        await client.kill();
        client.dispose();
        root.deleteSync(recursive: true);
      });
      final file = File(p.join(root.path, 'main.dart'));
      const text = 'void main() {\n  int answer = 42;\n  print(answer);\n}\n';
      file.writeAsStringSync(text);
      final started = await client.start();
      expect(started.isSuccess, isTrue);
      await client.didOpen(path: file.path, text: text);
      final response = await client.request('textDocument/hover', {
        'textDocument': {'uri': file.uri.toString()},
        'position': {'line': 2, 'character': 9},
      });
      final info = response.fold(parseHoverText, (_) => null);
      expect(info, contains('answer'));
      expect(info, contains('int'));
      final signature = await client.request('textDocument/signatureHelp', {
        'textDocument': {'uri': file.uri.toString()},
        'position': {'line': 2, 'character': 9},
      });
      final parameters = signature.fold(parseSignatureHelpText, (_) => null);
      expect(parameters, contains('print('));
      expect(parameters, contains('object'));
    },
    skip: executable.isEmpty
        ? 'Set ORKEST_TEST_DART with --dart-define to run a real server.'
        : false,
  );
}
