# OpenIDEA como referência para o Orkest Code

Análise estática em 04/11/2026. Origem: `/Volumes/Externo 1/projetos/zurc/openidea`, versão declarada 0.1.36, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. Destino examinado: `remote_pi/cockpit`, aplicativo `orkest_code`.

## Parecer

O OpenIDEA é uma referência concreta para ampliar Git, depuração e inteligência de código do Orkest. A separação dos domínios Rust permite estudar reaproveitamento do backend sem migrar o editor Flutter para React. A interface, porém, depende de React, Zustand, CodeMirror e serviços do workbench: seus componentes não são reutilizáveis diretamente como widgets Flutter.

O ponto mais promissor é o `openidea-server`: já existe um backend independente da janela Tauri, acessível por JSON-RPC sobre stdio. Recomendo uma prova de integração pequena com esse processo antes de decidir entre portar funcionalidades para Dart ou incorporar crates por FFI. Essa é uma proposta técnica, ainda não uma decisão aprovada.

“Implementação completa” precisa ser delimitada: foram encontrados backend, interface e testes para fluxos avançados; não foram executados builds, testes ou sessões reais. Recursos de debug dependem do adaptador, SDK e linguagem. A existência de um teste não comprova sua aprovação nesta máquina.

## Estrutura e pontos de extensão

| Camada | Local | Responsabilidade e interesse para integração |
|---|---|---|
| Domínios | `crates/ide-*` | Serviços Rust separados para VCS, DAP, LSP, busca, execução, arquivos e outras áreas |
| Tipos e eventos | `crates/ide-core` | Erros, identificadores, texto e eventos compartilhados |
| Host | `crates/ide-host` | Composição de serviços, projetos, operações e servidor independente |
| Tauri | `src-tauri/src/commands` | Adaptadores IPC por domínio; não é o local principal da lógica |
| Contratos TS | `src/bindings.ts`, `src/platform/ipc.ts` | Tipagem gerada por tauri-specta, chamadas, erros, eventos e canais |
| Plataforma | `src/platform` | Ações, atalhos, contexto, localização e projeto |
| Workbench | `src/workbench/contributions.ts` | Registros de painéis, editores, serviços e contribuições |
| Funcionalidades | `src/features`, `src/features/index.ts` | Ativação e descarte de cada módulo |
| Editor | `src/editor/core`, `src/editor/lsp`, `src/editor/refactor` | CodeMirror, documentos, LSP e refatorações |
| Linguagens | `languages/*.toml` | Detecção, comentários, indentação, servidores e adaptadores de debug |
| Extensões | `wit`, `sdk`, `plugins`, `crates/ide-plugin` | Contratos e execução de componentes WebAssembly |
| Qualidade | `e2e`, `smoke`, `fixtures`, `perf` | Testes de UI, projetos reais por linguagem e orçamentos de desempenho |

O guia `AGENTS.md` da origem especifica linhas base zero e colunas UTF-16, cancelamento por RequestId, streaming por canais e execução pesada fora da thread de UI. Esses contratos merecem ser preservados em uma ponte Dart; índices de bytes Rust e posições do editor não são intercambiáveis.

## Git: inventário aprofundado

Fontes principais: `crates/ide-vcs/src/lib.rs`, seus módulos internos, `src/features/vcs`, `src-tauri/src/commands/vcs.rs` e `crates/ide-host/src/ops/vcs`.

