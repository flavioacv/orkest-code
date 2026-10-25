import 'dart:convert';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/ui/session/pane_item.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_agent_profile_dialog.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Displays the Habblaud office layout with Orkest workspaces and sessions.
class OfficeWorldFlutterView extends StatefulWidget {
  const OfficeWorldFlutterView({
    super.key,
    required this.projects,
    required this.sessions,
    required this.labels,
    required this.onOpenSession,
    required this.onRenameSession,
  });

  final List<Project> projects;
  final List<PaneItem> sessions;
  final OfficeWorldLabels labels;
  final ValueChanged<TerminalSession> onOpenSession;
  final void Function(TerminalSession session, String name) onRenameSession;

  @override
  State<OfficeWorldFlutterView> createState() => _OfficeWorldViewState();
}

class OfficeWorldLabels {
  const OfficeWorldLabels({
    required this.reception,
    required this.cafe,
    required this.restrooms,
    required this.lounge,
    required this.working,
    required this.waiting,
    required this.idle,
  });

  final String reception;
  final String cafe;
  final String restrooms;
  final String lounge;
  final String working;
  final String waiting;
  final String idle;
}

class _OfficeFrameClock extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _OfficeWorldViewState extends State<OfficeWorldFlutterView> {
  // The pixel scene does not need a 60 Hz full-scene repaint. Thirty frames
  // per second keeps movement fluid while leaving more time for terminal UI.
  late final Timer _clock = Timer.periodic(
    const Duration(milliseconds: 33),
    (_) => _onClock(),
  );
  final _OfficeFrameClock _frameClock = _OfficeFrameClock();
  late final Future<List<Map<String, dynamic>>> _manifestFuture =
      _loadManifest();
  late final Future<_CharacterAtlas> _charactersFuture = _loadCharacters();
  final Map<int, Future<_WorldMap>> _mapFutures = {};
  final Map<int, _WorldMap> _loadedMaps = {};
  final Map<String, _OfficeAgent> _agents = {};
  final List<ui.Image> _images = [];
  int _lastTickMs = DateTime.now().millisecondsSinceEpoch;
  _WorldMap? _currentMap;
  List<Project> _baseProjects = const [];
  List<TerminalSession> _currentSessions = const [];

  Future<List<Map<String, dynamic>>> _loadManifest() async {
    final manifestBytes = await rootBundle.load(
      'assets/habblaud_art/worlds/manifest.json',
    );
    final entries =
        jsonDecode(
              utf8.decode(
                manifestBytes.buffer.asUint8List(
                  manifestBytes.offsetInBytes,
                  manifestBytes.lengthInBytes,
                ),
              ),
            )
            as List<dynamic>;
    return entries.cast<Map<String, dynamic>>();
  }

  Future<_WorldMap> _loadMap(int requestedCount) async {
    final entries = await _manifestFuture;
    final index = requestedCount.clamp(0, entries.length - 1);
    final entry =
        jsonDecode(
              await rootBundle.loadString(
                'assets/habblaud_art/worlds/${entries[index]['file']}',
              ),
            )
            as Map<String, dynamic>;
    final bytes = await rootBundle.load(
      'assets/habblaud_art/worlds/world-${entry['count']}.png',
    );
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
      targetWidth: entry['width'] as int,
      targetHeight: entry['height'] as int,
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    _images.add(image);
    final map = _WorldMap.fromJson(entry, image);
    _loadedMaps[requestedCount] = map;
    return map;
  }

