# X02 · Aprimoramento de HTTP, GraphQL e Navegação Web

**Status:** Concluído  
**Data de Conclusão:** 05/11/2026  
**Prioridade:** P2 · **Porte:** M  
**Dependências:** F01  
**Branch:** `fix/harness-state-detection`  
**Referência:** ide-http, http-client/graphql/web, Spring route sources  
**Destino:** `http_document`, `http_request_runner` e browser atuais  

---

## 1. Contexto e Objetivos

O item X02 aprimora as capacidades de testes de APIs e navegação web do Orkest Code, expandindo o suporte ao formato canônico `.http`, consultas GraphQL, gestão de ambientes de variáveis, histórico de chamadas e extração estática de rotas de backend, sem sobre-engenharia e preservando os mandamentos inegociáveis de segurança e privacidade:
1. **Gestão de Perfis de Ambiente (`HttpEnvironmentManager`):** Parsing estruturado de arquivos `.env`, suporte a alternância dinâmica de ambientes (dev, staging, prod, local) e mesclagem com variáveis de arquivo `.http` respeitando a precedência das declarações locais.
2. **Proteção Rigorosa de Segredos (`HttpAuthConfig`):** Mapeamento declarativo de autenticação (Bearer Token, Basic Auth com codificação segura Base64 e API Key em header/query), com mascaramento automático de credenciais sensíveis (`Authorization`, `X-API-Key`, `Cookie`) para prevenir vazamentos em telemetria, logs ou histórico.
3. **Auditoria e Histórico de Requisições (`HttpRequestHistoryService`):** Registro cronológico de chamadas com timestamps, latência em milissegundos, status code, tamanho de resposta, sanitização preventiva de URLs (expurgando `user:pass@host`) e política de retenção FIFO com filtros avançados.
4. **Cancelamento Atômico (`HttpRequestCancellationToken`):** Cancelamento determinístico de requisições em trânsito com notificação imediata de ouvintes e fechamento seguro de sockets sem deixar conexões pendentes.
5. **Suporte Completo a GraphQL (`GraphQLRequestSpec`):** Montagem do payload canônico `{ "query": "...", "variables": {...}, "operationName": "..." }` com geração de `HttpRequestSpec` em método `POST` e headers automáticos (`Content-Type: application/json`).
6. **Extração Estática de Rotas de Backend (`FrameworkRouteScanner`):** Scanner determinístico cobrindo Spring Boot (`@GetMapping`, `@PostMapping`, etc.), Express.js (`app.get`, `router.post`), FastAPI (`@app.get`, `@router.post`) e NestJS (`@Get`, `@Post`), com capacidade de exportar arquivos `.http` completos prontos para teste imediato.
7. **Navegação Web e Preservação de Engine (`WebNavigationService`):** Respeito estrito a `BrowserCapability.resolve()` para usar WebView nativa nas plataformas suportadas e delegar ao browser do SO no Linux, sem duplicar engines de navegador embutidas ou rodar processos pesados desnecessários.

---

## 2. Componentes Implementados

### 2.1 Entidades de Domínio (`cockpit/lib/app/core/domain/entities/http_advanced_tools.dart`)
- **`HttpEnvironment`**: Modelo de ambiente com nome e mapa imutável de variáveis.
- **`HttpRequestHistoryEntry`**: Registro imutável de requisições com métricas e status.
- **`HttpAuthType`** & **`HttpAuthConfig`**: Tipos de autenticação, aplicação determinística em `HttpRequestSpec` e sanitização de headers sensíveis (`sanitizeHeaders`, `maskSecret`).
- **`GraphQLRequestSpec`**: Especificação de consultas/mutações com variáveis e serialização JSON.
- **`ExtractedRoute`**: Rota extraída de código com framework, método, caminho e gerador de snippet `.http`.

### 2.2 Serviços de Domínio (`cockpit/lib/app/core/domain/services/http_advanced_tools_service.dart`)
- **`HttpEnvironmentManager`**: Parsing de `.env`, gestão de perfis e resolução de variáveis mescladas.
- **`HttpRequestHistoryService`**: Gerenciador de histórico com retenção FIFO, sanitização e filtros.
- **`HttpRequestCancellationToken`**: Token com notificação e aborto seguro.
- **`FrameworkRouteScanner`**: Scanner multi-framework e gerador de documentos `.http`.
- **`WebNavigationService`**: Sanitizador de URLs e orquestrador de modo de browser.

---

## 3. Validação e Qualidade

- **Testes Unitários:** 12 testes dedicados em `cockpit/test/domain/http_advanced_tools_test.dart`:
  1. Parsing preciso de arquivos `.env` com comentários e aspas;
  2. Alternância de ambientes e precedência de variáveis locais;
  3. Aplicação segura de Bearer, Basic e API Key;
  4. Mascaramento e sanitização de segredos em headers;
  5. Registro histórico com expurgo de credenciais na URL e política FIFO;
  6. Payload canônico e conversão de requisições GraphQL;
  7. Varredura estática de rotas Spring, Express, FastAPI e NestJS;
  8. Geração de arquivo `.http` válido a partir de rotas;
  9. Sanitização de URLs de navegação web e cancelamento determinístico.
- **Suíte Combinada:** 46 testes aprovados em conjunto (`http_advanced_tools_test.dart`, `http_document_test.dart`, `http_request_runner_test.dart`, `editor_productivity_test.dart`).
- **Análise Estática:** `puro -e stable dart analyze --fatal-infos` 100% limpo (**0 issues**).
