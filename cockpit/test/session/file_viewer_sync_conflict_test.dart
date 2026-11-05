import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/data/filesystem/file_reader_impl.dart';
import 'package:orkest_code/app/orkest/domain/entities/file_view.dart';
import 'package:orkest_code/app/orkest/ui/session/file_viewer_session.dart';

void main() {
  group('FileViewerSession - Sincronização, Dirty Buffers e Conflito de Disco', () {
    test('gerencia transição de dirty e desativa preview automaticamente', () {
      final session = FileViewerSession(
        id: 'tab-1',
        projectId: 'proj-1',
        path: '/tmp/test.dart',
        view: const FileViewText('void main() {}'),
        isPreview: true,
      );

      expect(session.dirty, isFalse);
      expect(session.isPreview, isTrue);

      var notified = false;
      session.addListener(() => notified = true);

      session.setDirty(true);
      expect(session.dirty, isTrue);
      expect(session.isPreview, isFalse); // edição fixa a aba (pin)
      expect(notified, isTrue);

      notified = false;
      session.setDirty(true); // idempotente
      expect(notified, isFalse);
    });

    test('detecta e sinaliza hasDiskConflict com notificações reativas', () {
      final session = FileViewerSession(
        id: 'tab-2',
        projectId: 'proj-1',
        path: '/tmp/test.dart',
        view: const FileViewText('initial content'),
      );

      expect(session.hasDiskConflict, isFalse);

      var notifications = 0;
      session.addListener(() => notifications++);

      session.setDiskConflict(true);
      expect(session.hasDiskConflict, isTrue);
      expect(notifications, 1);

      session.setDiskConflict(true); // idempotente
      expect(notifications, 1);

      session.setDiskConflict(false);
      expect(session.hasDiskConflict, isFalse);
      expect(notifications, 2);
    });

    test('adoptDisk atualiza view e notifica listeners', () {
      final session = FileViewerSession(
        id: 'tab-3',
        projectId: 'proj-1',
        path: '/tmp/test.dart',
        view: const FileViewText('version 1'),
      );

      var notified = false;
      session.addListener(() => notified = true);

      session.adoptDisk(const FileViewText('version 2'));
      expect((session.view as FileViewText).text, 'version 2');
      expect(notified, isTrue);
    });
  });

  group('FileReaderImpl - Proteção de Arquivos Grandes e Preservação de CRLF', () {
    late Directory tempDir;
    const reader = FileReaderImpl();

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('file_sync_test');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test('preserva CRLF em arquivos com terminador Windows', () async {
      final crlfFile = File('${tempDir.path}/windows.txt');
      await crlfFile.writeAsString('linha1\r\nlinha2\r\nlinha3\r\n');

      final view = await reader.read(crlfFile.path);
      expect(view, isA<FileViewText>());
      final text = (view as FileViewText).text;
      expect(text.contains('\r\n'), isTrue);

      // Simulação de salvamento com normalização CRLF reversa
      final editedInEditor = '${text.replaceAll('\r\n', '\n')}nova linha\n';
      final savedText = editedInEditor.replaceAll(RegExp(r'(?<!\r)\n'), '\r\n');
      expect(savedText.contains('\r\n'), isTrue);
      expect(savedText.contains(RegExp(r'(?<!\r)\n')), isFalse);
    });

    test('limita arquivos maiores que 2MB retornando FileViewUnsupported', () async {
      final largeFile = File('${tempDir.path}/huge.bin');
      // Escreve 2.1 MB de dados
      final sink = largeFile.openWrite();
      final chunk = List<int>.filled(64 * 1024, 65); // 64KB de 'A'
      for (var i = 0; i < 34; i++) {
        sink.add(chunk);
      }
      await sink.flush();
      await sink.close();

      final view = await reader.read(largeFile.path);
      expect(view, isA<FileViewUnsupported>());
    });
  });
}
