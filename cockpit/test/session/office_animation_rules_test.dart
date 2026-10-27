import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/orkest/ui/session/office_animation_rules.dart';
import 'package:orkest_code/app/orkest/ui/session/office_harness_identity.dart';

void main() {
  test('shell stages change exactly at the upstream thresholds', () {
    for (final (age, expected) in [
      (0, OfficeShellStage.popcorn),
      (179999, OfficeShellStage.popcorn),
      (180000, OfficeShellStage.restless),
      (599999, OfficeShellStage.restless),
      (600000, OfficeShellStage.cobweb),
      (1499999, OfficeShellStage.cobweb),
      (1500000, OfficeShellStage.nap),
    ]) {
      expect(OfficeAnimationRules.shellStage(age), expected);
    }
  });
  test('only urgent movement beyond each distance runs', () {
    for (final (mode, threshold) in [
      ('waiting', 2),
      ('working', 12),
      ('shell', 20),
    ]) {
      expect(OfficeAnimationRules.shouldRun(threshold.toDouble(), mode), false);
      expect(OfficeAnimationRules.shouldRun(threshold + .01, mode), true);
    }
    expect(OfficeAnimationRules.shouldRun(100, 'idle'), false);
  });
  test('room lights converge after flickering', () {
    expect(OfficeAnimationRules.lightLevel(true, 550), 1);
    expect(OfficeAnimationRules.lightLevel(false, 600), 0);
    expect(OfficeAnimationRules.lightLevel(true, 100), .1);
    expect(OfficeAnimationRules.lightLevel(false, 90), .95);
  });
  test('every catalog harness preserves its own identity', () {
    for (final kind in HarnessKind.values) {
      final identity = OfficeHarnessIdentity.resolve(kind, 'external');
      expect(identity.id, kind.name);
      expect(identity.label, HarnessCatalog.getSpec(kind)!.label);
      expect(identity.source, 'process');
    }
  });
  test('new harnesses work without a catalog entry', () {
    for (final id in ['kimi', 'apple-fm', 'xcode/custom', 'future:model']) {
      final identity = OfficeHarnessIdentity.resolve(null, id);
      expect(identity.id, id);
      expect(identity.source, 'reported');
    }
    expect(OfficeHarnessIdentity.resolve(null, null).source, 'unknown');
    expect(OfficeHarnessIdentity.resolve(null, 'bad\nvalue').source, 'unknown');
  });
}
