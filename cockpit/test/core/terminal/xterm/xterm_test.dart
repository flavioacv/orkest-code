import 'package:flutter_test/flutter_test.dart';

import 'package:orkest_code/app/core/terminal/xterm/xterm.dart';

void main() {
  test('Can instantiate Terminal', () {
    final terminal = Terminal(maxLines: 10000);
    terminal.write('hello');
  });
}
