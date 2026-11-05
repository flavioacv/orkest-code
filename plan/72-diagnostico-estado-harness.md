# Diagnóstico de Estado de Harness sem Captura de Conteúdo (H05) — Orkest Code

## 1. Visão Geral e Contexto
No Orkest Code, as sessões de terminal interagem continuamente com harnesses de IA (Claude Code, Antigravity, OpenCode, Codex, Aider, Gemini CLI, Kimi, etc.) executando ferramentas, turnos e solicitações de permissão humana.

Para prover telemetria confiável, transparência na interface e diagnósticos de observabilidade sem violar a privacidade do desenvolvedor nem vazar dados proprietários, a atividade **H05** implementou o serviço formal de diagnóstico de estado:
- **Origem do Último Estado**: identifica precisamente qual camada ou sensor reportou o estado atual (`structuredHook`, `ptyMarker`, `userInput`, `screenObservation`);
- **Idade do Sinal (`signalAge`)**: calcula o delta temporal em milissegundos entre o último evento recebido e a consulta diagnóstica;
- **Detecção com Dados Limitados (`limitedDataMode`)**: sinaliza e adapta o grau de confiança quando o ambiente opera sem hooks estruturados ou sem marcadores PTY (modo degradado);
- **Garantia Inegociável contra Falsa Execução**: falta de sinal **NUNCA** inventa execução — uma sessão virgem ou sem sinais reportados é estritamente `idle` com confiança `unasserted`;
- **Privacidade Absoluta**: zero retenção ou serialização de buffers de tela, outputs de comando, prompts de usuário, código-fonte ou tokens sensíveis;
- **Avaliação em Corpus Rotulado**: cálculo determinístico de matriz de confusão medindo falsos working, falsos waiting e falsos idle com taxas percentuais de erro e acurácia.

---

## 2. Modelos de Domínio e Entidades

### `HarnessDetectionConfidence` (`cockpit/lib/app/core/domain/entities/harness_diagnostic.dart`)
Enum determinístico com 5 níveis de confiança:
- `unasserted`: ausência de sinais reportados ou terminal sem processo de harness (garante zero execução inventada);
- `low`: heurística fraca baseada apenas em observação heurística de buffer de tela (`screenObservation`);
- `medium`: entrada física recente do usuário (`userInput`);
- `high`: marcadores determinísticos do emulador de terminal (`ptyMarker` / OSC 133);
- `authoritative`: hooks de processo estruturados via IPC/socket (`structuredHook`).

### `HarnessStateDiagnostic`
Snapshot imutável e seguro para consumo da UI e telemetria:
- `presence`: `HarnessPresence` (`none`, `attached`, `detached`);
- `phase`: `HarnessExecutionPhase` (`idle`, `running`, `waitingInput`, `completed`, `closed`);
- `terminalStatus`: mapeamento para `TerminalStatus` (`idle`, `working`, `waiting`);
- `lastSource`: `HarnessSignalSource?` (nulo quando nenhum sinal foi emitido);
- `lastUpdatedAt`: `DateTime?`;
- `signalAge`: `Duration` relativa ao instante de referência;
- `confidence`: `HarnessDetectionConfidence`;
- `limitedDataMode`: `bool`;
- `totalSignalsReceived`: `int`;
- `sourceDistribution`: contadores agregados por fonte;
- `toTelemetryMap()`: serialização contendo exclusivamente metadados estruturados de status, descartando quaisquer strings sensíveis de resumo ou comandos.

### `HarnessCorpusConfusionMatrix`
Estrutura para medição matemática de acurácia sobre sequências de eventos rotuladas:
- `totalSamples`
- `trueWorking`, `falseWorking` (detectado working quando ground truth era idle ou waiting);
- `trueWaiting`, `falseWaiting` (detectado waiting quando ground truth era working ou idle);
- `trueIdle`, `falseIdle` (detectado idle quando ground truth era working ou waiting);
- Métricas calculadas: `accuracyRate`, `falseWorkingRate`, `falseWaitingRate`, `falseIdleRate`.

---

## 3. Serviços e Integração

### `HarnessDiagnosticService` (`cockpit/lib/app/core/domain/services/harness_diagnostic_service.dart`)
- `buildDiagnostic({required HarnessStateCoordinator coordinator, DateTime? referenceTime, bool limitedDataMode})`:
  - Trata o caso de `totalSignalsReceived == 0`: retorna obrigatoriamente `phase: idle`, `terminalStatus: idle`, `confidence: unasserted` e `lastSource: null`;
  - Deriva `signalAge` e ajusta `confidence` para `low` quando `limitedDataMode` está ativo sobre observações heurísticas;
- `evaluateCorpusAccuracy({required List<HarnessLabeledSample> samples, HarnessStateCoordinator? customCoordinator})`:
  - Processa a sequência no coordenador e compara o estado final consolidado contra o ground truth rotulado.

### `HarnessStateCoordinator` (`cockpit/lib/app/core/domain/services/harness_state_coordinator.dart`)
- Mantém contadores atômicos de telemetria diagnóstica (`_totalSignalsReceived`, `_sourceDistribution`);
- Expõe método público `getDiagnostic({DateTime? referenceTime, bool limitedDataMode = false})`.

### `TerminalSession` (`cockpit/lib/app/orkest/ui/session/terminal_session.dart`)
- Expõe getter público `HarnessStateDiagnostic get harnessDiagnostic => harnessCoordinator.getDiagnostic();`.

---

## 4. Garantias e Validação Automatizada

### Suíte de Testes Dedicada (`cockpit/test/domain/harness_diagnostic_service_test.dart`)
1. **Falta de sinal nunca inventa execução**: coordenador novo retorna deterministicamente `idle`, `unasserted`, `totalSignalsReceived = 0`, `lastSource = null`;
2. **Origem e idade do sinal**: validação de delta temporal e preservação da fonte mais recente;
3. **Grau de confiança hierárquico**: `structuredHook` -> `authoritative`, `ptyMarker` -> `high`, `userInput` -> `medium`, `screenObservation` -> `low`;
4. **Modo degradado / limitedDataMode**: rebaixamento de confiança sob restrição de dados;
5. **Privacidade estrita**: verificação de que `toTelemetryMap()` não expõe chaves `summary`, `prompt`, `output`, `text`, `buffer`, nem tokens;
6. **Matriz de confusão em corpus rotulado**: cálculo exato de falsos idle, working e waiting, taxas de erro e acurácia.

### Execução dos Testes e Análise Estática
- **Testes dedicados**: 6/6 testes aprovados em `harness_diagnostic_service_test.dart`;
- **Suíte combinada de harness**: 69/69 testes aprovados sem falhas ou regressões (`harness_diagnostic_service_test.dart`, `harness_environment_parity_test.dart`, `terminal_harness_classifier_test.dart`, `harness_host_evidence_test.dart`, `harness_corpus_replay_test.dart`, `harness_signal_precedence_test.dart`, `agent_harness_test.dart`);
- **Análise estática**: `puro -e stable dart analyze --fatal-infos` 100% limpa (0 issues).
