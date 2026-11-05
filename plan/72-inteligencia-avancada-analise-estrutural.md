# Inteligência Avançada e Análise Estrutural (L06) — Orkest Code

## 1. Visão Geral e Contexto
Na evolução do Orkest Code para IDE completa, os recursos semânticos avançados de linguagem devem operar de maneira eficiente e seletiva:
- **Inlay Hints (`textDocument/inlayHint`)**: exibição de tipos inferidos e nomes de parâmetros inline no editor;
- **Hierarquias (`CallHierarchy` e `TypeHierarchy`)**: navegação estruturada entre símbolos chamadores/chamados e relações de herança/implementação de tipos;
- **CodeLens (`textDocument/codeLens`, `codeLens/resolve`)**: ações contextuais e contagem de referências no cabeçalho de classes e métodos;
- **Análise Estrutural e Duplicações**: detecção de blocos repetidos de código e busca estrutural por correspondência de padrões sintáticos;
- **Subset Útil e Auditoria de Custos**: cada linguagem e servidor possui custos de latência e processamento distintos; recursos que oneram projetos grandes (como CodeLens em TypeScript ou hierarquias complexas em JSON/YAML) são seletivamente desativados por design.

---

## 2. Modelos de Domínio e Entidades

### `LspInlayHint` (`cockpit/lib/app/core/domain/entities/lsp_inlay_hint.dart`)
- `position`: `LspPosition` de inserção no buffer;
- `label`: texto do hint (com suporte a String simples ou lista de `InlayHintLabelPart`);
- `kind`: `LspInlayHintKind` (`type`, `parameter`);
- `paddingLeft` e `paddingRight`: controle visual de espaçamento;
- `tooltip`: documentação contextual ao passar o mouse.

### `LspCallHierarchyItem` & `LspTypeHierarchyItem` (`cockpit/lib/app/core/domain/entities/lsp_hierarchy.dart`)
- `LspCallHierarchyItem`: símbolo representativo, URI, range total e range de seleção (`selectionRange`);
- `LspCallHierarchyIncomingCall`: identifica quem invoca o método com lista de `fromRanges`;
- `LspCallHierarchyOutgoingCall`: identifica quais funções são invocadas a partir do método com lista de `fromRanges`;
- `LspTypeHierarchyItem`: nós de tipos para navegação em árvore de supertipos e subtipos.

### `LspCodeLens` & `LspCommand` (`cockpit/lib/app/core/domain/entities/lsp_code_lens.dart`)
- `LspCodeLens`: range associado no documento, comando resolvido ou campo `data` arbitrário para resolução preguiçosa (`lazy resolve`).

---

## 3. Métodos Integrados no `LspServerPool` (`cockpit/lib/app/core/data/lsp/lsp_server_pool.dart`)

O pool de servidores LSP incorpora métodos de consulta e resolução com degradação graciosa:
- `inlayHints(String path, LspRange range)`
- `prepareCallHierarchy(String path, int line, int character)`
- `callHierarchyIncomingCalls(String path, LspCallHierarchyItem item)`
- `callHierarchyOutgoingCalls(String path, LspCallHierarchyItem item)`
- `prepareTypeHierarchy(String path, int line, int character)`
- `typeHierarchySupertypes(String path, LspTypeHierarchyItem item)`
- `typeHierarchySubtypes(String path, LspTypeHierarchyItem item)`
- `codeLenses(String path)`
- `resolveCodeLens(String path, LspCodeLens lens)`

Se o servidor não estiver em execução, não suportar a capacidade ou retornar nulo/erro, todas as chamadas retornam coleções vazias sem quebrar o editor.

---

## 4. Análise Estrutural e Auditoria de Custos

### `StructuralAnalysisService` (`cockpit/lib/app/core/domain/services/structural_analysis_service.dart`)
1. **Detecção de Código Duplicado (`findDuplications`)**:
   - Normaliza linhas removendo comentários (`//`, `#`), pontuação cosmética e múltiplos espaços em branco;
   - Agrupa blocos deslizantes (`minLines >= 3`) e calcula o índice de similaridade de Jaccard;
   - Reporta `StructuralDuplication` contendo os intervalos originais, duplicados e percentual de similaridade.
2. **Busca Estrutural por Padrões (`searchPattern`)**:
   - Converte padrões estruturais com curingas (`$ID`, `$VAR`, `$FIELD`) em regexes de captura de sintaxe;
   - Extrai correspondências precisas no documento com ranges delimitados.
3. **Auditoria de Subset Útil (`auditLanguageSubset`)**:
   - `Dart`: ecossistema de alta fidelidade (`inlayHints`, `callHierarchy`, `typeHierarchy`, `codeLens`) com latência baixa (~18ms);
   - `TypeScript`: subset útil focado em `inlayHints` e hierarquias, com `codeLens` desabilitado por custo de I/O em monorepos;
   - `Python` & `Go`: `inlayHints` e `callHierarchy`;
   - `Linguagens Web / Configuração (JSON, YAML, HTML)`: recursos desativados por design (subset útil zero);
   - `Servidores Ausentes`: fallback seguro com degradação limpa para edição pura.

---

## 5. Validação Automatizada

- **Suíte Dedicada L06:** 9 testes aprovados em [`lsp_advanced_intelligence_test.dart`](file:///Volumes/Externo%201/projetos/zurc/remote_pi/cockpit/test/domain/lsp_advanced_intelligence_test.dart);
- **Suíte Combinada LSP:** 39 testes aprovados sem falhas (`lsp_advanced_intelligence_test.dart`, `lsp_workspace_edit_test.dart`, `safe_workspace_edit_service_test.dart`, `lsp_symbol_test.dart`, `semantic_navigation_history_test.dart`, `language_capability_homologation_test.dart`, `lsp_typescript_homologation_test.dart`);
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` com **zero issues** (0 erros e 0 alertas).
