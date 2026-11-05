# OpenIDEA: mapa inicial de ferramentas e escolha Dart/Rust

Data: 04/11/2026. Projeto considerado: `/Volumes/Externo 1/projetos/zurc/openidea`, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. O pedido menciona “Open Hands”; pelo histórico, foi assumido OpenIDEA enquanto se aguarda esclarecimento. Este documento não é um inventário do produto OpenHands.

## Resultado e alcance

Foram identificados 40 diretórios de funcionalidades de interface, 35 crates, 77 definições de linguagem e 510 funções explicitamente anotadas como comandos Tauri, distribuídas em 41 arquivos de domínio. São contagens de estrutura e declarações, não de ferramentas independentes, comandos registrados em runtime ou recursos homologados.

O catálogo `OPENIDEA_CATALOGO_TECNICO.md` lista cada comando com arquivo e linha e relaciona linguagens/servidores/adaptadores. `OPENIDEA_INVENTARIO.json` fornece os mesmos dados estruturados. `ANALISE_OPENIDEA_ORKEST.md` aprofunda Git e debug e registra os pontos já existentes no Orkest.

Este é um mapa inicial de toda a superfície por domínio. A extração de comandos não cobre ações exclusivamente frontend, geração por macros ou todos os comportamentos internos. A matriz abaixo complementa esse limite com os módulos de interface. Não houve execução da aplicação nem testes de integração.

## Mapa funcional

As referências abaixo são relativas à raiz do OpenIDEA. R significa candidato a reaproveitamento de backend Rust; D significa implementação/adaptação no Dart/Flutter do Orkest; H significa combinação. São recomendações, não decisões aprovadas. P1 = núcleo de programação; P2 = evolução posterior; P3 = adotar somente havendo demanda. Prioridade não representa esforço.

