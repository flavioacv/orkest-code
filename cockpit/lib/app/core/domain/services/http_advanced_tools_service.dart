import 'package:orkest_code/app/core/domain/entities/http_advanced_tools.dart';
import 'package:orkest_code/app/orkest/domain/entities/browser_capability.dart';

/// Gerenciador de perfis de ambiente HTTP e parsing de arquivos .env (X02).
class HttpEnvironmentManager {
  HttpEnvironmentManager({
    List<HttpEnvironment> initialEnvironments = const [],
  }) {
    for (final env in initialEnvironments) {
      _environments[env.name] = env;
      if (env.isDefault || _activeEnvironmentName == null) {
        _activeEnvironmentName = env.name;
      }
    }
  }

  final Map<String, HttpEnvironment> _environments = {};
  String? _activeEnvironmentName;

  List<HttpEnvironment> get environments => List.unmodifiable(_environments.values);
  HttpEnvironment? get activeEnvironment =>
      _activeEnvironmentName != null ? _environments[_activeEnvironmentName] : null;

  void addEnvironment(HttpEnvironment environment) {
    _environments[environment.name] = environment;
    if (environment.isDefault || _activeEnvironmentName == null) {
      _activeEnvironmentName = environment.name;
    }
  }

  bool selectEnvironment(String name) {
    if (_environments.containsKey(name)) {
      _activeEnvironmentName = name;
      return true;
    }
    return false;
  }

  /// Faz o parse de conteúdo de arquivo `.env` gerando um [HttpEnvironment].
  static HttpEnvironment parseDotEnv(
    String content, {
    required String name,
    bool isDefault = false,
  }) {
    final vars = <String, String>{};
    final lines = content.split('\n');

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('#')) continue;

      final eqIdx = trimmed.indexOf('=');
      if (eqIdx != -1) {
        final key = trimmed.substring(0, eqIdx).trim();
        var val = trimmed.substring(eqIdx + 1).trim();

        // Remove aspas simples ou duplas envolventes
        if ((val.startsWith('"') && val.endsWith('"')) ||
            (val.startsWith("'") && val.endsWith("'"))) {
          if (val.length >= 2) {
            val = val.substring(1, val.length - 1);
          }
        }

        if (key.isNotEmpty) {
          vars[key] = val;
        }
      }
    }

    return HttpEnvironment(
      name: name,
      variables: Map.unmodifiable(vars),
      isDefault: isDefault,
    );
  }

  /// Mescla variáveis do arquivo `.http` com o ambiente ativo selecionado.
  /// As variáveis locais do arquivo possuem precedência sobre as do ambiente.
  Map<String, String> resolveMergedVariables(Map<String, String> localFileVars) {
    final merged = <String, String>{};
    if (activeEnvironment != null) {
      merged.addAll(activeEnvironment!.variables);
    }
    merged.addAll(localFileVars);
    return Map.unmodifiable(merged);
  }
}

/// Serviço de histórico e auditoria de requisições HTTP disparadas (X02).
class HttpRequestHistoryService {
  HttpRequestHistoryService({this.maxRetention = 100});

  final int maxRetention;
  final List<HttpRequestHistoryEntry> _history = [];

  List<HttpRequestHistoryEntry> get entries => List.unmodifiable(_history);

  void record({
    required String method,
    required String url,
    required int statusCode,
    required int elapsedMs,
    required int responseSizeBytes,
    String? requestLabel,
    bool isGraphQL = false,
    String? errorMessage,
  }) {
    // Sanitiza URL de credenciais expostas
    final sanitizedUrl = WebNavigationService.sanitizeUrl(url);

    final entry = HttpRequestHistoryEntry(
      id: 'http_hist_${DateTime.now().microsecondsSinceEpoch}',
      timestamp: DateTime.now(),
      method: method.toUpperCase(),
      url: sanitizedUrl,
      statusCode: statusCode,
      elapsedMs: elapsedMs,
      responseSizeBytes: responseSizeBytes,
      requestLabel: requestLabel,
      isGraphQL: isGraphQL,
      errorMessage: errorMessage,
    );

    _history.insert(0, entry);
    if (_history.length > maxRetention) {
      _history.removeLast();
    }
  }

