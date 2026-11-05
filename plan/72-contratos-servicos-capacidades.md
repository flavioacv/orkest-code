# A01 · Especificação de Contratos de Serviços e Capacidades (Orkest Code)

> **Documento:** `plan/72-contratos-servicos-capacidades.md`  
> **Status:** Concluído / Aprovado para Implementação  
> **Contexto:** Evolução da arquitetura híbrida Orkest Code baseada no inventário OpenIDEA (`plan/72-orkest-ide-completa.md`)  
> **Branch:** `fix/harness-state-detection`

---

## 1. Visão Geral e Princípios Fundamentais

Esta especificação define os contratos de serviços, ownership, garantias de concorrência, tratamento de erros, versionamento e negociação de capacidades para o protocolo de comunicação cliente-servidor do **Orkest Code** (`cockpit/packages/orkest_protocol/`, `orkest_remote/`, `orkest_server/` e `orkest_engine/`).

### Princípios Arquiteturais:
1. **Single Writer Rule (Dono Único de Buffer/Documento):** Apenas um subsistema ou ator pode deter a autoridade de escrita de um documento/buffer ativo a qualquer momento. Conflitos entre edição do usuário, assistentes autônomos e operações do sistema de arquivos são mediados por controle estrito de versões monotônicas.
2. **Defesa em Camadas no Cancelamento:** O cancelamento de operações assíncronas é cooperativo (notifica o executor remoto via `rpc.cancel` com `rid`) e preventivo na UI (descarte local imediato do ID da requisição, garantindo que respostas em voo não contaminem o estado).
3. **Consistência UTF-16:** Todas as coordenadas de texto (linha, coluna, offsets, seleções, substituições e diagnósticos) usam UTF-16 code units, em total conformidade com a especificação LSP e o motor de renderização de texto do Flutter.
4. **Resiliência e Tolerância a Tipos Desconhecidos (Forward Compatibility):** Mensagens não reconhecidas por clientes ou servidores legados decodificam para mensagens neutras (`UnknownMessage`), preservando a conexão sem derrubar o canal JSONL.

---

## 2. Modelo de Ownership de Recursos

| Recurso | Autoridade Primária | Ciclo de Vida | Garantia de Concorrência |
| :--- | :--- | :--- | :--- |
| **Projeto / Workspace** | Cliente (`projects_rail`, Workspace Model) | Vinculado à pasta raiz selecionada no cliente. | O servidor remoto atua como executor de comandos e observador de arquivos sob a raiz informada. |
| **Sessão PTY** | Servidor (`orkest_server`) | Criada via `pty.open`, identificada por `sessionId` e `pid`. | Uma sessão suporta múltiplos observadores (`pty.attach`), mas a entrada (`pty.input`) é sequencializada pelo socket da PTY. |
| **Documento / Buffer de Edição** | Editor Host (Cliente Flutter) | Abre ao carregar arquivo; persiste em dirty state até save explícito ou fechamento. | **Regra do Dono Único:** A UI mantém o estado canônico em memória. Se um agente ou comando externo alterar o arquivo em disco, dispara-se notificação de conflito (`fs.conflict`), exigindo merge ou confirmação do usuário. |
| **Sessão LSP / DAP** | Pool de Serviços (Cliente ou Sidecar) | Por linguagem/projeto. | Cada requisição carrega `id`/`rid` único; respostas obsoletas são filtradas pelo número de versão do documento ativo. |

---

## 3. Coordenadas de Texto e Normalização de Quebras de Linha

1. **Unidades de Posição:**
   - Linhas e colunas são indexadas em `0`.
   - Colunas são expressas estritamente em **UTF-16 code units**. Caracteres fora do BMP (ex.: emojis 4-bytes compostos por surrogate pairs) ocupam 2 unidades de coluna, alinhando-se com Dart strings e servidores de linguagem (LSP).
