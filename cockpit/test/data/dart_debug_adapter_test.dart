import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/dap_client.dart';
import 'package:orkest_code/app/core/data/dap/dap_codec.dart';
import 'package:orkest_code/app/core/data/dap/dap_models.dart';
import 'package:orkest_code/app/core/data/dap/dart_debug_adapter.dart';
import 'package:orkest_code/app/core/data/dap/debug_session_controller.dart';

class _MockDartDapServer {
  final StreamController<List<int>> input = StreamController<List<int>>();
  final StreamController<List<int>> output = StreamController<List<int>>();

  final List<String> receivedCommands = [];
  final List<Map<String, dynamic>> receivedRequests = [];

  _MockDartDapServer() {
    const DapCodec().decodeStream(input.stream).listen(_handleRequest);
  }

  void _handleRequest(Map<String, dynamic> req) {
    final command = req['command'] as String;
    final seq = req['seq'] as int;
    receivedCommands.add(command);
    receivedRequests.add(req);

    final body = <String, dynamic>{};
    var success = true;
    String? message;

    switch (command) {
      case 'initialize':
        body['supportsConfigurationDoneRequest'] = true;
        body['supportsTerminateRequest'] = true;
        break;
      case 'setExceptionBreakpoints':
        break;
      case 'launch':
        break;
      case 'hotReload':
        // Sucesso por padrão
        break;
      case 'hotRestart':
        // Sucesso por padrão
        break;
      case 'disconnect':
        break;
    }

    final resp = DapResponse(
      seq: seq + 100,
      requestSeq: seq,
      success: success,
      command: command,
      body: body,
      message: message,
    ).toJson();
    output.add(DapCodec.encode(resp));
  }

  Future<void> close() async {
    await input.close();
    await output.close();
  }
}

