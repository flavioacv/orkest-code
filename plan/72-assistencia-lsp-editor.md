# Assistência LSP Completa no Editor (L02)

> **Atividade:** `L02 · Completar assistência LSP no editor`  
> **Prioridade:** P1 · Porte: L · Dependências: W03, L01 (Concluídas)  
> **Status:** Concluído e Homologado em Suite Automatizada  
> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`

---

## 1. Contexto e Objetivos

A atividade **L02** consolida todo o ecossistema de inteligência de código e assistência semântica no editor do Orkest Code, operando sobre o cliente LSP stdio nativo e o pool compartilhado de servidores (`LspServerPool`), preservando a regra de não sobre-engenharia e mantendo os buffers e processos estritamente protegidos.

Sub-incrementos consolidados:
- **`L02a`**: Hover semântico formatado;
- **`L02b`**: Signature help com rastreamento de parâmetros ativos e múltiplos overloads;
- **`L02c`**: Autocomplete simples com resolução segura de imports (`additionalTextEdits`);
- **`L02d`**: Cancelamento assíncrono por documento (`$/cancelRequest`) em edições e timeouts;
- **`L02e`**: Cancelamento imediato disparado pela UI (Escape, perda de foco, scroll, dispose);
- **`L02 (Final)`**:
  - **Homologação TypeScript:** Suporte completo ao `typescript-language-server` (`ts`, `tsx`, `mts`, `cts`) com resolução de projeto via `tsconfig.json`/`package.json`, auto-imports ESM, tipos aninhados, overloads de métodos e descarte de respostas obsoletas em edições concorrentes;
  - **Expansão de Snippets (`LspSnippetService`):** Processamento limpo de snippets TextMate (`insertTextFormat: 2`) com remoção de marcadores `${1:name}` -> `name`, cálculo do cursor offset relativo do primeiro tabstop (`$1` ou `$0`), e suporte opcional via `supportSnippets: true` em `parseCompletions`.

---

## 2. Componentes e Contratos

- **`LspSnippetService`** (`cockpit/lib/app/core/domain/services/lsp_snippet_service.dart`):
  - Expansão determinística de snippets TextMate para texto puro sem lixo sintático;
  - Cálculo de `caretOffset` para posicionamento imediato do cursor;
  - Suporte a choices `${1|opt1,opt2|}`, placeholders `${1:default}` e escapes `\$`.
- **`parseCompletions` com suporte a snippets** (`cockpit/lib/app/core/data/lsp/lsp_completion.dart`):
  - Preserva compatibilidade padrão (`supportSnippets: false`), e quando ativado (`supportSnippets: true`), expande itens com `insertTextFormat: 2` em vez de descartá-los.
- **Homologação TypeScript** (`cockpit/test/integration/lsp_typescript_homologation_test.dart`):
  - Validação de ponta a ponta com cliente emulado de `typescript-language-server`;
  - Abertura de documentos `.ts`, consultas de completion com métodos e interfaces tipadas, auto-imports em `additionalTextEdits`, resolução de documentação, hover e signature help;
  - Descarte de respostas atrasadas quando o documento for editado concorrentemente.

---

## 3. Validação e Qualidade

- **14 novos testes dedicados** em `test/integration/lsp_typescript_homologation_test.dart` e `test/data/lsp_snippet_parser_test.dart`;
- **92 testes aprovados** em toda a suíte completa de LSP (codec, launchers, pool, completion, signature, hover, cancellation, snippets e homologação TypeScript);
- **Zero erros ou alertas** na análise estática `dart analyze --fatal-infos`.
