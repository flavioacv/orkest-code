// The regression requires the native event modifiers, which KeyEvent omits.
// ignore_for_file: deprecated_member_use
import 'package:cockpit/app/core/terminal/macos_paste_activator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const activator = MacOsSyntheticPasteActivator();
  const down = KeyDownEvent(
    physicalKey: PhysicalKeyboardKey.keyV,
    logicalKey: LogicalKeyboardKey.keyV,
    timeStamp: Duration.zero,
  );

  void nativeV(int modifiers) {
    RawKeyboard.instance.handleRawKeyEvent(
      RawKeyDownEvent(
        data: RawKeyEventDataMacOs(
          keyCode: 9,
          characters: 'v',
          charactersIgnoringModifiers: 'v',
          modifiers: modifiers,
        ),
      ),
    );
  }

  setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.macOS);
  tearDown(() {
    RawKeyboard.instance.clearKeysPressed();
    debugDefaultTargetPlatformOverride = null;
  });

  test('accepts native Command+V without a physical Command press', () {
    nativeV(RawKeyEventDataMacOs.modifierCommand);
    expect(HardwareKeyboard.instance.isMetaPressed, isFalse);
    expect(activator.accepts(down, HardwareKeyboard.instance), isTrue);
    expect(
      activator.accepts(
        const KeyUpEvent(
          physicalKey: PhysicalKeyboardKey.keyV,
          logicalKey: LogicalKeyboardKey.keyV,
          timeStamp: Duration.zero,
        ),
        HardwareKeyboard.instance,
      ),
      isFalse,
    );
  });

  test('plain V and other Command chords do not trigger a paste', () {
    nativeV(0);
    expect(activator.accepts(down, HardwareKeyboard.instance), isFalse);
    nativeV(
      RawKeyEventDataMacOs.modifierCommand | RawKeyEventDataMacOs.modifierShift,
    );
    expect(activator.accepts(down, HardwareKeyboard.instance), isFalse);
  });

  test('native modifier fallback is restricted to macOS', () {
    nativeV(RawKeyEventDataMacOs.modifierCommand);
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    expect(activator.accepts(down, HardwareKeyboard.instance), isFalse);
  });
}
