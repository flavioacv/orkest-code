# Revisão de PRs por repositório do workspace

## Problema e entrega

A revisão de PRs da tela principal recebia treeRootPath, mesmo quando o workspace tinha múltiplas raízes Git. O usuário não podia escolher o repositório da revisão e a abertura de diff reutilizava a primeira pasta como destino implícito.

WorkspacePullRequestPanel recebe as raízes explícitas que possuem GitInfo e oferece um seletor de repositório com nome da pasta, contexto do caminho e tooltip completo. Pastas sem Git não são candidatas. A seleção permanece enquanto o host está montado, inclusive ao mudar de ferramenta, e é preservada ao reordenar raízes. Não há novo estado persistido entre reinícios.

Cada raiz selecionada identifica uma instância de GitPrReviewPanel: lista, seleção e formulário não são reaproveitados para outro repositório. Fetch da ref de revisão usa a raiz capturada; só abre o diff se o painel continuar montado e a geração/raiz forem as mesmas. A troca A→B→A também invalida o fetch antigo de A. A tela principal ainda verifica workspace ativo e pertencimento da raiz antes de abrir o diff. Se uma raiz for removida, seleciona a primeira disponível; se não houver nenhuma, exibe estado vazio sem fazer consulta.

Durante checkout ou envio de comentário, o seletor de repositórios e a seleção de outro PR ficam bloqueados. O campo do comentário também bloqueia edição durante o envio, evitando perder texto adicional na conclusão. Falhas, inclusive exceções inesperadas dos serviços, são apresentadas e liberam o contexto. A remoção externa de uma raiz não cancela fisicamente operações já iniciadas: elas continuam apontando ao repositório de origem; resultados da view descartada não alteram a nova view.

## Validação

Quatorze testes combinados de workspace/revisão responsiva/atalhos/integração aprovados. Revalidação dos cinco casos do workspace e do envio de comentário após o ajuste final. Cobertura inclui troca e reordenação de repositórios, propagação da raiz até fetch/diff, remoção durante navegação, lista vazia, deduplicação das opções, painel de 320 px, sequência A→B→A, bloqueio/liberação em checkout e exceção de comentário.

Os serviços dos testes são controlados: não houve publicação de comentários, checkout ou criação de PR no repositório do usuário. O serviço de produção permanece GitPullRequestService.

## Limites

Este incremento encerra P02, sem declarar E2/E6/E7 concluídas. A auditoria de Working Tree/Index/HEAD multifolder, a separação restante da composição Git do explorador, provedores corporativos e homologação com GitHub autenticado continuam pendentes. A descoberta usa as raízes Git já conhecidas pelo workspace; não há busca recursiva ou interpretação de uma pasta sem Git como repositório.

Commit local de implementação: 026114b8, na mesma branch fix/harness-state-detection, sem push ou PR. Análise estrita final sem issues e git diff --check limpo.


## Evidência nativa

Prévia isolada macOS compilada e inspecionada com o componente real, repositórios de demonstração e serviço controlado. Hot reload concluído; prévia encerrada normalmente. Sem novos erros de layout no output dessa execução; persistem os avisos nativos anteriores de plugins. Não foram restaurados terminais do usuário nem feitas operações autenticadas no GitHub.

[Captura do seletor de repositórios](evidence/79-pr-repositories.png).

Build normal macOS debug restaurado com sucesso após encerrar a prévia: flutter build macos --debug --no-pub -t lib/main.dart. Artefato cockpit/build/macos/Build/Products/Debug/Orkest Code.app. O aplicativo instalado não foi substituído.