| Grupo | Recursos encontrados | Referências da origem | Aplicação no Orkest |
|---|---|---|---|
| Estado | Descoberta de repositório, branch/HEAD, staged/unstaged, operação em andamento, múltiplas raízes | `repo.rs`, `status.rs`, `roots.rs`; `multiRoot.ts` | Evoluir a base existente sem duplicar a identificação de repositórios |
| Staging e commit | Stage/unstage por arquivo, patches e hunks, descarte, commit parcial, amend, sign-off, opções e verificações antes do commit | `lib.rs`, `ops.rs`; `hunkInclusion.ts`, `commitChecks.tsx`, `CommitView.tsx` | Prioridade alta para revisão precisa do trabalho de agentes |
| Comparação | Diff por revisão e worktree, comparação de branches, arquivos e diretórios; navegação, opções e código movido | `compare.rs`, `diff.rs`; `DiffEditor.tsx`, `DirectoryCompare.tsx`, `movedCode.ts` | Ampliar o diff atual e adicionar revisão por trechos |
| Conflitos | Versões base/ours/theirs, editor de merge, marcadores e ações de resolução | `lib.rs`; `MergeEditor.tsx`, `mergeDiff3.ts`, `conflictMarkers.ts` | Prioridade alta: reduzir dependência do terminal na resolução |
| Histórico | Log filtrado, detalhes, arquivos por commit, refs, usuários, índice persistido, grafo e ordenação | `history.rs`, `log_index.rs`, `bek.rs`; `GitLog.tsx`, `graph.ts` | Evoluir o painel de histórico já existente |
| Autoria | Blame, blame inline, histórico de bloco/seleção | `blame.rs`, `block_history.rs`; `inlineBlame.ts`, `SelectionHistory.tsx` | Contexto para usuário e agente antes de alterar código |
| Branches | Criar, trocar, renomear, remover e restaurar branch removida; tratamento de divergências | `lib.rs`; `branchOps.ts`, `branches.ts` | Complementar o seletor e checkout existentes |
| Remotos | Fetch, pull, push, upstream, tags, remotes e saída cancelável | `remotes.rs`, `manage.rs`, `cli.rs`; `PushChanges.tsx`, `remoteUi.tsx` | Padronizar progresso, falhas e credenciais |
| Reescrita e recuperação | Merge, rebase, rebase interativo, cherry-pick, revert, reset, continuar/abortar/pular | `ops.rs`, `manage.rs`; `rebase.tsx`, `rebasePlan.ts`, `MergeRebaseWidget.tsx` | Segunda etapa, com pré-condições e recuperação explícitas |
| Trabalho temporário | Stash, aplicar/pop/drop, criar branch de stash; shelf e unshelve; changelists | `shelf.rs`, `changelists.rs`; `shelf.tsx`, `changelistsUi.tsx` | Isolar alterações e alternar tarefas |
| Patch e revisão | Criar, visualizar, importar e aplicar patches; navegador de revisões | `patch.rs`; `patches.tsx`, `RevisionBrowser.tsx` | Fluxo de revisão de alterações produzidas por agentes |
| Organização | Clone, init, tags e gestão de worktrees | `lib.rs`, `manage.rs` | Worktrees para tarefas isoladas do Orkest |
| Histórico local | Interface e ações próprias de histórico local, separadas do log Git | `LocalHistory.tsx`, `localHistoryActions.ts`, comandos `history.rs` | Recuperar edições não commitadas; verificar política de retenção antes de portar |

O backend combina `gix` com o executável Git. `cli.rs` declara que as operações mutáveis usam a CLI, inclui escolha de executável, askpass, observação de comandos e encerramento de processos. Portanto, incorporar `ide-vcs` não elimina a dependência de Git instalado nem resolve automaticamente a integração de credenciais no Orkest.

## Debug: inventário aprofundado

Fontes: `crates/ide-dap/src`, `src/features/debugger`, `src-tauri/src/commands/debug.rs` e definições de linguagens.

| Grupo | Recursos encontrados | Referências |
|---|---|---|
| Sessões | Launch, attach, sessões filhas, encerramento por projeto, transporte stdio/TCP, conexão com adaptador existente | `lib.rs`, `session.rs`, `connection.rs`, `adapter.rs`, `attach.rs` |
| Controle | Resume, pause, step into/over/out, run to cursor, force step over, seleção do alvo de step, reset de frame | `lib.rs`; `editor/runToCursor.ts`, `editor/smartStep.ts` |
| Breakpoints | Linha, condições/modelos persistidos, exceções, funções e data breakpoints conforme capacidades | `breakpoints/*`; `lib.rs` |
| Inspeção | Threads, stack frames, scopes, árvore de variáveis, avaliação de expressões, completions e acompanhamento visual de valores | `frames.ts`, `values.ts`, `ui/VariablesView.tsx`, `ui/ExpressionCompletion.tsx` |
| Editor e console | Linha atual, gutter de breakpoints, avaliação rápida, tooltip de valor, console de debug e histórico de expressões | `editor/*`, `ui/DebugConsole.tsx`, `ui/expressionHistory.ts` |
| Ecossistemas | Resolução declarativa de adaptadores, integração Java/JDT, Kotlin/JDWP, Cargo, HotSwap de classes Java | `adapter.rs`, `java.ts`, `jdwp.rs`, `kotlin*.rs`, `cargo.rs`, `hotswap.ts` |
| Remoto e execução | Integração com run configurations e caminho remoto | `launch.ts`, `remote.ts`, `src/features/run` |

