import 'dart:convert';
import 'package:orkest_code/app/orkest/domain/entities/http_document.dart';

/// Perfil de ambiente de execução HTTP (X02).
class HttpEnvironment {
  const HttpEnvironment({
    required this.name,
    required this.variables,
    this.isDefault = false,
  });

  final String name; // ex: 'dev', 'staging', 'prod', 'local'
  final Map<String, String> variables;
  final bool isDefault;

  String? get(String key) => variables[key];

  HttpEnvironment copyWith({
    String? name,
    Map<String, String>? variables,
    bool? isDefault,
  }) {
    return HttpEnvironment(
      name: name ?? this.name,
      variables: variables ?? this.variables,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

/// Registro histórico de uma requisição HTTP disparada (X02).
class HttpRequestHistoryEntry {
  const HttpRequestHistoryEntry({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.url,
    required this.statusCode,
    required this.elapsedMs,
    required this.responseSizeBytes,
    this.requestLabel,
    this.isGraphQL = false,
    this.errorMessage,
  });

  final String id;
  final DateTime timestamp;
  final String method;
  final String url;
  final int statusCode;
  final int elapsedMs;
  final int responseSizeBytes;
  final String? requestLabel;
  final bool isGraphQL;
  final String? errorMessage;

  bool get isSuccess => statusCode >= 200 && statusCode < 400;
}

/// Tipo de autenticação suportada de forma declarativa (X02).
enum HttpAuthType {
  none,
  bearerToken,
  basicAuth,
  apiKeyHeader,
  apiKeyQuery,
}

/// Configuração de autenticação com proteção de credenciais (X02).
class HttpAuthConfig {
  const HttpAuthConfig({
    this.type = HttpAuthType.none,
    this.token,
    this.username,
    this.password,
    this.apiKeyName,
    this.apiKeyValue,
  });

  final HttpAuthType type;
  final String? token;
  final String? username;
  final String? password;
  final String? apiKeyName;
  final String? apiKeyValue;

  /// Aplica a autenticação sobre a especificação [spec], retornando uma nova cópia.
  HttpRequestSpec applyTo(HttpRequestSpec spec) {
    switch (type) {
      case HttpAuthType.none:
        return spec;

      case HttpAuthType.bearerToken:
        if (token == null || token!.isEmpty) return spec;
        final headers = List<HttpHeader>.from(spec.headers);
        headers.removeWhere((h) => h.name.toLowerCase() == 'authorization');
        headers.add((name: 'Authorization', value: 'Bearer $token'));
        return spec.copyWith(headers: List.unmodifiable(headers));

      case HttpAuthType.basicAuth:
        final u = username ?? '';
        final p = password ?? '';
        final encoded = base64Encode(utf8.encode('$u:$p'));
        final headers = List<HttpHeader>.from(spec.headers);
        headers.removeWhere((h) => h.name.toLowerCase() == 'authorization');
        headers.add((name: 'Authorization', value: 'Basic $encoded'));
        return spec.copyWith(headers: List.unmodifiable(headers));

      case HttpAuthType.apiKeyHeader:
        final name = apiKeyName ?? 'X-API-Key';
        final val = apiKeyValue ?? '';
        final headers = List<HttpHeader>.from(spec.headers);
        headers.removeWhere((h) => h.name.toLowerCase() == name.toLowerCase());
        headers.add((name: name, value: val));
        return spec.copyWith(headers: List.unmodifiable(headers));

      case HttpAuthType.apiKeyQuery:
        final name = apiKeyName ?? 'api_key';
        final val = apiKeyValue ?? '';
        final separator = spec.url.contains('?') ? '&' : '?';
        final newUrl = '${spec.url}$separator$name=${Uri.encodeQueryComponent(val)}';
        return spec.copyWith(url: newUrl);
    }
  }

  /// Retorna os headers com valores sensíveis mascarados para telemetria/logs seguros.
  static List<HttpHeader> sanitizeHeaders(List<HttpHeader> headers) {
    const sensitive = {'authorization', 'x-api-key', 'cookie', 'set-cookie', 'proxy-authorization'};
    return headers.map((h) {
      if (sensitive.contains(h.name.toLowerCase())) {
        return (name: h.name, value: maskSecret(h.value));
      }
      return h;
    }).toList(growable: false);
  }

  /// Mascara valor sensível preservando apenas prefixos conhecidos (ex: 'Bearer ...').
  static String maskSecret(String secret) {
    if (secret.isEmpty) return '';
    if (secret.toLowerCase().startsWith('bearer ')) {
      final token = secret.substring(7);
      if (token.length <= 6) return 'Bearer ***';
      return 'Bearer ${token.substring(0, 3)}...***';
    }
    if (secret.toLowerCase().startsWith('basic ')) {
      return 'Basic ***';
    }
    if (secret.length <= 6) return '***';
    return '${secret.substring(0, 3)}...***';
  }
}

/// Especificação de consulta ou mutação GraphQL estruturada (X02).
class GraphQLRequestSpec {
  const GraphQLRequestSpec({
    required this.query,
    this.operationName,
    this.variables = const {},
  });

  final String query;
  final String? operationName;
  final Map<String, dynamic> variables;

  /// Converte a requisição GraphQL no payload JSON esperado pelo endpoint.
  Map<String, dynamic> toJsonPayload() {
    final payload = <String, dynamic>{'query': query};
    if (operationName != null && operationName!.isNotEmpty) {
      payload['operationName'] = operationName;
    }
    if (variables.isNotEmpty) {
      payload['variables'] = variables;
    }
    return payload;
  }

  /// Converte para uma requisição HTTP POST padronizada para o [endpointUrl].
  HttpRequestSpec toHttpRequestSpec({
    required String endpointUrl,
    String? requestName,
    List<HttpHeader> extraHeaders = const [],
  }) {
    final headers = <HttpHeader>[
      (name: 'Content-Type', value: 'application/json'),
      (name: 'Accept', value: 'application/json'),
      ...extraHeaders,
    ];

    return HttpRequestSpec(
      name: requestName ?? 'GraphQL Request',
      method: 'POST',
      url: endpointUrl,
      headers: List.unmodifiable(headers),
      body: jsonEncode(toJsonPayload()),
      startLine: 0,
      endLine: 0,
    );
  }
}

/// Rota de API extraída estaticamente a partir de frameworks de backend (X02).
class ExtractedRoute {
  const ExtractedRoute({
    required this.framework,
    required this.httpMethod,
    required this.path,
    required this.sourceFile,
    required this.sourceLine,
    this.handlerName,
  });

  final String framework; // Spring, Express, FastAPI, NestJS
  final String httpMethod;
  final String path;
  final String sourceFile;
  final int sourceLine;
  final String? handlerName;

  /// Converte a rota em um snippet `.http` pronto para teste rápido.
  String toHttpSnippet({String baseUrl = '{{baseUrl}}'}) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    return '### $framework: ${handlerName ?? path}\n'
        '$httpMethod $baseUrl$normalizedPath\n'
        'Accept: application/json\n';
  }
}
