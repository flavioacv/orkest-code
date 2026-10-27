# Relatório de animações e eventos do Office

Referência: Habblaud `de913185c16bfc5d680aeeec092bcf02a2fcad4b`.
Escopo: escritório do editor, sessões locais/remotas, personagens e ambiente.
Este inventário distingue pose, efeito e regra de entrada: uma imagem no atlas
não constitui, por si só, uma integração funcional.

## Origem dos eventos e identificação de harness

As automações existentes usam `CliAutomationGateway.discover`: procuram os
executáveis do `HarnessCatalog` e consultam os modelos quando o CLI oferece
essa capacidade. Isso identifica instalações disponíveis, sem garantir que
estejam executando em uma aba.

O Office reutiliza `TerminalSession.activeHarness`. Esse valor vem de
`TerminalHarnessMonitor`, dos provedores de processos de cada plataforma e do
`ProcessTreeResolver`: a partir do PID raiz do PTY, percorre descendentes,
normaliza lançadores como Node/Python/Bun, classifica entradas conhecidas e
prioriza o processo interativo em foreground. Comandos administrativos,
consultas de versão e processos suspensos não devem aparecer como agente ativo.

`OfficeHarnessIdentity` preserva a identidade encontrada no processo, aceita
identidade descritiva externa via `orkest activity --harness <id>` e usa Orkest
quando nenhuma está disponível. Identidades externas não precisam integrar o
enum. Um modelo dentro do Xcode não é necessariamente um processo CLI separado;
nesse caso a extensão/produtor deve informar seus eventos. O nome do harness
nunca decide qual animação pode rodar.

O fluxo funcional é: PTY/telemetria/produtor → sessão → atividade, execução,
tarefa ou efeito normalizado → simulação → renderizador. O mesmo contrato
percorre as sessões remotas pelo protocolo do sidecar. OSC 133/633 C/D fornece
início/fim e exit code quando o shell emite esses marcadores. Não instala hooks
específicos de Claude, Codex ou outro harness. Texto livre sem resultado
confiável não deve fabricar conclusão, erro de CI ou merge.

## Poses dos personagens

| Pose | Condição de uso no escritório |
| --- | --- |
| `stand` | Permanecer em pé, aguardar deslocamento, observar janela ou conversar em pé. |
| `walk` | Entrada, saída, retorno à mesa, lazer, encontro social e entrega ao agente pai. Rotas respeitam a malha de colisão. |
| `run` | Retorno urgente: aprovação a mais de 2 tiles; trabalho a mais de 12; espera de comando a mais de 20. |
| `sit` | Sentar em mesa, banco, sofá ou assento de encontro; repouso sem tarefa ativa. |
| `type` | Sessão trabalhando na mesa; notebook nos pontos de trabalho alternativos. |
| `sleep` | Inatividade prolongada, espera de comando de pelo menos 25 minutos, cochilo no sofá/TV; reação à falha quando sentado. |
| `drink` | Pausa de café/água após usar o respectivo equipamento. |
| `use` | Cafeteira, água, geladeira, pia, fliperama e interruptor. |
| `raise_hand` | Sessão aguardando intervenção humana; também variante de reação à conclusão bem-sucedida. |
| `talk` | Conversa social, delegação e entrega do resultado ao pai. |
| `stretch` | Pausa ociosa e variante de reação ao sucesso de comando. |
| `read` | Livro, telefone, papéis de entrega e trabalho em assento alternativo. |
| `play` | Pingue-pongue, com raquete. |
| `wait` | Espera de comando com pipoca e audiência na TV. |
| `cheer` | Festa de PR/merge/release, vitória social e gol na TV. |
| `laugh` | Conversas e programas de TV. |
| `game` | Videogame, com controle. |
| `rps` | Jokenpô: contagem, revelação de pedra/papel/tesoura e resultado. |
| `groom` | Espelho, pente/batom e brilho ao concluir. |
| `sulk` | Derrota em jogo social ou reação ao gol adversário; não representa falha genérica de terminal. |

## Espera, execução e prioridade

| Estado/efeito | Disparo e duração |
| --- | --- |
| Trabalho | Atividades como pensar, ler, pesquisar, editar, executar e delegar colocam a sessão em trabalho. Monitor recebe conteúdo coerente com o tipo da atividade. |
| Aprovação humana | `needs_input`; tem prioridade sobre espera de execução. Novo prompt/resposta libera a espera. |
| Espera foreground | Execução confirmada pendente por mais de 10 s. |
| Espera background | Execução marcada como background; encerrar um turno não encerra essa execução. |
| Pipoca | Espera inferior a 3 min. |
| Inquietação | De 3 a 10 min; giro intermitente. |
| Teia/bocejo | De 10 a 25 min; teia cresce após 20 min e há bocejos intermitentes. |
| Cochilo de comando | A partir de 25 min. |
| Sucesso de comando | Resultado confirmado com código 0: estrela/confete e reação por 2,2 s. |
| Falha/interrupção | Resultado confirmado não zero: tempestade/chuva por 4 s. Não cria alarme de CI. |
| Pausas individuais | Sessão ociosa ou livre durante espera elegível; café, água, banheiro/pia, sofá, telefone, livro, janela, arcade, lanche, alongamento e espelho. Novo trabalho interrompe o lazer e retorna à mesa. |
| Frequência de lazer | Calma: 16–42 s; normal: 6–20 s; animada: 3–10 s entre oportunidades. |
| Inatividade longa | Após 10 min, favorece repouso/cochilo. |

