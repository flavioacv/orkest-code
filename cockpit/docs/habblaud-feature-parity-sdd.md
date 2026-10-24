# SDD: perfil, estatísticas e preferências do escritório Habblaud no Cockpit

**Estado:** editor de roupa local, perfil básico, renomeação, histórico genérico de estados, chegada animada e sons integrados; métricas detalhadas seguem pendentes
**Data:** 2026-10-23  
**Origem consultada:** checkout vizinho `../habblaud`  
**Integração visual existente:** [`habblaud-office-integration.md`](habblaud-office-integration.md)

## 1. Objetivo

Completar o escritório pixel art do Cockpit com duas capacidades que o usuário
percebe no Habblaud: selecionar um personagem para consultar o agente e ajustar
a apresentação do mundo. Exibir estatísticas apenas quando uma fonte do Cockpit
as fornecer; ausência de dado deve aparecer como indisponível, nunca como zero
sintético.

Este documento registra a análise do código de origem e define uma fatia de
implementação revisável. Não propõe iniciar o cliente web completo do Habblaud
dentro do Cockpit: aquele cliente depende de store, servidor, preferências,
permissões e serviços que não existem na aplicação Flutter.

## 2. Como o Habblaud original funciona

### Perfil do agente

`client/src/ui/drawer.ts` implementa `AgentView`. A seleção de personagem no
mundo é convertida em `Selection { type: 'agent', id }`; `client/src/ui/index.ts`
atualiza a seleção e o drawer renderiza o `AgentInfo` mais recente do store.
O perfil inclui:

- identidade: nome, papel, título, provider/conta e sala;
- status e quando ele mudou, ações para centralizar/seguir a câmera;
- atividade atual e linha do tempo;
- tarefas, subagentes e shells aguardados;
- métricas: ferramentas, tokens de entrada/saída, custo, linhas, subagentes;
- metadados: modelo, branch, permissões, id da sessão, início e duração;
- ações contextuais que dependem de recursos próprios do Habblaud (terminal,
  permissões, mensagens, edição de aparência/social).

O drawer não calcula as estatísticas do nada. Ele apresenta `AgentInfo` vindo do
store/snapshot; dados de execução são produzidos pelos coletores de provider e
hooks do Habblaud. `shared/types.ts` define `Activity`, `TaskItem`, `ShellJob`,
`AgentStats` e `AgentInfo`.

O editor de personagem do Habblaud está em `client/src/ui/character-editor.ts`
e `appearance-fields.ts`, com regras puras em
`client/src/ui/character-model.ts` e `shared/appearance.ts`. Ele edita nome,
seed e 13 peças de aparência, valida combinações (por exemplo, acessório com
cabelo) e persiste pelo endpoint de personagem do projeto/sala. O lápis só é
oferecido a agente principal ao vivo em acesso local. Cockpit já adapta a parte
do nome via `manualLabel`, que persiste por aba; ainda não tem armazenamento
local de aparência por workspace nem editor de roupa. A próxima etapa deve
persistir a aparência no próprio Cockpit, indexada pelo projeto, sem conectar o
store ou a API do servidor Habblaud.

### Estatísticas agregadas / gamificação

`client/src/ui/daystats.ts` e `shared/daystats.ts` acumulam tempo por status,
esperas, sessões, subagentes, prompts, chamadas de ferramenta, tarefas, tokens
e custo por agente/projeto/conta/hora. No produto conectado, a tela lê a API
`/api/stats`; o modo local/demo acumula snapshots em memória e pode semear
histórico fictício. O escritório também contém recursos sociais/World, metas e
dados da cidade. Eles dependem do servidor Habblaud, identidade/conta ou dados
demo e não são uma fonte válida para o Cockpit local.

### Preferências de apresentação

`client/src/ui/settings.ts` guarda preferências do navegador via `prefs.ts`.
As opções relevantes ao mundo são:

| Preferência Habblaud | Efeito |
| --- | --- |
| `showNames` | etiquetas de nome nos personagens |
| `bubbles` | todos/importantes/nenhum balões de atividade |
| `liveliness` | ritmo calmo/normal/agitado da circulação |
| `daylight` | automático/dia/noite |
| `theme` | automático/nenhum/Natal/Halloween |
| `sound`, `sounds` | sons e categorias/volume |