2. **Fim de Linha (EOL):**
   - Na leitura de arquivos (`fs.read`), detecta-se o terminador predominante: `LF` (`\n`) ou `CRLF` (`\r\n`).
   - O buffer em memória normaliza internamente para `\n` para cálculos simples de offset.
   - Na gravação (`fs.write`), o terminador original é restaurado, impedindo diffs poluídos em sistemas heterogêneos (macOS/Linux/Windows).

---

## 4. Negociação de Capacidades no Handshake (`Hello` & `HelloAck`)

Para permitir evolução desacoplada entre cliente (`cockpit`) e servidor (`orkest_server` ou sidecar nativo), o envelope do handshake suporta o mapa declarativo `caps` (`capabilities`):

### Estrutura do `Hello`:
```json
{
  "t": "hello",
  "v": 2,
  "client": "orkest-cockpit",
  "loc": true,
  "tok": "optional-token",
  "caps": {
    "rpc_cancel": true,
    "fs_streaming": true,
    "pty_ack": true,
    "vcs": true
  }
}
```

### Estrutura do `HelloAck`:
```json
{
  "t": "hello.ack",
  "v": 2,
  "server": "0.1.0",
  "exe": "/path/to/server",
  "pid": 1234,
  "caps": {
    "rpc_cancel": true,
    "fs": true,
    "git": true,
    "dap": false,
    "pty_resize": true
  }
}
```

---

## 5. Protocolo RPC, Erros Tipados e Cancelamento Cooperativo

### 5.1 Envelopes RPC

* **Requisição (`RpcRequest`):**
  - `t`: `"rpc"`
  - `rid`: Identificador monotônico crescente da requisição (inteiro).
  - `m`: Método com namespace dot-separated (ex.: `"fs.readFile"`, `"git.status"`, `"search.query"`).
  - `p`: Mapa de parâmetros (`params`).

* **Resposta (`RpcResponse`):**
  - `t`: `"rpc.res"`
  - `rid`: Eco do ID da requisição.
  - `ok`: `true` se a operação teve sucesso; `false` se houve falha de negócio ou sistema.
  - `data`: Objeto de dados em caso de sucesso (`ok: true`).
  - `code`: Código do erro em caso de falha (`ok: false`).
  - `detail`: Detalhe descritivo legível por humanos / logs técnicos.

* **Cancelamento (`RpcCancel`):**
  - `t`: `"rpc.cancel"`
  - `rid`: ID da requisição a ser interrompida.
  - `reason`: Motivo opcional (ex.: `"user_cancelled"`, `"stale_query"`, `"buffer_closed"`).

### 5.2 Catálogo de Códigos de Erro Estruturados (`RemoteError` / `RpcResponse.code`)

| Código | Descrição | Ação Recomendada na UI |
| :--- | :--- | :--- |
| `session_not_found` | Sessão PTY solicitada não existe ou encerrou. | Remover aba ou notificar encerramento. |
| `spawn_failed` | Falha ao instanciar processo remoto ou sidecar. | Exibir alerta com mensagem do sistema operacional. |
| `version_mismatch` | Versão incompatível do protocolo de comunicação. | Oferecer atualização automática do servidor. |
| `rpc_cancelled` | Operação interrompida por solicitação explícita. | Silenciar resultado; liberar recursos locais. |
| `rpc_timeout` | Tempo limite esgotado antes da resposta. | Informar timeout e oferecer repetição. |
| `file_not_found` | Caminho solicitado não existe no sistema remoto. | Notificar usuário ou remover da lista de abas. |
| `document_dirty_conflict`| Tentativa de gravação sobreposta a buffer com edições não salvas. | Apresentar diálogo de resolução de conflito / diff. |
| `unsupported_capability`| Método solicitado exige capacidade ausente no handshake. | Desabilitar botão/menu correspondente na interface. |

---

## 6. Streaming, Backpressure e Limites de Payload

