# Plano 72 — Evolução do Orkest Code para uma IDE completa

Data: 04/11/2026. Estado: execução autorizada pelo usuário após elaboração do plano; arquitetura híbrida recomendada, sujeita às provas e decisões listadas. Agregar funcionalidades preservando a base atual é a prioridade. Ajustes visuais e otimizações motivadas apenas por desempenho ficam para avaliação futura quando houver necessidade identificada.

## Diretriz vigente de Git desta versão

Por instrução explícita de Flavio nesta conversa, todas as atividades desta versão devem continuar na mesma branch `fix/harness-state-detection`, com commits incrementais locais. Não criar novas branches por atividade, não fazer push e não abrir PR sem novo pedido explícito. As PRs #12 e #13 foram fechadas sem merge. As alterações já foram concentradas na primeira branch por fast-forward, preservando os commits existentes. Referências anteriores a branches separadas/PRs descrevem o histórico e não autorizam repetir esse fluxo.

## Contexto e direção

Preservar o modelo de workspace do Orkest centrado em buscar, abrir e alternar projetos, incluindo hosts remotos. Evoluir a profundidade do trabalho humano no código: compreender, editar, refatorar, executar, depurar e revisar alterações no mesmo projeto, com terminais e agentes integrados.

OpenIDEA de referência: `/Volumes/Externo 1/projetos/zurc/openidea`, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. Inventário estático: 40 diretórios de features, 35 crates, 77 definições de linguagem e 510 comandos Tauri explícitos em 41 domínios. Não equivale a homologação runtime, 77 linguagens com paridade ou exposição integral pelo servidor remoto.

Fontes locais: [análise inicial](../ANALISE_OPENIDEA_ORKEST.md), [catálogo técnico](../OPENIDEA_CATALOGO_TECNICO.md), [mapa funcional](../OPENIDEA_MAPA_FUNCIONAL_E_ARQUITETURA.md), [harness e bancos](../OPENIDEA_HARNESS_E_BANCOS.md), [inventário estruturado](../OPENIDEA_INVENTARIO.json). O catálogo fornece arquivos/linhas dos comandos; a tabela de cobertura abaixo liga todos os domínios a atividades deste plano.

## Estrutura atual e fronteiras

```text
cockpit/lib/app/core/data/lsp/          cliente, pool e launchers LSP Dart
cockpit/lib/app/orkest/
  domain/                             contratos de arquivos, Git, busca, bancos e tasks
  data/filesystem/                    Git CLI e busca; busca de conteúdo em isolate
  data/hooks/                         produtores e transporte de status
  ui/session/terminal_session.dart    estados de harness por terminal
  ui/widgets/                         editor Flutter, árvore, projetos, Git, banco, Office
cockpit/packages/
  orkest_protocol/                    contratos de transporte existentes
  orkest_engine/                      serviços de FS, Git, DB e PTY
  orkest_server/                      composição e serviços no host
cockpit/cli/                          CLI Rust existente
cockpit/tool/office_world/            integração/simulação TypeScript do Office
cockpit/third_party/office_engine/    engine visual vendorizada
```

O Orkest já tem Git, busca, tarefas, cliente LSP, editor, banco/HTTP, terminal, SSH e componentes de diagnóstico. O catálogo LSP declara Dart, TypeScript, JavaScript, Python, Go, Rust, PHP, C# e Java. Declaração não prova suporte completo na UI. O editor examinado expõe navegação de definição e hover de diagnósticos; completion/rename/hierarquias exigem auditoria de uso para estabelecer paridade.

Drivers SQL atuais passam por anaki Rust/FFI e isolates. O contrato DbDriver é efêmero por operação; transações manuais precisam de sessão dedicada ou mudança de contrato, não apenas de um botão Commit. Redis/Mongo seguem caminhos próprios e devem ser preservados.

O caminho de agentes permanece terminal-first, conforme decisões do repositório. ACP/app-server/stream-json da origem são referências para correlação, capacidades e testes, não autorização para reintroduzir composer/aba de agente RPC. Novos transportes de controle exigem RFC própria se alterarem essa direção.

## Arquitetura proposta por domínio

| Área | Direção inicial | Condição para mudar |
|---|---|---|
| Workspace, UI, ações, editor e integração de harness | Manter Flutter/Dart | Evidência de limitação concreta e decisão explícita |
| LSP | Ampliar cliente/pool existente | Substituir somente diante de lacuna comprovada; evitar dois clientes alterando documento |
| Git atual | Preservar contratos e Git CLI | Reaproveitar ide-vcs onde simplificar recursos avançados e passar testes |
| Debug | Provar ide-dap em serviço Rust e comparar com cliente Dart | Escolher após cobertura funcional, empacotamento e medições |
| Busca/indexação | Comparar Dart isolate com Rust | Troca atrás do contrato somente se ganho total justificar manutenção |
| Banco | Manter anaki e políticas atuais | Extensões por capability; mudança de sessão para transação exige ADR |
| Protocolos e host | Evolução compatível dos serviços atuais | Não substituir orkest-server inteiro pelo OpenIDEA sem avaliação |
| Algoritmos TS da origem | Portar seletivamente ou preservar conceito/testes | Comprovar equivalência e custo de integração; React não vira Rust/Flutter automaticamente |
| TypeScript do Office atual | Preservar renderer e comportamento | Somente hotspot puro medido pode gerar proposta de migração separada |

A alternativa Rust inicial é um processo supervisionado com contrato versionado. O `openidea-server --stdio` é útil para prova, mas não deve ser presumido como binário final nem como interface estável do produto. Auditar dispatcher, callbacks, credenciais, confiança e comandos ausentes. Comparar extração de serviços mínimos; FFI exige ABI, memória/ownership e callbacks assíncronos próprios.

Suporte a linguagens de projeto é independente da linguagem de implementação do editor: migrar um algoritmo TS para Rust não remove edição/debug de projetos TypeScript nem substitui Dart/Flutter na UI.

## Mapa específico de migração

| Candidato | Origem | Dependências/riscos | Destino e decisão |
|---|---|---|---|
| Diff por linha/palavra/caractere e otimização | OpenIDEA src/features/vcs/comparison | Semântica de offsets, Unicode, CRLF, hunks e testes de equivalência | M01 avalia core Rust puro; G01 consome saída tipada em Flutter |
| Merge de três vias e navegação de conflito | mergeDiff3.ts, mergeModel.ts, MergeEditor.tsx | Separar algoritmo da UI CodeMirror/React; não perder edições | M01/G02; core candidato Rust, UI Dart |
| Histórico/grafo/indexação Git | graph.ts, logStore e ide-vcs/log_index | Parte já Rust; paginação, ordenação, invalidação e multi-root | G03; evitar portar duas vezes o que já está no backend |
| Busca e índice | ide-search/index/vfs versus content_searcher_impl.dart | Exclusões, symlinks, incrementalidade, cancelamento e custo de IPC | M02; manter contrato Dart e decidir implementação |
| DAP | ide-dap e debugger TS | UI/estado de sessão e adaptadores externos; dependências core/language/jsonrpc | A03/R02; Rust reaproveitável, UI Flutter nova/adaptada |
| Harness | ide-agent normalizers/timeline/replay | Protocolo controlado difere de observação TUI; sessões e versões | H01-H05: aplicar princípios ao motor Dart sem trocar interação |
| Simulação Office | tool/office_world e third_party | Render browser, estado visual e ponte; migração pode custar mais que ganho | M03 mede separado; nenhum rewrite aprovado |
| Workbench React e CodeMirror | src/workbench, editor e components | DOM, foco, atalhos, acessibilidade e APIs de editor | Adaptar conceitos em Dart; não prometer port mecânico para Rust |

## Como medir e decidir desempenho

Primeiro fixar corpus, hardware, versões e baseline. Comparar 20 execuções warm por cenário após aquecimento e ao menos 5 cold, registrando mediana/p95, dispersão e parâmetros de cache. Repetir em sistemas/arquiteturas alvo disponíveis; ambientes ausentes ficam explicitamente pendentes. Não usar os números do README OpenIDEA como evidência sobre Orkest.

Cenários: abertura/troca/restauração de projeto; pesquisa em 1 mil e 100 mil arquivos quando houver corpus; diff pequeno/grande/adverso; grafo de histórico; LSP sob digitação; DAP com variáveis extensas; terminal com alto volume; múltiplos harnesses; Office visível/oculto; SSH com latência controlada. Medir processo inteiro, inclusive subprocessos, serialização e IPC, não só microbenchmark Rust.

Critérios propostos para a decisão A04: paridade de resultados obrigatória e nenhuma perda de documentos; ganho de pelo menos 20% no p95 do cenário que motivou a migração, sem regressão superior a 10% em RSS/CPU/latência dos demais cenários relevantes, ou justificativa funcional documentada. São limites iniciais de avaliação, não resultados obtidos; calibrar com baseline antes de aprovar. Se o ganho não justificar custo total e distribuição, manter Dart/TS é resultado aceitável.

## Multilinguagem por entrega

| Faixa | Linguagens | Critério |
|---|---|---|
| Primeira | Dart/Flutter e TS/JS | Editor/LSP/navegação/refatoração/teste/debug em fixtures reais; Flutter reload/restart validado separadamente |
| Segunda | Python, Rust e Go | Homologar servidores/adaptadores instalados e lifecycle local/remoto |
| Terceira | Java, C# e PHP | SDKs e projetos de referência; recursos JVM/.NET somente quando comprovados |
| Expansão | Vue, Svelte, HTML/CSS, JSON/YAML/SQL e demais catálogo | Priorizar demanda e registrar nível: highlight, LSP, execução, teste, debug; sem promessa de 77 linguagens completas |

