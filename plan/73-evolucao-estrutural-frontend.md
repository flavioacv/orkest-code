# Evolução estrutural do front-end do Orkest Code

## Objetivo e limites da análise

Análise estática dos repositórios locais OpenIDEA (`../openidea`) e Orkest Code (`cockpit`), em 05/11/2026. O objetivo é definir uma evolução integrada do ambiente do desenvolvedor, preservando o tema Orkest, o workspace de projetos à esquerda e o funcionamento dos agentes/terminais. Os fluxos abaixo são propostas de produto e arquitetura; não representam funcionalidades já homologadas. Não houve comparação visual com as duas aplicações executando nem medição de desempenho nesta análise.

A referência é o OpenIDEA local informado pelo usuário como Open IDE/OpenDE. A existência de arquivos ou testes isolados não prova integração no produto. Para o Orkest, distinguir serviço existente, widget existente e fluxo acessível ao usuário.

## Diagnóstico principal

O maior ganho não virá de novos ícones. O OpenIDEA tem um workbench com ferramentas registradas, posições e estado persistidos, ações contextuais, documentos especializados e navegação entre resultados e código. No Orkest, várias capacidades estão concentradas em componentes grandes ou não possuem ponto de entrada visível.

Evidências no estado analisado:

- `FileTreePanel` reúne Files, Search, Source Control, Database, Gallery e Telemetry, incluindo árvore, menus e composer de commit. Tem aproximadamente 4,2 mil linhas.
- `OrkestPage` concentra montagem do shell, atalhos e ligação das ferramentas, com aproximadamente 2,4 mil linhas.
- `OrkestViewModel` tem aproximadamente 7,4 mil linhas. O tamanho não é uma falha por si, mas a montagem de novas ferramentas exige atenção aos limites de responsabilidade.
- `DebugPanel`, `DebugToolbar`, `GitBlameView` e `GitPrReviewPanel` aparecem como declarações em `lib`, sem chamadas de construção encontradas. Não devem ser contabilizados como experiências completas disponíveis na tela principal.
- Database tem integração real via `DbPanel` em `OrkestPage`; não deve ser reconstruído do zero.
- Diff e Source Control já possuem melhorias funcionais. A revisão focada recém-adicionada filtra para um hunk; não equivale a navegar e revelar trechos dentro de todo o documento.
- Q01 e estudos de desempenho anteriores têm relatórios simulados/constantes. Não servem como aceite visual ou evidência de desempenho desta nova evolução.

## Arquitetura visual de destino

```text
┌─────────────────────────────────────────────────────────────────────┐
│ Comandos e contexto: projeto · branch · configuração Run/Debug       │
├──────────────┬──────────────────────────────────────┬───────────────┤
│ Workspace    │ Documentos e terminais em panes      │ Ferramentas   │
│ Orkest atual │                                      │ Arquivos      │
│              │ Código · Diff · Merge · Dados · HTTP │ Git           │
│ Projetos     │                                      │ Database      │
│ Worktrees    ├──────────────────────────────────────┤ Estrutura     │
│ Agentes      │ Área inferior opcional               │ Serviços      │
│              │ Run · Debug · Tests · Problems       │ Busca         │
├──────────────┴──────────────────────────────────────┴───────────────┤
│ Status do documento, linguagem, conexão e tarefas em andamento       │
└─────────────────────────────────────────────────────────────────────┘
```

O painel esquerdo continua com o papel atual. Documentos ricos ocupam o centro; árvores de navegação usam a direita; inspeção de execução e resultados extensos podem usar a área inferior. O terminal atual continua uma sessão/pane de primeira classe. A nova área inferior não deve duplicar nem substituir automaticamente seus terminais.

### Estrutura mínima necessária

