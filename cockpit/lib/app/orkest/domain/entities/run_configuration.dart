import 'package:orkest_code/app/orkest/domain/entities/task_definition.dart';

/// Tipo da configuração de execução.
enum RunConfigurationKind {
  /// Execução normal de aplicação / script (ex.: `flutter run`, `dart run`, `node app.js`).
  run,

  /// Execução de testes automatizados (ex.: `flutter test`, `dart test`, `npm test`, `pytest`).
  test,

  /// Execução customizada de comando.
  custom,
}

/// Configuração de execução de aplicação, script ou suíte de testes.
///
/// Modela configurações importadas de `.vscode/launch.json`, `.orkest/run.json`
/// ou geradas dinamicamente via [RunConfigurationProducer] a partir do arquivo
/// atualmente aberto no editor.
///
/// Pode ser convertida diretamente para uma [TaskDefinition] executável pelo
/// [PtyTaskRunner] existente, preservando streaming PTY, interatividade de
/// teclas e ciclo de vida de processo.
class RunConfiguration {
  const RunConfiguration({
    required this.id,
    required this.name,
    required this.type,
    this.kind = RunConfigurationKind.run,
    required this.program,
    required this.cwd,
    this.args = const [],
    this.env = const {},
    this.sdkPath,
    this.isTest = false,
  });

  /// Identificador único estável da configuração.
  final String id;

  /// Nome amigável exibido na UI (ex.: "Run current file", "Test git_conflict_resolution_test.dart").
  final String name;

  /// Tipo de runtime/stack (ex.: "dart", "flutter", "node", "python", "cargo", "shell").
  final String type;

  /// Categoria da configuração.
  final RunConfigurationKind kind;

  /// Caminho relativo ou absoluto do arquivo ou alvo principal.
  final String program;

  /// Diretório de trabalho onde o processo será executado.
  final String cwd;

  /// Argumentos adicionais de linha de comando.
  final List<String> args;

  /// Variáveis de ambiente explícitas passadas para o processo.
  final Map<String, String> env;

  /// Caminho opcional do SDK a utilizar.
  final String? sdkPath;

  /// Indica se esta configuração executa testes automatizados.
  final bool isTest;

  /// Converte esta configuração em uma [TaskDefinition] executável pelo runner PTY.
  TaskDefinition toTaskDefinition() {
    final (command, baseArgs) = _resolveCommandAndArgs();

    return TaskDefinition(
      id: id,
      label: name,
      cwd: cwd,
      command: command,
      args: baseArgs,
      kind: isTest ? TaskKind.oneShot : TaskKind.watch,
      source: TaskSource.manual,
      profiles: env.isNotEmpty
          ? [
              TaskProfile(
                name: 'custom-env',
                args: const [],
                env: env,
              ),
            ]
          : const [],
    );
  }

  (String command, List<String> args) _resolveCommandAndArgs() {
    final cleanType = type.toLowerCase();

    switch (cleanType) {
      case 'flutter':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('flutter', ['test', if (program.isNotEmpty) program, ...args]);
        }
        return ('flutter', ['run', if (program.isNotEmpty) '-t', if (program.isNotEmpty) program, ...args]);

      case 'dart':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('dart', ['test', if (program.isNotEmpty) program, ...args]);
        }
        return ('dart', ['run', if (program.isNotEmpty) program, ...args]);

      case 'node':
      case 'pwa-node':
      case 'javascript':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('npm', ['test', '--', if (program.isNotEmpty) program, ...args]);
        }
        return ('node', [if (program.isNotEmpty) program, ...args]);

      case 'typescript':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('npx', ['vitest', 'run', if (program.isNotEmpty) program, ...args]);
        }
        return ('npx', ['tsx', if (program.isNotEmpty) program, ...args]);

      case 'python':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('pytest', [if (program.isNotEmpty) program, ...args]);
        }
        return ('python3', [if (program.isNotEmpty) program, ...args]);

      case 'cargo':
      case 'rust':
        if (isTest || kind == RunConfigurationKind.test) {
          return ('cargo', ['test', ...args]);
        }
        return ('cargo', ['run', ...args]);

      default:
        // Custom / shell
        return (program.isNotEmpty ? program : 'sh', [...args]);
    }
  }
}
