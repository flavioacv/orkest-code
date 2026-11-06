import 'package:flutter/foundation.dart';
import 'package:orkest_code/app/core/domain/entities/lsp_diagnostic.dart';

/// Controlador reativo de problemas e diagnósticos (LSP/inspeções) por workspace.
///
/// Modela o repositório em memória de diagnósticos agrupados por arquivo (`filePath`),
/// com suporte a contadores agregados por severidade, filtros de busca por texto
/// e filtro estrito por severidade (`LspSeverity`).
class ProblemsController extends ChangeNotifier {
  final Map<String, List<LspDiagnostic>> _diagnosticsByFile = {};
  String _filterQuery = '';
  LspSeverity? _severityFilter;

  /// Mapa imutável de diagnósticos por caminho de arquivo.
  Map<String, List<LspDiagnostic>> get diagnosticsByFile => Map.unmodifiable(_diagnosticsByFile);

  /// Filtro textual ativo.
  String get filterQuery => _filterQuery;

  /// Filtro de severidade ativo (`null` exibe todas).
  LspSeverity? get severityFilter => _severityFilter;

  /// Total de erros (severidade mais crítica).
  int get errorCount => _countBySeverity(LspSeverity.error);

  /// Total de avisos (warnings).
  int get warningCount => _countBySeverity(LspSeverity.warning);

  /// Total de informações (infos).
  int get infoCount => _countBySeverity(LspSeverity.info);

  /// Total de dicas (hints).
  int get hintCount => _countBySeverity(LspSeverity.hint);

  /// Total geral de diagnósticos registrados.
  int get totalCount {
    var count = 0;
    for (final list in _diagnosticsByFile.values) {
      count += list.length;
    }
    return count;
  }

  /// Define ou atualiza os diagnósticos de um arquivo específico.
  void setDiagnostics(String filePath, List<LspDiagnostic> diagnostics) {
    if (diagnostics.isEmpty) {
      if (_diagnosticsByFile.remove(filePath) != null) {
        notifyListeners();
      }
    } else {
      _diagnosticsByFile[filePath] = List.unmodifiable(diagnostics);
      notifyListeners();
    }
  }

  /// Remove os diagnósticos associados a um arquivo (ex.: arquivo fechado ou deletado).
  void clearFile(String filePath) {
    if (_diagnosticsByFile.remove(filePath) != null) {
      notifyListeners();
    }
  }

  /// Limpa todos os diagnósticos registrados (ex.: troca de workspace).
  void clearAll() {
    if (_diagnosticsByFile.isNotEmpty) {
      _diagnosticsByFile.clear();
      notifyListeners();
    }
  }

  /// Atualiza o filtro textual.
  void setFilterQuery(String query) {
    final trimmed = query.trim().toLowerCase();
    if (_filterQuery != trimmed) {
      _filterQuery = trimmed;
      notifyListeners();
    }
  }

  /// Atualiza o filtro de severidade.
  void setSeverityFilter(LspSeverity? severity) {
    if (_severityFilter != severity) {
      _severityFilter = severity;
      notifyListeners();
    }
  }

  /// Retorna os arquivos e seus diagnósticos filtrados de acordo com `filterQuery` e `severityFilter`.
  Map<String, List<LspDiagnostic>> get filteredDiagnostics {
    if (_filterQuery.isEmpty && _severityFilter == null) {
      return _diagnosticsByFile;
    }

    final result = <String, List<LspDiagnostic>>{};
    for (final entry in _diagnosticsByFile.entries) {
      final fileMatches = _filterQuery.isNotEmpty && entry.key.toLowerCase().contains(_filterQuery);
      final matchedList = entry.value.where((diag) {
        if (_severityFilter != null && diag.severity != _severityFilter) {
          return false;
        }
        if (_filterQuery.isEmpty || fileMatches) {
          return true;
        }
        final msgMatches = diag.message.toLowerCase().contains(_filterQuery);
        final codeMatches = diag.code?.toLowerCase().contains(_filterQuery) ?? false;
        final sourceMatches = diag.source?.toLowerCase().contains(_filterQuery) ?? false;
        return msgMatches || codeMatches || sourceMatches;
      }).toList();

      if (matchedList.isNotEmpty) {
        result[entry.key] = matchedList;
      }
    }
    return result;
  }

  int _countBySeverity(LspSeverity severity) {
    var count = 0;
    for (final list in _diagnosticsByFile.values) {
      for (final diag in list) {
        if (diag.severity == severity) count++;
      }
    }
    return count;
  }
}