  Future<_CharacterAtlas> _loadCharacters() async {
    final metadataBytes = await rootBundle.load(
      'assets/habblaud_art/characters.json',
    );
    final metadata =
        jsonDecode(
              utf8.decode(
                metadataBytes.buffer.asUint8List(
                  metadataBytes.offsetInBytes,
                  metadataBytes.lengthInBytes,
                ),
              ),
            )
            as Map<String, dynamic>;
    final bytes = await rootBundle.load('assets/habblaud_art/characters.png');
    final codec = await ui.instantiateImageCodec(
      bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    final image = (await codec.getNextFrame()).image;
    codec.dispose();
    _images.add(image);
    final iconBytes = await rootBundle.load('assets/habblaud_art/icons.png');
    final iconCodec = await ui.instantiateImageCodec(
      iconBytes.buffer.asUint8List(
        iconBytes.offsetInBytes,
        iconBytes.lengthInBytes,
      ),
    );
    final iconsImage = (await iconCodec.getNextFrame()).image;
    iconCodec.dispose();
    _images.add(iconsImage);
    final carsMetadataBytes = await rootBundle.load(
      'assets/habblaud_art/cars.json',
    );
    final carsMetadata =
        jsonDecode(
              utf8.decode(
                carsMetadataBytes.buffer.asUint8List(
                  carsMetadataBytes.offsetInBytes,
                  carsMetadataBytes.lengthInBytes,
                ),
              ),
            )
            as Map<String, dynamic>;
    final carsBytes = await rootBundle.load('assets/habblaud_art/cars.png');
    final carsCodec = await ui.instantiateImageCodec(
      carsBytes.buffer.asUint8List(
        carsBytes.offsetInBytes,
        carsBytes.lengthInBytes,
      ),
    );
    final carsImage = (await carsCodec.getNextFrame()).image;
    carsCodec.dispose();
    _images.add(carsImage);
    return _CharacterAtlas.fromJson(
      metadata,
      image,
      iconsImage,
      carsMetadata,
      carsImage,
    );
  }

  List<Project> _projectsForScene(List<Project> projects) {
    final result = projects.toList();
    for (final actor in _agents.values.where((actor) => actor.leaving)) {
      if (result.any((project) => project.id == actor.project.id)) continue;
      result.insert(actor.slot.clamp(0, result.length), actor.project);
    }
    return result;
  }

  void _syncAgents(
    List<Project> projects,
    List<TerminalSession> sessions,
    _WorldMap map, {
    bool notify = true,
  }) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final projectSlots = <String, int>{
      for (var i = 0; i < projects.length; i++) projects[i].id: i,
    };
    final sessionsById = {for (final session in sessions) session.id: session};
    final activeIds = <String>{};
    final usedDesks = <String, int>{};
    for (final actor in _agents.values) {
      if (actor.leaving) continue;
      usedDesks[actor.projectId] = (usedDesks[actor.projectId] ?? 0) + 1;
    }

    var changed = false;
    for (final actor in _agents.values.toList()) {
      if (actor.leaving) continue;
      final session = sessionsById[actor.id];
      final slot = projectSlots[actor.projectId];
      if (session == null || slot == null) {
        actor.beginLeaving(map, now);
        changed = true;
        continue;
      }
      actor.project = projects[slot];
      actor.slot = slot;
      actor.session = session;
      if (!session.hasOfficeAgentPresence) {
        actor.missingAt ??= now;
        if (now - actor.missingAt! >= _OfficeAgent.missingGraceMs) {
          actor.beginLeaving(map, now);
          changed = true;
        }
        continue;
      }
      activeIds.add(session.id);
      actor.missingAt = null;
      if (actor.status != session.status) {
        actor.changeStatus(session.status, now);
      }
    }

    for (final session in sessions) {
      if (!session.hasOfficeAgentPresence || activeIds.contains(session.id)) {
        continue;
      }
      final slot = projectSlots[session.projectId];
      if (slot == null || slot >= map.workSpots.length) continue;
      final project = projects[slot];
      final deskIndex = usedDesks[project.id] ?? 0;
      final spots = map.workSpots[slot];
      if (spots.isEmpty) continue;
      final spotIndex = deskIndex % spots.length;
      final actor = _OfficeAgent(
        session: session,
        project: project,
        slot: slot,
        deskIndex: spotIndex,
        status: session.status,
        createdAt: now,
      )..arrive(map);
      _agents[session.id] = actor;
      usedDesks[project.id] = deskIndex + 1;
      activeIds.add(session.id);
      changed = true;
    }
    if (changed && notify && mounted) setState(() {});
  }