Cada linha deve informar versão do SDK, servidor e adaptador, capacidades negociadas, origem/instalação, teste executado e limitações. Ausência de SDK ou autenticação precisa aparecer como indisponibilidade, não erro genérico. Novos pacotes/ferramentas externas dependem de justificativa e consentimento conforme regras do projeto.

## Ondas, prioridades e caminho de entrega

- Onda 0: F01/F02/A01 e revisão H00. Fotografar base e estabelecer contratos; A02 quando houver necessidade de desempenho identificada.
- Onda 1: A03/A04, W01/W03, L01-L04, H01-H03, M01/M02. Decidir recorte de Rust e tornar edição/reconhecimento mais profundos.
- Onda 2: A05, L05, H04, G01/G02 e R01-R03. Completar jornada editar -> testar/debug -> revisar.
- Onda 3: histórico/gestão Git/PR, debug adicional, bancos, qualidade e produtividade.
- Onda 4: funcionalidades condicionais P3 e rollout Q01 das ondas selecionadas.

P0 = habilitador/risco central; P1 = núcleo de IDE; P2 = aprofundamento; P3 = condicionado à demanda. Porte S/M/L indica complexidade relativa, não dias nem prazo. Cada L deve ser dividido em PRs funcionais no refinamento. Não há cronograma fechado ou estimativa de equipe validada.

Manter no máximo duas atividades em implementação e uma em revisão. Uma atividade só entra em Prontas quando dependências e critérios de teste estiverem definidos; Bloqueadas não é usado para representar um item que apenas aguarda sua ordem no backlog. O quadro registra dependências nativas por IDs.

H00 está Em revisão porque o commit da correção de harness já foi publicado, mas build/validação integrada ainda estão pendentes; as PRs #12 e #13 foram encerradas sem merge conforme a nova diretriz de branch única. DOC está Concluídas por ser o planejamento desta entrega; isso não marca implementações futuras como entregues.

### Ajuste de execução autorizado

F01/F02 foram documentadas em [auditoria e recorte](72-auditoria-paridade.md), com [manifesto de referência](72-openidea-proveniencia.json). L00 é a primeira entrega de código: oito perfis adicionais no catálogo LSP e reconhecimento por nomes de arquivo, preservando os nove perfis anteriores. L01 continua aberta para capacidades/SDK/adaptadores e homologação. A02/M01/M02/M03 são condicionais à necessidade: medições de migração não bloqueiam recursos implementáveis sobre a infraestrutura Dart existente. A03 depende de contratos e proveniência; só exige estudo de performance quando esse for o motivo de sua adoção.

## Atividades e critérios de aceite

### F01 — Auditar paridade funcional e preservar o workspace

Prioridade P0 · Porte M · Dependências: nenhuma.

Referência: OpenIDEA src/features; inventário local.
Destino: projects_rail, workspace_actions, JSON project/layout stores.

Aceite: Matriz por recurso com existente/parcial/ausente/não validado; cenários de buscar projeto, abrir, alternar, restaurar e conectar remoto registrados sem trocar o modelo atual.

### F02 — Fixar proveniência e recorte de código reutilizável

Prioridade P0 · Porte S · Dependências: nenhuma.

Referência: LICENSE, NOTICE, THIRD_PARTY_LICENSES; Cargo manifests.
Destino: Documentação de origem e avisos dos componentes escolhidos.

Aceite: Manifesto por arquivo/crate/asset com commit, licença, alterações e dependências; nenhum material sem proveniência entra na distribuição.

### A01 — Especificar contratos de serviços e capacidades

Prioridade P0 · Porte M · Dependências: F01.

Referência: ide-core; ide-host/src/rpc.rs; commands.
Destino: orkest_protocol, orkest_engine, orkest_server.

Aceite: Definir ownership de projeto/sessão/documento, UTF-16, erros, versão, cancelamento, streaming, backpressure e capacidades; mapear comandos locais/remotos e evitar dois donos do mesmo documento.

Incremento concluído: especificação formal de contratos de serviços, ownership (Single Writer Rule), UTF-16, EOL CRLF/LF, erros tipados, cancelamento cooperativo com RpcCancel, negociação declarativa de capacidades (caps em Hello/HelloAck) e mapeamento dos 41 domínios OpenIDEA em [contratos de serviços e capacidades](72-contratos-servicos-capacidades.md); 17 testes de orkest_protocol e 40 testes de orkest_server aprovados; análise estática limpa.

### A02 — Medir baseline Dart, TypeScript e pontes

Prioridade P0 · Porte M · Dependências: F01.

Referência: OpenIDEA perf; comparação TS; Office snapshots.
Destino: Diagnósticos e telemetria existentes do Orkest.

Aceite: Registrar hardware, versões, corpus pequeno/grande, cold/warm, p50/p95, RSS, CPU idle, jank, cancelamento, bytes IPC e remoto; nenhum ganho de Rust presumido.

### A03 — Provar reaproveitamento Rust para VCS e DAP

Prioridade P0 · Porte L · Dependências: A01, F02.

Referência: ide-host/bin/server.rs, rpc.rs; ide-vcs; ide-dap.
Destino: Protótipo isolado de cliente Dart, sem substituir serviços de produção.

Aceite: Handshake, abertura de projeto, status/diff, cancelamento e sessão DAP funcionam; inventário de comandos realmente expostos e dependências do host registrado; avaliar host reduzido e isolamento de falhas.
Entrega: Protótipo de cliente Dart implementado em `cockpit/test/spike/` (`rust_ide_host_client.dart`, `rust_ide_host_protocol.dart`, `mock_rust_ide_host_server.dart`); 7 testes aprovados em `cockpit/test/spike/rust_ide_host_spike_test.dart` cobrindo handshake com protocol 2, open/close project, vcs_status/roots/cancel_request, ciclo de vida DAP completo (launch, breakpoints, threads, stack trace, variables, evaluate, step, stop), streaming de progresso via canais, eventos assíncronos, isolamento total de crashes com `RustRpcException` e benchmark de latência IPC (p50 ~0.25ms, p95 ~0.89ms); documentado em `plan/72-prova-reaproveitamento-rust-vcs-dap.md`. Concluído em 05/11/2026.

### A04 — Decidir arquitetura por domínio com resultados medidos

Prioridade P0 · Porte S · Dependências: A03.

Referência: Medições A02/A03 e contratos A01.
Destino: ADR Dart, processo Rust ou FFI por domínio.

Aceite: ADR compara custo total, paridade, distribuição e manutenção; decide por componente e mantém fallback; FFI somente se justificada; preserva Flutter e suporte a projetos Dart.
Entrega: ADR formalizado em `plan/72-decisao-arquitetura-por-dominio.md`. Decisão por Dart nativo via CLI Git do sistema (`GitController`) para ciclo de vida VCS e algoritmo em Dart puro para hunks/patches (G01); cliente DAP Dart puro sobre stdio para depuração sem processo intermediário; manutenção do StdioLspClient em Dart; FFI terminantemente rejeitada para VCS, DAP e Editor; Isolate Dart + ripgrep para busca textual. Desbloqueia formalmente G01, R02 e A05. Concluído em 05/11/2026.

### A05 — Empacotar e supervisionar serviços nativos selecionados

Prioridade P1 · Porte L · Dependências: A04.

Referência: ide-core/process; host; crates selecionadas.
Destino: Build/release desktop e transporte remoto existentes.

Aceite: Bins/bibliotecas por OS/arch, encerramento de filhos, handshake incompatível, reinício, logs sem segredos, atualização/rollback e ausência de ferramentas externas testados.

