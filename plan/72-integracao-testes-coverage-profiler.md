# R05 · Integração de Resultados de Testes, Coverage e Profiler Sob Demanda

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P2 · **Porte:** L  
**Dependências:** R01, L05  
**Branch:** `fix/harness-state-detection`  
**Referência:** ide-coverage, ide-profiler, run TestTreeView  
**Destino:** Tasks, telemetria e gutter de editor  

---

## 1. Contexto e Objetivos

O item R05 do plano mestre de evolução do Orkest Code estabelece a infraestrutura técnica para execução e diagnóstico unificado do ciclo de testes e performance do ecossistema de desenvolvimento, sem sobre-engenharia e respeitando os princípios de arquitetura de alta performance:
1. **Árvore Estruturada de Resultados de Testes (`TestTreeReport`):** Decodificação dos eventos JSON emitidos por test runners modernos (ex: `dart test --reporter json`, `jest --json`, `pytest --json-report`) em nós de suítes e casos de teste com métricas de tempo, status (`passed`, `failed`, `skipped`) e extração de erros detalhados.
2. **Reexecução Seletiva de Falhas (`buildRerunFailedCommand`):** Capacidade de filtrar deterministicamente apenas os testes que falharam para gerar o comando de reexecução imediata focado (ex: `--name "pattern1|pattern2"`).
3. **Mapeamento de Cobertura LCOV (`GlobalCoverageReport` / `FileCoverageReport`):** Parser padronizado do formato canônico LCOV (`lcov.info`) com granularidade de linha (`hit`, `miss`, `neutral`) para integração com o gutter do editor de código.
4. **Regra Inegociável de Integridade de Cobertura:** Dados ausentes ou arquivos sem linhas executáveis **nunca** devem ser apresentados como `0.0%`; o valor retornado deve ser estritamente `null` com indicação clara da ferramenta e linguagem, evitando relatórios falsos.
5. **Profiler Sob Demanda (`ProfilerReport` / `ProfilerHotSpot`):** Telemetria de CPU e memória capturada exclusivamente por demanda do desenvolvedor (nunca rodando em background continuamente para não degradar a taxa de quadros e o consumo térmico), identificando hotspots de função, consumo de milissegundos, percentual de tempo e consumo de RSS de memória.

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/test_coverage_profiler.dart`)

- **`TestStatus`**: Enum representando os estados de um teste (`passed`, `failed`, `skipped`).
- **`TestCaseNode`**: Entidade imutável com identificador único, nome amigável, suíte de origem, caminho do arquivo, linha, duração em milissegundos, status e mensagem/stack trace de erro.
- **`TestSuiteNode`**: Agrupador imutável de casos de teste com métricas agregadas de contagem (`passedCount`, `failedCount`, `skippedCount`) e duração total.
- **`TestTreeReport`**: Relatório consolidado contendo a ferramenta utilizada (`toolName`), linguagem alvo (`language`), lista de suítes, duração total e helper `failedTests` para identificação rápida de regressões.
- **`LineCoverageStatus`**: Enum de cobertura granular por linha (`hit`, `miss`, `neutral`).
- **`FileCoverageReport`**: Relatório por arquivo com total de linhas encontradas (`linesFound`), linhas atingidas (`linesHit`), mapa de status por número de linha e cálculo percentual (`coveragePercent`), retornando `null` estrito caso `linesFound == 0`.
- **`GlobalCoverageReport`**: Visão global da suíte com porcentagem agregada (`globalCoveragePercent`), índice de arquivos e ferramenta de origem.
- **`ProfilerHotSpot`**: Representação de função crítica com nome, localização (`arquivo:linha`), tempo de CPU em milissegundos, percentual de carga e contagem de invocações.
- **`ProfilerReport`**: Relatório estritamente pontual (sob demanda, `isRealtime: false`) com timestamp de captura, duração do tracing, consumo de memória RSS em MB, total de tempo de CPU e lista ordenada de hotspots.

### 2.2 Serviço de Parsing e Orquestração (`cockpit/lib/app/core/domain/services/test_coverage_profiler_service.dart`)

- **`parseDartTestJson(String jsonLinesOutput, {String toolName, String language})`**: Processa o fluxo JSONL de eventos do runner Dart/Flutter, correlacionando eventos `testStart`, `error` e `testDone`, calculando durações e agrupando os nós em suítes lógicas.
- **`buildRerunFailedCommand(TestTreeReport report, {String baseCommand})`**: Gera o comando CLI exato para reexecutar apenas os casos de teste que falharam, utilizando regex de nomes com escape seguro de caracteres especiais.
- **`parseLcov(String lcovContent, {String toolName})`**: Decodifica arquivos `lcov.info` mapeando registros `SF:`, `DA:`, `LH:` e `LF:` e alimentando os relatórios de arquivo e globais.
- **`parseProfilerOutput(String rawText, {required String runtimeTool, DateTime? capturedAt, Duration? duration, double? memoryRssMb})`**: Extrai tabelas tabulares e relatórios textuais de profilers (Dart VM Service, Linux `perf`, Node `--prof`) em hotspots estruturados.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 5 testes em `cockpit/test/domain/test_coverage_profiler_test.dart` validando:
  1. Parsing completo de eventos de teste do Dart (`passed`, `failed`, `skipped`).
  2. Geração do comando de rerun seletivo para falhas.
  3. Mapeamento fiel de linhas cobertas e não cobertas via LCOV.
  4. Garantia mandatória de ausência de dados de cobertura representada como `null`, nunca `0.0%`.
  5. Parsing sob demanda de saídas de profiler com hotspots e RSS de memória.
- **Suíte Combinada:** 13 testes aprovados na suíte de depuração multilinguagem e testes (`multi_language_debug_adapter_test.dart` e `test_coverage_profiler_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` concluído com **0 issues**.
