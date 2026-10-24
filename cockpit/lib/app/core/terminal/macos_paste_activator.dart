import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

// macOS dictation tools can post V with the Command event flag without
// posting a physical Command key. HardwareKeyboard then reports no Meta key,
// while RawKeyboard retains the modifiers from the native NSEvent. Keep this
// compatibility boundary local until Flutter preserves those flags in KeyEvent.
// ignore_for_file: deprecated_member_use

class MacOsSyntheticPasteActivator extends SingleActivator {
  const MacOsSyntheticPasteActivator()
    : super(LogicalKeyboardKey.keyV, meta: true, includeRepeats: false);

  @override
  bool accepts(KeyEvent event, HardwareKeyboard state) {
    if (defaultTargetPlatform != TargetPlatform.macOS ||
        state.isMetaPressed ||
        event is! KeyDownEvent ||
        event.logicalKey != LogicalKeyboardKey.keyV) {
      return false;
    }
    final nativeKeys = RawKeyboard.instance.keysPressed;
    return nativeKeys.contains(LogicalKeyboardKey.keyV) &&
        (nativeKeys.contains(LogicalKeyboardKey.metaLeft) ||
            nativeKeys.contains(LogicalKeyboardKey.metaRight)) &&
        !nativeKeys.any(_otherModifierKeys.contains);
  }

  static const _otherModifierKeys = [
    LogicalKeyboardKey.controlLeft,
    LogicalKeyboardKey.controlRight,
    LogicalKeyboardKey.altLeft,
    LogicalKeyboardKey.altRight,
    LogicalKeyboardKey.shiftLeft,
    LogicalKeyboardKey.shiftRight,
  ];
}