Entrega: Implementação do subsistema de resolução, empacotamento e supervisão de serviços nativos auxiliares (`NativeBinaryResolver`, `NativeServiceSupervisor` e `LogSanitizer`). O `NativeBinaryResolver` (`cockpit/lib/app/orkest/domain/services/native_binary_resolver.dart`) detecta deterministicamente a plataforma e arquitetura em runtime (`macos-arm64`, `macos-x64`, `linux-arm64`, `linux-x64`, `windows-arm64`, `windows-x64` com sufixo `.exe`) e implementa resolução em cascata (binários embutidos no bundle -> pasta de desenvolvimento `.orkest/bin/` -> PATH do sistema), lançando `NativeBinaryNotFoundException` na ausência de binários. O `NativeServiceSupervisor` (`cockpit/lib/app/orkest/domain/services/native_service_supervisor.dart`) gerencia o ciclo de vida completo do processo filho (`unstarted`, `starting`, `running`, `stopping`, `stopped`, `degraded`), assegura encerramento forçado de processos filhos no encerramento (SIGTERM seguido de SIGKILL via `killTimeout` e `dispose`), executa verificação de compatibilidade de versão no handshake (`IncompatibleProtocolException`), previne loops infinitos de crash ("crash loops") com monitoramento de taxa na janela temporal e auto-restart controlado, e permite reversão/rollback imediato para binário anterior (`fallbackBinaryPath`). O `LogSanitizer` (`cockpit/lib/app/orkest/domain/services/log_sanitizer.dart`) sanitiza em tempo real saídas stdout/stderr de subprocessos, mascarando tokens Bearer, senhas de CLI, senhas em JSON, blocos PEM de chave privada e credenciais embutidas em URLs.
Validação: 15 testes unitários dedicados aprovados em `cockpit/test/domain/log_sanitizer_test.dart`, `cockpit/test/domain/native_binary_resolver_test.dart` e `cockpit/test/domain/native_service_supervisor_test.dart`; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-empacotamento-supervisao-servicos-nativos.md`.

### W01 — Garantir workspace por projetos com ferramentas IDE

Prioridade P0 · Porte M · Dependências: F01.

Referência: Workbench/contributions como referência de integração.
Destino: projects_rail, workspace_actions, file_viewer_session, document host.

Aceite: Projeto continua entrada principal; editor, terminal, Git, problemas e debug seguem a raiz/host corretos; trocar projeto não mistura estado; restauração preserva layouts e arquivos abertos.

Incremento concluído: garantia de isolamento de estado e contexto de ferramentas por projeto documentados em [workspace por projetos com ferramentas IDE](72-workspace-projetos-ferramentas-ide.md); roteamento canônico de raiz via Project.effectiveRoot, associação de sessões ao projectId, preservação do ciclo de workspaces e suite de testes de isolamento validada; 4 testes unitários e análise estática limpos.

### W02 — Unificar ações, atalhos e navegação do desenvolvedor

Prioridade P1 · Porte M · Dependências: W01.

Referência: src/platform actions/keymaps; contributions.
Destino: Sistema de ações e menu existente do Orkest.

Aceite: Paleta busca ações e símbolos sem substituir busca de projetos; foco/contexto/atalhos, acessibilidade e i18n coerentes; ação indisponível explica capacidade faltante.

Incremento concluído: Command Palette unificada (showCommandPalette) via atalhos globais ⇧⌘P / Shift+Ctrl+P / F1 e menu nativo; integração fluida com quick-open de arquivos (Cmd+P) via prefixo '>'; modelo desacoplado AppCommandItem e AppCommandRegistry com categorização (File, Edit, View, Terminal, Preferences), suporte a busca multi-palavras, atalhos visuais e exibição de justificativa contextual (disabledReason) para ações desabilitadas sem quebrar o modelo project-first em [paleta de ações e navegação](72-paleta-acoes-navegacao.md); 3 testes aprovados e análise estática limpa.

### W03 — Fortalecer edição, documentos e sincronização

Prioridade P0 · Porte L · Dependências: W01.

Referência: src/editor/core/sync e model.
Destino: code_editor, file_viewer_session, document host.

Aceite: Undo/redo, dirty buffers, mudanças externas, fechamento, arquivos grandes, Unicode/CRLF e multi-janela verificados; nenhuma perda silenciosa de edições.

Incremento concluído: modelo de sincronização e dirty buffers fortalecido com Single Writer Rule; detecção e preservação de CRLF original no salvamento; detecção de conflitos de concorrência com arquivo alterado no disco (`hasDiskConflict`), banner de aviso no editor com opções de manter edições locais ou recarregar do disco; suporte a descarte limpo de buffer; proteção contra perda de dados no fechamento atômico de abas; proteção contra arquivos grandes (> 2MB) retornando FileViewUnsupported com integridade garantida em [edição, documentos e sincronização](72-edicao-documentos-sincronizacao.md); 5 testes aprovados e análise estática limpa.

### L01 — Evoluir catálogo declarativo de linguagens

Prioridade P1 · Porte M · Dependências: F01.

Referência: languages/*.toml; ide-language.
Destino: core/data/lsp/lsp_launchers e configuração Language.

Aceite: Detecção/markers/servidores/args/adaptadores/SDK e capacidades separados; comandos com paths contendo espaços; configurações do usuário preservadas; não confundir highlight, LSP e debug.

Incremento concluído: separação declarativa de LanguageServerConfig, DebugAdapterConfig, SdkConfig e LanguageCapabilities em [catálogo declarativo](72-catalogo-declarativo.md); suporte a caminhos com espaços em toSpec via splitLspCommand; 121 testes aprovados e análise estática limpa.


### L02 — Completar assistência LSP no editor

Prioridade P1 · Porte L · Dependências: W03, L01.

Referência: src/editor/lsp; commands/lsp.rs.
Destino: Cliente/pool LSP existente, code_editor e controllers.

Aceite: Completion, resolve, hover semântico e signature help funcionam em Dart e TS; requests cancelados e respostas antigas não alteram documento/versão errados.

Entrega: Consolidação integral de inteligência LSP com hover semântico (L02a), signature help com parâmetros ativos e overloads (L02b), autocomplete com resolve (L02c), cancelamento assíncrono $/cancelRequest por documento/versão (L02d), cancelamento pela UI/resolve (L02e), serviço de expansão de snippets TextMate `LspSnippetService` (`cockpit/lib/app/core/domain/services/lsp_snippet_service.dart`) com suporte a tabstops `$0`/`$1`, placeholders `${1:name}` e cálculo de caretOffset, e homologação completa de TypeScript (`cockpit/test/integration/lsp_typescript_homologation_test.dart`) cobrindo `typescript-language-server`, detecção de projeto via `tsconfig.json`/`package.json`, auto-imports ESM via `additionalTextEdits`, overloads de métodos e descarte seguro de respostas obsoletas após edições concorrentes de versão.
Validação: 14 testes dedicados de TypeScript e Snippets em `cockpit/test/integration/lsp_typescript_homologation_test.dart` e `cockpit/test/data/lsp_snippet_parser_test.dart`; 92 testes de toda a suíte de LSP aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-assistencia-lsp-editor.md`.

### L03 — Adicionar navegação semântica e busca unificada

Prioridade P1 · Porte M · Dependências: L02, W02.

Referência: code-insight; search; nav.
Destino: Painéis de resultados e navegação existentes.

Aceite: Definição/implementação/referências/símbolos e histórico abrem posição UTF-16 correta; resultados paginados, exclusões, cancelamento e raízes locais/remotas respeitados.

Entrega: Implementação da navegação semântica completa e busca unificada de símbolos: decodificação universal de localizações LSP (`parseLocationsResponse` em `cockpit/lib/app/core/domain/entities/lsp_location.dart`) com suporte a `Location` e `LocationLink`; modelo e parser universal de símbolos (`LspSymbolKind` com 26 categorias, `LspDocumentSymbol` e `parseDocumentSymbols` em `cockpit/lib/app/core/domain/entities/lsp_symbol.dart`) cobrindo hierarquias modernas (`DocumentSymbol`) e formatos legados planos (`SymbolInformation`); histórico semântico bidirecional com Go Back e Go Forward (`SemanticNavigationHistory` em `cockpit/lib/app/core/domain/services/semantic_navigation_history.dart`); e métodos de navegação assíncronos no pool de servidores (`implementation`, `references`, `documentSymbols`, `workspaceSymbols` em `cockpit/lib/app/core/data/lsp/lsp_server_pool.dart`).
Validação: 13 testes automatizados aprovados em `cockpit/test/domain/lsp_symbol_test.dart` (4), `cockpit/test/domain/semantic_navigation_history_test.dart` (5) e `cockpit/test/integration/lsp_semantic_navigation_test.dart` (4); análise estática `dart analyze --fatal-infos` com 0 erros/alertas. Concluído em 05/11/2026. Detalhes em `plan/72-navegacao-semantica-busca-unificada.md`.

### L04 — Entregar refatoração e workspace edits seguros

Prioridade P1 · Porte L · Dependências: L02, W03.

Referência: src/editor/refactor; apply/prepare/undo workspace edit.
Destino: Operações de arquivo e editor existentes.

Aceite: Rename, quick fixes, organização de imports e formatação com preview de múltiplos arquivos; validar versões antes de aplicar e recuperar/undo em falha parcial.

Entrega: Implementação da infraestrutura completa de refatoração semântica, renomeação e workspace edits seguros: decodificador e modelos universais `LspWorkspaceEdit`, `LspTextDocumentEdit`, `LspPrepareRenameResult` e operações de recursos (`create`, `rename`, `delete`) em `cockpit/lib/app/core/domain/entities/lsp_workspace_edit.dart`; catálogo de ações de código `LspCodeAction` e `LspCodeActionKind` (`quickfix`, `refactor`, `source.organizeImports`) em `cockpit/lib/app/core/domain/entities/lsp_code_action.dart`; serviço de execução segura `SafeWorkspaceEditService` (`cockpit/lib/app/core/domain/services/safe_workspace_edit_service.dart`) fornecendo preview em memória com diffs por arquivo, bloqueio imediato em divergência de versão do documento (`document.version`), execução transacional com rollback automático atômico em caso de falha de gravação/permissão, e geração de token de reversão global (undo atômico); e integração de operações no `LspServerPool` (`prepareRename`, `rename`, `codeActions`, `resolveCodeAction`, `organizeImports` e `formatDocument`).
Validação: 12 testes unitários e de integração aprovados em `cockpit/test/domain/lsp_workspace_edit_test.dart` (4), `cockpit/test/domain/safe_workspace_edit_service_test.dart` (4) e `cockpit/test/integration/lsp_refactoring_and_rename_test.dart` (4); suíte combinada de navegação e refatoração com 25 testes aprovados; análise estática `dart analyze --fatal-infos` com 0 erros e 0 alertas. Concluído em 05/11/2026. Detalhes em `plan/72-refatoracao-workspace-edits-seguros.md`.

