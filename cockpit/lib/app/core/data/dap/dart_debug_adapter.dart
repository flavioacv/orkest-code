import 'dart:io';
import 'package:path/path.dart' as p;

import 'package:orkest_code/app/core/data/dap/dap_client.dart';

/// Tipo de execução depurável na stack Dart / Flutter.
enum DartDebugType {
  /// Execução CLI padrão via Dart SDK (`dart run`).
  dartCli,

  /// Execução de testes de unidade via Dart SDK (`dart test`).
  dartTest,

  /// Aplicação Flutter (`flutter run`).
  flutterApp,

  /// Testes de integração ou widget Flutter (`flutter test`).
  flutterTest,
}

/// Alvo de depuração configurado para Dart ou Flutter.
class DartDebugTarget {
  const DartDebugTarget({
    required this.kind,
    required this.program,
    required this.cwd,
    this.args = const [],
    this.toolArgs = const [],
    this.vmAdditionalArgs = const [],
    this.deviceId,
    this.noDebug = false,
  });

  /// Tipo de alvo depurável.
  final DartDebugType kind;

  /// Caminho do script de entrada (ex: `lib/main.dart` ou `test/my_test.dart`).
  final String program;

  /// Diretório de trabalho onde o processo é executado.
  final String cwd;

  /// Argumentos de linha de comando passados ao script da aplicação.
  final List<String> args;

  /// Argumentos de ferramenta passados ao CLI Flutter ou Dart (ex: `-d macos`).
  final List<String> toolArgs;

  /// Argumentos adicionais da VM Dart.
  final List<String> vmAdditionalArgs;

  /// Dispositivo de destino selecionado (ex: `macos`, `chrome`, `emulator-5554`).
  final String? deviceId;

  /// Se verdadeiro, roda em modo noDebug (apenas telemetria e execução).
  final bool noDebug;

  /// Indica se o alvo é uma aplicação ou teste Flutter.
  bool get isFlutter =>
      kind == DartDebugType.flutterApp || kind == DartDebugType.flutterTest;

  /// Converte para os argumentos do comando `launch` do adaptador DAP.
  Map<String, dynamic> toDapLaunchArgs() {
    final effectiveToolArgs = <String>[...toolArgs];
    if (deviceId != null &&
        deviceId!.isNotEmpty &&
        !effectiveToolArgs.contains('-d') &&
        !effectiveToolArgs.contains('--device-id')) {
      effectiveToolArgs.addAll(['-d', deviceId!]);
    }

    return {
      'noDebug': noDebug,
      'program': program,
      'cwd': cwd,
      if (args.isNotEmpty) 'args': args,
      if (effectiveToolArgs.isNotEmpty) 'toolArgs': effectiveToolArgs,
      if (vmAdditionalArgs.isNotEmpty) 'vmAdditionalArgs': vmAdditionalArgs,
    };
  }

  /// Converte para os argumentos do comando `attach` do adaptador DAP.
  static Map<String, dynamic> toDapAttachArgs({
    required String vmServiceUri,
    required String cwd,
  }) {
    return {'vmServiceUri': vmServiceUri, 'cwd': cwd};
  }
}

/// Orquestrador do adaptador de depuração oficial do Dart e Flutter SDK.
class DartDebugAdapter {
  const DartDebugAdapter._();

  /// Resolve o executável e argumentos para iniciar o servidor DAP stdio oficial.
  ///
  /// Para Dart: `dart debug_adapter`
  /// Para Flutter: `flutter debug_adapter`
  static (String executable, List<String> args) resolveAdapterCommand({
    required DartDebugType kind,
    String? sdkPath,
  }) {
    final isFlutter =
        kind == DartDebugType.flutterApp || kind == DartDebugType.flutterTest;

    if (isFlutter) {
      final flutterExe = sdkPath != null && sdkPath.isNotEmpty
          ? p.join(
              sdkPath,
              'bin',
              Platform.isWindows ? 'flutter.bat' : 'flutter',
            )
          : 'flutter';
      return (
        flutterExe,
        ['debug_adapter', if (kind == DartDebugType.flutterTest) '--test'],
      );
    }

    final dartExe = sdkPath != null && sdkPath.isNotEmpty
        ? p.join(sdkPath, 'bin', Platform.isWindows ? 'dart.exe' : 'dart')
        : 'dart';
    return (
      dartExe,
      ['debug_adapter', if (kind == DartDebugType.dartTest) '--test'],
    );
  }

  /// Inicia o subprocesso do adaptador DAP do SDK e retorna um [DapClient] conectado.
  static Future<DapClient> spawnClient({
    required DartDebugTarget target,
    String? sdkPath,
    String? sessionId,
  }) async {
    final (executable, args) = resolveAdapterCommand(
      kind: target.kind,
      sdkPath: sdkPath,
    );

    final process = await Process.start(
      executable,
      args,
      workingDirectory: target.cwd,
      runInShell: Platform.isWindows,
    );

    return DapClient.fromProcess(
      process: process,
      sessionId:
          sessionId ?? 'dart-debug-${DateTime.now().millisecondsSinceEpoch}',
    );
  }
}
