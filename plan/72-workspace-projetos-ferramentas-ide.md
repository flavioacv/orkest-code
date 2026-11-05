# W01 · Garantir Workspace por Projetos com Ferramentas IDE (Orkest Code)

> **Documento:** `plan/72-workspace-projetos-ferramentas-ide.md`  
> **Status:** Concluído / Validado  
> **Contexto:** Evolução da experiência de workspace no Orkest Code baseada no inventário OpenIDEA (`plan/72-orkest-ide-completa.md`)  
> **Branch:** `fix/harness-state-detection`

---

## 1. Visão Geral e Princípios do Workspace por Projeto

O Orkest Code adota o paradigma **Project-First & Terminal-First**: o projeto (local ou remoto) é a unidade fundamental de trabalho. Todas as ferramentas da IDE — editor de código, terminais PTY, integração com Git, diagnósticos/problemas LSP e sessões de depuração — derivam seu contexto de execução estritamente a partir da raiz do projeto ativo (`Project.effectiveRoot`).

### Garantias Essenciais de W01:
1. **Entrada Principal:** O seletor de projetos (`ProjectsRail`) e a busca de projetos continuam sendo a porta de entrada única do desenvolvedor.
2. **Isolamento de Estado:** Trocar de projeto no rail não mistura nem polui abas, buffers abertos, histórico de comandos, terminais PTY ou árvores de split panes (`_trees[projectId]`).
3. **Persistência e Restauração de Layout:** A árvore de panes e as sessões associadas a cada projeto são salvas de forma incremental e restauradas fielmente via `WorkspaceLayoutStore`.
4. **Contextualização de Ferramentas:** Editor, terminal, Git e LSP resolvem seus caminhos a partir de `effectiveRoot`, garantindo paridade entre workspaces locais no POSIX/Windows e workspaces remotos via SSH/sidecar.

---

## 2. Arquitetura de Isolamento e Roteamento de Estado

```
┌────────────────────────────────────────────────────────────────────────┐
│                              ProjectsRail                              │
│         (Projetos Locais, Worktrees Git, Remote Hosts, Realms)         │
└───────────────────────────────────┬────────────────────────────────────┘
                                    │ onSelect(projectId)
                                    ▼
┌────────────────────────────────────────────────────────────────────────┐
│                            OrkestViewModel                             │
│                                                                        │
│  _trees[projectId]          _sessions[tabId]      _layoutStore.save()  │
│  ┌───────────────────────┐  ┌──────────────────┐  ┌──────────────────┐ │
│  │ Split Tree Projeto A  │  │ TerminalSession  │  │ Documento JSON   │ │
│  ├───────────────────────┤  ├──────────────────┤  │ por projectId    │ │
│  │ Split Tree Projeto B  │  │ FileViewerSession│  │ (árvore + abas)  │ │
│  └───────────────────────┘  └──────────────────┘  └──────────────────┘ │
└─────────────┬────────────────────────────────────────────┬─────────────┘
              │ DocumentHost                               │ TerminalGateway
              ▼                                            ▼
┌───────────────────────────┐                ┌───────────────────────────┐
│     Editor & LSP Pool     │                │    Terminais & Processos  │
│  • projectRootOf(projId)  │                │  • cwd = effectiveRoot    │
│  • textDocument/uri       │                │  • env[ORKEST_PROJECT_ID] │
│  • SCM decorations por raiz│               │  • PTY isolada por sessão │
└───────────────────────────┘                └───────────────────────────┘
```

---

## 3. Matriz de Comportamento das Ferramentas por Workspace

| Ferramenta / Subsistema | Como Resolve a Raiz | Comportamento na Troca de Projeto | Persistência / Restauração |
| :--- | :--- | :--- | :--- |
| **Editor de Código** (`FileViewerSession`) | `session.projectId` -> `DocumentHost.projectRootOf(projectId)` | Mantém dirty buffers e scroll position em memória; reexibe ao voltar ao projeto. | Salvo na árvore de panes com caminho relativo/absoluto do arquivo. |
| **Terminal PTY** (`TerminalSession`) | `Project.effectiveRoot` como `workingDirectory` inicial. | Processo continua executando em background; saída acumula no buffer sem interrupção. | Sessão PTY e scrollback restaurados; reconecta se sidecar estiver ativo. |
| **Git / SCM** (`GitController`) | Repositório sob `effectiveRoot` (ou sub-roots multi-root). | Recarrega status e branch do novo projeto; descarta cache da raiz anterior. | Não perde commits nem estado de staging; branch visível no rail. |
| **LSP / Diagnósticos** (`LspServerPool`) | Raiz do projeto enviada em `initialize` (`rootUri`). | Servidor dedicado ou roteamento por documento; diagnósticos filtrados pelo projeto ativo. | Reanálise automática sob demanda; arquivos abertos reapresentam erros. |
| **Busca de Conteúdo** (`SearchIsolate`) | Escopo padrão restrito a `effectiveRoot` do projeto selecionado. | Cancela buscas ativas do projeto anterior ao trocar. | Filtros de busca recentes mantidos por projeto. |

---

## 4. Verificação e Critérios de Aceite Atendidos

1. [x] **Projeto como entrada principal:** `ProjectsRail` e atalhos de seleção preservados sem substituição por conceitos externos.
2. [x] **Roteamento correto de raiz:** `Project.effectiveRoot` fornece o caminho canônico para locais e remotos.
3. [x] **Isolamento de estado:** A troca de projeto preserva as sessões ativas no mapa global e seleciona a subárvore correta de visualização sem colisão de IDs.
4. [x] **Restauração de layout:** Documento opaco via `WorkspaceLayoutStore` preserva as abas e estrutura de splits entre reinicializações.
