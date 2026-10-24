# Integração do escritório Habblaud no Cockpit

**Estado:** mundo, editor de personagem local, perfil básico, nome editável, linha do tempo genérica, chegada animada e sons ambientais integrados
**Atualizado:** 2026-10-23  
**Objetivo:** registrar as decisões e o estado técnico para retomar a integração
sem precisar redescobrir os contratos.

## 1. Especificação e estado

O Cockpit executa agentes como processos de CLI dentro de sessões de terminal.
A integração representa workspaces como salas e sessões com agente ativo como
personagens no escritório pixel art do Habblaud. O mapa ocupa a área central;
os terminais continuam acessíveis pela topbar e pelo clique no personagem.

| Requisito | Estado |
| --- | --- |
| Mostrar mapa pixel art no painel central | Implementado: Canvas 2D original em plataformas com WebView; fallback Flutter no Linux |
| Projetos/workspaces com sessões de harness ativas como salas | Implementado: uma sala compartilhada por projeto/worktree; quando a última sessão some, o Sim mantém a sala para apagar a luz, animar a saída e desmontá-la |
| Somente sessões com harness ativo como personagens | Implementado |
| Atualizar nome, estado e atividade observada | Estado working/waiting/idle e eventos UserPromptSubmit, Pre/PostToolUse, Notification, PermissionRequest e Stop vêm dos hooks compatíveis; sem prompt ou argumentos da ferramenta |
| Entrada e saída animadas | Acopladas ao ciclo de snapshot da simulação Habblaud; validar a duração visual em execução |
| Clicar no personagem e abrir perfil | Implementado: perfil Cockpit com nome editável, projeto, harness, status, duração da aba, diretório e histórico de estados observado nesta execução; seguir/centralizar controlam a câmera Canvas |
| Abrir terminal correspondente pelo perfil | Implementado: seleciona projeto e aba exata e mostra o multiplexador existente numa janela sobre o mapa |
| Tema e preferências visuais do mundo | Implementado no Canvas WebView: preferências locais persistentes; não altera tema do editor |
| Reorganizar panes sem controller/viewport descartado | Fluxo alterado para aguardar um frame entre detach e mount; falta repetir manualmente o gesto no macOS |
| Notificação genérica de espera | Implementado: estado `waiting` produz balão/atividade e sino; resposta acontece na janela do terminal real |
| Sons ambientais de teclado/elevador/atividades sociais | Implementado no Canvas Habblaud; opção local desligada por padrão e áudio liberado no primeiro gesto dentro do mundo |
| Chegada e continuidade dos agentes | Implementado no Canvas: chegada pelo elevador na primeira criação da sessão; alternar entre Office e terminal mantém o WebView e a posição atual dos personagens |
| Edição de roupa/peças do personagem | Pendente: o editor do Habblaud persiste aparência por sala no store; Cockpit ainda não possui preferências de aparência por workspace |
| Linha do tempo detalhada, tarefas, tokens, modelo e ferramentas | Pendente: Cockpit só registra transições genéricas de estado; não lê transcript nem coleta métricas uniformemente entre harnesses |
| Gamificação social (moedas, jogos, amizades e ranking) | Fora desta integração: depende dos eventos/tarefas e armazenamento social do Habblaud; não deve exibir valores fictícios no Cockpit |

## 2. Decisão arquitetural

### Aparência individual dos agentes (24/10/2026)

As peças do personagem são persistidas em `office.characterParts` pela chave
`projectId:sessionId`. Duas sessões na mesma sala têm aparência independente.
A configuração antiga, que usava somente `projectId`, migra uma única vez para
a sessão mais antiga presente na sala; os demais agentes usam a própria aparência
gerada. Editar ou restaurar um agente não altera seus colegas.

O cache de retratos considera o agente, nome e peças atuais. Depois de salvar
uma edição, o perfil recarrega a imagem e guarda as peças salvas para a próxima
abertura do editor, sem exigir que o usuário feche o perfil. A lista, o histórico
e o snapshot do mapa consultam a mesma preferência individual.

