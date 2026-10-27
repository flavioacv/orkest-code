part of 'office_world_flutter_view.dart';

// Native simulation consumes the same normalized PTY state as the Canvas
// simulation. Destinations and collision cells are exported from its layout.
class _OfficeAgent {
  _OfficeAgent({
    required this.session,
    required this.project,
    required this.slot,
    required this.deskIndex,
    required this.status,
    required int createdAt,
    String? agentId,
    this.child,
    this.parentId,
  }) : id = agentId ?? session.id,
       projectId = session.projectId,
       statusSince =
           child?.startedAt.millisecondsSinceEpoch ??
           session.officeStatusSince.millisecondsSinceEpoch,
       poseSince = createdAt,
       nextOutingAt = createdAt + 5000 + (_hash(agentId ?? session.id) % 9000),
       look = _hash(agentId ?? session.id) % 16,
       rng = math.Random(_hash(agentId ?? session.id));

  static const missingGraceMs = 3000;
  static const _walkSpeed = 51.2;
  final String id, projectId;
  final int look;
  final math.Random rng;
  TerminalSession session;
  Project project;
  OfficeSubagent? child;
  String? parentId;
  int slot, deskIndex, statusSince, poseSince, nextOutingAt;
  TerminalStatus status;
  int? missingAt, actionUntil, celebrationUntil;
  int outingState = 0, outingCount = 0;
  Map<String, dynamic>? outing, _workSpot;
  bool entering = false, leaving = false, gone = false, seated = false;
  bool delivered = false, delivering = false;
  int _lastDeliverySequence = -1;
  _WorldMap? _world;
  String? _reservation;
  double alpha = 1;
  Offset position = Offset.zero;
  String pose = 'stand', held = 'none', dir = 'down';
  String? icon;
  int iconUntil = 0;
  String emoji = '';
  int emojiUntil = 0, sparkleAt = 0, confettiAt = 0, coinsAt = 0;
  String? coinsTo;
  int _routeIndex = 0;
  int _entryAt = 0, _entryStage = 0, _switchAt = 0;
  int? _exitAt;
  int _exitStage = 0;
  bool _lastToLeave = false;
  _NativeRoomTransition? roomLight;
  Map? _arrivalSwitch;
  Offset? _exitTarget;
  List<Offset> _route = const [];
  bool _running = false;
  int _reactionUntil = 0, _reactionAt = 0;
  bool _reactionSuccess = false;
  int _lastActivity = -1, _partyKey = -1;
  String? _shellDoneKey;
  _NativeGathering? gathering;
  int shellSince = 0, _now = 0;
  String mode = 'idle';
  OfficeShellStage? shellStage;
  String get title => child?.type ?? session.displayTitle;
  bool get atHome =>
      !entering &&
      !leaving &&
      !delivering &&
      outing == null &&
      gathering == null &&
      _routeIndex >= _route.length;
  bool get canSocial =>
      atHome &&
      (mode == 'idle' ||
          (mode == 'shell' &&
              _now - shellSince >= OfficeAnimationRules.socialShellMinMs)) &&
      _now >= _reactionUntil;
  int between(int a, int b) => a + rng.nextInt(b - a + 1);
  int idleDelay(AppSettings settings) {
    final (a, b) = OfficeAnimationRules.idleRange(settings.officeLiveliness);
    return between(a, b);
  }

  void arrive(_WorldMap map) {
    final spot = _spot(map);
    if (spot == null) {
      gone = true;
      return;
    }
    entering = true;
    final toDesk = Offset(
      (spot['x'] as num).toDouble(),
      (spot['y'] as num).toDouble(),
    );
    dir = (spot['dir'] as String?) ?? 'down';
    seated = false;
    final elevators = (map.native['spots'] as List)
        .where((s) => s['kind'] == 'elevator')
        .toList();
    final elevator = elevators.isEmpty
        ? null
        : elevators[_hash(id) % elevators.length] as Map;
    position = elevator == null
        ? toDesk
        : Offset(
            (elevator['x'] as num).toDouble(),
            (elevator['y'] as num).toDouble(),
          );
    _entryAt = poseSince;
    if (elevator != null) {
      final key = elevator['id'] as String;
      _entryAt = math.max(_entryAt, map.elevatorNext[key] ?? _entryAt);
      map.elevatorNext[key] = _entryAt + 520;
    }
    alpha = 0;
    final switches = (map.native['spots'] as List)
        .where((s) => s['areaId'] == 'workspace-$slot' && s['kind'] == 'switch')
        .toList();
    if (roomLight?.lightAt == null &&
        roomLight?.claim == null &&
        switches.isNotEmpty) {
      roomLight?.claim = id;
      _arrivalSwitch = switches.first as Map;
      _entryStage = 1;
      final target = Offset(
        (_arrivalSwitch!['x'] as num).toDouble(),
        (_arrivalSwitch!['y'] as num).toDouble(),
      );
      _setRoute(_path(map, position, target));
    } else {
      _entryStage = 3;
      _setRoute(_path(map, position, toDesk));
    }
  }

