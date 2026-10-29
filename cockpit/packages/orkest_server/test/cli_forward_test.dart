// A CLI `orkest` rodando NO HOST não executa nada: o servidor encaminha o
// comando ao cliente (direção inversa do RPC) e devolve a resposta pelo mesmo
// socket do hook. Estes testes cobrem esse trajeto de ponta a ponta.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:orkest_core/orkest_core.dart';
import 'package:orkest_protocol/orkest_protocol.dart';
import 'package:orkest_server/orkest_server.dart';
import 'package:test/test.dart';

void main() {
  late Directory dir;
  late String path;

  setUp(() {
    dir = Directory.systemTemp.createTempSync('orkest-cli-forward');
    path = '${dir.path}/s.sock';
    LocalEndpoint.debugForceTcp = true;
  });
  tearDown(() {
    LocalEndpoint.debugForceTcp = null;
    dir.deleteSync(recursive: true);
  });

  test(
    'comando da CLI vai ao cliente e a resposta volta pro chamador',
    () async {
      final server = _server();
      await server.bind(path);
      addTearDown(server.close);

      // Cliente que se comporta como o Orkest: responde ao `cli.cmd`.
      final client = await _connectClient(path);
      final seen = <RpcRequest>[];
      client.messages.listen((m) {
        if (m is! RpcRequest || m.method != 'cli.cmd') return;
        seen.add(m);
        client.send(RpcResponse(rid: m.rid, ok: true, data: {'tabs': 2}));
      });

      final reply = await _sendCliCommand(server, {
        'type': 'cmd',
        'cmd': 'list-panes',
        'tabId': 't1',
        'args': <String, Object?>{},
      });

      expect(reply['ok'], isTrue);
      expect((reply['data'] as Map)['tabs'], 2);
      // O envelope chega inteiro ao cliente: ele precisa do tabId pra rotear.
      expect(seen.single.params['cmd'], 'list-panes');
      expect(seen.single.params['tabId'], 't1');
    },
  );

  test('erro do cliente volta como {ok:false} com o detalhe', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final client = await _connectClient(path);
    client.messages.listen((m) {
      if (m is! RpcRequest || m.method != 'cli.cmd') return;
      client.send(
        RpcResponse(
          rid: m.rid,
          ok: false,
          code: 'cli',
          detail: 'no workspace selected',
        ),
      );
    });

    final reply = await _sendCliCommand(server, {
      'type': 'cmd',
      'cmd': 'open',
      'args': {'path': '/tmp/x'},
    });
    expect(reply['ok'], isFalse);
    expect(reply['error'], 'no workspace selected');
  });

  test('sem cliente conectado, a CLI recebe erro em vez de pendurar', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final reply = await _sendCliCommand(server, {
      'type': 'cmd',
      'cmd': 'list-panes',
    });
    expect(reply['ok'], isFalse);
    expect(reply['error'], contains('no Orkest client'));
  });

  test('turn status is delivered only to its owning client', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);
    final owner = await _connectClient(path);
    final other = await _connectClient(path);
    await _claimTab(owner, 'owner-tab');
    await _claimTab(other, 'other-tab');
    final seen = <TurnStatus>[];
    final sub = other.messages
        .where((m) => m is TurnStatus)
        .cast<TurnStatus>()
        .listen(seen.add);
    addTearDown(sub.cancel);
    final delivered = owner.messages.firstWhere((m) => m is TurnStatus);
    final socket = await _connectStatus(server);
    socket.writeln(
      jsonEncode({
        'paneId': 'owner-tab',
        'st': 'waiting',
        'tok': _token(server),
      }),
    );
    await socket.flush();
    expect(
      (await delivered.timeout(const Duration(seconds: 5)) as TurnStatus)
          .paneId,
      'owner-tab',
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(seen, isEmpty);
  });

  test('equal tab IDs are disambiguated by PTY generation', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);
    final owner = await _connectClient(path);
    final other = await _connectClient(path);
    await _claimTab(owner, 't1', 'owner-generation');
    await _claimTab(other, 't1', 'other-generation');
    final seen = <TurnStatus>[];
    final sub = other.messages
        .where((m) => m is TurnStatus)
        .cast<TurnStatus>()
        .listen(seen.add);
    addTearDown(sub.cancel);
    final delivered = owner.messages.firstWhere((m) => m is TurnStatus);
    final socket = await _connectStatus(server);
    socket.writeln(
      jsonEncode({
        'paneId': 't1',
        'st': 'waiting',
        'gen': 'owner-generation',
        'tok': _token(server),
      }),
    );
    await socket.flush();
    expect(
      (await delivered.timeout(const Duration(seconds: 5)) as TurnStatus)
          .generation,
      'owner-generation',
    );
    await Future<void>.delayed(const Duration(milliseconds: 100));
    expect(seen, isEmpty);
  });

  test('status de turno segue funcionando no mesmo socket', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final client = await _connectClient(path);
    await _claimTab(client, 't1', 'pty-1');
    final status = client.messages.firstWhere((m) => m is TurnStatus);

    final socket = await _connectStatus(server);
    socket.write(
      '${jsonEncode({'paneId': 't1', 'st': 'working', 'tid': 'turn-1', 'gen': 'pty-1', 'tok': _token(server)})}\n',
    );
    await socket.flush();

    final received = await status.timeout(const Duration(seconds: 5));
    expect((received as TurnStatus).paneId, 't1');
    expect(received.status, 'working');
    expect(received.turnId, 'turn-1');
    expect(received.generation, 'pty-1');
    await socket.close();
  });
  test('structured Office activities reach the remote client intact', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);
    final client = await _connectClient(path);
    await _claimTab(client, 't1');
    final status = client.messages.firstWhere((m) => m is TurnStatus);
    final socket = await _connectStatus(server);
    addTearDown(socket.destroy);
    socket.writeln(
      jsonEncode({
        'paneId': 't1',
        'st': 'activity',
        'tok': _token(server),
        'activityKind': 'command',
        'activityPhase': 'failed',
        'activitySummary': 'Build failed',
        'activityId': 'run1',
        'hn': 'apple-fm',
      }),
    );
    await socket.flush();
    final received =
        await status.timeout(const Duration(seconds: 5)) as TurnStatus;
    expect(received.status, 'activity');
    expect(received.activityKind, 'command');
    expect(received.activityPhase, 'failed');
    expect(received.activitySummary, 'Build failed');
    expect(received.activityId, 'run1');
    expect(received.harness, 'apple-fm');
  });
  test('com dois clientes, o comando vai para o DONO da aba', () async {
    // Desktop e iPad ligados ao mesmo host: responder pelo último que conectou
    // devolvia as abas do dispositivo errado.
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final dono = await _connectClient(path);
    final outro = await _connectClient(path);
    await _claimTab(dono, 'tab-do-ipad');

    var respondeuOutro = false;
    dono.messages.listen((m) {
      if (m is! RpcRequest || m.method != 'cli.cmd') return;
      dono.send(RpcResponse(rid: m.rid, ok: true, data: {'quem': 'dono'}));
    });
    outro.messages.listen((m) {
      if (m is! RpcRequest || m.method != 'cli.cmd') return;
      respondeuOutro = true;
      outro.send(RpcResponse(rid: m.rid, ok: true, data: {'quem': 'outro'}));
    });

    final reply = await _sendCliCommand(server, {
      'type': 'cmd',
      'cmd': 'list-panes',
      'tabId': 'tab-do-ipad',
    });
    expect((reply['data'] as Map)['quem'], 'dono');
    expect(respondeuOutro, isFalse);
  });

  test('aba órfã com vários clientes explica em vez de chutar', () async {
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final a = await _connectClient(path);
    await _connectClient(path);
    a.messages.listen((m) {
      if (m is RpcRequest && m.method == 'cli.cmd') {
        a.send(RpcResponse(rid: m.rid, ok: true, data: 'nao deveria'));
      }
    });

    final reply = await _sendCliCommand(server, {
      'type': 'cmd',
      'cmd': 'list-panes',
      'tabId': 'tab-de-ninguem',
    });
    expect(reply['ok'], isFalse);
    expect(reply['error'], contains('no attached Orkest owns tab'));
  });

  test(
    'a stale generation never falls back to the only connected client',
    () async {
      final server = _server();
      await server.bind(path);
      addTearDown(server.close);
      final client = await _connectClient(path);
      await _claimTab(client, 't1', 'current');
      final reply = await _sendCliCommand(server, {
        'type': 'cmd',
        'cmd': 'list-panes',
        'tabId': 't1',
        'gen': 'stale',
      });
      expect(reply['ok'], false);
      expect(reply['error'], contains('stale terminal generation'));
    },
  );

  test('cliente único responde mesmo sem reivindicar a aba', () async {
    // Aba aberta antes deste servidor (processo reiniciado): com um cliente só
    // não há ambiguidade, então segue funcionando.
    final server = _server();
    await server.bind(path);
    addTearDown(server.close);

    final client = await _connectClient(path);
    client.messages.listen((m) {
      if (m is! RpcRequest || m.method != 'cli.cmd') return;
      client.send(RpcResponse(rid: m.rid, ok: true, data: 'ok'));
    });

    final reply = await _sendCliCommand(server, {
      'type': 'cmd',
      'cmd': 'list-panes',
      'tabId': 'aba-antiga',
    });
    expect(reply['ok'], isTrue);
    expect(reply['data'], 'ok');
  });
}

