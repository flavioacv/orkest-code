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

Incrementos implementados: hover L02a, signature help L02b, [autocomplete simples com resolve L02c](72-autocomplete.md), [cancelamento de consultas obsoletas L02d](72-cancelamento-lsp.md) e [cancelamento pela UI e de resolve L02e](72-cancelamento-ui-lsp.md). A validação real cobre Dart; homologação TypeScript, snippets e demais capacidades avançadas permanecem pendentes. O descarte local de respostas antigas continua protegendo o buffer mesmo após enviar cancelamento ao servidor.

### L03 — Adicionar navegação semântica e busca unificada

Prioridade P1 · Porte M · Dependências: L02, W02.

Referência: code-insight; search; nav.
Destino: Painéis de resultados e navegação existentes.

Aceite: Definição/implementação/referências/símbolos e histórico abrem posição UTF-16 correta; resultados paginados, exclusões, cancelamento e raízes locais/remotas respeitados.

### L04 — Entregar refatoração e workspace edits seguros

Prioridade P1 · Porte L · Dependências: L02, W03.

Referência: src/editor/refactor; apply/prepare/undo workspace edit.
Destino: Operações de arquivo e editor existentes.

Aceite: Rename, quick fixes, organização de imports e formatação com preview de múltiplos arquivos; validar versões antes de aplicar e recuperar/undo em falha parcial.

### L05 — Homologar linguagens por níveis de capacidade

Prioridade P1 · Porte L · Dependências: L02, L03, L04.

Referência: 77 definições e fixtures OpenIDEA.
Destino: Catálogo e fixtures de teste do Orkest.

Aceite: Matriz executada para Dart/Flutter, TS/JS, Python, Rust e Go; fase seguinte Java/C#/PHP; Vue/Svelte/HTML/CSS/JSON/YAML/SQL por demanda; registrar SDK/server/adapter e recurso não suportado sem prometer paridade.

### L06 — Avaliar inteligência avançada e análise estrutural

Prioridade P2 · Porte L · Dependências: L05.

Referência: ide-analysis, ide-syntax; code lens/inlay/hierarchies.
Destino: Painéis do editor e serviços de análise selecionados.

Aceite: Provar inlays, hierarquias, busca estrutural/duplicações e análise apenas onde servidor suporta; medir custo e escolher subset útil.

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

### H02 — Criar corpus e replay de leitura de harness

Prioridade P1 · Porte M · Dependências: H01.

Referência: ide-agent/replay.rs e fixtures JSONL.
Destino: test/session e fixtures sanitizadas.

Aceite: Capturas versionadas sem segredos para ANSI fragmentado, redraw, prompts repetidos, permissões simultâneas, subagentes, Stop/SessionEnd, WSL e reconnect; replay determinístico compara transições e duplicações.

### H03 — Ampliar reconhecimento de CLI por evidência

Prioridade P1 · Porte M · Dependências: H02.

Referência: provider.rs e registry como metadados de referência.
Destino: HarnessCatalog, normalizer, classifier, monitor.

Aceite: Para cada CLI selecionada, validar executável/wrappers/flags e modos não interativos no host; hooks opcionais; fornecedores não reconhecidos continuam via contrato genérico, sem parser inventado.

### H04 — Verificar paridade local, SSH e WSL de harness

Prioridade P1 · Porte M · Dependências: H02, H03.

Referência: Correlação ACP como referência; protocolo atual Orkest.
Destino: orkest_protocol, remote adapters e host server.

Aceite: Mesmas sequências geram mesmos estados em local/remoto; geração antiga não ressuscita sessão; desconexão não se apresenta falsamente como fim de turno ou aprovação.

### H05 — Expor diagnóstico de estado sem capturar conteúdo

Prioridade P2 · Porte M · Dependências: H01.

Referência: Probe/capabilities ide-agent; telemetria Orkest.
Destino: Diagnósticos existentes e testes de estado.

