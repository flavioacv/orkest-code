# Revisão da entrega frontend — 06/11/2026

Atualização posterior: os bloqueadores abaixo foram tratados na [integração para teste completo](76-integracao-frontend-teste-completo.md). Este relatório preserva os achados do HEAD auditado; não representa o estado final após a correção.

Referência auditada: `18956841`, branch `fix/harness-state-detection`. Checkout limpo no início; 20 commits locais à frente do remoto. Após o repasse `65ff1f1c`, houve 10 commits, abrangendo 37 arquivos. Não houve nova implementação nesta revisão.

## Parecer

Existem incrementos funcionais para testes parciais, especialmente Git. A evolução estrutural completa ainda não está finalizada. Componentes e testes isolados não equivalem à integração na aplicação nem à homologação de jornadas em build.

## Entregas observadas

- Host de ferramentas com persistência, recolher/expandir e largura ampliada.
- Revisão de conflitos do documento completo: rascunhos por bloco, resolução explícita, revisão final editável e aplicação ao buffer com guardas de snapshot/sessão/path/conflito de disco.
- Blame conectado ao FileViewer, busca no histórico e comparação entre revisões.
- Componentes de Debug, Problems, Outline e revisão PR, com testes isolados.
- Filtro do catálogo Database e exportação CSV/JSON para clipboard.

## Bloqueadores de conclusão

1. **Debug, Problems e Outline não montados na aplicação.** `orkest_page.dart` constrói FileTreePanel sem `debugPanel`, `problemsPanel` ou `outlinePanel`. Não há instanciação desses painéis em outros pontos de `lib/`. FileTreePanel só registra essas ferramentas quando os parâmetros são fornecidos. ProblemsController também não tem instância de produção. A jornada LSP/DAP não está ligada ao host.
2. **Gutter DAP sem controller na produção.** FileViewer aceita `debugController`, mas nenhum chamador em `lib/` fornece esse argumento. O teste direto de CodeEditor não verifica propagação entre sessão DAP e o editor real.
3. **PRs sem serviço/builder no ponto de composição.** FileTreePanel aceita `gitPullRequestsPanel`/`gitPullRequestService`, mas a tela principal não fornece nenhum deles. A nova aba depende desse builder. O teste de integração instancia manualmente SourceControlPanel com serviço HTTP simulado.
4. **Edição Database somente em memória.** `_editCell` em DbQueryView muda `result.rows[rowIndex][colIndex] = newVal`; não chama DbRowEditService, não executa UPDATE, não valida PK nem confirma linhas afetadas. A interface não deve ser homologada como persistência de dados. O teste de diálogo constrói um AlertDialog próprio, sem montar o DbQueryView real.
5. **Cancelamento Database somente visual.** O botão `db-query-cancel` apenas define `_running = false`. A consulta continua, pode publicar resultado mais tarde e libera nova execução concorrente. Falta cancelamento real ou contrato explícito de descarte de resultado com proteção contra concorrência.
6. **Base do índice Git desconectada e enriquecimento incorreto por bloco.** `readConflictStages` e `enrichBlocksWithBase` não possuem chamadas na UI. O diálogo recebe apenas texto, não dados dos estágios. Além disso, `enrichBlocksWithBase` atribui o documento base inteiro a cada bloco, sem mapear o trecho correspondente; conectar diretamente essa função produziria uma base inadequada em conflitos múltiplos.
7. **Homologação completa não comprovada.** E7 descrevia homologação transversal implementada, mas os testes citados são de serviços/widgets, com as lacunas acima. Não foi executada nesta revisão uma jornada na aplicação completa, build novo ou teste de provedores remotos reais.

## Testes manuais possíveis agora

Usar um repositório descartável e o app compilado deste checkout: diff split/unificado, navegação por hunks, conflitos múltiplos com cancelamento/revisão final/salvar explícito, blame e histórico/comparações. No Database, avaliar busca e exportação; não interpretar edição visual como gravação nem cancelamento como interrupção efetiva.

Debug/Problems/Outline/PR devem aguardar a conexão de produção antes de uma homologação integrada. A área inferior, auditoria de I/O oculto, multifolder e demais pendências do plano continuam abertas.

## Verificação desta revisão

- `dart analyze --fatal-infos lib test`: sem issues.
- `git diff --check`: limpo antes das alterações documentais.
- Dez suítes reexecutadas: **57 testes aprovados**, exit code 0. Escopo: git_conflict_resolution, merge_conflict_editor, workbench_tool_host, workbench_layout_persistence, git_history_panel, file_viewer_blame, debug_widgets, db_widgets, problems_and_outline_widgets e git_pr_workbench_integration. Não equivale à execução de toda a suíte nem à homologação integrada.
- MCP base-conhecimento-dev respondeu às buscas nesta sessão; reinicialização não foi necessária.
