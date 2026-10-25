import 'package:orkest_code/app/orkest/ui/session/office_social_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('same session restores its game state, a new session rejects it', () {
    final state = OfficeSocialState();
    final data = {
      'version': 1,
      'identity': state.identity,
      'wallet': {'coins': 125},
    };
    expect(state.update(data), isTrue);
    expect(state.update(data), isFalse);
    expect(
      OfficeSocialState(identity: state.identity, restored: data).data,
      data,
    );
    expect(OfficeSocialState(restored: data).data, isNull);
  });
  test('rejects unsupported or unbounded state and copies incoming data', () {
    final state = OfficeSocialState();
    final data = {
      'version': 1,
      'identity': state.identity,
      'wallet': {'coins': 125},
    };
    expect(state.update(data), isTrue);
    (data['wallet'] as Map)['coins'] = 0;
    expect((state.data!['wallet'] as Map)['coins'], 125);
    expect(
      state.update({'version': 2, 'identity': state.identity, 'wallet': {}}),
      isFalse,
    );
    expect(
      state.update({
        'version': 1,
        'identity': state.identity,
        'wallet': {'text': 'x' * 25000},
      }),
      isFalse,
    );
  });
}
