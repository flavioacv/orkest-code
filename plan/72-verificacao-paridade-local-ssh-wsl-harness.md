# Verificação de Paridade Local, SSH e WSL de Harness (H04)

## 1. Visão Geral e Contexto

No Orkest Code, as sessões de terminal interativo com harnesses de IA podem ser executadas em múltiplos ambientes: localmente no host do usuário (macOS, Linux, Windows), remotamente através de conexões SSH gerenciadas, ou no subsistema Linux para Windows (WSL).

O objetivo da atividade **H04** foi assegurar **paridade determinística absoluta de estados**, garantir que quedas de conexão ou mortes de processos nunca se disfarcem de encerramento bem-sucedido ou aprovação fantasma, e proteger a sessão contra sinais residuais de conexões passadas.

A entrega contempla:
1. **Modelos de Contexto e Ambiente (`HarnessEnvironmentType`, `HarnessEnvironmentContext`)**:
   - Representação desacoplada do ambiente (`local`, `sshRemote`, `wsl`), identificador do host/distro, geração de sessão e flag de conectividade do transporte (`isConnected`);
2. **Serviço de Paridade e Integridade de Transporte (`HarnessEnvironmentParity`)**:
   - `processSignal`: processamento com proteção de conectividade e descarte estrito de sinais de gerações anteriores (`signal.generation < context.generation`);
   - `handleDisconnection`: desconexão desanexa o harness (`presence: detached`), encerra a fase ativa (`phase: closed`), cancela esperas pendentes e **NUNCA** emite status `completed` nem aprovação de ferramenta (`isTurnActive: false`, `isPresent: false`);
   - `handleReconnection`: avanço formal de geração (`nextGeneration: generation + 1`), sincronizando o coordenador e invalidando buffers defasados;
   - `normalizeEnvironmentPath`: normalização segura de caminhos entre Windows (`C:\...`), WSL (`/mnt/c/...`) e caminhos remotos POSIX via SSH (`/home/...`) sem vazamentos de identificadores do host local.
3. **Integração no Ciclo de Vida da `TerminalSession`**:
   - Métodos públicos `handleTransportDisconnection` e `handleTransportReconnection` permitindo que os gateways de transporte (como `RemoteHostTerminalGateway`) notifiquem a sessão de terminal de forma desacoplada e segura;
   - Cancelamento imediato de debounces de notificação ao desconectar, impedindo que `onTurnFinished` dispare falsamente.
4. **Implementação de Igualdade por Valor (`operator ==` e `hashCode`) em `HarnessStateSnapshot`**:
   - Comparação determinística de snapshots de estado para testes, diagnósticos e telemetria.

---

## 2. Decisões Arquiteturais e Mitigações Críticas

### A. Prevenção de Falsa Conclusão e Falsa Aprovação na Desconexão
* **Problema:** Em conexões instáveis de SSH ou fechamento abrupto de canal PTY no WSL enquanto um harness aguardava autorização humana (`waitingInput`), a queda de conexão podia disparar finalizações com status `idle`, interpretadas falsamente pela UI ou pelo agente como se o usuário tivesse aprovado o comando ou o turno tivesse concluído com sucesso.
* **Solução:** O `handleDisconnection` desanexa a presença (`presence: detached`), transiciona explicitamente a fase para `closed`, limpa flags de prompt de permissão e cancela os timers de notificação. Nenhum evento de sucesso ou aprovação é gerado.

### B. Proteção de Geração Contra Buffers de Replay Defasados
* **Problema:** Ao reconectar uma sessão SSH ou re-abrir um terminal no WSL, o servidor ou multiplexador pode reenviar o buffer histórico de tela. Esse buffer contém textos e saídas de comandos passados que, se reprocessados, causavam ressuscitação de atividades já encerradas.
* **Solução:** A reconexão incrementa a geração (`advanceGeneration`). Sinais com `generation < currentGeneration` são sumariamente rejeitados antes de alcançar o coordenador.

### C. Paridade Rigorosa Entre Ambientes
* **Garantia:** Sequências idênticas de eventos aplicadas em instâncias de Local, SSH e WSL produzem exatamente os mesmos estados (`HarnessStateSnapshot`), comprovado por testes automatizados de igualdade vetorial.

---

## 3. Cobertura de Testes Automatizados

* `cockpit/test/session/harness_environment_parity_test.dart` (4 testes dedicados):
  - Paridade determinística idêntica de sequências de eventos em Local, SSH e WSL;
  - Desconexão de transporte em meio a espera humana (`waitingInput`) comprovando ausência de aprovação e cancelamento de turno;
  - Reconexão avançando geração e rejeitando sinais defasados de buffer antigo;
  - Normalização segura de caminhos de arquivo em WSL e SSH.
* Suíte Combinada de Regressão de Terminal e Harness (63 testes aprovados):
  - `terminal_harness_classifier_test.dart` (30 testes);
  - `harness_host_evidence_test.dart` (10 testes);
  - `harness_corpus_replay_test.dart` (10 testes);
  - `harness_signal_precedence_test.dart` (6 testes);
  - `agent_harness_test.dart` (3 testes);
  - `harness_environment_parity_test.dart` (4 testes).
* Análise estática limpa: `puro -e stable dart analyze --fatal-infos` em `cockpit/` sem nenhum aviso (`No issues found!`).