### L05 — Homologar linguagens por níveis de capacidade

Prioridade P1 · Porte L · Dependências: L02, L03, L04.

Referência: 77 definições e fixtures OpenIDEA.
Destino: Catálogo e fixtures de teste do Orkest.

Aceite: Matriz executada para Dart/Flutter, TS/JS, Python, Rust e Go; fase seguinte Java/C#/PHP; Vue/Svelte/HTML/CSS/JSON/YAML/SQL por demanda; registrar SDK/server/adapter e recurso não suportado sem prometer paridade.

Entrega: Estruturação e homologação da matriz de linguagens por níveis de capacidade (*tiers*): inclusão do enum `LanguageTier` (`tier1Core`, `tier2Enterprise`, `tier3WebData`) em `LanguageDef` (`cockpit/lib/app/core/data/lsp/lsp_launchers.dart`); expansão do catálogo declarativo para 20 linguagens com inclusão das linguagens sob demanda requeridas no plano (`sql` com `sql-language-server`, `vue` com `@vue/language-server` e `svelte` com `svelte-language-server`); implementação do serviço de auditoria e conformidade `LanguageCapabilityMatrix` (`cockpit/lib/app/core/domain/entities/language_capability_matrix.dart`) fornecendo relatórios determinísticos (`LanguageAuditReport`, `LanguageSupportStatus`) e discriminando explicitamente recursos não suportados para eliminar falsas promessas de paridade; e conjunto de fixtures sintéticas em `cockpit/test/fixtures/languages/`.
Validação: 13 testes dedicados aprovados em `cockpit/test/integration/language_capability_homologation_test.dart` (5) e `cockpit/test/data/lsp_launchers_test.dart` (8); análise estática `dart analyze --fatal-infos` com 0 erros e 0 alertas. Concluído em 05/11/2026. Detalhes em `plan/72-homologacao-linguagens-niveis-capacidade.md`.

### L06 — Avaliar inteligência avançada e análise estrutural

Prioridade P2 · Porte L · Dependências: L05.

Referência: ide-analysis, ide-syntax; code lens/inlay/hierarchies.
Destino: Painéis do editor e serviços de análise selecionados.

Aceite: Provar inlays, hierarquias, busca estrutural/duplicações e análise apenas onde servidor suporta; medir custo e escolher subset útil.

Entrega: Implementação da infraestrutura de inteligência avançada, análise estrutural e escolha seletiva de subconjunto útil de capacidades LSP: entidades de domínio `LspInlayHint` e `LspInlayHintKind` (`type`, `parameter`) em `cockpit/lib/app/core/domain/entities/lsp_inlay_hint.dart`; modelos de hierarquia `LspCallHierarchyItem`, `LspCallHierarchyIncomingCall`, `LspCallHierarchyOutgoingCall` e `LspTypeHierarchyItem` em `cockpit/lib/app/core/domain/entities/lsp_hierarchy.dart`; modelos de `LspCodeLens` e `LspCommand` em `cockpit/lib/app/core/domain/entities/lsp_code_lens.dart`; serviço de análise estrutural `StructuralAnalysisService` (`cockpit/lib/app/core/domain/services/structural_analysis_service.dart`) provendo `findDuplications` (detecção de blocos de código duplicados com coeficiente de Jaccard e normalização sintática), `searchPattern` (busca estrutural com curingas `$ID` e captura de sintaxe) e `auditLanguageSubset` (matriz de viabilidade recomendando subsets úteis com fallback gracioso para coleções vazias quando o servidor LSP não suporta ou está indisponível); e integração dos métodos públicos no `LspServerPool` (`inlayHints`, `prepareCallHierarchy`, `callHierarchyIncomingCalls`, `callHierarchyOutgoingCalls`, `prepareTypeHierarchy`, `typeHierarchySupertypes`, `typeHierarchySubtypes`, `codeLenses` e `resolveCodeLens`).
Validação: 9 testes unitários dedicados em `cockpit/test/domain/lsp_advanced_intelligence_test.dart`; 39 testes da suíte combinada aprovados sem falhas; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-inteligencia-avancada-analise-estrutural.md`.

### H00 — Revisar e integrar correção de espera já implementada

Prioridade P0 · Porte S · Dependências: nenhuma.

Referência: Commit 8d01a751, fix/harness-state-detection.
Destino: TerminalSession e terminal_status_test.

Aceite: Revisar na branch única; build e validação real antes de marcar entregue; 102 testes anteriores não equivalem a validação de todas as CLIs.

### H01 — Formalizar estado e precedência dos sinais de harness

Prioridade P0 · Porte M · Dependências: F01.

Referência: ide-agent/model, conversation, normalize; regras vigentes Orkest.
Destino: TerminalSession e contrato activity/hooks existente.

Aceite: Separar presença, execução, espera humana, conclusão e encerramento; origem/geração/sessão/turno/request quando disponíveis, deduplicação e eventos atrasados definidos; nomes de harness não selecionam comportamento.

Entrega: Formalização do modelo de estados ortogonais e precedência determinística dos sinais de harness: criação das entidades `HarnessPresence` (`none`, `attached`, `detached`), `HarnessExecutionPhase` (`idle`, `running`, `waitingInput`, `completed`, `closed`), `HarnessSignalSource` (com pesos: `structuredHook` [100] > `ptyMarker` [75] > `userInput` [50] > `screenObservation` [25]), `HarnessSignal` e `HarnessStateSnapshot` em `cockpit/lib/app/core/domain/entities/harness_signal.dart`; implementação do `HarnessStateCoordinator` (`cockpit/lib/app/core/domain/services/harness_state_coordinator.dart`) aplicando regras estritas de precedência de fontes (bloqueando rebaixamentos espúrios por observação de tela), isolamento de gerações de sessão (descarte de sinais atrasados), deduplicação de atividades concluídas em buffer circular FIFO cap de 256 itens e neutralidade absoluta de produtores/CLIs; e integração transparente na `TerminalSession` (`cockpit/lib/app/orkest/ui/session/terminal_session.dart`).
Validação: 6 novos testes unitários dedicados em `cockpit/test/domain/harness_signal_precedence_test.dart` e 68 testes de status de terminal revalidados em `cockpit/test/session/terminal_status_test.dart` (total de 74 testes aprovados sem falhas); análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-formalizacao-estado-precedencia-harness.md`.

### H02 — Criar corpus e replay de leitura de harness

Prioridade P1 · Porte M · Dependências: H01.

Referência: ide-agent/replay.rs e fixtures JSONL.
Destino: test/session e fixtures sanitizadas.

Aceite: Capturas versionadas sem segredos para ANSI fragmentado, redraw, prompts repetidos, permissões simultâneas, subagentes, Stop/SessionEnd, WSL e reconnect; replay determinístico compara transições e duplicações.

Entrega: Criação da infraestrutura de corpus e replay determinístico de leitura de harness: entidades de dados serializáveis `HarnessReplayEvent`, `HarnessReplayTransition` e `HarnessReplayScenario` em `cockpit/lib/app/core/domain/entities/harness_replay_event.dart`; motor de execução determinístico `HarnessReplayRunner` em `cockpit/lib/app/core/domain/services/harness_replay_runner.dart` com recomposição de sequências ANSI fragmentadas, detecção de marcadores PTY (OSC 133/activity), avaliação de precedência temporal baseada no timestamp dos eventos (`abs() < 5000ms`), métricas de integridade e isolamento de gerações de sessão no cômputo de flicker; suporte formal a ciclos de vida hierárquicos de subagentes no `HarnessStateCoordinator` mantendo `working` até a conclusão de todas as subtarefas; catálogo com 8 cenários versionados e sanitizados em JSON (`cockpit/test/fixtures/harness/`: `01_ansi_fragmented`, `02_screen_redraw`, `03_repeated_prompts`, `04_concurrent_permissions`, `05_subagents`, `06_stop_session_end`, `07_wsl_environment`, `08_session_reconnect`).
Validação: 10 testes dedicados em `cockpit/test/session/harness_corpus_replay_test.dart` (auditoria estrita de segredos e zero vazamentos com regex, determinismo comprovado e 100% de match de transições com 0 flickers em sucessivas execuções); 74 testes de regressão aprovados em `harness_signal_precedence_test.dart` e `terminal_status_test.dart`; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-corpus-replay-leitura-harness.md`.

### H03 — Ampliar reconhecimento de CLI por evidência

Prioridade P1 · Porte M · Dependências: H02.

Referência: provider.rs e registry como metadados de referência.
Destino: HarnessCatalog, normalizer, classifier, monitor.

Aceite: Para cada CLI selecionada, validar executável/wrappers/flags e modos não interativos no host; hooks opcionais; fornecedores não reconhecidos continuam via contrato genérico, sem parser inventado.

Entrega: Ampliação e consolidação do reconhecimento de CLI por evidência: enriquecimento de `HarnessSpec` com metadados de capacidades (`supportsStructuredHooks`, `supportsPtyMarkers`, `supportsResume`, `resumeSyntax`, `nonInteractiveFlags`, `adminSubcommands`, `knownWrappers`); catálogo expandido para 11 ferramentas em `cockpit/lib/app/core/domain/entities/harness.dart` com inclusão de Gemini CLI (`gemini`), Kimi CLI (`kimi`), Aider (`aider`) e Ollama (`ollama`), provendo SVGs dedicados em `cockpit/assets/harness_icons/`; serviço de evidência no host `HarnessHostEvidence` (`cockpit/lib/app/core/domain/services/harness_host_evidence.dart`) com relatório `HarnessEvidenceReport` e probe de binários no host (`isExecutableAvailable`); normalizador multi-runtime `TerminalHarnessNormalizer` com suporte a `python -m`, `npx`, `bunx`, `uvx`, `pipx`, `pnpm` e `yarn`; classificador declarativo `TerminalHarnessClassifier` com regras para flags de help/versão, modos não interativos/batch/print/quiet e subcomandos administrativos; e contrato genérico estrito que retorna `null` determinístico para comandos desconhecidos sem alucinar parsers ad-hoc.
Validação: 40 testes unitários aprovados em `test/domain/terminal_harness_classifier_test.dart` (30) e `test/domain/harness_host_evidence_test.dart` (10); 19 testes de regressão aprovados em `harness_corpus_replay_test.dart`, `harness_signal_precedence_test.dart` e `agent_harness_test.dart`; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-reconhecimento-cli-evidencia-harness.md`.