Regressões cobertas por `app_settings_office_appearance_test.dart` e
`office_agent_profile_appearance_test.dart`: isolamento, persistência, migração,
restauração individual e atualização do retrato com o perfil aberto.

O Habblaud separa simulação, renderer, câmera e input. O Cockpit instancia esses
módulos diretamente, sem iniciar o cliente de produto nem a conexão dele com
store/rede. Assim, o Cockpit mantém autoridade sobre projetos, sessões e status,
e o Habblaud cuida de movimento, poses, rotas e desenho.

```mermaid
flowchart LR
  VM[CockpitViewModel: projects + sessions] --> D[HabblaudWorldWebView: Dart adapter]
  D -->|snapshot JSON via JS bridge| S[Habblaud Sim.applySnapshot]
  S --> R[Habblaud Renderer + Overlay]
  C[Camera + input Habblaud] --> R
  R --> CV[Canvas 2D em InAppWebView]
  CV -->|officeAgentClicked(sessionId)| D
  D -->|seleciona projeto e aba| VM
  VM --> T[TerminalView correspondente]
```

O wrapper cria `Sim`, `Renderer`, `Overlay` e `Camera`, instala `attachInput`,
carrega assets locais, mantém o `requestAnimationFrame` e expõe
`window.cockpitHabblaudWorld.update/selectAgent/destroy`. O Flutter carrega o
bundle em `InAppWebViewInitialData`. A base URL
`https://cockpit.local/habblaud-world/` dá uma origem à página embutida; não há
servidor atendendo essa URL e o escritório não depende de rede.

O Canvas do Habblaud desenha a região visível da camada estática, descarta
elementos fora do viewport, mantém cache de arte e limita o DPR a 3. O objetivo
é usar o mesmo motor visual sem executar um painter Flutter completo a cada
frame.

### Plataformas

`OfficeWorldView` escolhe o backend:

- macOS/Windows: `HabblaudWorldWebView`, motor Habblaud Canvas 2D.
- Linux: `OfficeWorldFlutterView`, fallback porque o Cockpit não oferece a
  WebView incorporada usada nesta integração.

O fallback Flutter tem atlas, mapas, clock de 33 ms, estados e saída próprios.
Ele não é o motor de simulação original nem tem paridade garantida de efeitos.

## 3. Montagem na interface

O ponto de montagem fica no `_CenterPanel` de
`lib/app/cockpit/ui/cockpit_page.dart`:

1. `_officeView` começa `true`, deixando o escritório como visão inicial.
2. As salas vêm de `vm.rootProjects`, das worktrees de cada raiz e de
   `vm.remoteWorkspaces`; o terminal interno sistêmico é excluído.
3. As sessões vêm de `vm.allSessions`.
4. A topbar alterna entre escritório e terminais. A ação **Abrir terminal** no
   perfil seleciona projeto e aba e abre uma janela sobre o mapa. A janela usa
   o multiplexador normal do workspace; não cria outro PTY nem interpreta o
   protocolo de permissão de um harness específico. Perguntas interativas que
   aparecem no terminal podem ser respondidas ali como no terminal normal.
5. O perfil edita o nome através do rótulo persistente da aba do Cockpit; o
   Habblaud recebe `displayTitle`, que continua acompanhando OSC enquanto não
   houver rótulo manual. O nome escolhido é específico daquela sessão/aba.
6. `Mostrar terminais`/`Mostrar escritório` estão traduzidos nos três locales
   Slang (`lib/i18n/*.i18n.json`).

A escolha escritório/terminais é estado de página e não persiste entre boots.

## 4. Contrato Cockpit → Habblaud

`HabblaudWorldWebView._snapshot()` cria um `OfficeSnapshot` para
`Sim.applySnapshot`. IDs de projeto e sessão são mantidos estáveis.

### Salas

| Campo | Origem |
| --- | --- |
| `id` | `Project.id` |
| `name` | `Project.name` |
| `path` | `Project.effectiveRoot` (inclui path remoto) |
| `slot` | posição na lista enviada pelo `_CenterPanel` |
| `seed` | hash determinístico de `Project.id` |
| `createdAt` | `Project.createdAt` em milissegundos |

