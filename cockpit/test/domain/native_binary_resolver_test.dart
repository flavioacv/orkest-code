import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/orkest/domain/services/native_binary_resolver.dart';

void main() {
  group('NativeBinaryResolver (A05)', () {
    test('identifies platform directory names and extensions', () {
      expect(NativePlatformArch.macosArm64.directoryName, 'macos-arm64');
      expect(NativePlatformArch.macosArm64.executableExtension, '');

      expect(NativePlatformArch.linuxX64.directoryName, 'linux-x64');
      expect(NativePlatformArch.linuxX64.executableExtension, '');

      expect(NativePlatformArch.windowsX64.directoryName, 'windows-x64');
      expect(NativePlatformArch.windowsX64.executableExtension, '.exe');
    });

    test('resolves bundled binary when available', () {
      final tempDir = Directory.systemTemp.createTempSync('orkest_bundle_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final targetDir = Directory('${tempDir.path}/macos-arm64')..createSync(recursive: true);
      final binFile = File('${targetDir.path}/openidea-server')..writeAsStringSync('#!/bin/sh\nexit 0');

      final resolver = NativeBinaryResolver(
        customPlatform: NativePlatformArch.macosArm64,
        bundledBinariesDir: tempDir.path,
      );

      final path = resolver.resolve('openidea-server', allowSystemPath: false);
      expect(path, binFile.path);
    });

    test('resolves local workspace binary when available', () {
      final tempDir = Directory.systemTemp.createTempSync('orkest_ws_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final binDir = Directory('${tempDir.path}/.orkest/bin')..createSync(recursive: true);
      final binFile = File('${binDir.path}/custom-tool')..writeAsStringSync('echo ok');

      const resolver = NativeBinaryResolver(
        customPlatform: NativePlatformArch.linuxX64,
      );

      final path = resolver.resolve('custom-tool', workspaceRoot: tempDir.path, allowSystemPath: false);
      expect(path, binFile.path);
    });

    test('appends .exe extension on Windows platforms', () {
      final tempDir = Directory.systemTemp.createTempSync('orkest_win_test_');
      addTearDown(() => tempDir.deleteSync(recursive: true));

      final binDir = Directory('${tempDir.path}/.orkest/bin')..createSync(recursive: true);
      final exeFile = File('${binDir.path}/mytool.exe')..writeAsStringSync('binary');

      const resolver = NativeBinaryResolver(
        customPlatform: NativePlatformArch.windowsX64,
      );

      final path = resolver.resolve('mytool', workspaceRoot: tempDir.path, allowSystemPath: false);
      expect(path, exeFile.path);
    });

    test('throws NativeBinaryNotFoundException on required binary missing', () {
      const resolver = NativeBinaryResolver(
        customPlatform: NativePlatformArch.macosX64,
      );

      expect(
        () => resolver.resolveRequired('non_existent_binary_xyz_123', allowSystemPath: false),
        throwsA(isA<NativeBinaryNotFoundException>().having(
          (e) => e.binaryName,
          'binaryName',
          'non_existent_binary_xyz_123',
        )),
      );
    });
  });
}