Idioma, notificações, modo demonstração, conta e controles do Habblaud World
são preferências/serviços do cliente original, não devem ser copiados como se
fossem recursos do escritório Cockpit.

Os sons ficam em `client/src/audio/board.ts` e `scheduler.ts`; o componente
`client/src/ui/sound.ts` liga os cues da simulação (`client/src/world/sound-cues.ts`)
às preferências e desbloqueia o `AudioContext` no primeiro gesto do usuário.
Cockpit integrou o mesmo `SoundCues`/`SoundBoard`, com um master switch local
desligado por padrão e sino ao entrar em `waiting`. A notificação de permissão
continua genérica: o hook do Cockpit não fornece conteúdo estruturado e a
resposta acontece no PTY compartilhado do Office.

## 3. Estado atual no Cockpit

O wrapper `tool/habblaud_world/main.ts` reutiliza `Sim`, `Renderer`, `Overlay`,
`Camera` e `attachInput`, mas instancia `Sim` sem store (`null`) e injeta um
snapshot feito em `HabblaudWorldWebView._snapshot()`.

O snapshot tem rooms e agentes com id, nome, sala, provider aproximado, status,
início da aba atual e `recent` baseado somente nas transições genéricas de
estado observadas pelo Cockpit; `tasks` permanece vazio. O contrato de simulação ainda
recebe placeholders numéricos em `stats`, mas eles não são exibidos como dados
medidos no perfil. `startedAt` usa
`TerminalSession.createdAt`. As métricas de uso não são coletadas nem exibidas
como zeros medidos. Provider e nome vêm do harness detectado ou do rótulo manual
da aba; todos os agentes são `kind: main`. O perfil Flutter permite editar o
nome pelo mecanismo persistente de rótulo do Cockpit. A ação **Abrir terminal**
mostra a árvore existente de panes numa janela sobre o mapa, compartilhando o
mesmo PTY/controller. As preferências visuais persistem em `AppSettings` e
seguem no snapshot para as opções do mundo Habblaud; sons permanecem opt-in.

Dados disponíveis com confiança no objeto atual `TerminalSession`:

| Dado | Disponível | Fonte/limite |
| --- | --- | --- |
| sessão e projeto | sim | `TerminalSession.id/projectId` |
| título e diretório de trabalho | sim | `title/workingDirectory` |
| harness/provider | parcial | `activeHarness`; identifica a família, não o modelo executado |
| estado working/waiting/idle | sim | hooks via `applyClaudeStatus`; `waiting` existe no contrato |
| momento da última transição de status | adapter | observado na ponte; ainda é estado transitório em memória |
| histórico genérico de status | sim | últimos 100 eventos working/waiting/idle da execução atual; não é persistido nem inclui atividade interna do harness |
| início da aba/PTy atual | sim | `TerminalSession.createdAt`; não representa a vida histórica da conversa restaurada |
| modelo, tokens, custo, chamadas/ferramenta | não | não há contrato no estado da sessão/hook |
| tarefas/subagentes/atividade | não | sem eventos estruturados conectados ao snapshot |
| branch Git | não por sessão | há estado Git por projeto/worktree em outros serviços; não é parte do snapshot atual |

## 4. Decisões de produto e limites

1. Cockpit continua sendo a fonte de verdade para sessões e seus processos.
2. Habblaud continua sendo a fonte do motor do mundo, das poses e do desenho.
3. O perfil usa dados locais da sessão e deixa explícita a indisponibilidade de
   métricas que Cockpit não coleta.
4. Não exibir zeros para tokens, custo, ferramentas ou tarefas: zero significaria
   uma medição válida de nenhuma atividade; atualmente significa dado ausente.
5. Não importar o modo demo, API social, conta, mensagens, permissão remota ou
   gamificação baseada em dados simulados do Habblaud.
6. Preferências visuais do escritório devem persistir localmente no Cockpit e
   ser enviadas para a instância WebView. Não devem alterar o tema global do
   editor/terminal nem gravar configurações no checkout Habblaud.