  void beginLeaving(_WorldMap map, int now) {
    if (leaving || gone) return;
    if (_reservation != null) {
      map.reservations.remove(_reservation);
      _reservation = null;
    }
    gathering?.remove(this);
    if (roomLight?.claim == id && roomLight?.lightAt == null) {
      roomLight?.claim = null;
    }
    leaving = true;
    entering = false;
    delivering = false;
    icon = null;
    final elevators = (map.native['spots'] as List)
        .where((s) => s['kind'] == 'elevator')
        .toList();
    final elevator = elevators.isEmpty
        ? null
        : elevators[_hash(id) % elevators.length] as Map;
    final home = _spot(map);
    _exitTarget = elevator == null
        ? position
        : Offset(
            (elevator['x'] as num).toDouble(),
            (elevator['y'] as num).toDouble(),
          );
    final switches = (map.native['spots'] as List)
        .where((s) => s['areaId'] == 'workspace-$slot' && s['kind'] == 'switch')
        .toList();
    if (_lastToLeave && roomLight?.lightAt != null && switches.isNotEmpty) {
      final point = switches.first as Map;
      _exitStage = 1;
      _setRoute(
        _path(
          map,
          position,
          Offset(
            (point['x'] as num).toDouble(),
            (point['y'] as num).toDouble(),
          ),
        ),
      );
    } else {
      _exitStage = 3;
      _setRoute(_path(map, position, _exitTarget!));
    }
    if (home == null && _route.isEmpty) _exitAt = now;
  }

  void changeStatus(TerminalStatus next, int now) {
    if (status == next) return;
    status = next;
    statusSince =
        child?.finishedAt?.millisecondsSinceEpoch ??
        session.officeStatusSince.millisecondsSinceEpoch;
    if (next != TerminalStatus.idle && gathering != null) {
      gathering!.remove(this);
      emoji = '👋';
      emojiUntil = now + 1600;
    }
    if (next != TerminalStatus.idle && outing != null) _returnFromOuting();
  }

  late final Map<String, dynamic> wallet = Map<String, dynamic>.from(
    child == null
        ? ((session.officeSocial.data?['wallet'] as Map?) ?? _newWallet(100))
        : _newWallet(30),
  );
  Map<String, dynamic> _newWallet(int coins) => {
    'name': title,
    'coins': coins,
    'earned': coins,
    'wins': 0,
    'losses': 0,
    'vs': <String, dynamic>{},
    'paid': <String>[],
    'ledger': <dynamic>[],
    'createdAt': statusSince,
    'seenAt': statusSince,
  };
  int _taskRevision = -1, coinRewardAt = 0, coinDelta = 0;
  void _saveWallet() {
    if (child != null) return;
    session.updateOfficeSocialState({
      'identity': session.officeIdentity,
      'version': 1,
      'wallet': wallet,
      'events': session.officeSocial.data?['events'] ?? <dynamic>[],
    });
  }

  void _credit(int amount, int now, String rewardIcon) {
    wallet['coins'] = (wallet['coins'] as num).toInt() + amount;
    wallet['earned'] = (wallet['earned'] as num).toInt() + amount;
    final ledger = List<dynamic>.from(wallet['ledger'] as List? ?? []);
    ledger.insert(0, {
      'at': now,
      'delta': amount,
      'icon': rewardIcon,
      'text': title,
    });
    wallet['ledger'] = ledger.take(12).toList();
    coinRewardAt = now;
    coinDelta = amount;
    _saveWallet();
  }

  void _payTasks(int now) {
    if (child != null || _taskRevision == session.officeTaskRevision) return;
    final first = _taskRevision < 0;
    _taskRevision = session.officeTaskRevision;
    final paid = List<String>.from(wallet['paid'] as List? ?? []);
    var amount = 0;
    for (final task in session.officeTasks) {
      final key = '${task['id']}|${task['title']}';
      if (task['status'] == 'completed' && !paid.contains(key)) {
        paid.add(key);
        amount += 10;
      }
    }
    wallet['paid'] = paid.skip(math.max(0, paid.length - 300)).toList();
    if (amount > 0) {
      _credit(amount, now, '✅');
      if (first) coinRewardAt = 0;
    } else if (first) {
      _saveWallet();
    }
  }