### Personagens

Só entram `TerminalSession`s com `activeHarness != null` e `projectId` presente
nas salas. Shells comuns sem harness detectado não aparecem.

| Campo | Mapeamento atual |
| --- | --- |
| `id` | `TerminalSession.id` |
| `kind` | Sempre `main` |
| `roomId` | `TerminalSession.projectId` |
| `name` | `session.displayTitle` (rótulo manual persistido vence o título dinâmico OSC); fallback do harness |
| `look` | `f`/`m` determinístico pelo seed de projeto + sessão |
| `sessionId` | ID da sessão; o bridge de clique usa esse ID |
| `status` | `working`, `waiting` ou `idle` de `TerminalStatus` |
| `statusSince` | momento em que o adapter percebeu a última mudança de status |
| `startedAt` | `TerminalSession.createdAt` (início da aba/PTy atual; ao restaurar não representa a idade da conversa histórica) |
| `recent`, `activity` | mudanças genéricas de estado do Cockpit; até 30 no snapshot, sem texto/transcript do agente |
| `tasks` | lista vazia: Cockpit ainda não mapeia as tarefas internas dos diferentes harnesses |
| `stats` | placeholders zero exigidos pelo contrato Habblaud; não são mostrados no perfil como medições |

Contas/providers são sintéticos: Codex → `codex`, Antigravity → `antigravity`;
Claude Code, Cursor, GitHub Copilot, OpenCode e Pi são agrupados como `claude`.
As contas `cockpit-*` usam `usageStatus: disabled` e não leem arquivos privados
nem uso real dos providers. Isso satisfaz o formato da simulação, mas não
diferencia todos os harnesses nem contas reais.

## 5. Atualização, animações e input

A sessão pode mudar sem reconstruir o painel pai. Por isso o adapter checa as
assinaturas a cada 250 ms e também reage a `didUpdateWidget`. A assinatura
contém preferências visuais, projeto (id/nome/path/criação) e sessão
(id/projeto/título/harness/status). Só envia novo snapshot quando a assinatura
muda; `rev` incrementa a cada envio.

O botão de paleta na topbar abre preferências persistidas em `AppSettings`:
tema (automático/original/Natal/Halloween), etiquetas, balões, ritmo de
movimento, ciclo dia/noite e sons ambientais. O snapshot leva essas opções para
o bundle Habblaud. A seleção do personagem abre o perfil Flutter; a seleção é
refletida no overlay Canvas e removida ao fechar. Linux usa o renderer Flutter
de fallback: o perfil funciona, mas sons Habblaud e controles avançados de
aparência não são mostrados nessa plataforma.

A simulação original cuida de spawn, entrada, pathfinding, poses/direções,
atividades ociosas, reações, ausência, saída e atualização/demolição de salas.
O Habblaud usa `MISSING_DEBOUNCE_MS = 3000`: uma ausência transitória não inicia
imediatamente a saída; após o debounce, a simulação muda o modo e planeja o
caminho de saída. O adapter não apaga o sprite diretamente.

O comportamento inicial foi adaptado para o Cockpit: `main.ts` aplica o
primeiro snapshot com as salas e sem agentes, e logo depois o snapshot real.
Assim, as salas aparecem prontas e os agentes existentes fazem a chegada pelo
elevador na primeira criação da sessão. O Habblaud mantém a instância da
simulação enquanto a página continua aberta. O Cockpit agora cria o WebView na
primeira entrada no Office e o mantém montado, fora da tela, enquanto o usuário
volta ao terminal. Isso preserva fila de movimento, posição, pose, câmera e
estado social; ao voltar ao Office, o personagem continua do ponto em que estava
em vez de repetir a chegada. Fechar/reiniciar o aplicativo ainda cria uma nova
simulação e repete a chegada inicial.

