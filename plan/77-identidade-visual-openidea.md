# Identidade visual do workbench — referência Open IDE

Commit de implementação: `16396170`, na branch `fix/harness-state-detection`, sem push ou PR.

## Direção aplicada

Referência local: OpenIDEA `8021a8cccaad4002704d0b0c6df9d1ab17d854b0`, especialmente `src/styles/tokens.css`, `src/ui/Tabs.module.css` e a seleção de cores de `src/workbench/theme.ts`. A referência utiliza o estilo Islands. O código Flutter é independente; não foram importados assets, fontes ou componentes da outra IDE.

- Paleta padrão Orkest com neutros próximos ao Islands, azul `#3871E1`, texto secundário mais legível e superfícies com separação discreta. O tema claro conserva a hierarquia de superfícies do Orkest.
- Campo escuro de código/terminal em `#1F2124`: próximo à referência, mas suficientemente escuro para manter contraste mínimo de 3:1 da paleta ANSI existente. O teste de contraste valida essa condição.
- `IdeTabSurface` compartilhada por abas de documentos e ferramentas: cabeçalho de 40px, aba de 28px, raio de 6px, hover discreto, seleção tingida pelo accent e borda sutil. A aba selecionada em pane sem foco fica neutra. A faixa inferior azul e as divisórias verticais entre abas de documentos foram substituídas pelo contorno da aba.
- Ícones Lucide nas ferramentas e na navegação Git: arquivos, busca, branch, debug, problemas, estrutura, database, telemetria, galeria, alterações, commits e PRs. Ícones de tipo de arquivo, marcas de banco e logos dos harnesses continuam próprios de cada conteúdo.
- Nome da ferramenta ativa visível no painel principal; contagens Git usam a cor de destaque e Problems conserva a indicação de aviso. Personalizações explícitas de cores continuam sendo carregadas pelo codec existente.
- Painel recolhido usa a mesma superfície visual. Selecionar uma ferramenta expande o painel antes de publicar a seleção, evitando o ciclo expandir/recolher quando o componente pai também expande ao selecionar.

## Limites da mudança

O workspace esquerdo conserva sua estrutura. Abas mantêm fechamento, confirmação de buffer sujo, títulos de preview, reordenação, drag e identidade das sessões. Não há mudança de protocolo, banco, dependências ou configuração persistida. Temas personalizados continuam usando seus tokens; o novo desenho das abas usa o accent do tema ativo.

## Validação

Análise final `dart analyze --fatal-infos lib test` sem issues e `git diff --check` limpo. Foram aprovados 43 testes direcionados de temas, importação, contraste ANSI, navegação, fechamento com buffer sujo, persistência, logos de harness, painel Git e montagem/expansão do host. A execução seleciona explicitamente os testes fora dos dois grupos com falhas anteriores descritos abaixo; não é a suíte completa do aplicativo.

Capturas claras/escuras inspecionadas e hot reload nativo executado com sucesso. O target da prévia usa dados de demonstração e componentes reais; não representa uma nova homologação de Git/Debug ou uma sessão do usuário. O build normal macOS de debug foi restaurado com lib/main.dart após a prévia: cockpit/build/macos/Build/Products/Debug/Orkest Code.app. O app instalado não foi substituído.

- [Prévia escura](evidence/77-identity-dark.png)
- [Prévia clara](evidence/77-identity-light.png)

O teste de logos passou após limpar o ciclo de vida das sessões simuladas e aguardar a notificação de término do stream vazio do fixture. Não houve alteração no motor de harness ou em TerminalSession.

Há duas falhas anteriores na suíte completa `theme_codec_test.dart`, reproduzidas também com `AppColors` do HEAD anterior: ausência de `docs/theme.schema.json` e divergência entre o teste que exige a maior razão de contraste e a política existente de `onColor` (limiar 0.24). Os 28 testes direcionados de paleta, herança e contraste de superfícies/ANSI passam. Os dois problemas anteriores não foram ocultados com skips nem alterados fora deste escopo.

Build e testes Flutter devem ser serializados neste checkout: a execução concorrente encontrou disputa na geração/assinatura dos mesmos native assets. A validação final é executada novamente sem essa concorrência.


## Fechamento de QV01 — 06/11/2026

As duas falhas anteriores descritas acima foram resolvidas. O schema e o exemplo de tema voltaram a integrar docs/, com todos os tokens atuais e apple-hig no enum de extends. A escolha de texto sobre cores comuns agora compara as razões de contraste reais, inclusive com candidatos personalizados; a exceção documentada para ações destrutivas só é aplicada ao destructiveForeground do tema.

A suíte completa theme_codec_test.dart passou com 36 testes, sem filtros ou skips. A combinação com abas, fechamento, logos, host, Git e persistência passou com 51 testes. Os números desta seção substituem a limitação anterior de QV01; não declaram homologação de todas as jornadas da IDE.

## Incremento funcional além do tema

O painel de Run/Debug passou a descobrir configurações nas raízes explicitamente adicionadas ao workspace, com cwd e workspaceFolder resolvidos por pasta e IDs diferenciados pelo arquivo de origem. O seletor identifica a pasta quando há múltiplas raízes. Arquivos fora dessas raízes não geram execuções contextuais. A alteração não implementa variáveis workspaceFolder:nome nem descoberta recursiva de launch.json em pastas não adicionadas.

Oito testes de serviços/painel passaram. O Kanban mantém E1–E6 em andamento e E7 em revisão: área inferior de ferramentas, composição/semântica Git, configurações avançadas e homologação de Debug, diagramas/drivers NoSQL, serviços/Search Everywhere e provedores Git self-hosted continuam pendentes. Não foi identificado relato específico da área de negócios nos registros consultados nesta etapa; isso não equivale a uma validação formal por essa área.


Commits locais desta etapa: 77d94673 (contraste/schema) e 3330328d (Run/Debug multifolder), na mesma branch fix/harness-state-detection, sem push ou PR. Análise final dart analyze --fatal-infos lib test sem issues e git diff --check limpo. Prévia macOS clara/escura novamente inspecionada; hot reload concluído. As imagens de referência já versionadas continuam representando a direção visual adotada; a prévia usa fixtures, não uma sessão real do usuário.

Build normal macOS de debug restaurado com sucesso por flutter build macos --debug --no-pub -t lib/main.dart, após encerrar a prévia. Artefato: cockpit/build/macos/Build/Products/Debug/Orkest Code.app. Persistem avisos de plugins nativos anteriores; não houve instalação sobre o aplicativo existente.
