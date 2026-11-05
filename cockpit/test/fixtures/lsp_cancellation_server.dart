import 'dart:io';
import 'package:orkest_code/app/core/data/lsp/lsp_codec.dart';

/// Servidor controlado para observar cancelamento no protocolo stdio real.
Future<void> main() async {
  final messages = <Map<String, dynamic>>[];
  final pending = <int, String>{};
  void reply(Object id, Object? result) {
    stdout.add(
      encodeLspMessage({'jsonrpc': '2.0', 'id': id, 'result': result}),
    );
  }

  await for (final message in stdin.transform(const LspMessageDecoder())) {
    messages.add(message);
    final id = message['id'];
    final method = message['method'];
    switch (method) {
      case 'initialize':
        reply(id, {'capabilities': {}});
      case 'test/observed':
        reply(id, messages.toList());
      case 'test/release':
        for (final request in pending.keys) {
          reply(request, 'fresh');
        }
        pending.clear();
        reply(id, null);
      case r'$/cancelRequest':
        final cancelled = (message['params'] as Map)['id'] as int;
        pending.remove(cancelled);
        // Servidores podem responder mesmo depois de receber cancelamento.
        reply(cancelled, 'late');
      case 'shutdown':
        reply(id, null);
      case 'exit':
        await stdout.flush();
        return;
      default:
        if (id is int) pending[id] = method as String;
    }
    await stdout.flush();
  }
}
