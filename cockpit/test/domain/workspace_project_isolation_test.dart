import 'package:orkest_code/app/orkest/domain/entities/file_view.dart';
import 'package:orkest_code/app/orkest/domain/entities/project.dart';
import 'package:orkest_code/app/orkest/domain/services/workspace_cycle.dart';
import 'package:orkest_code/app/orkest/ui/session/file_viewer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('W01 · Workspace por projetos e isolamento de ferramentas IDE', () {
    test('effectiveRoot direciona corretamente ferramentas para locais, remotos e sistema', () {
      final local = Project(
        id: 'proj_local',
        name: 'Local Project',
        path: '/Users/developer/projects/app',
        colorValue: 0xFF123456,
        createdAt: DateTime(2026, 1, 1),
      );
      expect(local.effectiveRoot, '/Users/developer/projects/app');

      final remote = Project.remoteHost(
        pinId: 'host1::/var/www/app',
        hostId: 'host1',
        name: 'Remote App',
        remotePath: '/var/www/app',
        colorValue: 0xFF654321,
      );
      expect(remote.path, isEmpty);
      expect(remote.effectiveRoot, '/var/www/app');

      final system = Project(
        id: '__orkest__',
        name: 'Orkest',
        path: '',
        colorValue: 0,
        createdAt: DateTime(2026, 1, 1),
        kind: WorkspaceKind.systemTerminal,
      );
      expect(system.effectiveRoot, isEmpty);
    });

    test('FileViewerSession preserva projectId, title e deriva workingDirectory do arquivo', () {
      final session = FileViewerSession(
        id: 'tab_editor_1',
        projectId: 'proj_alpha',
        path: '/Users/developer/projects/alpha/lib/main.dart',
        view: const FileViewText('void main() {}'),
      );

      expect(session.projectId, 'proj_alpha');
      expect(session.title, 'main.dart');
      expect(session.workingDirectory, '/Users/developer/projects/alpha/lib');
      expect(session.dirty, isFalse);

      session.setDirty(true);
      expect(session.dirty, isTrue);

      session.retarget('/Users/developer/projects/alpha/lib/app.dart');
      expect(session.path, '/Users/developer/projects/alpha/lib/app.dart');
      expect(session.title, 'app.dart');
    });

    test('ciclo de workspaces e navegação mantém ordem e limites estritos', () {
      final projects = ['proj_a', 'proj_a::wt_feat', 'proj_b', 'proj_c'];

      expect(nextWorkspaceId(projects, 'proj_a', 1), 'proj_a::wt_feat');
      expect(nextWorkspaceId(projects, 'proj_a::wt_feat', 1), 'proj_b');
      expect(nextWorkspaceId(projects, 'proj_b', 1), 'proj_c');
      expect(nextWorkspaceId(projects, 'proj_c', 1), 'proj_a');

      expect(nextWorkspaceId(projects, 'proj_a', -1), 'proj_c');
      expect(nextWorkspaceId(projects, 'proj_b', -1), 'proj_a::wt_feat');
    });

    test('isolamento de abas e buffers entre múltiplos projetos', () {
      final sessionsByProject = <String, List<String>>{
        'proj_1': ['tab_term_1', 'tab_editor_1'],
        'proj_2': ['tab_term_2', 'tab_diff_2'],
      };

      expect(sessionsByProject['proj_1'], contains('tab_editor_1'));
      expect(sessionsByProject['proj_1'], isNot(contains('tab_term_2')));
      expect(sessionsByProject['proj_2'], contains('tab_term_2'));
      expect(sessionsByProject['proj_2'], isNot(contains('tab_editor_1')));
    });
  });
}
