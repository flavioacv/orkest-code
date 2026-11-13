# Git no Orkest Code: comparação com o VS Code e proposta de evolução

Data: 13/11/2026. Escopo: análise estática dos fontes locais de `vscode` e `remote_pi/cockpit`. Não constitui homologação da interface nem implementação. As prioridades abaixo são propostas, não decisões de produto já aprovadas.

## Conclusão

O Orkest já dispõe da maior parte das operações necessárias. A evolução deve conectar os comandos, o estado do repositório e a resolução de conflitos em uma jornada consistente, reutilizando os contratos existentes. Copiar a interface TypeScript do VS Code para Flutter não é necessário.

O principal ganho do VS Code está na orquestração: seleção contextual de referências, tratamento de alterações locais, políticas de atualização, leitura do estado depois de operações e apresentação das próximas ações. No Orkest, parte dessas capacidades existe separadamente, e alguns caminhos de menu executam comandos diretamente.

## Evidências no VS Code

Referências relativas a `/Volumes/Externo/projetos/zurc/vscode`:

| Capacidade | Implementação observada |
| --- | --- |
| Checkout remoto inteligente | `extensions/git/src/commands.ts`, `CheckoutRemoteHeadItem.run`: procura branches locais que rastreiam a referência; usa a primeira correspondência encontrada quando existe alguma e faz checkout com tracking quando nenhuma existe. |
| Seletor de referências | `commands.ts`, `_checkout` e `createCheckoutItems`: seleção de branches/tags, criar branch, criar a partir de outra referência e checkout detached. |
| Alterações locais impedindo checkout | `_checkout`: oferece stash e checkout, migração de mudanças e checkout forçado. A opção destrutiva não é recomendada para a primeira etapa do Orkest. |
| Pull contextual | `repository.ts:2442–2500`: resolve upstream, diferencia pull e pull com rebase, consulta configurações de fetch/tags/autostash e trata conflito de tags. |
| Atualização antes do checkout | `repository.ts:2301`: `pullBeforeCheckout` pode tentar fast-forward da branch de destino. Não equivale a fazer merge arbitrário entre branches. |
| Ciclo de operações | `repository.ts:2858`, `run`: registra início/fim, atualiza o modelo após sucesso e também após erro em operações de escrita, emitindo eventos de conclusão. Isso não implica exclusão mútua universal entre todos os comandos. |
| Merge editor | `commands.ts:843`, `openMergeEditor`: monta Base, Current, Incoming e Result, com metadados de commits e tratamento específico de rebase e renomeações. O editor está em `src/vs/workbench/contrib/mergeEditor/`. |
| Autostash configurável | `repository.ts:3318` contém fallback para versões antigas do Git; `git.ts:2522` compõe opções do pull, incluindo `--autostash`. Não é uma automação incondicional. |

As configurações correspondentes estão em `extensions/git/package.json`: `git.pullBeforeCheckout`, `git.fetchOnPull`, `git.pullTags`, `git.autoStash`, `git.rebaseWhenSync` e `git.mergeEditor`.

## Estado atual do Orkest

Referências relativas a `cockpit/`:

| Área | Já implementado | Lacuna observada |
| --- | --- | --- |
| Source Control | `source_control_panel.dart`: alterações, histórico, PRs e compositor; integração em `file_tree_panel.dart`. | Cabeçalho identifica repositório/branch, mas não oferece um gerenciador completo de branches. |
| Entradas Git | Rail de projetos, menus do projeto, Source Control e infraestrutura de dock Git. | Os pontos de entrada precisam compartilhar os mesmos comandos, pré-condições e resultados. A posição visual efetiva depende do layout ativo. |
| Branches | `git_controller.dart:286`, `git_branch_picker.dart`: busca, branch atual, locais/remotas e bloqueio de branches em uso por worktree. | Entidade contém apenas nome e flags; faltam upstream, divergência, atividade recente e caminho do worktree. |
| Checkout remoto | `git_controller.dart:341`. | Sempre executa `switch --track -c <nome> <remota>`. Se a branch local já existir, pode falhar, apesar do comentário indicar criação apenas quando necessária. |
| Criação | `git_controller.dart:360`: cria e seleciona a partir de HEAD. | Falta escolher referência de origem; validação antecipada do nome é parcial, embora o Git ainda rejeite nomes inválidos. |
| Pull/Sync | `git_controller.dart:246`, `git_command_runner_impl.dart`: pull; sync faz pull seguido de push apenas quando pull retorna zero. | Ausência de opções estruturadas de estratégia/upstream e resultado semântico; o dialog apresenta sucesso/falha e logs. |
| Atualização após comando | `workspace_actions.dart:196`, `_gitOpDialog`: relê Git após o fechamento do dialog; existem watchers e polling no controller. | O encerramento da operação precisa atualizar o estado diretamente, independentemente do fechamento do dialog. Watchers não substituem esse contrato. |
| Operações avançadas | `file_tree_panel.dart:1049`: merge, rebase, rename, delete e publish. | Referências digitadas manualmente; rebase vai por comando genérico e não pelo serviço que contém pré-condições. Publish fixa `origin`. |
| Resolução visual | `merge_conflict_editor.dart`: revisão por bloco, navegação, edição do resultado e revisão do documento; `GitConflictService` contém leitura de estágios do índice. | Ampliar a integração com estado do repositório e conflitos sem marcadores, preservando o editor já existente. |

