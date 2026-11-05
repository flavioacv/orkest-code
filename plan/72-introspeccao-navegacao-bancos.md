# Introspecção Avançada e Navegação de Bancos de Dados (B01)

## 1. Visão Geral
A atividade **B01** do Plano 72 expande a introspecção de bancos de dados do Orkest Code para além da visualização superficial de tabelas e colunas, introduzindo suporte completo a **índices**, **chaves estrangeiras (foreign keys)**, **views**, **rotinas/funções**, geração automática de **DDL** (`CREATE TABLE` / `CREATE VIEW`) e **invalidação seletiva de cache de schema** na árvore visual.

## 2. Componentes e Arquitetura

### 2.1 Modelos de Introspecção (`lib/app/orkest/domain/entities/db_schema_entities.dart`)
- **`SchemaIndex`**: Modela nome, tabela, lista de colunas, unicidade (`isUnique`) e chave primária (`isPrimary`).
- **`SchemaForeignKey`**: Modela nome da constraint, coluna de origem, tabela e coluna referenciadas, e regras de integridade referencial (`onDelete`, `onUpdate`).
- **`SchemaRoutine`**: Modela rotinas com identificação de tipo (`function` vs `procedure`), schema e tipo de retorno.
- **`SchemaTableDetail`**: Agregação estruturada contendo as colunas, índices e chaves estrangeiras de uma tabela.

### 2.2 Consultas SQL Especializadas (`lib/app/orkest/domain/db_schema_sql.dart`)
- **`dbIndexesSql`**: Dialetos nativos para SQLite (`PRAGMA index_list`), PostgreSQL (`pg_indexes`/`pg_index`), MySQL (`SHOW INDEX FROM`) e SQL Server (`sys.indexes`).
- **`dbForeignKeysSql`**: Dialetos nativos para SQLite (`PRAGMA foreign_key_list`), PostgreSQL (`information_schema.referential_constraints`), MySQL (`information_schema.KEY_COLUMN_USAGE`) e MSSQL (`sys.foreign_keys`).
- **`dbRoutinesSql`**: Extração de rotinas em PostgreSQL, MySQL e MSSQL, excluindo schemas internos do sistema.
- **`dbViewDefinitionSql`**: Extração determinística do código SQL de definição de views.

### 2.3 Gerador Determinístico de DDL (`lib/app/orkest/domain/services/db_ddl_generator.dart`)
- **`DbDdlGenerator`**: Gera scripts `CREATE TABLE` completos com identificadores devidamente delimitados (`"col"` em PG/SQLite, `` `col` `` em MySQL, `[col]` em MSSQL), constraints inline/table-level e instruções `CREATE INDEX` adicionais. Suporta também `CREATE VIEW ... AS ...`.

### 2.4 Integração na ViewModel e Painel (`DatabaseViewModel` e `DbPanel`)
- Caches dedicados (`_indexesCache`, `_foreignKeysCache`, `_routinesCache`) com método de invalidação seletiva `invalidateSchema(connName)`.
- Opção "Recarregar Schema" no menu de contexto de cada conexão.
- Componente `_TableDetailList` na árvore exibindo subseções expansíveis para colunas (com indicador PK), índices (com UNIQUE/PK) e chaves estrangeiras (`coluna ➔ tabela_ref.coluna_ref`).
- Ação de contexto na tabela/view: `Copiar DDL (CREATE)` e `Copiar SELECT *`.

## 3. Validação
- **Testes Automatizados**:
  - `cockpit/test/domain/db_schema_sql_test.dart` (19 testes)
  - `cockpit/test/domain/db_ddl_generator_test.dart` (4 testes)
  - `cockpit/test/domain/db_schema_entities_test.dart` (4 testes)
- **Regressão de Banco de Dados**: 81 testes da suíte completa de DB aprovados com 100% de sucesso.
- **Análise Estática**: `dart analyze --fatal-infos` com 0 issues.