void main() {
  group('DartDebugAdapter - Resolução de Comandos e Argumentos', () {
    test('resolve comando oficial para Dart CLI e Dart Test', () {
      final (exeCli, argsCli) = DartDebugAdapter.resolveAdapterCommand(
        kind: DartDebugType.dartCli,
      );
      expect(exeCli, equals('dart'));
      expect(argsCli, equals(['debug_adapter']));

      final (exeTest, argsTest) = DartDebugAdapter.resolveAdapterCommand(
        kind: DartDebugType.dartTest,
        sdkPath: '/opt/dart-sdk',
      );
      expect(exeTest, equals('/opt/dart-sdk/bin/dart'));
      expect(argsTest, equals(['debug_adapter']));
    });

    test('resolve comando oficial para Flutter App e Flutter Test', () {
      final (exeApp, argsApp) = DartDebugAdapter.resolveAdapterCommand(
        kind: DartDebugType.flutterApp,
      );
      expect(exeApp, equals('flutter'));
      expect(argsApp, equals(['debug_adapter']));

      final (exeFlutterTest, argsFlutterTest) =
          DartDebugAdapter.resolveAdapterCommand(
        kind: DartDebugType.flutterTest,
        sdkPath: '/opt/flutter',
      );
      expect(exeFlutterTest, equals('/opt/flutter/bin/flutter'));
      expect(argsFlutterTest, equals(['debug_adapter']));
    });

    test('formata argumentos DAP launch para Dart CLI', () {
      const target = DartDebugTarget(
        kind: DartDebugType.dartCli,
        program: 'bin/server.dart',
        cwd: '/project/app',
        args: ['--port', '8080'],
        vmAdditionalArgs: ['--enable-asserts'],
      );

      final launchArgs = target.toDapLaunchArgs();
      expect(launchArgs['program'], equals('bin/server.dart'));
      expect(launchArgs['cwd'], equals('/project/app'));
      expect(launchArgs['args'], equals(['--port', '8080']));
      expect(launchArgs['vmAdditionalArgs'], equals(['--enable-asserts']));
      expect(launchArgs['noDebug'], isFalse);
      expect(launchArgs.containsKey('toolArgs'), isFalse);
    });

    test('formata argumentos DAP launch para Flutter com device selecionado', () {
      const target = DartDebugTarget(
        kind: DartDebugType.flutterApp,
        program: 'lib/main.dart',
        cwd: '/project/flutter_app',
        deviceId: 'macos',
        noDebug: true,
      );

      final launchArgs = target.toDapLaunchArgs();
      expect(launchArgs['program'], equals('lib/main.dart'));
      expect(launchArgs['cwd'], equals('/project/flutter_app'));
      expect(launchArgs['toolArgs'], equals(['-d', 'macos']));
      expect(launchArgs['noDebug'], isTrue);
      expect(target.isFlutter, isTrue);
    });

    test('formata argumentos DAP attach para VM Service', () {
      final attachArgs = DartDebugTarget.toDapAttachArgs(
        vmServiceUri: 'http://127.0.0.1:5858/ws',
        cwd: '/project/flutter_app',
      );

      expect(attachArgs['vmServiceUri'], equals('http://127.0.0.1:5858/ws'));
      expect(attachArgs['cwd'], equals('/project/flutter_app'));
    });
  });

  group('Dart & Flutter Debug Lifecycle & Operations', () {
    late _MockDartDapServer server;
    late DapClient client;
    late DebugSessionController controller;

    setUp(() {
      server = _MockDartDapServer();
      client = DapClient(
        stdout: server.output.stream,
        stdin: server.input.sink,
        sessionId: 'test-dart-session',
      );
      controller = DebugSessionController();
    });

    tearDown(() async {
      await controller.stop();
      controller.dispose();
      await client.close();
      await server.close();
    });

    test('inicia sessão Dart especializada e sincroniza estado', () async {
      const target = DartDebugTarget(
        kind: DartDebugType.dartCli,
        program: 'bin/main.dart',
        cwd: '/project/cli',
      );

      await controller.startDartSession(
        target: target,
        clientOverride: client,
      );

      expect(controller.isActive, isTrue);
      expect(controller.isFlutter, isFalse);
      expect(controller.activeTarget, equals(target));
      expect(server.receivedCommands, contains('initialize'));
      expect(server.receivedCommands, contains('launch'));
    });

    test('inicia sessão Flutter e executa Hot Reload com sucesso', () async {
      const target = DartDebugTarget(
        kind: DartDebugType.flutterApp,
        program: 'lib/main.dart',
        cwd: '/project/mobile',
        deviceId: 'chrome',
      );

      await controller.startDartSession(
        target: target,
        clientOverride: client,
      );

      expect(controller.isActive, isTrue);
      expect(controller.isFlutter, isTrue);

      final reloadOk = await controller.hotReload();
      expect(reloadOk, isTrue);
      expect(server.receivedCommands, contains('hotReload'));
      expect(
        controller.consoleLogs,
        contains('[DAP Flutter]: Hot Reload concluído com sucesso.'),
      );
    });

    test('executa Hot Restart com sucesso em sessão Flutter', () async {
      const target = DartDebugTarget(
        kind: DartDebugType.flutterApp,
        program: 'lib/main.dart',
        cwd: '/project/mobile',
      );

      await controller.startDartSession(
        target: target,
        clientOverride: client,
      );

      final restartOk = await controller.hotRestart();
      expect(restartOk, isTrue);
      expect(server.receivedCommands, contains('hotRestart'));
      expect(
        controller.consoleLogs,
        contains('[DAP Flutter]: Hot Restart concluído com sucesso.'),
      );
    });

    test('configura e alterna modos de exceção no Dart DAP', () async {
      const target = DartDebugTarget(
        kind: DartDebugType.dartCli,
        program: 'lib/app.dart',
        cwd: '/project/cli',
      );

      await controller.startDartSession(
        target: target,
        clientOverride: client,
      );

      expect(controller.exceptionMode, equals('Unhandled'));

      await controller.setExceptionMode('All');
      expect(controller.exceptionMode, equals('All'));
      expect(server.receivedCommands, contains('setExceptionBreakpoints'));

      final lastReq = server.receivedRequests.lastWhere(
        (r) => r['command'] == 'setExceptionBreakpoints',
      );
      final rawArgs = lastReq['arguments'] as Map<String, dynamic>;
      expect(rawArgs['filters'], equals(['All']));
    });

    test('distingue encerramento limpo da sessão e desativação de controles Flutter', () async {
      const target = DartDebugTarget(
        kind: DartDebugType.flutterApp,
        program: 'lib/main.dart',
        cwd: '/project/mobile',
      );

      await controller.startDartSession(
        target: target,
        clientOverride: client,
      );
      expect(controller.isActive, isTrue);
      expect(controller.isFlutter, isTrue);

      await controller.stop();
      expect(controller.isActive, isFalse);
      expect(controller.isFlutter, isFalse);
      expect(controller.activeTarget, isNull);
    });
  });
}