| Domínio / módulos de interface | Ferramentas e potencial para o desenvolvedor | Evidência principal | Estratégia / prioridade |
|---|---|---|---|
| Projeto e arquivos (`project-tree`, `welcome`, `app`) | Abrir projeto, explorar e operar arquivos, recentes, raízes, estado da aplicação | `commands/fs.rs`, `workspace.rs`, `app.rs`; `ide-vfs`, `ide-workspace` | D: manter integração com workspace atual; P1 |
| Edição (fora de `features`, em `src/editor`) | Documentos, abas, salvar/recarregar, sincronização com disco, undo/redo, seleção, folding e navegação | `src/editor/core`; `commands/doc.rs` | D: widgets e modelo de edição precisam integrar o editor Flutter; P1 |
| Inteligência (`code-insight`) | Completion/inline completion, hover, assinatura, definição/implementação, referências, símbolos, highlights, links, inlays, code lens, semantic tokens, hierarquias | `commands/lsp.rs`, `ide-lsp`, `src/editor/lsp` | H: preservar cliente atual e avaliar serviços adicionais; P1 |
| Refatoração (`src/editor/refactor`) | Rename, ações, workspace edits com undo/redo, movimentação de arquivos, introduce/safe delete conforme servidor ou fallback | `commands/refactor.rs`, `lsp.rs`; `src/editor/refactor` | H: UI e confirmação de alterações em Dart; P1 |
| Busca (`search`) | Texto/regex, substituição com preview, arquivos/diretórios/símbolos, escopos, máscaras, recentes e bookmarks | `commands/search.rs`, `nav.rs`; `ide-search`, `ide-index` | H: Rust é candidato para varredura/indexação, Dart para resultados; P1 |
| Análise (`analysis`) | Inspeção de código, localização de duplicações, busca estrutural e validação por linguagem | `commands/analysis.rs`, `ide-analysis`, `ide-syntax` | R/H: medir valor por linguagem e custo; P2 |
| Git (`vcs`) | Status, raízes, branches, staged/unstaged, revisão, hunks, commit parcial, amend, diff, blame, histórico e grafo | 76 comandos explícitos em `commands/vcs.rs`; `ide-vcs`; `src/features/vcs` | H: backend Rust seletivo e interface Dart; P1 |
| Git avançado (`vcs`) | Merge/conflitos, rebase, gestão de operações, tags, remotes, worktrees, stash, shelf, changelists e patches | `ide-vcs/src/{lib,ops,manage,shelf,patch,changelists}.rs` | H; conflitos/hunks P1, demais P2 |
| Histórico local (`vcs`) | Inspecionar/restaurar histórico independente de commits Git | `commands/history.rs`; `LocalHistory.tsx` | H: conferir retenção e integração com documentos; P2 |
| GitHub (`github`) | Repositórios da conta, listar/detalhar/criar PR, checkout, comentários, reviews, preparação de diff e acesso API | 11 comandos em `commands/github.rs`; `ide-github`; `src/features/github` | H: requer `gh` e autenticação; P2 |
| Execução (`run`, `run-anything`) | Configurações/templates, importação, início/parada, stdin, resize, relatórios de testes, console e execução contextual | 25 comandos em `commands/run.rs`; `ide-run` | H: integrar aos tasks atuais; P1 |
| Debug (`debugger`) | Launch/attach, threads, stack, scopes, variáveis, modificar variável, avaliar/completar expressão, breakpoints, step/pause/resume, run to cursor | 30 comandos em `commands/debug.rs`; `ide-dap` | R/H: candidato mais forte para evitar reimplementação; P1 |
| Debug avançado (`debugger`) | Exceções, funções e data breakpoints, smart step, reset de frame, processos anexáveis, listener JVM e HotSwap | `debug_capabilities`, `debug_set_data_breakpoints`, `debug_restart_frame`, `debug_redefine_classes` | R/H: depende do adaptador; P2 |
| Testes/serviços (`run`, `services`) | Árvore de testes, resultados, organização de processos e serviços, associação com execução/debug | `src/features/run`, `services`; `run_test_reports` | H: UI compartilhada com tasks; P1/P2 |
| Build (`build`, `build-tools`) | Modelo/sync de build, executar tarefas, Gradle/Maven, dependências e catálogos | `commands/build.rs`; `ide-build`; `src/features/build-tools` | H: adoção por ecossistema; P2 |
| Dependências e bibliotecas (`dependencies`, `libraries`) | Consulta/modelagem de dependências e bibliotecas de projeto | `commands/dependencies.rs`, `sdk.rs`; features correspondentes | H; P2 |
| SDKs/ferramentas (`tools`) | Detectar SDKs, localizar ferramentas, ambiente Python, venv/pacotes, gerenciar servidores e configurações | `commands/sdk.rs`, `tools.rs`; `ide-sdk`, `ide-tools` | H: preservar SDKs/configuração do usuário; P2 |
| Coverage (`coverage`) | Preparar execução instrumentada, coletar/importar cobertura, relatórios e gutter | `commands/coverage.rs`; `ide-coverage`; `src/features/coverage` | R/H: cobertura não é universal por linguagem; P2 |
| Profiler (`profiler`) | Preparar/coletar execução com profiler, exibir dados de perfil | `commands/profiler.rs`; `ide-profiler` | R/H: depende de profiler externo; P3 |
| Terminal (`terminal`) | Sessões PTY, entrada, resize, saída e apresentação de terminal | `commands/term.rs`; `ide-terminal` | D: Orkest já tem terminal; evitar duplicar motor; P1 de integração |
| SSH (`ssh`) | Testar conexão, segredos, confiança de host, desconectar, askpass, credenciais Git e comando de terminal SSH | `commands/ssh.rs`; `ide-ssh` | H: comparar com infraestrutura remota atual; P2 |
| Remoto (`remote-dev`) | Backend perto do projeto, transporte remoto, mapeamento e operações do host | `ide-host/src/bin/server.rs`, `rpc.rs`; `ide-remote` | R/H: potencial de backend comum local/remoto; P2 |
| Deployment (`deployment`) | Upload/download/exclusão remota, comparação e plano de sincronização | 15 comandos em `commands/deploy.rs`; `ide-remote`, `ide-ssh` | R/H; P3 |
| Banco (`database`) | Fontes/segredos, conexões, bancos/schemas/tabelas/objetos, DDL, explain, SQL completion, histórico, paginação, edição e transações | 28 comandos em `commands/db.rs`; `ide-db` | D/H: comparar com ferramentas de banco existentes no Orkest; P3 |
| Docker (serviços/backend) | Snapshot, ações de container, inspect, logs/eventos, pull, prune, Compose, registry e ambiente de execução | 14 comandos em `commands/docker.rs`; `ide-docker` | H: requer engine/acesso e credenciais; P3 |
| HTTP (`http-client`) | Parsing de requisições, ambientes, executar/cancelar, respostas/histórico e teste de proxy | `commands/http.rs`; `ide-http`; `src/features/http-client` | D/H: comparar com `.http` atual; P2/P3 |
| Rotas web (`http-client`, `web`) | Fontes de rotas Spring, navegação e resolução de referências web | `commands/nav.rs`; `ide-host/src/ops/routes.rs` | H: suporte específico, não descoberta universal de APIs; P3 |
| GraphQL (`graphql`) | Módulo de edição/estado e integração GraphQL | `src/features/graphql` | D/H: verificar cobertura de introspecção/execução antes de prometer paridade; P3 |
| Navegadores (`web`) | Enumerar browsers, resolver URL e abrir conteúdo | `commands/web.rs`; `ide-web` | D: aproveitar browser/preview existente; P3 |
| Notebooks (`notebook`) | Abrir/editar/salvar/recarregar, undo/redo, executar célula, interromper e reiniciar kernel | 11 comandos em `commands/notebook.rs`; `ide-notebook` | H: interface própria e kernel Jupyter externo; P3 |
| Visualização (`viewers`) | Markdown/Mermaid e visualizadores especializados de arquivos | `src/features/viewers`; `src/editor/core/customDocuments*` | D: preservar viewers existentes; P2/P3 |
| Arquivos temporários (`scratch`) | Scratch files e fluxo de edição/execução rápida | `src/features/scratch`; `run` | D; P2 |
| Templates (`templates`) | Templates de arquivo e código, snippets, live/postfix templates, surround e Emmet | `src/features/templates` | D: regras e interação com seleção do editor; P2 |
| Produtividade (`vim`, `macros`, `todo`, `color-preview`) | Modo Vim, macros, busca de TODO e preview de cores | Features correspondentes | D: dependem da superfície de edição; P2/P3 |
| Plugins (`plugins`) | Catálogo/market, instalar/habilitar/desinstalar/recarregar, permissões, secrets, eventos, painéis, comandos, temas/ícones/linguagens | 39 comandos em `commands/plugin.rs`; `ide-plugin`, `ide-extension`, `wit`, `sdk` | H: runtime Rust possível, UI/contribuições exigem adaptação; P3 |
| Agentes (`agents`) | Provedores/configuração, tarefas, prompt/fila, fork/rollback, cancelamento/respostas, arquivo e mudanças | 24 comandos em `commands/agent.rs`; `ide-agent` | D/H: avaliar recursos individuais frente à orquestração atual; P2/P3 |
| Preferências (`settings`) | Configurações, aparência, atalhos, servidores, escolhas de ferramentas e armazenamento | `src/features/settings`, `src/platform`, comandos de app | D: manter fonte de configuração do Orkest; P1 |
| Confiança (`project-trust`) | Controle de confiança do projeto antes de operações que executam ferramentas | `src/features/project-trust`, `ide-host/src/trust.rs` | H: integrar ao fluxo existente; P1 de infraestrutura |
| Workbench/janelas (`app`, `welcome`) | Painéis, overlays, status, múltiplas janelas/grupos e contribuições | `src/workbench`, `commands/window.rs`, `window_group.rs` | D: comportamento Flutter; P2 |
| Desempenho (`perf`) | Instrumentação, relatórios e ferramentas de verificação | `commands/perf.rs`; `perf`, `src/features/perf` | D/H: medir no Orkest, não herdar números da origem; P1 de validação |

