import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, String> appearance(AppSettings settings, String id) =>
      settings.officeCharacterPartsForAgent(
        projectId: 'project',
        sessionId: id,
        legacyOwnerSessionId: 'julia',
      );

  test('editing one agent does not change a colleague in the same project', () {
    final settings = const AppSettings()
        .withOfficeCharacterPartsForAgent(
          projectId: 'project',
          sessionId: 'julia',
          legacyOwnerSessionId: 'julia',
          parts: {'top': '#ff0000'},
        )
        .withOfficeCharacterPartsForAgent(
          projectId: 'project',
          sessionId: 'carlos',
          legacyOwnerSessionId: 'julia',
          parts: {'top': '#0000ff'},
        );
    final restored = AppSettings.fromJson(settings.toJson());
    expect(appearance(restored, 'julia'), {'top': '#ff0000'});
    expect(appearance(restored, 'carlos'), {'top': '#0000ff'});
    expect(appearance(restored, 'new-agent'), isEmpty);
  });

  test('legacy project appearance belongs only to its oldest session', () {
    const original = AppSettings(
      officeCharacterParts: {
        'project': {'hair': '#123456'},
      },
    );
    expect(appearance(original, 'julia'), {'hair': '#123456'});
    expect(appearance(original, 'carlos'), isEmpty);
    final edited = original.withOfficeCharacterPartsForAgent(
      projectId: 'project',
      sessionId: 'carlos',
      legacyOwnerSessionId: 'julia',
      parts: {'top': '#abcdef'},
    );
    expect(appearance(edited, 'julia'), {'hair': '#123456'});
    expect(appearance(edited, 'carlos'), {'top': '#abcdef'});
    expect(edited.officeCharacterParts.containsKey('project'), isFalse);
    expect(original.officeCharacterParts['project'], {'hair': '#123456'});
  });

  test('resetting an agent preserves the other agent appearance', () {
    const original = AppSettings(
      officeCharacterParts: {
        'project': {'hair': '#123456'},
        'project:carlos': {'top': '#abcdef'},
      },
    );
    final reset = original.withOfficeCharacterPartsForAgent(
      projectId: 'project',
      sessionId: 'julia',
      legacyOwnerSessionId: 'julia',
      parts: {},
    );
    expect(appearance(reset, 'julia'), isEmpty);
    expect(appearance(reset, 'carlos'), {'top': '#abcdef'});
  });
}
