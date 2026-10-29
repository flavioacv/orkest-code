part of 'office_world_flutter_view.dart';

extension _NativeOfficeEffects on _WorldPainter {
  double get _unit => map.transform['scale']!;
  Color _color(Object? raw, [Color fallback = const Color(0xffd9dde2)]) {
    final value = int.tryParse(raw.toString().replaceFirst('#', ''), radix: 16);
    return value == null ? fallback : Color(0xff000000 | value);
  }

  Rect _rect(num x, num y, num w, num h) {
    final p = _sourcePoint(x.toDouble(), y.toDouble());
    return Rect.fromLTWH(p.dx, p.dy, w * _unit, h * _unit);
  }

  _NativeRoomTransition? _roomFor(String area) {
    if (!area.startsWith('workspace-')) return null;
    final slot = int.tryParse(area.substring(10));
    return transitions.values.where((r) => r.slot == slot).firstOrNull;
  }

  double _roomProgress(_NativeRoomTransition room, int time) {
    if (room.leftAt != null) {
      return (1 - (time - room.leftAt! - 2100) / 2200).clamp(0, 1);
    }
    return ((time - room.at) / 2600).clamp(0, 1);
  }

  double _back(double t) =>
      1 + 2.70158 * math.pow(t - 1, 3) + 1.70158 * math.pow(t - 1, 2);

