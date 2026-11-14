import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_codec.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';
import 'package:orkest_code/app/core/ui/themes/themes.dart';
import 'package:orkest_code/app/core/ui/widgets/code_editing_controller.dart';
import 'package:orkest_code/app/orkest/domain/entities/run_configuration.dart';
import 'package:orkest_code/app/orkest/ui/widgets/code_editor.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_panel.dart';
import 'package:orkest_code/app/orkest/ui/widgets/debug_toolbar.dart';
import 'package:orkest_code/i18n/strings.g.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

class _MockServer {
  final StreamController<List<int>> input = StreamController<List<int>>();
  final StreamController<List<int>> output = StreamController<List<int>>();

  _MockServer() {
    const DapCodec().decodeStream(input.stream).listen(_handleRequest);
  }

  void emitEvent(String event, [Map<String, dynamic>? body]) {
    final msg = DapEvent(seq: 999, event: event, body: body).toJson();
    output.add(DapCodec.encode(msg));
  }

  void _handleRequest(Map<String, dynamic> req) {
    final command = req['command'] as String;
    final seq = req['seq'] as int;
    if (command == 'launch' || command == 'attach') {
      output.add(
        DapCodec.encode({'seq': 998, 'type': 'event', 'event': 'initialized'}),
      );
    }

    final body = <String, dynamic>{};
    switch (command) {
      case 'initialize':
        body['supportsConfigurationDoneRequest'] = true;
        body['supportsTerminateRequest'] = true;
        body['supportsFunctionBreakpoints'] = true;
        break;
      case 'setBreakpoints':
        final rawArgs = req['arguments'] as Map<String, dynamic>?;
        final rawBps = rawArgs?['breakpoints'] as List? ?? [];
        body['breakpoints'] = [
          for (var i = 0; i < rawBps.length; i++)
            {'id': i + 1, 'verified': true, 'line': rawBps[i]['line']},
        ];
        break;
      case 'threads':
        body['threads'] = [
          {'id': 1, 'name': 'main.dart'},
        ];
        break;
      case 'stackTrace':
        body['stackFrames'] = [
          {
            'id': 10,
            'name': 'doSomething',
            'line': 88,
            'column': 4,
            'source': {'path': '/project/lib/service.dart'},
          },
        ];
        break;
      case 'scopes':
        body['scopes'] = [
          {'name': 'Locals', 'variablesReference': 100},
        ];
        break;
      case 'variables':
        body['variables'] = [
          {'name': 'status', 'value': '"ok"', 'type': 'String'},
        ];
        break;
      case 'evaluate':
        body['result'] = '42';
        body['type'] = 'int';
        body['variablesReference'] = 0;
        break;
    }

    final resp = DapResponse(
      seq: seq + 100,
      requestSeq: seq,
      success: true,
      command: command,
      body: body,
    ).toJson();
    output.add(DapCodec.encode(resp));
  }

  Future<void> close() async {
    await input.close();
    await output.close();
  }
}

Widget _wrapWithTheme(Widget child) {
  final tokens = buildTokens(brightness: Brightness.dark);
  return TranslationProvider(
    child: ShadcnApp(
      theme: buildTheme(brightness: Brightness.dark),
      home: OrkestTheme(
        colors: tokens.colors,
        typo: tokens.typo,
        syntax: tokens.syntax,
        terminal: tokens.terminal,
        child: SizedBox(width: 600, height: 600, child: child),
      ),
    ),
  );
}

