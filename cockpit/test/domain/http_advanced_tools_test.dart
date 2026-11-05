import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/http_advanced_tools.dart';
import 'package:orkest_code/app/core/domain/services/http_advanced_tools_service.dart';
import 'package:orkest_code/app/orkest/domain/entities/http_document.dart';

void main() {
  group('HttpEnvironmentManager (X02)', () {
    test('parses .env content accurately handling quotes and comments', () {
      const dotEnv = '''
# Server configuration
PORT=8080
API_BASE="https://api.staging.example.com/v1"
DB_HOST='10.0.0.12'
EMPTY_VAL=
# Secret token
SECRET_KEY=super_secret_token_123
''';

      final env = HttpEnvironmentManager.parseDotEnv(dotEnv, name: 'staging');
      expect(env.name, equals('staging'));
      expect(env.get('PORT'), equals('8080'));
      expect(env.get('API_BASE'), equals('https://api.staging.example.com/v1'));
      expect(env.get('DB_HOST'), equals('10.0.0.12'));
      expect(env.get('SECRET_KEY'), equals('super_secret_token_123'));
    });

    test('switches active environments and merges with local file variables', () {
      final dev = HttpEnvironmentManager.parseDotEnv('BASE_URL=https://dev.api\nTIMEOUT=5000', name: 'dev');
      final prod = HttpEnvironmentManager.parseDotEnv('BASE_URL=https://prod.api\nTIMEOUT=10000', name: 'prod');

      final manager = HttpEnvironmentManager(initialEnvironments: [dev, prod]);
      expect(manager.activeEnvironment?.name, equals('dev'));

      // Troca para prod
      final switched = manager.selectEnvironment('prod');
      expect(switched, isTrue);
      expect(manager.activeEnvironment?.name, equals('prod'));

      // Variáveis locais do arquivo .http sobrepõem as do ambiente
      final localVars = {'TIMEOUT': '2000', 'PAGE': '1'};
      final merged = manager.resolveMergedVariables(localVars);

      expect(merged['BASE_URL'], equals('https://prod.api'));
      expect(merged['TIMEOUT'], equals('2000')); // Precedência do arquivo local
      expect(merged['PAGE'], equals('1'));
    });
  });

  group('HttpAuthConfig & Secret Masking (X02)', () {
    const baseSpec = HttpRequestSpec(
      name: 'Test Request',
      method: 'GET',
      url: 'https://api.example.com/data',
      headers: [],
      startLine: 0,
      endLine: 1,
    );

    test('applies Bearer token authentication securely', () {
      const auth = HttpAuthConfig(type: HttpAuthType.bearerToken, token: 'xyz_jwt_token_999');
      final spec = auth.applyTo(baseSpec);

      expect(spec.headers.length, equals(1));
      expect(spec.headers.first.name, equals('Authorization'));
      expect(spec.headers.first.value, equals('Bearer xyz_jwt_token_999'));
    });

    test('applies Basic auth encoding credentials in base64', () {
      const auth = HttpAuthConfig(type: HttpAuthType.basicAuth, username: 'admin', password: 'secretpassword');
      final spec = auth.applyTo(baseSpec);

      expect(spec.headers.first.name, equals('Authorization'));
      expect(spec.headers.first.value, equals('Basic YWRtaW46c2VjcmV0cGFzc3dvcmQ='));
    });

    test('applies API key to header and query parameter', () {
      const headerAuth = HttpAuthConfig(type: HttpAuthType.apiKeyHeader, apiKeyName: 'X-App-Key', apiKeyValue: 'key_123');
      final specHeader = headerAuth.applyTo(baseSpec);
      expect(specHeader.headers.first.name, equals('X-App-Key'));
      expect(specHeader.headers.first.value, equals('key_123'));

      const queryAuth = HttpAuthConfig(type: HttpAuthType.apiKeyQuery, apiKeyName: 'api_key', apiKeyValue: 'val_abc');
      final specQuery = queryAuth.applyTo(baseSpec);
      expect(specQuery.url, equals('https://api.example.com/data?api_key=val_abc'));
    });

    test('sanitizes and masks sensitive headers preventing leaks', () {
      final sensitiveHeaders = [
        (name: 'Accept', value: 'application/json'),
        (name: 'Authorization', value: 'Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'),
        (name: 'X-API-Key', value: 'live_secret_api_key_4455'),
        (name: 'Cookie', value: 'session_id=abcdef123456'),
      ];

      final sanitized = HttpAuthConfig.sanitizeHeaders(sensitiveHeaders);
      expect(sanitized[0].value, equals('application/json')); // Não sensível
      expect(sanitized[1].value, startsWith('Bearer eyJ...***'));
      expect(sanitized[2].value, startsWith('liv...***'));
      expect(sanitized[3].value, startsWith('ses...***'));
    });
  });

  group('HttpRequestHistoryService (X02)', () {
    test('records and filters request entries with sanitization and FIFO retention', () {
      final history = HttpRequestHistoryService(maxRetention: 3);

      history.record(
        method: 'GET',
        url: 'https://admin:pass123@api.example.com/users',
        statusCode: 200,
        elapsedMs: 145,
        responseSizeBytes: 2048,
        requestLabel: 'List Users',
      );

      history.record(
        method: 'POST',
        url: 'https://api.example.com/login',
        statusCode: 401,
        elapsedMs: 80,
        responseSizeBytes: 120,
        requestLabel: 'Login',
        errorMessage: 'Invalid credentials',
      );

      history.record(
        method: 'POST',
        url: 'https://api.example.com/graphql',
        statusCode: 200,
        elapsedMs: 210,
        responseSizeBytes: 4096,
        isGraphQL: true,
      );

      expect(history.entries.length, equals(3));
      // Credenciais na URL devem ser expurgadas
      expect(history.entries.last.url, equals('https://api.example.com/users'));

      // Filtro por GraphQL
      final gqlEntries = history.filter(isGraphQL: true);
      expect(gqlEntries.length, equals(1));
      expect(gqlEntries.first.isGraphQL, isTrue);

      // Filtro por status code de erro
      final errors = history.filter(statusCode: 401);
      expect(errors.length, equals(1));
      expect(errors.first.requestLabel, equals('Login'));

      // Teste de FIFO: inserindo quarta chamada descarta a mais antiga
      history.record(
        method: 'GET',
        url: 'https://api.example.com/status',
        statusCode: 200,
        elapsedMs: 30,
        responseSizeBytes: 50,
      );
      expect(history.entries.length, equals(3));
      expect(history.entries.any((e) => e.requestLabel == 'List Users'), isFalse);
    });
  });

  group('GraphQLRequestSpec (X02)', () {
    test('generates canonical GraphQL payload and converts to HttpRequestSpec', () {
      const gql = GraphQLRequestSpec(
        query: 'query GetUser(\$id: ID!) { user(id: \$id) { id name email } }',
        operationName: 'GetUser',
        variables: {'id': '42'},
      );

      final payload = gql.toJsonPayload();
      expect(payload['query'], contains('query GetUser'));
      expect(payload['operationName'], equals('GetUser'));
      expect(payload['variables'], equals({'id': '42'}));

      final httpSpec = gql.toHttpRequestSpec(
        endpointUrl: 'https://api.example.com/graphql',
        requestName: 'Fetch User GraphQL',
      );

      expect(httpSpec.method, equals('POST'));
      expect(httpSpec.url, equals('https://api.example.com/graphql'));
      expect(httpSpec.headers.any((h) => h.name == 'Content-Type' && h.value == 'application/json'), isTrue);
      expect(httpSpec.body, contains('"operationName":"GetUser"'));
    });
  });

  group('FrameworkRouteScanner & Route Generation (X02)', () {
    const scanner = FrameworkRouteScanner();

    test('extracts routes across Spring, Express, FastAPI and NestJS syntaxes', () {
      const springCode = '''
@RestController
@RequestMapping("/api/v1")
public class UserController {
    @GetMapping("/users")
    public List<User> listUsers() {}

    @PostMapping("/users")
    public User createUser() {}
}
''';

      final springRoutes = scanner.scan(springCode, filePath: 'UserController.java', basePrefix: '/api/v1');
      expect(springRoutes.length, equals(2));
      expect(springRoutes[0].framework, equals('Spring'));
      expect(springRoutes[0].httpMethod, equals('GET'));
      expect(springRoutes[0].path, equals('/api/v1/users'));

      const expressCode = '''
const router = express.Router();
router.get('/products', getProducts);
router.post('/orders', createOrder);
app.delete('/cart/:id', clearCart);
''';

      final expressRoutes = scanner.scan(expressCode, filePath: 'routes.js');
      expect(expressRoutes.length, equals(3));
      expect(expressRoutes[0].framework, equals('Express'));
      expect(expressRoutes[0].httpMethod, equals('GET'));
      expect(expressRoutes[0].path, equals('/products'));

      const fastApiCode = '''
@router.get("/items")
def read_items():
    return []

@app.post("/items")
def create_item():
    pass
''';

      final fastApiRoutes = scanner.scan(fastApiCode, filePath: 'main.py');
      expect(fastApiRoutes.length, equals(2));
      expect(fastApiRoutes[0].framework, equals('FastAPI'));
      expect(fastApiRoutes[0].httpMethod, equals('GET'));

      const nestCode = '''
@Controller('customers')
export class CustomerController {
  @Get()
  findAll() {}

  @Post('create')
  create() {}
}
''';

      final nestRoutes = scanner.scan(nestCode, filePath: 'customer.controller.ts', basePrefix: 'customers');
      expect(nestRoutes.length, equals(2));
      expect(nestRoutes[0].framework, equals('NestJS'));
      expect(nestRoutes[0].httpMethod, equals('GET'));
    });

    test('generates valid .http document from extracted routes', () {
      const routes = [
        ExtractedRoute(framework: 'Spring', httpMethod: 'GET', path: '/api/v1/users', sourceFile: 'User.java', sourceLine: 10, handlerName: 'listUsers'),
        ExtractedRoute(framework: 'Spring', httpMethod: 'POST', path: '/api/v1/users', sourceFile: 'User.java', sourceLine: 25, handlerName: 'createUser'),
      ];

      final httpFileContent = scanner.generateHttpDocument(routes, defaultBaseUrl: 'https://api.local:8080');
      expect(httpFileContent, contains('@baseUrl = https://api.local:8080'));
      expect(httpFileContent, contains('### Spring: listUsers'));
      expect(httpFileContent, contains('GET {{baseUrl}}/api/v1/users'));
      expect(httpFileContent, contains('POST {{baseUrl}}/api/v1/users'));
    });
  });

  group('WebNavigationService & Cancellation (X02)', () {
    test('sanitizes user:password from navigation URLs', () {
      expect(
        WebNavigationService.sanitizeUrl('http://admin:secret123@myhost.internal:3000/dashboard'),
        equals('http://myhost.internal:3000/dashboard'),
      );
      expect(
        WebNavigationService.sanitizeUrl('https://api.example.com/v1/health'),
        equals('https://api.example.com/v1/health'),
      );
    });

    test('triggers cancellation token listeners deterministically', () {
      final token = HttpRequestCancellationToken();
      expect(token.isCancelled, isFalse);

      String? cancelReason;
      token.onCancel((reason) => cancelReason = reason);

      token.cancel('User aborted HTTP request');
      expect(token.isCancelled, isTrue);
      expect(cancelReason, equals('User aborted HTTP request'));
    });
  });
}
