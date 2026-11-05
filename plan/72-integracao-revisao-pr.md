# Integração e Revisão de Pull Requests no Contexto do Código (G05)

## 1. Visão Geral
A atividade **G05** do Plano 72 entrega ao Orkest Code uma experiência de revisão de Pull Requests totalmente integrada ao contexto do editor e do fluxo de trabalho Git local, eliminando a necessidade de alternar constantemente para interfaces web externas para tarefas essenciais de code review.

## 2. Componentes e Arquitetura

### 2.1 Modelos de Domínio (`lib/app/orkest/domain/entities/git_pull_request.dart`)
- **`GitPullRequest`**: Modela os metadados do PR (`number`, `title`, `body`, `state`, `author`, `headRef`, `baseRef`, `htmlUrl`, `createdAt`, `updatedAt`, `isDraft`).
- **`GitPrComment`**: Modela comentários na discussão do PR ou anotações inline em código (`path`, `line`, `commitId`).
- **`GitPrDetail`**: Agrega o PR com seus comentários, a lista de `GitHistoryFileChange` e o diff unificado bruto.

### 2.2 Serviço REST e Git (`lib/app/orkest/domain/services/git_pull_request_service.dart`)
- **`parseOwnerRepo`**: Extração de `owner` e `repo` suportando padrões SSH (`git@github.com:owner/repo.git`) e HTTPS (`https://github.com/owner/repo`).
- **`listPullRequests`**: Consulta os PRs remotos via REST API, com tratamento claro para status 401/403 (orientando sobre `GITHUB_TOKEN` ou `gh auth`).
- **`getPullRequestDetail`**: Carrega detalhes, arquivos alterados e comentários em paralelo.
- **`checkoutPullRequest`**: Realiza `git fetch origin pull/<number>/head:pr-<number>` e `git checkout pr-<number>`, trazendo o código completo para inspeção direta no editor do Orkest Code.
- **`addComment`**: Permite comentar na discussão geral da issue ou em linhas de arquivos específicos (`inline comments`).
- **Injeção de dependências**: Suporte a `HttpRequester` e `originUrlOverride` injetáveis para testes unitários e de widget 100% herméticos.

### 2.3 Interface do Usuário (`lib/app/orkest/ui/widgets/git_pr_review_panel.dart`)
- Layout bifurcado com lista à esquerda e painel de detalhes à direita.
- Abas comutáveis para **Descrição**, **Arquivos Alterados** (com badges visuais A/M/D/R e navegação direta) e **Comentários**.
- Botão de **Checkout Local** para abrir e rodar a branch do PR instantaneamente.
- Formulário de submissão de comentários com feedback assíncrono.

## 3. Validação
- **Testes Automatizados**:
  - `cockpit/test/domain/git_pull_request_service_test.dart`: 8 testes unitários cobrindo parsing de URL, listagem, tratamento de erros, detalhamento, criação e comentários inline/gerais.
  - `cockpit/test/ui/git_pr_review_panel_test.dart`: 2 testes de widget cobrindo renderização, alternância de abas e interação.
- **Regressão**: 27 testes da suíte completa de Git/PR aprovados sem falhas.
- **Análise Estática**: `dart analyze --fatal-infos` com zero issues.
