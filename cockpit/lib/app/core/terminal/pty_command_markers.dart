// Shell lifecycle metadata, independent of renderer, shell and harness. Never
// retains command text. OSC 133 (FinalTerm) and OSC 633 share C/D markers.
class PtyCommandMarkers {
  PtyCommandMarkers({required this.onStart, required this.onFinish});
  final void Function() onStart;
  final void Function(int exitCode) onFinish;
  String _pending = '';

  void feed(String chunk) {
    final text = _pending + chunk;
    _pending = '';
    var cursor = 0;
    while (cursor < text.length) {
      final start = text.indexOf('\x1b]', cursor);
      if (start < 0) {
        if (text.endsWith('\x1b')) _pending = '\x1b';
        return;
      }
      var end = start + 2;
      while (end < text.length &&
          text.codeUnitAt(end) != 7 &&
          !(text.codeUnitAt(end) == 27 &&
              end + 1 < text.length &&
              text[end + 1] == '\\')) {
        end++;
      }
      if (end >= text.length) {
        if (text.length - start <= 96) _pending = text.substring(start);
        return;
      }
      final parts = text.substring(start + 2, end).split(';');
      if (parts.length >= 2 && (parts[0] == '133' || parts[0] == '633')) {
        if (parts[1] == 'C' && parts.length == 2) onStart();
        if (parts[1] == 'D' && parts.length >= 3) {
          final code = int.tryParse(parts[2]);
          if (code != null && code >= 0 && code <= 255) onFinish(code);
        }
      }
      cursor = end + (text.codeUnitAt(end) == 7 ? 1 : 2);
    }
  }
}
