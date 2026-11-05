# Autocomplete LSP — incremento L02c

Implementação nativa em Dart/Flutter sobre o cliente e o pool LSP existentes. Referência conceitual: OpenIDEA `src/editor/lsp/completion.ts`, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`; nenhum código da referência foi importado e nenhuma dependência adicionada.

O editor consulta sugestões após dois caracteres ASCII de identificador, após ponto ou por Ctrl+Espaço, com debounce de 200 ms. Setas selecionam; Enter, Tab ou clique aceitam; Escape encerra inclusive requisições ainda pendentes. O popup compartilha o tema do editor e tem prioridade sobre hover/ajuda de parâmetros. A ajuda manual de parâmetros encerra o autocomplete.

O cliente anuncia inserção simples, InsertReplaceEdit e resolução de detalhes/edições adicionais. O parser aceita CompletionItem[] e CompletionList, normaliza intervalos padrão e ordena por preselect/sortText/label com desempate estável. Processa até 200 itens por resposta; snippets são descartados porque seu suporte não é anunciado.

A aceitação pode resolver o item antes de editar, incluindo imports em additionalTextEdits. O serviço puro valida todas as posições UTF-16 e os intervalos contra o mesmo buffer, rejeita sobreposições e posições inválidas e produz uma única atualização do controller, com caret ajustado. Não aplica parcialmente uma sugestão inválida. Sem textEdit, substitui a palavra ASCII ao redor do caret. InsertReplaceEdit usa o intervalo de substituição.

O pool rejeita respostas após mudança de versão, fechamento ou reabertura do documento. A UI também compara geração, texto, seleção, controller e foco; edição, movimento do caret, scroll, perda de foco e descarte do widget invalidam a consulta. Uma resolução atrasada não sobrescreve digitação mais recente. O host standalone mantém o comportamento sem LSP.

Os testes cobrem parsing, ordenação, snippets recusados, UTF-16/CRLF, imports, intervalos inválidos/sobrepostos, roteamento e descarte no pool, atalhos, clique, foco, descarte e resolução atrasada. A integração utiliza um processo real do servidor Dart e aplica uma sugestão retornada por ele. A regressão inclui hover, signature help, seleção, scroll, navegação, indentação, comentários e hosts de documento.

Limites desta entrega: snippets, commit characters, comandos de CompletionItem, apresentação rica de documentação, ranking/filtro local avançado, gatilhos específicos por servidor e cancelamento remoto por `$/cancelRequest` permanecem pendentes. O descarte local protege o buffer, mas não interrompe processamento no servidor. Não há homologação real de TypeScript ou de todos os perfis LSP, nem build/instalação do aplicativo. L02 continua aberta para esses critérios; L05 acompanha homologação por linguagem.

Evoluções posteriores: [L02d](72-cancelamento-lsp.md) adiciona cancelamento por substituição, edição, fechamento e timeout; [L02e](72-cancelamento-ui-lsp.md) estende o envio a Escape/foco/scroll/descarte/troca de documento e resolve. O descarte local continua necessário para respostas tardias.

Fluxo da versão: commits locais em `fix/harness-state-detection`, sem nova branch, push ou PR.
