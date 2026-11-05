# Resolução Visual de Conflitos Git no Orkest Code (G02)

> **Atividade:** `G02 · Adicionar resolução visual de conflitos`  
> **Status:** Concluído e Validado  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivo

Conflitos de merge, rebase, cherry-pick ou revert são situações frequentes no fluxo de desenvolvimento colaborativo. Tradicionalmente, desenvolvedores precisam inspecionar marcadores brutos textuais (`<<<<<<<`, `=======`, `>>>>>>>`) e editar manualmente as linhas, incorrendo em alto risco de erro humano e corrupção acidental da base de código.

A atividade **G02** entregou uma solução completa de resolução visual integrada ao editor de código do Orkest Code:
1. Parser robusto de marcadores de conflito com suporte a 2-way (standard) e 3-way (diff3 com ancestral comum `|||||||`);
2. Resoluções atômicas e contextuais:
   - **Aceitar Atual (`ours`)**: preserva as mudanças locais (HEAD);
   - **Aceitar Entrante (`theirs`)**: adota as alterações que estão entrando (incoming/branch remota);
   - **Aceitar Ambos (`both`)**: concatena de forma limpa ambas as versões;
   - **Restaurar Base (`base`)**: retorna ao ancestral comum (quando presente no formato diff3);
3. Resolução individual de blocos e resolução em lote (`resolveAll`);
4. Navegação ágil entre conflitos com revelação e scroll sincronizado no editor (`revealLine`);
5. Detecção automática de operações Git em andamento (`MERGE_HEAD`, `rebase-merge`, `rebase-apply`, `CHERRY_PICK_HEAD`, `REVERT_HEAD`) com atalhos para **Continuar** (`git <op> --continue`) ou **Abortar** (`git <op> --abort`);
6. Banner flutuante no topo do editor (`GitConflictBanner`), com contagem dinâmica, navegação, estilo visual alinhado ao design system (`colors.gitConflict` e `colors.panel2`), e suporte a internacionalização (i18n) em `pt_BR`, `en` e `es`.

---

## 2. Arquitetura e Componentes

### 2.1. `GitConflictService` (`domain/services/git_conflict_service.dart`)
Serviço desacoplado em Dart puro com as seguintes responsabilidades:
- **`hasConflictMarkers(text)`**: detecção rápida O(1)/O(N) sem parsing desnecessário;
- **`parseConflicts(text)`**: mapeamento determinístico de todos os blocos válidos de conflito, retornando offsets (`from`, `to`), linhas de início/fim (`startLine`, `endLine`), rótulos e trechos (`ours`, `theirs`, `base`);
- **`resolveBlock` e `resolveAll`**: substituição segura de trechos mantendo quebras de linha limpas;
- **`detectOngoingOperation(repoRoot)`**: inspeção não-bloqueante da pasta `.git` para identificar se há merge, rebase, cherry-pick ou revert ativo;
- **`continueOperation` e `abortOperation`**: execução controlada via `Process.run` com retorno tipado `Result<void, String>`.

### 2.2. Componente Visual `GitConflictBanner` (`ui/widgets/git_conflict_banner.dart`)
- Componente flutuante com elevação e borda semântica `colors.gitConflict`;
- Exibe o total de conflitos e a posição atual (ex: `(1/3)`);
- Botões de navegação rápida (↑ / ↓) acionando `widget.session.reveal`;
- Botões de ação rápida estilizados:
  - *Aceitar Atual* (destaque azul `colors.accent`);
  - *Aceitar Entrante* (destaque verde `colors.gitStaged`);
  - *Aceitar Ambos* (destaque neutro);
- Ações Git contextuais quando detectada operação em andamento (*Continuar Merge/Rebase* e *Abortar Merge/Rebase*).

### 2.3. Integração no `FileViewer` (`ui/widgets/file_viewer.dart`)
- Avaliação reativa de conflitos no `_initContent` e no listener `_onCtrlChanged`;
- Posicionamento flutuante no topo do `_editor()` integrado com a busca (`_findOpen`) e aviso de conflito externo em disco (`hasDiskConflict`);
- Modificação direta no buffer (`_applyToBuffer`) preservando o histórico de undo/redo nativo do editor.

### 2.4. Integração no `GitController` (`ui/viewmodels/git_controller.dart`)
- Expõe `detectOngoingOperation`, `continueOperation` e `abortOperation` integrados ao ciclo de vida e agendamento de refresh do Git.

---

## 3. Validação Automatizada

- **Suíte de Testes de Conflito:** `cockpit/test/domain/git_conflict_resolution_test.dart`
  - 13 testes unitários aprovados cobrindo:
    1. Detecção e parsing de conflitos 2-way;
    2. Detecção e parsing com ancestral comum 3-way (diff3);
    3. Parsing de múltiplos conflitos intercalados no mesmo arquivo;
    4. Resoluções unitárias (`ours`, `theirs`, `both`);
    5. Resolução em lote (`resolveAll`);
    6. Detecção precisa de repositório limpo, `MERGE_HEAD`, `rebase-merge`, `CHERRY_PICK_HEAD` e `REVERT_HEAD`.
- **Suíte de Testes de Hunk Staging:** `cockpit/test/domain/git_hunk_staging_test.dart` (4 testes aprovados sem regressão).
- **Análise Estática Global:** `dart analyze` no pacote `cockpit` executado com **zero issues / no issues found**.
