# X04 · Avaliação de Notebooks e Extensões

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P3 · **Porte:** L  
**Dependências:** A04, W02  
**Branch:** `fix/harness-state-detection`  
**Referência:** ide-notebook, ide-plugin, ide-extension, wit/sdk  
**Destino:** Pontos de extensão e viewers do Orkest  

---

## 1. Contexto e Objetivos

O item X04 conclui a trilha de ferramentas do Orkest Code formalizando a avaliação de notebooks e extensões através de duas RFCs normativas, modelos de dados de células Jupyter, validação de manifestos de plugin com sandbox e decisões arquiteturais transparentes:
1. **RFC 01 — Notebooks Interativos (`plan/rfc-01-notebooks-interativos.md`):** Avaliação de modelo de células (`code`, `markdown`), saídas estruturadas de execução (`stream`, `execute_result`, `error`), ciclo de vida do kernel (`idle`, `starting`, `busy`, `restarting`, `dead`) e justificativa formal de deferral de execução pesada de kernels Jupyter em runtime nativo.
2. **RFC 02 — Extensões e Plugins (`plan/rfc-02-sistema-extensoes-plugins.md`):** Definição da fronteira de extensibilidade com posicionamento mandatória de que **plugins React NÃO são widgets Flutter**, especificando sandbox de permissões (`filesystem.read`, `network`, `terminal.pty`), versionamento semver e priorização de protocolos padronizados (LSP, DAP, MCP).
3. **Decisão Explícita de Adiar (Deferral):** Inclusão formal de ADRs em `ExtensibilityEvaluationRegistry` registrando a rejeição de embutir componentes React e o adiamento de kernels de computação pesada, protegendo o design minimalista, a responsividade a 60fps e o modelo project-first.

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/notebook_plugin_eval.dart`)
- **`NotebookCellKind`** & **`NotebookCellOutput`**: Tipos de célula e saídas ricas com metadados.
- **`NotebookCell`** & **`JupyterNotebookDocument`**: Representação de caderno `.ipynb` com contadores de código e documentação.
- **`PluginPermission`** & **`PluginContribution`**: Permissões granulares de acesso e pontos de extensão declarativos.
- **`PluginManifest`** & **`PluginSandboxPolicy`**: Manifesto tipado e validador de violações de sandbox.
- **`ExtensibilityEvaluationReport`**: Modelo formal de ADR registrando decisões de aceitação, rejeição ou adiamento.

### 2.2 Serviços de Domínio (`cockpit/lib/app/core/domain/services/notebook_plugin_eval_service.dart`)
- **`JupyterNotebookParser`**: Decodificador tolerante a falhas do formato JSON do Jupyter Notebook v4 (`.ipynb`).
- **`PluginManifestValidator`**: Validador de compatibilidade de versão SemVer e auditor de segurança de sandbox.
- **`ExtensibilityEvaluationRegistry`**: Repositório imutável das decisões arquiteturais e alternativas recomendadas.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 5 testes em `cockpit/test/domain/notebook_plugin_eval_test.dart`:
  1. Parsing completo de arquivo `.ipynb` com células de markdown, código e saída de erro;
  2. Validação de manifesto conforme com permissões e contribuições;
  3. Rejeição de manifesto com versão incompatível do Orkest;
  4. Auditoria de violações de sandbox contra permissões bloqueadas (rede, escrita em disco, PTY);
  5. Registro formal de decisões técnicas rejeitando plugins React e adiando kernel nativo de Jupyter.
- **Suíte Combinada:** 36 testes aprovados em conjunto (`notebook_plugin_eval_test.dart`, `docker_build_deploy_test.dart`, `http_advanced_tools_test.dart`, `editor_productivity_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` 100% limpo (**0 issues**).
