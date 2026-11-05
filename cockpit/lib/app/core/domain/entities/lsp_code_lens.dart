import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';

/// Comando associado a uma CodeLens ou CodeAction no LSP (L06).
class LspCommand {
  const LspCommand({
    required this.title,
    required this.command,
    this.arguments,
  });

  /// Título visível na interface do editor (ex.: "3 references", "Run Test").
  final String title;

  /// Identificador do comando a ser invocado.
  final String command;

  /// Argumentos associados ao comando.
  final List<dynamic>? arguments;

  factory LspCommand.fromJson(Map<String, dynamic> json) {
    return LspCommand(
      title: json['title'] as String? ?? '',
      command: json['command'] as String? ?? '',
      arguments: json['arguments'] as List<dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'command': command,
        if (arguments != null) 'arguments': arguments,
      };

  @override
  String toString() => 'LspCommand("$title" -> $command)';
}

/// Ação contextual embutida no código (CodeLens) segundo LSP 3.16+ (L06).
class LspCodeLens {
  const LspCodeLens({
    required this.range,
    this.command,
    this.data,
  });

  /// Range do documento onde a CodeLens se aplica.
  final LspRange range;

  /// Comando resolvido (pode ser null se requerer `codeLens/resolve`).
  final LspCommand? command;

  /// Dados arbitrários preservados para resolução sob demanda via `codeLens/resolve`.
  final dynamic data;

  factory LspCodeLens.fromJson(Map<String, dynamic> json) {
    final cmd = json['command'] as Map?;
    return LspCodeLens(
      range: LspRange.fromJson((json['range'] as Map? ?? const {}).cast<String, dynamic>()),
      command: cmd != null ? LspCommand.fromJson(cmd.cast<String, dynamic>()) : null,
      data: json['data'],
    );
  }

  Map<String, dynamic> toJson() => {
        'range': range.toJson(),
        if (command != null) 'command': command!.toJson(),
        if (data != null) 'data': data,
      };

  @override
  String toString() =>
      'LspCodeLens(range: $range, title: "${command?.title ?? '<unresolved>'}")';
}

/// Decodificador de lista de CodeLenses da resposta LSP.
List<LspCodeLens> parseCodeLenses(dynamic response) {
  if (response is! List) return const [];
  return List.unmodifiable(
    response
        .whereType<Map>()
        .map((m) => LspCodeLens.fromJson(m.cast<String, dynamic>())),
  );
}
