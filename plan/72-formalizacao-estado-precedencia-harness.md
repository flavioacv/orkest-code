# Formalização de Estado e Precedência dos Sinais de Harness (H01)

> **Atividade:** `H01 · Formalizar estado e precedência dos sinais de harness`  
> **Prioridade:** P0 · Porte: M · Dependências: F01 (Concluídas)  
> **Status:** Concluído e Homologado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

A atividade **H01** é o marco central (P0) para a resolução de estados de agentes e harnesses no Orkest Code, superando o modelo simplista de polling ou heurísticas soltas de tela. Ela formaliza uma máquina de estados com **eixos ortogonais independentes** e uma **matriz de precedência determinística** entre fontes de sinal, protegendo a experiência do usuário contra falsos idle, regressões por redraw e corridas de concorrência entre hooks e emulação de terminal.

Pilares centrais atendidos:
1. **Separação Rígida de Eixos Ortogonais:**
   - **Presença do Harness (`HarnessPresence`):** `none` (shell puro), `attached` (harness presente e ativo), `detached` (sessão terminada ou processo morto).
     - *Regra inviolável:* O harness **continua presente (`attached`)** durante a ociosidade entre turnos. Apenas `SessionEnd` ou encerramento de PTY o desvincula.
   - **Fase de Execução (`HarnessExecutionPhase`):** `idle`, `running`, `waitingInput`, `completed`, `closed`.
   - **Fonte do Sinal (`HarnessSignalSource`):** `structuredHook` (peso 100), `ptyMarker` (peso 75), `userInput` (peso 50), `screenObservation` (peso 25).
2. **Matriz Determinística de Precedência:**
   - Eventos estruturados (`structuredHook`) têm **precedência estrita** sobre observações de tela (`screenObservation`). Uma observação heurística não pode cancelar ou rebaixar um estado de execução ou de espera estruturado recente (< 3s);
   - Sinais de gerações de sessão anteriores (`signal.generation < currentGeneration`) são descartados deterministicamente;
   - Atividades já concluídas (`completed`) são registradas num buffer circular (*FIFO cap* de 256 itens) e jamais são reabertas por repinturas/redraws de tela do terminal.
3. **Neutralidade Absoluta de Produtor:**
   - Nomes de CLI ou produtores (`claude`, `codex`, `gemini`, `anti-gravity`, `kimi`, `custom-agent`) **não alteram** o comportamento ou a precedência. O motor opera 100% agnóstico ao nome da ferramenta.

---

## 2. Componentes e Contratos Entregues

- **Entidades de Sinal e Snapshot** (`cockpit/lib/app/core/domain/entities/harness_signal.dart`):
  - `HarnessPresence`, `HarnessExecutionPhase`, `HarnessSignalSource` com pesos numéricos;
  - `HarnessSignal`: payload contendo fonte, fase, timestamp, activityId, generation, sessionId, turnId;
  - `HarnessStateSnapshot`: visão imutável do estado consolidado, com projeção canônica para `TerminalStatus` (`working`, `waiting`, `idle`).
- **Coordenador de Precedência e Estado** (`cockpit/lib/app/core/domain/services/harness_state_coordinator.dart`):
  - `HarnessStateCoordinator`: resolve conflitos de fontes concorrentes, aplica filtragem de gerações e deduplica atividades finalizadas com FIFO cap de 256 itens;
  - Métodos `processSignal`, `advanceGeneration` e `detach`.
- **Integração na Sessão de Terminal** (`cockpit/lib/app/orkest/ui/session/terminal_session.dart`):
  - Inclusão do campo `harnessCoordinator` e getter público `harnessSnapshot`;
  - Sincronização em `_setStatus`, `applyOfficeActivity` e término de processos de PTY.

---

## 3. Validação e Qualidade

- **6 testes unitários dedicados** de precedência e estados ortogonais em `cockpit/test/domain/harness_signal_precedence_test.dart`:
  - Separação ortogonal de presença vs execução vs espera;
  - Precedência estrita de hook estruturado sobre observação de tela;
  - Descarte de sinais de gerações anteriores;
  - Deduplicação de atividades finalizadas contra redraws de terminal;
  - Neutralidade de produtor em matriz exaustiva;
  - Desconexão explícita em encerramento de sessão.
- **68 testes de status de terminal revalidados** em `cockpit/test/session/terminal_status_test.dart` (total de 74 testes aprovados sem falhas).
- **Análise estática:** `dart analyze --fatal-infos` com 0 erros e 0 alertas.
