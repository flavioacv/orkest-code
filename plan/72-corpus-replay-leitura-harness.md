# Arquitetura e Corpus de Replay de Leitura de Harness (H02)

## 1. Visão Geral e Contexto

O objetivo da atividade **H02** foi estabelecer um corpus versionado, sanitizado e determinístico para a leitura e detecção de estado de harnesses de IA (como Antigravity, Claude Code, Codex, Cursor, Pi, Aider e OpenCode), emulando as condições reais observadas em terminais interativos locais, remotos (SSH) e WSL, sem depender de timing de relógio real ou processos externos voláteis.

Com base na formalização de estados e precedência entregue em **H01** (`HarnessSignal`, `HarnessPresence`, `HarnessExecutionPhase`, `HarnessSignalSource`, `HarnessStateSnapshot`), a entrega H02 implementa:
1. **Estruturas de Dados do Corpus (`HarnessReplayEvent`, `HarnessReplayTransition`, `HarnessReplayScenario`)**: representação desacoplada e serializável para timelines de captura;
2. **Motor Determinístico de Replay (`HarnessReplayRunner`)**: simulador de eventos de terminal com recomposição de sequências ANSI fragmentadas, detecção de marcadores PTY (`\x1b]133;C`/`D`), filtragem por precedência de fontes e cálculo de métricas (sinais aceitos, rejeitados, transições e contagem de flicker);
3. **8 Cenários Sanitizados Versionados em JSON (`test/fixtures/harness/`)**:
   - `01_ansi_fragmented.json`: sequências ANSI cortadas no meio de pacotes arbitrários (`\x1b[38;5;` seguido de `240m...`);
   - `02_screen_redraw.json`: repintura total de tela (clear screen e reposicionamento de cursor) com deduplicação de tarefas finalizadas via `_settledActivityIds`;
   - `03_repeated_prompts.json`: linhas repetidas de prompts e spinners de repouso sem disparos espúrios de trabalho;
   - `04_concurrent_permissions.json`: múltiplas solicitações simultâneas de permissão humana mantendo o estado `waitingInput` e status `waiting` de forma coesa;
   - `05_subagents.json`: orquestração hierárquica mantendo o status em `working` enquanto houver subtarefas ativas, consolidando para `completed` apenas no encerramento da raiz;
   - `06_stop_session_end.json`: interrupção forçada (`Stop`) e fechamento limpo com transição para `detached` (`SessionEnd`);
   - `07_wsl_environment.json`: isolamento de processos sob subsistema WSL (`wslDistro: Ubuntu-22.04`) com caminhos Unix sanitizados e sem vazamento de identificadores de usuário do host;
   - `08_session_reconnect.json`: reconexão com incremento de geração (`generation: 1`), descartando buffers residuais e restaurando sincronismo limpo.

---

## 2. Decisões Arquiteturais e Correções Críticas

### A. Precedência Temporal Baseada no Fluxo de Eventos (Event Timestamp Delta)
* **Problema:** A comparação contra relógio do sistema (`DateTime.now()`) quebrava determinismo em replays, testes unitários ou execuções em batch com timestamps sintéticos.
* **Solução:** O coordenador compara a distância temporal entre o sinal recebido e o último sinal aceito (`signal.timestamp.difference(_lastUpdatedAt).inMilliseconds.abs() < 5000`). Se a fonte ativa for de alta precedência (`structuredHook` ou `ptyMarker`), fontes mais fracas (`screenObservation`) não podem rebaixar nem sobrescrever o estado durante a janela de atividade.

### B. Ciclo de Vida Hierárquico de Subagentes
* **Problema:** Ao receber o sinal `completed` de um subagente em uma árvore de execução (`_activeActivityIds`), a fase da sessão colapsava prematuramente para `completed`, ignorando que o agente orquestrador raiz ainda estava executando.
* **Solução:** Ao receber `completed`, o coordenador remove a atividade específica de `_activeActivityIds` e reavalia a lista ativa. A fase da sessão só se torna `completed` quando `_activeActivityIds.isEmpty`. Caso restem atividades pai/irmãs, o status permanece em `working` (`HarnessExecutionPhase.running`).

### C. Isolamento de Gerações de Conexão no Cálculo de Flicker
* **Problema:** Ao reconectar uma sessão PTY (`generation 0 -> generation 1`), a queda momentânea para `idle` seguida pelo primeiro comando da nova sessão era falsamente classificada como *flicker*.
* **Solução:** O detector de oscilação do `HarnessReplayRunner` restringe a detecção de *flicker* à mesma geração (`prevPrevGen == currGen`). Mudanças de geração representam limites de conexão explícitos, eliminando falsos positivos na telemetria de integridade.

### D. Sanitização Rígida sem Segredos
* **Segurança:** Todas as 8 fixtures foram submetidas a verificações de regex cobrindo tokens de API (`sk-`, `ghp_`), senhas em texto claro e caminhos absolutos locais de desenvolvimento (`/Users/...` e `C:\Users\...`), garantindo distribuição limpa e segura no repositório.

---

## 3. Cobertura de Testes Automatizados

* `cockpit/test/session/harness_corpus_replay_test.dart`: 10 testes dedicados cobrindo:
  1. Auditoria de sanitização (zero segredos ou vazamentos em todas as fixtures);
  2. Execução determinística dos 8 cenários obrigatórios (zero flickers e correspondência de 100% com as transições esperadas);
  3. Reprodutibilidade idêntica em execuções sucessivas (`run1 == run2`).
* Revalidação de regressão completa:
  - `harness_signal_precedence_test.dart` (6 testes aprovados);
  - `terminal_status_test.dart` (68 testes aprovados).
* Análise estática limpa: `dart analyze --fatal-infos` em `cockpit/` sem nenhum aviso.
