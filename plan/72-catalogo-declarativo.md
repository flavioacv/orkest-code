# Catálogo Declarativo de Linguagens (L01)

Data: 04/11/2026. Branch: `fix/harness-state-detection`.
Atividade Kanban: `L01 · Evoluir catálogo declarativo de linguagens`.

## 1. Objetivo e Escopo

Evoluir a arquitetura do catálogo de linguagens (`cockpit/lib/app/core/data/lsp/lsp_launchers.dart`), agregando a maturidade de separação conceitual presente na referência OpenIDEA (`languages/*.toml`) ao Orkest Code, sem quebrar nenhuma interface pública existente, preservando o pool de servidores, configurações de usuário (`app_settings.dart`) e document hosts.

## 2. Decisões Arquiteturais e Separação de Responsabilidades

1. **Separação Conceitual Limpa**:
   - **Detecção de Arquivo**: `extensions`, `filenames`, delimitadores de comentários (`lineComment`, `blockComment`).
   - **Estrutura de Projeto / Workspace**: marcadores de raiz (`markers`).
   - **Servidor LSP**: `LanguageServerConfig` encapsula identificador (`name`), comando (`executable`), argumentos padrão (`args`) e dica de instalação (`installHint`).
   - **Adaptador de Depuração (DAP)**: `DebugAdapterConfig` encapsula `adapterId`, `executable`, `args` e `installHint`, preparando o terreno para R01-R04 sem acoplar ou confundir LSP com Debug.
   - **SDK e Ambiente**: `SdkConfig` documenta formalmente o SDK (`name`, `installHint`, `documentationUrl`).
   - **Matriz de Capacidades**: `LanguageCapabilities` declara explicitamente o suporte da linguagem a `lsp`, `debug`, `formatting`, `hover`, `completion`, `signatureHelp` e `semanticTokens`.

2. **Tratamento de Comandos com Espaços**:
   - `LanguageDef.toSpec` foi enriquecido para suportar:
     - Argumento `commandLine`: divide comandos inteiros usando `splitLspCommand` seguro contra caminhos com espaços em aspas (`"/Custom Path/bin/server" --arg`).
     - Argumento `executable` contendo espaços e sem lista de argumentos explícita: tokeniza deterministicamente preservando argumentos subsequentes.
     - Preservação total de chamadas com `executable` e `args` explicitamente separados.

3. **Retrocompatibilidade e Desempenho**:
   - Getters `defaultExecutable` e `defaultArgs` mantidos delegando para a configuração do servidor.
   - Consulta rápida de linguagem por ID adicionada: `languageById(String id)`.
   - Consulta por arquivo existente mantida intacta: `languageForPath(String path)`.

## 3. Validação Reproduzível

- Análise estática limpa: `dart analyze --fatal-infos` (0 issues).
- Suíte completa de testes aprovada: **121 testes aprovados** cobrindo unidades de codec, completion, hover, signatureHelp, pool de servidores, editores, standalone document host, integração com servidor Dart real e testes do novo catálogo declarativo (`test/data/lsp_launchers_test.dart`).
