import 'package:orkest_protocol/orkest_protocol.dart';
import 'package:test/test.dart';

void main() {
  const codec = RemoteMessageCodec();
  test('remote Office events preserve the correlation ID and outcome', () {
    const event = TurnStatus(
      paneId: 'p1',
      status: 'activity',
      activityKind: 'command',
      activityPhase: 'failed',
      activitySummary: 'Build failed',
      activityId: 'run1',
      harness: 'apple-fm',
    );
    final decoded = codec.decodeLine(codec.encode(event).trim()) as TurnStatus;
    expect(decoded.toJson(), event.toJson());
    expect(decoded.activitySummary, 'Build failed');
    expect(decoded.activityId, 'run1');
    expect(decoded.harness, 'apple-fm');
  });
  test('task events preserve their stable ID and external producer', () {
    const event = TurnStatus(
      paneId: 'p1',
      status: 'activity',
      activityKind: 'task_completed',
      activityPhase: 'completed',
      activityId: 'task:1',
      activitySummary: 'Review',
      harness: 'kimi',
    );
    final decoded = codec.decodeLine(codec.encode(event).trim()) as TurnStatus;
    expect(decoded.toJson(), event.toJson());
  });
  test('older hosts can omit Office activities', () {
    final decoded = TurnStatus.fromJson({'pane': 'p1', 'st': 'idle'});
    expect(decoded.activityKind, isNull);
    expect(decoded.activityId, isNull);
    expect(decoded.toJson().containsKey('activityKind'), false);
  });
}