### H04 — Verificar paridade local, SSH e WSL de harness

Prioridade P1 · Porte M · Dependências: H02, H03.

Referência: Correlação ACP como referência; protocolo atual Orkest.
Destino: orkest_protocol, remote adapters e host server.

Aceite: Mesmas sequências geram mesmos estados em local/remoto; geração antiga não ressuscita sessão; desconexão não se apresenta falsamente como fim de turno ou aprovação.

Entrega: Implementação da garantia formal de paridade determinística e integridade de transporte entre Local, SSH e WSL: modelos de domínio `HarnessEnvironmentType` e `HarnessEnvironmentContext` em `cockpit/lib/app/core/domain/services/harness_environment_parity.dart`; serviço `HarnessEnvironmentParity` com `processSignal` (rejeitando sinais em desconexão ou com geração defasada), `handleDisconnection` (desanexação imediata `presence: detached`, fase `closed`, cancelando esperas pendentes sem emitir conclusão de turno nem aprovação fantasma de ferramenta), `handleReconnection` (avanço formal de geração `advanceGeneration`, impedindo ressurreição por replays de buffers residuais antigos) e `normalizeEnvironmentPath` (mapeamento seguro entre Windows, WSL `/mnt/c/...` e caminhos remotos POSIX via SSH); implementação de igualdade por valor (`operator ==` e `hashCode`) em `HarnessStateSnapshot` (`cockpit/lib/app/core/domain/entities/harness_signal.dart`); e integração dos métodos públicos `handleTransportDisconnection` e `handleTransportReconnection` em `TerminalSession` (`cockpit/lib/app/orkest/ui/session/terminal_session.dart`).
Validação: 4 testes unitários dedicados em `cockpit/test/session/harness_environment_parity_test.dart`; 63 testes da suíte combinada aprovados sem regressões em `terminal_harness_classifier_test.dart`, `harness_host_evidence_test.dart`, `harness_corpus_replay_test.dart`, `harness_signal_precedence_test.dart` e `agent_harness_test.dart`; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-verificacao-paridade-local-ssh-wsl-harness.md`.

### H05 — Expor diagnóstico de estado sem capturar conteúdo

Prioridade P2 · Porte M · Dependências: H01.

Referência: Probe/capabilities ide-agent; telemetria Orkest.
Destino: Diagnósticos existentes e testes de estado.

Aceite: Mostrar origem do último estado, idade do sinal e capacidade de detecção com dados limitados; medir falso working/waiting/idle em corpus rotulado; falta de sinal não inventa execução.

Entrega: Implementação da infraestrutura formal de diagnóstico de estado com privacidade estrita e sem captura de conteúdo: modelos de domínio `HarnessDetectionConfidence` (`unasserted`, `low`, `medium`, `high`, `authoritative`), `HarnessStateDiagnostic`, `HarnessLabeledSample` e `HarnessCorpusConfusionMatrix` em `cockpit/lib/app/core/domain/entities/harness_diagnostic.dart`; serviço de diagnóstico `HarnessDiagnosticService` (`cockpit/lib/app/core/domain/services/harness_diagnostic_service.dart`) provendo `buildDiagnostic` (com cômputo da idade do sinal `signalAge`, derivação hierárquica de confiança, tratamento de ambiente degradado `limitedDataMode`, e garantia matemática de que falta de sinal resulta deterministicamente em estado `idle` com confiança `unasserted` sem inventar falsos working ou waiting) e `evaluateCorpusAccuracy` (matriz de confusão sobre amostras rotuladas com taxas de falsos working, waiting e idle); contadores acumulados e distribuição por fonte no `HarnessStateCoordinator`; integração de `harnessDiagnostic` no `TerminalSession`; e proteção rigorosa em `toTelemetryMap()` garantindo zero vazamento de prompts, buffers de terminal, saídas stdout/stderr ou credenciais.
Validação: 6 testes unitários dedicados em `cockpit/test/domain/harness_diagnostic_service_test.dart`; 69 testes da suíte combinada aprovados sem falhas; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-diagnostico-estado-harness.md`.

### G01 — Entregar revisão e staging por hunks

Prioridade P1 · Porte L · Dependências: W03, A04.

Referência: ide-vcs stage_hunks/stage_patch; TS hunks/inclusion.
Destino: GitController, diff_viewer e contratos Git.

Aceite: Stage/unstage por trecho, diff staged/unstaged, commit parcial/amend e preview; validar HEAD/index contra corridas e preservar alterações não selecionadas, arquivos binários e untracked.
Entrega: Serviço desacoplado `GitHunkService` (`domain/services/git_hunk_service.dart`) gerando patches unificados para `git apply --cached` e `git apply --cached --reverse`; descarte no working tree com `discardHunk`; botões interativos contextuais no `DiffViewer` (`_HunkHeader`) com tema visual semântico `colors.gitStaged`; integração com `GitController` e `DiffViewerSession`; proteção atômica contra corridas no índice; i18n em pt_BR, en e es; documentado em `plan/72-revisao-staging-por-hunks.md`. 4 testes unitários com repo real aprovados e 13 testes de regressão de diff aprovados com análise estática limpa. Concluído em 05/11/2026.

### G02 — Adicionar resolução visual de conflitos

Prioridade P1 · Porte L · Dependências: G01.

Referência: MergeEditor, mergeDiff3; vcs_conflict_versions.
Destino: Diff/editor e GitController.

Aceite: Base/ours/theirs/result editável, navegação e validação de marcadores; continuar/abortar operação; salvar sem perder conteúdo e revalidar alterações externas.

### G03 — Evoluir histórico, autoria e comparação

Prioridade P2 · Porte L · Dependências: G01.

Referência: GitLog, graph, block_history, blame, log_index.
Destino: git_history_panel e leitores de histórico.

Aceite: Grafo/filtros/paginação, blame e histórico de arquivo/seleção; comparar revisões/branches e navegar para código; desempenho medido em repositório grande.

Entrega: Modelos tipados de autoria (`GitBlameHunk`), consulta avançada (`GitHistoryQuery`) com suporte a paginação (`limit`, `skip`), acompanhamento de renomeações de arquivo (`--follow`), filtros por autor (`--author`), busca por mensagem (`--grep`), intervalos de revisão e flag `all`; comparação atômica de revisões e branches divergentes (`GitComparison` e `compareRefs`); parser estruturado `GitBlameParser` para `git blame --porcelain` com cache de metadados em blocos contíguos; componente visual `GitBlameView` com filtragem rápida em tempo real, badges de linhas, identificação de commit, autor, data relativa e navegação clicável para código-fonte.
Validação: 22 testes unitários e de integração aprovados em `cockpit/test/data/git_blame_parser_test.dart`, `cockpit/test/data/git_history_evolution_test.dart`, `cockpit/test/ui/git_blame_view_test.dart`, `cockpit/test/data/git_history_reader_impl_test.dart` e `cockpit/test/ui/git_history_panel_test.dart`; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-evolucao-historico-autoria-comparacao.md`.

### G04 — Adicionar gestão avançada de trabalho Git

Prioridade P2 · Porte L · Dependências: G02.

Referência: ide-vcs/manage, shelf, patch, rebasePlan.
Destino: Serviços Git local/remoto.

Aceite: Worktrees, stash/shelf, changelists, patches, tags e rebase/cherry-pick/revert em subentregas; pré-condições/abort/recovery e processos cancelados testados, sem merge automático na main.

Entrega: Modelos estruturados de trabalho (`GitStashEntry` e `GitTagEntry`); serviço de operações Git desacoplado `GitWorkService` cobrindo Stash (operações completas: listagem, push com untracked/keep-index, aplicação, pop, drop e diff prévio), Tags (listagem formatada, criação anotada/leve e exclusão) e Patches unificados (geração via diff e aplicação com validação prévia `--check`); operações avançadas protegidas (`cherryPick`, `revertCommit` e `rebase`) com garantia de working tree limpo e bloqueio mandatório contra execuções diretas na branch `main`; métodos expostos em `GitController` com invalidação automática de cache de histórico e refresh assíncrono.
Validação: 5 testes de integração em repositório real em `cockpit/test/domain/git_work_service_test.dart`; 44 testes da suíte completa de Git aprovados; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-gestao-avancada-trabalho-git.md`.

