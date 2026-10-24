import 'dart:convert';
import 'dart:math';

String newOfficeIdentity() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}

/// Session-owned game data. Never shared by project, character name or harness.
class OfficeSocialState {
  OfficeSocialState({String? identity, Map<String, dynamic>? restored})
    : identity = identity ?? newOfficeIdentity() {
    if (restored != null) update(restored);
  }
  final String identity;
  Map<String, dynamic>? _data;
  String? _signature;
  Map<String, dynamic>? get data => _data;
  void clear() {
    _data = null;
    _signature = null;
  }

  bool update(Map<String, dynamic> value) {
    if (value['identity'] != identity ||
        value['version'] != 1 ||
        value['wallet'] is! Map) {
      return false;
    }
    final encoded = jsonEncode(value);
    if (encoded.length > 24000 || encoded == _signature) return false;
    _signature = encoded;
    _data = (jsonDecode(encoded) as Map).cast<String, dynamic>();
    return true;
  }
}

class OfficeSocialEvent {
  const OfficeSocialEvent({
    required this.id,
    required this.agentId,
    required this.at,
    required this.icon,
    required this.text,
    required this.place,
  });
  final String id, agentId, icon, text, place;
  final DateTime at;
  static OfficeSocialEvent? fromJson(dynamic value) {
    if (value is! Map ||
        value['id'] is! String ||
        value['agentId'] is! String ||
        value['at'] is! num ||
        !(value['at'] as num).isFinite ||
        (value['at'] as num).abs() > 8640000000000000) {
      return null;
    }
    return OfficeSocialEvent(
      id: value['id'] as String,
      agentId: value['agentId'] as String,
      at: DateTime.fromMillisecondsSinceEpoch((value['at'] as num).toInt()),
      icon: '${value['icon'] ?? '💬'}',
      text: '${value['text'] ?? ''}',
      place: '${value['place'] ?? ''}',
    );
  }
}

class OfficeAgentSocial {
  OfficeAgentSocial.fromJson(Map<dynamic, dynamic> value)
    : coins = _number(value['coins']),
      earned = _number(value['earned']),
      wins = _number(value['wins']),
      losses = _number(value['losses']),
      catchphrase = '${value['catchphrase'] ?? ''}',
      doing = value['doing'] is String ? value['doing'] as String : null,
      traits = _maps(value['traits']),
      bonds = _maps(value['bonds']),
      ledger = _maps(value['ledger']);
  final int coins, earned, wins, losses;
  final String catchphrase;
  final String? doing;
  final List<Map<String, dynamic>> traits, bonds, ledger;
  static int _number(dynamic value) =>
      value is num && value.isFinite ? value.toInt() : 0;
  static List<Map<String, dynamic>> _maps(dynamic value) => value is List
      ? value
            .whereType<Map>()
            .take(20)
            .map((e) => e.cast<String, dynamic>())
            .toList()
      : [];
}