## O que realmente se reaproveita

1. **Backend Rust:** código de domínio e seus testes, mediante análise das dependências e contratos. Não basta copiar uma crate: há tipos, estado, eventos, storage e serviços do host.
2. **Protocolos externos:** Git CLI, `gh`, LSP, DAP, SSH, kernels e ferramentas de build. Muitas capacidades dependem desses programas; Rust não implementa sozinho toda a inteligência de cada linguagem.
3. **Algoritmos frontend:** parte de diff/merge, histórico e interação está em TypeScript. Reaproveitar só `ide-vcs` não entrega automaticamente o editor visual de conflitos nem todos os algoritmos da UI.
4. **Interface:** React/CodeMirror não vira widget Flutter diretamente. Telas, atalhos, foco, seleção, árvore de variáveis e painéis precisam ser adaptados ao Orkest.
5. **Testes e fixtures:** casos de regressão são material valioso para reproduzir comportamento em uma integração ou port Dart. Devem ser executados na implementação escolhida.

## Parecer Dart versus Rust

**Recomendação inicial: arquitetura híbrida. Flutter/Dart continua responsável pelo produto e pela interação; Rust é candidato para serviços complexos já existentes e serviços que se beneficiem de processamento nativo.** Não há evidência que justifique reescrever todo o Orkest nem portar todo o OpenIDEA para Dart.

