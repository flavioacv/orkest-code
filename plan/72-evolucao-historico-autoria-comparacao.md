# Evolução de Histórico, Autoria e Comparação Git (G03 Orkest Code)

> **Data:** 05/11/2026  
> **Branch:** `fix/harness-state-detection`  
> **Status:** Concluído e Validado

---

## 1. Contexto e Motivação
A atividade `G03 · Evoluir histórico, autoria e comparação` expande os recursos de Version Control System (VCS) do Orkest Code, dotando a IDE de recursos avançados de auditoria de código, autoria granular linha a linha (`git blame`) e comparação entre branches ou revisões arbitrárias, sem depender de parsing de arte gráfica ASCII (`--graph`).

---

## 2. Componentes Entregues

### 2.1. Entidades de Domínio para Histórico e Auditoria
- **`GitBlameHunk` (`cockpit/lib/app/orkest/domain/entities/git_blame_hunk.dart`):**
  - Modelagem estruturada dos blocos de autoria com hash completo, `shortHash`, autor, email, timestamp do commit (`authorTime`), sumário da mensagem e intervalo de linhas (`finalLine`, `lineCount`, `containsLine`).
- **`GitHistoryQuery` (`cockpit/lib/app/orkest/domain/entities/git_history_query.dart`):**
  - Paginação via `limit` e `skip`;
  - Filtros por caminho de arquivo (`filePath`) com acompanhamento de renomeações (`--follow`);
  - Filtros por autor (`author`) e por mensagem/assunto (`query`);
  - Intervalos de revisão (`revisionRange`) e inclusão de todas as referências (`all: true`).
- **`GitComparison` (`cockpit/lib/app/orkest/domain/entities/git_comparison.dart`):**
  - Modelo para comparação entre duas referências (`baseRef` e `targetRef`), contendo lista de commits exclusivos e lista de arquivos alterados/adicionados/removidos.

### 2.2. Parsers Estruturados
- **`GitBlameParser` (`cockpit/lib/app/orkest/domain/git_blame_parser.dart`):**
  - Decodificação robusta do formato padrão `git blame --porcelain`;
  - Cache dinâmico de metadados de commits para reaproveitamento em hunks repetidos (otimização nativa do Git Porcelain);
  - Agrupamento de linhas contíguas do mesmo hunk e suporte a saídas truncadas ou parciais.

### 2.3. Leitor Estruturado Estendido (`cockpit/lib/app/orkest/data/filesystem/git_history_reader_impl.dart`)
- **`read`:** Consulta parametrizada com `GitHistoryQuery` combinando paginação (`--skip`) e filtros (`--author`, `--grep`, `--follow`, `--all`).
- **`readBlame`:** Execução direta de `git blame --porcelain` com suporte a intervalo de linhas (`-L<start>,<end>`).
- **`compareRefs`:** Execução atômica combinando `git diff --name-status -z` e `git log` estruturado entre duas referências (`baseRef..targetRef`).

### 2.4. Componentes Visuais
- **`GitBlameView` (`cockpit/lib/app/orkest/ui/widgets/git_blame_view.dart`):**
  - Painel de visualização de autoria com badges de linhas, identificação de commit, autor, data relativa e sumário da mensagem;
  - Campo de busca textual reativo para filtragem rápida de commits e autores dentro do arquivo;
  - Ação de cópia do hash de commit e navegação com clique direto para a linha no editor (`onNavigateToLine`).

---

## 3. Validação e Testes Automatizados
- **Suíte de Parser de Blame (`cockpit/test/data/git_blame_parser_test.dart`):**
  - 3 testes cobrindo formato completo porcelain, reaproveitamento de metadados cacheados e tolerância a dados vazios.
- **Suíte de Integração Real (`cockpit/test/data/git_history_evolution_test.dart`):**
  - 7 testes em repositório Git temporário real validando paginação (`limit`/`skip`), filtros (`author`, `grep`, `filePath`, `--all`), `readBlame` com autoria multi-autor e `compareRefs` entre branches divergentes.
- **Suíte de Widgets (`cockpit/test/ui/git_blame_view_test.dart`):**
  - 2 testes validando renderização, filtragem dinâmica em tempo real e interações de navegação/cópia.
- **Suíte de Regressão de Histórico (`git_history_reader_impl_test.dart` e `git_history_panel_test.dart`):**
  - 10 testes de regressão aprovados sem quebras. Total: 22 testes de histórico aprovados.
- **Análise Estática:** `dart analyze --fatal-infos` com **zero issues** no projeto `cockpit`.