void main() {
  group('Debug UI Widgets', () {
    late _MockServer server;
    late DapClient client;
    late DebugSessionController controller;

    setUp(() {
      server = _MockServer();
      client = DapClient(
        stdout: server.output.stream,
        stdin: server.input.sink,
        sessionId: 'ui-session',
      );
      controller = DebugSessionController();
    });

    tearDown(() async {
      await controller.stop();
      controller.dispose();
      await client.close();
      await server.close();
    });

    testWidgets(
      'DebugToolbar renderiza botões e reflete estado pausado/rodando',
      (tester) async {
        await tester.pumpWidget(
          _wrapWithTheme(DebugToolbar(controller: controller)),
        );

        // Inativo: nada exibido
        expect(find.byType(DebugToolbar), findsOneWidget);
        expect(find.text('PAUSADO'), findsNothing);
        expect(find.text('RODANDO'), findsNothing);

        // Inicia sessão sob runAsync
        await tester.runAsync(() async {
          await controller.startSession(
            client: client,
            program: '/project/lib/main.dart',
          );
          await Future<void>.delayed(const Duration(milliseconds: 20));
        });
        await tester.pump();

        expect(find.byKey(const ValueKey('debug-pause')), findsOneWidget);
        expect(controller.isRunning, isTrue);

        // Simula interrupção em breakpoint
        await tester.runAsync(() async {
          server.emitEvent('stopped', {'reason': 'breakpoint', 'threadId': 1});
          await Future<void>.delayed(const Duration(milliseconds: 30));
        });
        await tester.pump();

        expect(find.byKey(const ValueKey('debug-resume')), findsOneWidget);
      },
    );

    testWidgets('DebugPanel exibe Call Stack, Variáveis e Breakpoints', (
      tester,
    ) async {
      String? navigatedPath;
      int? navigatedLine;

      await controller.toggleBreakpoint('/project/lib/main.dart', 42);

      await tester.pumpWidget(
        _wrapWithTheme(
          DebugPanel(
            controller: controller,
            onNavigateToSource: (path, line, col) {
              navigatedPath = path;
              navigatedLine = line;
            },
          ),
        ),
      );

      // Breakpoint presente
      expect(find.text('Breakpoints'), findsOneWidget);
      expect(find.text('42'), findsOneWidget);

      // Clica no breakpoint para navegar
      await tester.tap(find.text('42'));
      await tester.pump();
      expect(navigatedPath, equals('/project/lib/main.dart'));
      expect(navigatedLine, equals(42));

      // Inicia sessão e para no frame
      await tester.runAsync(() async {
        await controller.startSession(
          client: client,
          program: '/project/lib/main.dart',
        );
        server.emitEvent('stopped', {'reason': 'breakpoint', 'threadId': 1});
        await Future<void>.delayed(const Duration(milliseconds: 40));
      });
      await tester.pump();

      // Call Stack e Variáveis carregadas
      await tester.runAsync(() async {
        for (final scope in controller.scopes) {
          await controller.variablesFor(scope.variablesReference);
        }
      });
      await tester.pumpAndSettle();
      expect(find.text('Call Stack'), findsOneWidget);
      expect(find.textContaining('doSomething'), findsOneWidget);
      expect(find.text('Variables'), findsOneWidget);
      expect(find.textContaining('status', findRichText: true), findsWidgets);
      expect(find.textContaining('"ok"', findRichText: true), findsWidgets);
    });

    testWidgets(
      'DebugPanel renderiza launcher de RunConfiguration e gerencia Watches',
      (tester) async {
        RunConfiguration? startedConfig;
        const testConfig = RunConfiguration(
          id: 'cfg-1',
          name: 'Executar Servidor',
          type: 'dart',
          program: 'bin/server.dart',
          cwd: '.',
        );

        await tester.pumpWidget(
          _wrapWithTheme(
            DebugPanel(
              controller: controller,
              configurations: const [testConfig],
              onStartConfiguration: (cfg) => startedConfig = cfg,
            ),
          ),
        );

        // Launcher visível
        expect(find.text('Executar Servidor'), findsOneWidget);
        expect(find.byKey(const ValueKey('run-config-start')), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('run-config-start')));
        await tester.pump();
        expect(startedConfig?.name, equals('Executar Servidor'));

        // Watches
        expect(find.text('Watch'), findsOneWidget);
        await tester.tap(find.byKey(const ValueKey('debug-add-watch')));
        await tester.pump();

        expect(find.byKey(const ValueKey('debug-watch-input')), findsOneWidget);
        await tester.enterText(
          find.byKey(const ValueKey('debug-watch-input')),
          'myCounter',
        );
        await tester.tap(find.byKey(const ValueKey('debug-add-watch')));
        await tester.pump();

        expect(controller.watchExpressions, contains('myCounter'));
        expect(find.text('Watch'), findsOneWidget);
        expect(
          find.textContaining('myCounter', findRichText: true),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'CodeEditor renderiza breakpoints e activeDebugLine no gutter',
      (tester) async {
        int? toggledLine;
        const code = 'void main() {\n  final x = 1;\n  print(x);\n}\n';
        final editCtrl = CodeEditingController(text: code, language: 'dart');
        final focusNode = FocusNode();

        await tester.pumpWidget(
          _wrapWithTheme(
            CodeEditor(
              controller: editCtrl,
              focusNode: focusNode,
              filePath: '/project/lib/main.dart',
              breakpoints: const {2},
              activeDebugLine: 2,
              onToggleBreakpoint: (line) => toggledLine = line,
            ),
          ),
        );

        // Breakpoint na linha 2 desenhado no gutter
        expect(
          find.byKey(const ValueKey('debug-breakpoint-gutter:2')),
          findsOneWidget,
        );
        // Indicador de linha ativa (seta amarela) desenhado no gutter
        expect(
          find.byKey(const ValueKey('debug-active-line:2')),
          findsOneWidget,
        );

        // Clica no gutter da linha 1 para alternar breakpoint
        await tester.tap(
          find.byKey(const ValueKey('code-editor-gutter-line:1')),
        );
        await tester.pump();
        expect(toggledLine, equals(1));

        editCtrl.dispose();
        focusNode.dispose();
      },
    );
  });
}
