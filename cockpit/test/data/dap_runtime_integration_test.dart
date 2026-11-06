import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:path/path.dart' as p;

void main() {
  test(
    'real Dart adapter launches, stops at breakpoint, evaluates and terminates',
    () async {
      final configFile = File('.dart_tool/package_config.json').absolute;
      final packages =
          jsonDecode(await configFile.readAsString()) as Map<String, dynamic>;
      final flutter = (packages['packages'] as List)
          .cast<Map<String, dynamic>>()
          .firstWhere((package) => package['name'] == 'flutter');
      final flutterPackage = Directory.fromUri(
        configFile.uri.resolve(flutter['rootUri'] as String),
      );
      final flutterRoot = flutterPackage.parent.parent.path;
      final temp = await Directory.systemTemp.createTemp('orkest-dap-runtime-');
      final source = File(p.join(temp.path, 'main.dart'));
      await source.writeAsString(
        'void main() {\n  var value = 42;\n  print(value);\n}\n',
      );
      final controller = DebugSessionController();
      addTearDown(() async {
        await controller.stop();
        controller.dispose();
        await temp.delete(recursive: true);
      });
      final stopped = Completer<void>();
      final terminated = Completer<void>();
      var launched = false;
      controller.addListener(() {
        if (controller.isStopped &&
            controller.currentFrame != null &&
            !stopped.isCompleted) {
          stopped.complete();
        }
        if (launched && !controller.isActive && !terminated.isCompleted) {
          terminated.complete();
        }
      });
      await controller.toggleBreakpoint(source.path, 3);
      await controller.startFromRunConfiguration(
        config: RunConfiguration(
          id: 'real',
          name: 'real',
          type: 'dart',
          program: source.path,
          cwd: temp.path,
          sdkPath: p.join(flutterRoot, 'bin/cache/dart-sdk'),
        ),
      );
      launched = true;
      expect(
        controller.isActive,
        isTrue,
        reason: controller.consoleLogs.join('\n'),
      );
      await stopped.future.timeout(const Duration(seconds: 15));
      expect(controller.currentFrame!.sourcePath, source.path);
      expect(controller.currentFrame!.line, 3);
      expect(await controller.evaluate('value'), '42');
      await controller.resume();
      await terminated.future.timeout(const Duration(seconds: 15));
      expect(controller.isActive, isFalse);
    },
    timeout: const Timeout(Duration(seconds: 60)),
  );
}
