/// Tipo de efeito visual em uma sala do escritório virtual.
enum OfficeRoomEffectKind {
  /// Celebração: confetes, pulinhos de alegria, faixa dourada e estrelas.
  party,

  /// Emergência: giroflex nos cantos, piso pulsante avermelhado, luz giratória e faixa vermelha.
  alarm,
}

/// Representa um efeito ativo em uma sala do escritório virtual.
class OfficeRoomEffect {
  const OfficeRoomEffect({
    required this.kind,
    required this.text,
    required this.at,
    required this.until,
    this.agentId,
  });

  final OfficeRoomEffectKind kind;
  final String text;
  final int at;
  final int until;
  final String? agentId;

  bool isExpired(int now) => now >= until;

  Map<String, dynamic> toMap() => {
    'kind': kind.name,
    'text': text,
    'at': at,
    'until': until,
    if (agentId != null) 'agentId': agentId,
  };
}

/// Gerencia o ciclo de vida dos efeitos visuais das salas por projeto.
///
/// Espelha o comportamento do `RoomEffects` original do Habblaud:
/// - Uma festa (`party`) dura por padrão 12 segundos.
/// - Um alarme (`alarm`) dura por padrão 10 minutos ou até ser resolvido por um CI verde.
/// - Um alarme cancela qualquer festa atual.
/// - Um CI verde ou resolução em uma sala que estava em alarme dispara uma festa comemorativa.
class OfficeRoomEffectsManager {
  OfficeRoomEffectsManager({
    this.partyDuration = const Duration(seconds: 12),
    this.alarmDuration = const Duration(minutes: 10),
  });

  final Duration partyDuration;
  final Duration alarmDuration;

  final Map<String, _RoomSlots> _rooms = <String, _RoomSlots>{};

  /// Dispara uma festa comemorativa na sala do projeto.
  void triggerParty(
    String roomId,
    String text, {
    String? agentId,
    int? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final slots = _rooms.putIfAbsent(roomId, _RoomSlots.new);
    slots.party = OfficeRoomEffect(
      kind: OfficeRoomEffectKind.party,
      text: text,
      at: now,
      until: now + partyDuration.inMilliseconds,
      agentId: agentId,
    );
  }

  /// Dispara um alarme de erro/CI vermelho na sala do projeto.
  void triggerAlarm(
    String roomId,
    String text, {
    String? agentId,
    int? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final slots = _rooms.putIfAbsent(roomId, _RoomSlots.new);
    // Um alarme encerra imediatamente uma festa em andamento.
    slots.party = null;
    slots.alarm = OfficeRoomEffect(
      kind: OfficeRoomEffectKind.alarm,
      text: text,
      at: now,
      until: now + alarmDuration.inMilliseconds,
      agentId: agentId,
    );
  }

  /// Resolve um alarme ativo (ex.: CI voltou a passar).
  ///
  /// Se havia um alarme ativo, converte em festa de redenção ("CI verde de novo!").
  /// Retorna `true` se um alarme foi efetivamente resolvido.
  bool resolveAlarm(
    String roomId, {
    String celebrationText = 'CI verde de novo!',
    String? agentId,
    int? timestamp,
  }) {
    final now = timestamp ?? DateTime.now().millisecondsSinceEpoch;
    final slots = _rooms[roomId];
    if (slots == null || slots.alarm == null || slots.alarm!.isExpired(now)) {
      return false;
    }
    slots.alarm = null;
    triggerParty(roomId, celebrationText, agentId: agentId, timestamp: now);
    return true;
  }

  /// Retorna o efeito visível atual da sala ou `null` se nenhum estiver ativo.
  OfficeRoomEffect? getEffect(String roomId, int now) {
    final slots = _rooms[roomId];
    if (slots == null) return null;
    if (slots.party != null && !slots.party!.isExpired(now)) {
      return slots.party;
    }
    if (slots.alarm != null && !slots.alarm!.isExpired(now)) {
      return slots.alarm;
    }
    return null;
  }

  /// Limpa efeitos expirados para liberar memória.
  void prune(int now) {
    final toRemove = <String>[];
    for (final entry in _rooms.entries) {
      final slots = entry.value;
      if (slots.party != null && slots.party!.isExpired(now)) {
        slots.party = null;
      }
      if (slots.alarm != null && slots.alarm!.isExpired(now)) {
        slots.alarm = null;
      }
      if (slots.party == null && slots.alarm == null) {
        toRemove.add(entry.key);
      }
    }
    for (final key in toRemove) {
      _rooms.remove(key);
    }
  }

  /// Instância singleton compartilhada na aplicação para comunicação entre terminal e Office.
  static final OfficeRoomEffectsManager instance = OfficeRoomEffectsManager();
}

class _RoomSlots {
  OfficeRoomEffect? party;
  OfficeRoomEffect? alarm;
}
