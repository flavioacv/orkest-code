# Cancelamento de consultas LSP — incremento L02d

O cliente stdio existente passa a registrar método/URI das consultas de hover, completion, signatureHelp, semanticTokens/full e definition enquanto aguardam resposta. Uma nova consulta do mesmo método/URI cancela a anterior por `$/cancelRequest`, usando seu ID JSON-RPC. `didChange` e `didClose` cancelam as leituras registradas daquele documento antes de enviar a notificação correspondente.

O cancelamento conclui a espera local com falha tipada. Os consumidores existentes mantêm suas verificações de versão e geração; o cliente ignora respostas posteriores de IDs removidos. Outros documentos e métodos distintos permanecem independentes. Formatação e comandos de alteração não entram nesse cancelamento automático. Ao atingir o timeout existente de 15 segundos, qualquer requisição informa seu ID ao servidor antes de retornar a falha de timeout.

O protocolo permite ao servidor concluir trabalho mesmo após o cancelamento; enviar a notificação não garante economia de CPU. A proteção local do buffer continua necessária. Escape, scroll e perda de foco ainda descartam respostas na UI sem envio imediato de cancelamento. completionItem/resolve não carrega URI neste contrato e continua protegido localmente até resposta ou timeout. Esses casos continuam pendentes em L02.

Os testes executam um servidor controlado em subprocesso Dart e inspecionam as mensagens stdio: IDs exatos, ordem antes de didChange, isolamento de documento/método, preservação de formatting, fechamento/reabertura, timeout e respostas tardias. A fixture responde após cancelamento para verificar que a conexão segue utilizável. A regressão utiliza também o servidor Dart real; não é homologação TypeScript nem build/instalação da IDE.

Nenhuma dependência adicionada ou contrato público substituído. A homologação TypeScript foi investigada, mas `typescript-language-server`/`tsserver` não foram localizados no PATH ou nos locais consultados. Instalação de novos pacotes não foi realizada. L02 e L05 seguem abertas, com o recorte deste incremento registrado separadamente no Kanban.

Validação final: 101 testes aprovados, incluindo servidor Dart real, protocolo de cancelamento e regressão do editor. `dart analyze --fatal-infos` sem problemas. Telemetria `r_29`: zero erros e avisos.

Evolução posterior: [L02e](72-cancelamento-ui-lsp.md) cobre o cancelamento por Escape/foco/scroll, descarte/troca de documento e o contexto local de completionItem/resolve. Os limites de UI/resolve acima descrevem o recorte original de L02d e foram atendidos nesse incremento posterior.

Fluxo: commits locais em `fix/harness-state-detection`, sem nova branch, push ou PR.