  void _signals(int now) {
    _now = now;
    _payTasks(now);
    mode = child == null ? session.officeVisualStatus : status.name;
    if (mode != 'waiting' && child == null) {
      final pending = session.officeShells
          .where((j) => mode == 'shell' || j['background'] == false)
          .toList();
      if (pending.isNotEmpty) {
        shellSince = (pending.first['startedAt'] as num).toInt();
        if (mode == 'shell' ||
            (mode == 'working' &&
                now - shellSince > OfficeAnimationRules.foregroundWaitMs)) {
          mode = 'shell';
          shellStage = OfficeAnimationRules.shellStage(now - shellSince);
        } else {
          shellStage = null;
        }
      } else {
        shellStage = null;
        shellSince = 0;
      }
    } else {
      shellStage = null;
      shellSince = 0;
    }
    if (child == null) {
      final done = session.officeShellDone;
      if (done != null && done['id'] != _shellDoneKey) {
        _shellDoneKey = done['id'] as String?;
        if (now - (done['at'] as num).toInt() < 10000 && !leaving) {
          _reactionSuccess = done['error'] != true;
          _reactionAt = now;
          _reactionUntil =
              now +
              (_reactionSuccess
                  ? OfficeAnimationRules.shellSuccessMs
                  : OfficeAnimationRules.shellFailureMs);
          icon = _reactionSuccess ? 'star' : 'storm';
          iconUntil = _reactionUntil;
          if (_reactionSuccess) confettiAt = now;
        }
      }
      final event = session.officeStatusHistory.lastOrNull;
      if (event != null && event.sequence != _lastActivity) {
        final initial = _lastActivity < 0;
        _lastActivity = event.sequence;
        if (!initial) {
          switch (event.activityKind) {
            case 'done':
              icon = 'check';
              iconUntil = now + 2600;
              _credit(5, now, '💬');
            case 'error':
              icon = 'sweat';
              iconUntil = now + 2200;
            case 'delegate':
              if (atHome) {
                _delegateUntil = now + 2600;
                emoji = '💬';
                emojiUntil = _delegateUntil;
              }
          }
        }
      }
    }
    final fx = OfficeRoomEffectsManager.instance.getEffect(projectId, now);
    if (fx != null &&
        fx.kind == OfficeRoomEffectKind.party &&
        fx.at != _partyKey &&
        fx.until - now >= 3000 &&
        mode != 'waiting' &&
        !entering &&
        alpha >= .5 &&
        !leaving &&
        !delivering) {
      _partyKey = fx.at;
      _partyAt = now + (_hash(id) % 700);
      celebrationUntil = atHome
          ? _partyAt + OfficeAnimationRules.partyCheerMs
          : null;
      if (fx.agentId == id) {
        icon = 'star';
        iconUntil = _partyAt + OfficeAnimationRules.partyCheerMs;
        confettiAt = _partyAt;
      }
      if (!atHome) {
        emoji = '🎉';
        emojiUntil = now + 2400;
      }
    }
  }

  int _delegateUntil = 0, _partyAt = 0;

  void advance(double dt, int now, _WorldMap map, AppSettings settings) {
    if (gone) return;
    _world = map;
    _signals(now);
    if (icon != null && now >= iconUntil) icon = null;
    if (leaving) {
      if (_routeIndex < _route.length) {
        _advanceRoute(dt, now);
        return;
      }
      if (_exitStage == 1) {
        _exitStage = 2;
        _switchAt = now;
      }
      if (_exitStage == 2) {
        _setPose('use', now);
        if (now - _switchAt < 180) return;
        roomLight?.darkAt = now;
        roomLight?.lightAt = null;
        _exitStage = 3;
        _setRoute(_path(map, position, _exitTarget ?? position));
        return;
      }
      _exitAt ??= now;
      dir = 'up';
      _setPose('stand', now);
      alpha = (1 - (now - _exitAt! - 180) / 320).clamp(0, 1);
      if (now - _exitAt! >= 650) gone = true;
      return;
    }
    if (entering && now - _entryAt < 650) {
      alpha = 0;
      dir = 'up';
      _setPose('stand', now);
      return;
    }
    if (entering) alpha = ((now - _entryAt - 650) / 300).clamp(0, 1);
    if (entering && _entryStage == 2) {
      _setPose('use', now);
      if (now - _switchAt < 180) return;
      roomLight?.lightAt = now;
      roomLight?.darkAt = null;
      roomLight?.claim = null;
      _entryStage = 3;
      _setRoute(_path(map, position, _deskPoint(_workSpot!)));
      return;
    }
    if (_routeIndex < _route.length) {
      if (!entering && outingState == 3) {
        _running = OfficeAnimationRules.shouldRun(
          _pathLength([position, ..._route.skip(_routeIndex)]) / 16,
          mode,
        );
      }
      _advanceRoute(dt, now);
      if (_routeIndex >= _route.length) {
        if (entering && _entryStage == 1) {
          _entryStage = 2;
          _switchAt = now;
          return;
        }
        if (entering) {
          entering = false;
          alpha = 1;
          _seatAt = now;
        }
        if (outingState == 1) {
          _beginOutingAction(now);
        } else if (outingState == 3) {
          outing = null;
          outingState = 0;
          actionUntil = null;
          nextOutingAt = now + idleDelay(settings);
          _seatAt = now;
        }
      }
      return;
    }
    if (entering && _entryStage == 1) {
      _entryStage = 2;
      _switchAt = now;
      return;
    }
    if (entering) {
      entering = false;
      _seatAt = now;
    }
    if (delivering) {
      if (_deliveryAt == 0) {
        _deliveryAt = now;
        emoji = '📦';
        emojiUntil = now + 2700;
      }
      _setPose('talk', now);
      if (now - _deliveryAt >= 2700) {
        delivered = true;
        delivering = false;
        _deliveryAt = 0;
        _credit(15, now, '📦');
        if (child != null) {
          beginLeaving(map, now);
        } else {
          _returnHome();
        }
      }
      return;
    }
    if (gathering != null) {
      return; // the group owns the pose at its reserved destination
    }
    if (outingState == 2 && actionUntil != null) {
      if (now >= actionUntil!) {
        if (_soloKind == 'stall' && _planWash(map, now)) return;
        _returnFromOuting();
      } else {
        _outingPose(now);
      }
      return;
    }
    if (mode == 'idle' &&
        now - statusSince < OfficeAnimationRules.longIdleMs &&
        now >= nextOutingAt &&
        now >= _reactionUntil) {
      _startOuting(map, now, settings);
      if (outing != null) return;
    }
    _setRestPose(now);
  }

  int _seatAt = 0, _deliveryAt = 0;
  double get seatBlend => ((_now - _seatAt) / 180).clamp(0, 1);

