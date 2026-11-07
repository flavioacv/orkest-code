# P05 · Endurecimento da Resolução Multifolder Git no SourceControl e Semântica de Diff

## Resumo da Entrega
Implementação e validação da resolução determinística de repositórios Git em workspaces com múltiplas raízes (multifolder / multi-root) no Orkest Code, branch `fix/harness-state-detection`.

## Arquivos Modificados e Entregues
1. `cockpit/lib/app/orkest/ui/viewmodels/orkest_viewmodel.dart`:
   - `rootContaining(projectId, absolutePath)`: ordenação determinística das raízes candidatas por comprimento decrescente (da mais específica/profunda para a mais rasa), prevenindo captura acidental por raízes pai em workspaces com subprojetos ou sub-repositórios.
   - `commitStaged(message, {repoRoot, amendHash})`: adicionado suporte a `repoRoot` explícito em chamadas direcionadas, mantendo a regra de segurança que bloqueia commits ambíguos quando há arquivos staged pertencentes a múltiplos repositórios sem raiz informada.
   - Restauração de sessão de diff: valida `isUnderPath(path, project.path)` antes de permitir fallback para `project.path`, evitando diffs fantasmas no repositório errado.
2. `cockpit/lib/app/orkest/ui/viewmodels/remote_workspace_controller.dart`:
   - `rootContaining(wsId, absolutePath)`: ordenação por comprimento decrescente de path para consistência com o motor local.
3. `cockpit/lib/app/orkest/ui/widgets/file_tree_panel.dart`:
   - `repositoryLabel`:
     - 1 repositório Git: exibe `${name} · ${branch}`, mesmo em workspaces mistos com pastas sem Git (resolvendo o problema de rótulo nulo / "Source Control" genérico).
     - Múltiplos repositórios Git: exibe contagem e resumo compacto: `${gitRoots.length} repos · ${gitRoots.map((r) => '${r.name}:${r.git.branch}').join(', ')}`.
     - Sem repositórios Git: fallback padrão para `tr.sectionSourceControl`.
   - `_ChangedTree`:
     - Agrupamento unificado por raiz em `_ScRootSection(root: root)` contendo internamente Staged Changes e Changes daquela raiz (eliminando cabeçalhos duplicados para a mesma raiz).
     - `_filesUnder`: mapeia arquivos à raiz mais específica através de `_ownerRoot(abs)`, eliminando duplicações visuais em raízes aninhadas.
4. `cockpit/test/ui/git_multifolder_source_control_test.dart`:
   - Suíte com 5 testes de integração ponta a ponta com repositórios Git reais temporários:
     - Header com múltiplos repositórios e branches.
     - Header com workspace misto (1 Git + 1 pasta comum).
     - Seções colapsáveis separadas por repositório.
     - Operações atômicas isoladas de stage/unstage por repositório via `GitController`.
     - Resolução determinística da raiz mais específica em sobreposição/aninhamento.

## Validação e Qualidade
- `dart analyze lib test`: 0 erros e 0 avisos.
- Testes automatizados executados e 100% aprovados:
  - `git_multifolder_source_control_test.dart`: 5/5 aprovados.
  - `git_hunk_actions_test.dart`: 7/7 aprovados.
  - `git_hunk_staging_test.dart`: 6/6 aprovados.
  - `git_diff_target_ui_test.dart`: 4/4 aprovados.
