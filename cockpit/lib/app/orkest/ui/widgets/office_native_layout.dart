part of 'office_world_flutter_view.dart';

// Baked scenery is a cache, not an agent/workspace limit. Additional columns
// reuse matched room geometry and sprites while extending the walk grid.
Map<String, dynamic> _nativeLayout(
  Map<String, dynamic> source,
  Map details,
  int count,
) {
  final native = (jsonDecode(jsonEncode(details)) as Map)
      .cast<String, dynamic>();
  final entry = (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  entry['native'] = native;
  final oldCount = source['count'] as int;
  if (count <= oldCount) {
    _assignNativeOutings(entry);
    return entry;
  }
  final oldGrid = native['grid'] as Map;
  final oldW = oldGrid['w'] as int, height = oldGrid['h'] as int;
  final oldCells = (oldGrid['cells'] as List).cast<int>();
  final cols = 2 + (count / 2).ceil(), width = cols * 16;
  final cells = List<int>.filled(width * height, 0);
  for (var y = 0; y < height; y++) {
    for (var x = 0; x < oldW; x++) {
      cells[y * width + x] = oldCells[y * oldW + x];
    }
  }
  for (var y = 12; y < 17; y++) {
    for (var x = oldW; x < width; x++) {
      cells[y * width + x] = 1;
    }
  }
  final furniture = (native['furniture'] as List).cast<Map>();
  final areas = (native['areas'] as List).cast<Map>();
  final spots = (native['spots'] as List).cast<Map>();
  final rooms = (entry['rooms'] as List).cast<Map>();
  final work = (entry['workSpots'] as List).cast<List>();
  final doors = (entry['doors'] as List).cast<Map>();
  Map clone(Map value) => (jsonDecode(jsonEncode(value)) as Map);
  for (var slot = oldCount; slot < count; slot++) {
    final template = slot % 2;
    final oldId = 'workspace-$template', newId = 'workspace-$slot';
    final dx = (slot ~/ 2) * 256;
    Map identifiers(Map value) {
      for (final key in [
        'id',
        'areaId',
        'deskId',
        'furnitureId',
        'seatSpot',
        'group',
      ]) {
        if (value[key] is String) {
          value[key] = (value[key] as String).replaceAll(oldId, newId);
        }
      }
      return value;
    }

    final room = clone(rooms[template]);
    room['x'] = (room['x'] as num) + dx;
    rooms.add(room);
    final area = clone(areas.firstWhere((a) => a['id'] == oldId));
    area['id'] = newId;
    (area['rect'] as Map)['x'] = ((area['rect'] as Map)['x'] as num) + dx / 16;
    for (final field in ['walls', 'floors', 'rugs']) {
      for (final element in area[field] as List) {
        element['x'] = (element['x'] as num) + dx;
        for (final doorway in element['doorways'] as List? ?? []) {
          doorway['x'] = (doorway['x'] as num) + dx;
        }
      }
    }
    areas.add(area);
    for (final original
        in furniture.where((f) => f['areaId'] == oldId).toList()) {
      final f = identifiers(clone(original));
      f['ax'] = (f['ax'] as num) + dx;
      if (f['tx'] != null) f['tx'] = (f['tx'] as num) + dx / 16;
      if (f['cx'] != null) f['cx'] = (f['cx'] as num) + dx;
      furniture.add(f);
    }
    for (final original in spots.where((s) => s['areaId'] == oldId).toList()) {
      final spot = identifiers(clone(original));
      spot['x'] = (spot['x'] as num) + dx;
      spot['tx'] = (spot['tx'] as num) + dx / 16;
      spots.add(spot);
    }
    final desks = <Map>[];
    for (final original in work[template]) {
      final desk = clone(original as Map);
      desk['x'] = (desk['x'] as num) + dx;
      for (final point in desk['pathToDoor'] as List) {
        point['x'] = (point['x'] as num) + dx;
      }
      desks.add(desk);
    }
    work.add(desks);
    final door = clone(doors[template]);
    door['x'] = (door['x'] as num) + dx;
    (door['outside'] as Map)['x'] = ((door['outside'] as Map)['x'] as num) + dx;
    doors.add(door);
    final y0 = template == 0 ? 0 : 17;
    final targetX = 32 + (slot ~/ 2) * 16;
    for (var y = y0; y < y0 + 12; y++) {
      for (var x = 0; x < 16; x++) {
        cells[y * width + targetX + x] = oldCells[y * oldW + 32 + x];
      }
    }
  }
  native['grid'] = {'w': width, 'h': height, 'cells': cells};
  native['furniture'] = furniture;
  native['areas'] = areas;
  native['spots'] = spots;
  native['extendedFrom'] = oldW * 16;
  entry['count'] = count;
  entry['rooms'] = rooms;
  entry['workSpots'] = work;
  entry['doors'] = doors;
  entry['width'] =
      (entry['width'] as num) +
      (width - oldW) * 16 * (entry['transform'] as Map)['scale'];
  _assignNativeOutings(entry);
  return entry;
}

void _assignNativeOutings(Map<String, dynamic> entry) {
  final spots = (entry['native'] as Map)['spots'] as List;
  final work = entry['workSpots'] as List;
  const leisure = {
    'arcade',
    'armchair',
    'beanbag',
    'bench',
    'cafe_seat',
    'coffee',
    'fridge',
    'pingpong',
    'shelf',
    'sink',
    'snack',
    'sofa',
    'stall',
    'water',
    'window',
  };
  for (var slot = 0; slot < work.length; slot++) {
    for (final desk in work[slot]) {
      desk['outingSpots'] = spots
          .where(
            (s) =>
                leisure.contains(s['kind']) &&
                ((s['areaId'] as String).startsWith('core:') ||
                    s['areaId'] == 'workspace-$slot'),
          )
          .map((s) => {...s, 'path': <dynamic>[]})
          .toList();
    }
  }
}