  void _furniture(
    Canvas canvas,
    Map f,
    int state, {
    double scale = 1,
    bool front = false,
  }) {
    final frames = f['frames'] as List;
    var frame = atlas.furniture[frames[state.clamp(0, frames.length - 1)]];
    final theme = _theme(now());
    if (!front &&
        theme != 'none' &&
        ['plant_tall', 'plant_small'].contains(f['kind']) &&
        f['areaId'] != 'core:banheiros') {
      final first = (map.native['furniture'] as List)
          .where((p) => p['areaId'] == f['areaId'] && p['kind'] == 'plant_tall')
          .firstOrNull;
      if (f['kind'] == 'plant_small' || first?['id'] == f['id']) {
        frame =
            atlas
                .furniture['seasonal:${theme == 'christmas' ? (f['kind'] == 'plant_tall' ? 'tree' : 'gift') : 'pumpkin'}'] ??
            frame;
      }
    }
    if (frame is! Map) return;
    final data = frame[front ? 'front' : 'base'];
    if (data is! Map) return;
    final anchor = _sourcePoint(
      (f['ax'] as num).toDouble(),
      (f['ay'] as num).toDouble(),
    );
    final source = Rect.fromLTWH(
      (data['x'] as num).toDouble(),
      (data['y'] as num).toDouble(),
      (data['w'] as num).toDouble(),
      (data['h'] as num).toDouble(),
    );
    var x = anchor.dx - (data['ax'] as num) * _unit;
    var y = anchor.dy - (data['ay'] as num) * _unit;
    if (f['on'] == 'south') {
      y = anchor.dy - 7 * _unit - source.height * _unit / 2;
    }
    canvas.save();
    canvas.translate(anchor.dx, anchor.dy);
    canvas.scale(scale);
    canvas.translate(-anchor.dx, -anchor.dy);
    canvas.drawImageRect(
      atlas.furnitureImage,
      source,
      Rect.fromLTWH(x, y, source.width * _unit, source.height * _unit),
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.restore();
  }

  Rect? _detailRect(Map f, String kind) {
    final frame = atlas.furniture[(f['frames'] as List).first];
    if (frame is! Map || frame['base'] is! Map) return null;
    final base = frame['base'] as Map;
    final details = base['rects'];
    if (details is! Map || details[kind] is! Map) return null;
    final r = details[kind] as Map;
    var x = (f['ax'] as num) - (base['ax'] as num),
        y = (f['ay'] as num) - (base['ay'] as num);
    if (f['on'] == 'south') y = (f['ay'] as num) - 7 - (base['h'] as num) / 2;
    return _rect(
      x + (r['x'] as num),
      y + (r['y'] as num),
      r['w'] as num,
      r['h'] as num,
    );
  }

  void _paintRoomTransitions(Canvas canvas) {
    final time = now();
    if (map.native['extendedFrom'] case final num old) {
      final width = ((map.native['grid'] as Map)['w'] as num) * 16;
      canvas.drawRect(
        _rect(old, 192, width - old, 80),
        Paint()..color = const Color(0xffdce1e4),
      );
    }
    for (final raw in map.native['areas'] as List) {
      final area = raw as Map;
      if (area['kind'] != 'room') continue;
      final room = _roomFor(area['id'] as String);
      if (room == null) continue;
      final bounds = area['rect'] as Map;
      final x = (bounds['x'] as num) * 16, y = (bounds['y'] as num) * 16;
      final w = (bounds['w'] as num) * 16, h = (bounds['h'] as num) * 16;
      final p = _roomProgress(room, time);
      canvas.drawRect(
        _rect(x, y, w, h),
        Paint()..color = const Color(0xff78a65f),
      );
      if (p <= 0) continue;
      final assembling = room.leftAt == null;
      final floor = assembling
          ? (p / .4).clamp(0.0, 1.0)
          : ((p) / .3).clamp(0.0, 1.0);
      canvas.save();
      canvas.clipRect(_rect(x, y, w, h * floor));
      canvas.drawRect(
        _rect(x, y, w, h),
        Paint()
          ..color = _color(
            area['floorTint'],
            const Color(0xffdde2e6),
          ).withValues(alpha: 1),
      );
      for (var xx = 0; xx < w; xx += 16) {
        for (var yy = 0; yy < h; yy += 16) {
          canvas.drawRect(
            _rect(x + xx, y + yy, 16, 16),
            Paint()
              ..color = const Color(0x12818b91)
              ..style = PaintingStyle.stroke
              ..strokeWidth = _unit * .5,
          );
        }
      }
      for (final rug in area['rugs'] as List) {
        final r = rug as Map;
        canvas.drawRect(
          _rect(r['x'] as num, r['y'] as num, r['w'] as num, r['h'] as num),
          Paint()..color = _color(r['color']),
        );
      }
      canvas.restore();
      final walls = assembling
          ? ((p - .22) / .3).clamp(0.0, 1.0)
          : ((p - .28) / .25).clamp(0.0, 1.0);
      for (final rawWall in area['walls'] as List) {
        final wall = rawWall as Map;
        final hh = wall['kind'] == 'face'
            ? 32
            : wall['kind'] == 'south'
            ? 16
            : (wall['h'] as num).toDouble();
        final r = _rect(
          wall['x'] as num,
          (wall['y'] as num) + (1 - walls) * 12,
          wall['w'] as num,
          hh * walls,
        );
        canvas.drawRect(
          r,
          Paint()
            ..color = _color(
              (wall['style'] as Map)['base'],
            ).withValues(alpha: walls),
        );
        if (walls > .9) {
          canvas.drawRect(
            Rect.fromLTWH(r.left, r.top, r.width, 3 * _unit),
            Paint()..color = _color((wall['style'] as Map)['trim']),
          );
        }
        for (final door in wall['doorways'] as List? ?? []) {
          canvas.drawRect(
            _rect(
              door['x'] as num,
              (wall['y'] as num) + hh - 16,
              door['w'] as num,
              16,
            ),
            Paint()..color = _color(area['floorTint']),
          );
        }
      }
      final furniture =
          (map.native['furniture'] as List)
              .where((f) => f['areaId'] == area['id'])
              .toList()
            ..sort((a, b) => (a['ay'] as num).compareTo(b['ay'] as num));
      for (final f in furniture) {
        final order = (f['order'] as num).toDouble();
        final t = assembling
            ? ((p - (.48 + order * .36)) / .13).clamp(0.0, 1.0)
            : (((1 - p) - (1 - order) * .33) / .12).clamp(0.0, 1.0);
        var growth = assembling
            ? (t >= 1 ? 1.0 : math.max(0.0, _back(t)))
            : t >= 1
            ? 0.0
            : math.max(0.0, 1 - (2.70158 * t * t * t - 1.70158 * t * t));
        if (f['kind'] == 'sign') {
          growth = assembling
              ? ((p - .84) / .16).clamp(0.0, 1.0)
              : ((p - .85) / .15).clamp(0.0, 1.0);
        }
        if (growth > 0) _furniture(canvas, f as Map, 0, scale: growth);
      }
      if (p > .84) {
        final anchor = _sourcePoint((x + w / 2).toDouble(), (y - 5).toDouble());
        _badge(
          canvas,
          anchor.dx,
          anchor.dy,
          room.project.name,
          const Color(0xff303744),
          maxWidth: 220,
        );
      }
    }
  }

  void _paintDynamicFurniture(Canvas canvas) {
    final time = now();
    for (final raw in map.native['furniture'] as List) {
      final f = raw as Map, kind = f['kind'] as String;
      final room = _roomFor(f['areaId'] as String);
      if (room != null && _roomProgress(room, time) < .999) continue;
      final nearby = agents
          .where(
            (a) =>
                (a.position -
                        Offset(
                          (f['ax'] as num).toDouble(),
                          (f['ay'] as num).toDouble(),
                        ))
                    .distance <
                32,
          )
          .toList();
      if (['coffee_machine', 'toilet_stall', 'elevator'].contains(kind)) {
        final active = nearby.any(
          (a) => kind == 'elevator'
              ? (a.entering || a.leaving)
              : kind == 'toilet_stall'
              ? a._soloKind == 'stall' && a.outingState == 2
              : a.pose == 'use',
        );
        final state = kind == 'elevator'
            ? nearby.fold<int>(0, (v, a) {
                final age = a.entering
                    ? time - a._entryAt
                    : a._exitAt == null
                    ? -1
                    : time - a._exitAt!;
                final stage = age < 0 || age > 950
                    ? 0
                    : age < 180 || age > 650
                    ? 1
                    : 2;
                return math.max(v, stage);
              })
            : active
            ? 1
            : 0;
        _furniture(canvas, f, state);
        if (kind == 'coffee_machine' && active) {
          final p = _sourcePoint(
            (f['ax'] as num).toDouble(),
            (f['ay'] as num).toDouble() - 28,
          );
          for (var i = 0; i < 3; i++) {
            final phase = (time / 900 + i / 3) % 1;
            canvas.drawRect(
              Rect.fromLTWH(
                p.dx + math.sin(phase * 6 + i) * 2 * _unit,
                p.dy - phase * 10 * _unit,
                _unit,
                3 * _unit,
              ),
              Paint()
                ..color = const Color(0xfff5f4e9).withValues(alpha: 1 - phase),
            );
          }
        }
      }
      if (kind == 'desk') {
        final spot = (map.native['spots'] as List)
            .where((s) => s['id'] == f['seatSpot'])
            .firstOrNull;
        final owner = spot == null
            ? null
            : agents
                  .where(
                    (a) =>
                        a._workSpot?['x'] == spot['x'] &&
                        a._workSpot?['y'] == spot['y'] &&
                        a.atHome,
                  )
                  .firstOrNull;
        final latest = owner?.session.officeStatusHistory.lastOrNull;
        final mode = owner == null
            ? 'standby'
            : owner.mode == 'shell'
            ? 'progress'
            : owner.mode == 'waiting'
            ? 'alert'
            : owner.mode == 'idle'
            ? 'idle'
            : OfficeAnimationRules.screenMode(latest?.activityKind);
        for (final key in ['screen', 'screen2']) {
          final rect = _detailRect(f, key);
          if (rect != null) {
            _screen(
              canvas,
              rect,
              mode,
              time,
              _OfficeAgent._hash(f['id'] as String),
            );
          }
        }
      } else if (kind == 'arcade') {
        final rect = _detailRect(f, 'screen');
        if (rect != null) _screen(canvas, rect, 'game', time, 3);
      } else if (kind == 'tv') {
        final rect = _detailRect(f, 'tv');
        if (rect != null) {
          final group = gatherings
              .where((g) => g.kind == 'tv' || g.kind == 'videogame')
              .firstOrNull;
          final program = group == null
              ? (time ~/ 9000) % 3
              : _OfficeAgent._hash(group.members.firstOrNull?.id ?? '') % 3;
          _screen(
            canvas,
            rect,
            group?.kind == 'videogame'
                ? 'game'
                : program == 0
                ? 'football'
                : program == 1
                ? 'show'
                : 'cartoon',
            time,
            1,
          );
        }
      } else if (kind == 'whiteboard') {
        final rect = _detailRect(f, 'board');
        if (rect != null) {
          canvas.drawRect(rect, Paint()..color = const Color(0xffeef3e8));
          final slot = int.tryParse(
            (f['areaId'] as String).replaceFirst('workspace-', ''),
          );
          final tasks = agents
              .where((a) => a.slot == slot && a.child == null)
              .expand((a) => a.session.officeTasks)
              .take(24)
              .toList();
          for (var i = 0; i < tasks.length; i++) {
            final task = tasks[i];
            final col = task['status'] == 'completed'
                ? 2
                : task['status'] == 'in_progress'
                ? 1
                : 0;
            final inCol = tasks
                .take(i)
                .where((t) => t['status'] == task['status'])
                .length;
            canvas.drawRect(
              Rect.fromLTWH(
                rect.left + 2 * _unit + col * rect.width / 3,
                rect.top + (2 + inCol * 3) * _unit,
                7 * _unit,
                2 * _unit,
              ),
              Paint()
                ..color = col == 2
                    ? const Color(0xff9ed397)
                    : col == 1
                    ? const Color(0xffffd476)
                    : const Color(0xffa4c9e5),
            );
          }
        }
      } else if (kind == 'clock') {
        final rect = _detailRect(f, 'face');
        if (rect != null) {
          final date = DateTime.fromMillisecondsSinceEpoch(time),
              c = rect.center;
          canvas.drawCircle(
            c,
            rect.width * .43,
            Paint()..color = const Color(0xfff4f0e4),
          );
          for (final pair in [
            (date.hour % 12 + date.minute / 60, 12.0, .28),
            (date.minute + date.second / 60, 60.0, .38),
            (date.second.toDouble(), 60.0, .42),
          ]) {
            final a = pair.$1 / pair.$2 * math.pi * 2 - math.pi / 2;
            canvas.drawLine(
              c,
              c + Offset(math.cos(a), math.sin(a)) * rect.width * pair.$3,
              Paint()
                ..color = const Color(0xff374353)
                ..strokeWidth = _unit * .7,
            );
          }
        }
      } else if (kind == 'window') {
        final rect = _detailRect(f, 'glass');
        if (rect != null) {
          _window(canvas, rect, time, _OfficeAgent._hash(f['id'] as String));
        }
      } else if (kind == 'mirror') {
        final rect = _detailRect(f, 'glass');
        if (rect != null) {
          final person = nearby.firstOrNull;
          if (person != null) {
            final sprite = atlas.sprites['${person.look}:up:stand:none:0:0'];
            if (sprite != null) {
              canvas.save();
              canvas.clipRect(rect);
              canvas.drawImageRect(
                atlas.image,
                sprite.rect,
                Rect.fromCenter(
                  center: rect.center,
                  width: sprite.rect.width * _unit * .55,
                  height: sprite.rect.height * _unit * .55,
                ),
                Paint()
                  ..color = const Color(0x99ffffff)
                  ..filterQuality = FilterQuality.none,
              );
              canvas.restore();
            }
          }
        }
      }
    }
  }

  void _screen(Canvas canvas, Rect r, String mode, int time, int seed) {
    canvas.save();
    canvas.clipRect(r);
    canvas.drawRect(
      r,
      Paint()
        ..color = mode == 'off'
            ? const Color(0xff172126)
            : mode == 'football'
            ? const Color(0xff3f9a4a)
            : mode == 'game'
            ? const Color(0xff292957)
            : const Color(0xff11243a),
    );
    final p = (time % 7000) / 7000;
    if (mode == 'football') {
      canvas.drawLine(
        Offset(r.center.dx, r.top),
        Offset(r.center.dx, r.bottom),
        Paint()
          ..color = const Color(0xffcfeccd)
          ..strokeWidth = _unit,
      );
      canvas.drawCircle(
        r.center,
        3 * _unit,
        Paint()
          ..style = PaintingStyle.stroke
          ..color = const Color(0xffcfeccd)
          ..strokeWidth = _unit * .5,
      );
      final right = (time ~/ 7000) % 2 == 0;
      final x =
          r.center.dx +
          (right ? 1 : -1) * (r.width / 2 - 2 * _unit) * (p / .8).clamp(0, 1);
      canvas.drawRect(
        Rect.fromLTWH(
          x,
          r.center.dy + math.sin(p * math.pi * 3) * _unit,
          2 * _unit,
          2 * _unit,
        ),
        Paint()..color = const Color(0xffffffff),
      );
      if (p >= .8) {
        canvas.drawRect(
          r.deflate(_unit),
          Paint()..color = const Color(0x66ffffff),
        );
      }
    } else if (mode == 'game') {
      for (var i = 0; i < 5; i++) {
        final x = r.left + (time / 400 + i * 7 + seed) % math.max(1, r.width);
        canvas.drawRect(
          Rect.fromLTWH(
            x,
            r.top + (i % 3 + 1) * 3 * _unit,
            3 * _unit,
            2 * _unit,
          ),
          Paint()
            ..color = i % 2 == 0
                ? const Color(0xfffaad63)
                : const Color(0xff7cdcd2),
        );
      }
    } else if (mode == 'show' || mode == 'cartoon') {
      for (var i = 0; i < 2; i++) {
        canvas.drawCircle(
          Offset(
            r.left + r.width * (i == 0 ? 0.3 : 0.7),
            r.center.dy + math.sin(time / 350 + i) * _unit,
          ),
          3 * _unit,
          Paint()
            ..color = i == 0
                ? const Color(0xffe9aa87)
                : const Color(0xffa79be5),
        );
      }
    } else if (mode == 'progress') {
      canvas.drawRect(
        Rect.fromLTWH(
          r.left + _unit,
          r.center.dy,
          r.width - 2 * _unit,
          2 * _unit,
        ),
        Paint()..color = const Color(0xff304256),
      );
      canvas.drawRect(
        Rect.fromLTWH(
          r.left + _unit + (time / 100 % (math.max(1, r.width - 6 * _unit))),
          r.center.dy,
          4 * _unit,
          2 * _unit,
        ),
        Paint()..color = const Color(0xff78d3d4),
      );
    } else if (mode == 'alert') {
      canvas.drawRect(
        r,
        Paint()
          ..color = Color.lerp(
            const Color(0xff5f1d29),
            const Color(0xffab3c40),
            (math.sin(time / 200) + 1) / 2,
          )!,
      );
      canvas.drawRect(
        Rect.fromCenter(center: r.center, width: _unit, height: 4 * _unit),
        Paint()..color = const Color(0xffffdeaf),
      );
    } else if (mode == 'idle' || mode == 'standby') {
      final x = r.left + (time / 400 + seed) % math.max(1, r.width);
      canvas.drawRect(
        Rect.fromLTWH(x, r.center.dy, 2 * _unit, _unit),
        Paint()..color = const Color(0xff7aa8c0),
      );
    } else if (mode != 'off') {
      final color = mode == 'terminal'
          ? const Color(0xff79daa1)
          : mode == 'code'
          ? const Color(0xff95b8f5)
          : mode == 'chat'
          ? const Color(0xffcba6e8)
          : const Color(0xffb5d1db);
      for (var i = 0; i < 5; i++) {
        final y =
            r.top +
            ((i * 3 + (time ~/ 500) % 3) % math.max(1, r.height / _unit)) *
                _unit;
        final width = math.min(
          r.width - 2 * _unit,
          (3 + (seed + i * 13) % 8) * _unit,
        );
        canvas.drawRect(
          Rect.fromLTWH(r.left + _unit, y, math.max(1, width), _unit),
          Paint()..color = color,
        );
      }
    }
    canvas.restore();
  }

  String _theme(int time) {
    if (settings.officeTheme != 'auto') return settings.officeTheme;
    final month = DateTime.fromMillisecondsSinceEpoch(time).month;
    return month == 10
        ? 'halloween'
        : month >= 11
        ? 'christmas'
        : 'none';
  }

  String _season(int time) {
    final s = settings.officeSeason;
    if (s == 'spring' || s == 'summer' || s == 'autumn' || s == 'winter') {
      return s;
    }
    final month = DateTime.fromMillisecondsSinceEpoch(time).month;
    if (s == 'auto_north') {
      if (month == 12 || month <= 2) return 'winter';
      if (month <= 5) return 'spring';
      if (month <= 8) return 'summer';
      return 'autumn';
    }
    if (month == 12 || month <= 2) return 'summer';
    if (month <= 5) return 'autumn';
    if (month <= 8) return 'winter';
    return 'spring';
  }

  void _paintExteriorSeason(Canvas canvas, int time) {
    final season = _season(time);
    for (var i = 0; i < 28; i++) {
      final cycle = (time / 1000 + i * 0.41) % 3.2;
      final px =
          ((i * 73) % 100) / 100 * map.width +
          math.sin(time / 420 + i) * 6 * _unit;
      final py = (cycle / 3.2) * map.height;
      final inBuilding =
          map.core.any(
            (r) => _rect(
              r['x']!,
              r['y']!,
              r['w']!,
              r['h']!,
            ).contains(Offset(px, py)),
          ) ||
          map.rooms.any(
            (r) => _rect(
              r['x']!,
              r['y']!,
              r['w']!,
              r['h']!,
            ).contains(Offset(px, py)),
          );
      if (inBuilding) continue;
      final color = switch (season) {
        'winter' => const Color(0xddeef5fc),
        'autumn' =>
          i % 2 == 0 ? const Color(0xddd4652f) : const Color(0xdde89d38),
        'spring' =>
          i % 2 == 0 ? const Color(0xddff94be) : const Color(0xddffe97d),
        _ => const Color(0xaaffe680),
      };
      canvas.drawRect(
        Rect.fromLTWH(px, py, (i % 2 + 1) * _unit, _unit),
        Paint()..color = color,
      );
    }
  }

  void _window(Canvas canvas, Rect r, int time, int seed) {
    final hour = DateTime.fromMillisecondsSinceEpoch(time).hour;
    final night =
        settings.officeDaylight == 'night' ||
        (settings.officeDaylight == 'auto' && (hour < 6 || hour >= 19));
    canvas.save();
    canvas.clipRect(r);
    canvas.drawRect(
      r,
      Paint()
        ..color = night ? const Color(0xff1c2d51) : const Color(0xffa7d9ef),
    );
    if (night) {
      for (var i = 0; i < 8; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            r.left + (seed + i * 7) % math.max(1, r.width),
            r.top + (seed + i * 3) % math.max(1, r.height * .7),
            _unit,
            _unit,
          ),
          Paint()
            ..color = const Color(
              0xffffffff,
            ).withValues(alpha: .4 + .5 * (math.sin(time / 750 + i) + 1) / 2),
        );
      }
    } else {
      for (var i = 0; i < 2; i++) {
        final x = r.left + (time / 900 + i * 14 + seed) % math.max(1, r.width);
        canvas.drawRect(
          Rect.fromLTWH(x, r.top + (i * 4 + 2) * _unit, 6 * _unit, _unit),
          Paint()..color = const Color(0xaaffffff),
        );
      }
    }
    if (_theme(time) == 'christmas') {
      for (var i = 0; i < 12; i++) {
        canvas.drawRect(
          Rect.fromLTWH(
            r.left + (seed + i * 17) % math.max(1, r.width),
            r.top + (time / 180 + i * 11) % math.max(1, r.height),
            _unit,
            _unit,
          ),
          Paint()..color = const Color(0xffedf3f3),
        );
      }
    }
    canvas.restore();
  }

  void _paintOfficeEffects(Canvas canvas) {
    final time = now();
    _paintExteriorSeason(canvas, time);
    for (final room in transitions.values) {
      if (room.slot >= map.rooms.length) continue;
      final source = map.rooms[room.slot];
      final r = _rect(source['x']!, source['y']!, source['w']!, source['h']!);
      final fx = OfficeRoomEffectsManager.instance.getEffect(
        room.project.id,
        time,
      );
      if (fx != null && fx.kind == OfficeRoomEffectKind.party) {
        for (var i = 0; i < 36; i++) {
          final t = ((time - fx.at) / 1000 + i * .113) % 3;
          final x =
              r.left +
              ((i * 37) % 100) / 100 * r.width +
              math.sin(time / 100 + i) * 2 * _unit;
          final y = r.top + t / 3 * r.height;
          canvas.drawRect(
            Rect.fromLTWH(x, y, (i % 2 + 1) * _unit, _unit),
            Paint()..color = _confetti(i),
          );
        }
      } else if (fx != null) {
        canvas.drawRect(
          r,
          Paint()
            ..color = const Color(
              0xffd22235,
            ).withValues(alpha: .08 + .12 * (math.sin(time / 120) + 1) / 2),
        );
        for (final x in [r.left + 8 * _unit, r.right - 8 * _unit]) {
          final c = Offset(x, r.top + 12 * _unit);
          canvas.drawArc(
            Rect.fromCircle(center: c, radius: 22 * _unit),
            time / 130,
            1.2,
            true,
            Paint()..color = const Color(0x44ff3749),
          );
          canvas.drawCircle(
            c,
            2 * _unit,
            Paint()..color = const Color(0xffef334b),
          );
        }
      }
      if (fx != null) {
        _badge(
          canvas,
          r.center.dx,
          r.top + 24 * _unit,
          localizedOfficeVcsSummary(fx.text),
          fx.kind == OfficeRoomEffectKind.party
              ? const Color(0xee7c5728)
              : const Color(0xee842e39),
          maxWidth: r.width - 12,
        );
      }
      final level = room.darkAt != null
          ? OfficeAnimationRules.lightLevel(false, time - room.darkAt!)
          : room.lightAt == null
          ? 0.0
          : OfficeAnimationRules.lightLevel(true, time - room.lightAt!);
      if (level < .999) {
        canvas.drawRect(
          r,
          Paint()
            ..color = const Color(
              0xff111b2b,
            ).withValues(alpha: (1 - level) * .7),
        );
      }
    }
    for (final actor in agents) {
      if (actor.gone || actor.alpha < .05) continue;
      final foot = _sourcePoint(actor.position.dx, actor.position.dy);
      final head = foot - Offset(0, 25 * _unit);
      final roomEffect = OfficeRoomEffectsManager.instance.getEffect(
        actor.projectId,
        time,
      );
      if (roomEffect?.kind == OfficeRoomEffectKind.alarm &&
          roomEffect?.agentId == actor.id) {
        _badge(
          canvas,
          head.dx,
          head.dy - 20 * _unit,
          '!',
          const Color(0xeeab2838),
          maxWidth: 24,
        );
      }
      if (actor.pose == 'wait' && actor.held == 'popcorn') {
        final t = (time % 800) / 800;
        canvas.drawRect(
          Rect.fromLTWH(
            head.dx + _unit,
            foot.dy - (10 + 14 * 4 * t * (1 - t)) * _unit,
            2 * _unit,
            2 * _unit,
          ),
          Paint()..color = const Color(0xfffff3ca),
        );
      }
      if (actor.icon == 'storm') {
        for (var i = 0; i < 5; i++) {
          final t = (time / 300 + i * .2) % 1;
          canvas.drawRect(
            Rect.fromLTWH(
              head.dx + (i - 2) * 2 * _unit,
              head.dy + (-4 + t * 13) * _unit,
              _unit,
              2 * _unit,
            ),
            Paint()..color = const Color(0xff7cc4ff),
          );
        }
      }
      if (actor.mode == 'shell' &&
          actor.shellStage != null &&
          [
            OfficeShellStage.cobweb,
            OfficeShellStage.nap,
          ].contains(actor.shellStage)) {
        final size = time - actor.shellSince >= 1200000 ? 2.0 : 1.0;
        _icon(
          canvas,
          'cobweb',
          head + Offset(9 * _unit, 4 * _unit),
          scale: size,
        );
      }
      if (time >= actor.confettiAt &&
          time - actor.confettiAt < 2200 &&
          actor.confettiAt > 0) {
        final t = (time - actor.confettiAt) / 1000;
        for (var i = 0; i < 32; i++) {
          final a = -math.pi / 2 + (i % 17 - 8) / 7;
          final speed = (30 + i % 7 * 8) * _unit;
          final p =
              head +
              Offset(
                math.cos(a) * speed * t,
                math.sin(a) * speed * t + 75 * _unit * t * t,
              );
          canvas.drawRect(
            Rect.fromLTWH(p.dx, p.dy, (i % 2 + 1) * _unit, _unit),
            Paint()
              ..color = _confetti(
                i,
              ).withValues(alpha: (1 - t / 2.2).clamp(0, 1)),
          );
        }
      }
      if (actor.sparkleAt > 0 && time - actor.sparkleAt < 1500) {
        final t = (time - actor.sparkleAt) / 1500;
        for (var i = 0; i < 9; i++) {
          final a = i / 9 * math.pi * 2;
          final p =
              head +
              Offset(
                math.cos(a) * 9 * _unit,
                math.sin(a) * 7 * _unit - t * 10 * _unit,
              );
          canvas.drawLine(
            p - Offset(_unit, 0),
            p + Offset(_unit, 0),
            Paint()..color = const Color(0xffffffb8),
          );
          canvas.drawLine(
            p - Offset(0, _unit),
            p + Offset(0, _unit),
            Paint()..color = const Color(0xffffffb8),
          );
        }
      }
      if (actor.coinsAt > 0 && time - actor.coinsAt < 1100) {
        final to = agents.where((a) => a.id == actor.coinsTo).firstOrNull;
        if (to != null) {
          final end = _sourcePoint(to.position.dx, to.position.dy - 18);
          for (var i = 0; i < 7; i++) {
            final t = ((time - actor.coinsAt - i * 50) / 750).clamp(0.0, 1.0);
            final p =
                Offset.lerp(head, end, t)! -
                Offset(0, 4 * t * (1 - t) * 18 * _unit);
            canvas.drawOval(
              Rect.fromCenter(
                center: p,
                width: (math.sin(time / 70 + i).abs() * 2 + 1) * _unit,
                height: 3 * _unit,
              ),
              Paint()..color = const Color(0xffffcf3a),
            );
          }
        }
      }
      if (actor.coinRewardAt > 0 && time - actor.coinRewardAt < 1900) {
        final t = (time - actor.coinRewardAt) / 1900;
        _badge(
          canvas,
          head.dx,
          head.dy - (8 + 10 * t) * _unit,
          '+🪙${actor.coinDelta}',
          const Color(0xdd73521a),
          maxWidth: 80,
        );
      }
      if (settings.officeBubbles != 'none' && time < actor.emojiUntil) {
        _badge(
          canvas,
          head.dx,
          head.dy - 9 * _unit,
          actor.emoji,
          const Color(0xeef8f4e9),
          maxWidth: 100,
        );
      }
      final activity = actor.child == null
          ? actor.session.officeStatusHistory.lastOrNull
          : null;
      final recent =
          activity != null && time - activity.at.millisecondsSinceEpoch < 4000;
      if (settings.officeBubbles != 'none' &&
          !actor.leaving &&
          (actor.mode == 'waiting' ||
              (actor.mode != 'shell' &&
                  (recent ||
                      settings.officeBubbles == 'all' &&
                          actor.mode == 'working')))) {
        final label = localizedOfficeActivitySummary(activity);
        if (label != null && label.isNotEmpty) {
          _badge(
            canvas,
            head.dx,
            head.dy - 13 * _unit,
            label,
            actor.mode == 'waiting'
                ? const Color(0xee815a24)
                : const Color(0xee253645),
            maxWidth: 200,
          );
        }
      }
      if (actor.mode == 'shell' && settings.officeBubbles != 'none') {
        final age = ((time - actor.shellSince) / 1000).floor();
        if (settings.officeBubbles == 'all' || age < 6 || age % 30 < 4) {
          _badge(
            canvas,
            head.dx,
            head.dy - 10 * _unit,
            '⏳ ${age < 60 ? '$age s' : '${age ~/ 60} min'}',
            const Color(0xdd253645),
            maxWidth: 140,
          );
        }
      }
      if (actor.mode == 'waiting') {
        canvas.drawCircle(
          foot,
          7 * _unit * (1 + .08 * math.sin(time / 220)),
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = _unit
            ..color = const Color(0xffffbe63),
        );
      }
    }
    for (final group in gatherings.where(
      (g) => g.kind == 'pingpong' && g.start > 0 && g.members.length >= 2,
    )) {
      final a = _sourcePoint(
        group.members[0].position.dx,
        group.members[0].position.dy - 10,
      );
      final b = _sourcePoint(
        group.members[1].position.dx,
        group.members[1].position.dy - 10,
      );
      final t = (time % 1100) / 1100;
      final u = t < .5 ? t * 2 : 2 - t * 2;
      final ball =
          Offset.lerp(a, b, u)! - Offset(0, math.sin(u * math.pi) * 6 * _unit);
      canvas.drawCircle(ball, _unit, Paint()..color = const Color(0xfffff4db));
    }
    final date = DateTime.fromMillisecondsSinceEpoch(time);
    final night =
        settings.officeDaylight == 'night' ||
        (settings.officeDaylight == 'auto' &&
            (date.hour < 6 || date.hour >= 19));
    if (night) {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, map.width, map.height),
        Paint()..color = const Color(0x24333b69),
      );
    }
  }

  Color _confetti(int i) => const [
    Color(0xffff4d6d),
    Color(0xffffb11f),
    Color(0xffffe14d),
    Color(0xff3ddc84),
    Color(0xff3fa7ff),
    Color(0xffb06bff),
    Color(0xffff7ad9),
  ][i % 7];
  void _icon(Canvas canvas, String name, Offset anchor, {double scale = 1}) {
    final sprite = atlas.icons[name];
    if (sprite == null) return;
    canvas.drawImageRect(
      atlas.iconsImage,
      sprite.rect,
      Rect.fromLTWH(
        anchor.dx - sprite.ax * _unit * scale,
        anchor.dy - sprite.ay * _unit * scale,
        sprite.rect.width * _unit * scale,
        sprite.rect.height * _unit * scale,
      ),
      Paint()..filterQuality = FilterQuality.none,
    );
  }
}
