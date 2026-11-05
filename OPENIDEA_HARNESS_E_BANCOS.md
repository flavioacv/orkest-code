# Harness e bancos no OpenIDEA

Inspeção estática em 04/11/2026 do checkout `../openidea`, commit `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`. Nenhum agente ou banco foi iniciado; não houve instalação, consulta de dados ou teste runtime.

## Como os harness são mapeados

O OpenIDEA possui um catálogo de lançamento e uma camada de protocolos. Não foi encontrado um parser específico de tela para cada nome exibido. O núcleo cria/controla processos e recebe mensagens estruturadas.

`crates/ide-agent/src/provider.rs` define `ProviderSpec`: id, nome, driver, executável, argumentos, variáveis de ambiente, orientação de login e origem. Existem três drivers: ACP, Codex e Claude. Os dois nativos são traduzidos para um endpoint ACP interno; o restante do sistema trabalha com o mesmo contrato.

### Entradas padrão do checkout

| ID | Nome | Transporte/lançamento declarado |
|---|---|---|
| claude | Claude Code | Driver nativo; `claude`, lançado em modo stream-json pela integração |
| codex | Codex | Driver nativo; `codex app-server` |
| claude-acp | Claude Code (ACP) | `npx -y @agentclientprotocol/claude-agent-acp@0.97.0` |
| codex-acp | Codex (ACP) | `npx -y @agentclientprotocol/codex-acp@2.3.0` |
| gemini | Gemini CLI | `gemini --experimental-acp` |
| copilot | GitHub Copilot | `copilot --acp` |
| cursor | Cursor | `cursor-agent acp` |
| opencode | OpenCode | `opencode acp` |
| qwen | Qwen Code | `qwen --experimental-acp` |
| kimi | Kimi CLI | `kimi acp` |
| goose | Goose | `goose acp` |
| auggie | Auggie | `auggie --acp` |
| kiro | Kiro | `kiro-cli acp` |
| vibe | Mistral Vibe | `vibe-acp` |

São 14 entradas, incluindo duas alternativas ACP para produtos também atendidos por drivers nativos. Não representam 14 parsers nativos nem certificação de funcionamento das versões atualmente instaladas.

### Catálogo externo e configuração customizada

`registry.rs` consome o catálogo em `https://cdn.agentclientprotocol.com/registry/v1/latest/registry.json`, mantém cache e trata distribuição binária por plataforma, npm e uv. Persiste instalações em `<config>/agents/<id>.toml`; ferramentas ficam em `<data>/agents/tools/<id>/<version>/`. O código prevê checksum SHA-256 de arquivos quando fornecido pelo catálogo e explicita o caso sem checksum. Instalação, disponibilidade do runtime e autenticação são condições distintas.

Também aceita arquivos TOML personalizados com nome, driver, comando, argumentos e ambiente. Assim, cadastrar um novo agente ACP não exige criar outro normalizador de conversa.

A lista `FEATURED` em `src/features/agents/registry.ts` contém Copilot, Gemini, Cursor, OpenCode, Amp, Devin, Factory Droid, Junie, Cline, Kilo, Antigravity, Grok Build, Qoder, Pi, Poolside e DeepAgents. Ela apenas ordena nomes conhecidos na interface. Não comprova que estejam instalados, que existam no catálogo atual ou que tenham testes próprios. O catálogo remoto não foi consultado nesta análise.

## Descoberta de capacidades e leitura de eventos

1. O catálogo informa como iniciar o processo.
2. `providers()` descreve o provedor; o teste de instalação é sobre a disponibilidade do comando. Disponibilidade de `npx`, por exemplo, não comprova que o adaptador esteja baixado ou autenticado.
3. `probe()` inicia a conexão e envia `initialize`, sem abrir sessão de conversa. Obtém nome, versão, autenticação e capacidades; encerra o processo usado na sondagem e mantém cache.
4. A sessão negocia o protocolo. `acp/mod.rs` possui negociação das gerações v1/v2 e adaptação de chamadas/permissões.
5. `acp/normalize.rs` converte updates v2 para a forma v1 consumida pela timeline. Guarda estado por sessão, toolCallId, messageId e terminal; combina chunks, mensagens completas, planos e compactações. A saída acumulada de terminal mantém uma cauda limitada a 64 KiB.
6. `timeline.rs` agrega texto, chamadas de ferramenta, status, localizações, saída e diffs. `conversation.rs` trata associação de sessões e subagentes.
7. `model.rs` oferece um modelo uniforme: tarefas, configuração, fila, uso, retries, permissões e eventos de UI. Estados incluem Starting, Running, NeedsInput, Ready, Failed, Limited e Archived.

As capacidades normalizadas incluem imagens, fork, rollback e steer. Algumas dependem de metadados específicos de OpenIDEA, portanto não devem ser presumidas em qualquer agente ACP. Outros dados, como configuração e slash commands, são reportados por sessão. Esse modelo permite que a UI reflita o suporte efetivo do agente.

### Drivers nativos

