import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cockpit/app/cockpit/domain/entities/project.dart';
import 'package:cockpit/app/cockpit/ui/session/terminal_session.dart';
import 'package:cockpit/app/cockpit/ui/widgets/office_agent_profile_dialog.dart';
import 'package:cockpit/app/core/ui/themes/app_theme.dart';
import 'package:cockpit/app/core/domain/entities/harness.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;

class _Session extends Fake implements TerminalSession {
  @override
  String get id => 'julia';
  @override
  String get projectId => 'project';
  @override
  String get title => 'Julia';
  @override
  String? get manualLabel => null;
  @override
  HarnessKind? get activeHarness => null;
  @override
  TerminalStatus get status => TerminalStatus.idle;
  @override
  DateTime get createdAt => DateTime(2026);
  @override
  String get workingDirectory => '/tmp';
  @override
  String? get currentDirectory => null;
  @override
  List<TerminalStatusEvent> get officeStatusHistory => const [];
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  testWidgets(
    'saving appearance updates the open profile and the next editor',
    (tester) async {
      tester.view.reset();
      tester.view.physicalSize = const Size(1600, 1200);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = _Session();
      final before = File('assets/branding/cockpit_logo.png').readAsBytesSync();
      final png = 'data:image/png;base64,${base64Encode(before)}';
      final after = Uint8List.fromList(before);
      final drafts = <Map<String, String>>[];
      Map<String, String>? saved;
      await tester.pumpWidget(
        TranslationProvider(
          child: shad.ShadcnApp(
            theme: buildTheme(brightness: Brightness.dark),
            home: shad.Scaffold(
              child: Builder(
                builder: (context) => shad.PrimaryButton(
                  child: const Text('Open profile'),
                  onPressed: () => showOfficeAgentProfile(
                    context,
                    session: session,
                    project: Project(
                      id: 'project',
                      name: 'Project',
                      path: '/tmp',
                      colorValue: 0,
                      createdAt: DateTime(2026),
                    ),
                    onOpenTerminal: () {},
                    onRename: (_) {},
                    portraitBytes: before,
                    initialAppearance: const {'top': '#0000ff'},
                    loadPortrait: () async => after,
                    loadAppearance: (parts) async {
                      drafts.add(Map.of(parts));
                      return {
                        'parts': {'top': '#ff0000'},
                        'options': {},
                        'preview': png,
                      };
                    },
                    onSaveAppearance: (parts) => saved = Map.of(parts),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Open profile'));
      await tester.pumpAndSettle();
      expect(
        (tester.widget<Image>(find.byType(Image).first).image as MemoryImage)
            .bytes,
        same(before),
      );
      await tester.tap(find.text(t.cockpit.officeWorld.editAppearance));
      await tester.pumpAndSettle();
      await tester.tap(find.text(t.common.save));
      await tester.pumpAndSettle();
      expect(saved, {'top': '#ff0000'});
      expect(
        (tester.widget<Image>(find.byType(Image).first).image as MemoryImage)
            .bytes,
        same(after),
      );
      await tester.tap(find.text(t.cockpit.officeWorld.editAppearance));
      await tester.pumpAndSettle();
      expect(drafts.last, {'top': '#ff0000'});
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
