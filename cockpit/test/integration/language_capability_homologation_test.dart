import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_launchers.dart';
import 'package:orkest_code/app/core/domain/entities/language_capability_matrix.dart';

void main() {
  group('Language Capability Matrix & Tiers Homologation (L05)', () {
    test('enforces no duplicate language IDs across catalog', () {
      final ids = <String>{};
      for (final def in kLanguageDefs) {
        expect(ids.add(def.id), isTrue, reason: 'Duplicate language ID found: ${def.id}');
      }
      expect(kLanguageDefs.length, 20);
    });

    test('validates Tier 1 Core languages (Dart, TS, JS, Python, Go, Rust)', () {
      final tier1 = LanguageCapabilityMatrix.tier1Languages;
      expect(tier1.length, 6);

      final ids = tier1.map((l) => l.id).toSet();
      expect(ids, containsAll(['dart', 'typescript', 'javascript', 'python', 'go', 'rust']));

      for (final lang in tier1) {
        expect(lang.tier, LanguageTier.tier1Core);
        expect(lang.capabilities.lsp, isTrue);
        expect(lang.capabilities.debug, isTrue);
        expect(lang.capabilities.formatting, isTrue);
        expect(lang.capabilities.hover, isTrue);
        expect(lang.capabilities.completion, isTrue);
        expect(lang.capabilities.signatureHelp, isTrue);
        expect(lang.capabilities.semanticTokens, isTrue);
        expect(lang.server, isNotNull);
        expect(lang.debugger, isNotNull);
        expect(lang.sdk, isNotNull);
        expect(lang.markers, isNotEmpty);
      }

      // Verificação específica de servidores e adaptadores DAP de Tier 1
      final dartLang = languageById('dart')!;
      expect(dartLang.server!.executable, 'dart');
      expect(dartLang.debugger!.adapterId, 'dart');

      final tsLang = languageById('typescript')!;
      expect(tsLang.server!.executable, 'typescript-language-server');
      expect(tsLang.debugger!.adapterId, 'js-debug');

      final pyLang = languageById('python')!;
      expect(pyLang.server!.executable, 'pyright-langserver');
      expect(pyLang.debugger!.adapterId, 'debugpy');

      final goLang = languageById('go')!;
      expect(goLang.server!.executable, 'gopls');
      expect(goLang.debugger!.adapterId, 'delve');

      final rustLang = languageById('rust')!;
      expect(rustLang.server!.executable, 'rust-analyzer');
      expect(rustLang.debugger!.adapterId, 'codelldb');
    });

    test('validates Tier 2 Enterprise languages (Java, C#, PHP)', () {
      final tier2 = LanguageCapabilityMatrix.tier2Languages;
      expect(tier2.length, 3);

      final ids = tier2.map((l) => l.id).toSet();
      expect(ids, containsAll(['java', 'csharp', 'php']));

      final javaLang = languageById('java')!;
      expect(javaLang.tier, LanguageTier.tier2Enterprise);
      expect(javaLang.capabilities.lsp, isTrue);
      expect(javaLang.capabilities.debug, isTrue);
      expect(javaLang.server!.name, 'jdtls');
      expect(javaLang.debugger!.adapterId, 'java-debug');
      expect(javaLang.markers, contains('pom.xml'));

      final csharpLang = languageById('csharp')!;
      expect(csharpLang.tier, LanguageTier.tier2Enterprise);
      expect(csharpLang.capabilities.lsp, isTrue);
      expect(csharpLang.capabilities.debug, isTrue);
      expect(csharpLang.server!.name, 'csharp-ls');
      expect(csharpLang.debugger!.adapterId, 'netcoredbg');

      final phpLang = languageById('php')!;
      expect(phpLang.tier, LanguageTier.tier2Enterprise);
      expect(phpLang.capabilities.lsp, isTrue);
      // PHP declara debug falso transparentemente (sem prometer paridade falsa)
      expect(phpLang.capabilities.debug, isFalse);
      expect(phpLang.server!.name, 'intelephense');
      expect(phpLang.markers, contains('composer.json'));
    });

    test('validates Tier 3 Web, Data and On-Demand languages (SQL, Vue, Svelte, HTML, CSS, JSON, YAML, Shell)', () {
      final tier3 = LanguageCapabilityMatrix.tier3Languages;
      expect(tier3.length, 11);

      final ids = tier3.map((l) => l.id).toSet();
      expect(ids, containsAll([
        'sql',
        'vue',
        'svelte',
        'html',
        'css',
        'scss',
        'less',
        'json',
        'jsonc',
        'yaml',
        'shellscript',
      ]));

      // SQL sob demanda integrado ao Orkest
      final sql = languageById('sql')!;
      expect(sql.tier, LanguageTier.tier3WebData);
      expect(sql.extensions, contains('sql'));
      expect(sql.server!.executable, 'sql-language-server');
      expect(sql.capabilities.signatureHelp, isFalse);
      expect(sql.capabilities.debug, isFalse);
      expect(sql.lineComment, '--');

      // Vue sob demanda
      final vue = languageById('vue')!;
      expect(vue.tier, LanguageTier.tier3WebData);
      expect(vue.extensions, contains('vue'));
      expect(vue.server!.name, 'vue-language-server');
      expect(vue.markers, contains('nuxt.config.ts'));

      // Svelte sob demanda
      final svelte = languageById('svelte')!;
      expect(svelte.tier, LanguageTier.tier3WebData);
      expect(svelte.extensions, contains('svelte'));
      expect(svelte.server!.executable, 'svelteserver');
      expect(svelte.markers, contains('svelte.config.js'));

      // JSON / YAML não inventam assinatura de função nem debug
      final json = languageById('json')!;
      expect(json.capabilities.signatureHelp, isFalse);
      expect(json.capabilities.debug, isFalse);
      expect(json.capabilities.semanticTokens, isFalse);
    });

    test('resolves file paths correctly for synthetic fixtures and special filenames', () {
      final fixturesDir = Directory('test/fixtures/languages');
      if (fixturesDir.existsSync()) {
        final files = fixturesDir.listSync().whereType<File>();
        for (final file in files) {
          final resolved = languageForPath(file.path);
          expect(resolved, isNotNull, reason: 'Failed to resolve fixture ${file.path}');
        }
      }

      // Nomes de arquivos especiais
      expect(languageForPath('/project/tsconfig.json')?.id, 'jsonc');
      expect(languageForPath('/home/user/.bashrc')?.id, 'shellscript');
      expect(languageForPath('/app/.prettierrc')?.id, 'json');
      expect(languageForPath('/src/.clang-format')?.id, 'yaml');
      expect(languageForPath('/src/component.vue')?.id, 'vue');
      expect(languageForPath('/src/App.svelte')?.id, 'svelte');
      expect(languageForPath('/src/schema.sql')?.id, 'sql');
    });

    test('generates transparent capability matrix audit report without false parity', () {
      // Simula um ambiente onde apenas dart e python estão instalados
      final report = LanguageCapabilityMatrix.exportMatrix(
        executableChecker: (exec) => exec == 'dart' || exec == 'python' || exec == 'pyright-langserver',
      );

      expect(report['totalLanguages'], 20);
      expect(report['tier1Count'], 6);
      expect(report['tier2Count'], 3);
      expect(report['tier3Count'], 11);

      final languages = (report['languages'] as List).cast<Map<String, dynamic>>();

      final dartReport = languages.firstWhere((l) => l['id'] == 'dart');
      expect(dartReport['status'], LanguageSupportStatus.fullySupported.name);
      expect(dartReport['hasServer'], isTrue);
      expect(dartReport['hasDebugger'], isTrue);
      expect(dartReport['activeCapabilities'], contains('signatureHelp'));

      final pyReport = languages.firstWhere((l) => l['id'] == 'python');
      expect(pyReport['status'], LanguageSupportStatus.fullySupported.name);

      final rustReport = languages.firstWhere((l) => l['id'] == 'rust');
      expect(rustReport['status'], LanguageSupportStatus.missingServer.name);
      expect(rustReport['hasServer'], isFalse);

      final jsonReport = languages.firstWhere((l) => l['id'] == 'json');
      expect(jsonReport['unsupportedCapabilities'], contains('signatureHelp'));
      expect(jsonReport['unsupportedCapabilities'], contains('debug'));
    });
  });
}