7. O renderer permanece Canvas 2D. Perfil e controles são HTML/Flutter de
   interface, sem redesenhar o mapa por Flutter a cada frame.

## 5. Especificação proposta

### 5.1 Clique e perfil — implementado

- Clique simples no personagem seleciona o agente e abre um perfil no Cockpit.
- O perfil mostra nome/título, projeto, harness/provider, status, duração da
  sessão quando houver início confiável e diretório de trabalho.
- O perfil edita o nome através do `manualLabel` persistente da sessão; sem um
  nome manual, o título automático continua vindo do terminal/OSC.
- O perfil mostra até oito transições genéricas recentes. Isso não deve ser
  rotulado como histórico completo de mensagens ou ferramentas do agente.
- A ação **Abrir terminal** seleciona projeto/aba e mostra o multiplexador
  existente numa janela sobre o mapa; fechar a janela mantém o Office aberto.
- Clique duplo pode continuar como atalho para abrir diretamente o terminal,
  desde que a distinção entre simples/duplo seja deliberada e não dispare ambos.
- A seleção deve ser passada ao wrapper (`selectAgent`) para o overlay do
  Habblaud destacar o personagem, e limpar-se ao fechar/trocar sessão.
- Atualizações de status enquanto o perfil está aberto devem atualizar o
  conteúdo sem recriar a WebView.

### 5.2 Campos e proveniência

| Campo do perfil | Implementação inicial |
| --- | --- |
| Nome/título | `session.displayTitle` e fallback traduzido para harness; `manualLabel` pode ser editado no perfil |
| Projeto | `Project.name` |
| Harness/provider | label de `HarnessCatalog.specs[activeHarness]` |
| Status | `TerminalStatus`, labels localizados já disponíveis |
| Duração | `createdAt` imutável da aba; sessão restaurada começa a contar no novo PTY |
| Diretório | `session.currentDirectory ?? session.workingDirectory` |
| Modelo | mostrar indisponível até o harness publicar modelo estruturado |
| Tokens/custo/ferramentas/tarefas/subagentes | ocultar ou marcar como indisponível até haver coleta real |
| Branch | opcional numa fatia posterior, consultando o serviço Git da raiz correta, sem bloquear abertura do perfil |

O começo da sessão atual e o começo histórico do processo não são a mesma coisa:
o PTY é recriado ao restaurar uma aba. Nomear o campo da UI como “sessão atual”
e usar o momento de criação da aba evita prometer duração do processo remoto ou
do agente antes do boot atual.

### 5.3 Tema e controles visuais — implementados no backend Canvas/WebView

Adicionar um menu “Aparência do escritório” acessível enquanto o mapa está
aberto, com opções iniciais:

- tema: automático, original, Natal e Halloween;
- nomes visíveis;
- balões: importantes/todos/nenhum;
- movimento: calmo/normal/agitado;
- ciclo: automático/dia/noite;
- sons ambientais: desligados por padrão, com áudio liberado pelo primeiro gesto
  dentro do mapa.

Essas preferências mapeiam para `WorldOptions` (`showNames`, `bubbles`,
`liveliness`, `dayNight`, `daylight`, `theme`) do Habblaud. A implementação
precisa sanitizar valores, preservar defaults e enviar atualização ao wrapper
sem recarregar a página. A integração usa `SoundCues` e `SoundBoard` originais;
os eventos respeitam o limite de frequência do Habblaud e sons ficam opt-in.

Persistência usa `AppSettings` e `SettingsController`; as opções são incluídas
na assinatura do snapshot, persistem ao reabrir o app e não alteram o tema do
editor. A topbar mostra o botão de aparência apenas quando o Canvas WebView está
disponível. Linux mantém o renderer de fallback e seu perfil básico.

### 5.4 Estatísticas reais: evolução do contrato

Uma etapa posterior pode ampliar os eventos `cockpit-hook` com campos tipados
e opcionais: `model`, atividade/resumo, tarefas, contagens de ferramentas e
tokens quando o provider realmente os informar. O estado agregado deve ser
indexado por `sessionId` e provider, e atualizado por eventos, não inferido de
texto cru do terminal.

