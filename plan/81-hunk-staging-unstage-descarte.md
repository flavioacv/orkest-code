# Entrega P04 — Ações Granulares de Hunk (Stage, Unstage e Descarte) às Sessões de Produção

## Visão Geral
Conexão produtiva e real das ações granulares de hunk (`stage`, `unstage` e `descarte`) do `DiffViewer` e `DiffViewerSession` à `OrkestViewModel` e ao `GitController` com `GitHunkService`.

## Arquivos Modificados e Criados

1. **`cockpit/lib/app/orkest/domain/entities/file_diff.dart`**
   - Adicionada propriedade opcional `final bool noNewline;` (default `false`) à entidade `DiffLine`.

2. **`cockpit/lib/app/orkest/data/filesystem/unified_diff_parser.dart`**
   - Detecção e marcação de `\ No newline at end of file` marcando `noNewline: true` na última linha do hunk correspondente.

3. **`cockpit/lib/app/orkest/data/filesystem/git_diff_reader_impl.dart`**
   - Normalização dos diffs sintéticos de arquivos untracked (`_untrackedDiff`): header unificado padrão `@@ -0,0 +1,${lines.length} @@` e marcação de `noNewline: true` se o arquivo não terminar com `\n`.

4. **`cockpit/lib/app/orkest/domain/services/git_hunk_service.dart`**
   - Suporte a `FileDiffKind kind` em `buildHunkPatch`, `stageHunk`, `unstageHunk` e `discardHunk`.
   - Headers Git obrigatórios para criação de novo arquivo (`new file mode 100644`, `--- /dev/null`, `+++ ...`) e deleção (`deleted file mode 100644`).
   - Normalização de headers sintéticos `@@ +1,N @@` -> `@@ -0,0 +1,N @@`.
   - Emissão de `\ No newline at end of file` após linhas com `noNewline: true`.
   - Citação segura de caminhos contendo espaços, tabulações ou aspas.

5. **`cockpit/lib/app/orkest/ui/session/diff_viewer_session.dart`**
   - Adicionados estados de feedback e trava: `bool isOperatingHunk = false;`, `String? hunkOperationError;` e método `clearHunkError()`.

6. **`cockpit/lib/app/orkest/ui/viewmodels/git_controller.dart`**
   - Propagação de `FileDiffKind kind` em `stageHunk`, `unstageHunk` e `discardHunk` para o `_hunkService`.
   - Injeção opcional de `GitHunkService` no construtor.

7. **`cockpit/lib/app/orkest/ui/viewmodels/orkest_viewmodel.dart`**
   - Implementado `_bindDiffViewerHunkCallbacks`:
     - `workingTree`: conecta `onStageHunk` e `onDiscardHunk`.
     - `staged`: conecta `onUnstageHunk`.
     - `head`, commits históricos (`commitHash != null`) ou conexões remotas: mutações desabilitadas (`null`).
   - Conectado em `_openDiff` (novas abas e candidatos a preview) e em `_restoreSessionFromDescriptor` (restauração de layout).
   - Implementado `_handleHunkAction`:
     - Trava de concorrência atômica com `_activeHunkOperations`.
     - Snapshot pré-await de identidade e contexto (`sessionId`, `projectId`, `path`, `target`, `repoRoot`).
     - Guardrail de descarte: verificação de buffers `dirty` no editor (`FileViewerSession`) recusando a operação com erro amigável caso haja alterações não salvas.
     - Execução via `gitController` e tratamento seguro de erros (`Failure` preenche `hunkOperationError`).
     - Re-leitura pós-sucesso com `_gitDiff.read` e atualização da sessão.

8. **`cockpit/lib/app/orkest/ui/widgets/diff_viewer.dart`**
   - Banner de erro visível quando `session.hunkOperationError != null` com botão de fechar chamando `clearHunkError()`.
   - Botões de ação em `_HunkHeader` respeitam `target`:
     - `workingTree` exibe botões Stage e Discard; Unstage ausente.
     - `staged` exibe botão Unstage; Stage e Discard ausentes.
     - `head` não exibe botões de mutação.
   - Descarte protegido por diálogo de confirmação destrutivo (`showConfirmDialog` com `danger: true`).
   - Estado de carregamento desabilita cliques concorrentes.

9. **Testes Criados e Atualizados:**
   - `cockpit/test/domain/git_hunk_staging_test.dart`: 6 testes de patching e staging com Git real (caminhos, corrida, untracked, espaços, EOF sem newline).
   - `cockpit/test/ui/git_hunk_actions_test.dart`: 7 testes de integração cobrindo UI (botões por target, diálogo de confirmação, banner de erro) e Git real (fluxo stage/unstage/discard e rejeição de hunk obsoleto).

## Evidências de Testes
- Análise estática: `cd cockpit && dart analyze lib test` -> `No issues found! (0 erros, 0 avisos)`.
- Suíte completa de testes de diff e hunks (34 testes aprovados):
  - `git_hunk_staging_test.dart` (6/6)
  - `git_hunk_actions_test.dart` (7/7)
  - `diff_viewer_test.dart` (14/14)
  - `git_diff_targets_test.dart` (3/3)
  - `git_diff_reader_impl_test.dart` (1/1)
