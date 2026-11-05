import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_launchers.dart';

void main() {
  group('languageForPath', () {
    test('preserves existing source language IDs', () {
      for (final entry in {
        'main.dart': 'dart',
        'app.tsx': 'typescript',
        'app.mjs': 'javascript',
        'main.pyi': 'python',
        'main.go': 'go',
        'main.rs': 'rust',
        'index.php': 'php',
        'App.cs': 'csharp',
        'App.java': 'java',
      }.entries) {
        expect(languageForPath(entry.key)?.id, entry.value);
      }
    });

    test('recognizes web, configuration and shell documents', () {
      for (final entry in {
        '/project/index.HTML': 'html',
        '/project/style.css': 'css',
        '/project/style.scss': 'scss',
        '/project/style.less': 'less',
        '/project/package.json': 'json',
        '/project/config.jsonc': 'jsonc',
        '/project/config.yml': 'yaml',
        '/project/config.yaml': 'yaml',
        '/project/build.sh': 'shellscript',
      }.entries) {
        expect(languageForPath(entry.key)?.id, entry.value, reason: entry.key);
      }
    });

    test('named files override the generic extension on either host style', () {
      for (final prefix in ['/project/', r'C:\project\', r'src\']) {
        expect(languageForPath('${prefix}tsconfig.json')?.id, 'jsonc');
        expect(languageForPath('$prefix.babelrc')?.id, 'jsonc');
        expect(languageForPath('$prefix.prettierrc')?.id, 'json');
        expect(languageForPath('$prefix.clang-format')?.id, 'yaml');
        expect(languageForPath('$prefix.bashrc')?.id, 'shellscript');
      }
    });

    test('a directory name is never mistaken for the document extension', () {
      for (final path in [
        '/project.ts/README',
        r'C:\project.ts\README',
        '/project.json/.unknown',
        r'C:\project.yaml\.unknown',
        '',
      ]) {
        expect(languageForPath(path), isNull, reason: path);
      }
    });
  });

  group('languageById', () {
    test('finds all 17 registered languages by exact ID', () {
      const ids = [
        'dart',
        'typescript',
        'javascript',
        'python',
        'go',
        'rust',
        'php',
        'csharp',
        'java',
        'html',
        'css',
        'scss',
        'less',
        'json',
        'jsonc',
        'yaml',
        'shellscript',
      ];
      expect(kLanguageDefs.length, ids.length);
      for (final id in ids) {
        final def = languageById(id);
        expect(def, isNotNull, reason: 'id: $id');
        expect(def!.id, id);
      }
      expect(languageById('unknown'), isNull);
    });
  });

  group('declarative metadata', () {
    test('separates LSP server, debug adapter, SDK and capabilities', () {
      final dartDef = languageById('dart')!;
      expect(dartDef.server?.name, 'dart');
      expect(dartDef.server?.executable, 'dart');
      expect(dartDef.debugger?.adapterId, 'dart');
      expect(dartDef.sdk?.name, contains('Dart'));
      expect(dartDef.capabilities.lsp, isTrue);
      expect(dartDef.capabilities.debug, isTrue);
      expect(dartDef.lineComment, '//');
      expect(dartDef.blockComment, ['/*', '*/']);

      final pyDef = languageById('python')!;
      expect(pyDef.server?.executable, 'pyright-langserver');
      expect(pyDef.debugger?.adapterId, 'debugpy');
      expect(pyDef.capabilities.debug, isTrue);
      expect(pyDef.lineComment, '#');

      final yamlDef = languageById('yaml')!;
      expect(yamlDef.server?.executable, 'yaml-language-server');
      expect(yamlDef.debugger, isNull);
      expect(yamlDef.capabilities.debug, isFalse);
    });

    test('toSpec preserves defaults and supports spaces in custom commandLine', () {
      final dartDef = languageById('dart')!;
      final defaultSpec = dartDef.toSpec();
      expect(defaultSpec.executable, 'dart');
      expect(defaultSpec.args, ['language-server', '--client-id', 'orkest']);

      // Caminho de executável com espaço e argumentos separados
      final customSpec = dartDef.toSpec(
        commandLine: '"/Volumes/Custom Disk/bin/dart" language-server --custom-flag',
      );
      expect(customSpec.executable, '/Volumes/Custom Disk/bin/dart');
      expect(customSpec.args, ['language-server', '--custom-flag']);

      // Executable override com espaços e sem args explícitos
      final singleStringSpec = dartDef.toSpec(
        executable: '"/Applications/Dart SDK/bin/dart" language-server',
      );
      expect(singleStringSpec.executable, '/Applications/Dart SDK/bin/dart');
      expect(singleStringSpec.args, ['language-server']);
    });
  });
}
