import 'package:orkest_code/app/orkest/domain/entities/http_document.dart';
import 'package:orkest_code/app/orkest/domain/entities/http_response_result.dart';
import 'package:orkest_code/app/orkest/domain/exceptions/http_request_error.dart';
import 'package:orkest_code/app/core/domain/result.dart';

/// Executa um request de um arquivo `.http`. Motor único da aba e da CLI
/// (`orkest http run`), como o `DbQueryService` é para o `.dbq`.
abstract class HttpRequestRunner {
  /// Dispara [spec] **já interpolado**. [baseDir] é a pasta do arquivo `.http`,
  /// usada para resolver `< ./body.json`.
  Future<Result<HttpResponseResult, HttpRequestError>> send(
    HttpRequestSpec spec, {
    required String baseDir,
    Duration timeout,
    bool followRedirects,
  });
}
