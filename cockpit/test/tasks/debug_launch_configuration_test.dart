import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/run_configuration_loader.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'launch variables expand recursively while adapter port remains a template',
    () {
      final root = p.join(Directory.systemTemp.path, 'example');
      final file = p.join(root, 'src', 'app.py');
      final result = RunConfigurationLoader.expand(
        {
          'program': r'${file}',
          'args': [
            r'${fileBasename}',
            r'${fileBasenameNoExtension}',
            r'${fileExtname}',
            r'${relativeFile}',
          ],
          'cwd': r'${cwd}',
          'folder': r'${workspaceFolderBasename}',
          'adapter': {
            'args': [r'--port=${port}'],
          },
        },
        root,
        file,
      );
      expect(result['program'], file);
      expect(result['args'], ['app.py', 'app', '.py', p.join('src', 'app.py')]);
      expect(result['cwd'], root);
      expect(result['folder'], 'example');
      expect((result['adapter'] as Map)['args'], [r'--port=${port}']);
    },
  );

  test(
    'launch environment expansion fails explicitly for missing variables',
    () {
      final entry = Platform.environment.entries.first;
      expect(
        RunConfigurationLoader.expand(
          {'value': '\${env:${entry.key}}'},
          '/repo',
          null,
        )['value'],
        entry.value,
      );
      expect(
        () => RunConfigurationLoader.expand(
          {'value': r'${env:ORKEST_DEBUG_MISSING_ENV_9187}'},
          '/repo',
          null,
        ),
        throwsFormatException,
      );
      expect(
        () => RunConfigurationLoader.expand(
          {'value': r'${command:unregistered}'},
          '/repo',
          null,
        ),
        throwsFormatException,
      );
    },
  );

  test('configuration identity survives reordering launch.json', () async {
    final root = await Directory.systemTemp.createTemp('orkest-debug-config-');
    addTearDown(() => root.delete(recursive: true));
    final launch = File(p.join(root.path, '.vscode', 'launch.json'));
    await launch.parent.create(recursive: true);
    await launch.writeAsString('''{"configurations":[
      {"name":"A","type":"python","program":"a.py"},
      {"name":"B","type":"python","program":"b.py"}
    ]}''');
    const loader = RunConfigurationLoader();
    final before = await loader.load(root.path, null);
    await launch.writeAsString('''{"configurations":[
      {"name":"B","type":"python","program":"b.py"},
      {"name":"A","type":"python","program":"a.py"}
    ]}''');
    final after = await loader.load(root.path, null);
    expect(before.first.id, after.last.id);
    expect(before.last.id, after.first.id);
  });
}