### G05 — Integrar revisão de PR no contexto do código

Prioridade P2 · Porte M · Dependências: G01.

Referência: ide-github e src/features/github.
Destino: Painel Git e ações de revisão.

Aceite: Listar/detalhar/criar PR, comentários/review/diff e checkout conforme ferramenta disponível; falhas de autenticação explícitas; nenhuma operação de publicação/merge fora de autorização.

Entrega: Modelos estruturados `GitPullRequest`, `GitPrComment` e `GitPrDetail` (`cockpit/lib/app/orkest/domain/entities/git_pull_request.dart`); serviço desacoplado `GitPullRequestService` (`cockpit/lib/app/orkest/domain/services/git_pull_request_service.dart`) implementando `parseOwnerRepo` (suporte a SSH e HTTPS), `listPullRequests` (com tratamento amigável de autorização HTTP 401/403 e paginação), `getPullRequestDetail` (agregação concorrente de metadados, arquivos, comentários e diff unificado), `createPullRequest`, `checkoutPullRequest` (fetch de `pull/<number>/head` para branch local `pr-<number>` e checkout direto no workspace para revisão no editor) e `addComment` (comentários gerais de issue e comentários inline atrelados a caminho, linha e commit); painel visual `GitPrReviewPanel` (`cockpit/lib/app/orkest/ui/widgets/git_pr_review_panel.dart`) com lista bifurcada de PRs, abas de Descrição, Arquivos Alterados (badges A/M/D/R) e Comentários, checkout local com um clique e formulário reativo de submissão de revisão; injeção hermética de `HttpRequester` e `originUrlOverride` para testes determinísticos.
Validação: 10 testes automatizados cobrindo domínio e widgets em `cockpit/test/domain/git_pull_request_service_test.dart` e `cockpit/test/ui/git_pr_review_panel_test.dart`; 27 testes de regressão de toda a suíte de Git e PR aprovados sem falhas; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-integracao-revisao-pr.md`.

### R01 — Integrar configurações de execução e testes

Prioridade P1 · Porte M · Dependências: W01, L01.

Referência: ide-run; src/features/run e producers.
Destino: Tasks, pty_task_runner e perfis existentes.

Aceite: Executar arquivo/teste/projeto com cwd/env/SDK explícitos; importar configurações selecionadas; console clicável e parar processo sem duplicar runner nem perder interatividade do terminal.

### R02 — Entregar núcleo DAP e UI de depuração

Prioridade P1 · Porte L · Dependências: A04, R01, W03.

Referência: ide-dap; debugger; commands/debug.rs.
Destino: Contratos de debug e painéis Flutter a definir.

Aceite: Launch/attach, lifecycle, breakpoints verificados, pause/resume/step, threads/stack/scopes/variáveis/evaluate e console; ações dependem de capabilities; limpar processos e rejeitar resposta de sessão antiga.

Entrega: Protocolo completo DAP em Dart puro com modelos fortemente tipados (`DapRequest`, `DapResponse`, `DapEvent`, `DapCapabilities`, etc.); codec de enquadramento `Content-Length` e buffer persistente resiliente a fragmentação de rede/I-O; cliente assíncrono `DapClient` com pareamento determinístico de `request_seq`; `DebugSessionController` reativo para ciclo de vida e sincronização de breakpoints; widgets especializados `DebugToolbar` (com atalhos F5, F10, F11, Shift+F11, Shift+F5) e painel colapsável `DebugPanel` com Call Stack, Variáveis e Breakpoints com navegação clicável para código-fonte.
Validação: 10 testes unitários e de widgets aprovados em `cockpit/test/data/dap_core_test.dart` e `cockpit/test/ui/debug_widgets_test.dart`; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-nucleo-dap-ui-depuracao.md`.

### R03 — Homologar debug Dart e Flutter

Prioridade P1 · Porte L · Dependências: R02.

Referência: languages/dart.toml; adapter.rs.
Destino: Configuração SDK e tasks Flutter existentes.

Aceite: Dart CLI e Flutter launch/attach em targets selecionados; breakpoints, exceptions, source mapping, hot reload/restart reais e lifecycle testados; distinguir chaves PTY atuais das funções via DAP.

Entrega: Orquestrador `DartDebugAdapter` com resolução de executáveis oficiais do Dart e Flutter SDK (`dart debug_adapter` e `flutter debug_adapter`) com suporte a `sdkPath` configurável; modelo `DartDebugTarget` cobrindo alvos CLI, testes e apps móveis/desktop com formatação determinística de argumentos para `launch` e `attach` (`vmServiceUri`); protocolo DAP estendido com a factory `DapClient.fromProcess`, configuração de filtros de exceção `setExceptionBreakpoints` (`None`, `All`, `Unhandled`) e requisições customizadas DAP de Hot Reload e Hot Restart do Flutter; controle reativo em `DebugSessionController` com método `startDartSession` e flag `isFlutter`; ações visuais dedicadas de Hot Reload (ícone de zap) e Hot Restart (ícone de rotação) na `DebugToolbar` com atalhos de teclado `Ctrl+F5` e `Ctrl+Shift+F5`; encerramento limpo sem retenção de processos nem colisão com chaves interativas do runner PTY.
Validação: 10 testes unitários específicos aprovados em `cockpit/test/data/dart_debug_adapter_test.dart`; 20 testes da suíte completa de DAP aprovados; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-homologacao-debug-dart-flutter.md`.

### R04 — Expandir debug multilinguagem progressivamente

Prioridade P2 · Porte L · Dependências: R02, L05.

Referência: debugpy, js-debug, codelldb e configs de linguagens.
Destino: Registro de adaptadores e painéis DAP.

Aceite: Validar TS/JS, Python, Rust/Go conforme adapter; depois JVM/.NET; documentar instalação/licença e limites de watchpoints, restart frame, smart step e HotSwap por adaptador.

Entrega: Implementação da infraestrutura formal de depuração multilinguagem via Debug Adapter Protocol (DAP): entidades de domínio `DebugAdapterCapabilities`, `DebugAdapterDefinition` e catálogo declarativo `MultiLanguageDebugRegistry` em `cockpit/lib/app/core/domain/entities/multi_language_debug_adapter.dart` cobrindo TypeScript/JavaScript (`pwa-node`), Python (`debugpy`), Rust/C/C++ (`lldb`/`codelldb`), Go (`dlv`), Java/Kotlin (`java`), C#/.NET (`coreclr`) e Dart/Flutter (`dart`); matriz estrita de capacidades documentando limitações e recursos de cada ecossistema (hardware watchpoints em LLDB/Delve/Java; HotSwap em Dart, Java, Node e .NET; Restart Frame em Dart, TS e Java); orquestrador unificado `MultiLanguageDebugAdapter` em `cockpit/lib/app/core/data/dap/multi_language_debug_adapter.dart` provendo resolução de comandos com suporte a overrides customizados de executáveis e argumentos (ex: virtualenv de Python), formatação de argumentos de launch mesclando templates e flags, e serviço de auditoria `auditAdapter` gerando relatórios de conformidade e instrução de instalação com licenças transparentes (MIT, GPL-2.0, EPL-1.0, BSD-3-Clause).
Validação: 8 testes unitários dedicados em `cockpit/test/domain/multi_language_debug_adapter_test.dart`; 26 testes da suíte combinada de depuração DAP aprovados sem falhas; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-expansao-debug-multilinguagem.md`.

### R05 — Integrar resultados de testes, coverage e profiler

Prioridade P2 · Porte L · Dependências: R01, L05.

Referência: ide-coverage, ide-profiler, run TestTreeView.
Destino: Tasks, telemetria e gutter de editor.

Aceite: Árvore de testes/reexecutar falhas e cobertura por formato validado; profiler somente por demanda; relatório aponta ferramenta/linguagem e não apresenta dado ausente como zero.