  void _setRestPose(int now) {
    _setDeskDir();
    final seat = _workSpot?['seated'] != false;
    if (mode == 'waiting') {
      _setPose('raise_hand', now, seated: seat);
      return;
    }
    if (atHome && now < _reactionUntil) {
      if (!_reactionSuccess) {
        _setPose(seat ? 'sleep' : 'stand', now, seated: seat);
      } else {
        _setPose(
          now - _reactionAt < OfficeAnimationRules.shellSuccessMs * .55
              ? 'stretch'
              : 'raise_hand',
          now,
        );
      }
      return;
    }
    if (atHome &&
        celebrationUntil != null &&
        now >= _partyAt &&
        now < celebrationUntil!) {
      _setPose('cheer', now);
      return;
    }
    if (now < _delegateUntil) {
      _setPose('talk', now);
      return;
    }
    if (mode == 'shell') {
      if (!seat) {
        _setPose('stand', now);
        return;
      }
      final age = now - shellSince;
      final stage = shellStage ?? OfficeAnimationRules.shellStage(age);
      switch (stage) {
        case OfficeShellStage.popcorn:
          _setPose('wait', now, held: 'popcorn', seated: true);
        case OfficeShellStage.restless:
          final cycle = 15000 + _hash(id) % 10000;
          final phase = (age - 182500) % cycle;
          if (age >= 182500 && phase < 800) {
            final dirs = ['up', 'right', 'down', 'left'];
            dir =
                dirs[(dirs.indexOf(_workSpot?['dir'] as String? ?? 'up') +
                        1 +
                        (phase ~/ 200)) %
                    4];
          }
          _setPose('wait', now, seated: true);
        case OfficeShellStage.cobweb:
          final gap = 18000 + _hash(id) % 14000;
          final yawn = age >= 604000 && (age - 604000) % gap < 1300;
          _setPose(yawn ? 'sleep' : 'wait', now, seated: true);
          if (yawn) {
            emoji = '🥱';
            emojiUntil = now + 300;
          }
        case OfficeShellStage.nap:
          _setPose('sleep', now, seated: true);
      }
      return;
    }
    if (mode == 'working') {
      _setPose(
        seat ? 'type' : 'read',
        now,
        held: (!seat || _workSpot?['laptop'] == true) ? 'laptop' : 'none',
        seated: seat,
      );
    } else if (now - statusSince > OfficeAnimationRules.longIdleMs) {
      _setPose(seat ? 'sleep' : 'stand', now, seated: seat);
      icon = 'zzz';
      iconUntil = now + 1500;
    } else {
      _setPose(seat ? 'sit' : 'stand', now, seated: seat);
    }
  }

  void _setDeskDir() {
    dir = _workSpot?['dir'] as String? ?? dir;
  }

  void _setPose(
    String next,
    int now, {
    String held = 'none',
    bool seated = false,
  }) {
    if (this.seated != seated) {
      _seatAt = now;
    }
    if (pose != next) {
      pose = next;
      poseSince = now;
    }
    this.held = held;
    this.seated = seated;
  }

  void _advanceRoute(double dt, int now) {
    var budget = (_running ? 96 : _walkSpeed) * dt;
    while (budget > 0 && _routeIndex < _route.length) {
      final target = _route[_routeIndex];
      final delta = target - position;
      final length = delta.distance;
      if (length < .01) {
        position = target;
        _routeIndex++;
        continue;
      }
      dir = _direction(delta, dir);
      _setPose(
        _running ? 'run' : 'walk',
        now,
        held: delivering ? 'papers' : held,
      );
      final step = math.min(budget, length);
      position += delta / length * step;
      budget -= step;
      if (step >= length) {
        position = target;
        _routeIndex++;
      }
    }
  }

  void _setRoute(List<Offset> points) {
    _route = points.where((point) => (point - position).distance > .5).toList();
    _routeIndex = 0;
  }

  void _startOuting(_WorldMap map, int now, AppSettings settings) {
    final options =
        (_workSpot?['outingSpots'] as List?)
            ?.whereType<Map>()
            .map((s) => s.cast<String, dynamic>())
            .toList() ??
        [];
    if (options.isEmpty) {
      nextOutingAt = now + idleDelay(settings);
      return;
    }
    // Weights and timing retain the original solo activities. Group games are
    // scheduled by the scene, not fabricated as isolated terminal actions.
    const weights = {
      'coffee': 18,
      'water': 12,
      'stall': 8,
      'sofa': 12,
      'armchair': 12,
      'beanbag': 12,
      'window': 7,
      'shelf': 6,
      'arcade': 5,
      'snack': 5,
      'sink': 3,
    };
    final choices = options
        .where(
          (s) =>
              weights.containsKey(s['kind']) &&
              !map.reservations.containsKey('${s['x']}:${s['y']}'),
        )
        .toList();
    final extra = outingCount % 7;
    if (extra == 0) {
      outingCount++;
      _soloKind = 'stretch';
      outing = {'kind': 'stretch'};
      outingState = 2;
      actionUntil = now + 2600;
      _actionAt = now;
      return;
    }
    if (extra == 1) {
      final seats = options
          .where(
            (s) => [
              'sofa',
              'armchair',
              'beanbag',
              'bench',
              'cafe_seat',
            ].contains(s['kind']),
          )
          .toList();
      if (seats.isNotEmpty) {
        _visit(map, seats[rng.nextInt(seats.length)], now, 'phone');
        return;
      }
    }
    if (choices.isEmpty) {
      nextOutingAt = now + idleDelay(settings);
      return;
    }
    final total = choices.fold<int>(0, (v, s) => v + (weights[s['kind']] ?? 1));
    var pick = rng.nextInt(total);
    for (final target in choices) {
      pick -= weights[target['kind']] ?? 1;
      if (pick < 0) {
        _visit(
          map,
          target,
          now,
          target['kind'] == 'sink' ? 'mirror' : target['kind'] as String,
        );
        return;
      }
    }
  }

