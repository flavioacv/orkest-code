import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/editor_productivity.dart';
import 'package:orkest_code/app/core/domain/services/editor_productivity_service.dart';

void main() {
  group('ProductivityInventoryRegistry & Capabilities (X01)', () {
    test('contains comprehensive catalog of all 8+ productivity categories', () {
      final capabilities = ProductivityInventoryRegistry.capabilities;
      expect(capabilities, isNotEmpty);

      final categories = capabilities.map((c) => c.category).toSet();
      expect(categories, contains(ProductivityCategory.snippets));
      expect(categories, contains(ProductivityCategory.templates));
      expect(categories, contains(ProductivityCategory.emmet));
      expect(categories, contains(ProductivityCategory.folding));
      expect(categories, contains(ProductivityCategory.bookmarks));
      expect(categories, contains(ProductivityCategory.todo));
      expect(categories, contains(ProductivityCategory.vim));
      expect(categories, contains(ProductivityCategory.macros));
      expect(categories, contains(ProductivityCategory.colorPreview));
      expect(categories, contains(ProductivityCategory.scratchFiles));
    });

    test('partitions deliveries by usage tiers and ensures accessibility labels', () {
      final tier1 = ProductivityInventoryRegistry.byUsageTier(1);
      final tier2 = ProductivityInventoryRegistry.byUsageTier(2);
      final tier3 = ProductivityInventoryRegistry.byUsageTier(3);

      expect(tier1, isNotEmpty);
      expect(tier2, isNotEmpty);
      expect(tier3, isNotEmpty);

      // Toda capacidade deve ter rótulo acessível explícito
      for (final cap in ProductivityInventoryRegistry.capabilities) {
        expect(cap.accessibilityLabel, isNotNull);
        expect(cap.accessibilityLabel!.isNotEmpty, isTrue);
      }
    });
  });

  group('EmmetAbbreviationService (X01)', () {
    const emmet = EmmetAbbreviationService();

    test('expands simple tags, IDs and classes', () {
      final res = emmet.expand('div.container#main');
      expect(res, equals('<div id="main" class="container"></div>'));
    });

    test('expands nested hierarchy and siblings with indentation', () {
      final res = emmet.expand('nav>ul>li');
      expect(
        res,
        equals(
          '<nav>\n'
          '  <ul>\n'
          '    <li></li>\n'
          '  </ul>\n'
          '</nav>',
        ),
      );
    });

    test('expands multiplication and text content', () {
      final res = emmet.expand('ul>li*3{Item}');
      expect(
        res,
        equals(
          '<ul>\n'
          '  <li>Item</li>\n'
          '  <li>Item</li>\n'
          '  <li>Item</li>\n'
          '</ul>',
        ),
      );
    });

    test('handles self closing tags and custom attributes', () {
      final res = emmet.expand('input[type="email" required]');
      expect(res, equals('<input type="email" required />'));
    });
  });

  group('CodeFoldingService (X01)', () {
    const folding = CodeFoldingService();

    test('detects code blocks spanning multiple lines', () {
      const code = '''
void main() {
  final list = [1, 2, 3];
  for (final item in list) {
    print(item);
  }
}
''';

      final ranges = folding.computeFoldingRanges(code);
      expect(ranges.length, greaterThanOrEqualTo(2));
      expect(ranges[0].kind, equals(FoldingKind.block));
      expect(ranges[0].startLine, equals(1));
      expect(ranges[0].endLine, equals(6));
    });

    test('detects multiline comments and custom region folds', () {
      const code = '''
/*
 * Header comment block
 */
// #region Business Logic
void process() {}
// #endregion
''';

      final ranges = folding.computeFoldingRanges(code);
      expect(ranges.length, equals(2));
      expect(ranges[0].kind, equals(FoldingKind.comment));
      expect(ranges[0].startLine, equals(1));
      expect(ranges[0].endLine, equals(3));

      expect(ranges[1].kind, equals(FoldingKind.region));
      expect(ranges[1].startLine, equals(4));
      expect(ranges[1].endLine, equals(6));
      expect(ranges[1].placeholder, equals('Business Logic'));
    });
  });

  group('TodoScanningService (X01)', () {
    const scanner = TodoScanningService();

    test('extracts TODO, FIXME, BUG and NOTE annotations with severities', () {
      const source = '''
// TODO: Implement user authentication flow
final token = null;
/* FIXME: Handle null pointer when token is absent */
# BUG: Memory leak observed under stress test
<!-- NOTE: Keep accessibility labels up to date -->
''';

      final items = scanner.scan(source, filePath: 'lib/auth.dart');
      expect(items.length, equals(4));

      expect(items[0].tag, equals('TODO'));
      expect(items[0].severity, equals(TodoSeverity.warning));
      expect(items[0].message, equals('Implement user authentication flow'));

      expect(items[1].tag, equals('FIXME'));
      expect(items[1].severity, equals(TodoSeverity.error));

      expect(items[2].tag, equals('BUG'));
      expect(items[2].severity, equals(TodoSeverity.error));

      expect(items[3].tag, equals('NOTE'));
      expect(items[3].severity, equals(TodoSeverity.info));
    });
  });

  group('ColorPreviewService & WCAG Contrast (X01)', () {
    const colorService = ColorPreviewService();

    test('detects hex, rgb, rgba and Flutter Color literals', () {
      const code = '''
const primary = #FF0055;
const semi = #00FF0088;
final bg = Color(0xFF1E1E2E);
final active = rgba(255, 128, 0, 0.8);
''';

      final matches = colorService.findColorMatches(code);
      expect(matches.length, equals(4));

      expect(matches[0].format, equals(ColorSyntaxFormat.hex6));
      expect(matches[0].red, equals(0xFF));
      expect(matches[0].green, equals(0x00));
      expect(matches[0].blue, equals(0x55));

      expect(matches[1].format, equals(ColorSyntaxFormat.hex8));
      expect(matches[2].format, equals(ColorSyntaxFormat.flutterColor));
      expect(matches[3].format, equals(ColorSyntaxFormat.rgba));
    });

    test('calculates relative luminance and WCAG compliant foreground text recommendation', () {
      // Branco puro (#FFFFFF) -> luminância 1.0 -> texto escuro (prefersLightForeground == false)
      final white = colorService.findColorMatches('const c = #FFFFFF;').first;
      expect(white.relativeLuminance, closeTo(1.0, 0.01));
      expect(white.prefersLightForeground, isFalse);

      // Preto puro (#000000) -> luminância 0.0 -> texto claro (prefersLightForeground == true)
      final black = colorService.findColorMatches('const c = #000000;').first;
      expect(black.relativeLuminance, closeTo(0.0, 0.01));
      expect(black.prefersLightForeground, isTrue);

      // Roxo escuro (#1E1E2E) -> luminância baixa -> texto claro
      final darkPurple = colorService.findColorMatches('const c = #1E1E2E;').first;
      expect(darkPurple.prefersLightForeground, isTrue);
    });
  });

  group('EditorBookmarkService (X01)', () {
    test('toggles, navigates and finds bookmarks by mnemonic', () {
      final service = EditorBookmarkService();

      service.toggleBookmark(filePath: 'lib/main.dart', line: 10, mnemonic: '1');
      service.toggleBookmark(filePath: 'lib/main.dart', line: 50, mnemonic: '2');
      service.toggleBookmark(filePath: 'lib/utils.dart', line: 25);

      expect(service.bookmarks.length, equals(3));

      // Teste de navegação forward
      final next = service.nextBookmark(currentFile: 'lib/main.dart', currentLine: 10);
      expect(next?.line, equals(50));

      // Teste de busca por mnemônico
      final b1 = service.getBookmarkByMnemonic('1');
      expect(b1?.filePath, equals('lib/main.dart'));
      expect(b1?.line, equals(10));

      // Alternar linha existente remove marcador
      service.toggleBookmark(filePath: 'lib/main.dart', line: 10);
      expect(service.bookmarks.length, equals(2));
      expect(service.getBookmarkByMnemonic('1'), isNull);
    });
  });

  group('EditorMacroService & VimStateController (X01)', () {
    test('records and replays keyboard macros', () {
      final macroService = EditorMacroService();
      macroService.startRecording();
      expect(macroService.isRecording, isTrue);

      macroService.recordAction('insertText', 'const x = ');
      macroService.recordAction('insertText', '42;');
      final macro = macroService.stopRecording(name: 'assignNumber');

      expect(macroService.isRecording, isFalse);
      expect(macro?.length, equals(2));

      final played = <String>[];
      macroService.playMacro(
        'assignNumber',
        times: 2,
        onExecuteAction: (action) => played.add(action.payload),
      );

      expect(played.length, equals(4));
      expect(played, equals(['const x = ', '42;', 'const x = ', '42;']));
    });

    test('manages Vim modal transitions and common command execution', () {
      final vim = VimStateController();
      expect(vim.currentMode, equals(VimMode.normal));

      // Entrar em modo insert
      expect(vim.processKey('i'), equals('setMode:insert'));
      expect(vim.currentMode, equals(VimMode.insert));

      // Voltar com Escape
      expect(vim.processKey('', isEscape: true), equals('setMode:normal'));
      expect(vim.currentMode, equals(VimMode.normal));

      // Movimentos normais
      expect(vim.processKey('h'), equals('move:h'));
      expect(vim.processKey('j'), equals('move:j'));

      // Modo de comando :w
      expect(vim.processKey(':'), equals('setMode:command'));
      expect(vim.currentMode, equals(VimMode.command));
      vim.processKey('w');
      expect(vim.processKey('', isEnter: true), equals('command:save'));
      expect(vim.currentMode, equals(VimMode.normal));
    });
  });
}