Entrega: Implementação da suíte de teste, cobertura e profiling sob demanda: entidades imutáveis `TestStatus`, `TestCaseNode`, `TestSuiteNode`, `TestTreeReport`, `LineCoverageStatus`, `FileCoverageReport`, `GlobalCoverageReport`, `ProfilerHotSpot` e `ProfilerReport` em `cockpit/lib/app/core/domain/entities/test_coverage_profiler.dart`; orquestrador e parser determinístico `TestCoverageProfilerService` em `cockpit/lib/app/core/domain/services/test_coverage_profiler_service.dart` decodificando eventos JSON de executores de teste (`parseDartTestJson`), montando comandos de reexecução seletiva de falhas (`buildRerunFailedCommand`), processando relatórios canônicos LCOV (`parseLcov`) com garantia estrita de retornar `coveragePercent == null` (e nunca `0.0%`) quando dados estiverem ausentes, e extração tabular de hotspots de profiler (`parseProfilerOutput`) operando unicamente sob demanda pontual (`isRealtime: false`).
Validação: 5 testes unitários dedicados em `cockpit/test/domain/test_coverage_profiler_test.dart`; 13 testes combinados de depuração e testes aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-integracao-testes-coverage-profiler.md`.

### B01 — Ampliar introspecção e navegação de bancos

Prioridade P2 · Porte M · Dependências: F01.

Referência: ide-db source/conn/sql; db commands.
Destino: DbDriver.schema, db_panel e conectores anaki existentes.

Aceite: Matriz de schemas/tabelas/views/índices/FKs/routines por engine; DDL e navegação contextual com paginação/cache invalidável; manter Redis/Mongo e política de acesso atual.

Entrega: Modelos estruturados de introspecção `SchemaIndex`, `SchemaForeignKey`, `SchemaRoutine` e `SchemaTableDetail` (`cockpit/lib/app/orkest/domain/entities/db_schema_entities.dart`); consultas SQL especializadas em `cockpit/lib/app/orkest/domain/db_schema_sql.dart` para extração de índices (`dbIndexesSql`), chaves estrangeiras (`dbForeignKeysSql`), rotinas e procedures (`dbRoutinesSql`) e definição textual de views (`dbViewDefinitionSql`) cobrindo SQLite, PostgreSQL, MySQL e MSSQL; gerador determinístico de DDL `DbDdlGenerator` (`cockpit/lib/app/orkest/domain/services/db_ddl_generator.dart`) gerando scripts `CREATE TABLE` (com PKs, FKs com regras ON DELETE/UPDATE, colunas tipadas e índices) e `CREATE VIEW`; integração de métodos assíncronos e caches dedicados em `DatabaseViewModel` com invalidação seletiva via `invalidateSchema(connName)`; interface atualizada no `DbPanel` (`_TableDetailList`) exibindo subseções expansíveis de colunas, índices e chaves estrangeiras, além de menu de contexto na tabela/view com ações "Copiar DDL" e "Copiar SELECT *".
Validação: 24 testes unitários cobrindo consultas SQL, gerador de DDL e modelos de schema em `cockpit/test/domain/db_schema_sql_test.dart`, `cockpit/test/domain/db_ddl_generator_test.dart` e `cockpit/test/domain/db_schema_entities_test.dart`; 81 testes de regressão de toda a suíte de banco de dados aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-introspeccao-navegacao-bancos.md`.

### B02 — Provar transações e edição persistente de dados

Prioridade P2 · Porte L · Dependências: B01, A04.

Referência: ide-db transactions e db_apply_edits.
Destino: DbDriver efêmero atual e painéis SQL.

Aceite: ADR decide sessão dedicada para transação manual; commit/rollback/disconnect e atualização otimista seguros; não simular transação entre conexões efêmeras; schema do produto só muda por migration versionada.

Entrega: Implementação da arquitetura de sessões transacionais dedicadas e edição atômica com concorrência otimista (`DbRowEditService`, `DbTransactionSession`, `DbTransactionManager`). O serviço `DbRowEditService` (`cockpit/lib/app/orkest/domain/services/db_row_edit_service.dart`) gera instruções SQL determinísticas de UPDATE e DELETE com cláusulas WHERE baseadas na chave primária e nos valores antigos das colunas modificadas (`WHERE pk = val AND col = old_val`), prevenindo sobrescritas acidentais e bloqueando operações em tabelas sem PK via `DbEditException`. A sessão transacional `DbTransactionSession` (`cockpit/lib/app/orkest/domain/services/db_transaction_session.dart`) mantém um lease exclusivo com a conexão física do banco de dados, executa `BEGIN`, intermediários e `COMMIT`/`ROLLBACK` garantindo isolamento total (sem simulação ingênua sobre conexões efêmeras), possui auto-rollback preventivo por inatividade após 60 segundos e descarte seguro em desconexões/erros. Gerenciador centralizado `DbTransactionManager` (`cockpit/lib/app/orkest/domain/services/db_transaction_manager.dart`) supervisiona o ciclo de vida e timeouts das sessões ativas.
Validação: 11 testes unitários aprovados em `cockpit/test/domain/db_row_edit_service_test.dart` e `cockpit/test/domain/db_transaction_session_test.dart` cobrindo geração de UPDATE/DELETE com concorrência otimista, escape de delimitadores por engine (PostgreSQL, MySQL, SQLite, MSSQL), rejeição de tabelas sem PK, ciclo de vida BEGIN->COMMIT, auto-rollback em erro/descarte e timeout por inatividade; 92 testes da suíte completa de banco de dados aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-transacoes-edicao-persistente-dados.md`.

### B03 — Evoluir console SQL e avaliar ClickHouse

Prioridade P2 · Porte M · Dependências: B01.

Referência: db_completion, explain/history/export; clickhouse.rs.
Destino: db_query_view e serviços SQL.

Aceite: Completion por schema, explain/histórico/export e limites de resultado; ClickHouse é decisão separada conforme demanda, sem remover suporte atual nem expor credenciais.

Entrega: Implementação da evolução completa do console SQL e formalização da avaliação técnica de ClickHouse. Entregue o serviço de exportação de dados estruturados `DbExportService` (`cockpit/lib/app/orkest/domain/services/db_export_service.dart`) com suporte a CSV (com delimitador flexível, controle de cabeçalhos e escape estrito de aspas duplicadas `""`, quebras de linha embutidas, datas ISO-8601 e blobs) e JSON (formatado/pretty e compacto); consultas `EXPLAIN` e `EXPLAIN ANALYZE` contextuais multi-engine via `dbExplainSql` em `cockpit/lib/app/orkest/domain/db_schema_sql.dart` para SQLite (`EXPLAIN QUERY PLAN`), PostgreSQL (`EXPLAIN` / `EXPLAIN (ANALYZE, COSTS, VERBOSE, BUFFERS)`), MySQL (`EXPLAIN` / `EXPLAIN ANALYZE`) e MSSQL (`SET SHOWPLAN_TEXT ON` / `SET STATISTICS PROFILE ON`); serviço de histórico de consultas `DbQueryHistoryService` (`cockpit/lib/app/orkest/domain/services/db_query_history_service.dart`) e entidade `DbQueryHistoryEntry` (`cockpit/lib/app/orkest/domain/entities/db_query_history_entry.dart`) com retenção máxima configurável (FIFO), pesquisa por texto e filtro por conexão; serviço de autocompletion de SQL por schema `DbSqlCompletionService` (`cockpit/lib/app/orkest/domain/services/db_sql_completion_service.dart`) provendo sugestões de keywords, funções agregadas/analíticas, tabelas (priorizadas em `FROM` e `JOIN`) e colunas qualificadas (`table.col`); avaliação técnica e arquitetural (ADR) de ClickHouse em `plan/72-avaliacao-clickhouse.md` formalizando a não inclusão no bundle padrão por YAGNI/KISS e recomendando uso da interface HTTP REST nativa quando demandado analiticamente.
Validação: 20 testes unitários aprovados em `cockpit/test/domain/db_export_service_test.dart`, `cockpit/test/domain/db_explain_sql_test.dart`, `cockpit/test/domain/db_query_history_service_test.dart` e `cockpit/test/domain/db_sql_completion_service_test.dart`; 122 testes de toda a suíte de bancos de dados aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-avaliacao-clickhouse.md`.

### X01 — Priorizar produtividade de edição e visualização

Prioridade P2 · Porte M · Dependências: W03, L02.

Referência: templates, macros, vim, todo, scratch, color-preview, viewers.
Destino: Editor e viewers já existentes.

Aceite: Inventário de snippets/templates/Emmet/folding/bookmarks/TODO/Vim/macros; selecionar e dividir entregas por uso; atalhos e preview seguem tema, i18n e acessibilidade.

