# Cancelamento da assistência LSP pela UI — incremento L02e

O editor encaminha as invalidações de hover, signature help, completion e completionItem/resolve pelo DocumentHost e pool até o cliente stdio. Escape, perda de foco, scroll, mudança de documento/controller e descarte encerram as consultas correspondentes. Saída do mouse também cancela o hover. O cancelamento é limitado ao método e ao caminho do documento; operações de alteração e consultas de outros arquivos permanecem independentes.

O contrato de request recebe documentPath opcional, usado apenas localmente para rastrear consultas. Isso permite cancelar completionItem/resolve, cujo payload normalmente contém apenas o item e seus dados. O caminho não é acrescentado ao JSON enviado ao servidor. O pool fornece esse contexto a partir do documento que atende o pedido.

O callback de cancelamento do viewer captura o host e o caminho no momento de construir o editor. Ao trocar o documento, o editor usa o callback anterior para encerrar consultas do arquivo anterior. A janela standalone implementa a operação como no-op, mantendo o comportamento sem servidor LSP.

Timers ainda não disparados são cancelados localmente. Requisições já em andamento recebem $/cancelRequest por ID. O servidor pode responder mesmo depois dessa notificação; verificações locais de versão, geração, seleção, foco e controller permanecem necessárias. A implementação não mede nem promete redução de CPU ou latência.

Testes cobrem callbacks de cancelamento durante sugestão e resolve por Escape/foco/scroll/dispose, invalidação de hover/assinatura e troca de documento, roteamento no pool e isolamento de resolve no protocolo stdio. A fixture confirma payload inalterado e resposta tardia ignorada. A regressão também utiliza um servidor Dart real.

Snippets, homologação TypeScript, gatilhos específicos por servidor, documentação rica e outros critérios de L02/L05 permanecem pendentes. Não houve instalação de dependências, build ou atualização do aplicativo instalado.

Validação final: 114 testes aprovados, incluindo Dart real, protocolo stdio, pool e regressão do editor. Análise estática sem problemas. Telemetria r_2b: zero erros e avisos.

Fluxo da versão: commits locais na mesma branch fix/harness-state-detection, sem nova branch, push ou PR.