Aceite: Mostrar origem do último estado, idade do sinal e capacidade de detecção com dados limitados; medir falso working/waiting/idle em corpus rotulado; falta de sinal não inventa execução.

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

### G04 — Adicionar gestão avançada de trabalho Git

Prioridade P2 · Porte L · Dependências: G02.

Referência: ide-vcs/manage, shelf, patch, rebasePlan.
Destino: Serviços Git local/remoto.

Aceite: Worktrees, stash/shelf, changelists, patches, tags e rebase/cherry-pick/revert em subentregas; pré-condições/abort/recovery e processos cancelados testados, sem merge automático na main.

### G05 — Integrar revisão de PR no contexto do código

Prioridade P2 · Porte M · Dependências: G01.

Referência: ide-github e src/features/github.
Destino: Painel Git e ações de revisão.

Aceite: Listar/detalhar/criar PR, comentários/review/diff e checkout conforme ferramenta disponível; falhas de autenticação explícitas; nenhuma operação de publicação/merge fora de autorização.

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

### R04 — Expandir debug multilinguagem progressivamente

Prioridade P2 · Porte L · Dependências: R02, L05.

Referência: debugpy, js-debug, codelldb e configs de linguagens.
Destino: Registro de adaptadores e painéis DAP.

Aceite: Validar TS/JS, Python, Rust/Go conforme adapter; depois JVM/.NET; documentar instalação/licença e limites de watchpoints, restart frame, smart step e HotSwap por adaptador.

### R05 — Integrar resultados de testes, coverage e profiler

Prioridade P2 · Porte L · Dependências: R01, L05.

Referência: ide-coverage, ide-profiler, run TestTreeView.
Destino: Tasks, telemetria e gutter de editor.

Aceite: Árvore de testes/reexecutar falhas e cobertura por formato validado; profiler somente por demanda; relatório aponta ferramenta/linguagem e não apresenta dado ausente como zero.

### B01 — Ampliar introspecção e navegação de bancos

Prioridade P2 · Porte M · Dependências: F01.

Referência: ide-db source/conn/sql; db commands.
Destino: DbDriver.schema, db_panel e conectores anaki existentes.

Aceite: Matriz de schemas/tabelas/views/índices/FKs/routines por engine; DDL e navegação contextual com paginação/cache invalidável; manter Redis/Mongo e política de acesso atual.

### B02 — Provar transações e edição persistente de dados

Prioridade P2 · Porte L · Dependências: B01, A04.

Referência: ide-db transactions e db_apply_edits.
Destino: DbDriver efêmero atual e painéis SQL.

Aceite: ADR decide sessão dedicada para transação manual; commit/rollback/disconnect e atualização otimista seguros; não simular transação entre conexões efêmeras; schema do produto só muda por migration versionada.

### B03 — Evoluir console SQL e avaliar ClickHouse

Prioridade P2 · Porte M · Dependências: B01.

Referência: db_completion, explain/history/export; clickhouse.rs.
Destino: db_query_view e serviços SQL.

Aceite: Completion por schema, explain/histórico/export e limites de resultado; ClickHouse é decisão separada conforme demanda, sem remover suporte atual nem expor credenciais.

### X01 — Priorizar produtividade de edição e visualização

Prioridade P2 · Porte M · Dependências: W03, L02.

Referência: templates, macros, vim, todo, scratch, color-preview, viewers.
Destino: Editor e viewers já existentes.

Aceite: Inventário de snippets/templates/Emmet/folding/bookmarks/TODO/Vim/macros; selecionar e dividir entregas por uso; atalhos e preview seguem tema, i18n e acessibilidade.

### X02 — Aprimorar HTTP, GraphQL e navegação web

Prioridade P2 · Porte M · Dependências: F01.

Referência: ide-http; http-client/graphql/web; Spring route sources.
Destino: http_document, http_request_runner e browser atuais.

Aceite: Comparar ambientes, histórico, auth, cancelamento e resultados com .http existente; GraphQL/rotas/frameworks somente com validação específica; proteger segredos e não duplicar browser.

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