1. Separar o host de ferramentas do conteúdo de `FileTreePanel`. Files, Git, Database e Telemetry tornam-se views com responsabilidade própria.
2. Descrever ferramentas com ID estável, título localizado, ícone, disponibilidade por contexto, badge e builder. Um catálogo interno fechado é suficiente; não criar uma plataforma de plugins nesta entrega.
3. Manter estado de seleção, filtros, expansão e scroll por workspace. Ocultar uma view não encerra uma execução; remover workspace encerra recursos que pertencem a ele.
4. Persistir visibilidade, dimensões e ferramenta ativa. Começar com direita/inferior; arraste arbitrário, janelas flutuantes e layouts nomeados só após o host estar estável.
5. Reusar a infraestrutura de comandos existente para menus, botões e atalhos. Disponibilidade de ações deve derivar do mesmo contexto: documento, root Git, host e sessão.
6. Definir identidade de recursos por workspace + host + root + caminho/sessão. Evitar cruzar conexões ou operações entre projetos com paths iguais.

Referência: OpenIDEA `src/workbench/Workbench.tsx`, `contributions.ts`, `toolwindows/store.ts`, `toolwindows/ToolWindows.tsx` e `toolwindows/layouts.ts`. O store possui slots direita/esquerda/inferior, tamanhos, splits, foco, visibilidade e ferramentas já montadas. Adaptar esses comportamentos aos contratos Dart existentes.

## Matriz de evolução por área

| Área | Referência OpenIDEA | Evolução estrutural no Orkest | Prioridade |
|---|---|---|---|
| Workbench | Tool windows, editor area, foco e layouts | Host independente para ferramentas e resultados, com persistência e lifecycle | P0 |
| Ações | Comandos/context keys e menus | Mesmo comando para toolbar, paleta, menu e atalho; disponibilidade consistente | P0 |
| Git cotidiano | CommitView, commitStore, changes | View própria com root explícita, Changes/Staged/Conflicts, seleção e composer | P0 |
| Diff | DiffEditor, diffNavigator, diffOptions | Editor de comparação completo, modos unificado/split e navegação real | P0 |
| Merge | MergeEditor, mergeModel, MergeToolbar | Documento de resolução com versões de origem e resultado editável | P0 |
| Debug | DebugToolWindow, VariablesView, DebugConsole | Conectar configuração, sessão DAP, editor, inspeção e console | P0 |
| Execução/testes | RunView, TestTreeView, EditConfigsDialog | Configuração visível e resultados navegáveis, com parar/reexecutar | P1 |
| Banco de dados | DatabaseView, TableEditor, ResultsView | Navegador, console e resultados como fluxo único | P1 |
| Histórico Git | GitLog, RevisionBrowser, SelectionHistory | Grafo, filtros, comparação de revisões e blame integrado ao editor | P1 |
| Busca e estrutura | FindToolWindow, StructureView, UsagesView | Resultados agrupados, símbolos, referências e hierarquia navegáveis | P1 |
| Diagnósticos | ProblemsView, InspectionView | Problems por projeto/arquivo, severidade, filtro e navegação | P1 |
| Serviços | ServicesHost, ServicesTree, RemoteHostView | Conexões e serviços com estado, ações e logs vinculados | P1/P2 |
| Revisão PR | github/toolwindow e reviewMode | PR, arquivos, comentários por linha e revisão dentro do diff | P2 |
| HTTP/GraphQL | HttpClientView, GraphQLView | Ambiente, execução, histórico, resposta e navegação de schema | P2 |
| Cobertura/profiler | CoverageView, ProfilerView | Resultado associado à execução e decoração no código | P2 |
| Produtividade | Templates, bookmarks, TODO, macros, Vim | Expor serviços existentes por comandos e UI; verificar integração de cada um | P2 |
| Preferências | SettingsWindow, keymap, theme | Configuração pesquisável, atalhos e opções de views consistentes | P1/P2 |
| Notebooks/extensões | notebook e plugins | Avaliação posterior, dependente de casos de uso reais | P3 |

## Entrega integrada 1 — Workbench do desenvolvedor

Resultado: abrir ferramentas, alternar entre elas e restaurar o contexto sem perder terminal, documento, seleção ou conexão.

- Extrair Source Control de `FileTreePanel` e separar o seletor de views do explorador de arquivos.
- Hosts direito/inferior com abrir, ocultar, maximizar e restaurar; título, ações e overflow uniformes.
- Indicadores de ferramenta ocupada, erro e contagem pendente; ícones existentes de uma família consistente.
- Foco visível, navegação por teclado e retorno ao editor. Não capturar atalhos destinados ao PTY.
- Estado por workspace e descarte explícito de controllers/subscriptions.
- Barras de status mostram o contexto do documento ativo, servidor de linguagem, branch/root e operação em andamento.