Não capturar transcript/JSONL inteiro só para desenhar estatísticas; o contrato
deve transportar resumos mínimos, limitar histórico e evitar segredo/prompt do
usuário. Cada métrica deve carregar origem/validade ou ser omitida quando a
origem não a suporta. Custo não deve ser estimado sem tabela de preços/modelo e
contagem confiável.

## 6. Critérios de aceite

- Clique no personagem abre seu próprio perfil e não troca a tela para terminais.
- O nome editado no perfil persiste como rótulo da aba e aparece sobre o
  personagem; sem rótulo manual, OSC continua atualizando o título.
- “Abrir terminal” seleciona a sessão exata, inclusive em projeto com várias
  abas, worktree ou workspace remoto, dentro da janela sobre o mapa e sem novo PTY.
- Sessões que o Cockpit marca como `waiting` exibem aviso no Office; **Responder**
  abre o terminal original da sessão para o usuário tratar o prompt real.
- Dispensar o aviso não altera a sessão, não envia entrada ao PTY e não aprova
  permissões implicitamente.
- O histórico curto, o balão e o sino usam somente transições de status que
  Cockpit observou. Não prometem o transcript completo do agente.
- Agentes ativos já existentes entram pelo elevador quando o Office é aberto.
- Fechar o perfil mantém o estado da câmera/mundo e não recria o WebView.
- Perfil atualiza status/duração de forma visível sem mostrar início do projeto
  como início do agente.
- Métricas ausentes não aparecem como zero ou valor fictício.
- Preferências de tema/apresentação sobrevivem a reinício e podem ser alteradas
  sem recarregar a página/canvas.
- Os sons do Office permitem ligar/desligar o master, ajustar volume e controlar
  alertas, teclado, elevador e atividades sociais separadamente.
- Não há chamadas de rede para Habblaud nem dependência de conta/servidor.
- Todas as strings de interface têm traduções en/pt-BR/es.
- Com a visão de terminal ativa, os controles do escritório não interferem nos
  atalhos de terminal.

## 7. Estado e próximos passos

1. Validar manualmente no macOS: clique, perfil, ação abrir terminal, botão de
   aparência, persistência após reinício e mudança ao vivo sem recarregar o mapa.
2. Evoluir instrumentação de hooks por provider e só então exibir estatísticas
   reais de modelo, atividade, tokens e ferramentas.
3. Adicionar estatísticas agregadas e metas apenas se Cockpit definir produto de
   gamificação próprio; os rankings/metas online do Habblaud não são portáveis
   para um cliente local sem backend.

O motor Habblaud original já controla chegada, deslocamento, trabalho/digitação,
espera, ociosidade e saída a partir dos estados genéricos. Eventos finos de
ferramenta, processo em foreground e subagentes continuam fora do contrato atual
do Cockpit; qualquer evolução deve vir de eventos neutros dos hooks, não de
parsing do transcript de um provider.

O editor de personagem local agora reaproveita `editorOptions`, `editorConflict`,
`fitToOptions`, `characterSprite` e `appearanceFromSeed` do Habblaud. As peças
selecionadas ficam em `AppSettings.officeCharacterParts`, indexadas pelo ID do
projeto; não dependem do armazenamento de personagem do servidor Habblaud.

## 8. Fontes consultadas

- Habblaud: `client/src/ui/drawer.ts` (`AgentView`, `renderStats`)
- Habblaud: `client/src/ui/index.ts` (seleção/store e ligação dos componentes)
- Habblaud: `client/src/ui/settings.ts`, `client/src/ui/prefs.ts`
- Habblaud: `client/src/ui/daystats.ts`, `client/src/ui/daystats-model.ts`
- Habblaud: `shared/types.ts`, `shared/daystats.ts`
- Cockpit: `tool/habblaud_world/main.ts`
- Cockpit: `lib/app/cockpit/ui/widgets/habblaud_world_webview.dart`
- Cockpit: `lib/app/cockpit/ui/session/terminal_session.dart`
- Cockpit: `lib/app/cockpit/ui/cockpit_page.dart`