  String _soloKind = '';
  int _actionAt = 0;
  bool _nap = false;
  void _visit(
    _WorldMap map,
    Map<String, dynamic> target,
    int now,
    String kind,
  ) {
    final key = '${target['x']}:${target['y']}';
    if (map.reservations.containsKey(key) && map.reservations[key] != id) {
      return;
    }
    if (_reservation != null) map.reservations.remove(_reservation);
    map.reservations[key] = id;
    _reservation = key;
    outing = target;
    outingState = 1;
    outingCount++;
    _soloKind = kind;
    final point = Offset(
      (target['x'] as num).toDouble(),
      (target['y'] as num).toDouble(),
    );
    _setRoute(_path(map, position, point));
    if (_route.isEmpty) _beginOutingAction(now);
  }

  void _beginOutingAction(int now) {
    final target = outing;
    if (target == null) return;
    outingState = 2;
    _actionAt = now;
    _nap = rng.nextDouble() < .25;
    dir = target['dir'] as String? ?? dir;
    seated = target['seated'] == true;
    final duration = switch (_soloKind) {
      'coffee' => 4500,
      'water' => 3500,
      'stall' => between(5000, 12000),
      'wash' => 2200,
      'phone' => between(8000, 18000),
      'mirror' => between(6000, 11000),
      'sofa' ||
      'armchair' ||
      'beanbag' => _nap ? between(11000, 22000) : between(9000, 22000),
      'shelf' => between(5000, 9000),
      'arcade' => between(6000, 12000),
      'snack' || 'fridge' => 2500,
      _ => between(5000, 10000),
    };
    actionUntil = now + duration;
    _outingPose(now);
  }

  void _outingPose(int now) {
    final age = now - _actionAt;
    final seat = outing?['seated'] == true;
    switch (_soloKind) {
      case 'coffee':
        _setPose(
          age < 1900 ? 'use' : 'drink',
          now,
          held: age < 1900 ? 'none' : 'coffee',
        );
      case 'water':
        _setPose(
          age < 1000 ? 'use' : 'drink',
          now,
          held: age < 1000 ? 'none' : 'water',
        );
      case 'stall':
        alpha = 0;
        _setPose('stand', now);
      case 'phone':
        _setPose('read', now, held: 'phone', seated: seat);
      case 'mirror':
        _setPose('groom', now, held: look % 2 == 0 ? 'comb' : 'lipstick');
        if (actionUntil! - now < 1600 && sparkleAt < _actionAt) {
          sparkleAt = now;
        }
      case 'stretch':
        _setPose('stretch', now);
      case 'shelf':
        _setPose('read', now, held: 'book');
      case 'window':
        _setPose('stand', now);
      case 'arcade' || 'snack' || 'fridge' || 'wash':
        _setPose('use', now);
      case 'sofa' || 'armchair' || 'beanbag':
        _setPose(_nap && age > 3000 ? 'sleep' : 'sit', now, seated: true);
        if (_nap && age > 3000) {
          icon = 'zzz';
          iconUntil = now + 500;
        }
      default:
        _setPose(seat ? 'sit' : 'stand', now, seated: seat);
    }
  }

  bool _planWash(_WorldMap map, int now) {
    final sinks =
        (_workSpot?['outingSpots'] as List?)
            ?.whereType<Map>()
            .where(
              (s) =>
                  s['kind'] == 'sink' &&
                  !map.reservations.containsKey('${s['x']}:${s['y']}'),
            )
            .toList() ??
        [];
    if (sinks.isEmpty) return false;
    alpha = 1;
    _visit(map, sinks.first.cast<String, dynamic>(), now, 'wash');
    return true;
  }

  void _returnFromOuting() {
    alpha = 1;
    if (_reservation != null) {
      _world?.reservations.remove(_reservation);
      _reservation = null;
    }
    if (outing == null || _workSpot == null) {
      outing = null;
      outingState = 0;
      return;
    }
    final path = _pointList(outing!['path']);
    _setRoute(
      _world == null
          ? [...path.reversed, _deskPoint(_workSpot!)]
          : _path(_world!, position, _deskPoint(_workSpot!)),
    );
    outingState = 3;
    actionUntil = null;
    held = _soloKind == 'coffee'
        ? 'coffee'
        : _soloKind == 'water' && rng.nextDouble() < .4
        ? 'water'
        : 'none';
  }

  void _returnHome() {
    if (_workSpot == null) return;
    final home = _deskPoint(_workSpot!);
    _setRoute(_world == null ? [home] : _path(_world!, position, home));
    outingState = 3;
  }

