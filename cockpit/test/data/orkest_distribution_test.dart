import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/brand/app_identity.dart';
import 'package:orkest_code/app/orkest/data/hooks/claude_hook_installer_impl.dart';
import 'package:orkest_code/app/orkest/data/hooks/codex_hook_installer_impl.dart';
import 'package:orkest_code/app/orkest/data/update/update_checker_impl.dart';

void main() {
  test('independent distribution has no implicit update endpoint', () async {
    expect(AppIdentity.applicationId, 'com.flavioacv.orkestcode');
    expect(AppIdentity.cli, 'orkest');
    expect(AppIdentity.homeDirectory, '.orkest');
    expect(AppIdentity.updatesEnabled, isFalse);
    expect(UpdateCheckerImpl.defaultManifestUrl, isEmpty);
    expect(await const UpdateCheckerImpl().fetchLatest(), isNull);
  });

  for (final codex in [false, true]) {
    test(
      '${codex ? 'Codex' : 'Claude'} preserves original Cockpit hooks',
      () async {
        final home = await Directory.systemTemp.createTemp('orkest-isolation-');
        addTearDown(() => home.delete(recursive: true));
        final file = File(
          '${home.path}/${codex ? '.codex/hooks.json' : '.claude/settings.json'}',
        );
        await file.parent.create(recursive: true);
        const event = 'Stop';
        const original = {
          'matcher': '',
          'hooks': [
            {
              'type': 'command',
              '_cockpit': 'v1',
              'command': '"/home/test/.cockpit/bin/cockpit" hook',
            },
          ],
        };
        await file.writeAsString(
          jsonEncode({
            'hooks': {
              event: [original],
            },
          }),
        );
        for (var pass = 0; pass < 2; pass++) {
          if (codex) {
            await const CodexHookInstallerImpl().writeConfig(
              home: home.path,
              command: '"/home/test/.orkest/bin/orkest" hook',
            );
          } else {
            await const ClaudeHookInstallerImpl().writeConfig(
              home: home.path,
              command: '"/home/test/.orkest/bin/orkest" hook',
            );
          }
        }
        final groups =
            (jsonDecode(await file.readAsString())['hooks'][event] as List);
        expect(
          groups.where((group) => jsonEncode(group) == jsonEncode(original)),
          hasLength(1),
        );
        expect(jsonEncode(groups), contains('_orkest'));
      },
    );
  }
}