Funções como Smart Step Into, reset de frame, watchpoints e HotSwap verificam suporte do adaptador. A UI do Orkest deve habilitar ações por capacidades, em vez de prometer a mesma experiência para toda linguagem.

`languages/dart.toml` define `dart language-server --protocol=lsp` e `dart debug_adapter`; a dica de instalação menciona `flutter debug_adapter` para Flutter. Isso evidencia um ponto de partida DAP para Dart, mas não demonstra um fluxo Flutter completo. A busca estática por `hotReload` e `hotRestart` não encontrou implementação explícita no código consultado. Validar reload/restart, attach, devices, testes e paths de source é obrigatório antes de considerar paridade com ferramentas Flutter.

## Outros domínios relevantes

O quadro abaixo inventaria módulos registrados e diretórios existentes. Eles tiveram inspeção de estrutura; não receberam a mesma profundidade de Git e DAP.

| Domínio | Funcionalidades candidatas | Fontes |
|---|---|---|
| Inteligência | Completion, hover, diagnósticos, navegação, referências/usages, hierarquia, rename, workspace edits, ações, inlays e semantic tokens | `src/editor/lsp`, `src/features/code-insight`, `crates/ide-lsp` |
| Refatoração | Introduzir elementos, safe delete, ocorrências, menus de refatoração e integração com servidor | `src/editor/refactor` |
| Busca | Search Everywhere, texto, escopos, máscaras, resultados no editor, bookmarks e estrutura | `src/features/search`, `crates/ide-search`, `ide-index` |
| Edição | Múltiplas abas, sessões, histórico de navegação, folding, seleção, clipboard, Vim, templates, snippets, Emmet e postfix | `src/editor/core`, `src/features/vim`, `templates` |
| Execução | Configurações, detecção de execução, console, árvore de testes e serviços | `src/features/run`, `run-anything`, `services`, `crates/ide-run` |
| Build | Ferramentas de build, dependências, SDKs, bibliotecas e análise de dependências | `src/features/build*`, `dependencies`, `libraries`, `crates/ide-build`, `ide-sdk`, `ide-tools` |
| Qualidade | Coverage, profiling, análise, TODO e painel de problemas | `src/features/coverage`, `profiler`, `analysis`, `todo` |
| GitHub | Módulo próprio, criação e timeline; backend e comandos dedicados | `src/features/github`, `crates/ide-github`, `commands/github.rs` |
| Desenvolvimento remoto | Servidor, conexão SSH, mapeamento de caminhos, deployment e comparação com arquivos remotos | `ide-host`, `ide-remote`, `ide-ssh`, `src/features/remote-dev`, `deployment` |
| Ferramentas | Terminal PTY, HTTP client, GraphQL, banco e Docker | `ide-terminal`, `ide-http`, `ide-db`, `ide-docker`; features correspondentes |
| Documentos | Notebooks/Jupyter, Markdown/Mermaid, visualizadores, scratch files e ferramentas web | `ide-notebook`, `src/features/notebook`, `viewers`, `scratch`, `web` |
| Extensibilidade | Ações, atalhos contextuais, painéis, editores customizados, temas, ícones e linguagens por plugins | `contributions.ts`, `src/platform`, `wit`, `sdk`, `ide-plugin` |
| Agentes | Feature e backend dedicados a agentes | `src/features/agents`, `crates/ide-agent`; avaliar separadamente frente à orquestração existente |
| Robustez | Confiança de projeto, cancelamento, sincronização de documentos, trabalho em background e medição de desempenho | `project-trust`, `ide-host/src/trust.rs`, `src/editor/core/sync`, `perf` |

## Comparação com a base atual do Orkest

Confirmados no destino: contratos e implementações de leitura de status/diff/HEAD/histórico, execução de Git, branches, troca e criação de branch, pull/push/sync, atualização por eventos/polling e adaptação remota. O painel de histórico expõe callbacks para revert e desfazer último commit. Fontes: `cockpit/lib/app/orkest/ui/viewmodels/git_controller.dart`, `ui/widgets/git_history_panel.dart`, `data/filesystem/git_*`, `data/remote/remote_git_adapter.dart` e contratos de domínio.