O histórico do perfil contém até 200 eventos de hook observados na sessão atual
do Cockpit, mantidos em memória. O adapter mapeia eventos para categorias do
Habblaud e usa apenas o nome da ferramenta (máximo 80 caracteres) para
`PreToolUse`/`PostToolUse`; nunca encaminha argumentos, prompt, resposta ou
saída. Helpers antigos continuam enviando só a mudança genérica de status. O
snapshot envia as atividades recentes para os balões e o histórico do Habblaud.
Uma espera
mostra a atividade “Precisa de você no terminal”; o Cockpit não tenta extrair
qual botão/operação foi pedido. Os sons ambientais são `SoundCues` e `SoundBoard`
originais do Habblaud, com as categorias e limites de frequência do projeto;
uma transição para `waiting` também pode tocar o sino de alerta. Como exige um
gesto da página, o áudio só fica desbloqueado depois de interagir com o mapa.

`attachInput` liga pan/zoom e reenquadramento à câmera, além de hover e hit-test.
Clique simples e duplo chamam `officeAgentClicked`; Dart suprime chamadas
duplicadas para o mesmo agente dentro de 350 ms. `selectAgent` atualiza o
destaque e o perfil Flutter usa `focusAgent` e `setFollowAgent` para
centralizar/seguir o personagem. A interação manual com o mapa interrompe o
acompanhamento, como no Habblaud.

### Dados que ainda não chegam ao perfil/mundo

O hook transporta nomes de ferramentas e eventos de início/fim de subagentes
para Claude Code e Codex. Ainda não há coleta genérica de tarefas, progresso,
tokens, erros ou uso de conta; `tasks` segue vazio e modelo/custo não são
inferidos.

### MCP e criação de agentes

No checkout analisado não há servidor MCP de agentes nem uma API MCP que
represente subagentes criados por qualquer harness. O Cockpit oferece a CLI
`cockpit` para operar abas e sessões, mas `new-tab` cria uma aba de terminal;
não é uma API de spawn de subagentes. O caminho de ciclo de vida no Office usa
`cockpit-hook` → socket local (ou encaminhamento do sidecar remoto). Claude e
Codex implementam os eventos nativos; para outro harness, um adaptador precisa
emitir o mesmo contrato neutro. Não inferir filhos de processos ou chamadas MCP.

O snapshot continua sendo a única entrada de estado para o Habblaud; novas
integrações devem alimentar esse mesmo modelo, sem criar uma segunda fonte de
verdade.

## 6. Assets e licenças

Há dois conjuntos:

1. `assets/habblaud_world/engine.js` e `tool/habblaud_world/assets.ts`: runtime
   Canvas da WebView. `assets.ts` embute o manifesto e imagens de marca/quadros
   do `client/public/assets` do checkout Habblaud usado no build. A arte dos
   personagens é renderizada pelo módulo `client/src/art` embutido no bundle.
2. `assets/habblaud_art/`: spritesheets/metadados de personagens, carros,
   ícones e 17 mapas usados pelo renderer Flutter alternativo.

Cada grupo contém uma cópia de `LICENSE` MIT. Manter esses arquivos ao distribuir
ou alterar arte derivada. Os diretórios estão declarados no bloco `flutter/assets`
de `pubspec.yaml`.

O bundle JS tem aproximadamente 1,5 MB, além dos assets Flutter do fallback.
Imagens do bundle são data URLs locais. Não introduzir CDN, `fetch` remoto ou
servidor HTTP como dependência do mapa sem uma decisão explícita.

## 7. Arquivos e responsabilidades

