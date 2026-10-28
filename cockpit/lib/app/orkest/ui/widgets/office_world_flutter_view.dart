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
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/orkest/ui/session/office_animation_rules.dart';
import 'package:orkest_code/app/orkest/ui/session/office_room_effects.dart';
import 'package:orkest_code/app/orkest/ui/session/office_social_state.dart';

part 'office_native_simulation.dart';
part 'office_native_effects.dart';
part 'office_native_layout.dart';

/// Displays the Habblaud office layout with Orkest workspaces and sessions.
class OfficeWorldFlutterView extends StatefulWidget {
  const OfficeWorldFlutterView({
    super.key,
    required this.projects,
    required this.sessions,
    required this.labels,
    required this.onOpenSession,
    required this.onRenameSession,
    this.settings = const AppSettings(),
    this.nowMilliseconds,
  });

  final List<Project> projects;
  final List<PaneItem> sessions;
  final OfficeWorldLabels labels;
  final ValueChanged<TerminalSession> onOpenSession;
  final void Function(TerminalSession session, String name) onRenameSession;
  final AppSettings settings;
  final int Function()? nowMilliseconds;

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
  int get _now =>
      widget.nowMilliseconds?.call() ?? DateTime.now().millisecondsSinceEpoch;
  final _gatherings = <_NativeGathering>[];
  final _roomTransitions = <String, _NativeRoomTransition>{};
  bool _initialScene = true;
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
  late final Future<Map<String, dynamic>> _nativeSceneFuture = rootBundle
      .loadString('assets/office_world/native-scene.json')
      .then((text) => (jsonDecode(text) as Map).cast<String, dynamic>());
  final Map<int, Future<_WorldMap>> _mapFutures = {};
  final Map<int, _WorldMap> _loadedMaps = {};
  final Map<String, _OfficeAgent> _agents = {};
  final List<ui.Image> _images = [];
  void _retainImage(ui.Image image) {
    if (mounted) {
      _images.add(image);
    } else {
      image.dispose();
    }
  }

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
    _retainImage(image);
    final native = await _nativeSceneFuture;
    final details = (native['scenes'] as Map)['${entry['count']}'] as Map;
    final map = _WorldMap.fromJson(
      _nativeLayout(entry, details, requestedCount),
      image,
    );
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
    _retainImage(image);
    final iconBytes = await rootBundle.load('assets/habblaud_art/icons.png');
    final iconCodec = await ui.instantiateImageCodec(
      iconBytes.buffer.asUint8List(
        iconBytes.offsetInBytes,
        iconBytes.lengthInBytes,
      ),
    );
    final iconsImage = (await iconCodec.getNextFrame()).image;
    iconCodec.dispose();
    _retainImage(iconsImage);
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
    final nativeMeta = await _nativeSceneFuture;
    final nativeBytes = await rootBundle.load(
      'assets/office_world/native-furniture.png',
    );
    final nativeCodec = await ui.instantiateImageCodec(
      nativeBytes.buffer.asUint8List(
        nativeBytes.offsetInBytes,
        nativeBytes.lengthInBytes,
      ),
    );
    final nativeImage = (await nativeCodec.getNextFrame()).image;
    nativeCodec.dispose();
    _retainImage(nativeImage);
    final carsBytes = await rootBundle.load('assets/habblaud_art/cars.png');
    final carsCodec = await ui.instantiateImageCodec(
      carsBytes.buffer.asUint8List(
        carsBytes.offsetInBytes,
        carsBytes.lengthInBytes,
      ),
    );
    final carsImage = (await carsCodec.getNextFrame()).image;
    carsCodec.dispose();
    _retainImage(carsImage);
    return _CharacterAtlas.fromJson(
      metadata,
      image,
      iconsImage,
      carsMetadata,
      carsImage,
      nativeMeta,
      nativeImage,
    );
  }

  List<Project> _projectsForScene(List<Project> projects) {
    final result = projects.toList();
    for (final actor in _agents.values.where((actor) => actor.leaving)) {
      if (result.any((project) => project.id == actor.project.id)) continue;
      result.insert(actor.slot.clamp(0, result.length), actor.project);
    }
    for (final room in _roomTransitions.values) {
      if (result.any((p) => p.id == room.project.id)) continue;
      if (room.leftAt == null || _now - room.leftAt! < 4300) {
        result.insert(room.slot.clamp(0, result.length), room.project);
      }
    }
    return result;
  }

  void _syncAgents(
    List<Project> projects,
    List<TerminalSession> sessions,
    _WorldMap map, {
    bool notify = true,
  }) {
    final now = _now;
    final slots = {for (var i = 0; i < projects.length; i++) projects[i].id: i};
    final sources = <String, (TerminalSession, OfficeSubagent?, String?)>{};
    for (final session in sessions) {
      if (!session.hasOfficeAgentPresence) continue;
      final parent = sessions
          .where(
            (candidate) =>
                candidate.officeIdentity == session.officeParentIdentity,
          )
          .firstOrNull;
      sources[session.id] = (session, null, parent?.id);
      final children = session.officeSubagents;
      for (final child in children) {
        final id = '${session.id}:sub:${child.id}';
        final nested = children.any((c) => c.id == child.parentSubagentId);
        sources[id] = (
          session,
          child,
          nested ? '${session.id}:sub:${child.parentSubagentId!}' : session.id,
        );
      }
    }
    for (var slot = 0; slot < projects.length; slot++) {
      final p = projects[slot];
      _roomTransitions.putIfAbsent(
        p.id,
        () =>
            _NativeRoomTransition(slot, _initialScene ? now - 2600 : now, p)
              ..lightAt = _initialScene ? now - 600 : null,
      );
    }
    var changed = false;
    for (final actor in _agents.values.toList()) {
      if (actor.leaving) continue;
      final source = sources[actor.id], slot = slots[actor.projectId];
      if (source == null || slot == null) {
        actor.missingAt ??= now;
        if (now - actor.missingAt! >= _OfficeAgent.missingGraceMs) {
          actor._lastToLeave = !_agents.values.any(
            (a) =>
                a != actor &&
                a.projectId == actor.projectId &&
                !a.leaving &&
                !a.gone,
          );
          actor.beginLeaving(map, now);
          changed = true;
        }
        continue;
      }
      actor.missingAt = null;
      actor.session = source.$1;
      actor.child = source.$2;
      actor.parentId = source.$3;
      if (actor.slot != slot) {
        final old = actor.slot;
        actor.position += Offset(
          ((slot ~/ 2) - (old ~/ 2)) * 256.0,
          ((slot % 2) - (old % 2)) * 272.0,
        );
        actor.slot = slot;
        actor._spot(map);
      }
      actor.project = projects[slot];
      actor.roomLight = _roomTransitions[actor.projectId];
      final child = source.$2;
      actor.changeStatus(
        child == null
            ? source.$1.status
            : child.finishedAt == null
            ? TerminalStatus.working
            : TerminalStatus.idle,
        now,
      );
      if (child?.finishedAt != null && !actor.delivered && !actor.delivering) {
        if (child!.outcome == null || child.outcome == 'success') {
          _deliverNative(actor, map, now);
        } else {
          actor.beginLeaving(map, now);
        }
      } else if (child == null && actor.parentId != null) {
        final last = actor.session.officeStatusHistory.lastOrNull;
        if (last?.activityKind == 'done' &&
            last!.sequence != actor._lastDeliverySequence &&
            !actor.entering) {
          actor._lastDeliverySequence = last.sequence;
          actor.delivered = false;
          _deliverNative(actor, map, now);
        }
      }
    }
    final used = <String, Set<int>>{};
    for (final actor in _agents.values.where((a) => !a.leaving)) {
      (used[actor.projectId] ??= <int>{}).add(actor.deskIndex);
    }
    for (final entry in sources.entries) {
      if (_agents.containsKey(entry.key)) continue;
      final source = entry.value, slot = slots[source.$1.projectId];
      if (slot == null || slot >= map.workSpots.length) continue;
      var desk = 0;
      while (used[source.$1.projectId]?.contains(desk) ?? false) {
        desk++;
      }
      (used[source.$1.projectId] ??= <int>{}).add(desk);
      final actor = _OfficeAgent(
        session: source.$1,
        project: projects[slot],
        slot: slot,
        deskIndex: desk,
        status: source.$2 == null ? source.$1.status : TerminalStatus.working,
        createdAt: now,
        agentId: entry.key,
        child: source.$2,
        parentId: source.$3,
      )..roomLight = _roomTransitions[source.$1.projectId];
      actor.arrive(map);
      _agents[entry.key] = actor;
      changed = true;
    }
    _initialScene = false;
    for (final entry in _roomTransitions.entries.toList()) {
      final listed =
          widget.projects.any((p) => p.id == entry.key) &&
          sources.values.any((v) => v.$1.projectId == entry.key);
      final occupants = _agents.values.any(
        (a) => a.projectId == entry.key && !a.gone,
      );
      if (listed) {
        entry.value.leftAt = null;
      } else if (!occupants) {
        entry.value.leftAt ??= now;
        entry.value.darkAt ??= now;
        entry.value.lightAt = null;
      }
      if (entry.value.leftAt != null && now - entry.value.leftAt! > 4300) {
        _roomTransitions.remove(entry.key);
        changed = true;
      }
    }
    if (changed && notify && mounted) setState(() {});
  }

  void _deliverNative(_OfficeAgent actor, _WorldMap map, int now) {
    final parent = _agents[actor.parentId];
    if (actor.entering) return;
    if (parent == null || parent.leaving) {
      if (actor.child != null) actor.beginLeaving(map, now);
      return;
    }
    actor.gathering?.remove(actor);
    actor.outing = null;
    actor.outingState = 0;
    actor.delivering = true;
    actor._deliveryAt = 0;
    actor.held = 'papers';
    final target = parent.position + const Offset(16, 0);
    actor._setRoute(_OfficeAgent._path(map, actor.position, target));
    parent.icon = 'check';
    parent.iconUntil = now + 2800;
  }

  List<Map<String, dynamic>> get debugActors => [
    for (final actor in _agents.values)
      {
        'id': actor.id,
        'pose': actor.pose,
        'held': actor.held,
        'mode': actor.mode,
        'icon': actor.icon,
        'group': actor.gathering?.kind,
        'shellStage': actor.shellStage?.name,
        'leaving': actor.leaving,
        'gone': actor.gone,
        'x': actor.position.dx,
        'y': actor.position.dy,
      },
  ];
  void debugTick() => _onClock();

  void _onClock() {
    final now = _now;
    final dt = ((now - _lastTickMs) / 1000).clamp(0.0, 0.1);
    _lastTickMs = now;
    final map = _currentMap;
    if (map != null) {
      // Match WebView polling when output arrives inside the scan throttle.
      for (final session in _currentSessions) {
        session.refreshOfficeActivityFromScreen();
      }
      _syncAgents(_projectsForScene(_baseProjects), _currentSessions, map);
      for (final actor in _agents.values) {
        actor.advance(dt, now, map, widget.settings);
      }
      _advanceGatherings(now, map);
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
    _currentSessions = widget.sessions.whereType<TerminalSession>().toList();
    _baseProjects = widget.projects
        .where(
          (p) => _currentSessions.any(
            (s) => s.projectId == p.id && s.hasOfficeAgentPresence,
          ),
        )
        .toList();
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
        if (_currentMap != null && !identical(_currentMap, mapSnapshot.data)) {
          for (final group in _gatherings) {
            group.finish(_now);
          }
          _gatherings.clear();
        }
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
                        gatherings: _gatherings,
                        transitions: _roomTransitions,
                        settings: widget.settings,
                        now: () => _now,
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
                                  loadSocial: () async {
                                    final actor = _agents[selectedSession.id];
                                    return actor == null
                                        ? null
                                        : OfficeAgentSocial.fromJson({
                                            ...actor.wallet,
                                            'doing':
                                                actor.gathering?.kind ??
                                                actor.outing ??
                                                actor.mode,
                                          });
                                  },
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
  _WorldMap({
    required this.image,
    required this.width,
    required this.height,
    required this.transform,
    required this.rooms,
    required this.workSpots,
    required this.doors,
    required this.core,
    required this.carLanes,
    required this.native,
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
      native: (json['native'] as Map).cast<String, dynamic>(),
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
  final Map<String, dynamic> native;
  final Map<String, String> reservations = {};
  final Map<String, int> elevatorNext = {};
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
    required this.furnitureImage,
    required this.furniture,
  });
  factory _CharacterAtlas.fromJson(
    Map<String, dynamic> json,
    ui.Image image,
    ui.Image iconsImage,
    Map<String, dynamic> carsJson,
    ui.Image carsImage,
    Map<String, dynamic> nativeMeta,
    ui.Image nativeImage,
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
      furnitureImage: nativeImage,
      furniture: (nativeMeta['sprites'] as Map).cast<String, dynamic>(),
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
  final ui.Image furnitureImage;
  final Map<String, dynamic> furniture;
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
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xff78a65f),
    );
    canvas.drawImageRect(
      map.image,
      Rect.fromLTWH(
        0,
        0,
        map.image.width.toDouble(),
        map.image.height.toDouble(),
      ),
      Rect.fromLTWH(0, 0, map.image.width * scale, size.height),
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
    required this.gatherings,
    required this.transitions,
    required this.settings,
    required this.now,
  }) : super(repaint: clock);

  final _WorldMap map;
  final _CharacterAtlas atlas;
  final List<_OfficeAgent> agents;
  final OfficeWorldLabels labels;
  final Listenable clock;
  final List<_NativeGathering> gatherings;
  final Map<String, _NativeRoomTransition> transitions;
  final AppSettings settings;
  final int Function() now;
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
    _paintRoomTransitions(canvas);
    _paintDynamicFurniture(canvas);
    _paintCars(canvas);
    _paintAgents(canvas);
    _paintOfficeEffects(canvas);
    canvas.restore();
  }

  void _paintCars(Canvas canvas) {
    final now = this.now();
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
    final now = this.now();
    final spriteScale = map.transform['scale']!;
    final ordered = agents.toList()
      ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
    for (final actor in ordered) {
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
      final sprite =
          atlas.sprites[key] ??
          atlas
              .sprites['${actor.look}:${actor.dir}:${actor.pose}:none:$seated:$frame'];
      if (sprite == null) continue;
      final dest = Rect.fromLTWH(
        foot.dx - sprite.ax * spriteScale,
        foot.dy -
            sprite.ay * spriteScale +
            (actor.seated ? -1 : 1) * (1 - actor.seatBlend) * 3 * spriteScale,
        sprite.rect.width * spriteScale,
        sprite.rect.height * spriteScale,
      );
      final opacity = actor.alpha.clamp(0, 1);
      final spritePaint = Paint()
        ..filterQuality = FilterQuality.none
        ..color = Color.fromARGB((opacity * 255).round(), 255, 255, 255);
      canvas.drawImageRect(atlas.image, sprite.rect, dest, spritePaint);
      if (actor.pose == 'read' && actor.held == 'laptop') {
        final laptop = Rect.fromLTWH(
          foot.dx - 5 * spriteScale,
          foot.dy - 12 * spriteScale,
          9 * spriteScale,
          6 * spriteScale,
        );
        canvas.drawRect(laptop, Paint()..color = const Color(0xff394f64));
        canvas.drawRect(
          laptop.deflate(spriteScale),
          Paint()..color = const Color(0xff81afbd),
        );
        canvas.drawRect(
          Rect.fromLTWH(
            laptop.left - spriteScale,
            laptop.bottom,
            11 * spriteScale,
            spriteScale,
          ),
          Paint()..color = const Color(0xff778b96),
        );
      }
      if (!actor.leaving && opacity > 0.4) {
        _hits.add(_AgentHit(dest.inflate(5), actor.session));
      }
      final iconName =
          actor.icon ??
          (actor.mode == 'waiting'
              ? 'alert'
              : actor.mode == 'shell'
              ? (now ~/ 1200 % 2 == 0 ? 'hourglass' : 'hourglass_flip')
              : null);
      final icon = iconName == null ? null : atlas.icons[iconName];
      if (icon != null && !actor.leaving) {
        final iconPoint = Offset(
          foot.dx,
          dest.top -
              4 +
              (actor.mode == 'waiting'
                  ? math.sin(now / 180).abs() * 4
                  : math.sin(now / 500) * 1.5),
        );
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
      final title =
          '${sessionTitle.isEmpty ? actor.title : sessionTitle} · ${actor.session.officeHarness.label} · $status';
      if (settings.officeShowNames) {
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