  Map<String, dynamic>? _spot(_WorldMap map) {
    if (slot < 0 || slot >= map.workSpots.length) return null;
    final desks = map.workSpots[slot];
    if (desks.isEmpty) return null;
    if (deskIndex < desks.length) {
      _workSpot = desks[deskIndex];
      return _workSpot;
    }
    final extras = (map.native['spots'] as List)
        .where(
          (s) =>
              s['areaId'] == 'workspace-$slot' &&
              ['stool', 'nook', 'stand'].contains(s['kind']),
        )
        .toList();
    final extraIndex = deskIndex - desks.length;
    if (extraIndex < extras.length) {
      final source = extras[extraIndex] as Map;
      final point = Offset(
        (source['x'] as num).toDouble(),
        (source['y'] as num).toDouble(),
      );
      final door = _pointList(desks.first['pathToDoor']).lastOrNull ?? point;
      _workSpot = {
        ...source.cast<String, dynamic>(),
        'laptop': true,
        'pathToDoor': _path(
          map,
          point,
          door,
        ).map((p) => {'x': p.dx, 'y': p.dy}).toList(),
        'outingSpots': desks.first['outingSpots'],
      };
      return _workSpot;
    }
    final grid = map.native['grid'] as Map, cells = grid['cells'] as List;
    final width = grid['w'] as int;
    final room = map.rooms[slot];
    final free = <Offset>[];
    for (var y = (room['y']! ~/ 16) + 2; y < (room['y']! ~/ 16) + 11; y++) {
      for (var x = (room['x']! ~/ 16) + 1; x < (room['x']! ~/ 16) + 15; x++) {
        if (cells[y * width + x] == 1) {
          free.add(Offset(x * 16 + 8, y * 16 + 11));
        }
      }
    }
    if (free.isEmpty) return null;
    final point = free[(extraIndex - extras.length) % free.length];
    final door = _pointList(desks.first['pathToDoor']).lastOrNull ?? point;
    _workSpot = {
      'x': point.dx,
      'y': point.dy,
      'dir': 'up',
      'seated': false,
      'laptop': true,
      'pathToDoor': _path(
        map,
        point,
        door,
      ).map((p) => {'x': p.dx, 'y': p.dy}).toList(),
      'outingSpots': desks.first['outingSpots'],
    };
    return _workSpot;
  }

  Offset _deskPoint(Map<String, dynamic> spot) =>
      Offset((spot['x'] as num).toDouble(), (spot['y'] as num).toDouble());
  static List<Offset> _pointList(Object? raw) => raw is List
      ? raw
            .whereType<Map>()
            .map(
              (p) => Offset(
                (p['x'] as num).toDouble(),
                (p['y'] as num).toDouble(),
              ),
            )
            .toList()
      : [];
  static double _pathLength(List<Offset> points) {
    var total = 0.0;
    for (var i = 1; i < points.length; i++) {
      total += (points[i] - points[i - 1]).distance;
    }
    return total;
  }

  static int _hash(String value) => value.codeUnits.fold<int>(
    0,
    (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
  );
  static String _direction(Offset delta, String fallback) {
    if (delta.distance < .01) return fallback;
    return delta.dx.abs() >= delta.dy.abs()
        ? (delta.dx > 0 ? 'right' : 'left')
        : (delta.dy > 0 ? 'down' : 'up');
  }

  // A bounded four-direction BFS on the exported collision grid. Actors never
  // cut through furniture when a group is interrupted or a child delivers.
  static List<Offset> _path(_WorldMap map, Offset from, Offset to) {
    final grid = map.native['grid'] as Map;
    final w = grid['w'] as int, h = grid['h'] as int;
    final cells = (grid['cells'] as List).cast<int>();
    int nearest(Offset p) {
      final x = (p.dx / 16).floor(), y = (p.dy / 16).floor();
      for (var r = 0; r < 8; r++) {
        for (var dy = -r; dy <= r; dy++) {
          for (var dx = -r; dx <= r; dx++) {
            if (math.max(dx.abs(), dy.abs()) != r) continue;
            final xx = x + dx, yy = y + dy;
            if (xx >= 0 &&
                yy >= 0 &&
                xx < w &&
                yy < h &&
                cells[yy * w + xx] != 0) {
              return yy * w + xx;
            }
          }
        }
      }
      return -1;
    }

    final start = nearest(from), end = nearest(to);
    if (start < 0 || end < 0) return [];
    final previous = List<int>.filled(w * h, -2), queue = <int>[start];
    previous[start] = -1;
    for (var head = 0; head < queue.length && previous[end] == -2; head++) {
      final i = queue[head], x = i % w, y = i ~/ w;
      for (final next in [
        if (x + 1 < w) i + 1,
        if (x > 0) i - 1,
        if (y + 1 < h) i + w,
        if (y > 0) i - w,
      ]) {
        if (cells[next] == 0 || previous[next] != -2) continue;
        previous[next] = i;
        queue.add(next);
      }
    }
    if (previous[end] == -2) return [];
    final path = <Offset>[];
    for (var i = end; i >= 0; i = previous[i]) {
      path.add(Offset((i % w) * 16 + 8, (i ~/ w) * 16 + 11));
    }
    return [...path.reversed.skip(1), to];
  }
}

class _NativeRoomTransition {
  _NativeRoomTransition(this.slot, this.at, this.project);
  final Project project;
  int slot, at;
  int? leftAt;
  int? darkAt;
  int? lightAt;
  String? claim;
}

class _NativeGathering {
  _NativeGathering(this.kind, this.members, this.at, this.map)
    : rng = math.Random(at ^ _OfficeAgent._hash(members.first.id));
  final String kind;
  final List<_OfficeAgent> members;
  final int at;
  final _WorldMap map;
  final math.Random rng;
  int start = 0, end = 0, beat = 0, round = 0, winner = -1;
  int _goalCycle = -1, _rpsWinner = -1;
  final score = [0, 0];
  final gestures = ['rock', 'paper', 'scissors'];
  final Map<String, Map<String, dynamic>> targets = {};
  void remove(_OfficeAgent actor) {
    actor.gathering = null;
    members.remove(actor);
    final target = targets[actor.id];
    if (target != null) {
      map.reservations.remove('${target['x']}:${target['y']}');
    }
    if (actor._workSpot != null) {
      actor._setRoute(
        _OfficeAgent._path(
          map,
          actor.position,
          actor._deskPoint(actor._workSpot!),
        ),
      );
      actor.outingState = 3;
    }
  }