  void _onClock() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final dt = ((now - _lastTickMs) / 1000).clamp(0.0, 0.1);
    _lastTickMs = now;
    final map = _currentMap;
    if (map != null) {
      _syncAgents(_projectsForScene(_baseProjects), _currentSessions, map);
      for (final actor in _agents.values) {
        actor.advance(dt, now, map);
      }
      final departed = _agents.values
          .where((actor) => actor.gone)
          .map((actor) => actor.id)
          .toList();
      if (departed.isNotEmpty) {
        for (final id in departed) {
          _agents.remove(id);
        }
        if (mounted) setState(() {});
      }
    }
    _frameClock.tick();
  }

  @override
  void dispose() {
    _clock.cancel();
    _frameClock.dispose();
    for (final image in _images) {
      image.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _baseProjects = widget.projects.where((p) => !p.isSystemTerminal).toList();
    _currentSessions = widget.sessions.whereType<TerminalSession>().toList();
    final currentMap = _currentMap;
    if (currentMap != null) {
      _syncAgents(
        _projectsForScene(_baseProjects),
        _currentSessions,
        currentMap,
        notify: false,
      );
    }
    final projects = _projectsForScene(_baseProjects);
    final mapFuture = _mapFutures.putIfAbsent(
      projects.length,
      () => _loadMap(projects.length),
    );
    return FutureBuilder<_WorldMap>(
      future: mapFuture,
      builder: (context, mapSnapshot) {
        if (mapSnapshot.hasError) {
          return _AssetLoadError(error: mapSnapshot.error.toString());
        }
        if (!mapSnapshot.hasData) return const SizedBox.expand();
        _currentMap = mapSnapshot.data!;
        _syncAgents(
          _projectsForScene(_baseProjects),
          _currentSessions,
          mapSnapshot.data!,
          notify: false,
        );
        return FutureBuilder<_CharacterAtlas>(
          future: _charactersFuture,
          builder: (context, characterSnapshot) {
            if (characterSnapshot.hasError) {
              return _AssetLoadError(error: characterSnapshot.error.toString());
            }
            final atlas = characterSnapshot.data;
            final map = mapSnapshot.data!;
            return LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final scale = height / map.height;
                final sceneWidth = math.max(
                  constraints.maxWidth,
                  map.width * scale,
                );
                final painter = atlas == null
                    ? null
                    : _WorldPainter(
                        map: map,
                        atlas: atlas,
                        agents: _agents.values.toList(growable: false),
                        labels: widget.labels,
                        clock: _frameClock,
                      );
                return ColoredBox(
                  color: const Color(0xff70a85f),
                  child: ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const ClampingScrollPhysics(),
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTapUp: (event) {
                          final activePainter = painter;
                          if (activePainter == null) return;
                          final session = activePainter.sessionAt(
                            event.localPosition,
                            Size(sceneWidth, height),
                          );
                          if (session != null) {
                            final selectedSession = session;
                            Project? project;
                            for (final candidate in widget.projects) {
                              if (candidate.id == selectedSession.projectId) {
                                project = candidate;
                                break;
                              }
                            }
                            if (project != null) {
                              unawaited(
                                showOfficeAgentProfile(
                                  context,
                                  session: selectedSession,
                                  project: project,
                                  onOpenTerminal: () =>
                                      widget.onOpenSession(selectedSession),
                                  onRename: (name) => widget.onRenameSession(
                                    selectedSession,
                                    name,
                                  ),
                                ),
                              );
                            }
                          }
                        },
                        child: SizedBox(
                          width: sceneWidth,
                          height: height,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              RepaintBoundary(
                                child: CustomPaint(
                                  painter: _WorldBackgroundPainter(
                                    map: map,
                                    projects: projects,
                                    labels: widget.labels,
                                  ),
                                ),
                              ),
                              if (painter != null)
                                CustomPaint(painter: painter),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _AssetLoadError extends StatelessWidget {
  const _AssetLoadError({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: const Color(0xff15171b),
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          'Falha ao carregar os assets do escritório.\n$error',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xffe7e9ed), fontSize: 13),
        ),
      ),
    ),
  );
}

class _WorldMap {
  const _WorldMap({
    required this.image,
    required this.width,
    required this.height,
    required this.transform,
    required this.rooms,
    required this.workSpots,
    required this.doors,
    required this.core,
    required this.carLanes,
  });

  factory _WorldMap.fromJson(Map<String, dynamic> json, ui.Image image) {
    Map<String, double> rect(Map<String, dynamic> value) => {
      for (final key in ['x', 'y', 'w', 'h'])
        key: (value[key] as num).toDouble(),
    };
    return _WorldMap(
      image: image,
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      transform: (json['transform'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      rooms: (json['rooms'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(rect)
          .toList(),
      workSpots: (json['workSpots'] as List<dynamic>)
          .map(
            (spots) =>
                (spots as List<dynamic>).cast<Map<String, dynamic>>().toList(),
          )
          .toList(),
      doors: (json['doors'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(),
      core: (json['core'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(rect)
          .toList(),
      carLanes: (json['carLanes'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .toList(),
    );
  }

  final ui.Image image;
  final double width;
  final double height;
  final Map<String, double> transform;
  final List<Map<String, double>> rooms;
  final List<List<Map<String, dynamic>>> workSpots;
  final List<Map<String, dynamic>> doors;
  final List<Map<String, double>> core;
  final List<Map<String, dynamic>> carLanes;
}

class _Sprite {
  const _Sprite(this.rect, this.ax, this.ay);
  final Rect rect;
  final double ax;
  final double ay;
}

class _CharacterAtlas {
  const _CharacterAtlas({
    required this.image,
    required this.iconsImage,
    required this.carsImage,
    required this.sprites,
    required this.icons,
    required this.animations,
    required this.cars,
  });
  factory _CharacterAtlas.fromJson(
    Map<String, dynamic> json,
    ui.Image image,
    ui.Image iconsImage,
    Map<String, dynamic> carsJson,
    ui.Image carsImage,
  ) {
    final entries = json['sprites'] as Map<String, dynamic>;
    final iconEntries =
        (json['icons'] as Map<String, dynamic>)['sprites']
            as Map<String, dynamic>;
    final animationEntries = json['animation'] as Map<String, dynamic>;
    final carEntries = carsJson['sprites'] as Map<String, dynamic>;
    return _CharacterAtlas(
      image: image,
      iconsImage: iconsImage,
      carsImage: carsImage,
      sprites: {
        for (final entry in entries.entries)
          entry.key: _Sprite(
            Rect.fromLTWH(
              (entry.value['x'] as num).toDouble(),
              (entry.value['y'] as num).toDouble(),
              (entry.value['w'] as num).toDouble(),
              (entry.value['h'] as num).toDouble(),
            ),
            (entry.value['ax'] as num).toDouble(),
            (entry.value['ay'] as num).toDouble(),
          ),
      },
      icons: {
        for (final entry in iconEntries.entries)
          entry.key: _Sprite(
            Rect.fromLTWH(
              (entry.value['x'] as num).toDouble(),
              (entry.value['y'] as num).toDouble(),
              (entry.value['w'] as num).toDouble(),
              (entry.value['h'] as num).toDouble(),
            ),
            (entry.value['ax'] as num).toDouble(),
            (entry.value['ay'] as num).toDouble(),
          ),
      },
      animations: {
        for (final entry in animationEntries.entries)
          entry.key: _AnimationSpec(
            entry.value['frames'] as int,
            (entry.value['durationMs'] as num).toInt(),
          ),
      },
      cars: {
        for (final entry in carEntries.entries)
          entry.key: _Sprite(
            Rect.fromLTWH(
              (entry.value['x'] as num).toDouble(),
              (entry.value['y'] as num).toDouble(),
              (entry.value['w'] as num).toDouble(),
              (entry.value['h'] as num).toDouble(),
            ),
            (entry.value['ax'] as num).toDouble(),
            (entry.value['ay'] as num).toDouble(),
          ),
      },
    );
  }

  final ui.Image image;
  final ui.Image iconsImage;
  final ui.Image carsImage;
  final Map<String, _Sprite> sprites;
  final Map<String, _Sprite> icons;
  final Map<String, _AnimationSpec> animations;
  final Map<String, _Sprite> cars;
}

class _AnimationSpec {
  const _AnimationSpec(this.frames, this.durationMs);
  final int frames;
  final int durationMs;
}

/// Runtime state for one active Orkest harness. The static map comes from
/// Habblaud's renderer; this state follows the real terminal session lifecycle.
class _OfficeAgent {
  _OfficeAgent({
    required this.session,
    required this.project,
    required this.slot,
    required this.deskIndex,
    required this.status,
    required int createdAt,
  }) : id = session.id,
       projectId = session.projectId,
       statusSince = createdAt,
       poseSince = createdAt,
       nextOutingAt = createdAt + 6000 + (_hash(session.id) % 9000),
       look = _hash(session.id) % 16;

  static const missingGraceMs = 3000;
  static const _walkSpeed = 51.2; // Habblaud's 3.2 tiles/s at 16 px/tile.

  final String id;
  final String projectId;
  final int look;
  TerminalSession session;
  Project project;
  int slot;
  int deskIndex;
  TerminalStatus status;
  int statusSince;
  int poseSince;
  int? missingAt;
  int? celebrationUntil;
  int nextOutingAt;
  int? actionUntil;
  int outingState = 0;
  int outingCount = 0;
  Map<String, dynamic>? outing;
  bool entering = false;
  bool leaving = false;
  bool gone = false;
  double alpha = 1;
  Offset position = Offset.zero;
  String pose = 'stand';
  String held = 'none';
  String dir = 'down';
  bool seated = false;
  String? icon;
  int iconUntil = 0;
  int _routeIndex = 0;
  List<Offset> _route = const [];
  int _leaveStartedAt = 0;
  int _leaveDurationMs = 0;
  Map<String, dynamic>? _workSpot;

  void arrive(_WorldMap map) {
    final spot = _spot(map);
    if (spot == null) {
      position = Offset.zero;
      return;
    }
    entering = true;
    dir = (spot['dir'] as String?) ?? 'down';
    seated = spot['seated'] == true;
    final toDesk = _deskPoint(spot);
    final route = _pointList(spot['pathToDoor']);
    if (route.isEmpty) {
      position = toDesk;
      entering = false;
      _setRestPose(DateTime.now().millisecondsSinceEpoch);
      return;
    }
    position = route.last;
    _setRoute([...route.reversed, toDesk]);
  }

  void beginLeaving(_WorldMap map, int now) {
    if (leaving || gone) return;
    leaving = true;
    entering = false;
    icon = null;
    final spot = _spot(map);
    if (spot == null) {
      _leaveStartedAt = now;
      _leaveDurationMs = 700;
      return;
    }
    final routeToDoor = _pointList(spot['pathToDoor']);
    final desk = _deskPoint(spot);
    final path = <Offset>[];
    if ((position - desk).distance > 2) path.add(desk);
    path.addAll(routeToDoor);
    if (path.isEmpty) path.add(desk);
    final length = _pathLength([position, ...path]);
    _leaveStartedAt = now;
    _leaveDurationMs = (length / _walkSpeed * 1000 + 250)
        .clamp(700, 12000)
        .toInt();
    _setRoute(path);
    if (_route.isEmpty) gone = true;
  }

  void changeStatus(TerminalStatus next, int now) {
    final previous = status;
    if (previous == next) return;
    status = next;
    statusSince = now;
    icon = null;
    iconUntil = 0;
    if (previous == TerminalStatus.working && next == TerminalStatus.idle) {
      celebrationUntil = now + 1500;
      icon = 'star';
      iconUntil = now + 2400;
    } else if (next == TerminalStatus.waiting) {
      icon = 'question';
      iconUntil = now + 3200;
    }
    if (next != TerminalStatus.idle && outing != null) {
      _returnFromOuting();
    }
  }

  void advance(double dt, int now, _WorldMap map) {
    if (gone) return;
    if (leaving) {
      _advanceRoute(dt, now, walk: true);
      final progress = (now - _leaveStartedAt) / _leaveDurationMs;
      alpha = progress > 0.72 ? (1 - progress) / 0.28 : 1;
      alpha = alpha.clamp(0, 1);
      if (_routeIndex >= _route.length || progress >= 1) gone = true;
      return;
    }
    if (entering) {
      _advanceRoute(dt, now, walk: true);
      if (_routeIndex >= _route.length) {
        entering = false;
        alpha = 1;
        _setRestPose(now);
      }
      return;
    }
    if (_routeIndex < _route.length) {
      _advanceRoute(dt, now, walk: true);
      if (_routeIndex >= _route.length) {
        if (outingState == 1) {
          _beginOutingAction(now);
        } else if (outingState == 3) {
          outing = null;
          outingState = 0;
          actionUntil = null;
          nextOutingAt = now + 7000 + (_hash('$id:$outingCount') % 13000);
        }
      }
      return;
    }
    if (outingState == 2 && actionUntil != null && now >= actionUntil!) {
      _returnFromOuting();
    }
    if (status == TerminalStatus.idle &&
        outing == null &&
        now >= nextOutingAt) {
      _startOuting(map, now);
      if (_routeIndex < _route.length) {
        _advanceRoute(dt, now, walk: true);
        return;
      }
    }
    if (iconUntil > 0 && now >= iconUntil) {
      icon = null;
      iconUntil = 0;
    }
    _setRestPose(now);
  }

  void _setRestPose(int now) {
    if (status == TerminalStatus.working) {
      _setPose('type', now, held: 'none', seated: true);
      _setDeskDir();
      return;
    }
    if (status == TerminalStatus.waiting) {
      _setPose('wait', now, held: 'none', seated: true);
      _setDeskDir();
      if (icon == null && now - statusSince < 3200) {
        icon = 'question';
        iconUntil = statusSince + 3200;
      }
      return;
    }
    final cheerUntil = celebrationUntil;
    if (cheerUntil != null && now < cheerUntil) {
      final elapsed = now - (cheerUntil - 1500);
      _setPose(elapsed < 650 ? 'stretch' : 'cheer', now, seated: true);
      icon ??= 'star';
      if (iconUntil < cheerUntil) iconUntil = cheerUntil;
      return;
    }
    if (now - statusSince >= const Duration(minutes: 10).inMilliseconds) {
      _setPose('sleep', now, seated: true);
      icon ??= 'zzz';
    } else {
      _setPose('sit', now, seated: true);
    }
    _setDeskDir();
  }

  void _setDeskDir() {
    final spot = _workSpot;
    if (spot != null) dir = (spot['dir'] as String?) ?? dir;
  }

  void _setPose(
    String next,
    int now, {
    String held = 'none',
    bool seated = false,
  }) {
    if (pose != next) {
      pose = next;
      poseSince = now;
    }
    this.held = held;
    this.seated = seated;
  }

  void _advanceRoute(double dt, int now, {required bool walk}) {
    if (_routeIndex >= _route.length) return;
    var budget = _walkSpeed * dt;
    while (budget > 0 && _routeIndex < _route.length) {
      final target = _route[_routeIndex];
      final delta = target - position;
      final distance = delta.distance;
      if (distance < 0.01) {
        position = target;
        _routeIndex++;
        continue;
      }
      dir = _direction(delta, dir);
      _setPose(walk ? 'walk' : 'run', now);
      if (distance <= budget) {
        position = target;
        budget -= distance;
        _routeIndex++;
      } else {
        position += delta / distance * budget;
        budget = 0;
      }
    }
  }

  void _setRoute(List<Offset> points) {
    _route = points.where((point) => (point - position).distance > 1).toList();
    _routeIndex = 0;
  }

  void _startOuting(_WorldMap map, int now) {
    final home = _spot(map);
    final options =
        (home?['outingSpots'] as List<dynamic>?)
            ?.cast<Map<String, dynamic>>() ??
        const <Map<String, dynamic>>[];
    if (options.isEmpty) {
      nextOutingAt = now + 8000;
      return;
    }
    final available = options
        .where((spot) => (spot['path'] as List?)?.isNotEmpty ?? false)
        .toList();
    if (available.isEmpty) {
      nextOutingAt = now + 8000;
      return;
    }
    final optionIndex = _hash('$id:$outingCount') % available.length;
    final target = available[optionIndex];
    outing = target;
    outingCount++;
    outingState = 1;
    final path = _pointList(target['path']);
    final destination = Offset(
      (target['x'] as num).toDouble(),
      (target['y'] as num).toDouble(),
    );
    _setRoute([...path, destination]);
    if (_route.isEmpty) _beginOutingAction(now);
  }

  void _beginOutingAction(int now) {
    final target = outing;
    if (target == null) return;
    outingState = 2;
    final kind = target['kind'] as String? ?? '';
    dir = target['dir'] as String? ?? dir;
    seated = target['seated'] == true;
    held = 'none';
    switch (kind) {
      case 'coffee':
      case 'cafe_seat':
        held = 'coffee';
        _setPose(
          kind == 'coffee' ? 'drink' : 'sit',
          now,
          held: held,
          seated: seated,
        );
        actionUntil = now + 4500;
        break;
      case 'pingpong':
        _setPose('play', now, held: 'paddle');
        actionUntil = now + 7000;
        break;
      case 'talk':
        _setPose('talk', now);
        actionUntil = now + 5000;
        break;
      case 'water':
        held = 'water';
        _setPose('drink', now, held: held, seated: seated);
        actionUntil = now + 3500;
        break;
      case 'sofa':
      case 'armchair':
      case 'beanbag':
        _setPose('sit', now, seated: true);
        actionUntil = now + 5500;
        break;
      case 'shelf':
      case 'window':
        held = kind == 'shelf' ? 'book' : 'papers';
        _setPose('read', now, held: held, seated: seated);
        actionUntil = now + 5000;
        break;
      case 'arcade':
      case 'snack':
      case 'fridge':
      case 'sink':
        _setPose('use', now, seated: seated);
        actionUntil = now + 3000;
        break;
      default:
        _setPose('stand', now);
        actionUntil = now + 2500;
        break;
    }
  }

  void _returnFromOuting() {
    final target = outing;
    final home = _workSpot;
    if (target == null || home == null) {
      outing = null;
      outingState = 0;
      return;
    }
    final path = _pointList(target['path']);
    final targetPoint = Offset(
      (target['x'] as num).toDouble(),
      (target['y'] as num).toDouble(),
    );
    final desk = _deskPoint(home);
    _setRoute([targetPoint, ...path.reversed, desk]);
    outingState = 3;
    actionUntil = null;
    held = 'none';
  }

  Map<String, dynamic>? _spot(_WorldMap map) {
    if (slot < 0 || slot >= map.workSpots.length) return null;
    final spots = map.workSpots[slot];
    if (spots.isEmpty) return null;
    _workSpot = spots[deskIndex % spots.length];
    return _workSpot;
  }

  Offset _deskPoint(Map<String, dynamic> spot) =>
      Offset((spot['x'] as num).toDouble(), (spot['y'] as num).toDouble());

  static List<Offset> _pointList(Object? raw) => raw is List
      ? raw
            .whereType<Map>()
            .map(
              (point) => Offset(
                (point['x'] as num).toDouble(),
                (point['y'] as num).toDouble(),
              ),
            )
            .toList()
      : const [];

  static double _pathLength(List<Offset> points) {
    var length = 0.0;
    for (var i = 1; i < points.length; i++) {
      length += (points[i] - points[i - 1]).distance;
    }
    return length;
  }

  static int _hash(String value) => value.codeUnits.fold<int>(
    0,
    (hash, unit) => (hash * 31 + unit) & 0x7fffffff,
  );

  static String _direction(Offset delta, String fallback) {
    if (delta.distance < 0.01) return fallback;
    if (delta.dx.abs() >= delta.dy.abs()) {
      return delta.dx > 0 ? 'right' : 'left';
    }
    return delta.dy > 0 ? 'down' : 'up';
  }
}

class _AgentHit {
  const _AgentHit(this.rect, this.session);
  final Rect rect;
  final TerminalSession session;
}

/// Static world layer. A repaint boundary lets Flutter retain this large
/// raster while the cars and agents animate on the layer above it.
class _WorldBackgroundPainter extends CustomPainter {
  const _WorldBackgroundPainter({
    required this.map,
    required this.projects,
    required this.labels,
  });

  final _WorldMap map;
  final List<Project> projects;
  final OfficeWorldLabels labels;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.height / map.height;
    canvas.drawImageRect(
      map.image,
      Rect.fromLTWH(0, 0, map.width, map.height),
      Rect.fromLTWH(0, 0, map.width * scale, size.height),
      Paint()..filterQuality = FilterQuality.none,
    );
    canvas.save();
    canvas.scale(scale);
    final transformScale = map.transform['scale']!;
    final ox = map.transform['ox']!;
    final oy = map.transform['oy']!;
    Offset point(double x, double y) =>
        Offset(x * transformScale + ox, y * transformScale + oy);
    final coreLabels = [
      labels.reception,
      labels.cafe,
      labels.restrooms,
      labels.lounge,
    ];
    for (var index = 0; index < map.core.length; index++) {
      final rect = map.core[index];
      final anchor = point(rect['x']! + rect['w']! / 2, rect['y']! - 5);
      _badge(
        canvas,
        anchor.dx,
        anchor.dy,
        coreLabels[index],
        const Color(0xff262d37),
      );
    }
    for (
      var index = 0;
      index < projects.length && index < map.rooms.length;
      index++
    ) {
      final rect = map.rooms[index];
      final anchor = point(rect['x']! + rect['w']! / 2, rect['y']! - 5);
      _badge(
        canvas,
        anchor.dx,
        anchor.dy,
        projects[index].name,
        const Color(0xff303744),
      );
    }
    canvas.restore();
  }

  void _badge(
    Canvas canvas,
    double centerX,
    double baselineY,
    String text,
    Color color,
  ) {
    if (text.isEmpty) return;
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xfff5f5f5),
          fontSize: 10,
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
      maxLines: 1,
      ellipsis: '…',
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 208);
    final rect = Rect.fromLTWH(
      centerX - (painter.width + 12) / 2,
      baselineY - painter.height - 7,
      painter.width + 12,
      painter.height + 7,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, const Radius.circular(5)),
      Paint()..color = color,
    );
    painter.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _WorldBackgroundPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.projects != projects ||
      oldDelegate.labels != labels;
}

class _WorldPainter extends CustomPainter {
  _WorldPainter({
    required this.map,
    required this.atlas,
    required this.agents,
    required this.labels,
    required this.clock,
  }) : super(repaint: clock);

  final _WorldMap map;
  final _CharacterAtlas atlas;
  final List<_OfficeAgent> agents;
  final OfficeWorldLabels labels;
  final Listenable clock;
  final List<_AgentHit> _hits = [];
  final Map<String, TextPainter> _badgePainters = {};
  double _scale = 1;

  Rect _imageRect(Size size) {
    _scale = size.height / map.height;
    return Rect.fromLTWH(0, 0, map.width * _scale, size.height);
  }

  Offset _sourcePoint(double x, double y) => Offset(
    x * map.transform['scale']! + map.transform['ox']!,
    y * map.transform['scale']! + map.transform['oy']!,
  );

  TerminalSession? sessionAt(Offset point, Size size) {
    final rect = _imageRect(size);
    final imagePoint = (point - rect.topLeft) / _scale;
    for (final hit in _hits.reversed) {
      if (hit.rect.contains(imagePoint)) return hit.session;
    }
    return null;
  }

  @override
  void paint(Canvas canvas, Size size) {
    _scale = size.height / map.height;
    _hits.clear();
    canvas.save();
    canvas.scale(_scale);
    _paintCars(canvas);
    _paintAgents(canvas);
    canvas.restore();
  }

  void _paintCars(Canvas canvas) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final scale = map.transform['scale']!;
    for (var laneIndex = 0; laneIndex < map.carLanes.length; laneIndex++) {
      final lane = map.carLanes[laneIndex];
      final x0 = (lane['x0'] as num).toDouble();
      final x1 = (lane['x1'] as num).toDouble();
      final distance = x1 - x0;
      if (distance <= 0) continue;
      final dir = (lane['dir'] as num).toInt() > 0 ? 'right' : 'left';
      final speed = 52 + laneIndex * 9.0;
      final travelMs = distance / speed * 1000;
      final gapMs = 4200.0;
      final cycleMs = travelMs + gapMs;
      final phase = (now + laneIndex * 6300) % cycleMs;
      if (phase >= travelMs) continue;
      final progress = phase / travelMs;
      final x = dir == 'right'
          ? x0 + distance * progress
          : x1 - distance * progress;
      final sprite = atlas.cars['${(laneIndex * 3 + 1) % 6}:$dir'];
      if (sprite == null) continue;
      final point = _sourcePoint(x, (lane['y'] as num).toDouble());
      final dest = Rect.fromLTWH(
        point.dx - sprite.ax * scale,
        point.dy - sprite.ay * scale,
        sprite.rect.width * scale,
        sprite.rect.height * scale,
      );
      canvas.drawImageRect(
        atlas.carsImage,
        sprite.rect,
        dest,
        Paint()..filterQuality = FilterQuality.none,
      );
    }
  }

  void _paintAgents(Canvas canvas) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final spriteScale = map.transform['scale']!;
    for (final actor in agents) {
      if (actor.gone || actor.alpha <= 0.02) continue;
      final foot = _sourcePoint(actor.position.dx, actor.position.dy);
      final animation = atlas.animations[actor.pose];
      final frame = animation == null || animation.frames <= 1
          ? 0
          : ((now - actor.poseSince) ~/ animation.durationMs) %
                animation.frames;
      final seated = actor.seated ? 1 : 0;
      final key =
          '${actor.look}:${actor.dir}:${actor.pose}:${actor.held}:$seated:$frame';
      final sprite = atlas.sprites[key];
      if (sprite == null) continue;
      final dest = Rect.fromLTWH(
        foot.dx - sprite.ax * spriteScale,
        foot.dy - sprite.ay * spriteScale,
        sprite.rect.width * spriteScale,
        sprite.rect.height * spriteScale,
      );
      final opacity = actor.alpha.clamp(0, 1);
      final spritePaint = Paint()
        ..filterQuality = FilterQuality.none
        ..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255);
      canvas.drawImageRect(atlas.image, sprite.rect, dest, spritePaint);
      if (!actor.leaving && opacity > 0.4) {
        _hits.add(_AgentHit(dest.inflate(5), actor.session));
      }
      final icon = actor.icon == null ? null : atlas.icons[actor.icon];
      if (icon != null && !actor.leaving) {
        final iconPoint = Offset(foot.dx, dest.top - 4);
        final iconRect = Rect.fromLTWH(
          iconPoint.dx - icon.ax * spriteScale,
          iconPoint.dy - icon.ay * spriteScale,
          icon.rect.width * spriteScale,
          icon.rect.height * spriteScale,
        );
        canvas.drawImageRect(
          atlas.iconsImage,
          icon.rect,
          iconRect,
          Paint()..filterQuality = FilterQuality.none,
        );
      }
      final status = switch (actor.status) {
        TerminalStatus.working => labels.working,
        TerminalStatus.waiting => labels.waiting,
        TerminalStatus.idle => labels.idle,
      };
      final sessionTitle = actor.session.displayTitle.trim();
      final title = sessionTitle.isEmpty ? status : '$sessionTitle · $status';
      _badge(
        canvas,
        foot.dx,
        dest.top - 4,
        title,
        const Color(0xe9222933),
        maxWidth: 180,
      );
    }
  }

  void _badge(
    Canvas canvas,
    double centerX,
    double baselineY,
    String text,
    Color color, {
    double maxWidth = 220,
  }) {
    if (text.isEmpty) return;
    final key = '$maxWidth\u0000$text';
    final painter = _badgePainters.putIfAbsent(key, () {
      return TextPainter(
        text: TextSpan(
          text: text,
          style: const TextStyle(
            color: Color(0xfff5f5f5),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            height: 1,
          ),
        ),
        maxLines: 1,
        ellipsis: '…',
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth - 12);
    });
    final rect = Rect.fromLTWH(
      centerX - (painter.width + 12) / 2,
      baselineY - painter.height - 7,
      painter.width + 12,
      painter.height + 7,
    );
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(5));
    canvas.drawRRect(rrect, Paint()..color = color);
    painter.paint(canvas, Offset(rect.left + 6, rect.top + 3));
  }

  @override
  bool shouldRepaint(covariant _WorldPainter oldDelegate) =>
      oldDelegate.map != map ||
      oldDelegate.atlas != atlas ||
      oldDelegate.agents != agents ||
      oldDelegate.labels != labels;
}
