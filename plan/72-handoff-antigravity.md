# Repasse ao Antigravity — integração OpenIDEA / Orkest Code

Flavio solicitou expressamente abrir um agente Antigravity pelo Orkest CLI, com `agy --dangerously-skip-permissions`, e transferir a responsabilidade por continuar esta integração. Este documento é o contexto de continuidade; confira o estado atual antes de trabalhar, pois commits posteriores podem existir.

## Objetivo e decisões do usuário

Agregar funcionalidades e pontos fortes do OpenIDEA ao Orkest Code para torná-lo uma IDE robusta, preservando a estrutura atual de busca/abertura de projetos, terminais, agentes e recursos existentes. Priorizar interações humanas de desenvolvimento: edição, assistência multilinguagem, Git, execução/debug, bancos e ferramentas. Visual e otimizações por performance ficam para quando houver necessidade comprovada. Não reescrever o produto inteiro.

O usuário autorizou implementar e commitar incrementalmente. **Usar uma única branch: `fix/harness-state-detection`. Não criar outra branch, não fazer push, não abrir PR e não fazer merge sem novo pedido explícito.** Essa orientação posterior e específica substitui instruções genéricas anteriores de PR. Main deve permanecer preservada. Não descartar mudanças de terceiros nem remover locks Git; locks transitórios anteriores se resolveram sem intervenção.

Manter o Kanban atualizado a cada incremento: implementado, testado e commitado vai para Concluídas com `[x]`; homologação/build/release ainda não realizados continuam em atividades próprias. Não deixar entrega concluída em revisão só porque não existe PR.

## Repositórios e leitura inicial

- Workspace: `/Volumes/Externo 1/projetos/zurc/remote_pi`; aplicativo Flutter em `cockpit/`.
- Referência somente leitura: `/Volumes/Externo 1/projetos/zurc/openidea`, commit inventariado `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`.
- Plano completo: `plan/72-orkest-ide-completa.md`.
- Quadro ativo: `plan/72-orkest-ide-completa.kanban`.
- Auditoria: `plan/72-auditoria-paridade.md`; proveniência: `plan/72-openidea-proveniencia.json`.
- Inventários raiz: `ANALISE_OPENIDEA_ORKEST.md`, `OPENIDEA_CATALOGO_TECNICO.md`, `OPENIDEA_INVENTARIO.json`, `OPENIDEA_MAPA_FUNCIONAL_E_ARQUITETURA.md`, `OPENIDEA_HARNESS_E_BANCOS.md`.
- Incrementos: `plan/72-hover-semantico.md`, `72-ajuda-assinatura.md`, `72-autocomplete.md`, `72-cancelamento-lsp.md`, `72-cancelamento-ui-lsp.md`.

Consultar **buscar_conhecimento no MCP base-conhecimento-dev como primeira ação operacional**, com termos específicos e projeto `remote-pi`. Antes de alterar código existente, chamar analisar_impacto_mudanca; o grafo frequentemente não encontra símbolos, então complementar com referências locais. Respeitar AGENTS.md e diretrizes locais. Salvar aprendizados validados ao concluir; o auto-sync da base é separado do Git do aplicativo. Não inventar regras de negócio nem instalar dependências novas sem consentimento. Comunicar em pt-BR, com atualizações objetivas durante o trabalho.

## Estado confirmado antes do repasse

HEAD de implementação/documentação: `b6107289`; árvore limpa antes de criar este repasse. Branch `fix/harness-state-detection`. Nenhum build ou instalação desta versão foi realizado; o app instalado não contém automaticamente o código novo. PRs históricas #12/#13 foram fechadas sem merge; não reabrir ou repetir o fluxo.

Commits relevantes já na mesma cadeia:

- `8d01a751`: precisão de espera/retomada dos harnesses; 102 testes da entrega original.
- `5d01916e`: inventário/plano/auditoria/proveniência.
- `b980a1fb`: catálogo LSP ampliado de 9 para 17 perfis, incluindo HTML/CSS/SCSS/Less/JSON/JSONC/YAML/Shell; preserva overrides e compartilhamento por raiz.
- `3ba5174c`: hover semântico, debounce e descarte de respostas antigas.
- `15058443`: assinatura/parâmetros, gatilhos `(`/`,` e Ctrl+Shift+Espaço.
- `6ae5ee34`: autocomplete simples, Ctrl+Espaço, setas/Enter/Tab/clique, resolve e imports adicionais validados atomicamente.
- `e0497b4e`: cancelamento LSP por substituição, edição, fechamento e timeout.
- `0eaa8e13`: cancelamento imediato da UI e de resolve; último incremento funcional.
- `b6107289`: último registro de conclusão no Kanban.

Quadro validado pelo parser nativo: **51 cartões, 71 dependências, 10 concluídos, 1 em revisão (H00 homologação de harness em build), 40 no backlog, nenhum em andamento**. L02a–L02e e H00a estão concluídos; atividades gerais L02/L05 seguem abertas pelos critérios restantes. Conferir estado atual, não recriar cartões existentes.

## Arquitetura e limites importantes

Manter Flutter/Dart para UI/workspace/editor/harness e cliente LSP existente. Rust já existe no CLI e em serviços; candidatos Git/DAP/busca precisam de provas, contratos e medidas antes de migração. Suporte a linguagens dos projetos é independente da linguagem de implementação. Não migrar TypeScript visual do Office sem hotspot medido. Preservar interação terminal-first; não introduzir composer/agente RPC em substituição aos terminais.

