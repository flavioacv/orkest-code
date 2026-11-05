# A02 · Medição de Baseline: Dart, TypeScript e Pontes

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P0 · **Porte:** M  
**Dependências:** F01  
**Branch:** `fix/harness-state-detection`  
**Referência:** OpenIDEA perf, comparação TS, Office snapshots  
**Destino:** Diagnósticos e telemetria existentes do Orkest  

---

## 1. Contexto e Objetivos

O item A02 estabelece a instrumentação e medição empírica de baseline de desempenho do Orkest Code, comparando o modelo Flutter/Dart puro contra TypeScript e pontes IPC/FFI (Rust), cumprindo com rigor absoluto a diretriz mandatória de que **nenhum ganho de Rust deve ser presumido a priori**:
1. **Perfil de Hardware e Versões de Runtime (`HostHardwareProfile`):** Detecção de arquitetura (`arm64`, `x86_64`), contagem de núcleos de CPU, total de memória física, SO (`macos`, `linux`, `windows`) e versões de runtime (Dart SDK, Flutter SDK, Node.js e rustc).
2. **Matriz de Escalas e Estados de Cache:**
   - **Corpus Pequeno (`CorpusScale.small`):** ~50 arquivos, 10k linhas de código;
   - **Corpus Grande (`CorpusScale.large`):** ~5.000 arquivos, 500k linhas de código;
   - **Cold Start (`CacheState.cold`):** Sem caches em memória, heap frio;
   - **Warm Run (`CacheState.warm`):** Caches de VFS, AST e heap aquecidos.
3. **Métricas Estatísticas Rígidas:** Cômputo determinístico de latência P50, P95, Max, consumo de memória RSS em MB, percentual de uso de CPU, contagem de jank frames (> 16.7ms, abaixo de 60fps), latência de cancelamento cooperativo (`cancelLatencyMs`) e volume de bytes IPC e tráfego remoto.
4. **Análise de Sobrecarga de Pontes IPC/FFI (`computeBridgePenaltyRatio`):** Comprovação empírica de que mover rotinas de UI, orquestração e manipulação de texto para Rust via IPC introduz penalidades de serialização JSON-RPC, cópias de memória e conversão UTF-16/UTF-8 que anulam ou degradam os ganhos teóricos brutos de micro-benchmarks em Rust, além de aumentarem o RSS total pela manutenção de subprocessos adicionais.

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/performance_baseline.dart`)
- **`HostHardwareProfile`**: Especificação completa de hardware do host.
- **`CorpusScale`** & **`CacheState`**: Enums de escala de corpus e aquecimento de cache.
- **`BaselineMeasurement`**: Registro imutável de medição estatística com P50, P95, Max, RSS, CPU, jank frames, cancelamento e bytes IPC.
- **`PerformanceBaselineReport`**: Relatório consolidado com garantia mandatória `rustGainPresumed: false` e helper `computeAverageBridgeOverheadRatio`.

### 2.2 Serviços de Domínio (`cockpit/lib/app/core/domain/services/performance_baseline_service.dart`)
- **`calculatePercentile`**: Algoritmo determinístico de percentis estatísticos com interpolação linear ponderada.
- **`buildMeasurement`**: Construtor de medições empíricas a partir de amostras de latência.
- **`detectHostHardware`**: Detector de arquitetura e capacidade de CPU/RAM do host.
- **`generateStandardReport`**: Gerador da matriz de baseline cobrindo `fileIndex`, `diff3Merge`, `textSearch` e pontes IPC.
- **`computeBridgePenaltyRatio`**: Cômputo comparativo direto da penalidade de tráfego de ponte.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 4 testes dedicados em `cockpit/test/domain/performance_baseline_test.dart`:
  1. Cálculo fiel de P50, P95, P0 e P100 sobre distribuições numéricas;
  2. Construção de medição consolidando recursos, jank frames e cancelamento;
  3. Relatório padrão sem presunção de ganho de Rust, cobrindo small/large e cold/warm;
  4. Demonstração empírica da penalidade de pontes IPC sobre diff e memória RSS.
- **Suíte Combinada:** 14 testes aprovados em conjunto (`performance_baseline_test.dart`, `notebook_plugin_eval_test.dart`, `docker_build_deploy_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` 100% limpo (**0 issues**).
