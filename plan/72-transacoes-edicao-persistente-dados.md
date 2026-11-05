# Transações e Edição Persistente de Dados com Concorrência Otimista (B02)

## 1. Visão Geral e ADR
O modelo arquitetural de banco de dados do Orkest Code (decisão D do Plano 51) adota execuções **efêmeras** por padrão: cada consulta abre a conexão física com o banco de dados, executa a instrução e encerra a conexão. Esse modelo simplifica imensamente o gerenciamento de recursos, evita vazamento de conexões ociosas e elimina retenção desnecessária de locks no servidor.

No entanto, a introdução de **transações manuais** (ex.: `BEGIN`, seguidos de múltiplos comandos e finalizando em `COMMIT` ou `ROLLBACK`) cria um desafio fundamental:
- **Problema de Simulação Ingênua**: Se cada chamada for tratada isoladamente em conexões efêmeras distintas, a emissão de um `BEGIN;` ocorre na conexão A, o `INSERT` na conexão B e o `COMMIT` na conexão C. Isso destrói o isolamento transacional, gera transações órfãs ou cria uma falsa ilusão de atomicidade.
- **Decisão Arquitetural (ADR)**:
  1. Transações manuais explícitas exigem uma **sessão dedicada com lease de conexão** (`DbTransactionSession`), mantendo o canal físico fixo para todos os comandos subsequentes.
  2. A sessão impõe **timeout automático de inatividade** (padrão: 60 segundos). Caso o desenvolvedor ou a interface se desconecte sem commitar, o sistema executa um `ROLLBACK` preventivo para não prender locks no banco.
  3. No descarte da sessão (`dispose`), o rollback é executado obrigatoriamente.
  4. O schema do banco de dados NUNCA é modificado por transações manuais arbitrárias; alterações DDL destrutivas continuam exigindo confirmação explícita ou migrations versionadas.

## 2. Componentes e Arquitetura

### 2.1 Sessão de Transação Dedicada (`lib/app/orkest/domain/services/db_transaction_session.dart`)
- **`DbTransactionState`**: `active`, `committed`, `rolledBack`, `timedOut`.
- **`DbTransactionSession`**:
  - Encapsula o executor atrelado ao mesmo canal de conexão.
  - Armazena histórico sequencial dos comandos executados (`history`).
  - Métodos `execute(sql)`, `commit()`, `rollback()` e `dispose()`.
  - Timer rearmável de inatividade disparando rollback preventivo.

### 2.2 Gerenciador de Transações (`lib/app/orkest/domain/services/db_transaction_manager.dart`)
- **`DbTransactionManager`**:
  - `beginTransaction`: inicia a sessão física emitindo `BEGIN;` e registra o lease em `_activeSessions`.
  - `getSession(id)` e `disposeAll()`.

### 2.3 Edição Persistente com Concorrência Otimista (`lib/app/orkest/domain/services/db_row_edit_service.dart`)
- **`DbRowEditService`**:
  - `generateOptimisticUpdateSql`: gera cláusula `UPDATE <table> SET <col> = <valNew> WHERE <pk> = <pkVal> AND <col> = <valOld>;`. Se outro usuário alterou o dado concorrentemente, a query afeta 0 linhas, permitindo sinalizar conflito e recarregar o registro.
  - `generateRowDeleteSql`: gera exclusão baseada estritamente na chave primária.
  - `generateRowInsertSql`: inserção com formatação literal segura.
  - **Guardrail**: Rejeição de qualquer tentativa de update/delete em tabelas sem chave primária (lança `DbEditException`).

## 3. Validação
- **Testes Automatizados**:
  - `cockpit/test/domain/db_row_edit_service_test.dart`: 7 testes unitários cobrindo geração de DML otimista, formatação de literais, primary keys compostas e guardrails de segurança.
  - `cockpit/test/domain/db_transaction_session_test.dart`: 4 testes de ciclo de vida cobrindo commit, rollback explícito, timeout de inatividade e dispose preventivo.
- **Regressão**: 35 testes combinados de B01 e B02 aprovados com 100% de sucesso.
- **Análise Estática**: `dart analyze --fatal-infos` com zero issues.
