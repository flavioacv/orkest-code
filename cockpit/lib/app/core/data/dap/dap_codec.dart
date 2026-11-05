import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// Codificador e decodificador com framing `Content-Length: <n>\r\n\r\n`
/// compatível com a especificação Debug Adapter Protocol (DAP).
class DapCodec {
  const DapCodec();

  /// Codifica uma mensagem Map em bytes formatados no protocolo DAP.
  static Uint8List encode(Map<String, dynamic> message) {
    final body = utf8.encode(jsonEncode(message));
    final header = ascii.encode('Content-Length: ${body.length}\r\n\r\n');
    final builder = BytesBuilder(copy: false)
      ..add(header)
      ..add(body);
    return builder.takeBytes();
  }

  /// Transforma um stream de chunks de bytes num stream de mensagens JSON decodificadas.
  Stream<Map<String, dynamic>> decodeStream(Stream<List<int>> byteStream) {
    late final StreamController<Map<String, dynamic>> controller;
    late final StreamSubscription<List<int>> subscription;

    final buffer = BytesBuilder(copy: false);
    int? expectedLength;

    void processBuffer() {
      while (true) {
        if (expectedLength == null) {
          final bytes = buffer.toBytes();
          final delimiter = _findHeaderDelimiter(bytes);
          if (delimiter == -1) break;

          final headerText = ascii.decode(bytes.sublist(0, delimiter));
          final match = RegExp(
            r'Content-Length:\s*(\d+)',
            caseSensitive: false,
          ).firstMatch(headerText);

          if (match == null) {
            buffer.clear();
            break;
          }

          expectedLength = int.parse(match.group(1)!);
          final remainingBytes = bytes.sublist(delimiter + 4);
          buffer.clear();
          buffer.add(remainingBytes);
        }

        final contentLength = expectedLength!;
        if (buffer.length < contentLength) break;

        final allBytes = buffer.toBytes();
        final bodyBytes = allBytes.sublist(0, contentLength);
        final leftoverBytes = allBytes.sublist(contentLength);

        buffer.clear();
        buffer.add(leftoverBytes);
        expectedLength = null;

        try {
          final decodedJson = jsonDecode(utf8.decode(bodyBytes));
          if (decodedJson is Map<String, dynamic>) {
            controller.add(decodedJson);
          }
        } catch (_) {}
      }
    }

    controller = StreamController<Map<String, dynamic>>(
      onListen: () {
        subscription = byteStream.listen(
          (chunk) {
            buffer.add(chunk);
            processBuffer();
          },
          onError: controller.addError,
          onDone: () {
            processBuffer();
            controller.close();
          },
        );
      },
      onCancel: () => subscription.cancel(),
    );

    return controller.stream;
  }

  static int _findHeaderDelimiter(Uint8List bytes) {
    for (var i = 0; i <= bytes.length - 4; i++) {
      if (bytes[i] == 13 &&
          bytes[i + 1] == 10 &&
          bytes[i + 2] == 13 &&
          bytes[i + 3] == 10) {
        return i;
      }
    }
    return -1;
  }
}
