# Expansão de Debug Multilinguagem Progressivamente (R04) — Orkest Code

## 1. Visão Geral e Contexto
Na evolução do Orkest Code para IDE completa, a depuração interativa via Debug Adapter Protocol (DAP) deve abranger múltiplos ecossistemas além do Dart/Flutter nativo:
- **TypeScript / JavaScript**: `pwa-node` (via `@vscode/js-debug` e V8 debug runtime);
- **Python**: `debugpy` (o adaptador oficial do ecossistema Python);
- **Rust / C / C++**: `lldb` (via `codelldb` / LLVM DAP);
- **Go**: `dlv` (via Delve DAP);
- **JVM / Java**: `java` (via Eclipse JDT / `java-debug-server`);
- **.NET / C#**: `coreclr` (via `netcoredbg`);
- **Dart / Flutter**: `dart` e `flutter` (via Dart/Flutter SDK nativo).

A atividade **R04** formaliza o catálogo de adaptadores, as capacidades suportadas por cada runtime, as limitações intrínsecas (como ausência de hardware watchpoints em runtimes interpretados ou impossibilidade de unwinding arbitrário de frames) e provê a orquestração desacoplada de sessões.

---

## 2. Catálogo Declarativo e Capacidades

### `MultiLanguageDebugRegistry` (`cockpit/lib/app/core/domain/entities/multi_language_debug_adapter.dart`)
Cada adaptador é registrado com:
- `adapterId`: identificador do protocolo DAP (`pwa-node`, `debugpy`, `lldb`, `dlv`, `java`, `coreclr`, `dart`);
- `defaultExecutable` e `defaultArgs`: comando padrão para spawn do servidor DAP via stdio;
- `supportedLanguages`: mapeamento para extensões e identidades de linguagem;
- `license`: licença de código-fonte (MIT, GPL-2.0, EPL-1.0, BSD-3-Clause);
- `installHint`: instrução de instalação via gerenciador de pacotes (`npm`, `pip`, `go install`, etc.);
- `sampleLaunchConfig`: modelo de configuração `launch.json`.

### Matriz de Capacidades por Adaptador:
| Adaptador | Linguagens | Watchpoints | HotSwap | Restart Frame | Smart Step | Licença |
| :--- | :--- | :---: | :---: | :---: | :---: | :--- |
| **`dart`** | Dart, Flutter | ❌ | ✅ (Hot Reload) | ✅ | ✅ | BSD-3-Clause |
| **`pwa-node`** | TypeScript, JavaScript | ❌ | ✅ (V8 Reload) | ✅ | ✅ | MIT |
| **`debugpy`** | Python | ❌ | ❌ | ❌ | ❌ | MIT |
| **`lldb`** | Rust, C, C++ | ✅ (Hardware) | ❌ | ❌ | ❌ | GPL-2.0 |
| **`dlv`** | Go | ✅ (Hardware) | ❌ | ❌ | ❌ | MIT |
| **`java`** | Java, Kotlin | ✅ (Field) | ✅ (JDWP) | ✅ (Drop) | ✅ | EPL-1.0 |
| **`coreclr`** | C# (.NET) | ❌ | ✅ (Edit&Continue) | ❌ | ❌ | MIT |

---

## 3. Orquestrador Unificado de Depuração

### `MultiLanguageDebugAdapter` (`cockpit/lib/app/core/data/dap/multi_language_debug_adapter.dart`)
1. **Resolução de Comandos com Overrides**:
   - `resolveAdapterCommand`: permite sobrescrever o executável (ex.: apontar para um interpretador Python em virtualenv específico `.venv/bin/python`) e argumentos customizados;
2. **Formatação de Configurações Launch**:
   - `buildLaunchArgs`: mescla o template padrão da linguagem com os caminhos de projeto (`program`, `cwd`, `args`, flags `noDebug` e propriedades customizadas);
3. **Auditoria de Conformidade (`auditAdapter`)**:
   - Emite relatório transparente (`DebugAdapterAuditReport`) identificando se o binário está disponível no host (`available`), ausente (`missingExecutable`) ou se a linguagem não possui suporte (`unsupported`);
   - Enumera limitações reais documentadas para cada runtime sem criar falsas expectativas de paridade.

---

## 4. Validação Automatizada

- **Suíte Dedicada R04:** 8 testes aprovados em [`multi_language_debug_adapter_test.dart`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/test/domain/multi_language_debug_adapter_test.dart);
- **Suíte Combinada DAP:** 26 testes aprovados sem falhas (`multi_language_debug_adapter_test.dart`, `dart_debug_adapter_test.dart`, `dap_core_test.dart`);
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` com **zero issues** (0 erros e 0 alertas).