OpenIDEA é React/CodeMirror + Rust/Tauri. Seu inventário contém 41 domínios/510 declarações Tauri, 35 crates e 77 definições de linguagens; isso não comprova paridade runtime. Nenhum código OpenIDEA foi importado nestes incrementos LSP. Verificar licença/proveniência antes de reutilizar arquivos.

LSP atual: `cockpit/lib/app/core/data/lsp/`, contratos/entidades em `core/domain/`; UI em `cockpit/lib/app/orkest/ui/`. O caminho é FileViewer → DocumentHost/OrkestViewModel → LspServerPool → LspClientImpl. StandaloneDocumentHost mantém no-op sem LSP.

Autocomplete anuncia **snippetSupport=false** e descarta insertTextFormat=2. Parser aceita lista/CompletionList/default ranges/InsertReplaceEdit, limita 200 itens e ordena de forma estável. Serviço puro valida intervalos UTF-16/CRLF, caret e sobreposições antes de aplicar sugestão + imports numa única atualização. Fallback substitui palavra ASCII. Snippets, documentação rica, gatilhos específicos por servidor e demais capacidades avançadas permanecem pendentes.

Cancelamento L02e: `LspClient.request` recebe documentPath opcional, usado apenas localmente; `cancelRequests(path, method)` cancela leituras registradas sem atingir outros métodos/documentos. Isso rastreia completionItem/resolve sem alterar seu payload. Escape/foco/scroll/saída do mouse/troca de documento/dispose propagam cancelamento por callback do editor; callback do viewer captura host e caminho para cancelar arquivo anterior corretamente. Respostas tardias ainda exigem guardas locais. Servidor pode concluir trabalho após cancelamento; não alegar ganho de CPU não medido.

Homologação real atual cobre Dart. `typescript-language-server` e `tsserver` não foram encontrados no PATH e locais consultados; não foram instalados. Não declarar TypeScript homologado. Se essa etapa exigir nova dependência, pedir consentimento com justificativa; continuar outras tarefas independentes enquanto possível.

## Validação reproduzível

Última rodada: **114 testes aprovados**, análise estática limpa, telemetria **r_2b: zero erros/avisos**. Inclui processo Dart real, servidor stdio controlado, pool e regressão do editor. Não equivale a homologação visual de todas as linguagens/harnesses ou instalação da versão.

Executar a partir de `cockpit/`:

```sh
dart analyze --fatal-infos
orkest telemetry flutter test --no-pub \
  --dart-define=ORKEST_TEST_DART=/Users/flavioacv/.puro/envs/default/flutter/bin/cache/dart-sdk/bin/dart \
  test/data/lsp_codec_test.dart test/data/lsp_completion_test.dart \
  test/data/lsp_hover_test.dart test/data/lsp_signature_help_test.dart \
  test/data/lsp_server_pool_test.dart test/ui/code_editor_completion_test.dart \
  test/ui/code_editor_hover_test.dart test/ui/code_editor_signature_help_test.dart \
  test/ui/code_editor_reveal_test.dart test/ui/code_editor_selection_scroll_test.dart \
  test/ui/code_editor_tab_indent_test.dart test/ui/code_editor_comment_chord_test.dart \
  test/ui/standalone_document_host_test.dart test/ui/notebook_view_reload_test.dart \
  test/integration/lsp_hover_server_test.dart test/integration/lsp_cancellation_test.dart \
  --reporter expanded
```

Puro pode exigir acesso ao lock do SDK fora do sandbox; não confundir isso com falha do código. Fazer testes proporcionais à alteração; não repetir tudo sem motivo. Não colocar asserts dentro de callbacks Timer quando isso conflitar com a zona do teste: capturar dados e verificar após pump. Fixture de cancelamento: `test/fixtures/lsp_cancellation_server.dart`.

## Kanban e Orkest CLI

Usar skills `orkest-cli`, `orkest-design` antes de editar o quadro e `orkest-telemetry` para testes/diagnóstico. `.kanban` é Markdown, não existe comando `orkest kanban`. Cabeçalhos `##` são colunas, última coluna Concluídas exige `[x]`; preservar IDs/blockedBy e comentários. Registrar evidências e limites, sem marcar macroatividade como concluída por um incremento parcial.

Validador temporário existente: `/private/tmp/validar-kanban-ide.dart`, importa KanbanDocument real, espera 51 cartões atualmente. Atualizar contagem quando necessário e conferir IDs/dependências/checkboxes. IDs de abas são efêmeros: descobrir com `orkest list-tabs --json`. Neste repasse, terminal de origem t436, quadro v443, workspace remote_pi `f5f3d890-56ce-4658-aee4-8143d7e1a295`.

## Responsabilidade de continuidade

Você assume a execução do plano, não apenas uma revisão deste documento. Comece pela base, confira branch/status/commits, leia plano e Kanban, escolha o próximo incremento útil respeitando dependências e avance autonomamente. Não refaça o inventário nem as entregas concluídas. Atualize o cartão em andamento, implemente, teste, commite localmente na mesma branch e marque o incremento concluído com evidências. Continue as próximas atividades autorizadas; solicite ao usuário apenas decisões ou recursos realmente necessários. Se uma tarefa depender de servidor ausente, prossiga em trabalho independente viável.

Preservar todas as instruções do usuário e informar claramente o que foi implementado versus o que continua pendente. O Codex de origem deixa de editar código após entregar este repasse para evitar concorrência na mesma árvore.
