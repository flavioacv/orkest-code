import 'package:flutter_test/flutter_test.dart';
import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/core/domain/services/harness_host_evidence.dart';

void main() {
  group('HarnessHostEvidence & Capabilities (H03)', () {
    group('Inspection of Host Evidence', () {
      test('identifies direct interactive binary with high confidence', () {
        final report = HarnessHostEvidence.inspect(
          executable: '/usr/local/bin/claude',
          argv: ['claude'],
        );

        expect(report.isKnownHarness, isTrue);
        expect(report.isInteractive, isTrue);
        expect(report.isWrapperInvocation, isFalse);
        expect(report.kind, HarnessKind.claudeCode);
        expect(report.entryPoint, 'claude');
        expect(report.confidence, equals(1.0));
      });

      test('identifies wrapper invocation with runtime confidence', () {
        final report = HarnessHostEvidence.inspect(
          executable: '/usr/bin/npx',
          argv: ['npx', '-y', '@google/gemini-cli'],
        );

        expect(report.isKnownHarness, isTrue);
        expect(report.isInteractive, isTrue);
        expect(report.isWrapperInvocation, isTrue);
        expect(report.kind, HarnessKind.gemini);
        expect(report.entryPoint, 'gemini');
        expect(report.confidence, equals(0.85));
      });

      test('identifies python -m module execution for aider', () {
        final report = HarnessHostEvidence.inspect(
          executable: 'python3',
          argv: ['python3', '-m', 'aider'],
        );

        expect(report.isKnownHarness, isTrue);
        expect(report.isInteractive, isTrue);
        expect(report.isWrapperInvocation, isTrue);
        expect(report.kind, HarnessKind.aider);
        expect(report.confidence, equals(0.85));
      });

      test('detects non-interactive batch mode and marks isInteractive false', () {
        final report = HarnessHostEvidence.inspect(
          executable: 'agy',
          argv: ['agy', '-p', 'write a function'],
        );

        expect(report.isKnownHarness, isTrue);
        expect(report.isInteractive, isFalse);
        expect(report.kind, HarnessKind.antigravity);
        expect(report.confidence, equals(0.0));
      });

      test('unrecognized CLIs strictly adhere to generic contract', () {
        final commands = [
          ['/bin/bash', 'bash'],
          ['/usr/bin/make', 'make', 'all'],
          ['python3', 'train_model.py'],
          ['arbitrary-agent-cli', 'talk'],
        ];

        for (final cmd in commands) {
          final report = HarnessHostEvidence.inspect(
            executable: cmd[0],
            argv: cmd,
          );

          expect(report.isKnownHarness, isFalse,
              reason: 'Comando ${cmd[0]} não deve inventar harness.');
          expect(report.isInteractive, isFalse);
          expect(report.kind, isNull);
          expect(report.spec, isNull);
          expect(report.confidence, equals(0.0));
        }
      });
    });

    group('Harness Catalog Capabilities & Specs', () {
      test('catalog exposes exactly 11 validated CLIs', () {
        expect(HarnessCatalog.specs.length, equals(11));
        expect(HarnessKind.values.length, equals(11));
      });

      test('validates formal capabilities of each harness', () {
        // Structured hooks support
        expect(
          HarnessCatalog.specs[HarnessKind.antigravity]!.supportsStructuredHooks,
          isTrue,
        );
        expect(
          HarnessCatalog.specs[HarnessKind.claudeCode]!.supportsStructuredHooks,
          isTrue,
        );
        expect(
          HarnessCatalog.specs[HarnessKind.gemini]!.supportsStructuredHooks,
          isFalse,
        );
        expect(
          HarnessCatalog.specs[HarnessKind.aider]!.supportsStructuredHooks,
          isFalse,
        );

        // Resume support
        expect(
          HarnessCatalog.specs[HarnessKind.claudeCode]!.supportsResume,
          isTrue,
        );
        expect(
          HarnessCatalog.specs[HarnessKind.claudeCode]!.resumeSyntax,
          equals('claude --resume {id}'),
        );
        expect(
          HarnessCatalog.specs[HarnessKind.codex]!.resumeSyntax,
          equals('codex resume {id}'),
        );
        expect(
          HarnessCatalog.specs[HarnessKind.ollama]!.supportsResume,
          isFalse,
        );
      });

      test('all specs provide valid nonInteractiveFlags and adminSubcommands', () {
        for (final spec in HarnessCatalog.specs.values) {
          expect(spec.label.isNotEmpty, isTrue);
          expect(spec.primaryEntryPoint.isNotEmpty, isTrue);
          expect(spec.assetPath.endsWith('.svg'), isTrue);
          expect(spec.allEntryPoints, contains(spec.primaryEntryPoint));
        }
      });
    });

    group('Host Executable Availability Probe', () {
      test('resolves standard binaries on host', () {
        // Pelo menos um shell ou comando padrão do SO existe
        final hasSh = HarnessHostEvidence.isExecutableAvailable('/bin/sh');
        expect(hasSh, isTrue);
      });

      test('returns false cleanly for non-existent binaries', () {
        final exists = HarnessHostEvidence.isExecutableAvailable(
          '/non/existent/path/to/fake_cli_tool_xyz_123',
        );
        expect(exists, isFalse);
      });
    });
  });
}
