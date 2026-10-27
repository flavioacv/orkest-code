import 'package:orkest_code/app/core/terminal/pty_command_markers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('split markers are renderer and shell independent', () {
    final events = <String>[];
    final markers = PtyCommandMarkers(
      onStart: () => events.add('start'),
      onFinish: (code) => events.add('exit:$code'),
    );
    for (final char in 'text\x1b]133;C\x07output\x1b]133;D;1\x1b\\'.split('')) {
      markers.feed(char);
    }
    markers.feed('\x1b]633;C\x07\x1b]633;D;130\x07');
    expect(events, ['start', 'exit:1', 'start', 'exit:130']);
  });
  test(
    'plain text, unrelated OSC and unknown outcomes do not invent results',
    () {
      final events = <String>[];
      final markers = PtyCommandMarkers(
        onStart: () => events.add('start'),
        onFinish: (code) => events.add('exit:$code'),
      );
      markers.feed(
        'command failed\x1b]7;file:///tmp\x07\x1b]133;D\x07\x1b]133;D;no\x07\x1b]133;D;-1\x07',
      );
      markers.feed('\x1b]52;${'a' * 10000}');
      markers.feed('\x1b]133;C\x07\x1b]133;D;0\x07');
      expect(events, ['start', 'exit:0']);
    },
  );
}