| Arquivo | Responsabilidade |
| --- | --- |
| `lib/app/cockpit/ui/cockpit_page.dart` | Monta mapa, lista projetos/worktrees/remotos e apresenta o multiplexador normal numa janela Office ao abrir a sessão |
| `lib/app/cockpit/ui/widgets/office_world_view.dart` | Seleciona backend por plataforma e exporta `OfficeWorldLabels` |
| `lib/app/cockpit/ui/widgets/habblaud_world_webview.dart` | WebView, snapshots, polling, carga HTML e bridge de clique |
| `lib/app/cockpit/ui/widgets/office_world_flutter_view.dart` | Fallback Flutter e sua simulação/render próprios |
| `lib/app/cockpit/ui/widgets/cockpit_topbar.dart` | Botão escritório/terminais |
| `tool/habblaud_world/main.ts` | Adapter JS sobre `Sim`, `Renderer`, `Overlay`, `Camera`, input e sons originais |
| `tool/habblaud_world/assets.ts` | Assets Base64 embutidos para o wrapper |
| `tool/habblaud_world/README.md` | Caminho do checkout de origem e comando esbuild |
| `assets/habblaud_world/engine.js` | Bundle consumido pelo Flutter |
| `assets/habblaud_world/LICENSE` | Licença do bundle/arte |
| `assets/habblaud_art/` | Assets do fallback Flutter |
| `lib/app/cockpit/ui/viewmodels/cockpit_viewmodel.dart` | Lifecycle da sessão e operações de pane/dock |

## 8. Rebuild e validação

O runtime distribuído é autocontido: não exige checkout Habblaud para iniciar.
Para reconstruir, o checkout fonte precisa estar em `../../habblaud` a partir do
diretório Cockpit, com esbuild instalado lá:

```sh
../../habblaud/node_modules/.bin/esbuild tool/habblaud_world/main.ts \
  --bundle --format=iife --target=es2022 \
  --outfile=assets/habblaud_world/engine.js
```

Checagem TypeScript (binário do checkout fonte):

```sh
../../habblaud/node_modules/.bin/tsc --noEmit --strict \
  --target ES2022 --module ESNext --moduleResolution Bundler \
  --lib ES2023,DOM,DOM.Iterable --allowImportingTsExtensions \
  tool/habblaud_world/main.ts
```

Checagem Flutter dos call sites/integração:

```sh
flutter analyze --no-pub \
  lib/app/cockpit/ui/cockpit_page.dart \
  lib/app/cockpit/ui/viewmodels/cockpit_viewmodel.dart \
  lib/app/cockpit/ui/widgets/cockpit_topbar.dart \
  lib/app/cockpit/ui/widgets/office_world_view.dart \
  lib/app/cockpit/ui/widgets/office_world_flutter_view.dart \
  lib/app/cockpit/ui/widgets/habblaud_world_webview.dart
```

### Verificação manual no macOS

1. `flutter run -d macos`: confirmar Canvas visível e ausência de erro JS/WebView.
2. Workspace com agente: confirmar sala, nome e estado; terminal shell comum não
   deve virar personagem.
3. Alternar working/waiting/idle e observar atualização sem reload da página.
4. Clicar no agente: abrir perfil, usar **Abrir terminal** e confirmar que a
   janela sobre o mapa mostra o terminal da aba selecionada e aceita entrada.
5. Editar o nome no perfil; conferir que ele aparece no personagem e continua
   após reiniciar o Cockpit. Iniciar um turno e provocar uma espera; conferir a
   linha do tempo genérica, balão e, com sons ativados, o sino após interagir
   com o mapa.
6. Fechar a janela do terminal: confirmar que o mapa continua no mesmo estado;
   alternar para a visão normal de terminais e confirmar que é a mesma sessão.
7. Fechar terminal/agente: observar debounce e saída animada; conferir também
   quando o processo encerra sem fechar a aba.
8. Alternar mapa/terminais pela topbar.
9. Com várias panes, arrastar para acoplar/criar split e redimensionar divisor;
   conferir que a UI responde e o processo continua vivo.
10. Remover workspace com agente e observar saída e atualização da sala.

No Linux, repetir a verificação funcional no fallback, sem assumir paridade
visual/animada com o Canvas original.

## 9. Decisões e incidentes registrados

- Canvas 2D foi escolhido para reutilizar o motor do Habblaud, não apenas uma
  imagem ou outra simulação Flutter no macOS/Windows.
- O `createWorld` completo não é usado porque está acoplado ao store/rede do
  Habblaud. O wrapper local aplica snapshots diretamente em `Sim`.
- O aviso observado `unhandled element <filter/>; Picture key: Svg loader` vem
  do caminho de parse de SVG. Sem o nome do arquivo/asset no log, ainda não foi
  possível atribuí-lo a uma imagem específica; não assumir que é o Canvas ou a
  animação sem essa evidência.