## Problemas prioritários

1. **Estado de operações em worktrees e remoto.** `GitConflictService.detectOngoingOperation` (`git_conflict_service.dart:317`) exige `.git` como diretório e consulta arquivos locais diretamente. Worktrees vinculados normalmente usam `.git` como arquivo. O método também captura exceções e retorna ausência de operação, ocultando erros de leitura. Continuar/abortar usam esse detector e execução local. Proposta: resolver diretório Git com `git rev-parse --absolute-git-dir` ou caminhos com `git rev-parse --git-path`, através do executor apropriado ao destino. Distinguir ausência de operação de falha na consulta. A integração atual com destinos remotos precisa ser validada por fluxo, sem presumir paridade porque existe um serviço remoto de status.

2. **Continuação depende de marcadores.** Em `file_viewer.dart:1334`, o banner que contém continuar/abortar só é construído quando `_conflictBlocks.isNotEmpty`. Ao resolver o último bloco, esse ponto de acesso pode desaparecer embora merge/rebase ainda esteja pendente. Proposta: faixa persistente no Source Control baseada na operação do repositório, com contagem de arquivos não resolvidos e ações adequadas. Resolver um texto, salvar e executar stage são etapas distintas; continuar só deve ser oferecido como pronto quando as pré-condições forem satisfeitas.

3. **Pré-condições inconsistentes.** O caminho genérico de rebase do menu não chama `GitWorkService.rebase`, que verifica working tree e protege branches. Proposta: todas as entradas visuais encaminharem a mesma operação tipada. Aplicar a política vigente também aos comandos de merge e publicação; branch padrão não deve ser inferida exclusivamente como `main/master`.

4. **Checkout remoto com branch local existente.** Consultar upstream real, não apenas coincidência de nomes. Se houver correspondência única, trocar para a local; se não houver, propor criação com tracking; se houver ambiguidade ou colisão de nomes, pedir escolha contextual. Manter bloqueio para branches ocupadas por outro worktree e oferecer navegação até ele.

5. **Merge de worktree abortado automaticamente.** `GitCommandRunnerImpl.mergeIntoParent` aborta quando o merge retorna erro e anuncia que o pai permaneceu intacto, sem verificar o resultado do abort. Nem todo erro é conflito. Proposta: classificar o estado efetivo, verificar o abort e preservar a origem. Um fluxo opcional de resolução interativa deve ser uma escolha explícita e não substituir silenciosamente a proteção atual; remover worktree apenas após sucesso confirmado.

## Experiência proposta

### Branches

- Um seletor compartilhado pelo cabeçalho do Source Control, indicador de branch e menu do projeto, sempre mostrando repositório e destino local/remoto.
- Busca com grupos Atual, Locais e Remotas; atividade recente, upstream e ahead/behind quando disponíveis. Indicar refs desatualizadas até fetch.
- “Criar branch” a partir de HEAD e “Criar a partir de…” com referência selecionável.
- Ações contextuais para comparar, merge na atual, rebase sobre a selecionada, renomear, excluir e publicar; destino explícito nas operações que alteram histórico ou repositório.
- Validar nomes via Git, tratar refs como argumentos e impedir que entradas sejam interpretadas como opções. Não compor comandos shell.
- Quando alterações locais bloquearem checkout: manter estado, oferecer stash e trocar ou cancelar. Migração com reaplicação pode vir depois, com tratamento de conflito e identificação do stash criado.