  void finish(int now) {
    for (final actor in members.toList()) {
      actor.nextOutingAt = now + 6000;
      remove(actor);
    }
  }

  void update(int now) {
    for (final actor in members.toList()) {
      if (actor.gone ||
          actor.leaving ||
          !(actor.mode == 'idle' || actor.mode == 'shell')) {
        remove(actor);
      }
    }
    if (members.isEmpty) return;
    if (start == 0) {
      if (members.any((a) => a._routeIndex < a._route.length)) {
        if (now - at > 35000) finish(now);
        return;
      }
      start = now;
      beat = now + 900;
      end =
          now +
          switch (kind) {
            'tv' => 45000,
            'kitchen' => 30000,
            'talk' => 14000,
            'mirror' => 8000,
            _ => 30000,
          };
    }
    if (now >= end) {
      finish(now);
      return;
    }
    for (final actor in members) {
      final target = targets[actor.id]!;
      actor.dir = target['dir'] as String? ?? 'up';
      if (actor._reactionUntil > now) continue;
      if (kind == 'tv') {
        actor._setPose(
          'wait',
          now,
          held: actor.look % 3 == 0 ? 'popcorn' : 'none',
          seated: true,
        );
      } else if (kind == 'videogame') {
        actor._setPose('game', now, held: 'controller', seated: true);
      } else if (kind == 'pingpong') {
        actor._setPose('play', now, held: 'paddle');
      } else if (kind == 'arcade') {
        actor._setPose('use', now);
      } else if (kind == 'mirror') {
        actor._setPose(
          'groom',
          now,
          held: actor.look % 2 == 0 ? 'comb' : 'lipstick',
        );
      } else {
        actor._setPose(
          target['seated'] == true ? 'sit' : 'stand',
          now,
          seated: target['seated'] == true,
        );
      }
    }
    if (kind == 'tv' &&
        _OfficeAgent._hash(members.first.id) % 3 == 0 &&
        now % 7000 >= 5600 &&
        _goalCycle != now ~/ 7000) {
      _goalCycle = now ~/ 7000;
      for (final actor in members.where((actor) => actor.pose != 'sleep')) {
        actor._setPose(_goalCycle % 2 == 0 ? 'cheer' : 'sulk', now);
        actor._reactionUntil = now + 1900;
        actor.emoji = '⚽';
        actor.emojiUntil = now + 1900;
      }
    }
    if (now < beat) return;
    if (kind == 'rps' && _rpsWinner >= 0) {
      _result(_rpsWinner, now);
      _rpsWinner = -1;
      return;
    }
    round++;
    beat = now + 2400 + rng.nextInt(1800);
    if (kind == 'talk' || kind == 'kitchen') {
      final speaker = members[round % members.length];
      speaker._setPose(
        'talk',
        now,
        seated: targets[speaker.id]!['seated'] == true,
      );
      speaker.emoji = round % 3 == 0 ? '😂' : '💬';
      speaker.emojiUntil = beat;
      speaker._reactionUntil = now + 1700;
      if (round % 3 == 0) {
        for (final other in members.where((a) => a != speaker)) {
          other._setPose(
            'laugh',
            now,
            seated: targets[other.id]!['seated'] == true,
          );
          other._reactionUntil = now + 1600;
        }
      }
    } else if (kind == 'tv') {
      final program = _OfficeAgent._hash(members.first.id) % 3;
      if (program == 1) {
        for (final a in members) {
          a.emoji = round % 2 == 0 ? '😱' : '❤️';
          a.emojiUntil = beat;
        }
      }
      if (program == 2) {
        for (final a in members) {
          a._setPose('laugh', now, seated: true);
          a._reactionUntil = now + 1600;
        }
      }
      if (now - start > (end - start) ~/ 2) {
        for (final a in members.where((a) => a.look % 7 == 0)) {
          a._setPose('sleep', now, seated: true);
          a._reactionUntil = end;
        }
      }
    } else if (kind == 'mirror') {
      if (end - now < 4000) {
        for (final a in members) {
          a.sparkleAt = now;
          a.icon = 'sparkle';
          a.iconUntil = end;
        }
      }
    } else if (kind == 'rps' && members.length >= 2) {
      beat = now + 540;
      for (final a in members.take(2)) {
        a._setPose('rps', now);
        a._reactionUntil = beat;
      }
      if (round % 4 == 0) {
        final a = rng.nextInt(3), b = rng.nextInt(3);
        members[0].held = gestures[a];
        members[1].held = gestures[b];
        if (a != b) {
          _rpsWinner = (a - b + 3) % 3 == 1 ? 0 : 1;
          beat = now + 1500;
          for (final actor in members.take(2)) {
            actor._reactionUntil = now + 2200;
          }
        } else {
          beat = now + 1500;
        }
      }
    } else if (members.length >= 2) {
      final target = kind == 'pingpong'
          ? 5
          : kind == 'videogame'
          ? 2
          : 1;
      if (kind == 'pingpong' || round % 3 == 0) {
        final point = rng.nextInt(2);
        score[point]++;
        if (score[point] >= target) _result(point, now);
      }
    }
  }

