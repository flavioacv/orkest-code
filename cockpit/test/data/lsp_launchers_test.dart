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
}
