import 'dart:async';
import 'dart:convert';

import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/ui/session/pane_item.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/orkest/ui/session/office_social_state.dart';
import 'package:orkest_code/app/orkest/ui/session/office_room_effects.dart';
import 'package:orkest_code/app/core/ui/widgets/unzoomed_native_view.dart';
import 'package:orkest_code/app/orkest/ui/widgets/webview_chrome.dart';
import 'package:orkest_code/app/orkest/ui/session/office_harness_identity.dart';
import 'package:orkest_code/app/core/ui/settings_controller.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_agent_profile_dialog.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_agent_names.dart';
import 'package:orkest_code/app/core/domain/entities/app_settings.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef _OfficePortrait = ({Uint8List body, Uint8List face});

/// Runs Habblaud's original simulation and Canvas 2D renderer in the local
/// WebView, feeding it snapshots synthesized from Orkest projects/sessions.
class HabblaudWorldWebView extends StatefulWidget {
  const HabblaudWorldWebView({
    super.key,
    required this.projects,
    required this.sessions,
    required this.onOpenSession,
    required this.onRenameSession,
  });

  final List<Project> projects;
  final List<PaneItem> sessions;
  final ValueChanged<TerminalSession> onOpenSession;
  final void Function(TerminalSession session, String name) onRenameSession;

  @override
  State<HabblaudWorldWebView> createState() => _HabblaudWorldWebViewState();
}

class _HabblaudWorldWebViewState extends State<HabblaudWorldWebView> {
  static const _engineAsset = 'assets/office_world/engine.js';
  static const _baseUrl = 'https://orkest.local/office-world/';

  InAppWebViewController? _web;
  Future<String>? _htmlFuture;
  bool _loaded = false;
  int _revision = 0;
  Timer? _snapshotTimer;
  Timer? _panelRefreshTimer;
  String? _lastSnapshotSignature;
  String? _lastOpenedAgent;
  int _lastOpenedAt = 0;
  bool _sidebarVisible = true;
  bool _activityVisible = true;
  String _agentQuery = '';
  final TextEditingController _agentSearch = TextEditingController();
  final Map<String, Future<_OfficePortrait?>> _portraitCache = {};
  final Map<String, String> _portraitSignatures = {};
  final Map<String, OfficeAgentSocial> _socialBySession = {};
  List<OfficeSocialEvent> _socialEvents = [];
  bool _readingSocial = false;
  bool _socialReadFailed = false;
  String? _socialSignature;
  final Map<String, TerminalStatus> _lastStatuses = {};
  final Map<String, int> _statusSince = {};

