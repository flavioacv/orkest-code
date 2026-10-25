import 'dart:io' show Platform;

import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/ui/session/pane_item.dart';
import 'package:orkest_code/app/orkest/ui/session/terminal_session.dart';
import 'package:orkest_code/app/orkest/ui/widgets/habblaud_world_webview.dart';
import 'package:orkest_code/app/orkest/ui/widgets/office_world_flutter_view.dart';
import 'package:flutter/widgets.dart';

export 'package:orkest_code/app/orkest/ui/widgets/office_world_flutter_view.dart'
    show OfficeWorldLabels;

/// Office view backed by Habblaud's Canvas 2D renderer where an embedded
/// WebView is available, with the Flutter renderer retained for Linux.
class OfficeWorldView extends StatelessWidget {
  const OfficeWorldView({
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
  Widget build(BuildContext context) {
    if (Platform.isLinux) {
      return OfficeWorldFlutterView(
        projects: projects,
        sessions: sessions,
        labels: labels,
        onOpenSession: onOpenSession,
        onRenameSession: onRenameSession,
      );
    }
    return HabblaudWorldWebView(
      projects: projects,
      sessions: sessions,
      onOpenSession: onOpenSession,
      onRenameSession: onRenameSession,
    );
  }
}
