# Comparações separadas de HEAD, Index e Working Tree

## Problema corrigido

As seções Staged Changes e Changes abriam o mesmo diff combinado contra HEAD. Em arquivos parcialmente preparados, alterações do Index e do disco ficavam misturadas. A restauração de diffs locais também lia pelo project.path, mesmo quando o arquivo pertencia a outro repositório do workspace.

GitDiffTarget explicita três comparações: head preserva a API existente contra HEAD, staged usa git diff --cached e workingTree usa git diff. Staged Changes e seu menu contextual passam o alvo staged; Changes passa workingTree. Lista, árvore, clique simples e duplo clique conservam o tipo de comparação.

DiffViewerSession mantém target, com compatibilidade para o isStaged existente. Títulos e cabeçalhos mostram Index ou Working tree; histórico mantém suas referências de commits. A identidade da aba considera path, commit, target e raiz conhecida. Preview atualiza target/raiz ao ser reutilizado. Retornos depois de troca de workspace ou fechamento da pane são descartados, e a ativação de preview usa a árvore atual, preservando alterações de layout feitas durante a leitura.

O descritor de sessão agora inclui diffTarget e repoRoot também para comparações locais. A restauração usa esses campos; descritores antigos ou modos desconhecidos conservam o padrão head e resolvem a raiz pelo workspace quando disponível. Isso é evolução compatível do documento JSON de layout, sem alteração de tabelas ou banco de dados.

O leitor local valida pertencimento do caminho à raiz com package:path e reporta erros do Git com FileDiff.error. A leitura atual desativa cor, diff externo e textconv, evitando que configuração local altere o formato esperado pelo parser. Untracked não entra na comparação do Index. --cached funciona sem commit inicial e lê a versão preparada mesmo quando o arquivo desapareceu do disco.

## Validação automatizada

Trinta e cinco testes aprovados em git_diff_targets_test, git_diff_reader_impl_test, git_diff_target_ui_test, diff_viewer_test e file_tree_panel_test. Os novos casos verificam:

- Dois repositórios Git temporários com o mesmo nome de arquivo e três conteúdos distintos: original em HEAD, preparado no Index e modificado no disco.
- Conteúdo exato de cada lado das três comparações, mesmo com color.ui=always.
- Arquivo apenas staged, untracked com Unicode, repositório sem commit inicial e exclusão no disco depois do staging.
- Raiz incompatível e diretório sem Git reportados como erro.
- Navegação staged/workingTree em lista/árvore, clique/duplo clique e cabeçalhos do viewer.

Os testes existentes preservam histórico, renomeação histórica, binários, UTF-8, navegação de hunks, preview e comportamento do painel Git.

## Limites e próximo passo

P03 é a correção de leitura e navegação. A auditoria encontrou GitHunkService/GitController e callbacks de sessão implementados, mas a VM ainda não os conecta à abertura de diffs. Essa integração está explicitamente em P04, incluindo trava/feedback de operação, atualização da comparação e proteção de sessão/raiz/hunk. A validação dessa etapa deve incluir novos arquivos, EOF sem newline e caminhos especiais, além de staging parcial. Não habilitamos mutações sobre o diff combinado ou sobre o histórico.

O caminho remoto recebe staged/workingTree explicitamente, sem fallback para o outro alvo. O modo remoto head conserva o fallback legado; não foi homologado como comparação combinada equivalente à leitura local. A restauração remota e a jornada completa exigem homologação própria. Os testes desta entrega usam Git local real e widgets controlados, sem afirmar homologação ponta a ponta da VM, adaptadores remotos ou GitHub autenticado. E2 e E7 permanecem abertas.


## Evidência nativa

Commit local 174c6a7a na mesma branch fix/harness-state-detection, sem push ou PR. Análise estrita dart analyze --fatal-infos lib test sem issues e git diff --check limpo.

Prévia macOS compilada com dois DiffViewers reais e um repositório temporário real: HEAD contém base, Index contém prepared in index e disco contém changed on disk. Captura inspecionada e hot reload concluído, sem novos erros de layout no output. A prévia foi encerrada normalmente. Os avisos nativos anteriores de plugins persistem. Nenhum repositório ou terminal do usuário foi alterado por essa prévia.

[Comparações lado a lado](evidence/80-index-working-tree.png).

O primeiro commit encontrou index.lock transitório, que desapareceu sozinho. O arquivo não foi removido; a segunda tentativa concluiu normalmente.

Build normal macOS debug restaurado com sucesso após encerrar a prévia: flutter build macos --debug --no-pub -t lib/main.dart. Artefato cockpit/build/macos/Build/Products/Debug/Orkest Code.app. O aplicativo instalado não foi substituído. Kanban atualizado e aberto pelo Orkest CLI.