  @override
  void initState() {
    super.initState();
    _htmlFuture = _loadHtml();
    _snapshotTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (_) => unawaited(_pushSnapshot()),
    );
    _panelRefreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
      unawaited(_refreshSocial());
    });
  }

  @override
  void didUpdateWidget(covariant HabblaudWorldWebView oldWidget) {
    super.didUpdateWidget(oldWidget);
    unawaited(_pushSnapshot());
  }

  Future<String> _loadHtml() async {
    final bundle = await rootBundle.loadString(_engineAsset);
    final safeBundle = bundle.replaceAll('</script', r'<\/script');
    return '''<!doctype html>
<html><head><meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<meta charset="utf-8"><style>
html,body,#office{width:100%;height:100%;margin:0;overflow:hidden;background:#7fae62}
canvas{display:block;image-rendering:pixelated;outline:none}
</style></head><body><canvas id="office" tabindex="0"></canvas>
<script>$safeBundle</script></body></html>''';
  }

  Map<String, dynamic> _snapshot() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final officeSettings = context.read<SettingsController>().settings;
    final projects = widget.projects
        .where((project) => !project.isSystemTerminal)
        .toList(growable: false);
    final projectIds = projects.map((project) => project.id).toSet();
    final sessions = widget.sessions
        .whereType<TerminalSession>()
        .where(
          // Require evidence that this PTY is running an agent, but do not
          // require the process to match a known harness. Generic PTY activity
          // and the shared activity contract are enough for new harnesses.
          (session) =>
              projectIds.contains(session.projectId) &&
              session.hasOfficeAgentPresence,
        )
        .toList(growable: false);
    final identities = _resolveAgentIdentities(sessions, officeSettings);
    final accountCounts = <String, int>{};
    final accountIdentities = <String, OfficeHarnessIdentity>{};
    final agents = <Map<String, dynamic>>[];
    final usedOfficeNames = <String>{
      for (final identity in identities.values) identity.name.toLowerCase(),
    };
    final officeLabels = context.t.orkest.officeWorld;

    for (final session in sessions) {
      final parent = sessions
          .where(
            (candidate) =>
                candidate.id != session.id &&
                candidate.officeIdentity == session.officeParentIdentity,
          )
          .firstOrNull;
      final identity = identities[session.id]!;
      final identityHarness = session.officeHarness;
      final provider = identityHarness.id;
      final accountId = 'orkest-$provider';
      accountIdentities[accountId] = identityHarness;
      accountCounts.update(accountId, (count) => count + 1, ifAbsent: () => 1);
      final previousStatus = _lastStatuses[session.id];
      if (previousStatus != session.status) {
        _lastStatuses[session.id] = session.status;
        _statusSince[session.id] =
            session.officeStatusSince.millisecondsSinceEpoch;
      }
      final seed = _stableSeed('${session.projectId}:${session.id}');
      final recent = [
        for (final event in session.officeStatusHistory)
          _officeStatusActivity(
            event.status,
            event.at.millisecondsSinceEpoch,
            sequence: event.sequence,
            hookEvent: event.event,
            toolName: event.toolName,
            activityKind: event.activityKind,
            activityPhase: event.activityPhase,
            activitySummary: event.activitySummary,
            working: officeLabels.workingInTerminal,
            waiting: officeLabels.waitingInTerminal,
            idle: officeLabels.turnCompleted,
            prompt: officeLabels.promptReceived,
            reading: officeLabels.readingFile,
            searching: officeLabels.searchingCode,
            editing: officeLabels.editingFile,
            writing: officeLabels.writingFile,
            command: officeLabels.runningCommand,
            tests: officeLabels.runningTests,
            web: officeLabels.browsingWeb,
            planning: officeLabels.organizingTasks,
            delegate: officeLabels.callingSubagents,
            toolComplete: officeLabels.toolCompleted,
            usingTool: officeLabels.usingTool,
            thinking: officeLabels.agentThinking,
            responded: officeLabels.agentResponded,
            activityError: officeLabels.activityError,
          ),
      ];
      final observedSince =
          _statusSince[session.id] ?? session.createdAt.millisecondsSinceEpoch;
      final latestActivity = recent.isEmpty
          ? _officeStatusActivity(
              session.status,
              observedSince,
              working: officeLabels.workingInTerminal,
              waiting: officeLabels.waitingInTerminal,
              idle: officeLabels.turnCompleted,
              prompt: officeLabels.promptReceived,
              reading: officeLabels.readingFile,
              searching: officeLabels.searchingCode,
              editing: officeLabels.editingFile,
              writing: officeLabels.writingFile,
              command: officeLabels.runningCommand,
              tests: officeLabels.runningTests,
              web: officeLabels.browsingWeb,
              planning: officeLabels.organizingTasks,
              delegate: officeLabels.callingSubagents,
              toolComplete: officeLabels.toolCompleted,
              usingTool: officeLabels.usingTool,
              thinking: officeLabels.agentThinking,
              responded: officeLabels.agentResponded,
              activityError: officeLabels.activityError,
            )
          : recent.last;
      agents.add({
        'id': session.id,
        'kind': parent == null ? 'main' : 'sub',
        if (parent != null) 'parentId': parent.id,
        'sessionBacked': true,
        'socialIdentity': session.officeIdentity,
        if (session.officeSocial.data != null)
          'socialState': session.officeSocial.data,
        'provider': provider,
        'roomId': session.projectId,
        'name': identity.name,
        'look': identity.look,
        'role': identityHarness.label,
        'harness': {
          'id': identityHarness.id,
          'label': identityHarness.label,
          'source': identityHarness.source,
        },
        'title': session.title,
        'sessionId': session.id,
        'account': accountId,
        'status': session.officeVisualStatus,
        if (session.officeShells.isNotEmpty) 'shells': session.officeShells,
        if (session.status == TerminalStatus.waiting)
          'waitingFor':
              session.officeWaitingSummary ?? officeLabels.waitingBubble,
        'activity': latestActivity,
        'recent': [
          if (session.officeShellDone != null) session.officeShellDone,
          ...recent.isEmpty
              ? [latestActivity]
              : recent.skip(recent.length > 30 ? recent.length - 30 : 0),
        ],
        'tasks': session.officeTasks,
        'startedAt': session.createdAt.millisecondsSinceEpoch,
        'lastEventAt': now,
        'statusSince': _statusSince[session.id] ?? now,
        // O contrato Habblaud exige AgentStats. Só a contagem de subagentes é
        // observada; tokens e chamadas permanecem sem medição.
        'stats': {
          'toolCalls': 0,
          'tokensIn': 0,
          'tokensOut': 0,
          'subagents': session.officeSubagents
              .where((agent) => agent.finishedAt == null)
              .length,
        },
        'seed': seed,
        'parts': _appearanceFor(session),
      });

      final sessionSubagents = session.officeSubagents;
      final subagentIds = sessionSubagents.map((agent) => agent.id).toSet();
      for (final subagent in sessionSubagents) {
        final childId = '${session.id}:sub:${subagent.id}';
        final nestedParent = subagent.parentSubagentId;
        final nestedParentId =
            nestedParent == null || !subagentIds.contains(nestedParent)
            ? null
            : '${session.id}:sub:$nestedParent';
        final identity = pickOfficeAgentIdentity(childId, usedOfficeNames);
        usedOfficeNames.add(identity.name.toLowerCase());
        final startedAt = subagent.startedAt.millisecondsSinceEpoch;
        final finishedAt = subagent.finishedAt?.millisecondsSinceEpoch;
        final outcome = subagent.outcome;
        final isDone =
            finishedAt != null && (outcome == null || outcome == 'success');
        final failed = finishedAt != null && outcome == 'error';
        final interrupted = finishedAt != null && outcome == 'interrupted';
        final activityAt = finishedAt ?? startedAt;
        final role = subagent.type?.trim();
        agents.add({
          'id': childId,
          'kind': 'sub',
          'provider': provider,
          'parentId': nestedParentId ?? session.id,
          'roomId': session.projectId,
          'name': identity.name,
          'look': identity.look,
          'role': role == null || role.isEmpty ? 'Subagente' : role,
          'title': role,
          'sessionId': childId,
          'socialIdentity': '${session.officeIdentity}:sub:${subagent.id}',
          'account': accountId,
          'status': finishedAt == null
              ? 'working'
              : isDone
              ? 'done'
              : 'offline',
          'activity': {
            'id': '$childId:${finishedAt == null ? 'started' : outcome}',
            'kind': finishedAt == null
                ? 'think'
                : isDone
                ? 'done'
                : 'error',
            'icon': finishedAt == null
                ? '👥'
                : isDone
                ? '✅'
                : failed
                ? '🌧️'
                : interrupted
                ? '🛑'
                : '⚠️',
            'text': finishedAt == null
                ? officeLabels.callingSubagents
                : isDone
                ? officeLabels.turnCompleted
                : failed
                ? officeLabels.subagentFailed
                : officeLabels.subagentInterrupted,
            if (finishedAt != null && !isDone) 'error': true,
            'at': activityAt,
          },
          'recent': const <dynamic>[],
          'tasks': const <dynamic>[],
          'startedAt': startedAt,
          'lastEventAt': activityAt,
          'statusSince': isDone ? finishedAt : startedAt,
          'stats': const {
            'toolCalls': 0,
            'tokensIn': 0,
            'tokensOut': 0,
            'subagents': 0,
          },
          'seed': _stableSeed(childId),
        });
      }
    }

    // O prédio representa sessões de agentes em execução, não apenas projetos
    // cadastrados no Orkest. Quando a última sessão some do snapshot, o Sim
    // Habblaud mantém a sala enquanto o personagem apaga a luz e sai; depois a
    // desmonta com a animação original.
    final occupiedProjects = projects
        .where(
          (project) =>
              sessions.any((session) => session.projectId == project.id),
        )
        .toList(growable: false);
    final effects = OfficeRoomEffectsManager.instance;
    effects.prune(now);
    final rooms = [
      for (var slot = 0; slot < occupiedProjects.length; slot++)
        {
          'id': occupiedProjects[slot].id,
          'name': occupiedProjects[slot].name,
          'path': occupiedProjects[slot].effectiveRoot,
          'slot': slot,
          'seed': _stableSeed(occupiedProjects[slot].id),
          'createdAt': occupiedProjects[slot].createdAt.millisecondsSinceEpoch,
          if (effects.getEffect(occupiedProjects[slot].id, now)
              case final effect?)
            'effect': effect.toMap(),
        },
    ];
    final accounts = [
      for (final entry in accountCounts.entries)
        {
          'id': entry.key,
          'provider': accountIdentities[entry.key]!.id,
          'short': accountIdentities[entry.key]!.short,
          'name': accountIdentities[entry.key]!.label,
          'color': '#596273',
          'configDir': '~/.orkest',
          'sessions': entry.value,
          'usageStatus': 'disabled',
        },
    ];

    return {
      'rev': ++_revision,
      'serverTime': now,
      'rooms': rooms,
      'agents': agents,
      'accounts': accounts,
      'options': {
        'locale': _officeLocale,
        'showNames': officeSettings.officeShowNames,
        'bubbles': officeSettings.officeBubbles,
        'liveliness': officeSettings.officeLiveliness,
        'daylight': officeSettings.officeDaylight,
        'dayNight': officeSettings.officeDaylight != 'day',
        'theme': officeSettings.officeTheme,
        'sound': officeSettings.officeSounds,
        'sounds': {
          'volume': officeSettings.officeSoundVolume / 100,
          'alerts': officeSettings.officeSoundAlerts,
          'keys': officeSettings.officeSoundKeys,
          'elevator': officeSettings.officeSoundElevator,
          'social': officeSettings.officeSoundSocial,
        },
      },
      'meta': {
        'demo': false,
        'sources': const <dynamic>[],
        'startedAt': now,
        'version': 'orkest',
      },
    };
  }

  Future<void> _pushSnapshot() async {
    if (!mounted) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => unawaited(_pushSnapshot()),
      );
      return;
    }
    final web = _web;
    if (!_loaded || web == null) return;
    context.read<SettingsController>().migrateOfficeCharacterParts({
      for (final session in _officeSessions)
        session.projectId: _legacyAppearanceOwner(session),
    });
    // Refresh the rendered PTY screen before computing the signature. A
    // harness may have started before Office was opened, so its current
    // activity cannot depend only on receiving a new output chunk.
    for (final session in widget.sessions.whereType<TerminalSession>()) {
      session.refreshOfficeActivityFromScreen();
    }
    final signature = _snapshotSignature();
    if (signature == _lastSnapshotSignature) return;
    final encoded = jsonEncode(_snapshot());
    await web.evaluateJavascript(
      source: 'window.orkestOfficeWorld?.update($encoded);',
    );
    _lastSnapshotSignature = signature;
  }

  String _snapshotSignature() => jsonEncode([
    context.read<SettingsController>().settings.officeTheme,
    _officeLocale,
    context.read<SettingsController>().settings.officeShowNames,
    context.read<SettingsController>().settings.officeBubbles,
    context.read<SettingsController>().settings.officeLiveliness,
    context.read<SettingsController>().settings.officeDaylight,
    context.read<SettingsController>().settings.officeSounds,
    context.read<SettingsController>().settings.officeSoundVolume,
    context.read<SettingsController>().settings.officeSoundAlerts,
    context.read<SettingsController>().settings.officeSoundKeys,
    context.read<SettingsController>().settings.officeSoundElevator,
    context.read<SettingsController>().settings.officeSoundSocial,
    context.read<SettingsController>().settings.officeCharacterParts,
    context.read<SettingsController>().settings.officeAgentNames,
    for (final project in widget.projects)
      [
        project.id,
        project.name,
        project.effectiveRoot,
        project.createdAt.millisecondsSinceEpoch,
      ],
    for (final session in widget.sessions.whereType<TerminalSession>()) ...[
      [
        session.id,
        session.officeIdentity,
        session.officeParentIdentity,
        session.officeShells,
        session.officeShellDone,
        session.officeTasks,
        session.projectId,
        session.displayTitle,
        session.activeHarness?.name,
        session.officeHarness.id,
        session.status.name,
        session.officeStatusHistory.length,
        if (session.officeStatusHistory.isNotEmpty)
          session.officeStatusHistory.last.at.millisecondsSinceEpoch,
        if (session.officeStatusHistory.isNotEmpty)
          session.officeStatusHistory.last.event,
        if (session.officeStatusHistory.isNotEmpty)
          session.officeStatusHistory.last.toolName,
        if (session.officeStatusHistory.isNotEmpty)
          session.officeStatusHistory.last.sequence,
        for (final subagent in session.officeSubagents)
          [
            subagent.id,
            subagent.type,
            subagent.startedAt.millisecondsSinceEpoch,
            subagent.finishedAt?.millisecondsSinceEpoch,
            subagent.outcome,
            subagent.parentSubagentId,
          ],
      ],
    ],
  ]);

  Object? _handleAgentClick(List<dynamic> arguments) {
    final id = arguments.isEmpty ? null : arguments.first;
    if (id is! String) return null;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (_lastOpenedAgent == id && now - _lastOpenedAt < 350) return null;
    _lastOpenedAgent = id;
    _lastOpenedAt = now;
    TerminalSession? session;
    for (final candidate in widget.sessions.whereType<TerminalSession>()) {
      if (candidate.id == id) {
        session = candidate;
        break;
      }
    }
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
          _showAgentProfile(
            context,
            session: selectedSession,
            project: project,
          ),
        );
      }
    }
    return null;
  }

  Map<String, OfficeAgentIdentity> _resolveAgentIdentities(
    List<TerminalSession> sessions,
    AppSettings settings,
  ) {
    final assigned = Map<String, String>.from(settings.officeAgentNames);
    final resolved = <String, OfficeAgentIdentity>{};
    final used = <String>{
      for (final session in sessions)
        if (session.manualLabel?.trim().isNotEmpty == true)
          session.manualLabel!.trim().toLowerCase(),
    };
    var changed = false;
    final sorted = [...sessions]..sort((a, b) => a.id.compareTo(b.id));
    for (final session in sorted) {
      final manual = session.manualLabel?.trim();
      if (manual != null && manual.isNotEmpty) {
        resolved[session.id] = (
          name: manual,
          look: officeAgentLookForName(
            manual,
            _stableSeed('${session.projectId}:${session.id}').isEven
                ? 'f'
                : 'm',
          ),
        );
        continue;
      }
      var name = assigned[session.id];
      if (name == null || used.contains(name.toLowerCase())) {
        final person = pickOfficeAgentIdentity(session.id, used);
        name = person.name;
        assigned[session.id] = name;
        changed = true;
      }
      used.add(name.toLowerCase());
      resolved[session.id] = (
        name: name,
        look: officeAgentLookForName(
          name,
          _stableSeed('${session.projectId}:${session.id}').isEven ? 'f' : 'm',
        ),
      );
    }
    if (changed) {
      context.read<SettingsController>().setOfficeAgentNames(assigned);
    }
    return resolved;
  }

  Future<void> _showAgentProfile(
    BuildContext context, {
    required TerminalSession session,
    required Project project,
  }) async {
    final settings = context.read<SettingsController>().settings;
    final identities = _resolveAgentIdentities(
      widget.sessions.whereType<TerminalSession>().toList(),
      settings,
    );
    final agentIdentity = identities[session.id];
    final web = _web;
    final portrait = await _portraitFor(session, project);
    if (!mounted || !context.mounted) return;
    await web?.evaluateJavascript(
      source:
          'window.orkestOfficeWorld?.selectAgent(${jsonEncode(session.id)});',
    );
    if (!mounted || !context.mounted) return;
    await showOfficeAgentProfile(
      context,
      session: session,
      project: project,
      officeName: agentIdentity?.name,
      portraitBytes: portrait?.body,
      loadSocial: () async => _socialBySession[session.id],
      parentAgentName: _officeSessions
          .where(
            (candidate) =>
                candidate.officeIdentity == session.officeParentIdentity,
          )
          .map(_agentName)
          .firstOrNull,
      loadPortrait: () async => (await _portraitFor(session, project))?.body,
      onOpenTerminal: () => widget.onOpenSession(session),
      onFollowAgent: (follow) {
        if (web != null) {
          unawaited(
            web.evaluateJavascript(
              source:
                  'window.orkestOfficeWorld?.setFollowAgent(${jsonEncode(session.id)}, $follow);',
            ),
          );
        }
      },
      onCenterAgent: () {
        if (web != null) {
          unawaited(
            web.evaluateJavascript(
              source:
                  'window.orkestOfficeWorld?.focusAgent(${jsonEncode(session.id)}, false);',
            ),
          );
        }
      },
      onRename: (name) {
        _portraitCache.remove(session.id);
        widget.onRenameSession(session, name);
      },
      initialAppearance: Map<String, String>.from(_appearanceFor(session)),
      loadAppearance: (parts) async {
        final draft = Map<String, String>.from(parts);
        final seed =
            int.tryParse(draft.remove('__seed') ?? '') ??
            _stableSeed('${session.projectId}:${session.id}');
        final look = agentIdentity?.look ?? (seed.isEven ? 'f' : 'm');
        final result = await web?.evaluateJavascript(
          source:
              'window.orkestOfficeWorld?.getAppearance($seed, ${jsonEncode(look)}, ${jsonEncode(draft)});',
        );
        final decoded = result is String ? jsonDecode(result) : result;
        if (decoded is! Map) throw StateError('Appearance preview unavailable');
        return decoded.cast<String, dynamic>();
      },
      onSaveAppearance: (parts) {
        _portraitCache.remove(session.id);
        context.read<SettingsController>().setOfficeAgentCharacterParts(
          projectId: project.id,
          sessionId: session.id,
          legacyOwnerSessionId: _legacyAppearanceOwner(session),
          parts: parts,
        );
        if (mounted) setState(() {});
        unawaited(_pushSnapshot());
      },
    );
    if (!mounted) return;
    await _web?.evaluateJavascript(
      source: 'window.orkestOfficeWorld?.selectAgent(null);',
    );
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _panelRefreshTimer?.cancel();
    _agentSearch.dispose();
    _web = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        final html = snapshot.data;
        final labels = context.t.orkest.officeWorld;
        if (snapshot.hasError) {
          return Center(child: Text(context.t.core.appErrorView.renderFailed));
        }
        if (html == null) return const SizedBox.expand();
        return Stack(
          fit: StackFit.expand,
          children: [
            WebViewCover(
              loaded: _loaded,
              child: WebViewEnvironmentGate(
                builder: (context, environment) => UnzoomedNativeView(
                  builder: (context, contentZoom) => InAppWebView(
                    key: const ValueKey('orkest-habblaud-world'),
                    webViewEnvironment: environment,
                    initialData: InAppWebViewInitialData(
                      data: html,
                      baseUrl: WebUri(_baseUrl),
                      mimeType: 'text/html',
                      encoding: 'utf-8',
                    ),
                    initialUserScripts: kWebViewUserScripts,
                    initialSettings: InAppWebViewSettings(
                      javaScriptEnabled: true,
                      isInspectable: true,
                      underPageBackgroundColor: webViewBackground(context),
                      pageZoom: contentZoom,
                      supportZoom: false,
                    ),
                    onWebViewCreated: (web) {
                      _web = web;
                      web.addJavaScriptHandler(
                        handlerName: 'officeAgentClicked',
                        callback: _handleAgentClick,
                      );
                      WebViewPointerRelay.register(web, context, contentZoom);
                    },
                    onLoadStop: (web, _) {
                      if (!mounted) return;
                      setState(() => _loaded = true);
                      unawaited(_pushSnapshot());
                    },
                  ),
                ),
              ),
            ),
            if (_sidebarVisible) _buildAgentSidebar(context),
            if (_activityVisible) _buildActivityFeed(context),
            if (!_sidebarVisible || !_activityVisible)
              Positioned(
                left: _sidebarVisible ? 12 : 16,
                bottom: _activityVisible ? 12 : 16,
                child: Row(
                  children: [
                    if (!_sidebarVisible)
                      _panelToggle(
                        context,
                        '☷',
                        labels.reopenRoster,
                        () => setState(() => _sidebarVisible = true),
                      ),
                    if (!_activityVisible && !_sidebarVisible)
                      const SizedBox(width: 8),
                    if (!_activityVisible)
                      _panelToggle(
                        context,
                        '☰',
                        labels.reopenFeed,
                        () => setState(() => _activityVisible = true),
                      ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  List<TerminalSession> get _officeSessions {
    final projectIds = widget.projects
        .where((project) => !project.isSystemTerminal)
        .map((project) => project.id)
        .toSet();
    return widget.sessions
        .whereType<TerminalSession>()
        .where(
          (session) =>
              projectIds.contains(session.projectId) &&
              session.hasOfficeAgentPresence,
        )
        .toList(growable: false);
  }

  Future<void> _refreshSocial() async {
    if (!mounted || !_loaded || _web == null || _readingSocial) return;
    _readingSocial = true;
    try {
      final raw = await _web!.evaluateJavascript(
        source: 'window.orkestOfficeWorld?.getSocialSnapshot?.();',
      );
      if (!mounted) return;
      final data = raw is String ? jsonDecode(raw) : raw;
      if (data is! Map || data['agents'] is! Map) return;
      _socialReadFailed = false;
      final signature = jsonEncode(data);
      if (signature == _socialSignature) return;
      _socialSignature = signature;
      final agents = data['agents'] as Map;
      final live = _officeSessions;
      final ids = live.map((session) => session.id).toSet();
      _socialBySession.removeWhere((id, _) => !ids.contains(id));
      for (final session in live) {
        final value = agents[session.id];
        if (value is! Map || value['identity'] != session.officeIdentity) {
          continue;
        }
        if (value['social'] is Map) {
          _socialBySession[session.id] = OfficeAgentSocial.fromJson(
            value['social'] as Map,
          );
        }
        if (value['state'] is Map) {
          session.updateOfficeSocialState(
            (value['state'] as Map).cast<String, dynamic>(),
          );
        }
      }
      _socialEvents =
          (data['events'] is List ? data['events'] as List : const [])
              .map(OfficeSocialEvent.fromJson)
              .whereType<OfficeSocialEvent>()
              .where((event) => ids.contains(event.agentId))
              .take(40)
              .toList();
      if (mounted) setState(() {});
    } catch (error, stack) {
      // A WebView may disappear while this asynchronous read is in flight.
      // Keep the last valid snapshot and retry on the next timer tick.
      if (mounted && !_socialReadFailed) {
        _socialReadFailed = true;
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'Orkest Office social bridge',
          ),
        );
      }
    } finally {
      _readingSocial = false;
    }
  }

  String _agentName(TerminalSession session) {
    final manual = session.manualLabel?.trim();
    if (manual != null && manual.isNotEmpty) return manual;
    final saved = context
        .read<SettingsController>()
        .settings
        .officeAgentNames[session.id];
    if (saved != null && saved.isNotEmpty) return saved;
    return session.displayTitle;
  }

  String _legacyAppearanceOwner(TerminalSession session) {
    final candidates =
        _officeSessions
            .where((candidate) => candidate.projectId == session.projectId)
            .toList()
          ..sort((a, b) {
            final byDate = a.createdAt.compareTo(b.createdAt);
            return byDate != 0 ? byDate : a.id.compareTo(b.id);
          });
    return candidates.isEmpty ? session.id : candidates.first.id;
  }

  Map<String, String> _appearanceFor(TerminalSession session) =>
      context.read<SettingsController>().settings.officeCharacterPartsForAgent(
        projectId: session.projectId,
        sessionId: session.id,
        legacyOwnerSessionId: _legacyAppearanceOwner(session),
      );

  Future<_OfficePortrait?> _portraitFor(
    TerminalSession session,
    Project project,
  ) {
    if (!_loaded) return Future.value(null);
    final parts = Map<String, String>.from(_appearanceFor(session));
    final cacheKey = jsonEncode([session.id, _agentName(session), parts]);
    if (_portraitSignatures[session.id] != cacheKey) {
      _portraitSignatures[session.id] = cacheKey;
      _portraitCache.remove(session.id);
    }
    return _portraitCache.putIfAbsent(session.id, () async {
      final web = _web;
      if (web == null) return null;
      final name = _agentName(session);
      final look = officeAgentLookForName(
        name,
        _stableSeed('${session.projectId}:${session.id}').isEven ? 'f' : 'm',
      );
      final result = await web.evaluateJavascript(
        source:
            'window.orkestOfficeWorld?.getAppearance(${_stableSeed('${session.projectId}:${session.id}')}, ${jsonEncode(look)}, ${jsonEncode(parts)});',
      );
      final decoded = result is String ? jsonDecode(result) : result;
      if (decoded is! Map ||
          decoded['preview'] is! String ||
          decoded['avatar'] is! String) {
        return null;
      }
      final body = _decodeImageDataUrl(decoded['preview'] as String);
      final face = _decodeImageDataUrl(decoded['avatar'] as String);
      if (body == null || face == null) return null;
      return (body: body, face: face);
    });
  }

  Uint8List? _decodeImageDataUrl(String value) {
    final comma = value.indexOf(',');
    if (comma < 0) return null;
    return base64Decode(value.substring(comma + 1));
  }

  Widget _buildAgentSidebar(BuildContext context) {
    final colors = context.colors;
    final labels = context.t.orkest.officeWorld;
    final query = _agentQuery.trim().toLowerCase();
    final sessions = _officeSessions.where((session) {
      if (query.isEmpty) return true;
      final project = widget.projects
          .where((item) => item.id == session.projectId)
          .firstOrNull;
      return '${_agentName(session)} ${project?.name ?? ''} ${session.activeHarness?.name ?? ''}'
          .toLowerCase()
          .contains(query);
    }).toList();
    final projectGroups = <Project, List<TerminalSession>>{};
    for (final session in sessions) {
      final project = widget.projects
          .where((item) => item.id == session.projectId)
          .firstOrNull;
      if (project != null) {
        projectGroups.putIfAbsent(project, () => []).add(session);
      }
    }
    return Positioned(
      left: 14,
      top: 14,
      bottom: _activityVisible ? 188 : 14,
      width: 292,
      child: _officePanel(
        colors,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _panelHeader(
              context,
              labels.rosterTitle,
              labels.collapseRoster,
              () => setState(() => _sidebarVisible = false),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: TextField(
                controller: _agentSearch,
                onChanged: (value) => setState(() => _agentQuery = value),
                style: TextStyle(color: colors.text, fontSize: 13),
                decoration: InputDecoration(
                  isDense: true,
                  hintText: labels.rosterSearch,
                  hintStyle: TextStyle(color: colors.text3),
                  filled: true,
                  fillColor: colors.panel3,
                  prefixIcon: const Icon(Icons.search, size: 17),
                  prefixIconColor: colors.text3,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: colors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                    borderSide: BorderSide(color: colors.accent),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(9),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 9,
                  ),
                ),
              ),
            ),
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          labels.rosterEmpty,
                          textAlign: TextAlign.center,
                          style: TextStyle(color: colors.text2, fontSize: 12),
                        ),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                      children: [
                        for (final entry in projectGroups.entries) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(8, 9, 8, 5),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.key.name,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.text,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                                _smallCount(entry.value.length, colors),
                              ],
                            ),
                          ),
                          for (final session in entry.value)
                            _agentRow(context, session, entry.key),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _agentRow(
    BuildContext context,
    TerminalSession session,
    Project project,
  ) {
    final colors = context.colors;
    final icon = switch (session.status) {
      TerminalStatus.working => '💻',
      TerminalStatus.waiting => '✋',
      TerminalStatus.idle => '🚶',
    };
    final harness = session.officeHarness.label;
    final title = session.title.trim();
    final description = title.isEmpty || title == 'New terminal'
        ? harness
        : title;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: colors.panel2,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => unawaited(
            _showAgentProfile(context, session: session, project: project),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FutureBuilder<_OfficePortrait?>(
                  future: _portraitFor(session, project),
                  builder: (context, snapshot) => _agentPortrait(
                    snapshot.data?.face,
                    colors,
                    size: 38,
                    fallback: icon,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _agentName(session),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: colors.text,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        description == harness
                            ? harness
                            : '$harness · $description',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colors.text2, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Abrir terminal',
                  visualDensity: VisualDensity.compact,
                  iconSize: 17,
                  onPressed: () => widget.onOpenSession(session),
                  icon: const Icon(Icons.terminal),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActivityFeed(BuildContext context) {
    final colors = context.colors;
    final labels = context.t.orkest.officeWorld;
    final rows =
        <
          ({
            TerminalSession session,
            Project project,
            TerminalStatusEvent event,
            String? socialIcon,
          })
        >[];
    for (final session in _officeSessions) {
      final project = widget.projects
          .where((item) => item.id == session.projectId)
          .firstOrNull;
      if (project == null) continue;
      for (final event in session.officeStatusHistory) {
        rows.add((
          session: session,
          project: project,
          event: event,
          socialIcon: null,
        ));
      }
    }
    for (final event in _socialEvents) {
      final session = _officeSessions
          .where((session) => session.id == event.agentId)
          .firstOrNull;
      if (session == null) continue;
      final project = widget.projects
          .where((p) => p.id == session.projectId)
          .firstOrNull;
      if (project == null) continue;
      rows.add((
        session: session,
        project: project,
        event: TerminalStatusEvent(
          session.status,
          event.at,
          activityKind: 'social',
          activitySummary: event.text,
        ),
        socialIcon: event.icon,
      ));
    }
    rows.sort((a, b) => b.event.at.compareTo(a.event.at));
    final recent = rows.take(50).toList(growable: false);
    return Positioned(
      left: _sidebarVisible ? 322 : 16,
      right: 16,
      bottom: 14,
      height: 174,
      child: _officePanel(
        colors,
        child: Column(
          children: [
            _panelHeader(
              context,
              labels.activityFeed,
              labels.collapseFeed,
              () => setState(() => _activityVisible = false),
            ),
            Expanded(
              child: recent.isEmpty
                  ? Center(
                      child: Text(
                        labels.activityEmpty,
                        style: TextStyle(color: colors.text2, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      reverse: false,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      itemCount: recent.length,
                      itemBuilder: (context, index) {
                        final row = recent[recent.length - 1 - index];
                        final time = row.event.at;
                        final clock =
                            '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        final summary = row.socialIcon == null
                            ? _activityLabel(context, row.event)
                            : '${labels.socialActivity}: ${row.event.activitySummary}';
                        return InkWell(
                          onTap: () => unawaited(
                            _showAgentProfile(
                              context,
                              session: row.session,
                              project: row.project,
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 42,
                                  child: Text(
                                    clock,
                                    style: TextStyle(
                                      color: colors.text3,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                SizedBox(
                                  width: 19,
                                  child: Text(
                                    row.socialIcon ?? _activityIcon(row.event),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                SizedBox(
                                  width: 23,
                                  height: 23,
                                  child: FutureBuilder<_OfficePortrait?>(
                                    future: _portraitFor(
                                      row.session,
                                      row.project,
                                    ),
                                    builder: (context, snapshot) =>
                                        _agentPortrait(
                                          snapshot.data?.face,
                                          colors,
                                          size: 23,
                                          fallback: '👤',
                                          fit: BoxFit.cover,
                                        ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                SizedBox(
                                  width: 100,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _agentName(row.session),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        row.session.activeHarness?.name ??
                                            'Orkest',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: colors.text3,
                                          fontSize: 9,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    summary,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: colors.text2,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 110,
                                  child: Text(
                                    row.project.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: colors.text3,
                                      fontSize: 10,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  String _activityLabel(BuildContext context, TerminalStatusEvent event) {
    final labels = context.t.orkest.officeWorld;
    return switch (event.activityKind) {
      'prompt' => labels.promptReceived,
      'respond' => labels.agentResponded,
      'thinking' => labels.agentThinking,
      'read' => labels.readingFile,
      'search' => labels.searchingCode,
      'edit' => labels.editingFile,
      'write' => labels.writingFile,
      'command' => labels.runningCommand,
      'wait' => labels.shellWaiting,
      'needs_input' => labels.waitingInTerminal,
      'test' => labels.runningTests,
      'web' => labels.browsingWeb,
      'plan' => labels.organizingTasks,
      'delegate' => labels.callingSubagents,
      'done' => labels.turnCompleted,
      'error' => labels.activityError,
      _ => labels.usingTool,
    };
  }

  String _activityIcon(TerminalStatusEvent event) =>
      switch (event.activityKind) {
        'prompt' => '📨',
        'respond' => '💬',
        'thinking' => '💭',
        'read' => '📖',
        'search' => '🔎',
        'edit' => '✏️',
        'write' => '📝',
        'command' => '💻',
        'wait' => '⏳',
        'needs_input' => '✋',
        'test' => '🧪',
        'web' => '🌐',
        'plan' => '🗒️',
        'delegate' => '👥',
        'done' => '✅',
        'error' => '⚠️',
        _ => '⚙️',
      };

  Widget _officePanel(AppColors colors, {required Widget child}) => Container(
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: colors.panel.withValues(alpha: 0.96),
      borderRadius: BorderRadius.circular(13),
      border: Border.all(color: colors.border2.withValues(alpha: 0.85)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 16,
          offset: Offset(0, 5),
        ),
      ],
    ),
    child: child,
  );

  Widget _panelHeader(
    BuildContext context,
    String title,
    String tooltip,
    VoidCallback onClose,
  ) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 5, 5, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: colors.text,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          IconButton(
            tooltip: tooltip,
            visualDensity: VisualDensity.compact,
            iconSize: 17,
            onPressed: onClose,
            icon: Icon(Icons.expand_less, color: context.colors.text2),
          ),
        ],
      ),
    );
  }

  Widget _panelToggle(
    BuildContext context,
    String icon,
    String label,
    VoidCallback onTap,
  ) => Material(
    color: context.colors.panel2,
    borderRadius: BorderRadius.circular(9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          '$icon  $label',
          style: TextStyle(color: context.colors.text, fontSize: 12),
        ),
      ),
    ),
  );

  Widget _smallCount(int count, AppColors colors) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
    decoration: BoxDecoration(
      color: colors.panel3,
      borderRadius: BorderRadius.circular(9),
    ),
    child: Text('$count', style: TextStyle(color: colors.text2, fontSize: 10)),
  );

  Widget _agentPortrait(
    Uint8List? bytes,
    AppColors colors, {
    required double size,
    required String fallback,
    BoxFit fit = BoxFit.contain,
  }) => Container(
    width: size,
    height: size,
    clipBehavior: Clip.antiAlias,
    decoration: BoxDecoration(
      color: colors.panel3,
      borderRadius: BorderRadius.circular(size * 0.24),
    ),
    child: bytes == null
        ? Center(
            child: Text(fallback, style: TextStyle(fontSize: size * 0.52)),
          )
        : Image.memory(bytes, fit: fit, filterQuality: FilterQuality.none),
  );
}

String get _officeLocale => switch (LocaleSettings.currentLocale) {
  AppLocale.en => 'en',
  AppLocale.es => 'es',
  AppLocale.ptBr => 'pt-BR',
};

Map<String, dynamic> _officeStatusActivity(
  TerminalStatus status,
  int at, {
  required String working,
  required String waiting,
  required String idle,
  required String prompt,
  required String reading,
  required String searching,
  required String editing,
  required String writing,
  required String command,
  required String tests,
  required String web,
  required String planning,
  required String delegate,
  required String toolComplete,
  required String usingTool,
  required String thinking,
  required String responded,
  required String activityError,
  String? hookEvent,
  String? toolName,
  String? activityKind,
  String? activityPhase,
  String? activitySummary,
  int sequence = 0,
}) {
  if (activityKind != null && activitySummary != null) {
    final icon = switch (activityKind) {
      'prompt' => '📨',
      'respond' => '💬',
      'thinking' => '💭',
      'read' => '📖',
      'search' => '🔎',
      'edit' => '✏️',
      'write' => '📝',
      'command' => '💻',
      'wait' => '⏳',
      'test' => '🧪',
      'web' => '🌐',
      'plan' => '🗒️',
      'delegate' => '👥',
      'needs_input' => '✋',
      'done' => '✅',
      'error' => '⚠️',
      'git' => switch (activitySummary.toLowerCase()) {
        final s when s.contains('falhou') || s.contains('failed') => '🚨',
        final s when s.contains('passou') || s.contains('passed') => '✅',
        final s when s.contains('enviou') || s.contains('push') => '🚀',
        _ => '🎉',
      },
      _ => '⚙️',
    };
    final observedLabel = switch (activityKind) {
      'prompt' => prompt,
      'respond' => responded,
      'thinking' => thinking,
      'read' => reading,
      'search' => searching,
      'edit' => editing,
      'write' => writing,
      'command' => command,
      'wait' => command,
      'needs_input' => waiting,
      'test' => tests,
      'web' => web,
      'plan' => planning,
      'delegate' => delegate,
      'done' => idle,
      'error' => activityError,
      'mcp' || 'other' => usingTool,
      _ => activitySummary,
    };
    final isObserved = activityPhase == 'observed';
    final label = isObserved ? observedLabel : activitySummary;
    final text =
        isObserved || activityPhase == null || activityPhase == 'started'
        ? label
        : '$label · $activityPhase';
    return {
      'id': 'orkest-activity-$at-$sequence',
      'kind': switch (activityKind) {
        'thinking' => 'think',
        'command' => 'run',
        'needs_input' => 'ask',
        'respond' => 'respond',
        _ => activityKind,
      },
      'icon': icon,
      'text': text.length > 72 ? '${text.substring(0, 71)}…' : text,
      'at': at,
      if (activityKind == 'git') 'tool': 'GitHub',
      if (activityKind == 'git' &&
          (activitySummary.toLowerCase().contains('falhou') ||
              activitySummary.toLowerCase().contains('failed')))
        'error': true,
    };
  }
  final tool = toolName?.trim();
  final toolLower = tool?.toLowerCase() ?? '';
  final (kind, icon, label) = switch (hookEvent) {
    'UserPromptSubmit' => ('prompt', '📨', prompt),
    'PreToolUse' => switch (toolLower) {
      'read' || 'notebookread' => ('read', '📖', reading),
      'glob' || 'grep' || 'search' => ('search', '🔎', searching),
      'edit' || 'multiedit' => ('edit', '✏️', editing),
      'write' => ('write', '📝', writing),
      'bash' || 'shell' => ('run', '💻', command),
      _ when toolLower.contains('test') => ('test', '🧪', tests),
      'websearch' || 'webfetch' => ('web', '🌐', web),
      'task' || 'agent' => ('delegate', '👥', delegate),
      'todowrite' || 'update_plan' => ('plan', '🗒️', planning),
      'askuserquestion' || 'exitplanmode' => ('ask', '✋', waiting),
      _ when toolLower.startsWith('mcp__') => ('mcp', '🔌', usingTool),
      _ => ('other', '⚙️', usingTool),
    },
    'PostToolUse' => ('run', '✅', toolComplete),
    'PermissionRequest' => ('ask', '✋', waiting),
    'Notification' when status == TerminalStatus.waiting => (
      'ask',
      '✋',
      waiting,
    ),
    'Stop' => ('done', '✅', idle),
    _ => switch (status) {
      TerminalStatus.working => ('run', '⚙️', working),
      TerminalStatus.waiting => ('ask', '✋', waiting),
      TerminalStatus.idle => ('done', '✅', idle),
    },
  };
  final text =
      tool != null &&
          tool.isNotEmpty &&
          (hookEvent == 'PreToolUse' || hookEvent == 'PostToolUse')
      ? '$label: $tool'
      : label;
  return {
    'id': 'orkest-${hookEvent ?? status.name}-$at-$sequence',
    'kind': kind,
    'icon': icon,
    'text': text.length > 46 ? '${text.substring(0, 45)}…' : text,
    if (tool != null && tool.isNotEmpty) 'tool': tool,
    'at': at,
  };
}

int _stableSeed(String value) => value.codeUnits.fold<int>(
  0x345678,
  (seed, unit) => (seed * 31 + unit) & 0x7fffffff,
);
