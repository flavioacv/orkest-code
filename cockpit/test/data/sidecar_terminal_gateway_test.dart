@TestOn('mac-os')
library;

import 'dart:convert';
import 'dart:io';

import 'package:orkest_code/app/orkest/data/terminal/sidecar/sidecar_terminal_connector.dart';
import 'package:orkest_code/app/orkest/data/terminal/sidecar/sidecar_terminal_gateway_factory.dart';
import 'package:orkest_code/app/core/domain/entities/terminal_profile.dart';
import 'package:flutter_test/flutter_test.dart';

/// Integração da Wave 1 (plano 58): o gateway do app servido pelo sidecar
/// real. Requer `./tool/build-sidecar.sh`; sem os artefatos o teste é pulado —
/// o fallback in-process é coberto pelo uso normal do app.
void main() {
  // `tool/build-sidecar.sh` passou a empacotar via `dart build cli` em
  // `build/server-bundle/bin/` (o `build/wave0/` só guarda a dylib do PTY).
  // O caminho antigo fica como fallback pra bundle gerado por versão anterior.
  final binary =
      [
        File(
          'build/macos/Build/Products/Debug/Orkest Code.app/Contents/Resources/orkest-server-bundle/bin/orkest-server',
        ),
        File('build/server-bundle/bin/orkest-server'),
        File('build/wave0/orkest-server'),
      ].firstWhere(
        (f) => f.existsSync(),
        orElse: () => File('build/wave0/orkest-server'),
      );

  test('terminal via sidecar: eco, ack e kill', () async {
    if (!binary.existsSync()) {
      markTestSkipped(
        'binário do orkest-server ausente; rode tool/build-sidecar.sh',
      );
      return;
    }

    final dir = Directory.systemTemp.createTempSync('orkest-sidecar-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final connector = SidecarTerminalConnector(
      socketPathOverride: '${dir.path}/s.sock',
      serverBinaryOverride: binary.absolute.path,
    );
    addTearDown(connector.dispose);

    final gateway = SidecarTerminalGatewayFactory(connector).create();
    final collected = StringBuffer();
    var chunks = 0;

    gateway.start(
      workingDirectory: Directory.systemTemp.path,
      profile: const TerminalProfile(
        id: 'login-shell',
        label: 'zsh',
        executable: '/bin/zsh',
        args: ['-f'],
      ),
      extraEnv: const {
        'WAVE1_MARKER': 'sidecar',
        'ORKEST_TAB_ID': 'audit-tab',
        'ORKEST_SESSION_TOKEN': 'audit-generation',
      },
    );
    final sub = gateway.output.listen((data) {
      chunks++;
      collected.write(utf8.decode(data, allowMalformed: true));
      gateway.acknowledgeOutput(); // papel do coalescer: crédito por chunk.
    });

    // write antes do backend pronto exercita a fila de operações.
    gateway.write(utf8.encode('echo wave1-\$WAVE1_MARKER-\$((40+2))\n'));

    await _until(() => collected.toString().contains('wave1-sidecar-42'));
    expect(chunks, greaterThan(0));
    final status = connector.turnStatus.first;
    final sender = await Socket.connect(
      InternetAddress(
        '${dir.path}/s.sock.status',
        type: InternetAddressType.unix,
      ),
      0,
    );
    sender.writeln(
      jsonEncode({
        'paneId': 'audit-tab',
        'st': 'activity',
        'gen': 'audit-generation',
        'tid': 'turn-one',
        'tool': 'fixture-tool',
        'sub': 'fixture-child',
        'activityKind': 'read',
        'activityPhase': 'started',
        'activitySummary': 'Fixture activity',
        'activityId': 'fixture-run',
      }),
    );
    await sender.flush();
    await sender.close();
    final event = await status.timeout(const Duration(seconds: 5));
    expect(event.activityKind, 'read');
    expect(event.activityId, 'fixture-run');
    expect(event.toolName, 'fixture-tool');
    expect(event.subagentId, 'fixture-child');
    expect(event.turnId, 'turn-one');
    expect(event.generation, 'audit-generation');

    gateway.resize(40, 120);
    gateway.write(utf8.encode('stty size\n'));
    await _until(() => collected.toString().contains('40 120'));

    await gateway.kill();
    await sub.cancel();
  }, timeout: const Timeout(Duration(minutes: 1)));

  // Regressão dos "terminais espelhados": dois `open()` no mesmo instante (o
  // que o restore de um workspace com dois panes faz) casavam com a MESMA
  // `pty.opened`, porque a resposta era buscada só pelo tipo. Os dois panes
  // adotavam um `sessionId` só, liam o mesmo PTY e o segundo ficava órfão.
  // Com o `rid` de correlação, cada gateway fica com a SUA sessão.
  test('dois terminais abertos ao mesmo tempo não compartilham PTY', () async {
    if (!binary.existsSync()) {
      markTestSkipped(
        'binário do orkest-server ausente; rode tool/build-sidecar.sh',
      );
      return;
    }

    final dir = Directory.systemTemp.createTempSync('orkest-sidecar-test-');
    addTearDown(() => dir.deleteSync(recursive: true));
    final connector = SidecarTerminalConnector(
      socketPathOverride: '${dir.path}/s.sock',
      serverBinaryOverride: binary.absolute.path,
    );
    addTearDown(connector.dispose);
    final factory = SidecarTerminalGatewayFactory(connector);

    const profile = TerminalProfile(
      id: 'login-shell',
      label: 'zsh',
      executable: '/bin/zsh',
      args: ['-f'],
    );

    final gateways = [factory.create(), factory.create()];
    final buffers = [StringBuffer(), StringBuffer()];
    final subs = [
      for (var i = 0; i < gateways.length; i++)
        gateways[i].output.listen((data) {
          buffers[i].write(utf8.decode(data, allowMalformed: true));
          gateways[i].acknowledgeOutput();
        }),
    ];
    addTearDown(() async {
      for (final sub in subs) {
        await sub.cancel();
      }
    });

    // Sem await entre os dois: é a simultaneidade que provocava a corrida.
    for (final gateway in gateways) {
      gateway.start(
        workingDirectory: Directory.systemTemp.path,
        profile: profile,
      );
    }

    // Cada terminal recebe uma marca própria; nenhuma pode vazar pro outro.
    gateways[0].write(utf8.encode('echo marca-\$((1+0))-um\n'));
    gateways[1].write(utf8.encode('echo marca-\$((1+1))-dois\n'));

    await _until(() => buffers[0].toString().contains('marca-1-um'));
    await _until(() => buffers[1].toString().contains('marca-2-dois'));

    expect(
      buffers[0].toString(),
      isNot(contains('marca-2-dois')),
      reason: 'saída do segundo terminal apareceu no primeiro (espelho)',
    );
    expect(
      buffers[1].toString(),
      isNot(contains('marca-1-um')),
      reason: 'saída do primeiro terminal apareceu no segundo (espelho)',
    );

    // Fechar um não pode derrubar o outro: com o PTY compartilhado, o kill
    // levava os dois.
    await gateways[0].kill();
    gateways[1].write(utf8.encode('echo ainda-vivo\n'));
    await _until(() => buffers[1].toString().contains('ainda-vivo'));

    await gateways[1].kill();
  }, timeout: const Timeout(Duration(minutes: 1)));
}

Future<void> _until(bool Function() test) async {
  final deadline = DateTime.now().add(const Duration(seconds: 20));
  while (!test()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('condição não satisfeita a tempo');
    }
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
}