### Pull, merge e sync

`git pull` integra uma referência remota na branch atual. Para branches locais, usar “Mesclar branch…” ou “Rebase sobre…”. Para outra branch remota, oferecer “Pull de…” com origem e destino visíveis.

Fluxo proposto:

1. Capturar repositório, branch atual, upstream e operação pendente; impedir comandos de escrita incompatíveis no mesmo repositório.
2. Mostrar ação específica para upstream ausente e escolha de estratégia quando necessária: respeitar configuração existente ou oferecer fast-forward-only, merge e rebase explicitamente. A política padrão do produto precisa ser definida antes da implementação.
3. Executar pelo contrato Git existente, mantendo logs acessíveis e estado de progresso compartilhado.
4. Ao terminar, reler status e operação, inclusive em caso de exit code não zero.
5. Sem conflito: atualizar branch, divergência, arquivos e histórico. Com conflito: abrir a seção de conflitos e oferecer revisão do primeiro arquivo; não avançar para push.
6. Em sync, mostrar que haverá pull e push, interrompendo a sequência diante de erro ou integração pendente. Nunca repetir uma escrita automaticamente sem conhecer seus efeitos.

Autostash, fetch automático e atualização antes de checkout devem ser preferências explícitas. A reaplicação de stash pode conflitar e precisa de recuperação visível. Não executar instalação de dependências, builds ou scripts adicionais como consequência implícita do pull.

### Conflitos

- Seção persistente “Conflitos” com tipo de operação, arquivos restantes e continuar/abortar.
- Reutilizar o editor atual, alimentando Base/Atual/Entrada pelos estágios 1/2/3 do índice quando disponíveis; ausência de um estágio pode representar adição ou exclusão, não erro genérico.
- Exibir refs e commits concretos; contextualizar os lados em rebase para evitar interpretações incorretas de ours/theirs.
- Tratar explicitamente conflitos binários, exclusão/modificação e renomeações; não exigir marcadores textuais para reconhecer arquivo não resolvido.
- Ação “Salvar e marcar como resolvido” deve verificar se o arquivo mudou desde a revisão e efetuar stage deliberadamente. A conclusão deve consultar arquivos não resolvidos no índice, não só procurar marcadores no editor.
- Continuar/abortar permanecem acessíveis mesmo após fechar o arquivo ou resolver o último marcador.

## Plano de implementação

| Ordem | Entrega | Critério de aceite |
| --- | --- | --- |
| P0 | Estado e resultados de operação comuns; corrigir detecção em worktree; unificar pré-condições; verificar abort. | Mesmo comportamento pelos diferentes menus; erro não vira “sem operação”; abort malsucedido não aparece como sucesso. |
| P1 | Seletor compartilhado, tracking correto, criação a partir de referência e escolha de remoto. | Checkout remoto reutiliza a branch local correta; colisões e múltiplos remotos são resolvidos sem perda de alterações. |
| P2 | Pull/Sync com opções e encaminhamento para conflitos; faixa persistente de operação. | Pull divergente e com conflito tem próxima ação clara; push não ocorre enquanto a integração estiver pendente. |
| P3 | Completar casos de conflito e polir apresentação. | Revisão textual, binária e exclusão/modificação; continuar funciona após resolver todos os arquivos. |

Arquivos centrais: `ui/viewmodels/git_controller.dart`, `domain/entities/git_branch.dart`, `domain/services/git_conflict_service.dart`, `domain/services/git_work_service.dart`, `domain/contracts/git_command_runner.dart`, `data/filesystem/git_command_runner_impl.dart`, `ui/actions/workspace_actions.dart`, `ui/widgets/git_branch_picker.dart`, `source_control_panel.dart`, `file_tree_panel.dart`, `file_viewer.dart` e `git_process_dialog.dart`. Avaliar o executor e serviços remotos antes de ampliar o contrato; não criar uma segunda camada Git paralela.

Antes de editar arquivos existentes, executar a análise de impacto exigida pela base. A consulta ao grafo por `GitController` nesta análise não encontrou entidades; a navegação foi feita diretamente nos fontes.

## Validação necessária na implementação

