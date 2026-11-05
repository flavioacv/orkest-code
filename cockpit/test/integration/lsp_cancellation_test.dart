import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_client_impl.dart';
import 'package:orkest_code/app/core/domain/contracts/lsp_client.dart';
import 'package:path/path.dart' as p;

void main() {
  const executable = String.fromEnvironment('ORKEST_TEST_DART');
  group(
    'LSP stdio cancellation',
    () {
      late LspClientImpl client;
      late Directory root;
      late String path;
      Map<String, dynamic> params(String file) => {
        'textDocument': {'uri': Uri.file(file).toString()},
        'position': {'line': 0, 'character': 0},
      };
      Future<List<dynamic>> observed() async => (await client.request(
        'test/observed',
        {},
      )).fold((value) => value as List, (error) => throw StateError('$error'));

      setUp(() async {
        root = Directory.systemTemp.createTempSync('orkest_cancel_');
        path = p.join(root.path, 'main.dart');
        final fixture = p.absolute(
          'test/fixtures/lsp_cancellation_server.dart',
        );
        client = LspClientImpl(
          spec: LspServerSpec(
            languageId: 'dart',
            executable: executable,
            args: [fixture],
          ),
          rootPath: root.path,
        );
        expect((await client.start()).isSuccess, isTrue);
        await client.didOpen(path: path, text: 'initial');
      });
      tearDown(() async {
        await client.kill();
        client.dispose();
        root.deleteSync(recursive: true);
      });

      test('edit cancels obsolete reads only in the edited document', () async {
        const methods = [
          'textDocument/hover',
          'textDocument/completion',
          'textDocument/signatureHelp',
          'textDocument/semanticTokens/full',
          'textDocument/definition',
        ];
        final reads = [
          for (final method in methods) client.request(method, params(path)),
        ];
        final other = client.request(
          'textDocument/hover',
          params(p.join(root.path, 'other.dart')),
        );
        final formatting = client.request(
          'textDocument/formatting',
          params(path),
        );
        await client.didChange(path: path, text: 'changed', version: 2);
        for (final result in await Future.wait(reads)) {
          expect(
            result.fold((_) => '', (error) => error.message),
            contains('cancelled'),
          );
        }
        final wire = await observed();
        final cancelled = wire
            .where((m) => m['method'] == r'$/cancelRequest')
            .toList();
        expect(cancelled, hasLength(5));
        final ids = wire
            .where(
              (m) =>
                  methods.contains(m['method']) &&
                  m['params']['textDocument']['uri'] ==
                      Uri.file(path).toString(),
            )
            .map((m) => m['id'])
            .toSet();
        expect(cancelled.map((m) => m['params']['id']).toSet(), ids);
        expect(
          wire.indexOf(cancelled.last),
          lessThan(
            wire.indexWhere((m) => m['method'] == 'textDocument/didChange'),
          ),
        );
        await client.request('test/release', {});
        expect((await other).isSuccess, isTrue);
        expect((await formatting).isSuccess, isTrue);
      });

      test('new query cancels only the same method and URI', () async {
        final first = client.request('textDocument/completion', params(path));
        final hover = client.request('textDocument/hover', params(path));
        final second = client.request('textDocument/completion', params(path));
        expect((await first).isFailure, isTrue);
        expect(
          (await observed()).where((m) => m['method'] == r'$/cancelRequest'),
          hasLength(1),
        );
        await client.request('test/release', {});
        expect((await second).fold((value) => value, (_) => null), 'fresh');
        expect((await hover).isSuccess, isTrue);
      });

      test('close cancels outstanding reads', () async {
        final read = client.request('textDocument/signatureHelp', params(path));
        await client.didClose(path: path);
        expect((await read).isFailure, isTrue);
        final wire = await observed();
        expect(
          wire.where((m) => m['method'] == r'$/cancelRequest'),
          hasLength(1),
        );
        await client.didOpen(path: path, text: 'new');
        final current = client.request('textDocument/hover', params(path));
        await client.request('test/release', {});
        expect((await current).isSuccess, isTrue);
      });

      test('timeout notifies the server and discards its late reply', () async {
        final read = await client.request('textDocument/hover', params(path));
        expect(
          read.fold((_) => '', (error) => error.message),
          contains('Timed out'),
        );
        final wire = await observed();
        expect(
          wire.where((m) => m['method'] == r'$/cancelRequest'),
          hasLength(1),
        );
        final current = client.request('textDocument/hover', params(path));
        await client.request('test/release', {});
        expect((await current).isSuccess, isTrue);
      });
    },
    skip: executable.isEmpty
        ? 'Set ORKEST_TEST_DART to run stdio integration.'
        : false,
  );
}
