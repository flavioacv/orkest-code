# Configurações de Execução e Testes no Orkest Code (R01)

> **Atividade:** `R01 · Integrar configurações de execução e testes`  
> **Status:** Concluído e Validado  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivo

No fluxo diário de desenvolvimento em uma IDE, rodar testes pontuais, scripts de build e aplicações com parâmetros específicos, variáveis de ambiente e diretório de trabalho controlados é uma necessidade primária.

A atividade **R01** estabeleceu o subsistema unificado de configurações de execução e testes no Orkest Code:
1. **Modelo de Configuração (`RunConfiguration`)**:
   - Representação tipada com suporte a kinds: `run`, `test`, `custom`;
   - Parâmetros explícitos: `program`, `cwd`, `args`, `env`, `sdkPath`, `isTest`;
   - Conversão direta e determinística para `TaskDefinition` (`toTaskDefinition()`), integrando-se nativamente com o `PtyTaskRunner` existente sem duplicar processos, terminais ou infraestrutura de PTY.
2. **Producers de Configuração Contextual (`RunConfigurationProducer`)**:
   - Dedução automática de comandos de execução e teste baseada no arquivo em foco:
     - Dart/Flutter: arquivos `*_test.dart` -> `flutter test <file>` / `dart test <file>`; scripts e entrypoints -> `dart run <file>` / `flutter run -t <file>`;
     - TypeScript/JavaScript: arquivos `*.test.ts`, `*.spec.ts` -> `npx vitest <file>` / `npm test`; arquivos executáveis -> `npx tsx <file>` / `node <file>`;
     - Python: arquivos `test_*.py` -> `pytest <file>`; scripts -> `python3 <file>`;
     - Rust: `tests/*.rs` -> `cargo test --test <name>`; binários -> `cargo run`.
3. **Importação e Suporte a `launch.json` (`LaunchJsonLoader`)**:
   - Carregamento de configurações existentes do VSCode (`.vscode/launch.json`) e Orkest (`.orkest/run.json`, `.orkest/launch.json`);
   - Parser tolerante a JSONC (comentários de linha/bloco e vírgulas finais);
   - Interpolação de variáveis de caminho (`${workspaceFolder}`, `${workspaceRoot}`);
   - Resolução de `cwd` relativo à raiz do workspace.
4. **Console Clicável e Navegação de Stack Traces (`ConsoleLinkMatcher`)**:
   - Parser de expressões regulares para detectar referências a arquivos, linhas e colunas na saída de console/terminal:
     - URIs `file:///path/to/file.ext:line[:col]`;
     - Caminhos padrão relativos/absolutos `path/to/file.ext:line[:col]`;
     - Formato do Dart test runner `test/foo_test.dart line:col`;
   - Retorno estruturado de `ConsoleLinkSpan` (`filePath`, `line`, `column`, `start`, `end`) permitindo navegação direta para o arquivo e linha correspondente no editor via `DocumentHost`.

---

## 2. Arquitetura e Componentes

### 2.1. `RunConfiguration` (`domain/entities/run_configuration.dart`)
Entidade de domínio pura desacoplada de UI/IO:
- Mapeia o tipo da stack (`flutter`, `dart`, `node`, `typescript`, `python`, `cargo`);
- O método `_resolveCommandAndArgs()` resolve o executável da CLI (`dart`, `flutter`, `node`, `npx`, `python3`, `cargo`) e seus argumentos canônicos;
- O método `toTaskDefinition()` encapsula as variáveis em um `TaskProfile`, configurando o `TaskKind.oneShot` para testes e `TaskKind.watch` para aplicações contínuas.

### 2.2. `RunConfigurationProducer` (`domain/services/run_configuration_producer.dart`)
Serviço contextual:
- Normaliza caminhos de forma segura com `path.normalize`;
- Reconhece projetos Flutter inspecionando dependências do `pubspec.yaml` (`sdk: flutter`);
- Gera tarefas sob demanda com nomes amigáveis para menus de contexto e atalhos.

### 2.3. `LaunchJsonLoader` (`data/tasks/launch_json_loader.dart`)
Loader com fallback de prioridades:
- Inspeciona `.orkest/run.json` -> `.orkest/launch.json` -> `.vscode/launch.json`;
- Utiliza `stripJsonc` para máxima robustez;
- Substitui variáveis dinâmicas e normaliza caminhos de execução.

### 2.4. `ConsoleLinkMatcher` (`core/terminal/console_link_matcher.dart`)
Detector de links de alta precisão:
- Suporte a múltiplos links em uma única linha ordenados por offset;
- Descarte de sobreposições (`_overlaps`);
- Suporte completo a SOs POSIX e Windows.

---

## 3. Validação Automatizada

- **Suíte de Testes de Execução e Launch:** `cockpit/test/tasks/run_configuration_test.dart`
  - 8 cenários aprovados cobrindo:
    1. Conversão de teste Dart para `TaskDefinition`;
    2. Conversão de execução Flutter para `TaskDefinition` com `-t`;
    3. Conversão de script TypeScript para `npx tsx`;
    4. Dedução de teste Dart em arquivos `*_test.dart`;
    5. Dedução de execução para scripts `.dart` normais;
    6. Detecção precisa de projeto Flutter;
    7. Dedução de testes TypeScript e Python;
    8. Carregamento completo de `.vscode/launch.json` com variáveis, comentários e envs.
- **Suíte de Testes de Console Clicável:** `cockpit/test/terminal/console_link_matcher_test.dart`
  - 5 cenários aprovados cobrindo:
    1. Localização de `file://` com linha e coluna;
    2. Localização de caminhos relativos compiladores/linters;
    3. Localização de formato do test runner do Dart;
    4. Múltiplos links na mesma linha com ordenação correta;
    5. Rejeição de linhas sem referências de arquivo.
- **Suíte de Regressão Completa:** 36 testes aprovados (`git_conflict_resolution_test.dart`, `git_hunk_staging_test.dart`, `tasks_json_loader_test.dart`, `rust_ide_host_spike_test.dart`).
- **Análise Estática Global:** `dart analyze --fatal-infos` em todo o pacote `cockpit` concluído com **zero issues** (`No issues found!`).
