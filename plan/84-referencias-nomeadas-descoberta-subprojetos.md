# D02 · Referências Nomeadas entre Pastas e Descoberta Contextual de Subprojetos

> **Branch:** `fix/harness-state-detection`  
> **Data:** 07/11/2026  
> **Status:** Concluído (Validado com 0 issues de análise estática e 41 testes de Debug/DAP aprovados)  
> **Contexto:** Épico E3 (`E3 · Integrar jornada Run, Debug e Test`) do Kanban 73 (`plan/73-frontend.kanban`).

---

## 1. Contexto e Motivação

No desenvolvimento de aplicações corporativas e monorepos compostos por múltiplos projetos interdependentes (ex: `client`, `server`, `backend`, `shared`), arquivos de configuração de execução e depuração (`.vscode/launch.json` ou `.orkest/run.json`) frequentemente utilizam a sintaxe oficial do VS Code para referenciar pastas irmãs no workspace:
- `${workspaceFolder:nome_do_projeto}` ou `${workspaceRoot:nome_do_projeto}`.
- Configurações de subprojetos localizados em diretórios aninhados (`packages/backend`, `apps/web`) que não foram adicionados explicitamente como raízes primárias do workspace.

Anteriormente, o `RunConfigurationLoader` e o `LaunchJsonLoader` substituíam apenas a variável global fixa `${workspaceFolder}`, lançando `FormatException('Unsupported launch variable')` ao encontrar a sintaxe com escopo de nome `:nome`. Além disso, subprojetos internos dependiam exclusivamente da inferência heurística simples do `RunConfigurationProducer`, sem carregar seus arquivos `launch.json` locais.

---

## 2. Implementação Realizada

### A. Resolução de Referências Nomeadas `${workspaceFolder:nome}`
- Modificados [`RunConfigurationLoader.expand`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/lib/app/orkest/domain/services/run_configuration_loader.dart#L136) e [`LaunchJsonLoader`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/lib/app/orkest/data/tasks/launch_json_loader.dart#L115):
  - Recebem a lista completa de raízes do workspace (`workspaceRoots`).
  - Mapeiam cada raiz candidata por seu nome/basename (`p.basename(wr)`).
  - Substituem deterministamente ocorrências de `\${workspaceFolder:$folderName}` e `\${workspaceRoot:$folderName}` pelo caminho absoluto normalizado da raiz correspondente.

### B. Descoberta Contextual de Subprojetos Monorepo
- Em `RunConfigurationLoader.load`:
  - Ao inspecionar o arquivo em foco (`file`), localiza o diretório pai que contém marcadores de projeto (`pubspec.yaml`, `package.json`, `Cargo.toml`, `pyproject.toml`).
  - Caso esse subprojeto (`fileRoot`) possua configurações locais em `.vscode/launch.json` ou `.orkest/run.json` e não esteja cadastrado diretamente como raiz primária do workspace, suas configurações são carregadas dinamicamente com nomes qualificados (`name · fileRoot`).
  - Em seguida, preserva a geração contextual de testes e execução via `RunConfigurationProducer`.

---

## 3. Validação e Qualidade

1. **Análise Estática Estrita:**
   - Executado `cd cockpit && dart analyze --fatal-infos`.
   - **Resultado:** `No issues found!` (0 erros, 0 avisos em toda a base e testes).

2. **Suíte de Testes Automatizados:**
   - `test/tasks/run_configuration_test.dart`: 11/11 testes aprovados (incluindo resolução de `${workspaceFolder:nome}` e descoberta contextual de subprojeto monorepo com `launch.json`).
   - `test/ui/debug_widgets_test.dart`: 30/30 testes aprovados (DAP lifecycle, Hot Reload, Hot Restart, Watches, Breakpoints, activeDebugLine no gutter).
   - **Total:** 41 testes de integração e componentes de execução/DAP executados e aprovados com 100% de sucesso.