- **Codex:** `native/codex/mod.rs` conecta ao app-server por JSON-RPC em linhas; threads/turns e notificações de itens são traduzidos para sessões/updates ACP. Há tratamento de deltas, execução de comandos, mudanças de arquivo, aprovações e perguntas ao usuário. Threads de subagentes são correlacionadas ao pai.
- **Claude:** `native/claude` controla `claude -p` em stream-json, traduz blocos/eventos, responde a control requests e `can_use_tool`; trata histórico/transcript, retomada, fork e interrupção conforme implementação.

Isso controla uma sessão iniciada pelo editor. Não equivale a anexar o leitor a qualquer TUI existente. Migrar para esses drivers muda a forma de interação com o agente e precisa preservar os fluxos que o usuário espera.

## Persistência e testes

O catálogo tem cache JSON; a configuração dos provedores usa TOML. O código de tarefas usa gravação JSON temporária seguida de rename; Claude também possui leitura de histórico/transcripts próprios. Nesta área não foi identificada necessidade de um banco relacional para que o mapeamento funcione.

`replay.rs` descreve captura de frames reais em fixtures JSONL e reprodução pelo mecanismo de tarefas. O replay espera mensagens do cliente por tipo/método, tolerando corridas e diferenças de paths/timestamps. Existem fixtures para Codex, Claude e ACP, cobrindo cenários como turnos, interrupção, retomada, permissões, subagentes e falhas. Não há evidência de cobertura equivalente para cada nome do catálogo. Os testes não foram executados nesta análise.

## Relação com o leitor atual do Orkest

O Orkest já separa partes relevantes:

- `terminal_harness_normalizer.dart`: normaliza executáveis, runtimes, scripts e aliases.
- `terminal_harness_classifier.dart`: identifica invocações interativas e exclui modos administrativos/não interativos.
- `terminal_harness_monitor.dart`: acompanha árvore de processos ancorada na sessão/PTY, incluindo WSL e polling adaptativo.
- `terminal_session.dart`: combina atividade, hooks, identidade de sessão, aprovação e sinais do terminal. Os hooks já fornecem informação estruturada; o Orkest não depende apenas de regex da tela.

| Necessidade | OpenIDEA | Direção proposta no Orkest |
|---|---|---|
| Identificar agente em terminal existente | Não é a função principal do catálogo ACP | Preservar monitor/classificador e correlação por PTY |
| Iniciar conversa controlada pelo editor | Drivers ACP/nativos e capabilities | Criar modo opcional com protocolo estruturado |
| Representar ferramentas, permissões e subagentes | Updates normalizados com IDs e associação | Aproveitar desenho de eventos e seus casos de regressão |
| Adicionar provedores | Catálogo + TOML + ACP | Separar metadados de lançamento, transporte e leitura de TUI |
| Prevenir duplicação e atribuição errada | Estado por sessão/mensagem/ferramenta | Preservar geração da sessão, origem do evento e deduplicação |
| Testar alterações de protocolo | Fixtures JSONL e replay | Adotar capturas anonimizadas por provedor e versão |

Recomendo duas entradas convergindo para o modelo de atividade do Orkest: (a) terminal interativo, com processos/hooks e sinais disponíveis; (b) sessão controlada, com ACP ou driver nativo. A precedência e deduplicação precisam ser definidas por evento/sessão, para evitar que uma mensagem antiga do terminal sobreponha um término confirmado. Um catálogo maior melhora descoberta; sozinho, não melhora precisão de leitura.

Esse desenho pode ser implementado em Dart. O valor do Rust aqui está na possibilidade de reaproveitar `ide-agent`, seus drivers e testes; não em uma exigência técnica de linguagem. Antes de adotar o backend, verificar dependências de host, eventos, arquivos, permissões e lifecycle. A arquitetura permanece uma recomendação, não decisão aprovada.

## Bancos: área independente dos harness

`ide-db/src/source.rs` declara cinco drivers: SQLite, PostgreSQL, MySQL/MariaDB, SQL Server e ClickHouse. O código inspecionado não declara Redis/MongoDB nesse enum. Isso não deve ser confundido com o catálogo de agentes.

O módulo possui configuração por projeto em `.openidea/data-sources.toml`, senhas separadas da configuração, opções de SSL/SSH, schemas e introspecção, filtros de objetos, console SQL, completion, histórico, DDL, explain, paginação, edição e controle de transações. A presença das operações não garante equivalência de recursos entre os cinco drivers.

O Orkest já oferece banco e conexões SQL/Redis/MongoDB. As oportunidades mais claras de comparação são profundidade da introspecção, visualização de objetos/DDL, completion contextual, explain e transações manuais. ClickHouse é uma diferença de driver a avaliar conforme demanda; não justifica substituir a infraestrutura atual inteira.

Conclusão técnica: o maior aprendizado de harness é a separação entre catálogo, transporte, negociação, normalização e apresentação, acompanhada de replay de eventos. Para bancos, avaliar as funções individualmente frente ao que o Orkest já entrega.