1. **PTY Output Backpressure:**
   - O servidor emite `pty.output` com o offset cumulativo de bytes enviados.
   - O cliente confirma periodicamente o consumo via `pty.ack` (`{"t": "pty.ack", "id": "s1", "offset": 1024}`).
   - Se o cliente suspender leituras (ex.: app minimizado), o servidor pausa o buffer de saída do PTY até novo ack ou teto de descarte.
2. **Teto de Payloads RPC:**
   - Mensagens individuais de RPC (`fs.readFile`, `search.query`) possuem teto recomendado de **4 MB**.
   - Arquivos maiores que o teto devem ser lidos em blocos paginados (`fs.readChunk`) ou abertos em modo streaming/somente leitura simplificado.

---

## 7. Matriz de Comandos: Mapeamento dos 41 Domínios OpenIDEA para Orkest Code

Mapeamento completo dos domínios extraídos da análise estática OpenIDEA para a arquitetura híbrida Orkest Code:

| Domínio OpenIDEA | Escopo de Execução | Contrato / Implementação Orkest | Detalhes Arquiteturais |
| :--- | :--- | :--- | :--- |
| `workspace` | Local (Dart) | `ProjectsRail`, `WorkspaceSession` | Busca dinâmica de projetos mantida; estado persistido localmente. |
| `editor` | Local (Dart) | `CodeEditorController`, Text Edit Engine | Buffer virtual em memória; donos exclusivos por aba. |
| `editor_sync` | Local (Dart) | `DocumentSyncHost` | Diffs incrementais, marcação de dirty state e auto-save coordenado. |
| `lsp` | Híbrido | `LspServerPool`, `LspClient` | Processos LSP locais ou gerenciados; comunicação JSON-RPC LSP padrão. |
| `lsp_catalog` | Local (Dart) | `LanguageCatalog` (`lsp_launchers.dart`) | Metadados declarativos de 17 linguagens (L01). |
| `vcs` / `git` | Híbrido / Remoto | `git.*` via `RpcRequest` (ou Rust Host A03) | Operações atômicas com `rid`; status, log, diff, commit, branch. |
| `terminal` / `pty` | Remoto / Sidecar | `pty.*` via `orkest_protocol` | Multiplexação de terminais com PTY real e controle de janela. |
| `harness` | Local (Dart) | `HarnessDetector`, `TerminalSession` | Detecção não-invasiva de Claude Code, Aider, Codex e shell ocioso. |
| `fs` | Remoto / Local | `fs.*` via `RpcRequest` | Listagem, leitura com detecção EOL, gravação atômica, exclusão. |
| `search` | Local / Remoto | `SearchIsolate` / `search.*` RPC | Busca de texto com regex, filtros glob e cancelamento por `rid`. |
| `settings` | Local (Dart) | `SettingsPage`, `PreferencesService` | Configurações persistidas em JSON local (`PreferencesStorage`). |
| `dap` (Debug) | Híbrido | `DapClient`, `DebugAdapterConfig` | Sessões de depuração com breakpoints e inspeção de variáveis. |
| `snippets` | Local (Dart) | `SnippetEngine`, LSP Completion | Inserção de snippets com tab-stops no editor de código. |
| `diagnostics` | Local (Dart) | `DiagnosticsCollector` | Agregação de erros e avisos de LSP e linters por URI de arquivo. |
| `symbols` | Híbrido | `LspClient` (`textDocument/documentSymbol`) | Outline de classes, métodos e campos para navegação rápida. |
| `navigation` | Híbrido | `LspClient` (`textDocument/definition`) | Go to definition, implementation, references com coordenadas UTF-16. |
| `format` | Híbrido | `LspClient` (`textDocument/formatting`) | Formatação do documento inteiro ou seleção com preview de diff. |
| `rename` | Híbrido | `LspClient` (`textDocument/rename`) | Renomeação segura em múltiplos arquivos via WorkspaceEdit. |
| `quickfix` | Híbrido | `LspClient` (`textDocument/codeAction`) | Ações de código e correções sugeridas pelo compilador. |
| `inlay_hints` | Híbrido | `LspClient` (`textDocument/inlayHint`) | Dicas visuais inline de tipos e parâmetros (sob demanda L06). |
| `folding` | Local (Dart) | `FoldingRangeProvider` | Recolhimento de blocos de código via indentação ou LSP. |
| `hover` | Híbrido | `LspClient` (`textDocument/hover`) | Tooltips ricos com documentação e tipos de símbolos (L02a). |
| `signature` | Híbrido | `LspClient` (`textDocument/signatureHelp`) | Guia de parâmetros da função ativa com índice ativo (L02b). |
| `completion` | Híbrido | `LspClient` (`textDocument/completion`) | Autocomplete de código com resolve sob demanda e cancelamento (L02c-e). |
| `command_palette`| Local (Dart) | `CommandPaletteOverlay` | Busca rápida de ações, comandos e arquivos sem perder o foco. |
| `keybindings` | Local (Dart) | `ShortcutRegistry` | Mapeamento customizável de atalhos por plataforma (macOS/Win/Linux). |
| `themes` | Local (Dart) | `ThemeService`, `ColorPalette` | Suporte a temas claro, escuro e alto contraste. |
| `file_icons` | Local (Dart) | `FileIconResolver` | Ícones declarativos mapeados por extensão e nome de arquivo. |
| `status_bar` | Local (Dart) | `StatusBarWidget` | Linha, coluna, encoding, EOL, linguagem ativa, status de Git e LSP. |
| `breadcrumbs` | Local (Dart) | `BreadcrumbBar` | Trilha hierárquica do arquivo e símbolo atual na viewport. |
| `tabs` / `layout`| Local (Dart) | `TabManager`, `SplitPaneView` | Divisão horizontal/vertical de editores e abas de ferramentas. |
| `database` | Local (FFI) | Anaki DB / SQLite | Acesso rápido a histórico, metadados locais e vetores. |
| `task_runner` | Local / Remoto | `TaskRunnerService` | Execução de tarefas (build, test, lint) no terminal ou background. |
| `diff_viewer` | Local (Dart) | `DiffEngine`, `DiffWidget` | Visualizador de diferenças lado a lado ou unificado. |
| `notifications`| Local (Dart) | `NotificationBannerService` | Notificações não-bloqueantes com ações contextuais. |
| `telemetry` | Local (Dart) | `OrkestTelemetry` | Registro de métricas e rastros operacionais (ex.: `r_2b`). |
| `plugin_core` | Local (Dart) | `PluginHost` (futuro P3) | Ponto de extensão para integrações de terceiros. |
| `testing` | Híbrido | `TestRunner`, LSP Test Adapter | Descoberta e execução de testes unitários com status na gutter. |
| `docker` | Remoto / CLI | `DockerCliAdapter` (futuro P3) | Listagem e anexação a containers via terminal. |
| `markdown` | Local (Dart) | `MarkdownPreviewWidget` | Visualização renderizada de arquivos Markdown em tempo real. |
| `clipboard` | Local (Dart) | `ClipboardService` | Integração segura com a área de transferência do sistema. |

---

## 8. Verificação e Critérios de Aceite Atendidos

1. **Ownership claro:** Documento formaliza o editor Flutter como dono exclusivo de buffers abertos, prevenindo conflitos com agentes remotos.
2. **Coordenadas UTF-16:** Padrão uniforme fixado para cursores, ranges e LSP.
3. **Erros tipados e versionamento:** Catálogo de códigos padronizado em `RemoteError` e `RpcResponse`.
4. **Cancelamento em duas camadas:** `RpcCancel` com `rid` emitido para o backend + invalidação imediata no frontend.
5. **Streaming e backpressure:** Fluxo PTY com offsets monotônicos e acks documentado.
6. **Handshake com capacidades:** Suporte a `caps` em `Hello` e `HelloAck` implementado no protocolo.
7. **Matriz de comandos dos 41 domínios:** Mapeamento integral sem deixar lacunas funcionais.
