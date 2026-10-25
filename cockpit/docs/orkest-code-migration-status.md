# Orkest Code — implementação da identidade independente

Data: 24/10/2026. Esta é a primeira migração funcional, versão `0.1.0+1`.
O diretório externo do aplicativo continua `cockpit/` para preservar a
organização do monorepo. O nome de produto é **Orkest Code**, CLI **`orkest`**.

## Implementado

- Pacote Dart principal `orkest_code`, namespace `com.flavioacv.orkestcode`,
  variante macOS debug `com.flavioacv.orkestcode.debug` e nomes próprios de
  pacotes internos, plugin PTY, comandos nativos, bibliotecas e recursos.
- Nome e metadados nas plataformas, traduções, nome da janela e ícone de fita azul/violeta
  aprovado, com masters PNG e gerador de tamanhos para macOS/Windows/Linux/iOS/
  Android/web. Paleta inicial: marinho, turquesa e lavanda.
- Diretórios `~/.orkest`, `.orkest/` no workspace, `.env.orkest`, variáveis
  `ORKEST_*`, socket, CLI, hooks e servidor `orkest-server` próprios.
- Skills embarcadas com prefixo `orkest-`; nenhum alias global `cockpit` ou atalho `ck` é instalado automaticamente. A CLI mantém os verbos de abas, delegação, atividade e telemetria.
- Instaladores de hooks reconhecem somente suas entradas. Testes confirmam
  que entradas `_cockpit` continuam presentes ao instalar/reinstalar Orkest.
- PTYs descartam variáveis `COCKPIT_*` herdadas para evitar que hooks antigos
  reportem para o aplicativo pai quando Orkest é iniciado por outro terminal.
- Atualizador padrão sem URL, sem feed nativo, checks automáticos desligados
  e chave pública antiga removida. `AppIdentity.updatesEnabled` permanece
  `false`. Não há fallback para o canal do Cockpit.
- Workflows de publicação antigos arquivados fora da pasta ativa, em
  `.github/workflow-templates/legacy/*.disabled`. CI do CLI adaptado ao binário
  `orkest`. Não foram criados secrets nem publicadas releases.
- Código necessário do Office incorporado em `third_party/office_engine`,
  com licença e revisão registradas. Ferramentas em `tool/office_world`,
  `package.json`/lockfile e esbuild próprio. `npm run office:build` e
  `npm run office:test` não dependem de checkout vizinho do Habblaud.
- Placa/símbolo originais retirados dos assets embarcados usados pela WebView;
  recepção identifica Orkest Code. Cores, mobiliário e arte original restante
  seguem como base atribuída para um redesenho posterior.
- README próprio, notices da base e do Office preservados e embarcados em
  `assets/branding/THIRD_PARTY_NOTICES.txt`. Instruções originais de publicação
  preservadas como documentação histórica em `docs/upstream`, não como
  credenciais/instruções válidas do Orkest.

## Instalação e dados

O aplicativo antigo não foi encerrado, atualizado ou substituído. Seus
diretórios `~/.cockpit` e suas configurações não foram modificados por esta
migração. A cópia independente inicia com dados próprios. Não há importação
automática de segredos, terminais, carteiras ou permissões pendentes.

Para usar a nova identidade, pare o `flutter run` antigo e execute novamente:

```sh
cd cockpit
flutter run -d macos
```

Hot reload não aplica mudança de pacote, bundle ID, plugin nativo ou ícone.
O novo bundle pode coexistir com a instalação original. A mudança de identidade
pode exigir nova autorização de acessibilidade/notificações/rede local no macOS;
o OpenLess precisa ser validado na nova instalação.

## Verificação realizada

- `flutter pub get --offline`: grafo de dependências renomeado resolvido.
- Análise estática: sem erros de código; lint de retorno void no harness de
  testes corrigido na revisão final.
- CLI Rust: 35 testes unitários e 41 de protocolo passaram (76).
- Office: 7 testes da simulação passaram usando o motor incorporado.
- Suíte Flutter ampla: 1.643 passaram, 6 ignorados e 15 falharam na primeira
  execução. As falhas de schemas, expectativas de hooks e mock HTTP global
  foram corrigidas; a rodada focada final passou 59 testes, incluindo os novos
  casos de isolamento. Não se trata de uma segunda execução integral verde.
- Resta um golden `htop_80x25_3s.png` com diferença de **2 pixels** no ambiente
  atual. A imagem não foi atualizada automaticamente para ocultar a diferença.
- Build macOS Debug gerado em
  `build/macos/Build/Products/Debug/Orkest Code.app`. Metadados inspecionados:
  nome Orkest Code, ID `.debug`, versão `0.1.0`, build `1`, update automático
  desativado e ausência da chave pública antiga. CLI e servidor embarcados.
- O aplicativo não foi iniciado automaticamente e a coexistência visual,
  entrada por voz e permissões reais ainda precisam de validação manual.

## Pendências de publicação e etapas posteriores

1. Verificar disponibilidade de marca/domínio e definir o repositório definitivo.
   Links próprios usam o fork já existente `flavioacv/remote_pi`.
2. Criar site, suporte, documentação pública e políticas do Orkest. O diretório
   `site/` do monorepo continua sendo o site histórico e **não deve ser publicado
   como site do Orkest nesta etapa**. Outros produtos do monorepo não foram
   renomeados automaticamente.
3. Configurar certificados, assinaturas/notarização, armazenamento de artefatos,
   feeds e chave de atualização próprios; só então criar workflows de release
   e habilitar o atualizador. O instalador do servidor aponta para seu fork,
   mas precisa de uma release própria para baixar artefatos publicados.
4. Compilar e testar Windows, Linux e mobile em seus ambientes. Metadados e
   recursos foram migrados; isso não equivale a pacotes publicados/validados.
5. Os forks pinados de `libghostty` e `flutter_inappwebview_windows` continuam
   como dependências técnicas, preservando os patches da base. Criar mirrors
   controlados ou migrar para upstream equivalente em alteração específica,
   sem substituir inadvertidamente os símbolos/bindings nativos.
6. Importador opcional por cópia/backup para preferências antigas; não importar
   identidade de agente encerrado nem reutilizar os sockets do outro produto.
7. Refinar o ícone, redesenhar o cenário e disponibilizar uma página de licenças
   no produto. Atribuições já acompanham os assets e os arquivos de origem.

Plano original: [levantamento da migração](orkest-code-migration-plan.md).

## Marca aplicada — fita azul/violeta

O símbolo e o wordmark aprovados foram aplicados aos recursos de ícone de
todas as plataformas, ao favicon e às telas de carregamento/boas-vindas.
O tema claro usa lettering escuro em PNG transparente; o tema escuro usa
lettering branco sobre marinho. O conceito geométrico anterior fica arquivado
como SVG em assets/branding/concepts; ele não é o ícone ativo.
Arte e instruções de reprodução: assets/branding/README.md. Os logos são
masters raster e não incluem uma fonte TTF/OTF ou vetor da fita.
