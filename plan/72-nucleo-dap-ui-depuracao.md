# Núcleo DAP e UI de Depuração (R02 Orkest Code)

> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`  
> **Status:** Concluído e Validado

---

## 1. Contexto e Motivação
A atividade `R02 · Entregar núcleo DAP e UI de depuração` tem como objetivo fornecer ao Orkest Code a capacidade de depuração interativa baseada no protocolo padrão **Debug Adapter Protocol (DAP)**, eliminando a dependência de plugins externos ou pontes intermediárias pesadas, conforme estabelecido no ADR `plan/72-decisao-arquitetura-por-dominio.md` (A04).

---

## 2. Componentes Implementados

### 2.1. Modelos Tipados do Protocolo DAP (`cockpit/lib/app/core/data/dap/dap_models.dart`)
- **Mensagens Base:** `DapRequest`, `DapResponse`, `DapEvent`.
- **Entidades de Execução:** `DapCapabilities`, `SourceBreakpoint`, `DapBreakpoint`, `DapThread`, `DapStackFrame`, `DapScope`, `DapVariable`, `DapStoppedEvent`, `DapOutputEvent`, `DapEvaluateResult`.
- Serialização bidirecional determinística JSON compatível com a especificação DAP da Microsoft.

### 2.2. Codec e Framing de Rede/Processo (`cockpit/lib/app/core/data/dap/dap_codec.dart`)
- **Protocol Framing:** `Content-Length: <n>\r\n\r\n<payload>` com buffer persistente entre chunks fragmentados.
- **Resiliência a Fragmentação:** Trata payloads divididos em múltiplos pacotes TCP/pipes de stdout sem perda de dados ou estouro de memória.

### 2.3. Cliente Assíncrono DAP (`cockpit/lib/app/core/data/dap/dap_client.dart`)
- Comunicação direta via subprocesso (`Process`) ou streams síncronos de `stdin`/`stdout`.
- Gerenciamento sequencial de requisições com `Completer` casados por `request_seq`.
- Métodos do ciclo de vida: `initialize`, `launch`, `attach`, `setBreakpoints`, `configurationDone`, `threads`, `stackTrace`, `scopes`, `variables`, `evaluate`, `pause`, `resume`, `stepOver`, `stepIn`, `stepOut`, `disconnect`, `close`.
- Streams reativos de eventos: `events`, `stoppedEvents`, `outputEvents`.

### 2.4. Gerenciador Reativo de Sessão (`cockpit/lib/app/core/data/dap/debug_session_controller.dart`)
- `ChangeNotifier` para sincronização com a árvore de widgets Flutter.
- Estados da sessão: `idle`, `initializing`, `running`, `stopped`, `terminating`.
- Sincronização automática de breakpoints por caminho de arquivo (`_breakpointsByPath`).
- Auto-inspeção ao parar em breakpoint ou exceção: consulta de threads, stack frame ativo e carregamento de variáveis do escopo local.

### 2.5. Componentes de Interface de Depuração
- **`DebugToolbar` (`cockpit/lib/app/orkest/ui/widgets/debug_toolbar.dart`):**
  - Barra de ações flutuante com badge de status (`RODANDO` / `PAUSADO`).
  - Botões de controle de fluxo: Continuar (F5), Pausar, Passar Sobre / Next (F10), Entrar / Step In (F11), Sair / Step Out (Shift+F11), Parar (Shift+F5).
  - Atalhos de teclado nativos via `CallbackShortcuts`.
- **`DebugPanel` (`cockpit/lib/app/orkest/ui/widgets/debug_panel.dart`):**
  - Painel colapsável de inspeção dividido em 3 seções:
    1. **Call Stack:** Lista de frames com navegação clicável para código-fonte (`onNavigateToSource`).
    2. **Variáveis:** Inspeção chave-valor formatada com indicação de tipo e referências.
    3. **Breakpoints:** Listagem com toggle/remoção e navegação rápida para o arquivo e linha.

---

## 3. Validação e Testes Automatizados
- **Suíte de Núcleo (`cockpit/test/data/dap_core_test.dart`):**
  - 8 testes cobrindo codificação/decodificação de chunks fragmentados, handshake initialize, sincronização de breakpoints, comandos de fluxo de execução, inspeção de variáveis/pilha e ciclo completo de transição de estados.
- **Suíte de Widgets (`cockpit/test/ui/debug_widgets_test.dart`):**
  - 2 testes com mock assíncrono validando renderização da `DebugToolbar` (badges e atalhos) e do `DebugPanel` (interações com frames, breakpoints e variáveis).
- **Análise Estática:** `dart analyze --fatal-infos` com **zero issues** no projeto `cockpit`.
