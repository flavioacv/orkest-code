import 'dart:io';

import 'package:orkest_code/app/orkest/data/remote/host_shell/host_shell.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;

  setUp(() {
    root = Directory.systemTemp.createTempSync('orkest-client-bundle');
    Directory('${root.path}/bin').createSync();
    Directory('${root.path}/lib').createSync();
  });

  tearDown(() => root.deleteSync(recursive: true));

  File put(String relative, String contents) {
    final file = File('${root.path}/$relative')..writeAsStringSync(contents);
    return file;
  }

  test(
    'manifesto é determinístico e cobre todos os arquivos implantados',
    () async {
      final server = put('bin/orkest-server-arm64', 'server');
      put('bin/orkest', 'cli');
      put('lib/liborkest_pty.so', 'pty');
      put('lib/libanaki_sqlite.so', 'sqlite');
      final bundle = ClientBundle(root: root.path, serverBinary: server.path);

      final first = await bundle.buildManifest();
      final second = await bundle.buildManifest();

      expect(second.digest, first.digest);
      expect(second.contents, first.contents);
      expect(
        first.files.map((file) => file.remotePath),
        orderedEquals([
          'bin/orkest',
          'bin/orkest-server',
          'lib/libanaki_sqlite.so',
          'lib/liborkest_pty.so',
        ]),
      );
      expect(first.contents, contains('  bin/orkest-server\n'));
      expect(first.contents, contains('  lib/liborkest_pty.so\n'));
    },
  );

  test('mudança só na CLI ou só numa lib muda o digest do bundle', () async {
    final server = put('bin/orkest-server', 'same-server');
    final cli = put('bin/orkest', 'cli-v1');
    final pty = put('lib/liborkest_pty.so', 'pty-v1');
    final bundle = ClientBundle(root: root.path, serverBinary: server.path);

    final original = (await bundle.buildManifest()).digest;
    cli.writeAsStringSync('cli-v2');
    final cliChanged = (await bundle.buildManifest()).digest;
    expect(cliChanged, isNot(original));

    cli.writeAsStringSync('cli-v1');
    pty.writeAsStringSync('pty-v2');
    final ptyChanged = (await bundle.buildManifest()).digest;
    expect(ptyChanged, isNot(original));
  });
}
