import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/data/dap/multi_language_debug_adapter.dart';
import 'package:orkest_code/app/core/domain/entities/multi_language_debug_adapter.dart';

void main() {
  group('MultiLanguageDebugAdapter Catalog & Capabilities (R04)', () {
    test('resolves registered debug adapter by language correctly', () {
      expect(MultiLanguageDebugRegistry.adapterForLanguage('typescript')?.adapterId, equals('pwa-node'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('javascript')?.adapterId, equals('pwa-node'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('python')?.adapterId, equals('debugpy'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('rust')?.adapterId, equals('lldb'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('c')?.adapterId, equals('lldb'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('go')?.adapterId, equals('dlv'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('java')?.adapterId, equals('java'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('csharp')?.adapterId, equals('coreclr'));
      expect(MultiLanguageDebugRegistry.adapterForLanguage('dart')?.adapterId, equals('dart'));

      // Linguagem não suportada
      expect(MultiLanguageDebugRegistry.adapterForLanguage('unsupported_lang'), isNull);
    });

    test('validates hardware watchpoints support matrix across adapters', () {
      // Rust (CodeLLDB) e Go (Delve) e Java suportam watchpoints de memória/campo
      final rustAdapter = MultiLanguageDebugRegistry.adapterById('lldb');
      expect(rustAdapter?.capabilities.supportsWatchpoints, isTrue);

      final goAdapter = MultiLanguageDebugRegistry.adapterById('dlv');
      expect(goAdapter?.capabilities.supportsWatchpoints, isTrue);

      final javaAdapter = MultiLanguageDebugRegistry.adapterById('java');
      expect(javaAdapter?.capabilities.supportsWatchpoints, isTrue);

      // Python, TS e Dart NÃO suportam hardware watchpoints
      final pyAdapter = MultiLanguageDebugRegistry.adapterById('debugpy');
      expect(pyAdapter?.capabilities.supportsWatchpoints, isFalse);

      final tsAdapter = MultiLanguageDebugRegistry.adapterById('pwa-node');
      expect(tsAdapter?.capabilities.supportsWatchpoints, isFalse);

      final dartAdapter = MultiLanguageDebugRegistry.adapterById('dart');
      expect(dartAdapter?.capabilities.supportsWatchpoints, isFalse);
    });

    test('validates HotSwap / Hot Reload matrix across adapters', () {
      // Dart/Flutter, Java (JDWP) e Node (V8) suportam HotSwap de código
      expect(MultiLanguageDebugRegistry.adapterById('dart')?.capabilities.supportsHotSwap, isTrue);
      expect(MultiLanguageDebugRegistry.adapterById('java')?.capabilities.supportsHotSwap, isTrue);
      expect(MultiLanguageDebugRegistry.adapterById('pwa-node')?.capabilities.supportsHotSwap, isTrue);
      expect(MultiLanguageDebugRegistry.adapterById('coreclr')?.capabilities.supportsHotSwap, isTrue);

      // Rust, Go e Python NÃO suportam HotSwap nativo em execução
      expect(MultiLanguageDebugRegistry.adapterById('lldb')?.capabilities.supportsHotSwap, isFalse);
      expect(MultiLanguageDebugRegistry.adapterById('dlv')?.capabilities.supportsHotSwap, isFalse);
      expect(MultiLanguageDebugRegistry.adapterById('debugpy')?.capabilities.supportsHotSwap, isFalse);
    });

    test('validates restart frame (drop to frame) matrix across adapters', () {
      // Dart, TS e Java suportam retorno a frame anterior
      expect(MultiLanguageDebugRegistry.adapterById('dart')?.capabilities.supportsRestartFrame, isTrue);
      expect(MultiLanguageDebugRegistry.adapterById('pwa-node')?.capabilities.supportsRestartFrame, isTrue);
      expect(MultiLanguageDebugRegistry.adapterById('java')?.capabilities.supportsRestartFrame, isTrue);

      // Rust, Go, Python e .NET têm limitações de unwinding de pilha
      expect(MultiLanguageDebugRegistry.adapterById('lldb')?.capabilities.supportsRestartFrame, isFalse);
      expect(MultiLanguageDebugRegistry.adapterById('dlv')?.capabilities.supportsRestartFrame, isFalse);
      expect(MultiLanguageDebugRegistry.adapterById('debugpy')?.capabilities.supportsRestartFrame, isFalse);
      expect(MultiLanguageDebugRegistry.adapterById('coreclr')?.capabilities.supportsRestartFrame, isFalse);
    });

    test('documents licenses and installation hints transparently', () {
      final py = MultiLanguageDebugRegistry.adapterById('debugpy');
      expect(py?.license, equals('MIT'));
      expect(py?.installHint, contains('pip install debugpy'));

      final lldb = MultiLanguageDebugRegistry.adapterById('lldb');
      expect(lldb?.license, equals('GPL-2.0'));
      expect(lldb?.installHint, contains('CodeLLDB'));

      final java = MultiLanguageDebugRegistry.adapterById('java');
      expect(java?.license, equals('EPL-1.0'));
      expect(java?.installHint, contains('Eclipse JDT'));

      final dlv = MultiLanguageDebugRegistry.adapterById('dlv');
      expect(dlv?.license, equals('MIT'));
      expect(dlv?.installHint, contains('go-delve'));
    });

    test('resolves adapter launch command and respects user overrides', () {
      // Python default
      final pyCmd = MultiLanguageDebugAdapter.resolveAdapterCommand(languageId: 'python');
      expect(pyCmd?.$1, equals('python3'));
      expect(pyCmd?.$2, equals(['-m', 'debugpy.adapter']));

      // Python custom override
      final pyCustom = MultiLanguageDebugAdapter.resolveAdapterCommand(
        languageId: 'python',
        customExecutable: '/opt/venv/bin/python',
        customArgs: ['-m', 'debugpy', '--listen', '9000'],
      );
      expect(pyCustom?.$1, equals('/opt/venv/bin/python'));
      expect(pyCustom?.$2, equals(['-m', 'debugpy', '--listen', '9000']));

      // Go default
      final goCmd = MultiLanguageDebugAdapter.resolveAdapterCommand(languageId: 'go');
      expect(goCmd?.$1, equals('dlv'));
      expect(goCmd?.$2, equals(['dap']));
    });

    test('builds launch arguments merging template and custom settings', () {
      final launchArgs = MultiLanguageDebugAdapter.buildLaunchArgs(
        languageId: 'python',
        program: 'manage.py',
        cwd: '/workspace/django_app',
        args: ['runserver', '--noreload'],
        extraArgs: {'justMyCode': false},
      );

      expect(launchArgs['program'], equals('manage.py'));
      expect(launchArgs['cwd'], equals('/workspace/django_app'));
      expect(launchArgs['args'], equals(['runserver', '--noreload']));
      expect(launchArgs['type'], equals('debugpy'));
      expect(launchArgs['justMyCode'], isFalse);
    });

    test('audits adapter availability and limitations objectively', () {
      // Auditoria com executável disponível
      final report = MultiLanguageDebugAdapter.auditAdapter(
        adapterId: 'debugpy',
        isExecutableAvailable: true,
      );
      expect(report.status, equals(DebugAdapterStatus.available));
      expect(report.license, equals('MIT'));
      expect(report.limitations.length, greaterThanOrEqualTo(2));
      expect(report.limitations, contains('Restart Frame (drop to frame) não suportado pelo runtime.'));
      expect(report.limitations, contains('HotSwap / Hot Reload de código em execução indisponível.'));

      // Auditoria com binário ausente
      final missingReport = MultiLanguageDebugAdapter.auditAdapter(
        adapterId: 'lldb',
        isExecutableAvailable: false,
      );
      expect(missingReport.status, equals(DebugAdapterStatus.missingExecutable));
      expect(missingReport.license, equals('GPL-2.0'));

      // Adaptador desconhecido
      final unknownReport = MultiLanguageDebugAdapter.auditAdapter(adapterId: 'fake_adapter');
      expect(unknownReport.status, equals(DebugAdapterStatus.unsupported));
    });
  });
}
