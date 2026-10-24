import 'dart:async';
import 'dart:convert';

import 'package:cockpit/app/cockpit/domain/entities/project.dart';
import 'package:cockpit/app/cockpit/ui/session/pane_item.dart';
import 'package:cockpit/app/cockpit/ui/session/terminal_session.dart';
import 'package:cockpit/app/core/ui/widgets/unzoomed_native_view.dart';
import 'package:cockpit/app/cockpit/ui/widgets/webview_chrome.dart';
import 'package:cockpit/app/core/domain/entities/harness.dart';
import 'package:cockpit/app/core/ui/settings_controller.dart';
import 'package:cockpit/app/cockpit/ui/widgets/office_agent_profile_dialog.dart';
import 'package:cockpit/app/cockpit/ui/widgets/office_agent_names.dart';
import 'package:cockpit/app/core/domain/entities/app_settings.dart';
import 'package:cockpit/i18n/strings.g.dart';
import 'package:flutter/services.dart';
import 'package:flutter_modular/flutter_modular.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Runs Habblaud's original simulation and Canvas 2D renderer in the local
/// WebView, feeding it snapshots synthesized from Cockpit projects/sessions.
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
  static const _engineAsset = 'assets/habblaud_world/engine.js';
  static const _baseUrl = 'https://cockpit.local/habblaud-world/';

  InAppWebViewController? _web;
  Future<String>? _htmlFuture;
  bool _loaded = false;
  int _revision = 0;
  Timer? _snapshotTimer;
  String? _lastSnapshotSignature;
  String? _lastOpenedAgent;
  int _lastOpenedAt = 0;
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
          (session) =>
              session.activeHarness != null &&
              projectIds.contains(session.projectId),
        )
        .toList(growable: false);
    final identities = _resolveAgentIdentities(sessions, officeSettings);
    final accountCounts = <String, int>{};
    final agents = <Map<String, dynamic>>[];
    final officeLabels = context.t.cockpit.officeWorld;

    for (final session in sessions) {
      final harness = session.activeHarness!;
      final identity = identities[session.id]!;
      final provider = _providerFor(harness);
      final accountId = 'cockpit-$provider';
      accountCounts.update(accountId, (count) => count + 1, ifAbsent: () => 1);
      final previousStatus = _lastStatuses[session.id];
      if (previousStatus != session.status) {
        _lastStatuses[session.id] = session.status;
        _statusSince[session.id] = now;
      }
      final seed = _stableSeed('${session.projectId}:${session.id}');
      final recent = [
        for (final event in session.officeStatusHistory)
          _officeStatusActivity(
            event.status,
            event.at.millisecondsSinceEpoch,
            working: officeLabels.workingInTerminal,
            waiting: officeLabels.waitingInTerminal,
            idle: officeLabels.turnCompleted,
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
            )
          : recent.last;
      agents.add({
        'id': session.id,
        'kind': 'main',
        if (provider != 'claude') 'provider': provider,
        'roomId': session.projectId,
        'name': identity.name,
        'look': identity.look,
        'role': 'Cockpit agent',
        'title': session.title,
        'sessionId': session.id,
        'account': accountId,
        'status': _statusFor(session.status),
        if (session.status == TerminalStatus.waiting)
          'waitingFor': officeLabels.waitingBubble,
        'activity': latestActivity,
        'recent': recent.isEmpty
            ? [latestActivity]
            : recent.skip(recent.length > 30 ? recent.length - 30 : 0).toList(),
        'tasks': const <dynamic>[],
        'startedAt': session.createdAt.millisecondsSinceEpoch,
        'lastEventAt': now,
        'statusSince': _statusSince[session.id] ?? now,
        // O contrato Habblaud exige AgentStats. São placeholders internos para
        // simulação; o perfil Cockpit não os apresenta como medições.
        'stats': const {
          'toolCalls': 0,
          'tokensIn': 0,
          'tokensOut': 0,
          'subagents': 0,
        },
        'seed': seed,
        if (officeSettings.officeCharacterParts[session.projectId] != null)
          'parts': officeSettings.officeCharacterParts[session.projectId],
      });
    }

    final rooms = [
      for (var slot = 0; slot < projects.length; slot++)
        {
          'id': projects[slot].id,
          'name': projects[slot].name,
          'path': projects[slot].effectiveRoot,
          'slot': slot,
          'seed': _stableSeed(projects[slot].id),
          'createdAt': projects[slot].createdAt.millisecondsSinceEpoch,
        },
    ];
    final accounts = [
      for (final entry in accountCounts.entries)
        {
          'id': entry.key,
          if (entry.key != 'cockpit-claude')
            'provider': entry.key.substring('cockpit-'.length),
          'short': _providerShort(entry.key),
          'name': 'Cockpit ${_providerShort(entry.key)}',
          'color': _providerColor(entry.key),
          'configDir': '~/.cockpit',
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
        'version': 'cockpit',
      },
    };
  }

  Future<void> _pushSnapshot() async {
    final web = _web;
    if (!_loaded || web == null) return;
    final signature = _snapshotSignature();
    if (signature == _lastSnapshotSignature) return;
    final encoded = jsonEncode(_snapshot());
    await web.evaluateJavascript(
      source: 'window.cockpitHabblaudWorld?.update($encoded);',
    );
    _lastSnapshotSignature = signature;
  }

  String _snapshotSignature() => jsonEncode([
    context.read<SettingsController>().settings.officeTheme,
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
        session.projectId,
        session.displayTitle,
        session.activeHarness?.name,
        session.status.name,
        session.officeStatusHistory.length,
        if (session.officeStatusHistory.isNotEmpty)
          session.officeStatusHistory.last.at.millisecondsSinceEpoch,
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
      widget.sessions
          .whereType<TerminalSession>()
          .where((item) => item.activeHarness != null)
          .toList(),
      settings,
    );
    final agentIdentity = identities[session.id];
    final web = _web;
    await web?.evaluateJavascript(
      source:
          'window.cockpitHabblaudWorld?.selectAgent(${jsonEncode(session.id)});',
    );
    if (!mounted || !context.mounted) return;
    await showOfficeAgentProfile(
      context,
      session: session,
      project: project,
      officeName: agentIdentity?.name,
      onOpenTerminal: () => widget.onOpenSession(session),
      onRename: (name) => widget.onRenameSession(session, name),
      initialAppearance: Map<String, String>.from(
        context
                .read<SettingsController>()
                .settings
                .officeCharacterParts[project.id] ??
            const <String, String>{},
      ),
      loadAppearance: (parts) async {
        final draft = Map<String, String>.from(parts);
        final seed =
            int.tryParse(draft.remove('__seed') ?? '') ??
            _stableSeed('${session.projectId}:${session.id}');
        final look = agentIdentity?.look ?? (seed.isEven ? 'f' : 'm');
        final result = await web?.evaluateJavascript(
          source:
              'window.cockpitHabblaudWorld?.getAppearance($seed, ${jsonEncode(look)}, ${jsonEncode(draft)});',
        );
        final decoded = result is String ? jsonDecode(result) : result;
        if (decoded is! Map) throw StateError('Appearance preview unavailable');
        return decoded.cast<String, dynamic>();
      },
      onSaveAppearance: (parts) => context
          .read<SettingsController>()
          .setOfficeCharacterParts(project.id, parts),
    );
    if (!mounted) return;
    await _web?.evaluateJavascript(
      source: 'window.cockpitHabblaudWorld?.selectAgent(null);',
    );
  }

  @override
  void dispose() {
    _snapshotTimer?.cancel();
    _web = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _htmlFuture,
      builder: (context, snapshot) {
        final html = snapshot.data;
        if (html == null) return const SizedBox.expand();
        return WebViewCover(
          loaded: _loaded,
          child: WebViewEnvironmentGate(
            builder: (context, environment) => UnzoomedNativeView(
              builder: (context, contentZoom) => InAppWebView(
                key: const ValueKey('cockpit-habblaud-world'),
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
        );
      },
    );
  }
}

String _statusFor(TerminalStatus status) => switch (status) {
  TerminalStatus.working => 'working',
  TerminalStatus.waiting => 'waiting',
  TerminalStatus.idle => 'idle',
};

Map<String, dynamic> _officeStatusActivity(
  TerminalStatus status,
  int at, {
  required String working,
  required String waiting,
  required String idle,
}) => switch (status) {
  TerminalStatus.working => {
    'id': 'cockpit-status-working-$at',
    'kind': 'run',
    'icon': '⚙️',
    'text': working,
    'at': at,
  },
  TerminalStatus.waiting => {
    'id': 'cockpit-status-waiting-$at',
    'kind': 'ask',
    'icon': '✋',
    'text': waiting,
    'at': at,
  },
  TerminalStatus.idle => {
    'id': 'cockpit-status-idle-$at',
    'kind': 'done',
    'icon': '✅',
    'text': idle,
    'at': at,
  },
};

String _providerFor(HarnessKind harness) => switch (harness) {
  HarnessKind.codex => 'codex',
  HarnessKind.antigravity => 'antigravity',
  HarnessKind.claudeCode ||
  HarnessKind.cursor ||
  HarnessKind.gitHubCopilot ||
  HarnessKind.openCode ||
  HarnessKind.pi => 'claude',
};

String _providerShort(String accountId) => switch (accountId) {
  'cockpit-codex' => 'CD',
  'cockpit-antigravity' => 'AG',
  _ => 'CO',
};

String _providerColor(String accountId) => switch (accountId) {
  'cockpit-codex' => '#6977e8',
  'cockpit-antigravity' => '#43a77a',
  _ => '#596273',
};

int _stableSeed(String value) => value.codeUnits.fold<int>(
  0x345678,
  (seed, unit) => (seed * 31 + unit) & 0x7fffffff,
);
