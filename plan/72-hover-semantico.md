# Plano 72 — Hover semântico no editor

Entrega incremental de L02, em Dart, sobre o editor e pool LSP existentes. Completion e signature help continuam pendentes; esta entrega não encerra L02.

## Comportamento

Após manter o ponteiro por 350 ms sobre um símbolo, o editor consulta `textDocument/hover` e apresenta informações de tipo/documentação junto dos diagnósticos já disponíveis. É usado o mesmo tooltip com cores do tema, em texto simples e altura limitada; HTML não é executado e Markdown não recebe renderização rica nesta etapa.

O cliente anuncia preferência por `plaintext`. O parser aceita MarkupContent, MarkedString e listas legadas. Respostas nulas, inválidas ou sem suporte não produzem tooltip semântico. O gesto de navegação Cmd/Ctrl mantém precedência sobre novas consultas de hover.

O viewer envia o texto atual antes da consulta para não depender do debounce de edição. O pool verifica identidade/versão do documento; o editor verifica geração da consulta, posição e conteúdo. Mover para outro símbolo, sair da área, editar, trocar o documento, rolar ou fechar invalida a consulta. O timer ainda não enviado é cancelado; uma consulta em trânsito é descartada logicamente quando obsoleta, sem implementar cancelamento remoto LSP nesta etapa.

Arquivos standalone preservam o comportamento atual sem servidor LSP: o host devolve ausência de informação. Workspace, terminal, motor Neovim e configurações de servidores permanecem no fluxo existente. Nenhum SDK/servidor/pacote foi instalado.

## Referência e implementação

Referência estudada: `openidea/src/editor/lsp/hover.ts` e `hoverPrecedence.test.ts`, no commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. Aplicados os princípios de debounce, descarte de respostas obsoletas e coordenação com navegação; não foram copiados componentes React/CodeMirror.

- `core/data/lsp/lsp_hover.dart`: interpretação textual de respostas.
- `lsp_client_impl.dart`: capacidades de hover na inicialização.
- `lsp_server_pool.dart`: roteamento e descarte por identidade/versão.
- `DocumentHost`/`OrkestViewModel`/`FileViewer`: acesso ao documento e flush do texto.
- `CodeEditor`: posição UTF-16, debounce e tooltip integrado, lifecycle de listeners ao substituir controller.

## Verificação

Testes de parser cobrem texto, MarkupContent, listas legadas e payloads vazios/inválidos. Testes de pool cobrem posição UTF-16 e respostas atrasadas após edição/reabertura. Testes de widget cobrem exibição, debounce e descarte após edição/saída/fechamento/troca de documento. A regressão inclui seleção com auto-scroll, indentação, reveal, SCM e hosts standalone/notebooks.

Existe teste opt-in com servidor Dart real em `cockpit/test/integration/lsp_hover_server_test.dart`. Executar com `flutter test --no-pub --dart-define=ORKEST_TEST_DART=<caminho-absoluto-do-binario-dart> test/integration/lsp_hover_server_test.dart`. Usa projeto temporário, consulta `answer` de tipo `int` pelo cliente real e encerra o servidor; sem o parâmetro, o teste fica explicitamente ignorado. O teste real executado nesta entrega passou com o SDK disponível nesta máquina; não constitui homologação de todos os servidores do catálogo.

Não houve build/instalação do aplicativo nesta entrega. O Kanban mantém o incremento em revisão até integração autorizada.
