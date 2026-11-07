# Revisão de PRs: acesso e layout do painel

## Entrega

O painel de PRs reservava 280 px fixos para a lista mesmo no painel lateral estreito. Em 320 px sobravam apenas 40 px para o detalhe. A navegação agora usa a largura efetivamente disponível: abaixo de 640 px apresenta a lista e, após selecionar um PR, mostra o detalhe com botão de retorno. A seleção é preservada ao voltar e ao expandir o painel. Em larguras maiores, lista e detalhe continuam lado a lado. As abas do detalhe passam a rolar quando a área disponível é menor que 480 px.

O comando `Git: Review Pull Requests` aparece na paleta com `Cmd+Shift+G` no macOS e `Ctrl+Shift+G` nos demais sistemas. Compartilha a mesma ação com o atalho global do shell e abre Source Control na seção de PRs, revela o painel lateral e desfaz o colapso sem perder a preferência de maximização. Não altera branches nem cria PRs.

A ação só está disponível para workspace local de projeto com Git detectado. Revalida essa capacidade ao executar, inclusive se o contexto mudou depois que a paleta abriu. O handler é removido no dispose, só aceita keydown sem repetição e não atua quando há uma rota modal sobreposta. Os demais atalhos continuam intactos.

Respostas de detalhes recebem uma geração de requisição. Se o usuário selecionar outro PR, uma resposta atrasada não pode substituir o detalhe atual. A montagem de produção identifica o painel por workspace/raiz, evitando reutilizar sua seleção ao trocar de repositório.

## Validação automatizada

Quinze testes aprovados no conjunto:

- pull_request_review_actions_test: revelação, preservação de layouts, recusa em contextos não suportados, revalidação e atalho com foco consumidor de eventos; repetições e modificadores extras rejeitados.
- git_pr_responsive_test: painel com 320 px, seleção/retorno, expansão para 800 px e resposta de detalhe fora de ordem.
- git_pr_review_panel_test: lista/detalhe e navegação em arquivos/comentários.
- command_palette_test, git_pr_workbench_integration_test e workbench_layout_persistence_test: regressões da paleta, integração de navegação e persistência existente.

## Limites

E6 não está integralmente concluída: provedores corporativos self-hosted continuam pendentes. E2 conserva a auditoria multifolder de Working Tree/Index/HEAD e a separação restante do explorador. O comando usa o contexto Git já disponibilizado pelo workspace; este incremento não adiciona um seletor de repositório para PRs. E7 conserva a homologação com GitHub autenticado e a jornada completa. Os testes usam serviço controlado; não publicaram comentários, não criaram PRs nem fizeram checkout em repositórios do usuário.


## Estado da entrega

Commit local de implementação: 6fecaa3d, na mesma branch fix/harness-state-detection, sem push ou PR. Análise estrita dart analyze --fatal-infos lib test sem issues; git diff --check limpo.

A primeira tentativa de prévia macOS foi bloqueada pelo banco build.db do Xcode: outra execução normal de flutter run -d macos compilava no mesmo checkout. O processo concorrente não foi interrompido e nenhum arquivo de lock foi removido. Testes automatizados não equivalem à homologação visual em build.


## Correção adicional: conteúdo de ferramentas recolhidas

O log da execução normal em t476 registrou RenderFlex overflow em debug_panel.dart:581 com apenas 19 px disponíveis. O processo já havia encerrado quando foi consultado. A telemetria do app instalado retornou zero casos registrados; a evidência do problema veio do log de execução, não de uma ausência inferida de erros.

Offstage mantém seus filhos no layout. Ao recolher para 44 px, o host passava essa largura às views preservadas, provocando overflow de cabeçalhos invisíveis. WorkbenchToolHost agora retém as últimas dimensões úteis em um LayoutBuilder e mantém o conteúdo nessas dimensões com OverflowBox quando está recolhido ou oculto por um host pai. A estrutura permanece uniforme, preservando State, Offstage, ExcludeFocus e TickerMode. Na primeira montagem oculta, sem dimensão anterior, usa 320×400 como fallback de layout do conteúdo; isso não altera a largura visível da barra.

A regressão usa o WorkspaceDebugPanel real: monta com 300 px, recolhe para 44 px e reabre, verificando ausência de exceções e a mesma instância de State. O conjunto ampliado, incluindo host e wrappers de Debug/Outline, passou com 21 testes; a análise estrita final ficou sem issues. Não atribuímos a perda de conexão do processo anterior exclusivamente ao overflow sem evidência adicional.

Commit local da correção do host: 01160627, na mesma branch, sem push ou PR.


## Prévia nativa

Após o término da compilação concorrente, a prévia isolada macOS compilou e iniciou. Foram renderizados o GitPrReviewPanel amplo, outro painel com 340 px e um WorkbenchToolHost com WorkspaceDebugPanel real, recolhido automaticamente após a primeira montagem. Captura inspecionada e hot reload concluído em 189 ms; sem novos erros de overflow no output dessa execução. Persistem os avisos nativos anteriores de desktop_multi_window/merged threads e volume_controller. A prévia foi encerrada normalmente.

[Captura da revisão ampla/estreita e Debug recolhido](evidence/78-pr-review-responsive.png).

Os dados de PR são demonstrativos e os componentes são reais. Esta evidência não comprova autenticação GitHub, checkout, publicação de comentários nem a jornada completa da aplicação; essas homologações continuam em E7.

Build normal macOS de debug restaurado com sucesso após encerrar a prévia: flutter build macos --debug --no-pub -t lib/main.dart. Artefato cockpit/build/macos/Build/Products/Debug/Orkest Code.app; aplicativo instalado não foi substituído. Kanban aberto no Orkest via CLI.