  List<HttpRequestHistoryEntry> filter({
    String? method,
    int? statusCode,
    String? query,
    bool? isGraphQL,
  }) {
    return _history.where((e) {
      if (method != null && e.method != method.toUpperCase()) return false;
      if (statusCode != null && e.statusCode != statusCode) return false;
      if (isGraphQL != null && e.isGraphQL != isGraphQL) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final matchesUrl = e.url.toLowerCase().contains(q);
        final matchesLabel = e.requestLabel?.toLowerCase().contains(q) ?? false;
        if (!matchesUrl && !matchesLabel) return false;
      }
      return true;
    }).toList(growable: false);
  }

  void clear() => _history.clear();
}

/// Token e controlador de cancelamento atômico de chamadas HTTP (X02).
class HttpRequestCancellationToken {
  bool _isCancelled = false;
  String? _reason;
  final List<void Function(String reason)> _listeners = [];

  bool get isCancelled => _isCancelled;
  String? get reason => _reason;

  void cancel([String reason = 'Cancelled by user']) {
    if (_isCancelled) return;
    _isCancelled = true;
    _reason = reason;
    for (final listener in _listeners) {
      listener(reason);
    }
    _listeners.clear();
  }

  void onCancel(void Function(String reason) callback) {
    if (_isCancelled) {
      callback(_reason ?? 'Cancelled');
    } else {
      _listeners.add(callback);
    }
  }
}

/// Extrator estático de rotas de backend (Spring, Express, FastAPI, NestJS) (X02).
class FrameworkRouteScanner {
  const FrameworkRouteScanner();

  static final _springMappingRegex = RegExp(
    r'@(GetMapping|PostMapping|PutMapping|DeleteMapping|PatchMapping|RequestMapping)\s*\(\s*(?:value\s*=\s*)?["\x27]([^"\x27]+)["\x27]',
  );

  static final _expressRouteRegex = RegExp(
    r'(?<!@)\b(?:app|router)\.(get|post|put|delete|patch)\s*\(\s*["\x27]([^"\x27]+)["\x27]',
  );

  static final _fastApiRouteRegex = RegExp(
    r'@(?:app|router)\.(get|post|put|delete|patch)\s*\(\s*["\x27]([^"\x27]+)["\x27]',
  );

  static final _nestJsRouteRegex = RegExp(
    r'@(Get|Post|Put|Delete|Patch)\s*\(\s*(?:["\x27]([^"\x27]+)["\x27])?\s*\)',
  );