/// Abre uma PTY por esta conexão declarando `ORKEST_TAB_ID` — é assim que o
/// servidor aprende de quem é a aba.
Future<void> _claimTab(
  _TestClient client,
  String tabId, [
  String? generation,
]) async {
  final opened = client.messages.firstWhere((m) => m is PtyOpened);
  client.send(
    PtyOpen(
      executable: '/bin/zsh',
      environment: {
        'ORKEST_TAB_ID': tabId,
        if (generation != null) 'ORKEST_SESSION_TOKEN': generation,
      },
    ),
  );
  await opened.timeout(const Duration(seconds: 5));
}

RemoteServer _server() =>
    RemoteServer(_FakeTerminals(), _Fake(), _Fake(), _Fake());

String? _token(RemoteServer server) => server.statusToken;

/// Escreve uma linha no socket de status/comando do servidor e lê a resposta.
Future<Map<String, Object?>> _sendCliCommand(
  RemoteServer server,
  Map<String, Object?> command,
) async {
  final socket = await _connectStatus(server);
  final line = socket
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .first;
  final token = _token(server);
  socket.write(
    '${jsonEncode({...command, if (token != null) 'tok': token})}\n',
  );
  await socket.flush();
  final reply = await line.timeout(const Duration(seconds: 5));
  return (jsonDecode(reply) as Map).cast<String, Object?>();
}

