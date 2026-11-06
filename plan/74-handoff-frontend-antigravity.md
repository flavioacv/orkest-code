# Continuidade do frontend — Antigravity

## Autorização e limites

Flavio autorizou continuar a implementação e delegar ao Antigravity com `agy --dangerously-skip-permissions`. Assuma a implementação neste checkout. O agente de origem deixará de editar para evitar concorrência.

- Diretório: `/Volumes/Externo 1/projetos/zurc/remote_pi`; app Flutter: `cockpit`.
- Branch única: `fix/harness-state-detection`. HEAD no repasse: `12f45f5a`, nove commits locais à frente do remoto.
- Manter todos os incrementos nessa branch e fazer commits locais atômicos. NÃO criar branch, push, PR ou merge: instrução específica do usuário para esta versão.
- Preservar tema Orkest, workspace esquerdo, terminais, harnesses e trabalho existente. Sem dependências novas sem consentimento.
- Consultar `buscar_conhecimento` com projeto `remote-pi` antes de trabalhar; `analisar_impacto_mudanca` antes de alterar entidades existentes; persistir aprendizado validado ao concluir. Ler AGENTS e skills aplicáveis.

## Fonte e quadro

Referência local: `/Volumes/Externo 1/projetos/zurc/openidea`. Ler `plan/73-evolucao-estrutural-frontend.md`, `plan/73-frontend.kanban`, `ANALISE_OPENIDEA_ORKEST.md` e o plano/quadro 72 para contexto histórico. O quadro ATUAL desta evolução visual é `plan/73-frontend.kanban`: E1/E2 em andamento, E3–E7 backlog. Atualizar evidências e pendências em cada incremento validado; não marcar entrega parcial como concluída.

## Já integrado e commitado

- `c1f18bc5`: WorkbenchToolHost extraído; views visitadas preservadas, lazy mount, foco/tickers ocultos suspensos.
- `eba8e93e`: diff unificado e quadro estrutural.
- `44a3f468`: ferramenta/seção Git persistida por workspace; SourceControlPanel próprio.
- `f3f2959f`: próximo/anterior hunk rola no diff virtualizado completo, contador e atalhos Alt+setas.
- `12f45f5a`: revisão EDITÁVEL POR BLOCO de conflito, fontes Atual/Entrante/Base quando marcadores diff3 incluem base. Aplica apenas ao buffer, com proteção de snapshot/sessão/path/conflito em disco; salvar é explícito. CRLF/EOF preservados.

O último incremento commitado teve 26 testes pertinentes aprovados, análise limpa, build macOS e prévia isolada inspecionada. Isso NÃO comprova homologação completa da IDE nem base recuperada dos estágios Git.

## Alterações locais NÃO concluídas — preservar e assumir

Existem duas modificações deliberadas ainda sem commit:

1. `cockpit/lib/app/orkest/domain/services/git_conflict_service.dart`: introduz `hasUnresolvedMarkers` e `resolveDocument(text:, results:)`, compondo rascunhos sobre offsets do snapshot e preservando texto externo aos conflitos. Exige quantidade correspondente e resultados sem marcadores. Ainda precisa de testes, revisão de casos malformados e validação.
2. `cockpit/lib/app/orkest/ui/widgets/merge_conflict_editor.dart`: extrai `MergeConflictComparison` reutilizável do diálogo por bloco. Mantém API antiga. Extração feita por transformação de código, portanto verificar compilação e regressões ANTES de expandir. Não presumir que análise/testes passaram para esse diff.

Não descartar/resetar/stash essas alterações. Ver `git diff` e concluir o incremento, sem atribuir à entrega anterior validação que ainda não ocorreu.

## Próxima entrega concreta: merge de documento completo (E2)

1. Revisar extração e executar análise/testes existentes.
2. Criar diálogo de revisão de documento: snapshot imutável, um controller/rascunho por conflito, navegação preservando edições e indicação explícita de resolvido. Inicializar com lado atual NÃO deve marcar resolvido silenciosamente.
3. Ao resolver todos, compor documento completo, permitir revisão/edição final, validar ausência de marcadores e retornar texto inteiro. Cancelar não altera buffer/disco. Se voltar aos blocos após editar resultado final, preservar o resultado ou confirmar descarte; cancelar confirmação mantém trabalho.
4. Integrar em FileViewer na ação de revisão atual, preservando guardas de identidade de controller/sessão/path/snapshot e conflito em disco. Aplicar uma alteração ao buffer; não salvar nem stage automaticamente.
5. Localizar textos em pt-BR/en/es com mecanismo existente. Sem implementar camada paralela desnecessária.
6. Testar múltiplos conflitos, navegação/rascunhos, pendências bloqueando aplicação, cancelamento, CRLF/EOF/texto externo e snapshot obsoleto conforme APIs existentes.
7. Atualizar E2 com entrega/evidências/limites e commitar incremento local.

Base obtida dos estágios Git, grafo/histórico, blame e auditoria Index/HEAD/Working Tree continuam pendentes; não confundir marcadores diff3 com leitura do índice. Após E2 seguir plano estrutural E1 e demais jornadas, sempre com incrementos funcionais substanciais.

## Validação e execução Flutter

No diretório `cockpit`, usar SDK já instalado, sem atualizar dependências. Testes existentes relevantes: `test/domain/git_conflict_resolution_test.dart`, `test/ui/merge_conflict_editor_test.dart`, `test/ui/diff_viewer_test.dart`, `test/ui/workbench_tool_host_test.dart`, `test/ui/workbench_layout_persistence_test.dart`. Localizar testes de sincronização/seleção com `rg --files test` conforme alteração. Executar análise, testes apropriados e `git diff --check` antes de commit.

Após mudanças Flutter, executar hot reload/restart em runtime disponível. Prévia isolada evita inicializar terminais reais. Se montar AlertDialog, usar rota `showDialog` real dentro de ShadcnApp, não AlertDialog diretamente como home (causa assert do Navigator no reload). Usar PTY para `flutter run -d macos --no-pub -t <entry temporária>` e enviar `r`/`R`. Capturas anteriores em `/private/tmp/orkest-merge-review.png`; entry anterior pode estar em `/private/tmp/orkest_merge_review_preview.dart`, inspecionar antes de reutilizar.

Prévia com target temporário sobrescreve o mesmo artefato Debug do app: ao terminar, restaurar com `flutter build macos --debug --no-pub -t lib/main.dart`. Não instalar/substituir app em execução automaticamente nem alegar inspeção visual quando apenas compilou. Registrar limitações reais no Kanban.
