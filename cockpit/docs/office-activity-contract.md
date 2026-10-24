# Contrato de atividade do Office

O Office recebe eventos pelo socket local do Cockpit, usando o mesmo transporte
que os hooks e a CLI interna. O contrato não depende do formato de sessão de um
harness. Hooks e `cockpit activity` são as fontes estruturadas preferidas. Como
fallback, o Cockpit reconhece um conjunto restrito de marcadores visíveis na TUI
do agente; não lê arquivos de transcript nem envia texto bruto ao Office.

## Reporte

Dentro de uma aba do Cockpit, um processo pode emitir:

```sh
cockpit activity read --summary "Lendo configuração" --phase started
cockpit activity read --summary "Lendo configuração" --phase completed
cockpit activity search --summary "Buscando referências no código"
cockpit activity edit --summary "Atualizando configuração" --phase started
cockpit activity needs_input --summary "Precisa de aprovação para executar o comando"
```

Kinds aceitos: `prompt`, `thinking`, `read`, `search`, `edit`, `write`,
`command`, `wait`, `test`, `web`, `plan`, `delegate`, `needs_input`, `done`,
`error` e `other`. Phases: `started`, `updated`, `completed`, `failed` e
`interrupted` (padrão: `started`). O resumo é obrigatório e limitado a 160
caracteres. IDs e roteamento usam `COCKPIT_TAB_ID`/`COCKPIT_PANE_ID`; fora da
aba, informe `--tab-id`.

`needs_input` é o único kind que coloca a sessão em `waiting` e aciona a
notificação do Office. Use-o somente quando a ação do usuário for necessária.
`respond` registra que o usuário enviou uma resposta pelo PTY e retoma o estado
de trabalho; não representa uma aprovação específica.
O botão **Responder** abre a visualização do PTY existente, que continua sendo a
fonte de verdade para conceder/recusar permissões. O contrato não simula uma
decisão de permissão nem inventa botões de aprovação específicos do harness.

## Observabilidade e limites

- O PTY fornece bytes de saída/entrada. A TUI não é um protocolo estável: a
  heurística só reconhece marcadores comuns de atividade, fim de turno e pedido
  de resposta quando identifica a interface de um agente. Isso melhora a
  animação sem hooks, mas pode não reconhecer versões ou idiomas diferentes e
  não substitui eventos estruturados.
- O monitor de processos do Cockpit identifica processos/harnesses na árvore da
  aba, mas atualmente não acompanha o ciclo de cada comando nem seus códigos de
  saída. Por isso não converte automaticamente `cat`, `rg` ou texto do terminal
  em atividades semânticas.
- Hooks já instalados para determinados harnesses seguem reportando seus eventos
  nativos. Eles são adaptadores opcionais; o Office guarda o resultado no mesmo
  histórico local e mantém o evento neutro disponível para outras fontes.
- Um harness ou agente pode integrar-se chamando a CLI para cada ação que
  conhece. O payload contém apenas kind, phase, resumo limitado e ID da aba; não
  deve incluir prompts, tokens, conteúdo de arquivos ou saída bruta do terminal.
- O histórico é efêmero e limitado a 200 eventos por sessão atual; não é um
  arquivo de sessão persistido.

Este contrato fornece um ponto comum de integração para qualquer harness. Sem
hook, wrapper ou chamada explícita do agente, a heurística visual é apenas uma
aproximação: a resposta continua sendo enviada ao PTY original, e o Cockpit não
consegue inferir com segurança todas as ações internas do modelo.
