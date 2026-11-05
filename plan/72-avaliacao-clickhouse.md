# Avaliação Técnica e Arquitetural de ClickHouse (B03)

> **Data:** 05/11/2026  
> **Status:** Avaliado e Decidido (Conector sob Demanda / Opt-in)  
> **Contexto:** Atividade B03 do plano `72-orkest-ide-completa.md` — Evolução do Console SQL e Avaliação de ClickHouse.

---

## 1. Visão Geral e Contexto

O **ClickHouse** é um sistema de gerenciamento de banco de dados colunar voltado para processamento analítico online em larga escala (**OLAP**). Ele se destaca por agregação e varredura massiva de logs, eventos, telemetria de séries temporais e dados analíticos com compressão colunar e execução vetorizada.

No ecossistema atual do **Orkest Code**, a camada de banco de dados (`DbEngine`, `DbDriver`, `DbQueryService`, `DatabaseViewModel`) suporta:
- **Bancos Relacionais / Transacionais (OLTP):** PostgreSQL, MySQL, SQLite, Microsoft SQL Server (MSSQL);
- **NoSQL / Cache / Chave-Valor:** Redis (browse de chaves, TTL, tipos KV, scans);
- **NoSQL Documentos:** MongoDB (browse de databases, collections e query filter JSON).

A atividade B03 previa a avaliação formal da viabilidade técnica, protocolos e impacto de segurança da introdução do ClickHouse.

---

## 2. Protocolos de Integração Possíveis

| Protocolo | Porta Padrão | Complexidade de Integração | Dependências Necessárias |
|---|---|---|---|
| **HTTP / JSONCompact** | 8123 | **Baixa** (Flutter/Dart puro via `HttpClient` padrão) | Nenhuma dependência externa adicional |
| **Native TCP** | 9000 | **Alta** (protocolo binário com compactação LZ4/ZSTD) | Exigiria bridge Rust (`clickhouse-rs`) via FFI/processo |
| **MySQL Wire Emulation** | 9004 | **Média** (emulação parcial de protocolo MySQL) | Incompatibilidades com dialetos específicos e DDL |
| **gRPC** | 9107 | **Média/Alta** (exige schemas Protobuf e geração de código) | Pacote `grpc` e stubs Dart |

### Recomendação de Protocolo:
Se o ClickHouse for ativado no Orkest Code, o protocolo ideal é a **interface HTTP REST nativa** (`http://host:8123/?query=...&default_format=JSONCompactEachRowWithNamesAndTypes`):
1. **Dart Puro:** Usa o `HttpClient` do `dart:io`, mantendo a garantia de zero dependências C/C++ ou subprocessos pesados;
2. **Normalização Imediata:** O formato `JSONCompactEachRowWithNamesAndTypes` mapeia 1:1 para a estrutura `DbResult(columns, rows, elapsed)` já usada pelo Orkest;
3. **Compatibilidade Remota:** Trafega facilmente através de túneis SSH e proxies corporativos sem necessidade de portas TCP binárias especiais abertas.

---

## 3. Análise de Segurança e Credenciais

- **Cofre e Passwords:** As credenciais de conexões ClickHouse devem seguir estritamente o cofre unificado do Orkest (`DbSecrets` com Keychain no macOS, Secret Service no Linux e credenciais protegidas em workspaces remotos);
- **Autenticação:** O ClickHouse suporta autenticação via header HTTP `X-ClickHouse-User` e `X-ClickHouse-Key`, garantindo que senhas nunca sejam expostas em logs de URLs ou histórico;
- **Lease e Conexões:** Sendo baseado em HTTP stateless, conexões ClickHouse não retêm locks nem exigem leases de transação (pois não é um banco OLTP ACID tradicional).

---

## 4. Decisão Arquitetural (ADR)

1. **Princípio YAGNI e KISS:** O ecossistema atual de desenvolvimento do `remote_pi` e projetos irmãos não possui carga analítica OLAP que justifique a inclusão imediata de uma nova engine nativa no menu padrão de bancos.
2. **Preservação de Escopo:** Manter os 6 engines atuais (PostgreSQL, MySQL, SQLite, MSSQL, Redis, MongoDB) perfeitamente integrados e estáveis.
3. **Decisão:** **Não incluir o ClickHouse compulsoriamente no bundle básico**. Manter a especificação da interface HTTP pronta para ser plugada como driver sob demanda caso surja um workspace ou serviço que requisite armazenamento analítico colunar explícito.
