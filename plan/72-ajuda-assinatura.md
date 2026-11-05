# Plano 72 — Ajuda de assinatura durante edição

Incremento L02b na branch única `fix/harness-state-detection`. Complementa o hover semântico sem encerrar L02: completion ainda está pendente.

## Uso

- Digitar `(` ou `,` consulta `textDocument/signatureHelp` após 150 ms.
- `Ctrl+Shift+Espaço` solicita manualmente, sem modificar o documento.
- A assinatura é atualizada ao digitar ou mudar o caret enquanto a ajuda está ativa.
- Escape, perda de foco, scroll, troca ou fechamento do documento encerram a ajuda.

O tooltip usa o tema existente, texto simples e seis linhas no máximo. Mostra a assinatura ativa, o nome/documentação do parâmetro ativo quando disponíveis e a documentação da assinatura. Não há seletor manual de sobrecargas nem Markdown rico nesta etapa. O tooltip de assinatura tem precedência sobre o hover para não empilhar informações.

## Integração e limites

O servidor escolhe a assinatura e o parâmetro ativos. O parser respeita `activeSignature`, a prioridade de `SignatureInformation.activeParameter` sobre o índice global e labels de parâmetros em string ou offsets UTF-16. Índices/ranges inválidos não provocam acesso fora dos limites. Documentação reutiliza a leitura textual segura de hover.

O editor mantém geração por consulta e snapshot de texto/seleção; o pool verifica identidade/versão do documento. O texto atual é enviado antes da consulta. Uma resposta antiga não substitui a ajuda atual; timers pendentes são cancelados e respostas em trânsito são descartadas logicamente, sem cancelamento remoto do request nesta etapa.

Não há interpretação local completa da sintaxe de todas as linguagens. `(` e `,` são os triggers iniciais; servidores sem suporte devolvem ausência/erro e o editor segue sem tooltip. O host standalone mantém seu comportamento sem LSP. Não houve alteração de workspace, terminal, Neovim, dependências ou SDKs instalados.

Referência estudada: `openidea/src/editor/lsp/signature.ts`, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. A implementação é Dart/Flutter sobre os contratos existentes, sem importação de componentes React/CodeMirror.

## Verificação

Testes de parser cobrem sobrecarga, precedência do parâmetro ativo, documentação, offsets UTF-16 e respostas inválidas. Testes de pool cobrem roteamento e respostas após edição/reabertura. Testes de widget cobrem os triggers, atualização do parâmetro, atalho manual, Escape e respostas depois de movimento/fechamento/perda de foco. A regressão inclui hover, seleção/scroll, reveal/SCM, indentação, comentários por chord, documentos standalone e notebooks.

O teste opt-in `test/integration/lsp_hover_server_test.dart` agora valida hover e ajuda de assinatura através do cliente real contra o servidor Dart disponível. Executar com `flutter test --no-pub --dart-define=ORKEST_TEST_DART=<binário-dart> test/integration/lsp_hover_server_test.dart`. Sem o parâmetro, o teste fica explicitamente ignorado. A execução real desta entrega retornou os parâmetros de `print`.

Os resultados finais ficam registrados no Kanban. Nenhum push, PR, merge ou atualização do aplicativo instalado faz parte desta entrega.
