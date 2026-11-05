/// Sanitizador de logs e saídas de processos nativos para proteção contra
/// vazamento acidental de credenciais, tokens e chaves privadas (A05).
class LogSanitizer {
  const LogSanitizer();

  /// Sanitiza o [text] mascarando trechos sensíveis com `[REDACTED]`.
  String sanitize(String text) {
    var result = text;

    // Chaves PEM completas
    result = result.replaceAllMapped(
      RegExp(r'-----BEGIN [A-Z ]+ PRIVATE KEY-----[\s\S]*?-----END [A-Z ]+ PRIVATE KEY-----'),
      (_) => '-----BEGIN PRIVATE KEY-----\n[REDACTED PRIVATE KEY]\n-----END PRIVATE KEY-----',
    );

    // Bearer tokens
    result = result.replaceAllMapped(
      RegExp(r'(Bearer\s+)[A-Za-z0-9_\-\.]{15,}', caseSensitive: false),
      (m) => '${m.group(1)}[REDACTED_TOKEN]',
    );

    // Flags de linha de comando
    result = result.replaceAllMapped(
      RegExp(r'(--(?:password|pass|secret|token|api[_-]?key)=)[^\s]+', caseSensitive: false),
      (m) => '${m.group(1)}[REDACTED]',
    );

    // Campos JSON
    result = result.replaceAllMapped(
      RegExp(r'("(?:password|secret|token|apiKey|passphrase)"\s*:\s*")[^"]+(")', caseSensitive: false),
      (m) => '${m.group(1)}[REDACTED]${m.group(2)}',
    );

    // URLs com credenciais
    result = result.replaceAllMapped(
      RegExp(r'(://[^:]+:)([^@]+)(@)'),
      (m) => '${m.group(1)}[REDACTED]${m.group(3)}',
    );

    return result;
  }
}