- Testes com repositórios temporários reais e remoto bare: pull fast-forward, divergência, upstream ausente, merge com conflito, rebase e reaplicação de stash com conflito.
- Checkout remoto com local rastreada de nome diferente, colisão de nomes, dois remotos e branch ocupada por worktree.
- Worktree com `.git` em arquivo, continuidade após reiniciar a interface e falha de abort.
- Testes de widget para consistência dos pontos de entrada, execução em andamento e banner persistente depois do último conflito.
- Validar erro de autenticação/rede e execução no destino remoto sem processos locais indevidos.
- Exercitar a interface desktop completa com arquivos abertos e alterações não salvas; verificar reconciliação do editor após checkout/pull.

Foram localizados os arquivos de testes Git existentes, sem auditoria de sua cobertura; nenhuma suíte, build ou teste visual foi executado nesta análise. Nenhum código de aplicação foi alterado, e não foram feitos checkout, commit, push ou merge.

## Incremento implementado em 13/11/2026

Aplicado em `fix/harness-state-detection`, avançada por fast-forward até o estado inicial de `main` antes das alterações, sem modificar `main`.

Entregas deste incremento:

- Seletor de branches com identificação do repositório, upstream e estado de tracking; criação a partir de HEAD ou de uma referência selecionada; validação pelo Git e bloqueio de cliques concorrentes.
- Checkout remoto reutiliza uma branch local que rastreia a referência, mesmo com nome diferente. Múltiplas correspondências retornam erro com os nomes para escolha explícita pela lista local.
- Atalho de branches no Source Control, opções explícitas de pull com rebase/fast-forward-only e preservação do pull padrão configurado pelo usuário.
- Rebase iniciado pelo menu passa pelo serviço existente com pré-condições. Entradas de referência iniciadas por hífen são rejeitadas.
- Estado Git atualizado no término do processo, inclusive em falha, sem depender de fechar o log. Falhas com conflitos oferecem acesso ao Source Control e abertura do primeiro arquivo afetado.
- Editor de conflitos com Atual/Entrada lado a lado, cores semânticas, números de linha e Base opcional; na revisão do resultado completo, as versões completas do índice permanecem visíveis. Mantidos os rascunhos por bloco, navegação e aplicação validada contra o snapshot original.
- Ação de salvar e marcar como resolvido verifica o texto em disco e marcadores antes de stage. Erros novos dessa ação são tipados e traduzidos na interface.
- Painel persistente por repositório com arquivos em conflito e continuar/abortar, mesmo sem arquivo aberto ou após resolver o último marcador. O banner do editor também permanece durante a operação.
- Detecção de operações em worktrees com `.git` em arquivo; continuação verifica arquivos não resolvidos no índice. Abortar exige confirmação na interface.
- Integração de worktree não aborta merge preexistente no pai, não ignora falha de status e verifica a saída do abort antes de comunicar restauração.
- Strings novas em inglês, português e espanhol, com código de tradução regenerado.

Validação: 52 testes aprovados em execução consolidada (`git_integration_workflow_test`, `git_operation_panel_test`, `merge_conflict_editor_test`, `git_branch_picker_test`, `git_conflict_resolution_test`, `git_command_runner_impl_test`, `git_multifolder_source_control_test`, `git_controller_test`). A análise estática com `--fatal-infos` de todos os arquivos alterados passou sem issues; `git diff --check` limpo. A análise ampliada da feature encontrou também dois avisos anteriores em `habblaud_world_webview.dart`, arquivo fora deste incremento e preservado.

Limites: este incremento não adiciona grafo de histórico, autostash automático ou política global nova de pull. Não amplia a resolução de arquivos binários/renomeações nem a execução Git em destinos SSH. O editor continua aplicando primeiro ao buffer; stage é uma ação explícita. A lista persistente permite abrir arquivos em conflito mesmo quando não há marcadores textuais, mas a comparação textual não substitui uma interface específica para conflitos binários.

A primeira tentativa de execução macOS falhou no build Rust da CLI: o build script em cache usava `/Volumes/Externo 1/...`, enquanto o projeto está em `/Volumes/Externo/...`; a asserção de presença de `cli/skills` falhou por esse caminho antigo. Foi removido apenas o cache compilado do pacote `orkest-cli` com `cargo clean -p orkest-cli --release`, sem alterações de código/configuração nativa. A segunda tentativa compilou `build/macos/Build/Products/Debug/Orkest Code.app` e iniciou a aplicação. Conexão DTD estabelecida; hot reload concluído com sucesso e consulta posterior sem erros de runtime. Isso valida build e inicialização; a jornada desktop completa de merge não foi exercitada por automação de interface. A captura isolada do widget usa fontes de teste e serve apenas para inspeção do layout.
