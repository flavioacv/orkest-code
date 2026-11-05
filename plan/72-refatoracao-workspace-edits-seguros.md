# Refatoração e Workspace Edits Seguros (L04)

> **Atividade:** `L04 · Entregar refatoração e workspace edits seguros`  
> **Prioridade:** P1 · Porte: L · Dependências: L02, W03 (Concluídas)  
> **Status:** Concluído e Homologado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

A atividade **L04** estabelece a infraestrutura transacional e resiliente para refatorações, renomeações de símbolos em múltiplos arquivos, quick fixes de diagnósticos, organização de imports e formatação de código no Orkest Code, com foco absoluto em segurança, atomicidade e proteção contra corrupção de código.

Pilares centrais atendidos:
1. **Renomeação Semântica Segura (`prepareRename` e `rename`):**
   - Validação prévia de elegibilidade de renomeação na posição (`textDocument/prepareRename`), retornando o placeholder atual e o range UTF-16;
   - Solicitação de `WorkspaceEdit` multi-arquivo (`textDocument/rename`).
2. **Ações de Código e Correções Rápidas (`codeAction` e `resolve`):**
   - Consulta contextualizada de ações por range e diagnósticos (`textDocument/codeAction`), incluindo filtros por categoria (`quickfix`, `refactor`, `source.organizeImports`);
   - Resolução lazy/on-demand de ações (`codeAction/resolve`) quando o language server adia o cálculo do `WorkspaceEdit`.
3. **Serviço de Workspace Edits Seguros (`SafeWorkspaceEditService`):**
   - **Geração de Preview em Memória:** Diff detalhado por arquivo afetado (antes vs depois), contagem de edits e flags de novos/deletados/renomeados;
   - **Prevenção de Conflito de Versões:** Bloqueio preventivo (*fast fail*) se qualquer buffer aberto estiver em versão (`doc.version`) divergente da esperada pelo servidor (`TextDocumentEdit.version`);
   - **Atomicidade Transacional e Rollback Automático:** Caso ocorra falha de I/O, permissão ou gravação em qualquer arquivo durante uma refatoração multi-arquivo, todos os arquivos previamente modificados são revertidos ao estado original em milissegundos;
   - **Desfazer Global Reversível (*Undo*):** Geração de ação de undo atômico que restaura simultaneamente todos os arquivos tocados.

---

## 2. Componentes e Contratos Entregues

- **`LspWorkspaceEdit` & Entidades de Recursos** (`cockpit/lib/app/core/domain/entities/lsp_workspace_edit.dart`):
  - Suporte ao formato clássico `changes` e ao formato moderno `documentChanges`;
  - Suporte a operações estruturadas de recursos do LSP 3.x (`LspCreateFile`, `LspRenameFile`, `LspDeleteFile`, `LspTextDocumentEdit`);
  - `consolidatedEdits` e `allAffectedUris` para unificação canônica;
  - `LspPrepareRenameResult` com detecção de placeholders e validação.
- **`LspCodeAction` & `LspCodeActionKind`** (`cockpit/lib/app/core/domain/entities/lsp_code_action.dart`):
  - Decodificação universal de ações de código e comandos da especificação LSP;
  - Mapeamento das categorias canônicas: `quickfix`, `refactor`, `refactor.extract`, `refactor.inline`, `refactor.rewrite`, `source.organizeImports`.
- **`SafeWorkspaceEditService`** (`cockpit/lib/app/core/domain/services/safe_workspace_edit_service.dart`):
  - Orquestrador de previews (`WorkspaceEditPreview`) e transações (`WorkspaceEditTransactionResult`);
  - Conversão robusta de URIs para caminhos locais de SO (`uriToPath`);
  - Rollback automático atômico em exceções no meio da cadeia de escrita;
  - Tokens de `undoAction` reversíveis.
- **Operações Integradas no `LspServerPool`** (`cockpit/lib/app/core/data/lsp/lsp_server_pool.dart`):
  - `prepareRename(path, line, character)`
  - `rename(path, line, character, newName)`
  - `codeActions(path, range, {diagnostics, kinds})`
  - `resolveCodeAction(path, action)`
  - `organizeImports(path, range)`
  - `formatDocument(path, {tabSize, insertSpaces})`

---

## 3. Validação e Qualidade

- **12 novos testes dedicados** aprovados com 100% de sucesso:
  - `cockpit/test/domain/lsp_workspace_edit_test.dart` (4 testes): parsing de changes, documentChanges, prepareRename e code actions;
  - `cockpit/test/domain/safe_workspace_edit_service_test.dart` (4 testes): preview com diffs, bloqueio por version mismatch, aplicação multi-arquivo com undo, e rollback automático em falha de escrita;
  - `cockpit/test/integration/lsp_refactoring_and_rename_test.dart` (4 testes): integração completa de prepareRename, rename multi-arquivo, codeActions com resolve, organização de imports e formatação.
- **25 testes da suíte combinada de navegação e refatoração** (L03 + L04) aprovados sem regressões.
- **Zero erros ou alertas** na análise estática `dart analyze --fatal-infos`.
