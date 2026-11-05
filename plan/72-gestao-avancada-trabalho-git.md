# Gestão Avançada de Trabalho Git (G04 Orkest Code)

> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`  
> **Status:** Concluído e Validado

---

## 1. Contexto e Motivação
A atividade `G04 · Adicionar gestão avançada de trabalho Git` fornece recursos completos para gerenciamento de fluxo de trabalho no Orkest Code:
- Gestão de alterações temporárias via **Stash (shelf)**;
- Marcação de releases e pontos de controle com **Tags** (anotadas e leves);
- Geração e aplicação determinística de **Patches unificados**;
- Operações de **Cherry-pick**, **Revert** e **Rebase** protegidas por **guardrails mandatórios** que impedem modificações ou merge direto na branch `main`.

---

## 2. Componentes Entregues

### 2.1. Modelos de Domínio
- **`GitStashEntry` (`cockpit/lib/app/orkest/domain/entities/git_stash_entry.dart`):**
  - Modelagem do stash com índice numérico (`index`), referência canônica (`stashRef` ex: `stash@{0}`), hash base, tempo relativo e mensagem.
- **`GitTagEntry` (`cockpit/lib/app/orkest/domain/entities/git_tag_entry.dart`):**
  - Modelagem de tags com nome, hash apontado, data de criação e mensagem de anotação (`isAnnotated`).

### 2.2. Serviço Especializado (`cockpit/lib/app/orkest/domain/services/git_work_service.dart`)
- **Stash (Shelf):**
  - `listStashes`: Lista stashes com formatação estruturada;
  - `stashPush`: Guarda modificações locais com suporte a `includeUntracked` e `keepIndex`;
  - `stashApply` e `stashPop`: Aplicação segura no working tree;
  - `stashDrop`: Descarte isolado de entrada de stash;
  - `stashDiff`: Inspeção textual do diff do stash antes da aplicação.
- **Tags:**
  - `listTags`: Listagem com nome, hash, data e subject;
  - `createTag`: Criação de tags leves ou anotadas (`-a -m`);
  - `deleteTag`: Exclusão de tags locais.
- **Patches:**
  - `createPatch`: Geração de patch unificado de working tree ou entre revisões;
  - `applyPatch`: Aplicação via stdin com validação de pré-condição (`--check`) e suporte a reversão (`--reverse`).
- **Operações com Guardrails (Cherry-pick / Revert / Rebase):**
  - **Bloqueio Mandatório na Main:** Verificação automática da branch ativa antes de executar qualquer alteração; se for `main` ou `master`, a operação é imediatamente rejeitada com erro descritivo.
  - **Garantia de Working Tree Limpo:** Verificação de status prévia antes de iniciar cherry-pick, revert ou rebase.

### 2.3. Exposição no `GitController` (`cockpit/lib/app/orkest/ui/viewmodels/git_controller.dart`)
- Métodos integrados que disparam invalidação de cache de histórico (`markHistoryStale`) e agendamento de refresh automático na interface.

---

## 3. Validação e Testes Automatizados
- **Suíte de Testes Especializada (`cockpit/test/domain/git_work_service_test.dart`):**
  - Testes em repositório Git real cobrindo ciclo de vida de stash (push, list, diff, apply, drop);
  - Criação, listagem e exclusão de tags leves e anotadas;
  - Criação e aplicação de patch com validação prévia (`checkOnly`);
  - Prova de guardrails mandatórios bloqueando cherry-pick e rebase na `main`;
  - Execução bem-sucedida de cherry-pick e revert em branch feature isolada.
- **Suíte de Regressão Completa de Git:** 44 testes aprovados sem qualquer quebra.
- **Análise Estática:** `dart analyze --fatal-infos` com **zero issues** no projeto `cockpit`.