Aceite: alternar entre dois workspaces, abrir/fechar views, redimensionar, restaurar sessão e continuar digitando no mesmo terminal; nenhuma execução duplicada e nenhum contexto cruzado. Verificar modo compacto e zoom.

## Entrega integrada 2 — Git como ambiente de revisão

### Source Control

- Root/repositório e branch sempre identificáveis; em multi-root, ações têm escopo visível.
- Changes, Staged e Conflicts separados, com contadores e seleção explícita. Arquivo parcialmente staged pode existir em duas visões, com comparações distintas.
- Ações por arquivo, grupo e seleção; confirmação proporcional ao descarte e recuperação quando aplicável.
- Composer persistente por root, prévia do que será commitado, amend e mensagens de erro no mesmo fluxo.
- Merge/rebase/cherry-pick em andamento exibem estado, conflitos restantes, continuar e abortar.
- Changelists são opção posterior de organização local; não substituir silenciosamente a semântica real do index Git.

### Diff e merge

- Mesmo editor suporta unificado/split, versões identificadas, busca, contexto recolhível e opções de whitespace.
- Próximo/anterior revela o hunk dentro do documento; revisão focada pode ser uma opção adicional.
- Realce intra-linha, números de linha corretos, rolagem sincronizada e ações stage/unstage por trecho.
- Separar comparação Working Tree ↔ Index de Index ↔ HEAD e comparações históricas. O usuário precisa saber qual conteúdo será alterado.
- Editor de merge com Ours, Base, Theirs e Result. Base pode ser uma view opcional para evitar quatro colunas estreitas.
- Resultado editável, aceitar por bloco, desfazer/refazer, contagem de conflitos e validação antes de concluir.
- Preservar encoding, EOL e mudanças externas; recusar patch obsoleto com explicação e recarregamento.

### Histórico, autoria e PR

- Histórico com grafo de relações de commits, refs, paginação e filtros por autor/mensagem/path.
- Comparar dois commits/branches, explorar revisão sem checkout e seguir renomeações.
- Blame integrado a linhas, com commit, autor e abertura de diff/histórico.
- Conectar o painel de PR existente a um comando real; comentários devem apontar para versão, arquivo e linha corretos.
- Publicar comentário, criar PR ou fazer push são ações explícitas do usuário e mantêm a autorização vigente.

Aceite: em repositório temporário real, editar arquivo parcialmente staged, revisar ambos os diffs, preparar commit parcial e preservar o restante; resolver conflito com alteração manual e desfazer; comparar duas revisões. Validar local e remoto separadamente.

## Entrega integrada 3 — Run, Debug e Test como jornada acessível

Resultado: selecionar configuração, iniciar, interromper em breakpoint, inspecionar e navegar pelo código a partir de um fluxo da interface.

- Seletor de configuração Run/Debug com cwd, runtime e destino explícitos. Expor os produtores e loaders já implementados.
- Sessões Run/Debug identificadas por workspace e destino; indicação de inicializando, executando, pausado, encerrado e falha.
- Integrar `DebugSessionController`, `DebugPanel` e `DebugToolbar` à composição real do app e ao lifecycle do workspace.
- Breakpoints no gutter com estado solicitado/verificado/desabilitado, condições quando suportadas e acesso à lista.
- Pilha e threads selecionáveis; mudar frame atualiza scopes/variáveis e destaca a linha de execução.
- Variáveis expansíveis sob demanda, watches, evaluate e console ligados à sessão selecionada.
- Controles e menus habilitados conforme capabilities do adaptador. Suporte de catálogo não significa que o adaptador está instalado ou funcional.
- Flutter hot reload/restart são controles da sessão DAP correspondente.
- Test explorer mostra hierarquia, falha, duração, stack trace, executar novamente e cancelar. Logs continuam associados à execução.
- Coverage e profiler só são exibidos quando existem dados reais da execução selecionada.

