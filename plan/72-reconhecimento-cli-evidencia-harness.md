# Reconhecimento de CLI por Evidência e Contrato Genérico de Harness (H03)

## 1. Visão Geral e Contexto

Na evolução do Orkest Code para IDE completa, a identificação dos processos de agentes de IA operando no terminal (locais, via wrappers ou subsistemas) deve ser fundamentada estritamente em **evidências comprováveis do host**, diferenciando execuções interativas reais de comandos utilitários, rotinas de batch ou scripts não catalogados.

A atividade **H03** expande e consolida essa camada arquitetural:
1. **Catálogo de Evidência e Capacidades (`HarnessCatalog` & `HarnessSpec`)**:
   - Enriquecimento formal de `HarnessSpec` com metadados de capacidades: `supportsStructuredHooks`, `supportsPtyMarkers`, `supportsResume`, `resumeSyntax`, `nonInteractiveFlags`, `adminSubcommands` e `knownWrappers`;
   - Expansão do catálogo para **11 ferramentas catalogadas**:
     - *Core existentes*: Antigravity (`agy`), Claude Code (`claude`), Codex (`codex`), Cursor (`cursor-agent`), GitHub Copilot (`copilot`), OpenCode (`opencode`), Pi (`pi`);
     - *Novas incorporadas por evidência*: Gemini CLI (`gemini`), Kimi CLI (`kimi`), Aider (`aider`), Ollama (`ollama`).
2. **Serviço de Evidência no Host (`HarnessHostEvidence`)**:
   - Inspeção com relatório tipado `HarnessEvidenceReport` (`isKnownHarness`, `isInteractive`, `isWrapperInvocation`, `confidence`, `reason`);
   - Resolução de binários no host (`isExecutableAvailable`) via caminhos absolutos, diretórios customizados ou PATH do sistema.
3. **Normalizador Multi-Runtime (`TerminalHarnessNormalizer`)**:
   - Tratamento determinístico de runtimes intermediários: `node`, `bun`, `deno`, `python`, `python3`, `npx`, `bunx`, `uvx`, `pipx`, `pnpm`, `yarn`;
   - Resolução de `python -m <module>` (ex: `python3 -m aider`), runners npx/uvx (`npx -y @google/gemini-cli`, `uvx aider-chat`) e wrappers `.cmd`/`.bat`/`.exe`.
4. **Classificador Declarativo por Evidência (`TerminalHarnessClassifier`)**:
   - Rejeição universal de flags administrativas/help (`-h`, `--help`, `-v`, `--version`, `-V`);
   - Rejeição declarativa de flags de modo não interativo e subcomandos administrativos mapeados na especificação de cada harness;
   - Regra estrita para Ollama (exige subcomando interativo `run <model>`);
   - Rejeição de flags one-shot (`-p`, `--print`, `-m`, `--message`, `--no-git`, `-q`, `--quiet`, `--mode=rpc/json/text`).
5. **Contrato Genérico Estrito para Comandos Desconhecidos**:
   - Comandos de shell, ferramentas de compilação (`gcc`, `make`, `cargo`) ou scripts de terceiros não catalogados retornam `null` determinístico;
   - **Zero Alucinação de Parsers**: nenhum parser ad-hoc é inventado para fornecedores desconhecidos; o terminal opera sob o contrato genérico de shell de forma segura e transparente.

---

## 2. Decisões Arquiteturais e Trade-offs

### A. Prevenção de Falsa Presença de Agente
* **Problema:** Um usuário executando `gemini --version` ou `claude -p "resuma este arquivo"` em um script não deve disparar animações de escritório ou presença de agente como se estivesse em uma sessão de chat interativo.
* **Solução:** A classificação exige que o processo seja comprovadamente interativo. Flags de print, quiet, batch ou subcomandos como `auth`, `config` e `doctor` suprimem a presença de harness, mantendo o processo como um comando comum de terminal.

### B. Ollama: Chat vs Servidor/Download
* **Problema:** `ollama` é tanto o daemon de modelos quanto o downloader (`pull`) e o cliente de chat (`run`).
* **Solução:** O classificador só reconhece `ollama` como harness interativo quando invocado com `ollama run <modelo>`. Invocadas soltas, como daemon (`serve`) ou gerenciamento de modelos (`pull`, `list`, `rm`), permanecem como comandos genéricos de sistema.

### C. Normalização de Wrappers Modernos de Pacotes (npx, uvx, pipx)
* **Problema:** Ferramentas modernas de IA são comumente instaladas e rodadas de forma efêmera via runners de pacotes (ex: `uvx aider-chat`, `npx @google/gemini-cli`).
* **Solução:** O normalizador salta argumentos próprios do runner (como `-y` no npx ou flags de ambiente) e correlaciona os pacotes aos entry points oficiais cadastrados no catálogo.

---

## 3. Cobertura de Testes Automatizados

* `cockpit/test/domain/terminal_harness_classifier_test.dart` (30 testes aprovados):
  - Invocação direta e interativa para todas as 11 ferramentas catalogadas;
  - Rejeição de modos de impressão, quiet e subcomandos administrativos;
  - Resolução via wrappers de runtime (`node`, `npx`, `python -m`, `uvx`);
  - Validação de comandos desconhecidos respeitando o contrato genérico.
* `cockpit/test/domain/harness_host_evidence_test.dart` (10 testes aprovados):
  - Inspeciona evidência direta vs wrapper, com cálculo formal de confiança (`1.0` vs `0.85` vs `0.0`);
  - Valida catálogo de 11 specs e capacidades declaradas (`supportsStructuredHooks`, `supportsResume`, `resumeSyntax`);
  - Valida probe de binários no host (`isExecutableAvailable`).
* Revalidação de regressão:
  - `harness_corpus_replay_test.dart` (10 testes);
  - `harness_signal_precedence_test.dart` (6 testes);
  - `agent_harness_test.dart` (3 testes).
* Análise estática limpa: `puro -e stable dart analyze --fatal-infos` sem nenhum aviso (`No issues found!`).