Future<Socket> _connectStatus(RemoteServer server) async {
  final endpoint = await LocalEndpoint.connect(server.statusSocketPath!);
  addTearDown(endpoint.socket.destroy);
  return endpoint.socket;
}

/// Conecta como cliente Orkest (handshake completo) e devolve a conexão.
Future<_TestClient> _connectClient(String path) async {
  final endpoint = await LocalEndpoint.connect(path);
  final socket = endpoint.socket;
  addTearDown(socket.destroy);
  final messages = StreamController<RemoteMessage>.broadcast();
  const RemoteMessageCodec().decodeStream(socket).listen(messages.add);
  final ack = messages.stream.first;
  socket.add(
    utf8.encode(
      const RemoteMessageCodec().encode(
        Hello(
          version: protocolVersion,
          client: 'test',
          token: endpoint.token,
          local: false,
        ),
      ),
    ),
  );
  await ack.timeout(const Duration(seconds: 5));
  return _TestClient(socket, messages.stream);
}

class _TestClient {
  _TestClient(this._socket, this.messages);
  final Socket _socket;
  final Stream<RemoteMessage> messages;

  void send(RemoteMessage m) =>
      _socket.add(utf8.encode(const RemoteMessageCodec().encode(m)));
}

class _FakeTerminals implements TerminalService {
  var _n = 0;

  @override
  Future<PtySessionInfo> open(PtySpawnSpec spec) async => PtySessionInfo(
    id: 's${++_n}',
    pid: _n,
    executable: spec.executable,
    rows: 25,
    columns: 80,
    scrollbackLength: 0,
  );

  @override
  Stream<PtyEvent> attach(String id, {int fromOffset = 0}) =>
      const Stream<PtyEvent>.empty();

  @override
  Future<void> dispose() async {}
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}

class _Fake implements FileService, GitService, DbService {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError('${invocation.memberName}');
}
