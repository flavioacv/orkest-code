import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/lsp/lsp_signature_help.dart';

void main() {
  test('selects the active overload and parameter documentation', () {
    expect(
      parseSignatureHelpText({
        'activeSignature': 1,
        'activeParameter': 1,
        'signatures': [
          {'label': 'other()'},
          {
            'label': 'call(first, second)',
            'documentation': {'kind': 'plaintext', 'value': 'Runs call.'},
            'parameters': [
              {'label': 'first'},
              {'label': 'second', 'documentation': 'Second argument.'},
            ],
          },
        ],
      }),
      'call(first, second)\n\nsecond: Second argument.\n\nRuns call.',
    );
  });
  test('signature-specific active parameter overrides the top-level value', () {
    expect(
      parseSignatureHelpText({
        'activeParameter': 1,
        'signatures': [
          {
            'label': 'f(a, b)',
            'activeParameter': 0,
            'parameters': [
              {'label': 'a'},
              {'label': 'b'},
            ],
          },
        ],
      }),
      'f(a, b)\n\na',
    );
  });
  test('parameter label offsets are UTF-16 and invalid ranges are ignored', () {
    const label = 'f(🚀, value)';
    final start = label.indexOf('value');
    expect(
      parseSignatureHelpText({
        'signatures': [
          {
            'label': label,
            'parameters': [
              {
                'label': [start, start + 5],
              },
            ],
          },
        ],
      }),
      '$label\n\nvalue',
    );
    expect(
      parseSignatureHelpText({
        'signatures': [
          {
            'label': label,
            'parameters': [
              {
                'label': [-1, 999],
              },
            ],
          },
        ],
      }),
      label,
    );
  });
  test('out of range overload falls back to the first signature', () {
    expect(
      parseSignatureHelpText({
        'activeSignature': 9,
        'signatures': [
          {'label': 'f()'},
        ],
      }),
      'f()',
    );
  });
  test('empty and malformed replies do not create an overlay', () {
    for (final value in [
      null,
      {},
      {'signatures': []},
      {
        'signatures': [null],
      },
      {
        'signatures': [
          {'label': ''},
        ],
      },
    ]) {
      expect(parseSignatureHelpText(value), isNull);
    }
  });
}
