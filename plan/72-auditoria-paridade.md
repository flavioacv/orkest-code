# Plano 72 — auditoria de paridade e primeira entrega

Data: 04/11/2026. Base Orkest: commit `8d01a751`; referência OpenIDEA: `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. Inspeção de código local, complementada pelos testes executados na entrega. Não representa homologação manual de todos os servidores/hosts/CLIs.

## Diretriz de execução confirmada

O usuário autorizou agregar funcionalidades preservando a base atual. Mudanças visuais e otimizações especulativas ficam para avaliação futura. Provas de backend necessárias para um recurso continuam possíveis, mas benchmarks e migração da engine visual não bloqueiam o trabalho funcional em Dart. O workspace continua baseado em busca/alternância de projetos e o caminho de agentes permanece o terminal.

## Matriz de paridade

E = existente com caminho identificado; P = cobertura parcial frente à referência; A = camada equivalente não encontrada na busca; NV = escopo/comportamento ainda não validado. Nenhum A afirma impossibilidade ou ausência absoluta de código fora da inspeção.

| Recurso | Estado | Evidência no Orkest | Próxima ação |
|---|---|---|---|
| Buscar/abrir/alternar projetos | E | projects_rail, workspace_actions, JsonProjectRepository | W01 preserva o modelo e testa jornada |
| Estado/layout e arquivos abertos | E | JsonWorkspaceLayoutStore, FileViewerSession, document host | W03 valida dirty buffers, restauração e multi-janela |
| Editor alternativo e arquivos especiais | E | FileEditorFacade e registry; FileEditorEngine orkest/neovim | Manter fallback, remoto, mídia, HTTP/DBQ/Kanban e notebooks |
| Navegação entre workspaces | E | workspace_cycle e ações/menu | Não trocar home/rail por estrutura do OpenIDEA |
| Catálogo de linguagens | P | kLanguageDefs antes desta entrega: 9; Settings consome catálogo | Primeira entrega amplia para 17 sem instalar servidores |
| LSP pool/handshake e sync | E | core/data/lsp, openDocument/didChange/close, lifecycle por raiz | A01/L02 evoluem capacidades sem duplicar owner |
| Diagnósticos e semantic tokens | E | file_viewer integra diagnósticos e tokens no editor | L05 precisa homologar cada servidor |
| Formatação e formatação ao salvar | E | file_viewer._format, lsp_formatter e overrides por linguagem | Preservar formatadores e distinção JSON/JSONC |
| Go to definition | E | code_editor callbacks, LspClient.definition e navegação | L03 amplia referências/símbolos/implementações |
| Completion/hover semântico/signature help | P/NV | Há cliente request genérico; hover examinado é de diagnósticos | L02 precisa UI/cancelamento/posicionamento e teste real |
| Rename/code actions/workspace edit | P/NV | lsp_text_edit aplica edições de formatação; não comprova refatoração completa | L04 integra preview, versão e undo multi-arquivo |
| Busca de arquivos/conteúdo | E | file_searcher_impl, content_searcher_impl em isolate, painéis | L03 melhora navegação; M02 só se necessidade de desempenho |
| Busca estrutural/duplicações | A | Nenhuma camada equivalente a ide-analysis identificada | L06 após núcleo LSP |
| Status/stage/commit/branches/Git diff | E/P | GitController, ações no VM, leitores e diff viewer | G01 adiciona revisão/staging por hunk sem substituir base |
| Worktrees | E/P | Worktree/merge remoto já aparecem no VM e adapters | G04 deve auditar o existente antes de criar outra gestão |
| Histórico/revert/desfazer commit | E/P | git_history_reader e git_history_panel | G03 amplia grafo/filtros/autoria/seleção |
| Merge visual 3-way/rebase avançado | A/NV | Não identificada UI equivalente ao MergeEditor/rebasePlan | G02/G04 com recuperação e preservação de conteúdo |
| PR/review integrado | A/NV | Não encontrada UI equivalente à feature GitHub examinada | G05, sem duplicar comandos de terminal existentes |
| Tasks/execução e console PTY | E | task_discovery, flutter/npm adapters, pty_task_runner e remoto | R01 amplia configurações e execução contextual |
| DAP genérico/UI de debugger | A | Não encontrada camada equivalente a ide-dap; há telemetria VM/inspector | R02/R03 com Dart/Flutter antes de expandir adapters |
| Árvore de testes/coverage/profiler | P/NV | Tasks e telemetria não comprovam apresentação completa dos resultados | R05 seleciona formatos e integrações úteis |
| Terminal/emulador/PTY | E | Ghostty/flterm, xterm e orkest_pty existentes | Preservar; não incorporar outro motor de terminal |
| Identidade e leitura de harness | E/P | monitor/classifier/normalizer, hooks, TerminalSession e activity | H01-H05; catálogo de provedores não equivale a detecção universal |
| Espera versus execução | E/P | Correção 8d01a751: evento estruturado prevalece sobre redraw | H00 ainda exige revisão/integração e validação real |
| Serviços local/remoto | E | orkest_protocol/engine/server e adapters SSH | Ampliar contratos existentes antes de propor host substituto |
| Bancos SQL | E/P | anaki Rust/FFI, DbDriver, db_panel/db_query_view | B01 amplia introspecção/DDL/explain por engine |
| Transações manuais persistentes | A/NV | DbDriver documenta conexão efêmera por operação | B02 exige ADR de sessão; não simular transação entre conexões |
| Redis/Mongo | E | NosqlCommandRunner, db_redis_table/db_mongo_view | Preservar; referência OpenIDEA não os substitui |
| HTTP e browser | E/P | http_document/request_runner, browser/webview | X02 faz comparação de ambientes/histórico/auth/cancelamento |
| GraphQL/rotas web | NV | Não auditada paridade com recurso específico da origem | X02 define demanda e cobertura por framework |
| Docker/build/deployment | P/NV | Tasks Compose, SSH e remoto já presentes | X03 audita antes de ampliar; deployment não autorizado implicitamente |
| Notebooks/viewers/scratch | E/P | Documentos/viewers e fallback FileEditorFacade já existem | X04 compara execução de kernel, não só edição do arquivo |
| Templates/macros/Vim/bookmarks/TODO | P/NV | Editor e Neovim existentes; não auditada paridade por ação | X01 refina entregas individuais |
| Plugin WASM e API de extensões | A/NV | `.panel` e CLI são extensibilidade existente, não equivalem à API WASM | X04 precisa RFC de API/permissões antes de incorporar runtime |
| Settings/tema/i18n/atalhos | E | Settings, slang, ações/menu | Preservar; sem redesign nesta execução |
| Confiança/proveniência e lifecycle | P | Controles por operação e contratos existentes; paridade não auditada | F02/A01/A05 por componente selecionado |
| Desempenho/diagnóstico | E/P | Telemetria e diagnósticos existentes | Sem promessa de ganho Rust; otimização quando necessidade identificada |

## Cenários de preservação

| Jornada | Evidência atual | Verificação necessária para entrega integrada |
|---|---|---|
| Buscar projeto e abrir arquivo | Rail + ações + façade | Busca real, abertura sem perder contexto/abas; W01 |
| Alternar projetos com terminais ativos | workspace_cycle + sessões por projectId | Estado/host correto e nenhum evento cruzado; W01/H04 |
| Restaurar projeto e arquivos | Stores JSON + document host | Dirty buffers, layout e arquivos movidos; W03 |
| Abrir projeto remoto | remote_workspace_controller + adapters/server | Reconexão, erros de host e servidor ausente; H04/A05 |
| Usar outro motor de edição | Registry orkest/neovim + fallback por arquivo | Arquivos especiais/remotos continuam no fluxo atual; teste façade |
| Abrir nova linguagem | Catálogo -> pool -> settings/file viewer | Testes de resolver e pool com overrides; teste real do servidor separado |

Esta auditoria registra o estado e os cenários; os cenários de GUI/remoto não executados continuam pendentes nas atividades de homologação. Não marcar W01/Q01 concluídas apenas porque seus pontos de entrada existem.

## Recorte de proveniência F02

O arquivo `72-openidea-proveniencia.json` registra SHA-256 e tamanho de 368 arquivos candidatos (core, JSON-RPC, language, VCS, DAP, host, search/index/VFS, configurações de linguagem e algoritmos selecionados), junto do commit da origem e dos avisos LICENSE/NOTICE/THIRD_PARTY_LICENSES/Cargo.lock. Todos estão marcados como referência, não importados.

Nenhum crate, asset ou componente React foi incorporado nesta entrega. Foram implementados perfis declarativos no catálogo Dart existente usando os nomes de servidores e convenções examinados. Não houve instalação de ferramentas, nova dependência ou alegação de autorização jurídica para dependências transitivas. Antes de copiar um componente futuro, revisar licenças transitivas e preservar seus avisos no produto; o manifesto de candidatos não substitui essa revisão.

## Primeira entrega funcional do catálogo

- HTML, CSS, SCSS, Less, JSON, JSONC, YAML e Shell Script passam pelo catálogo e aparecem no Settings já existente.
- Nomes específicos precedem extensão: `tsconfig.json`/`jsconfig.json` e configurações selecionadas são JSONC; arquivos como `.bashrc` e `.clang-format` são reconhecidos.
- Comandos/argumentos continuam separados e overrides do usuário são preservados. Perfis CSS/SCSS/Less compartilham executável padrão, mas mantêm languageIds distintos.
- Raiz segue o resolvedor existente com fallback para workspace. A detecção considera caminhos POSIX e Windows sem depender do SO local.
- O catálogo não instala o servidor e não garante diagnóstico/formatação se a ferramenta não estiver disponível ou não oferecer a capability. Vue e Svelte continuam pendentes de integração específica, em vez de anunciar paridade por extensão apenas.

L01 permanece parcial: catálogo declarativo ampliado, mas modelagem de capacidades/SDK/adaptadores e homologação runtime por linguagem continuam no backlog. As validações executadas devem ser registradas no comentário da entrega no Kanban.