Entrega: Implementação da infraestrutura formal e inventário completo de produtividade de edição e visualização: modelos de domínio `ProductivityCategory`, `CapabilityStatus`, `ProductivityCapability`, catálogo declarativo `ProductivityInventoryRegistry` cobrindo 10 categorias funcionais com divisão em tiers de uso (1 a 3) e rótulos acessíveis (a11y), modelos imutáveis `BookmarkItem`, `TodoItem`, `FoldingRange`, `ColorPreviewMatch`, `VimMode`, `MacroAction`, `EditorMacro` e `ScratchBuffer` em `cockpit/lib/app/core/domain/entities/editor_productivity.dart`; conjunto de serviços determinísticos em `cockpit/lib/app/core/domain/services/editor_productivity_service.dart`: `EmmetAbbreviationService` provendo expansão de sintaxe abreviada HTML/XML/CSS (aninhamento `>`, irmãos `+`, multiplicação `*N`, classes `.`, IDs `#`, atributos `[]` e texto `{}` com suporte a tags auto-fecháveis), `CodeFoldingService` computando regiões dobráveis de blocos `{ ... }`, comentários multilinhas e diretivas de região (`// #region`), `TodoScanningService` extraindo anotações em comentários (`TODO`, `FIXME`, `BUG`, `NOTE`, `HACK`, `XXX`) com classificação de severidade, `ColorPreviewService` identificando declarações literais de cor (Hex `#RGB`/`#RRGGBBAA`, CSS `rgb`/`rgba` e Flutter `Color()`) com cálculo de luminância e contraste WCAG sobre o limiar calibrado do Orkest (`0.24`), `EditorBookmarkService` com alternância e navegação rápida por mnemônico, `EditorMacroService` gravando e reproduzindo sequências atômicas de teclado, e `VimStateController` implementando máquina de estados modal com modos `normal`, `insert`, `visual` e buffer de comandos (`:w`, `:q`, `:wq`).
Validação: 14 testes unitários dedicados em `cockpit/test/domain/editor_productivity_test.dart`; 27 testes da suíte combinada aprovados sem falhas; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-produtividade-edicao-visualizacao.md`.

### X02 — Aprimorar HTTP, GraphQL e navegação web

Prioridade P2 · Porte M · Dependências: F01.

Referência: ide-http; http-client/graphql/web; Spring route sources.
Destino: http_document, http_request_runner e browser atuais.

Aceite: Comparar ambientes, histórico, auth, cancelamento e resultados com .http existente; GraphQL/rotas/frameworks somente com validação específica; proteger segredos e não duplicar browser.

Entrega: Implementação da infraestrutura avançada de HTTP, GraphQL e navegação web: modelos de domínio `HttpEnvironment`, `HttpRequestHistoryEntry`, enum `HttpAuthType`, entidade `HttpAuthConfig` com aplicação determinística e sanitização estrita de cabeçalhos (`sanitizeHeaders`, `maskSecret`), `GraphQLRequestSpec` para serialização de consultas/mutações com variáveis e payload canônico JSON, e `ExtractedRoute` para mapeamento de endpoints em `cockpit/lib/app/core/domain/entities/http_advanced_tools.dart`; orquestradores de serviço em `cockpit/lib/app/core/domain/services/http_advanced_tools_service.dart`: `HttpEnvironmentManager` (parsing de arquivos `.env`, alternância de perfis e mesclagem garantindo precedência de variáveis locais do `.http`), `HttpRequestHistoryService` (auditoria e armazenamento histórico cronológico FIFO de requisições com filtros por método, status, texto e expurgo automático de credenciais na URL), token de cancelamento determinístico `HttpRequestCancellationToken`, `FrameworkRouteScanner` (varredura estática de rotas cobrindo Spring Boot, Express.js, FastAPI e NestJS e gerador automático de arquivos `.http`) e `WebNavigationService` (sanitização de credenciais de URLs de navegação e resolução do modo de browser respeitando o contrato `BrowserCapability.resolve()` sem duplicar instâncias de engine de browser).
Validação: 12 testes unitários dedicados em `cockpit/test/domain/http_advanced_tools_test.dart`; 46 testes da suíte combinada de ferramentas e HTTP aprovados com 100% de sucesso; análise estática `dart analyze --fatal-infos` 100% limpa (0 issues). Concluído em 05/11/2026. Detalhes em `plan/72-aprimoramento-http-graphql-navegacao-web.md`.

### X03 — Avaliar Docker, build e deployment

Prioridade P3 · Porte L · Dependências: R01, A04.

Referência: ide-docker, ide-build, ide-remote; build-tools.
Destino: Tasks, SSH e serviços remotos existentes.

Aceite: Provar logs/inspect/Compose e tarefas build úteis; deployment com preview de diferenças e confirmação; selecionar demandas reais e não instalar ferramentas automaticamente.

### X04 — Avaliar notebooks e extensões

Prioridade P3 · Porte L · Dependências: A04, W02.

Referência: ide-notebook, ide-plugin, ide-extension, wit/sdk.
Destino: Pontos de extensão e viewers do Orkest.

Aceite: RFCs separados para notebook e plugin; definir kernel/lifecycle ou sandbox/permissões/API/versão; plugins React não são widgets Flutter; incluir decisão explícita de adiar quando custo não se justifica.

### M01 — Comparar algoritmos TS de diff/merge com Rust

Prioridade P1 · Porte L · Dependências: A02, F02.

Referência: src/features/vcs/comparison, mergeDiff3, graph.
Destino: Protótipos sem substituir editor de produção.

Aceite: Mesmo corpus e saídas esperadas em TS e Rust; medir custo completo com IPC/FFI, UTF-16, CRLF, hunks e casos adversos; decidir algoritmo por algoritmo e reaproveitar testes da origem.

### M02 — Comparar busca/indexação Dart com Rust

Prioridade P1 · Porte L · Dependências: A02, A01.

Referência: ide-search/index/vfs; busca atual em isolate.
Destino: content_searcher_impl, file_searcher e serviços remotos.

Aceite: Comparar exclusões/symlinks/binários/regex/cancelamento e incrementalidade; medir memória/latência total/CPU antes de trocar implementação atrás do contrato existente.

### M03 — Diagnosticar TypeScript visual do Office separadamente

Prioridade P3 · Porte M · Dependências: A02.

Referência: tool/office_world e third_party/office_engine.
Destino: habblaud_world_webview e engine visual atual.

Aceite: Perfis distinguem snapshot/serialização/simulação/render; migrar somente hotspot puro comprovado; manter desenho WebView/Flutter e rotinas atuais; resultado válido inclui não migrar.

### Q01 — Homologar IDE integrada e rollout reversível

Prioridade P1 · Porte L · Dependências: W02, L05, H04, G02, R03, A05.

Referência: Fixtures/e2e/perf da origem e testes Orkest.
Destino: CI e release desktop/local/remoto.

Aceite: Jornada buscar projeto -> editar/refatorar -> testar/debug -> revisar hunks/conflitos -> continuar harness validada; regressões de memória/latência avaliadas, flags/rollback e avisos de terceiros conferidos; merge somente com aprovação.

### DOC — Publicar análise e Kanban rastreável

Prioridade P0 · Porte S · Dependências: nenhuma.

Referência: Inventários OpenIDEA e inspeção atual Orkest.
Destino: plan/72-orkest-ide-completa.md e .kanban.

Aceite: Plano e quadro abertos pelo CLI; todos os 41 domínios de comandos referenciados; IDs, dependências e critérios consistentes; propostas futuras não marcadas como implementadas.

## Cobertura de todos os domínios de comandos

| Domínio OpenIDEA | Declarações explícitas | Atividades |
|---|---:|---|
| agent | 24 | H01, H02, H03 |
| analysis | 5 | L06 |
| app | 22 | W01, W02 |
| build | 7 | R01, X03 |
| bytes | 3 | W03 |
| caches | 2 | A02, M02 |
| clipboard | 3 | W03, X01 |
| coverage | 3 | R05 |
| db | 28 | B01, B02, B03 |
| debug | 30 | R02, R03, R04 |
| dependencies | 1 | X03, L01 |
| deploy | 15 | X03 |
| doc | 17 | W03 |
| docker | 14 | X03 |
| env | 1 | R01, A05 |
| fonts | 2 | W03 |
| fs | 12 | W01, W03 |
| github | 11 | G05 |
| history | 3 | G03 |
| http | 7 | X02 |
| java | 3 | L05, R04 |
| lsp | 37 | L01, L02, L03, L04, L05, L06 |
| nav | 13 | L03, M02 |
| notebook | 11 | X04 |
| perf | 2 | A02, M01, M02, M03, Q01 |
| plugin | 39 | X04 |
| profiler | 2 | R05 |
| refactor | 5 | L04 |
| run | 25 | R01, R05 |
| sdk | 7 | L01, L05 |
| search | 4 | L03, M02 |
| spell | 2 | X01 |
| ssh | 10 | H04, A05, X03 |
| syntax | 9 | L01, L06 |
| term | 8 | H01, H03, H04, R01 |
| tools | 7 | L01, L05 |
| vcs | 76 | G01, G02, G03, G04, M01 |
| web | 3 | X02 |
| window | 25 | W01, W03 |
| window_group | 9 | W01 |
| workspace | 3 | W01 |

## Definição de pronto e controles de migração

Cada implementação deve consultar impacto estrutural antes de alterar código, manter tipos/comentários/regras atuais e gerar commits incrementais na branch única `fix/harness-state-detection`. Push e abertura de PR somente sob novo pedido explícito de Flavio; merge exclusivamente com aprovação expressa. A implementação foi autorizada, mas mudanças de schema continuam exigindo migration estruturada quando necessárias.

Para entrega de serviço: contrato e capacidades testados, erros/cancelamento/desconexão simulados, recursos/processos encerrados e paridade local/remota verificada. Para UI: tema/i18n/acessibilidade/atalhos e fluxo humano testados. Para algoritmo: corpus de equivalência e benchmark versionados. Para harness: precisão por transição no corpus rotulado, isolamento por sessão e manutenção da presença idle. Aprovação visual de CLI real complementa testes simulados.

Novos caminhos entram por seleção controlada com implementação anterior disponível durante a prova. Migração incremental por domínio, não substituição completa do editor. Rollback restaura rota anterior sem regravar documentos/configurações ou perder sessões. Mudanças persistentes exigem migração estruturada e teste de leitura de versão anterior quando aplicável.

## Riscos e perguntas que as atividades resolvem

- RPC remoto da origem pode não cobrir todos os comandos Tauri; A03 mede cobertura real.
- O host completo pode carregar módulos desnecessários; A03/A05 avaliam recorte e distribuição.
- Protocolos/SDKs e capacidades variam por versão e linguagem; L05/R03/R04 fixam evidência.
- Regex/TUI sem evento estruturado é observação de menor confiança; H01/H02 preservam distinção e não prometem detecção universal.
- Transações SQL não cabem no contrato efêmero atual sem desenho adicional; B02 resolve explicitamente.
- Copiar componentes TS não entrega UI Flutter; M01 e atividades W/L/G separam algoritmo e interação.
- Catálogo de plugins/harnesses não equivale a autorização de instalação ou compatibilidade comprovada.

## Próxima execução recomendada

Começar por F01 e F02, e revisar H00 em paralelo quando houver responsável disponível. Em seguida A01/A02, H01/H02 e W01/W03 podem avançar conforme dependências. A decisão Dart/Rust deve sair de A04 antes de comprometer o produto com um backend novo. Não iniciar toda a migração só porque o catálogo é extenso.