Aceite: executar um projeto Dart/Flutter local real e um segundo adaptador instalado, parar em breakpoint, inspecionar variável aninhada, avaliar expressão, continuar e parar sem processos órfãos. Depois homologar SSH/WSL onde houver implementação; contextos sem suporte devem ser explícitos.

## Entrega integrada 4 — Database e conexões

O `DbPanel`, `DatabaseViewModel` e viewers de query/Mongo/Redis já compõem uma base existente. Evoluir sua experiência com o mesmo host de ferramentas.

- Árvore connection → database/catalog → schema → objeto → colunas/chaves/índices, conforme capacidades do engine.
- Estado conectado/desconectado/ocupado/erro e indicação clara de host e ambiente.
- Ações por nó: abrir dados, console, definição e atualizar metadados. Busca/filtros de objetos e favoritos.
- Editor SQL com conexão/schema ativos, execução da seleção/statement e cancelamento visível.
- Resultados por execução em abas: tabela, texto/JSON quando aplicável, mensagens, erros e plano de execução se suportado.
- Grid com paginação, ordenação, filtro, prévia de valores extensos, cópia e exportação.
- Edição com indicador de alterações pendentes, identificação de chave, aplicar/reverter e feedback de concorrência. Não anunciar escrita para drivers que só oferecem leitura.
- Configuração de conexão com teste, segredo mascarado e SSH quando já suportado; não unificar configurações de forma que credenciais transitem entre workspaces.
- Diagramas de relações e gráficos são evoluções posteriores; não bloqueiam o console e o grid utilizáveis.

Aceite: conectar um engine real suportado, navegar schema, executar/cancelar consulta, paginar e exportar; quando escrita estiver disponível, editar e reverter com conflito detectável. Distinguir funcionalidades por engine. Mudanças futuras de schema interno exigem migration; esta análise não altera banco.

## Entrega integrada 5 — Navegação, diagnóstico e serviços

- Search Everywhere/paleta mantém o contexto entre arquivos, símbolos, comandos e resultados recentes.
- Busca de conteúdo agrupada por arquivo com preview; referências e hierarquias usam o mesmo padrão de resultado navegável.
- Estrutura do documento ativo com símbolos, filtros e seleção sincronizada.
- Problems mostra erros/warnings do LSP por workspace, filtra por arquivo/severidade e abre a posição correta; não confundir diagnóstico de código com Telemetry de processos.
- TODO/bookmarks/templates/folding precisam de UI e comandos acessíveis, não apenas serviços de domínio.
- Services agrega recursos com lifecycle: tarefas, Docker e conexões conforme fornecedores realmente disponíveis. Cada ação abre logs/inspeção vinculados ao recurso.
- Remote Host/Ports são ferramentas próprias quando suportadas; mostrar destino e conexão para evitar operar no host errado.
- HTTP e GraphQL mantêm editores centrais, contexto de ambiente, resultados e ações no painel de ferramentas apropriado.

## Sistema visual e qualidade transversal

- Preservar `AppColors` e tipografia do Orkest. Reusar tokens semânticos para seleção, alteração Git, breakpoint, erro e conexão.
- Uniformizar alturas de linhas, áreas clicáveis, cabeçalhos, botões de ação, menus, badges e empty/error/loading states.
- Ícones devem vir dos pacotes já presentes ou de assets com proveniência verificada; não copiar indiscriminadamente o pacote gráfico da referência.
- Labels acessíveis, foco, tooltips com atalhos, teclado nas árvores/grids, contraste e suporte a zoom.
- Virtualizar árvores, grids e diffs grandes; preservar estado sem manter processos desnecessários. Medir no app real, com corpus e hardware registrados, antes de assumir ganho.
- Carregar dados sob demanda, cancelar requisições obsoletas e impedir atualização de uma view já pertencente a outro workspace.
- Internacionalizar labels e mensagens. Falhas devem oferecer ação útil: reconectar, recarregar, abrir configuração ou exibir detalhes.

## Ordem de execução e dependências

