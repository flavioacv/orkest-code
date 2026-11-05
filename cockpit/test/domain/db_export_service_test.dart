import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/entities/db_result.dart';
import 'package:orkest_code/app/orkest/domain/services/db_export_service.dart';

void main() {
  const exporter = DbExportService();

  final sampleResult = DbResult(
    columns: const [
      DbColumn('id', 'INTEGER'),
      DbColumn('name', 'TEXT'),
      DbColumn('notes', 'TEXT'),
      DbColumn('created_at', 'DATETIME'),
      DbColumn('avatar', 'BLOB'),
    ],
    rows: [
      [
        1,
        'Alice',
        'Hello, "world"!',
        DateTime.parse('2026-11-05T12:00:00Z'),
        Uint8List.fromList([1, 2, 3]),
      ],
      [
        2,
        'Bob',
        'Line 1\nLine 2',
        null,
        null,
      ],
    ],
    elapsed: const Duration(milliseconds: 15),
  );

  group('DbExportService - CSV', () {
    test('exports standard CSV with headers and proper escaping', () {
      final csv = exporter.exportCsv(sampleResult);

      expect(csv, startsWith('id,name,notes,created_at,avatar\n'));
      expect(csv, contains('1,Alice,"Hello, ""world""!",2026-11-05T12:00:00.000Z,<blob 3 bytes>'));
      // A linha 2 contém uma quebra de linha embutida no campo notes com aspas duplas
      expect(csv, contains('"Line 1\nLine 2"'));
      expect(csv, contains('2,Bob,"Line 1\nLine 2",,'));
    });

    test('supports custom delimiter and omitting headers', () {
      final csv = exporter.exportCsv(
        sampleResult,
        options: const DbCsvExportOptions(
          delimiter: ';',
          includeHeaders: false,
          nullRepresentation: 'NULL',
        ),
      );

      expect(csv.startsWith('id;name'), isFalse);
      expect(csv, contains('1;Alice;"Hello, ""world""!";2026-11-05T12:00:00.000Z;<blob 3 bytes>'));
      expect(csv, contains('2;Bob;"Line 1\nLine 2";NULL;NULL'));
    });
  });

  group('DbExportService - JSON', () {
    test('exports formatted pretty JSON with column keys', () {
      final jsonStr = exporter.exportJson(sampleResult, pretty: true);
      final list = jsonDecode(jsonStr) as List<dynamic>;

      expect(list.length, 2);
      final first = list[0] as Map<String, dynamic>;
      expect(first['id'], 1);
      expect(first['name'], 'Alice');
      expect(first['notes'], 'Hello, "world"!');
      expect(first['created_at'], '2026-11-05T12:00:00.000Z');
      expect(first['avatar'], {'blob': 3});

      final second = list[1] as Map<String, dynamic>;
      expect(second['id'], 2);
      expect(second['name'], 'Bob');
      expect(second['notes'], 'Line 1\nLine 2');
      expect(second['created_at'], isNull);
      expect(second['avatar'], isNull);
    });

    test('exports compact JSON when pretty is false', () {
      final jsonStr = exporter.exportJson(sampleResult, pretty: false);
      expect(jsonStr.contains('\n'), isFalse);
      final list = jsonDecode(jsonStr) as List<dynamic>;
      expect(list.length, 2);
    });
  });
}
