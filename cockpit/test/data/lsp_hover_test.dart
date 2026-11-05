import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_hover.dart';

void main() {
  test('accepts plain text and MarkupContent', () {
    expect(parseHoverText({'contents': '  Symbol  '}), 'Symbol');
    expect(
      parseHoverText({
        'contents': {'kind': 'markdown', 'value': '**Type**'},
      }),
      '**Type**',
    );
  });
  test('joins legacy MarkedStrings and skips malformed entries', () {
    expect(
      parseHoverText({
        'contents': [
          {'language': 'dart', 'value': 'int value'},
          'Description',
          null,
          {'value': 42},
          '',
        ],
      }),
      'int value\n\nDescription',
    );
  });
  test('empty or invalid replies do not produce tooltips', () {
    for (final value in [
      null,
      42,
      {},
      {'contents': []},
      {
        'contents': {'value': ' '},
      },
    ]) {
      expect(parseHoverText(value), isNull);
    }
  });
}