- Ao arrastar/reorganizar pane, foi observado `ChangeNotifier was used after
  being disposed` em `TerminalRenderBox.attach`. A view tentava reanexar um
  `ViewportOffset` que o `Scrollable` antigo já havia descartado. Operações de
  mover/acoplar/split agora deixam a sessão fora da árvore por um frame antes
  de montá-la no destino. O fechamento manual também aguarda o frame antes de
  descartar o controller. Análise estática passou; falta repetir o gesto no app.
- Linhas `FlutterWebViewController - dealloc`, `WebViewChannelDelegate -
  dealloc`, `FindInteractionControl - dealloc` e `InAppWebView - dealloc` são
  logs de desalocação. Isoladamente, não indicam falha do renderizador.
- TypeScript passou, esbuild gerou o bundle e a análise Flutter dos arquivos
  alterados passou. Isso não substitui validação visual no macOS; o último
  relato de runtime ainda precisa ser reproduzido após a correção do dock.

## 10. Próximos passos

1. Rodar o roteiro manual e validar o drag/drop, inclusive foco e estado durante
   o frame em que a aba fica fora da árvore.
2. Decidir se o modo escritório deve persistir e se Linux seguirá com fallback.
3. Definir o contrato de eventos para preencher atividade, tarefas, shells,
   estatísticas e subagentes com dados reais dos hooks.
4. Diferenciar os providers atualmente agrupados em `claude`; decidir que
   metadados podem ser expostos sem ler configuração privada do agente.
5. Ligar seleção/follow visual do Habblaud à seleção de Flutter, se desejado.
6. Tornar o rebuild do bundle autocontido caso contribuidores não mantenham o
   checkout Habblaud em `../../habblaud`; o runtime distribuído já é autocontido.

## 11. Avisos de sessão aguardando resposta

O `CockpitPage` observa sessões `TerminalSession` com `status == waiting` e
harness ativo. No modo Office, exibe até três cartões no canto inferior direito
com o nome da sessão/projeto, **Responder** e dispensar. A entrada é a mesma
transição genérica que alimenta o status e o histórico do personagem; o cartão
não procura palavras no transcript e não depende de Claude, Codex ou outro
provider específico.

**Responder** seleciona o workspace/projeto, a pane e a aba da sessão original,
e abre o multiplexador de terminal existente sobre o mapa. Não cria PTY, não
envia teclas e não marca a permissão como aprovada. A resposta acontece no
prompt real do terminal, preservando o protocolo próprio do CLI e do provider.
Dispensar oculta o cartão durante o período em que a sessão permanecer em
`waiting`; a próxima mudança de estado limpa essa dispensa. Fechar o terminal
flutuante não altera o status nem fecha a sessão.

Esse fluxo cobre prompts de permissão quando os hooks do Cockpit reportam
`waiting`. Um prompt que não seja detectado pelo harness/hooks não pode ser
identificado com segurança sem suporte adicional do provider. A implementação
deliberadamente não finge que conseguiu aprovar um pedido nesses casos.

## 12. Editor de personagem

No renderer Canvas (macOS/Windows), o perfil do agente oferece **Editar
personagem**. A tela usa o próprio bundle Habblaud para prévia Canvas, paletas, opções por peça, compatibilidade entre
cabelo/acessórios, ajuste de cores ao trocar o estilo e sorteio de aparência.
As partes escolhidas ficam em `AppSettings.officeCharacterParts`, por ID de
projeto. O nome gerado segue o pool determinístico brasileiro do Habblaud,
associado ao ID de sessão, sem colisões entre personagens ativos e persistido
em `AppSettings.officeAgentNames`. Um rótulo manual da sessão substitui o nome
gerado; limpar o rótulo restaura o nome gerado. Roupas são preferência visual
da sala/projeto. Ao salvar, a próxima atualização de snapshot aplica as partes
aos personagens visíveis e às sessões futuras daquele projeto.
O fallback Flutter (Linux) mantém o perfil e a abertura do terminal, mas não
exibe esse editor enquanto não tiver a mesma API de arte/previsualização.

