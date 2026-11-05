# X01 · Priorização de Produtividade de Edição e Visualização

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P2 · **Porte:** M  
**Dependências:** W03, L02  
**Branch:** `fix/harness-state-detection`  
**Referência:** templates, macros, vim, todo, scratch, color-preview, viewers  
**Destino:** Editor e viewers já existentes  

---

## 1. Contexto e Objetivos

O item X01 estabelece o inventário formal e a infraestrutura de serviços de produtividade de edição e visualização do Orkest Code, dividindo recursos por perfil de uso (tiers de frequência) e garantindo conformidade com padrões de acessibilidade (WCAG 2.x), internacionalização e preservação do modelo Flutter puro (sem ponte C/Rust nem dependências pesadas):
1. **Inventário Estruturado de Capacidades (`ProductivityInventoryRegistry`):** Mapeamento de 10 categorias funcionais (`snippets`, `templates`, `emmet`, `folding`, `bookmarks`, `todo`, `vim`, `macros`, `colorPreview`, `scratchFiles`), associando atalhos de teclado padronizados, nível de uso (Tier 1 a 3) e rótulos de acessibilidade para leitores de tela.
2. **Expansão de Sintaxe Abreviada Emmet (`EmmetAbbreviationService`):** Processamento estruturado de aninhamentos (`>`), irmãos (`+`), multiplicações (`*N`), seletores de classe (`.class`), identificadores (`#id`), atributos customizados (`[attr="val"]`) e texto interno (`{texto}`), com tags auto-fecháveis (`input`, `img`, `br`).
3. **Detecção e Gestão de Code Folding (`CodeFoldingService`):** Mapeamento determinístico de regiões dobráveis cobrindo blocos delimitados por chaves `{ ... }`, comentários multilinhas `/* ... */` e regiões explícitas (`// #region` / `// #endregion`, `// <editor-fold>`).
4. **Varredura e Extração de Pendências (`TodoScanningService`):** Identificação e classificação de anotações em comentários (`TODO`, `FIXME`, `HACK`, `BUG`, `NOTE`, `XXX`) categorizadas por severidade (`error`, `warning`, `info`) com mapeamento exato de arquivo, linha e coluna.
5. **Amostras de Cor e Contraste Acessível (`ColorPreviewService`):** Detecção de literais de cor no código (`#RGB`, `#RGBA`, `#RRGGBB`, `#RRGGBBAA`, `rgb(...)`, `rgba(...)` e `Color(0xAARRGGBB)`), cálculo de luminância relativa e recomendação determinística de contraste (WCAG) utilizando o limiar calibrado do Orkest (`0.24`).
6. **Marcadores Rápidos e Mnemônicos (`EditorBookmarkService`):** Gerenciamento de marcadores de linha numerados (0 a 9) e nomeados, com alternância rápida (toggle) e navegação bidirecional (`nextBookmark`, `previousBookmark`).
7. **Gravação e Execução de Macros (`EditorMacroService`):** Registro de sequências atômicas de digitação e navegação de teclado para reprodução repetitiva em lote.
8. **Controlador Modal de Estado Vim (`VimStateController`):** Máquina de estados cobrindo modos canônicos (`normal`, `insert`, `visual`, `visualLine`, `command`), movimentos fundamentais (`h`, `j`, `k`, `l`) e comandos essenciais (`:w`, `:q`, `:wq`, `Esc`).

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/editor_productivity.dart`)
- **`ProductivityCategory`**: Enum com as 10 categorias funcionais.
- **`ProductivityCapability`**: Modelo imutável representando cada capacidade do inventário com identificador único, categoria, nome, descrição, atalho padrão, nível de uso e rótulo acessível.
- **`ProductivityInventoryRegistry`**: Catálogo central com 10 capacidades homologadas e helpers de filtragem por categoria e nível de uso (`byCategory`, `byUsageTier`).
- **`BookmarkItem`**: Representação de marcador em arquivo com caminho, linha, coluna, rótulo e mnemônico opcional.
- **`TodoItem`**: Entidade representando anotações de código com tag, mensagem e severidade (`TodoSeverity`).
- **`FoldingRange`**: Intervalo dobrável com linha inicial, final, tipo de dobra (`FoldingKind`: `block`, `comment`, `region`, `xml`), estado de colapso e placeholder.
- **`ColorPreviewMatch`**: Modelo de amostra de cor com texto original, valor inteiro ARGB de 32 bits, formato sintático (`ColorSyntaxFormat`), cálculo de luminância relativa e booleano `prefersLightForeground`.
- **`VimMode`**: Modos de edição modal (`normal`, `insert`, `visual`, `visualLine`, `command`).
- **`MacroAction`** & **`EditorMacro`**: Sequências atômicas de comandos gravados para reprodução.
- **`ScratchBuffer`**: Entidade imutável para gestão de rascunhos em memória.

### 2.2 Serviços de Domínio (`cockpit/lib/app/core/domain/services/editor_productivity_service.dart`)
- **`EmmetAbbreviationService`**: Parser recursivo respeitando precedência de aninhamento e multiplicação.
- **`CodeFoldingService`**: Varredura sintática de blocos e regiões explícitas.
- **`TodoScanningService`**: Extrator determinístico baseado em regex de comentários.
- **`ColorPreviewService`**: Analisador de sintaxes de cor com extração ARGB e luminância.
- **`EditorBookmarkService`**: Coleção ordenada e navegável de marcadores de código.
- **`EditorMacroService`**: Gravador e reprodutor de sequências de teclado.
- **`VimStateController`**: Controlador de modos e buffers de comando Vim.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 14 testes cobrindo todas as funcionalidades em `cockpit/test/domain/editor_productivity_test.dart`:
  1. Catálogo exaustivo com 10 categorias e rótulos de acessibilidade.
  2. Particionamento por tiers de uso (1, 2 e 3).
  3. Expansão Emmet de tags, IDs, classes, aninhamentos e multiplicações.
  4. Detecção de regiões dobráveis (blocos e comentários multilinhas).
  5. Varredura e severidades de anotações TODO, FIXME, BUG e NOTE.
  6. Detecção de hex, rgb, rgba e Color() com conformidade de contraste WCAG.
  7. Marcadores, navegação e busca por mnemônico.
  8. Macros de teclado e transições de modo Vim.
- **Suíte Combinada:** 27 testes aprovados em conjunto (`editor_productivity_test.dart`, `test_coverage_profiler_test.dart`, `multi_language_debug_adapter_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` concluído com **0 issues**.
