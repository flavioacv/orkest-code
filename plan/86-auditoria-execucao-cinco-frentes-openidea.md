# Auditoria e execução inicial das cinco frentes OpenIDEA → Orkest Code

**Data:** 09/11/2026  
**Escopo:** comparação estática do OpenIDEA local (HEAD `8021a8cc`) e do Orkest Code (branch `main`, HEAD inicial `9a91b946`), correções no quadro, integração de Explain/histórico SQL e validação local direcionada.  
**Limites:** sem credenciais GitHub/DB fornecidas, sem integração com serviço externo nesta etapa. Nenhum commit, branch ou PR foi criado.

## 1. Kanban e estado das entregas

- Removida a segunda ocorrência duplicada do cartão E7 em `plan/73-frontend.kanban`.
- E7 permanece em revisão porque a homologação ponta a ponta da aplicação ainda não está demonstrada. Os testes históricos descritos no cartão não devem ser interpretados como teste com GitHub autenticado ou serviços DB externos.
- Criados cartões B04 (Explain e histórico SQL), B05 (transação manual com conexão física comprovada), V02 (auditoria visual com capturas) e A06 (interop Rust com servidor real e distribuição). B04 foi implementado localmente nesta rodada e movido para Concluídas.
- E4 corrigido: Redis e MongoDB possuem painéis de UI no Orkest (`db_redis_table.dart` e `db_mongo_view.dart`). O comentário antigo em `DbEngine.isSql` que os chamava de CLI-only foi atualizado; os painéis ainda precisam de homologação com servidores reais.

## 2. Homologação possível nesta máquina

Na rodada anterior, as suítes direcionadas exercitaram processos Git reais em repositórios temporários, serviços/widgets Database e o adaptador DAP Dart instalado: **67 testes passaram** em 10 arquivos. Após integrar B04, **31 testes passaram em 4 suítes Database** (`db_widgets_test`, histórico, Explain e transação), incluindo dois novos testes de widget para Explain sem ANALYZE e restauração do histórico. São execuções distintas, não somadas como se fossem uma só rodada. Isso não equivale a conectar GitHub, bancos de produção, todos os engines ou todos os adaptadores DAP.

`dart analyze --fatal-infos lib test` apontou 2 infos em `lib/app/orkest/ui/widgets/habblaud_world_webview.dart:782` (`clearCache` deprecated) e `:787` (`BuildContext` após async), fora dos arquivos alterados. Não havia processo Flutter de debug/DTD conectado para hot reload; portanto não foi feita validação visual em runtime nesta rodada.

Pendências externas que continuam em E7:
- credenciais e fluxo autenticado do provedor GitHub;
- conexões reais PostgreSQL/MySQL/SQL Server/ClickHouse/Redis/MongoDB e SQLite representativo;
- instalação e jornada de launch/attach por runtime além da prova Dart já registrada;
- percurso único dentro da aplicação: projeto → edição/LSP → Debug → Git/PR → Database → terminal/harness.

Os resultados e as limitações dessas execuções foram acrescentados ao cartão E7 do Kanban.

## 3. Database — estado e lacunas reais

### Já existe

- Engines declarados: SQLite, PostgreSQL, MySQL, SQL Server, ClickHouse, Redis e MongoDB.
- SQL: árvore/introspecção, console `.dbq`, exportação, edição otimista de linhas e opções de conexão.
- NoSQL: visualização de chaves Redis e navegação de databases/collections Mongo têm widgets próprios.
- O domínio contém `dbExplainSql`, `DbQueryHistoryService`, `DbTransactionManager` e `DbTransactionSession`, além de testes de seus contratos.

### Ainda não integrado ou não comprovado

- `DbQueryView` agora tem ações explícitas de Explain e histórico pesquisável por conexão. O Explain executa somente a variante sem ANALYZE, exige exatamente um statement e deixa a saída somente leitura. Selecionar histórico preenche o editor sem executar a consulta.
- A integração usa `DbQueryHistoryService` com limite de 100 entradas em memória, isoladas por workspace/conexão; não grava o SQL no arquivo de conexões. Histórico não persiste após encerrar o processo.
- O manager/sessão de transação não foi encontrado ligado ao `DatabaseViewModel` ou à UI. O contrato alega sessão dedicada, mas é necessário provar que a abstração de driver mantém a mesma conexão física entre BEGIN, statements e COMMIT/ROLLBACK antes de exibir esse fluxo.
- A existência de helpers/testes não comprova suporte equivalente por dialeto, autorização nem UX de EXPLAIN ANALYZE. O plano não pode ser executado automaticamente porque alguns dialetos executam a query analisada.
- Redis/Mongo têm UI; falta homologar paginação, filtros, erros, operações mutáveis e conexões reais. Não chamar esses engines de CLI-only.
- Diagramas relacionais são funcionalidade futura; antes, confirmar metadados e relações disponíveis nos drivers atuais.

## 4. Comparação visual — fontes e critério

OpenIDEA combina React/TypeScript e CodeMirror no frontend Tauri, com tokens compartilhados em `openidea/src/styles/tokens.css` e componentes de domínio em `openidea/src/features/vcs`, `debugger` e `database`. O Orkest tem componentes Flutter próprios e a identidade OpenIDEA já foi adaptada no cartão V01.

O inventário estático indica que a maior oportunidade visual não é trocar a paleta de novo: é comparar hierarquia e feedback dos fluxos de Git, Debug e Database (seleção de repositório, timeline/compare, conflitos; estados de pausa e árvore de variáveis; conexão, catálogo, query e resultado). A comparação runtime com screenshots ainda não foi feita neste incremento e ficou explicitamente no cartão V02.

Referências de implementação atual: `source_control_panel.dart`, `source_control_changes_view.dart`, `git_history_panel.dart`, `debug_panel.dart`, `db_panel.dart`, `db_query_view.dart`, `db_redis_table.dart`, `db_mongo_view.dart`.

## 5. Rust — decisão e evidência

- OpenIDEA não é um aplicativo totalmente Rust. É Tauri: UI em React/TypeScript/CodeMirror e backend modular em crates Rust.
- A inspeção local mostra `ide-vcs`, `ide-dap`, `ide-db`, `ide-index` e outros crates. Declarar um comando Tauri ou uma crate não prova automaticamente que a função está registrada, exposta ou executada na mesma forma pelo servidor stdio.
- A documentação anterior do spike informa explicitamente um `MockRustIdeHostServer`. Latência medida contra esse mock é custo do cliente/protocolo simulado, não comparação de performance de produção com o backend Rust real.
- Decisão atual: permanecer em Flutter/Dart para produto, UI e orquestração. A06 vai determinar se existe uma razão funcional concreta para integrar um processo Rust. Não migrar algoritmo/editor/UI por uniformidade de linguagem.
- Critérios para uma nova prova: servidor real; mesma sequência funcional no Dart existente e Rust; tempo total incluindo spawn/IPC/JSON; memória e binários por SO/arquitetura; cancelamento, crash/restart e confiança do workspace; licença e manutenção do fork/upstream. Se a ponte não se justificar, manter as implementações Dart atuais.

## Estado após a execução

O Kanban, e não este relatório, é a fonte de andamento operacional. B04 foi concluído no código local e validado com testes automatizados. E7 e B05/V02/A06 continuam abertos até evidência observável, incluindo serviços reais, comparação visual e servidor Rust real. A `main` não foi commitada nem publicada; as mudanças estão disponíveis para revisão local.