  /// Varre [codeContent] e extrai todas as rotas declaradas conforme a sintaxe do framework.
  List<ExtractedRoute> scan(
    String codeContent, {
    required String filePath,
    String? basePrefix,
  }) {
    final lines = codeContent.split('\n');
    final routes = <ExtractedRoute>[];
    String? currentClassPrefix = basePrefix;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNum = i + 1;

      // 1. Spring Boot
      final springMatch = _springMappingRegex.firstMatch(line);
      if (springMatch != null) {
        final annotation = springMatch.group(1)!;
        final rawPath = springMatch.group(2)!;

        // Se for @RequestMapping e a linha seguinte (ou próxima linha não vazia) contiver 'class ',
        // trata como prefixo de classe (basePrefix) em vez de rota solta
        final isClassPrefix = annotation == 'RequestMapping' &&
            _isFollowedByClassDeclaration(lines, i + 1);
        if (isClassPrefix) {
          currentClassPrefix = rawPath;
          continue;
        }

        final method = _springAnnotationToMethod(annotation);
        final fullPath = _combinePrefix(currentClassPrefix, rawPath);
        routes.add(
          ExtractedRoute(
            framework: 'Spring',
            httpMethod: method,
            path: fullPath,
            sourceFile: filePath,
            sourceLine: lineNum,
          ),
        );
        continue;
      }

      // 2. Express.js
      final expressMatch = _expressRouteRegex.firstMatch(line);
      if (expressMatch != null) {
        final method = expressMatch.group(1)!.toUpperCase();
        final rawPath = expressMatch.group(2)!;
        final fullPath = _combinePrefix(basePrefix, rawPath);
        routes.add(
          ExtractedRoute(
            framework: 'Express',
            httpMethod: method,
            path: fullPath,
            sourceFile: filePath,
            sourceLine: lineNum,
          ),
        );
        continue;
      }

      // 3. FastAPI
      final fastApiMatch = _fastApiRouteRegex.firstMatch(line);
      if (fastApiMatch != null) {
        final method = fastApiMatch.group(1)!.toUpperCase();
        final rawPath = fastApiMatch.group(2)!;
        final fullPath = _combinePrefix(basePrefix, rawPath);
        routes.add(
          ExtractedRoute(
            framework: 'FastAPI',
            httpMethod: method,
            path: fullPath,
            sourceFile: filePath,
            sourceLine: lineNum,
          ),
        );
        continue;
      }

      // 4. NestJS
      final nestMatch = _nestJsRouteRegex.firstMatch(line);
      if (nestMatch != null) {
        final decorator = nestMatch.group(1)!;
        final rawPath = nestMatch.group(2) ?? '';
        final method = decorator.toUpperCase();
        final fullPath = _combinePrefix(basePrefix, rawPath);
        routes.add(
          ExtractedRoute(
            framework: 'NestJS',
            httpMethod: method,
            path: fullPath,
            sourceFile: filePath,
            sourceLine: lineNum,
          ),
        );
        continue;
      }
    }

    return List.unmodifiable(routes);
  }

  /// Gera um arquivo `.http` completo com variáveis e requests para as rotas extraídas.
  String generateHttpDocument(
    List<ExtractedRoute> routes, {
    String defaultBaseUrl = 'http://localhost:8080',
  }) {
    final buffer = StringBuffer();
    buffer.writeln('@baseUrl = $defaultBaseUrl');
    buffer.writeln();

    for (final r in routes) {
      buffer.write(r.toHttpSnippet(baseUrl: '{{baseUrl}}'));
      buffer.writeln();
    }

    return buffer.toString();
  }

  String _springAnnotationToMethod(String annotation) {
    switch (annotation) {
      case 'GetMapping':
        return 'GET';
      case 'PostMapping':
        return 'POST';
      case 'PutMapping':
        return 'PUT';
      case 'DeleteMapping':
        return 'DELETE';
      case 'PatchMapping':
        return 'PATCH';
      default:
        return 'GET';
    }
  }

  String _combinePrefix(String? prefix, String path) {
    if (prefix == null || prefix.isEmpty) {
      return path.startsWith('/') ? path : '/$path';
    }
    final cleanPrefix = prefix.endsWith('/') ? prefix.substring(0, prefix.length - 1) : prefix;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$cleanPrefix$cleanPath';
  }

  bool _isFollowedByClassDeclaration(List<String> lines, int startIndex) {
    for (var i = startIndex; i < lines.length && i < startIndex + 5; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      if (line.contains('class ') || line.contains('interface ')) {
        return true;
      }
      if (line.startsWith('@')) continue; // Outras anotações na classe
      break;
    }
    return false;
  }
}

/// Serviço de navegação web com proteção de credenciais e respeito a capacidades (X02).
class WebNavigationService {
  const WebNavigationService();

  /// Remove credenciais expostas na URL (ex: `user:pass@host`) e valida o protocolo.
  static String sanitizeUrl(String rawUrl) {
    final uri = Uri.tryParse(rawUrl);
    if (uri == null) return rawUrl;

    if (uri.userInfo.isNotEmpty) {
      return uri.replace(userInfo: '').toString();
    }
    return rawUrl;
  }

  /// Resolve o modo de exibição adequado sem duplicar instâncias de engine de browser.
  BrowserCapability resolveBrowserMode() => BrowserCapability.resolve();
}