## 13. Animações, comportamentos e sons

O adapter não redesenha a simulação: ele alimenta `Sim`, `Renderer`, `Overlay` e
`SoundCues` originais do Habblaud. O estado de `TerminalSession` é traduzido
para `working`, `waiting` e `idle`, acionando as regras existentes:

- **Chegada:** o primeiro snapshot cria as salas sem personagens; a atualização
  seguinte introduz as sessões pelo elevador. O personagem caminha na chegada.
- **Trabalho:** `working` o leva à mesa e aciona a pose de digitação quando está
  sentado. Pela regra Habblaud, ele corre em trajetos longos quando já está
  dentro da sala; a primeira chegada continua caminhando.
- **Espera:** `waiting` aciona a postura/balão de alerta e o sino na transição
  para esse estado.
- **Ociosidade:** `idle` libera passeios de copa, lounge e interações sociais;
  o ritmo segue a preferência de movimento. Depois de muito tempo pode cochilar.
- **Saída:** quando uma sessão deixa de aparecer no snapshot, a simulação aplica
  o debounce e toca a animação de saída pelo elevador.
- **Sons:** a preferência do Office agora tem volume e categorias separadas para
  alertas, teclado, elevador e atividades sociais. O teclado só toca para quem
  está sentado digitando em área visível. O navegador libera áudio após gesto do
  usuário; o master switch começa desligado, como no Habblaud.

O estado genérico não informa qual comando está rodando. Assim, a atividade de
ferramenta depende de hooks instalados e não lê texto do terminal. Tokens e
modelo efetivo continuam indisponíveis para harnesses genéricos.

## 14. Subagentes

Claude Code e Codex CLI registram `SubagentStart` e `SubagentStop` no helper
`cockpit hook`. Um adapter de qualquer outro harness também pode reportar o
ciclo por `cockpit agent start <id> [--type <role>]` e
`cockpit agent stop <id> [--outcome success|error|interrupted]`. O payload leva
somente `agent_id`, `agent_type` e o estado de saída opcional (com limite de
tamanho); prompts, transcripts e conteúdo dos resultados não são enviados. O
evento percorre o mesmo socket local ou o protocolo remoto de `turn.status`.
No cliente, o evento é roteado à sessão/aba pai e salvo no descritor da aba:
`SubagentStart` cria um personagem `kind: sub` na sala do pai e
`SubagentStop` marca-o como concluído. O simulador original faz a entrega ao
personagem principal e a saída; o registro concluído permanece por até 45 s
para permitir a animação. A vida do subagente não muda o status do terminal pai.

O nome e a aparência do personagem são determinísticos a partir do ID reportado
pelo evento. O tipo do subagente aparece como papel. Eventos de conclusão ficam
por 45 s para a animação, enquanto um agente ativo restaurado há mais de 24 h é
descartado como estado obsoleto. A CLI usa a aba atual como pai; `--tab-id`
escolhe explicitamente a aba e `--parent-agent-id` permite relacionar um filho
a outro subagente. Se o pai não estiver na sala, o ator é ligado à sessão
principal. Agentes que não emitirem o contrato não geram personagens
automaticamente. O CLI pode relatar falha/interrupção; esses personagens saem
sem a animação de entrega. Hooks nativos omitem o resultado quando não há um
status confiável, mantendo a animação padrão de conclusão.

### Interação com o terminal no Office

O perfil do agente e o botão **Responder** das notificações abrem uma janela
que espelha as últimas linhas do buffer da sessão e envia texto/teclas ao PTY
existente por `TerminalSession`. Ela não monta outra `TerminalView`, não cria
uma segunda sessão e não interpreta o protocolo de aprovação de um provider.
Assim, o usuário vê a mesma pergunta/opções do terminal e responde com texto,
Enter, setas, Tab, Esc ou Ctrl+C. Se a aba for fechada, a janela deixa de
receber entrada. Esta interação continua genérica para qualquer processo que
rode no PTY do Cockpit.