Execuções paralelas usam IDs distintos. Repetições e resultados atrasados não
devem disparar novamente as recompensas. Um terminal encerrado deixa de ser uma
presença ativa; a saída final do PTY é consumida antes da limpeza de execuções.

## Eventos de projeto, delegação e ambiente

| Animação/efeito | Regra |
| --- | --- |
| Festa da sala | PR aberto, PR mergeado ou release confirmados: 12 s; colegas elegíveis comemoram por 2,6 s com pequeno atraso individual. |
| Alarme da sala | CI falhou: até 10 min, luz vermelha/giroflex e faixa. |
| Recuperação de CI | CI passou remove alarme ativo e comemora a recuperação; CI verde sem alarme anterior não cria festa. |
| Push | Atualiza atividade; não cria festa automaticamente. |
| Entrada/saída | Elevador, fila, abertura/fechamento de portas e fade. Desaparecimento de uma fonte tem tolerância antes da caminhada de saída. |
| Sala nova | Construção em 2,6 s: piso, paredes, móveis com escalonamento e placa. |
| Sala vazia | Saída dos ocupantes, desligamento da luz e desmontagem de 2,2 s após espera inicial. |
| Iluminação | Interruptor com flicker ao ligar (550 ms) e apagar (600 ms). |
| Subagente | Nasce de subagente informado pela sessão ou terminal filho associado; resultado bem-sucedido leva papéis ao pai. Filho com sessão própria retorna à sua mesa; subagente efêmero sai. |
| Quadro de tarefas | `task_pending`, `task_started`, `task_completed`, `task_removed`, com ID e título; quadro reflete tarefas reais da sessão. |
| Recompensas | Moedas fictícias: tarefa concluída +10; turno concluído +5; entrega +15. Carteira pertence à identidade da sessão. |
| Social | TV, videogame, arcade, pingue-pongue, copa, conversa, jokenpô e espelho; trajetos, poses, balões, resultado e moedas de apostas simuladas. |
| Ambiente contínuo | Relógios, monitores, quadros, TV, bola de pingue-pongue, vapor, banheiro ocupado, reflexo no espelho, tráfego e janelas. |
| Dia/noite/estação | Configurações do Office controlam iluminação, nuvens/estrelas, neve e decoração sazonal. |
| Balões e indicadores | Atividade recente, tempo de espera, pedido humano, sucesso/falha, conversa, troféu e ganho de moedas. |

## Implementação e rastreabilidade

Canvas usa o motor original vendorizado e o adaptador em `tool/office_world`.
Os snapshots agora levam tarefas reais, timestamps de estado, execuções,
resultados e identidade do harness. O provedor não é reduzido a Claude/Codex.

Linux usa `OfficeWorldFlutterView`, `office_native_simulation.dart`,
`office_native_effects.dart` e `office_native_layout.dart`. A simulação nativa
executa as mesmas categorias funcionais, com agendamento social próprio; não
promete uma sequência aleatória idêntica à do Canvas. `export_native.ts` extrai
geometria, colisões e estados dos móveis do código vendorizado, sem dependências
novas. A cache de 16 salas é extensível em runtime.

`OfficeAnimationRules` centraliza os limiares compartilhados. `TerminalSession`
recebe o contrato genérico; o codec e os servidores local/remoto transportam os
campos opcionais. A documentação de uso está em `tool/office_world/README.md`.

Cidade pública/World, visitas entre escritórios, curtidas, metas comunitárias e
fogos da cidade pertencem ao produto público Habblaud World. Não há no motor PTY
uma fonte equivalente nem regra autorizada para criar esse backend no editor.
Não devem ser apresentados como eventos de execução do Office.

## Validação

Validação local em 27/10/2026: 95 testes aprovados — 62 de sessão, regras,
detecção e UI nativa; 19 do motor Canvas; 2 de wire Rust; 3 do codec remoto;
8 do servidor com socket real; 1 do instalador legado. Análise estática dos
arquivos Dart alterados e `git diff --check` sem problemas. Bundle Canvas e
assets nativos regenerados; build macOS Debug concluído com a CLI atualizada.
Capturas Canvas e Flutter revisadas em `build/office/canvas-execution.png` e
`build/office/native-execution.png`. O teste nativo inclui 18 salas e os oito
encontros sociais. O renderizador utilizado no Linux foi exercitado por testes
Flutter no macOS; não foi executado um binário Linux/Windows nesta máquina.

Os testes ficam em `tool/office_world/sim.test.ts`, `test/session`,
`test/core/terminal/pty_command_markers_test.dart`,
`test/ui/office_native_execution_test.dart`, testes de wire da CLI e testes do
protocolo/servidor. A aprovação desses testes demonstra os cenários cobertos,
não a disponibilidade automática de eventos em todo harness existente. A
detecção de um processo não substitui um produtor de eventos estruturados.
