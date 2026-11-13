# Revisão de branches e painel Git inferior

Implementação de 13/11/2026, sobre `e4520009`, na branch `fix/harness-state-detection`.

## Diagnóstico e referências

- O seletor carregava refs somente ao abrir. Não havia atualização manual/fetch nem acompanhamento das alterações feitas por agentes ou terminais enquanto o dialog permanecia aberto.
- Após checkout/criação, a interface atualizava `selectedProject`, mesmo quando a ação tinha sido iniciada pelo menu de outro projeto.
- A lista podia manter informações antigas de branch atual ou ocupação por worktree; branches ocupadas ficavam sem ação clara ao clicar. O backend agora revalida os dados em cada checkout.
- O painel inferior usava `refreshToken: 0` e a mesma timeline estreita da barra lateral.
- Um teste da escolha da origem para criação reproduziu `No DrawerOverlay found in the widget tree`: o menu sobreposto aberto dentro do dialog dependia de um overlay ausente nesse contexto. A seleção de origem passou a usar a própria lista, sem um segundo popup.
- Durante a execução desktop foi encontrado um overflow no estado de erro de PR quando a janela de ferramentas tinha pouca altura. Esse estado agora permite rolagem.

Fontes de referência inspecionadas: `openidea/src/features/vcs/BranchWidget.tsx`, `branches.ts`, `GitLog.tsx` e `graph.ts`, além da análise anterior da extensão Git do VS Code. Foram aproveitados os padrões de organização e interação, preservando a UI Flutter e os serviços do Orkest.

## Branches

- Componente compartilhado `GitBranchesPanel`, utilizado pelo dialog do menu do projeto e pelo painel inferior.
- Grupos Branch atual / Branches locais / Branches remotas, busca, tracking e caminho da worktree que ocupa uma branch.
- Atualização manual, fetch explícito e atualização periódica somente enquanto a ferramenta/janela está ativa. Resultados de uma raiz antiga são descartados.
- Refresh do repositório efetivamente alterado, independente do projeto selecionado.
- Checkout relê refs e worktrees antes de agir; erros tipados para ref removida, ocupação de worktree, múltiplos trackings e colisão com nome local. Nenhuma opção de checkout forçado foi adicionada.
- Criação a partir de HEAD ou de uma referência escolhida dentro do seletor, com validação Git existente. O teste garante que escolher a origem não executa checkout antes de criar.
- Falha de fetch permanece visível durante refresh local e desaparece após tentativa bem-sucedida. A janela pode ser fechada durante fetch; isso fecha a UI, sem cancelar o processo Git. Comandos GUI não ficam aguardando entrada de credenciais no stdin (`GIT_TERMINAL_PROMPT=0`); helpers Git continuam disponíveis.

## Painel inferior

`GitWorkbenchPanel`: branches à esquerda, log tabular com grafo de relações reais entre commits no centro e detalhes/arquivos do commit à direita. Em pouco espaço, as branches abrem no seletor e os detalhes usam uma apresentação compacta.

- Filtro por branch, busca por assunto/autor/hash/refs, seleção de repositório e atualização imediata por revisão do controller.
- Histórico de todas as refs por padrão, em ordem topológica; selecionar uma branch restringe a consulta. As consultas de projetos diferentes não bloqueiam a exibição da raiz atual.
- O grafo usa hashes de pais, mantém faixas durante o percurso e representa splits/convergências. Não conecta artificialmente raízes sem parentesco.
- Selecionar um commit lista seus arquivos; selecionar um arquivo abre o diff existente. Respostas atrasadas de histórico/arquivos não substituem a seleção atual.
- O botão de histórico preserva acesso à timeline anterior, comparação de revisões, revert e undo.
- Pastas comuns não são oferecidas como repositórios no dock. Traduções novas em en/pt-BR/es.

Limites: janela inicial de 100 commits, sem paginação nova, favoritos ou políticas automáticas de pull/fetch. O gerenciamento de branches continua local; no destino SSH o painel usa a leitura de histórico existente e não expõe escrita local por engano. A árvore de worktrees continua protegida pelo Git.

## Validação

64 testes aprovados na execução consolidada: `git_branch_picker_test`, `git_workbench_panel_test`, `git_graph_layout_test`, `git_integration_workflow_test`, `git_history_reader_impl_test`, `git_history_evolution_test`, `git_history_panel_test`, `bottom_dock_test`, `projects_rail_copy_branch_test`, `git_command_runner_impl_test`, `git_pr_responsive_test` e `git_pr_review_panel_test`.

Cobertura nova: atualização manual/periódica da lista; origem da criação sem overlay adicional; falha/recuperação de fetch; descarte de respostas de outro projeto; atualização por revisão sem esperar polling; painel reduzido com refs longas; grafo de merge e raízes independentes; checkout com metadata antiga, ref removida, colisão de nome e worktree ocupada em repositórios reais.

Análise estática dos arquivos alterados com `--fatal-infos` sem issues; `git diff --check` limpo. Build macOS e inicialização realizados. A primeira recarga incremental manteve definições anteriores do enum/traduções; após invalidar os timestamps desses arquivos, hot restart e hot reload concluíram com sucesso. A consulta de runtime após a recarga não encontrou erros. Não foi executado E2E completo por automação da interface desktop; os fluxos interativos foram verificados por testes de widget e Git real em diretórios temporários.

Nenhuma dependência adicionada. Sem push, PR ou merge em main nesta revisão.

## Evolução aprovada a partir da referência visual do OpenIDE

O painel passou a oferecer as abas Log, Console e Worktrees. O Log mantém a árvore de referências à esquerda, o grafo no centro e a área de detalhes à direita, inclusive antes da seleção de um commit. As divisórias permitem redimensionar as colunas. Branches remotas e nomes com prefixos aparecem em pastas recolhíveis; HEAD e tags podem restringir o histórico.

Filtros de autor e período são enviados à consulta Git, com chips removíveis. A busca textual continua filtrando a janela de commits carregada. Aba, referência, busca, autor, período, commit selecionado, colunas e pastas recolhidas são salvos no layout existente do workspace. O dock mantém as ferramentas visitadas montadas quando fechado ou quando outra aba é selecionada; ferramentas ocultas suspendem polling e foco.

O Console registra as operações iniciadas por `GitController.run`, `sync` e `collect`, preservando a saída entregue aos consumidores. Consultas de leitura via `output` não poluem o console. Há limite de 60 operações e 500 linhas por operação, remoção de credenciais de URLs HTTP(S) e limpeza por repositório. Os registros ficam em memória; não representam um terminal de execução arbitrária.

Worktrees reutiliza o gerenciador existente para listar worktrees vinculadas, abrir um projeto já cadastrado ou adicionar sua pasta, e acionar o fluxo existente de criação. A listagem rejeita resultados atrasados de outra raiz. O contrato legado do gerenciador retorna lista vazia quando indisponível; não foi alterado nesta entrega. Escrita de branches e Worktrees continua desabilitada no histórico SSH.

Validação adicional: testes de serialização e dados malformados, filtros enviados ao backend, detalhes vazios, redimensionamento persistido, resposta atrasada de Worktrees, captura e redação do Console, árvore recolhida com busca e tags, e retenção de entrada ao alternar/recolher o dock. Regressão dos controladores, histórico e editor de conflitos executada. Build macOS debug e hot reload concluídos; consulta do runtime sem erros. Automação desktop indisponível neste entrypoint (sem extensão Flutter Driver/Marionette); não foi alegado E2E completo.

Continuam fora do escopo favoritos, paginação adicional e alteração automática da política de pull. A organização visual não altera a estratégia de integração configurada no Git.