  void _result(int index, int now) {
    if (winner >= 0) return;
    winner = index;
    final win = members[index], lose = members[1 - index];
    win._setPose('cheer', now);
    lose._setPose('sulk', now);
    win._reactionUntil = lose._reactionUntil = now + 3000;
    win.icon = 'trophy';
    win.iconUntil = now + 3000;
    for (final watcher in members.skip(2)) {
      watcher._setPose('cheer', now);
      watcher._reactionUntil = now + 1800;
    }
    win.confettiAt = now;
    lose.coinsAt = now;
    lose.coinsTo = win.id;
    _nativeBet(win, lose, now);
    end = now + 3400;
  }

  static void _nativeBet(_OfficeAgent winner, _OfficeAgent loser, int now) {
    final a = winner.wallet, b = loser.wallet;
    final bet = math.min(
      5,
      math.min((a['coins'] as num).toInt(), (b['coins'] as num).toInt()),
    );
    a['coins'] = (a['coins'] as num) + bet;
    b['coins'] = (b['coins'] as num) - bet;
    a['wins'] = ((a['wins'] as num?)?.toInt() ?? 0) + 1;
    b['losses'] = ((b['losses'] as num?)?.toInt() ?? 0) + 1;
    final av = Map<String, dynamic>.from(a['vs'] as Map? ?? {}),
        bv = Map<String, dynamic>.from(b['vs'] as Map? ?? {});
    final ascore = List<int>.from(
      av[loser.session.officeIdentity] as List? ?? [0, 0],
    );
    final bscore = List<int>.from(
      bv[winner.session.officeIdentity] as List? ?? [0, 0],
    );
    ascore[0]++;
    bscore[1]++;
    av[loser.session.officeIdentity] = ascore;
    bv[winner.session.officeIdentity] = bscore;
    a['vs'] = av;
    b['vs'] = bv;
    winner._saveWallet();
    loser._saveWallet();
  }
}

extension _NativeSocialScene on _OfficeWorldViewState {
  void _advanceGatherings(int now, _WorldMap map) {
    for (final group in _gatherings.toList()) {
      group.update(now);
      if (group.members.isEmpty) _gatherings.remove(group);
    }
    final candidates = _agents.values
        .where((a) => a.canSocial && a.child == null)
        .toList();
    if (candidates.length < 2) return;
    for (final host in candidates) {
      if (!host.canSocial || now < host.nextOutingAt - 1500) continue;
      final guests = candidates.where((a) => a != host && a.canSocial).toList();
      if (guests.isEmpty) continue;
      final kinds = [
        'tv',
        'videogame',
        'arcade',
        'pingpong',
        'kitchen',
        'talk',
        'rps',
        'mirror',
      ];
      final kind = kinds[host.outingCount++ % kinds.length];
      final accepted = [
        host,
        ...guests.take(
          kind == 'pingpong' || kind == 'tv' || kind == 'videogame' ? 3 : 1,
        ),
      ];
      final group = _NativeGathering(kind, accepted, now, map);
      final used = <String>{};
      var valid = true;
      for (final actor in accepted) {
        final options =
            (actor._workSpot?['outingSpots'] as List?)
                ?.whereType<Map>()
                .map((s) => s.cast<String, dynamic>())
                .toList() ??
            [];
        final pool = options
            .where(
              (s) => switch (kind) {
                'tv' ||
                'videogame' => ['sofa', 'beanbag', 'armchair'].contains(s['kind']),
                'arcade' => s['kind'] == 'arcade',
                'pingpong' => s['kind'] == 'pingpong',
                'mirror' => s['kind'] == 'sink' && s['areaId'] == 'core:banheiros',
                'kitchen' => s['kind'] == 'cafe_seat',
                _ => s['kind'] == 'bench' || s['kind'] == 'cafe_seat',
              },
            )
            .where(
              (s) =>
                  !used.contains('${s['x']}:${s['y']}') &&
                  !map.reservations.containsKey('${s['x']}:${s['y']}'),
            )
            .toList();
        if (pool.isEmpty) {
          valid = false;
          break;
        }
        final target = pool.first;
        used.add('${target['x']}:${target['y']}');
        group.targets[actor.id] = target;
      }
      if (!valid) continue;
      for (final actor in accepted) {
        actor.gathering = group;
        final t = group.targets[actor.id]!;
        map.reservations['${t['x']}:${t['y']}'] = actor.id;
        actor._setRoute(
          _OfficeAgent._path(
            map,
            actor.position,
            Offset((t['x'] as num).toDouble(), (t['y'] as num).toDouble()),
          ),
        );
        actor.emoji = '👋';
        actor.emojiUntil = now + 2000;
      }
      _gatherings.add(group);
      break;
    }
  }
}