| Marco | Entrega demonstrável | Dependências |
|---|---|---|
| E1 | Host de ferramentas, contexto e foco funcionando com views existentes | Inventário de entradas/lifecycle e reaproveitamento de layout atual |
| E2 | Jornada Git completa: mudanças → diff → stage → commit → conflito | E1 e contratos Git existentes auditados |
| E3 | Jornada Run/Debug/Test acessível na interface | E1 e adaptadores reais selecionados |
| E4 | Jornada Database navegador → consulta → resultado → edição suportada | E1 e capacidades dos drivers verificadas |
| E5 | Busca, Problems, estrutura e serviços conectados ao código | E1; fontes reais de LSP/serviços |
| E6 | Histórico/PR, HTTP/GraphQL e produtividade avançada | E2/E3/E5 conforme recurso |
| E7 | Homologação e restauração completas | Jornadas anteriores executadas em build |

Cada marco entrega um fluxo completo ao usuário. É possível fazer commits internos atômicos na mesma branch, mas o marco só fica concluído com entrada visível, estado real, interação útil, tratamento de falha e demonstração em build. Os cartões antigos de serviços/widgets não devem servir como evidência automática para estes marcos.

## Estratégia de implementação e validação

- Manter a branch única `fix/harness-state-detection`, commits locais e a diretriz vigente de não abrir PR/push sem pedido.
- Criar cartões próprios para E1–E7 quando iniciar implementação desta proposta, preservando o histórico do quadro 72.
- Antes de alterar classes existentes, consultar impacto e complementar com busca de referências se o grafo não contiver a entidade.
- Para cada jornada: teste funcional que atravesse serviço real e UI quando viável, captura visual em tema Orkest, demonstração com dados reais, estados de falha/empty/loading e validação de restauração.
- Executar testes de regressão de terminal/foco ao alterar o shell. Não reconstruir indevidamente PTYs durante redimensionamento ou troca de ferramentas.
- Critérios de performance devem ser definidos a partir de baseline real: abertura, interação, cancelamento, memória e jank. Não preencher relatórios com números estimados como se medidos.

## Referências de implementação

| Domínio | OpenIDEA | Orkest |
|---|---|---|
| Shell | `src/workbench/Workbench.tsx`, `toolwindows/*`, `contributions.ts` | `cockpit/lib/app/orkest/ui/orkest_page.dart`, `widgets/file_tree_panel.dart`, `widgets/pane_view.dart` |
| Git | `src/features/vcs/{CommitView,DiffEditor,MergeEditor,GitLog,RevisionBrowser,SelectionHistory}.tsx` | `widgets/{diff_viewer,git_history_panel,git_conflict_banner,git_blame_view,git_pr_review_panel}.dart`, `viewmodels/git_controller.dart` |
| Debug | `src/features/debugger/ui/{DebugToolWindow,VariablesView,DebugConsole}.tsx`, `editor/*` | `cockpit/lib/app/core/data/dap/*`, `widgets/{debug_panel,debug_toolbar}.dart` |
| Dados | `src/features/database/{DatabaseView,TableEditor,ResultsView,Grid,SourceDialog}.tsx` | `widgets/{db_panel,db_query_view,db_connection_dialog,db_mongo_view,db_redis_table}.dart`, `viewmodels/database_viewmodel.dart` |
| Run/Test | `src/features/run/{RunView,TestTreeView,EditConfigsDialog}.tsx` | `domain/entities/run_configuration.dart`, `domain/services/run_configuration_producer.dart`, `data/tasks/launch_json_loader.dart`, `widgets/tasks_panel.dart` |
| Busca/qualidade | `src/features/search/*`, `code-insight/*`, `coverage/*`, `profiler/*` | `widgets/{command_palette,file_finder_palette,content_search_panel,telemetry_panel,code_editor}.dart` |
| Serviços | `src/features/services/*`, `deployment/*`, `remote-dev/*` | Contratos e controllers locais/remotos existentes; inventariar cada entrada antes de adicionar UI |

## Decisão proposta

Evoluir o Orkest para um workbench de desenvolvimento integrado em Flutter/Dart, usando o OpenIDEA como referência de fluxos e organização. A primeira entrega significativa deve ser E1 + E2: shell de ferramentas e experiência Git completa. Em seguida conectar Run/Debug/Test e consolidar Database. Manter tema e workspace atuais, com marcos de produto verificáveis em vez de tratar widgets isolados como IDE integrada.
