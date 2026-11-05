import 'package:orkest_code/app/core/domain/entities/harness.dart';
import 'package:orkest_code/app/orkest/domain/services/terminal_harness_classifier.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TerminalHarnessClassifier', () {
    group('Antigravity', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/local/bin/agy',
            argv: ['agy'],
          ),
          equals(HarnessKind.antigravity),
        );
      });

      test('interactive prompt or resume', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'agy',
            argv: ['agy', 'resume'],
          ),
          equals(HarnessKind.antigravity),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'agy',
            argv: ['agy', 'fix bug in code'],
          ),
          equals(HarnessKind.antigravity),
        );
      });

      test('rejects print mode and admin subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'agy',
            argv: ['agy', '-p', 'hello'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'agy',
            argv: ['agy', 'version'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'agy',
            argv: ['agy', '--help'],
          ),
          isNull,
        );
      });
    });

    group('Claude Code', () {
      test('direct interactive launch and resume', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/bin/claude',
            argv: ['claude'],
          ),
          equals(HarnessKind.claudeCode),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'claude',
            argv: ['claude', '-c'],
          ),
          equals(HarnessKind.claudeCode),
        );
      });

      test('via node runtime script wrapper', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'node',
            argv: [
              'node',
              '/usr/lib/node_modules/@anthropic-ai/claude-code/cli.js',
            ],
          ),
          equals(HarnessKind.claudeCode),
        );
      });

      test('rejects non-interactive print and admin subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'claude',
            argv: ['claude', '-p', 'explain code'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'claude',
            argv: ['claude', 'mcp', 'list'],
          ),
          isNull,
        );
      });
    });

    group('Codex', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'codex',
            argv: ['codex'],
          ),
          equals(HarnessKind.codex),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'codex',
            argv: ['codex', 'resume'],
          ),
          equals(HarnessKind.codex),
        );
      });

      test('rejects exec mode and admin subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'codex',
            argv: ['codex', 'exec', 'do work'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'codex',
            argv: ['codex', 'auth'],
          ),
          isNull,
        );
      });
    });

    group('Cursor', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/bin/cursor-agent',
            argv: ['cursor-agent'],
          ),
          equals(HarnessKind.cursor),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'cursor',
            argv: ['cursor'],
          ),
          equals(HarnessKind.cursor),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/home/user/.local/bin/agent',
            argv: ['agent'],
          ),
          equals(HarnessKind.cursor),
        );
      });

      test('rejects print mode and subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'cursor-agent',
            argv: ['cursor-agent', '-p', 'prompt'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'cursor-agent',
            argv: ['cursor-agent', 'login'],
          ),
          isNull,
        );
      });
    });

    group('GitHub Copilot', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'copilot',
            argv: ['copilot'],
          ),
          equals(HarnessKind.gitHubCopilot),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'github-copilot',
            argv: ['github-copilot'],
          ),
          equals(HarnessKind.gitHubCopilot),
        );
      });

      test('rejects prompt flag and subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'copilot',
            argv: ['copilot', '-p', 'prompt'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'copilot',
            argv: ['copilot', 'auth'],
          ),
          isNull,
        );
      });
    });

    group('OpenCode', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'opencode',
            argv: ['opencode'],
          ),
          equals(HarnessKind.openCode),
        );
      });

      test('rejects run mode and subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'opencode',
            argv: ['opencode', 'run', 'echo hi'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'opencode',
            argv: ['opencode', 'models'],
          ),
          isNull,
        );
      });
    });

    group('Pi', () {
      test('direct interactive launch and resume', () {
        expect(
          TerminalHarnessClassifier.classify(executable: 'pi', argv: ['pi']),
          equals(HarnessKind.pi),
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'pi',
            argv: ['pi', '-c'],
          ),
          equals(HarnessKind.pi),
        );
      });

      test('rejects print mode, rpc/json modes and subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'pi',
            argv: ['pi', '-p', 'prompt'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'pi',
            argv: ['pi', '--mode', 'json'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'pi',
            argv: ['pi', '--mode=rpc'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'pi',
            argv: ['pi', 'export'],
          ),
          isNull,
        );
      });
    });

    group('Generic binaries and incidental arguments', () {
      test('shell and generic binaries return null', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/bin/bash',
            argv: ['bash'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/bin/zsh',
            argv: ['zsh'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'git',
            argv: ['git', 'commit', '-m', 'claude code update'],
          ),
          isNull,
        );
      });
    });

    group('Gemini CLI (H03)', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/local/bin/gemini',
            argv: ['gemini'],
          ),
          equals(HarnessKind.gemini),
        );
      });

      test('interactive with prompt', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'gemini-cli',
            argv: ['gemini-cli', 'how to test flutter?'],
          ),
          equals(HarnessKind.gemini),
        );
      });

      test('via npx runner', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'npx',
            argv: ['npx', '-y', '@google/gemini-cli'],
          ),
          equals(HarnessKind.gemini),
        );
      });

      test('rejects non-interactive prompt flags and admin subcommands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'gemini',
            argv: ['gemini', '-p', 'batch prompt'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'gemini',
            argv: ['gemini', 'auth'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'gemini',
            argv: ['gemini', '--version'],
          ),
          isNull,
        );
      });
    });

    group('Kimi CLI (H03)', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/bin/kimi',
            argv: ['kimi'],
          ),
          equals(HarnessKind.kimi),
        );
      });

      test('rejects quiet mode and login/auth', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'kimi',
            argv: ['kimi', '-q'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'kimi',
            argv: ['kimi', 'login'],
          ),
          isNull,
        );
      });
    });

    group('Aider (H03)', () {
      test('direct interactive launch', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/local/bin/aider',
            argv: ['aider'],
          ),
          equals(HarnessKind.aider),
        );
      });

      test('via python -m module execution', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'python3',
            argv: ['python3', '-m', 'aider'],
          ),
          equals(HarnessKind.aider),
        );
      });

      test('via uvx runner', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'uvx',
            argv: ['uvx', 'aider-chat'],
          ),
          equals(HarnessKind.aider),
        );
      });

      test('rejects batch one-shot flags and admin commands', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'aider',
            argv: ['aider', '-m', 'fix code automatically'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'aider',
            argv: ['aider', '--no-git'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'aider',
            argv: ['aider', 'check-update'],
          ),
          isNull,
        );
      });
    });

    group('Ollama (H03)', () {
      test('interactive chat mode requires run <model>', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: '/usr/local/bin/ollama',
            argv: ['ollama', 'run', 'llama3'],
          ),
          equals(HarnessKind.ollama),
        );
      });

      test('rejects daemon, pull, list and bare invocation', () {
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'ollama',
            argv: ['ollama'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'ollama',
            argv: ['ollama', 'serve'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'ollama',
            argv: ['ollama', 'pull', 'mistral'],
          ),
          isNull,
        );
        expect(
          TerminalHarnessClassifier.classify(
            executable: 'ollama',
            argv: ['ollama', 'list'],
          ),
          isNull,
        );
      });
    });

    group('Evidence & Generic Contract (H03)', () {
      test('unrecognized CLIs adhere strictly to generic contract without invented parsers', () {
        final unknownCommands = [
          ['custom-llm-tool', 'chat'],
          ['gcc', 'main.c', '-o', 'main'],
          ['python', 'train.py'],
          ['docker', 'run', '-it', 'ubuntu'],
        ];

        for (final cmd in unknownCommands) {
          final result = TerminalHarnessClassifier.classify(
            executable: cmd[0],
            argv: cmd,
          );
          expect(result, isNull,
              reason: 'Comando ${cmd[0]} desconhecido não deve inventar harness.');
        }
      });
    });
  });
}
