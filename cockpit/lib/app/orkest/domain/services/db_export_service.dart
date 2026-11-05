import 'dart:convert';
import 'dart:typed_data';

import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';

/// Opções de exportação CSV.
class DbCsvExportOptions {
  const DbCsvExportOptions({
    this.delimiter = ',',
    this.includeHeaders = true,
    this.nullRepresentation = '',
    this.lineTerminator = '\n',
  });

  final String delimiter;
  final bool includeHeaders;
  final String nullRepresentation;
  final String lineTerminator;
}

/// Serviço de exportação estruturada de resultados de banco de dados (B03).
class DbExportService {
  const DbExportService();

  /// Exporta [result] para formato CSV formatado conforme as opções.
  String exportCsv(DbResult result, {DbCsvExportOptions options = const DbCsvExportOptions()}) {
    final buffer = StringBuffer();
    final delim = options.delimiter;
    final eol = options.lineTerminator;

    if (options.includeHeaders) {
      final headerLine = result.columns
          .map((col) => _escapeCsvCell(col.name, delim))
          .join(delim);
      buffer.write(headerLine);
      buffer.write(eol);
    }

    for (final row in result.rows) {
      final rowParts = <String>[];
      for (var i = 0; i < result.columns.length; i++) {
        final val = i < row.length ? row[i] : null;
        rowParts.add(_formatCsvCell(val, delim, options.nullRepresentation));
      }
      buffer.write(rowParts.join(delim));
      buffer.write(eol);
    }

    return buffer.toString();
  }

  /// Exporta [result] para formato JSON (array de objetos chave-valor).
  String exportJson(DbResult result, {bool pretty = true}) {
    final colNames = [for (final c in result.columns) c.name];
    final items = <Map<String, Object?>>[];

    for (final row in result.rows) {
      final map = <String, Object?>{};
      for (var i = 0; i < colNames.length; i++) {
        final val = i < row.length ? row[i] : null;
        map[colNames[i]] = _jsonValue(val);
      }
      items.add(map);
    }

    final encoder = pretty ? const JsonEncoder.withIndent('  ') : const JsonEncoder();
    return encoder.convert(items);
  }

  static String _formatCsvCell(Object? val, String delim, String nullRep) {
    if (val == null) return nullRep;
    if (val is Uint8List) {
      return _escapeCsvCell('<blob ${val.length} bytes>', delim);
    }
    if (val is DateTime) {
      return _escapeCsvCell(val.toIso8601String(), delim);
    }
    return _escapeCsvCell(val.toString(), delim);
  }

  static String _escapeCsvCell(String text, String delim) {
    final needsQuotes = text.contains(delim) ||
        text.contains('"') ||
        text.contains('\n') ||
        text.contains('\r');
    if (!needsQuotes) return text;
    final escaped = text.replaceAll('"', '""');
    return '"$escaped"';
  }

  static Object? _jsonValue(Object? val) => switch (val) {
    null || int() || double() || bool() || String() => val,
    DateTime() => val.toIso8601String(),
    Uint8List() => {'blob': val.length},
    _ => val.toString(),
  };
}
