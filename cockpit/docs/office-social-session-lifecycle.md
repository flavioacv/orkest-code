# Office: vida social e identidade da sessão

Implementado em 24/10/2026. O Office usa o motor visual do Habblaud e os eventos
genéricos do Cockpit. Nenhuma função desta integração exige Claude, Codex ou
outro harness específico.

## Perfil e atividade

O perfil mostra personalidade, bordão, saldo fictício, ganhos, vitórias/derrotas,
amizades, rivalidades e extrato. O feed geral inclui eventos sociais com o nome
e o retrato do personagem. TV, jogos, pingue-pongue, copa, conversas, jokenpô e
espelho continuam sendo decididos pela simulação, conforme disponibilidade e
personalidade. As moedas são apenas elementos de jogo.

O Flutter consulta `getSocialSnapshot()` a cada segundo. A ponte valida a
identidade antes de atualizar a sessão e persiste somente alterações reais.
Há limites de tamanho (24 mil caracteres por estado) e quantidade de eventos
(40 no feed social, 20 por agente no estado). O perfil acompanha as atualizações.
Rótulos novos do Flutter estão disponíveis em português, inglês e espanhol.

## Persistência e encerramento

Cada `TerminalSession` recebe `officeIdentity`, um token aleatório independente
de projeto, nome, harness e número da aba. O layout salva esse token junto ao
estado social daquela sessão. Recriar a WebView ou restaurar o mesmo descritor
de sessão pode recuperar sua carteira; criar outra sessão gera outro token.

Ao fechar a sessão, seu estado em memória é limpo e seu descritor é removido
do layout. A ponte remove carteiras, confrontos e eventos de agentes ausentes.
Clonar um layout para outro worktree remove identidade, parentesco e estado
social. Não existe busca de carteira antiga pelo nome ou pela pasta do projeto.
O armazenamento social não usa `localStorage` global.

A restauração do descritor representa a mesma sessão lógica do Cockpit. Não
é uma tentativa de reconhecer automaticamente uma sessão externa do harness.
Subagentes sintéticos reportados por `agent start/stop` vivem na simulação;
a persistência de carteira aqui é dos terminais reais.

## Delegação pelo CLI

`cockpit new-tab` já envia o ID da aba que chamou o comando. O backend agora
guarda a identidade do pai quando esse chamador é reconhecido como agente:

```sh
cockpit new-tab --title Desenvolvedor
cockpit new-tab --title Revisor --parent-tab t99
cockpit new-tab --title Independente --independent
```

As duas últimas opções exigem o CLI recompilado. A associação automática usa
o campo de origem que o CLI já enviava. As flags são mutuamente exclusivas.

O novo terminal só ganha personagem quando houver presença de agente. No
snapshot, um terminal com pai ativo recebe `kind: sub`, `parentId` e
`sessionBacked: true`. O perfil mostra quem delegou. Ao concluir um turno, ele
vai entregar o resultado e depois retoma sua rotina, mantendo o terminal aberto.
Se ainda estiver saindo do elevador, a entrega espera o fim da chegada. Um novo
pedido cancela uma entrega pendente. Não há envio de prompts entre agentes
nessa animação: a comunicação real continua pelo CLI/PTY.

Sem pai conhecido, o terminal é independente. Fechar o pai não fecha os filhos;
eles passam a aparecer como independentes. Abas criadas antes desta mudança não
recebem parentesco inferido retroativamente. Subagentes sintéticos do contrato
`agent start/stop` mantêm seu ciclo original de entrega e saída.

## Espera por shell

Uma linha de atividade observada no PTY não prova que um comando continua
rodando. Por isso, animações prolongadas dependem de sinais confiáveis:

- `cockpit telemetry <comando>` informa abertura e fechamento de cada execução.
- `activity command --phase started` ou `activity wait --phase started/updated`
  informa uma espera explícita; `completed/failed/interrupted` a encerra.
- Execuções paralelas têm IDs próprios; terminar uma não encerra as outras.
- Permissões e perguntas humanas têm prioridade sobre a espera de comandos.

Depois de 10 segundos em um shell rastreado, o motor usa a ampulheta e seus
estágios: pipoca, impaciência, teias e cochilo. Ao receber o resultado, usa a
reação de sucesso, falha ou interrupção. Ausência de saída não inventa uma
execução nem uma conclusão. Harnesses sem esses sinais continuam usando o
observador genérico de atividades do PTY, com a precisão que seus sinais permitem.

## Arquivos e validação

- `office_social_state.dart`: identidade, validação e modelos de apresentação.
- `terminal_session.dart`: estado da sessão e ciclo de comandos rastreados.
- `cockpit_viewmodel.dart`: restauração, salvamento e clonagem do layout.
- `cockpit_cli_handler.dart` e `cli/src/commands.rs`: origem da delegação e flags.
- `tool/habblaud_world/social.ts`: ponte social com descarte de agentes encerrados.
- `tool/habblaud_world/sim.ts`: entrega dos delegados e preservação da chegada.
- `habblaud_world_webview.dart` e `office_agent_profile_dialog.dart`: feed e perfil.

Testes cobrem isolamento por identidade, descarte de colegas encerrados,
delegação sem despawn, estágios de espera, comandos paralelos, prioridade da
permissão, perfil/edição reativa e protocolo das novas flags do CLI.

Recompile o bundle com `node tool/habblaud_world/build.mjs`. Pare e execute
`flutter run -d macos` novamente para carregar os novos campos de sessão e a
WebView. Hot reload sozinho não recria esses objetos. O aplicativo não foi
reiniciado automaticamente para preservar os terminais em uso.
