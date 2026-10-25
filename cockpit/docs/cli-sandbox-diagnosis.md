# CLI disponível no terminal, ausente na ferramenta do agente

Data: 24/10/2026. Correção distribuída em Orkest Code `0.1.1+2`, CLI `0.7.1r`.

## O que foi observado no DMG instalado

- `orkest-cli` existe no bundle de `/Applications/Orkest Code.app` e o app
  materializou `~/.orkest/bin/orkest`. O socket Release está disponível.
- `list-tabs --json` acessou a aba real do usuário fora do sandbox.
- Uma aba temporária criada pelo próprio CLI recebeu PATH, `ORKEST_TAB_ID`,
  `ORKEST_PANE_ID` e `ORKEST_STATUS_SOCK`. Um shell filho `zsh -lc` preservou
  essas informações e encontrou `orkest` normalmente.
- Um processo com ambiente mínimo, sem `ORKEST_*` e com PATH apenas de sistema,
  acessou o app pelo caminho absoluto do CLI e pela descoberta local do socket.
- A mesma tentativa de conexão dentro do sandbox da ferramenta retornou
  `Operation not permitted`; com autorização fora desse sandbox, funcionou.
- A consulta de erros do app não mostrou falha de inicialização/materialização.
- A aba temporária foi lida e fechada pelo CLI; a sessão do usuário foi mantida.

Isso distingue três coisas: skill global instalada, ambiente do terminal e
ambiente da ferramenta que executa comandos para o agente. A disponibilidade
da skill não garante que a ferramenta herde o PATH do terminal. A ausência das
variáveis não prova que a conversa esteja fora do aplicativo. O bloqueio de
socket pelo sandbox também não prova ausência de CLI ou defeito no DMG.
Não foi alterada a configuração global de ambiente/sandbox de nenhum harness.

## Correção

A skill agora orienta a descobrir o executável por caminho absoluto, testar
`list-tabs`, reconhecer bloqueio de permissões e solicitar aprovação pontual
pelo mecanismo da ferramenta. Não manda mais mover a conversa apenas porque
uma variável está ausente, nem substituir terminais pedidos pelo usuário por
agentes internos de colaboração.

Quando o ambiente não informa a origem, ações usam IDs explícitos obtidos pelo
CLI. O parentesco pode ser declarado com `new-tab --parent-tab <id conhecido>`;
não é inferido arbitrariamente da aba em foco. O comportamento é genérico,
sem leitura de transcripts ou classificação por fornecedor de agente.

O transporte do CLI conserva o tipo do erro de I/O e distingue permissão
negada de conexão recusada. Um endpoint órfão posterior não apaga um erro de
permissões de um endpoint anterior. O diagnóstico orienta aprovação da mesma
operação e não recomenda desabilitar proteções globalmente.

## Uso em ambiente filtrado

```sh
"$HOME/.orkest/bin/orkest" list-tabs --json
# Use IDs retornados na chamada acima, nunca IDs de outro boot:
"$HOME/.orkest/bin/orkest" new-tab --title Frontend --parent-tab ID_DO_ORQUESTRADOR
```

Se a ferramenta bloquear o socket, é necessário pedir autorização para essa
execução. O aplicativo não pode conceder a si próprio acesso fora do sandbox
de outro programa. A correção melhora descoberta e orientação; não elimina
essa fronteira de permissões.

## Validação e entrega

78 testes do CLI (37 unitários e 41 de protocolo). A descoberta sem variáveis
também foi exercitada contra o aplicativo instalado, além dos testes isolados.
As skills Orkest locais de Claude e Codex foram atualizadas (2 arquivos por
destino; nenhuma skill Cockpit foi removida). Sessões que já leram a skill
antiga devem relê-la. O novo DMG embarca as mesmas instruções para novas
instalações e próximos boots.
