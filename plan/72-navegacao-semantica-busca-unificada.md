# Navegação Semântica e Busca Unificada (L03)

> **Atividade:** `L03 · Adicionar navegação semântica e busca unificada`  
> **Prioridade:** P1 · Porte: M · Dependências: L02, W02 (Concluídas)  
> **Status:** Concluído e Homologado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

A atividade **L03** expande a inteligência de código e recursos de navegação semântica do Orkest Code, viabilizando:
1. **Navegação Semântica Completa:**
   - Obtenção de todas as referências semânticas no workspace (`textDocument/references`), com suporte à inclusão ou omissão da declaração de origem (`includeDeclaration`);
   - Resolução de implementações (`textDocument/implementation`), compatível com retornos LSP modernos (`LocationLink`) e legados (`Location`);
   - Extração do mapa/outline de símbolos do documento atual (`textDocument/documentSymbol`), suportando hierarquias aninhadas (`DocumentSymbol`) e listas planas (`SymbolInformation`);
   - Busca de símbolos por texto/query em todo o workspace (`workspace/symbol`).
2. **Histórico de Navegação Semântica Bidirecional:**
   - Gerenciamento de histórico de saltos semânticos com `SemanticNavigationHistory`;
   - Pilhas de *Go Back* e *Go Forward*, rastreando URI, linha e caractere em coordenadas UTF-16;
   - Limite configurável de tamanho do histórico (*FIFO cap* de 50 entradas) e descarte automático da pilha de avanço ao realizar um novo salto.

---

## 2. Componentes e Contratos Entregues

- **`LspLocation` & `parseLocationsResponse`** (`cockpit/lib/app/core/domain/entities/lsp_location.dart`):
  - Decodificação tolerante a falhas de respostas do LSP contendo listas ou nós singulares de `Location` (`uri`, `range`) ou `LocationLink` (`targetUri`, `targetSelectionRange`);
  - Conversão determinística para objetos `LspLocation` com coordenadas 0-indexed em code units UTF-16.
- **`LspSymbol`** (`cockpit/lib/app/core/domain/entities/lsp_symbol.dart`):
  - `LspSymbolKind`: Mapeamento canônico dos 26 tipos de símbolos da especificação LSP (File, Module, Namespace, Package, Class, Method, Property, Field, Constructor, Enum, Interface, Function, Variable, Constant, String, Number, Boolean, Array, Object, Key, Null, EnumMember, Struct, Event, Operator, TypeParameter);
  - `LspDocumentSymbol`: Estrutura com nome, detalhe opcional, kind, range do símbolo, selection range e lista recursiva de filhos (`children`);
  - `parseDocumentSymbols`: Decodificador universal com suporte tanto ao formato moderno aninhado (`DocumentSymbol[]`) quanto ao formato clássico plano (`SymbolInformation[]`).
- **`SemanticNavigationHistory`** (`cockpit/lib/app/core/domain/services/semantic_navigation_history.dart`):
  - Registro de passos de navegação (`push(fromUri, line, character)`);
  - Navegação retroativa (`goBack(currentUri, currentLine, currentCharacter)`) e progressiva (`goForward(currentUri, currentLine, currentCharacter)`);
  - Preservação de estabilidade em buffers e navegação rápida entre referências e implementações.
- **Extensão do `LspServerPool`** (`cockpit/lib/app/core/data/lsp/lsp_server_pool.dart`):
  - Métodos assíncronos:
    - `Future<List<LspLocation>> implementation(...)`
    - `Future<List<LspLocation>> references(...)`
    - `Future<List<LspDocumentSymbol>> documentSymbols(...)`
    - `Future<List<LspDocumentSymbol>> workspaceSymbols(...)`

---

## 3. Validação e Qualidade

- **13 testes dedicados** aprovados com 100% de sucesso:
  - `cockpit/test/domain/lsp_symbol_test.dart` (4 testes): mapeamento de kinds, hierarquia de document symbols, formato SymbolInformation plano e resiliência a payloads malformados;
  - `cockpit/test/domain/semantic_navigation_history_test.dart` (5 testes): empilhamento e goBack/goForward, descarte de forward stack em novo salto, limite de histórico (FIFO cap) e limpeza completa;
  - `cockpit/test/integration/lsp_semantic_navigation_test.dart` (4 testes de integração): resolução de referências no workspace, busca de implementações com LocationLink, outline de símbolos e busca em todo o workspace via `workspace/symbol`.
- **Análise Estática:** `dart analyze --fatal-infos` com zero erros e zero avisos.