O Orkest também tem cliente, pool, launchers, diagnósticos, posições e semantic tokens de LSP em `cockpit/lib/app/core`, além de `code_editor.dart`. Logo, Git e LSP não devem ser tratados como funcionalidades ausentes. A comparação funcional detalhada de completion/refatoração exige rastrear as chamadas do editor, pois um cliente LSP genérico não comprova exposição de todos os métodos na UI.

A busca por caminhos relacionados a debug encontrou ingestão de VM Service e um inspector de DevTools, mas não uma camada geral de sessões DAP/breakpoints. Isso indica uma lacuna provável; não é prova de ausência de toda forma de depuração. Não se deve confundir telemetria de VM com debugger interativo.

## Estratégia de integração proposta

1. **Prova com processo separado:** iniciar `openidea-server --stdio` pelo Orkest, negociar versão, abrir projeto e exercitar uma leitura VCS. Depois testar uma sessão DAP simples. Preservar a UI Flutter e os serviços existentes durante a avaliação.
2. **Git de maior retorno:** diff por trechos e staging parcial, comparação de revisões, editor de conflitos e histórico com grafo/filtros. Adicionar ao fluxo de revisão dos agentes.
3. **Debug mínimo utilizável:** configuração de launch/attach, breakpoint, pause/resume/step, stack, variáveis e console; começar por Dart e validar Flutter separadamente.
4. **Git e debug avançados:** worktrees, stash/shelf, rebase interativo, histórico de seleção, watchpoints e recursos específicos de linguagem conforme demanda.
5. **Complementos:** expandir LSP, busca e execução/testes. Reaproveitar ferramentas de banco, terminal, HTTP e agentes somente onde houver lacuna comprovada no Orkest.

O servidor existente usa JSON-RPC 2.0 com framing `Content-Length`, handshake `initialize`, chamadas `invoke {window, cmd, args}`, eventos e canais; o protocolo observado é versão 2. Fontes: `crates/ide-host/src/rpc.rs` e `src/bin/server.rs`. É infraestrutura útil, mas ainda vinculada aos contratos internos do OpenIDEA, não um SDK Dart estável. Verificar cobertura dos comandos, prompts de confiança, credenciais, eventos de debug e encerramento antes de adotar.

| Opção | Benefício | Custo / limite |
|---|---|---|
| Processo Rust via RPC | Usa separação já existente, isola falhas e favorece execução remota | Distribuir binário, supervisionar processo e adaptar protocolo/tipos/eventos |
| Crates por FFI | Reaproveita domínio sem processo adicional | Criar ABI C estável, gerenciar memória, async, cancelamento e empacotamento |
| Portar para Dart | Usa contratos e arquitetura atuais do Orkest | Reimplementar comportamentos e transportar casos de teste; maior divergência upstream |
| Interface React em WebView | Possível reutilização localizada de uma ferramenta | Integração de foco, atalhos, tema, acessibilidade e dependências do workbench; não é cópia direta |

## Critérios de validação

- Git: hunk parcial preserva alterações não selecionadas; conflitos não perdem conteúdo; cancelamento não deixa filhos/locks; worktrees e múltiplos repositórios permanecem isolados.
- DAP: lifecycle completo, breakpoint pendente/verificado, threads, valores expansíveis, erro/saída do adaptador, reinício da sessão e limpeza ao fechar projeto.
- Dart/Flutter: posições com Unicode, execução de testes, launch/attach, mapeamento de arquivos, reload/restart quando disponível e diferenças entre targets.
- Ponte: versão incompatível falha claramente, eventos são direcionados ao projeto correto, requests podem ser cancelados e credenciais não aparecem nos logs.
- Desempenho: medir startup, memória, latência e repositórios grandes no Orkest; os benchmarks do README da origem não são medições do destino.

## Proveniência, limites e entrega

O projeto declara Apache-2.0 e mantém `LICENSE`, `NOTICE` e `THIRD_PARTY_LICENSES.md`, inclusive proveniência de ícones JetBrains e componentes adicionais. Antes de redistribuir código/assets, inventariar especificamente o material incorporado e preservar seus avisos. Este relatório registra os arquivos encontrados, sem emitir conclusão jurídica.

Há testes unitários de VCS/debug, E2E (`e2e/debug.spec.ts`, entre outros), fixtures e smoke tests. Não foram executados nem foram instaladas dependências. Não houve alteração no código dos projetos, criação de branch, commit, push ou integração de funcionalidades. O resultado é um mapa técnico estático para orientar a escolha e a futura especificação de implementação.