| Critério | Tudo em Dart | Dart + processo Rust | Dart + FFI Rust |
|---|---|---|---|
| Reaproveitar OpenIDEA | Reimplementação relevante de domínio | Aproveita host/RPC existente, com adaptações | Aproveita crates, exige API própria |
| Complexidade inicial | Menor para UI e serviços simples; maior para paridade ampla | Ponte, versão e supervisão de processo | ABI, memória, async e callbacks |
| Falhas do backend | Compartilha processo, salvo uso de isolates/processos auxiliares | Falha pode ser isolada e processo reiniciado | Falha nativa pode encerrar aplicação |
| Desenvolvimento remoto | Requer desenho específico | Alinha-se ao servidor stdio existente | Precisa de transporte adicional |
| Distribuição | Flutter mais ferramentas externas | Flutter, binário Rust por plataforma e ferramentas | Bibliotecas nativas por plataforma e ferramentas |
| Desempenho | Adequado para UI/orquestração; medir workloads pesados | Serialização/IPC: paginar e agrupar respostas | Menor custo potencial de chamada; medir antes de assumir ganho |
| Manutenção upstream | Maior divergência na portabilidade | Adaptação de protocolo e componentes | Adaptação da API e dependências de crates |

**Por domínio:** manter UI, agentes, composição de workspace, preferências e fluxo de terminal em Dart. Avaliar Rust para DAP, Git avançado, indexação/busca/análise e serviços remotos. Manter LSP atual até uma lacuna concreta justificar substituição. Banco, HTTP e terminal já existentes não devem ser trocados apenas para uniformizar linguagem.

Git CLI pode continuar sendo chamado por Dart nas operações atuais. O motivo para incorporar Rust seria reaproveitar comportamento complexo testado, não uma suposta necessidade de Rust para executar Git. Da mesma forma, DAP pode ser implementado em Dart; o benefício potencial de Rust está no trabalho já realizado em sessões, adapters e lifecycle.

## Experimento que decide a arquitetura

Antes de tornar a recomendação definitiva:

1. Conferir o registro remoto dos comandos necessários; 510 comandos Tauri não implicam 510 comandos no servidor.
2. Conectar um cliente Dart ao `openidea-server --stdio`: handshake de versão, abrir projeto, obter status Git e receber invalidação/eventos.
3. Exercitar diff e staging parcial em repositório de teste, com cancelamento e preservação de alterações não selecionadas.
4. Exercitar DAP: iniciar Dart, breakpoint, pause/step, stack/variáveis, finalizar e limpar processo. Flutter exige teste próprio de launch/attach e hot reload/restart; a configuração Dart não prova esse suporte.
5. Medir startup, memória, tráfego, latência e recuperação de falha nos sistemas desktop suportados pelo Orkest. Definir limites antes da medição com base no orçamento do produto, sem inventar números neste relatório.
6. Estimar dependências transitivas e empacotamento do host inteiro versus host reduzido. O servidor atual é candidato de prova, não automaticamente o binário final a distribuir.

Se a prova funcionar e o custo operacional for aceitável, seguir com processo Rust. Se a ponte expuser acoplamento excessivo, extrair somente VCS/DAP ou manter esses serviços em Dart. Considerar FFI apenas se houver necessidade mensurada ou uma API nativa já adequada.

## Limites e próxima especificação

Nenhuma integração foi implementada ou aprovada. Inventário baseado em código local, sem download de dependências e sem alterações em código existente. Licença declarada Apache-2.0; o material incorporado deve manter a proveniência de `LICENSE`, `NOTICE` e `THIRD_PARTY_LICENSES.md` conforme seu conteúdo.

A especificação de implementação deve transformar cada recurso escolhido em um fluxo humano observável: entrada, ação, resultado, falha/cancelamento, persistência e contrato com os agentes. Essa etapa evita importar muitas telas sem uma experiência de programação consistente.
