# Integração do escritório Habblaud no Cockpit

**Estado:** implementação em andamento; arquitetura e ponte estão no código  
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
| Projetos/workspaces como salas | Implementado: raízes, worktrees e workspaces remotos |
| Somente sessões com harness ativo como personagens | Implementado |
| Atualizar nome e estado working/waiting/idle | Implementado a partir da sessão Cockpit |
| Entrada e saída animadas | Acopladas ao ciclo de snapshot da simulação Habblaud; validar a duração visual em execução |
| Clicar no personagem e abrir perfil | Implementado: perfil Cockpit com projeto, harness, status, duração da aba e diretório |
| Abrir terminal correspondente pelo perfil | Implementado: seleciona projeto e aba exata e mostra o multiplexador existente numa janela sobre o mapa |
| Tema e preferências visuais do mundo | Implementado no Canvas WebView: preferências locais persistentes; não altera tema do editor |
| Reorganizar panes sem controller/viewport descartado | Fluxo alterado para aguardar um frame entre detach e mount; falta repetir manualmente o gesto no macOS |
| Dados operacionais completos (tarefas, tokens, ferramentas, subagentes) | Pendente: ainda não fornecidos pela ponte |

## 2. Decisão arquitetural

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
5. `Mostrar terminais`/`Mostrar escritório` estão traduzidos nos três locales
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
| `name` | `session.title`; se vazio, label do harness |
| `look` | `f`/`m` determinístico pelo seed de projeto + sessão |
| `sessionId` | ID da sessão; o bridge de clique usa esse ID |
| `status` | `working`, `waiting` ou `idle` de `TerminalStatus` |
| `statusSince` | momento em que o adapter percebeu a última mudança de status |
| `startedAt` | `TerminalSession.createdAt` (início da aba/PTy atual; ao restaurar não representa a idade da conversa histórica) |
| `recent`, `tasks` | listas vazias |
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
movimento e ciclo dia/noite. O snapshot leva essas opções para `WorldOptions`
no bundle Habblaud. A seleção do personagem abre o perfil Flutter; a seleção é
refletida no overlay Canvas e removida ao fechar. Linux usa o renderer Flutter
de fallback: o perfil funciona, mas os controles avançados de aparência não são
mostrados nessa plataforma.

A simulação original cuida de spawn, entrada, pathfinding, poses/direções,
atividades ociosas, reações, ausência, saída e atualização/demolição de salas.
O Habblaud usa `MISSING_DEBOUNCE_MS = 3000`: uma ausência transitória não inicia
imediatamente a saída; após o debounce, a simulação muda o modo e planeja o
caminho de saída. O adapter não apaga o sprite diretamente.

Na carga inicial, o primeiro snapshot posiciona os personagens já existentes;
agentes que aparecem em snapshots seguintes seguem a chegada normal do mundo.
Fechar uma sessão ou remover um projeto faz o próximo snapshot omitir agente ou
sala e deixa a simulação conduzir o restante do ciclo.

`attachInput` liga pan/zoom e reenquadramento à câmera, além de hover e hit-test.
Clique simples e duplo chamam `officeAgentClicked`; Dart suprime chamadas
duplicadas para o mesmo agente dentro de 350 ms. `selectAgent` existe no JS,
mas ainda não há sincronização de seleção/follow a partir de Flutter.

### Dados que ainda não chegam ao perfil/mundo

Não são enviados eventos reais do hook sobre atividade recente, comandos shell,
tarefas, progresso, tokens, erros, subagentes ou uso de conta. O perfil atual
mostra os campos locais que existem, mas ainda não mostra modelo, tokens,
chamadas de ferramenta ou custo. A simulação
continua animando, mas reações que dependem desses eventos podem não acontecer;
`recent` e `tasks` são vazios. Todos os personagens são `main`, sem
representação de subagentes do Cockpit.

Próxima evolução: projetar eventos já observados pelo Cockpit (especialmente
hooks/monitor de harness) nos campos de `AgentInfo`. O snapshot deve continuar
sendo a única entrada de status para o Habblaud; não criar uma segunda fonte de
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
| `tool/habblaud_world/main.ts` | Adapter JS sobre `Sim`, `Renderer`, `Overlay`, `Camera` e input originais |
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
5. Fechar a janela do terminal: confirmar que o mapa continua no mesmo estado;
   alternar para a visão normal de terminais e confirmar que é a mesma sessão.
6. Fechar terminal/agente: observar debounce e saída animada; conferir também
   quando o processo encerra sem fechar a aba.
7. Alternar mapa/terminais pela topbar.
8. Com várias panes, arrastar para acoplar/criar split e redimensionar divisor;
   conferir que a UI responde e o processo continua vivo.
9. Remover workspace com agente e observar saída e atualização da sala.

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
