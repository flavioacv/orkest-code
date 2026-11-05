# Homologação de Linguagens por Níveis de Capacidade (L05)

> **Atividade:** `L05 · Homologar linguagens por níveis de capacidade`  
> **Prioridade:** P1 · Porte: L · Dependências: L02, L03, L04 (Concluídas)  
> **Status:** Concluído e Homologado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

A atividade **L05** estabelece a matriz formal de níveis de capacidade (*tiers*) de suporte a linguagens no Orkest Code, superando o modelo binário de "suporta / não suporta" e documentando de forma transparente e verificável o ecossistema de cada linguagem sem prometer paridade falsa.

A categorização em 3 níveis (*tiers*) alinha-se aos padrões de mercado:
1. **Tier 1 (Core / Primeira Classe):**
   - Suporte completo com LSP avançado (diagnostics, hover, completion com imports, signature help com overloads, semantic tokens, rename, formatting, code actions, outline e workspace symbols) e adaptadores DAP para depuração interativa.
   - Linguagens: **Dart/Flutter**, **TypeScript**, **JavaScript**, **Python**, **Go**, **Rust**.
2. **Tier 2 (Enterprise & Sistemas / Fase Seguinte):**
   - Suporte corporativo e de backend com language servers estruturados e adaptadores DAP documentados.
   - Linguagens: **Java** (`jdtls`, `java-debug`), **C#** (`csharp-ls`, `netcoredbg`), **PHP** (`intelephense`).
3. **Tier 3 (Web, Dados, Scripts e Configuração sob demanda):**
   - Linguagens de marcação, estilo, configuração e dados com suporte a formatação, completion, validação e highlight sintático; sem falsas promessas de recursos inaplicáveis (ex.: ausência intencional de signature help em JSON/YAML/HTML/CSS).
   - Linguagens: **SQL** (`sql-language-server`), **Vue** (`vue-language-server`), **Svelte** (`svelte-language-server`), **HTML**, **CSS**, **SCSS**, **Less**, **JSON**, **JSONC**, **YAML**, **Shell Script**.

---

## 2. Componentes e Contratos Entregues

- **Enum `LanguageTier` e Expansão do Catálogo** (`cockpit/lib/app/core/data/lsp/lsp_launchers.dart`):
  - Definição do enum `LanguageTier` (`tier1Core`, `tier2Enterprise`, `tier3WebData`);
  - Campo `tier` adicionado a `LanguageDef` com valor default `LanguageTier.tier3WebData`;
  - 20 linguagens catalogadas declarativamente, sem duplicações de identificador;
  - Adição de linguagens sob demanda requeridas no plano:
    - **SQL**: extensão `.sql`, comentário `--`, servidor `sql-language-server`, sem DAP;
    - **Vue**: extensão `.vue`, marcadores Vite/Nuxt, servidor `vue-language-server`, SDK Vue 3;
    - **Svelte**: extensão `.svelte`, marcador `svelte.config.js`, servidor `svelteserver`, SDK SvelteKit.
- **Matriz de Homologação e Auditoria Transparente** (`cockpit/lib/app/core/domain/entities/language_capability_matrix.dart`):
  - `LanguageSupportStatus`: classificação determinística do ambiente (`fullySupported`, `partiallySupported`, `missingServer`, `syntaxOnly`);
  - `LanguageAuditReport`: discriminação detalhada dos recursos ativos vs não suportados por design;
  - `LanguageCapabilityMatrix`: agrupamentos por tier, auditoria com injeção de checagem de executáveis (`executableChecker`) e exportação estruturada (`exportMatrix`).
- **Fixtures Sintéticas de Linguagens** (`cockpit/test/fixtures/languages/`):
  - 11 fixtures cobrindo `Dart`, `TS`, `Python`, `Go`, `Rust`, `Java`, `C#`, `PHP`, `SQL`, `Vue`, `Svelte`.

---

## 3. Validação e Qualidade

- **13 testes dedicados** aprovados com 100% de sucesso em:
  - `cockpit/test/integration/language_capability_homologation_test.dart` (5 testes): unicidade de IDs, validação dos 3 tiers, resolução de caminhos/fixtures e auditoria transparente;
  - `cockpit/test/data/lsp_launchers_test.dart` (8 testes): resolução por extensão e nomes especiais, isolamento de executáveis e comandos com espaços.
- **Zero erros ou alertas** na análise estática `dart analyze --fatal-infos`.
