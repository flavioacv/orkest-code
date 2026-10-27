import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shad;
import 'package:orkest_code/app/core/ui/themes/app_theme.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_workspace_window.dart';

void main() {
  testWidgets('move, resize, maximize and restore preserve content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final controller = TextEditingController(text: 'draft');
    addTearDown(controller.dispose);
    var closed = false;
    await tester.pumpWidget(
      shad.ShadcnApp(
        theme: buildTheme(brightness: Brightness.dark),
        home: Stack(
          children: [
            OfficeWorkspaceWindow(
              title: 'README.md',
              projectName: 'Project',
              onClose: () => closed = true,
              child: shad.TextField(controller: controller),
            ),
          ],
        ),
      ),
    );
    final frame = find.byKey(const ValueKey('office-workspace-frame'));
    final title = find.byKey(const ValueKey('office-workspace-titlebar'));
    final maximize = find.byKey(const ValueKey('office-workspace-maximize'));
    final original = tester.getRect(frame);
    await tester.drag(title, const Offset(30, 20));
    await tester.pump();
    final moved = tester.getRect(frame);
    expect(moved.left, greaterThan(original.left));
    expect(moved.top, greaterThan(original.top));
    await tester.drag(
      find.byKey(const ValueKey('office-resize-1-1')),
      const Offset(-80, -60),
    );
    await tester.pump();
    final resized = tester.getRect(frame);
    expect(resized.width, lessThan(moved.width));
    expect(resized.height, lessThan(moved.height));
    await tester.tap(maximize);
    await tester.pump();
    expect(tester.getSize(frame), const Size(1200, 900));
    expect(controller.text, 'draft');
    await tester.tap(maximize);
    await tester.pump();
    expect(tester.getRect(frame), resized);
    await tester.tap(title);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(title);
    await tester.pump();
    expect(tester.getSize(frame), const Size(1200, 900));
    tester.view.physicalSize = const Size(360, 240);
    await tester.pump();
    expect(tester.getSize(frame), const Size(360, 240));
    await tester.tap(maximize);
    await tester.pump();
    expect(tester.getRect(frame).right, lessThanOrEqualTo(360));
    expect(tester.getRect(frame).bottom, lessThanOrEqualTo(240));
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('office-workspace-close')));
    await tester.pump();
    expect(closed, isTrue);
    await tester.pumpAndSettle();
    await tester.pumpWidget(const SizedBox());
  });
}
