# P06 · Desacoplamento da Visão de Alterações do Source Control e WorkspaceRoot

> **Branch:** `fix/harness-state-detection`  
> **Data:** 07/11/2026  
> **Status:** Concluído (Validado com 0 issues de análise estática e suíte completa de testes aprovada)  
> **Contexto:** Épico E2 (`E2 · Entregar ambiente integrado de revisão Git`) e E1 (`E1 · Extrair host de ferramentas do explorador`) do Kanban 73 (`plan/73-frontend.kanban`).

---

## 1. Contexto e Motivação

O painel explorador de arquivos (`cockpit/lib/app/orkest/ui/widgets/file_tree_panel.dart`) continha historicamente mais de 3.000 linhas de código, acumulando não apenas o gerenciamento de árvore de diretórios e arquivos do workspace, mas também a implementação interna completa da visão de alterações Git:
- Listagem e árvore de arquivos modificados (`_ChangedFile`, `_ChangedTree`, `_ChangedDirectory`, `_ChangedDirectoryView`, `_ChangedRow`).
- Agrupamento multifolder por raiz (`_ScRootSection`).
- Redação e submissão de commits com suporte a amend, atalhos de teclado e persistência (`_CommitComposer`).
- Tipagem informal de raiz de workspace como `typedef WorkspaceRoot = ({String name, String path, GitInfo? git});`.

Esse alto acoplamento violava a separação de responsabilidades (SRP) e dificultava a reutilização e evolução do `SourceControlPanel` e do `WorkbenchToolHost`.

---

## 2. Implementação Realizada

### A. Criação da Entidade Formal `WorkspaceRoot`
- Criado [`cockpit/lib/app/orkest/domain/entities/workspace_root.dart`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/lib/app/orkest/domain/entities/workspace_root.dart):
  ```dart
  class WorkspaceRoot {
    const WorkspaceRoot({
      required this.name,
      required this.path,
      this.git,
    });

    final String name;
    final String path;
    final GitInfo? git;
    ...
  }
  ```
- Compatibilidade retroativa mantida: `file_tree_panel.dart` re-exporta `WorkspaceRoot` via `export 'package:orkest_code/app/orkest/domain/entities/workspace_root.dart';`.

### B. Extração Modular de `SourceControlChangesView`
- Criado [`cockpit/lib/app/orkest/ui/widgets/source_control_changes_view.dart`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/lib/app/orkest/ui/widgets/source_control_changes_view.dart) contendo:
  - `SourceControlChangedFile`: modelo tipado e imutável para entradas alteradas no Git.
  - `SourceControlChangesTree`: árvore e lista reativa com suporte a multifolder, expansão de pastas persistente e atalhos de seleção.
  - `SourceControlCommitComposer`: barra/painel de composição de mensagem de commit, atalhos Cmd+Enter/Ctrl+Enter, suporte a amend e automações de geração de commit com feedback inline.
  - `SourceControlChangedDirectory` e `SourceControlChangedDirectoryView`: renderização hierárquica de diretórios com suporte a badges de quantidade de modificações.
  - `SourceControlChangedRow`: renderização de linha de arquivo com ícones do tema (`FileTypeIcon`), cores de status Git, tooltips de caminho relativo e botões contextuais de stage, unstage e descarte.
  - `SourceControlRootSection`: agrupador colapsável por repositório Git em workspaces multifolder.
  - `SourceControlPanelHeaderAction` e `gitStatusColor`.

### C. Desacoplamento e Limpeza de `file_tree_panel.dart`
- Removidas mais de 900 linhas de implementação Git de dentro de `file_tree_panel.dart`.
- Mantida delegação transparente em `_ChangedTree` e `_CommitComposer` para garantir 100% de retrocompatibilidade com chamadores existentes.
- Eliminados imports obsoletos e corrigidas ambiguidades de escopo.

---

## 3. Validação e Qualidade

1. **Análise Estática Estrita:**
   - Executado `cd cockpit && dart analyze --fatal-infos`.
   - **Resultado:** `No issues found!` (0 erros, 0 avisos em toda a base e testes).

2. **Suíte de Testes Automatizados:**
   - `test/ui/file_tree_panel_test.dart`: 10/10 testes aprovados.
   - `test/ui/git_multifolder_source_control_test.dart`: 5/5 testes aprovados.
   - `test/ui/git_diff_target_ui_test.dart` & `git_hunk_actions_test.dart`: 11/11 testes aprovados.
   - `test/ui/git_history_panel_test.dart`, `git_branch_picker_test.dart` & `git_controller_test.dart`: 20/20 testes aprovados.
   - `test/data/git_diff_targets_test.dart` & `git_history_reader_impl_test.dart`: 8/8 testes aprovados.
   - **Total:** 54 testes de integração e componentes Git executados e aprovados com 100% de sucesso.
