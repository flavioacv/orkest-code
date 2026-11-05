# Revisão e Staging por Hunks no Git (G01)

> **Atividade:** `G01 · Entregar revisão e staging por hunks`  
> **Status:** Concluído e Validado  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivo

No desenvolvimento moderno de software, a capacidade de realizar commits atômicos revisando e preparando apenas trechos específicos de código (hunk staging) é indispensável para evitar que mudanças não relacionadas ou rascunhos de testes sejam incluídos inadvertidamente no repositório.

A atividade **G01** entregou:
1. Geração de patches unificados granulares (`UnifiedDiff`) para trechos individuais;
2. Staging e unstage atômicos via `git apply --cached` e `git apply --cached --reverse`;
3. Descarte isolado de trechos no working tree (`git apply --reverse`);
4. Integração nativa na UI do `DiffViewer`, exibindo botões de ação contextuais em cada cabeçalho de hunk (`_HunkHeader`);
5. Proteção contra corridas e conflitos de HEAD/índice com tratamento tipado de erros;
6. Preservação de arquivos binários, untracked e mudanças não selecionadas.

---

## 2. Arquitetura e Componentes

### 2.1. `GitHunkService` (`domain/services/git_hunk_service.dart`)
Serviço desacoplado que opera via CLI nativa do Git:
- **`buildHunkPatch`**: Normaliza caminhos para o formato POSIX (`/`) e constrói o formato exato esperado pelo `git apply`:
  ```diff
  diff --git a/relative/path.dart b/relative/path.dart
  --- a/relative/path.dart
  +++ b/relative/path.dart
  @@ -oldStart,oldLen +newStart,newLen @@
    contexto
  - removido
  + adicionado
  ```
- **`stageHunk`**: Executa `git apply --cached -` enviando o patch via stdin.
- **`unstageHunk`**: Executa `git apply --cached --reverse -` via stdin.
- **`discardHunk`**: Executa `git apply --reverse -` diretamente sobre o working tree.

### 2.2. Integração na Sessão (`DiffViewerSession`)
- Flag `isStaged`: distingue se a aba de diff visualiza alterações no working tree contra o index/HEAD ou alterações já preparadas no index (`git diff --cached`).
- Callbacks de ação: `onStageHunk`, `onUnstageHunk`, `onDiscardHunk`.

### 2.3. Interface Visual (`DiffViewer`)
- Cabeçalhos de hunk (`_HunkHeader`) agora contam com botões interativos compactos (`_HunkActionButton`) estilizados com as cores semânticas do tema (`colors.gitStaged`):
  - Em diffs unstaged: botões **"Stage Trecho"** (destacado) e **"Descartar"**.
  - Em diffs staged: botão **"Desfazer Stage"** para remover o trecho do índice.
  - Em diffs históricos (commits passados): botões suprimidos automaticamente (read-only).
- Suporte a internacionalização (i18n) em português (`pt_BR`), inglês (`en`) e espanhol (`es`).

### 2.4. `GitController`
- Métodos integrados `stageHunk`, `unstageHunk` e `discardHunk` que invocam o serviço, disparam `markHistoryStale()` e agendam o `refresh()` da árvore de arquivos e painel Git.

---

## 3. Validação Automatizada

- **Suite de Testes Unitários:** `cockpit/test/domain/git_hunk_staging_test.dart`
  - Teste 1: Formatação rigorosa do patch unificado e normalização de caminhos Windows/POSIX.
  - Teste 2: Ciclo de vida real em repositório Git temporário (staging parcial da linha 1 mantendo a linha 10 pendente, unstage do trecho e descarte pontual no working tree).
  - Teste 3: Proteção contra corridas e conflitos (rejeição segura com `Result.isFailure` quando o índice foi alterado).
  - Teste 4: Armazenamento e acionamento dos callbacks na `DiffViewerSession`.
- **Testes de Regressão:** `cockpit/test/ui/diff_viewer_test.dart` e `cockpit/test/data/git_diff_reader_impl_test.dart` (13 testes aprovados sem falhas).
- **Análise Estática:** `dart analyze --fatal-infos` limpa com **zero issues**.
