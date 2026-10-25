# Orkest Code — levantamento e especificação da identidade independente

Data: 24/10/2026. Status: levantamento concluído; migração ainda não aplicada.
Base inspecionada: checkout local de `remote_pi`, aplicativo `cockpit/`, CLI,
pacotes internos, plataformas nativas, workflows, site e integração do Office.

## 1. Objetivo e decisões

Publicar **Orkest Code** como aplicativo independente, mantendo o motor de
terminais e a interação genérica com diferentes harnesses. Instalar, executar,
atualizar e remover o produto sem afetar instalações do Cockpit.

Identidade acordada:

| Item | Valor proposto | Situação |
|---|---|---|
| Nome público | Orkest Code | Escolhido pelo usuário |
| Tagline | Orchestrate AI. Build Better. | Escolhida pelo usuário |
| CLI | `orkest` | Proposta técnica |
| Pacote Dart principal | `orkest_code` | Proposta técnica |
| Diretório próprio no HOME | `~/.orkest` | Proposta técnica |
| Variáveis de ambiente | `ORKEST_*` | Proposta técnica |
| Identificador nativo | Exemplo: `com.flavioacv.orkestcode` | Confirmar titular e namespace antes de publicar |
| Nome no escritório | Recepção sem marca; “Orkest Code” se houver placa | Direção proposta |
| Versão inaugural | Exemplo: `0.1.0+1` para prévia ou `1.0.0+1` para lançamento | Escolher conforme maturidade |

O identificador de exemplo não pressupõe domínio registrado. Não foram
verificadas disponibilidade de marca, domínio, identificador nas lojas ou CLI.
“Orchestra” não deve surgir como segunda grafia acidental: usar Orkest Code
de forma consistente nos metadados e traduções.

## 2. Achados que afetam a independência

1. **Há duas fontes de atualização originais.** `UpdateCheckerImpl` consulta
   `https://rp-s3.jacobmoura.work/downloads/cockpit/latest.json`; o módulo
   injeta appcasts do mesmo domínio no Sparkle/WinSparkle. Trocar só o nome ou
   só a URL de `latest.json` deixa o atualizador nativo ligado à outra origem.
2. **O bundle ID não isola todos os recursos.** CLI, socket, logs, marcador
   de armazenamento, servidor e outros recursos usam `~/.cockpit` diretamente.
3. **A identidade do editor original aparece no empacotamento.** macOS,
   Windows, Linux, Android e iOS têm identificadores e/ou publisher antigos.
4. **O Office não é reconstruível a partir deste repositório sozinho.**
   Imports TypeScript e o esbuild apontam para `../../../../habblaud/`.
   O bundle JavaScript pronto está embarcado, mas sua reconstrução depende da
   pasta vizinha e dos `node_modules` dela.
5. **A marca do mapa vem de mais de um lugar.** `main.ts` carrega imagem de
   placa e símbolo do manifesto embarcado; o overlay original também escreve
   “Habblaud” na recepção. Alterar só uma imagem não cobre toda a marca.
6. **Há forks de bibliotecas hospedados no GitHub do mantenedor original.**
   `libghostty` e `flutter_inappwebview_windows` estão pinados no pubspec.
   Renomear o aplicativo não remove essa dependência de fornecimento.
7. **O Git já aponta para seu fork.** `origin` é
   `https://github.com/flavioacv/remote_pi.git`. Isso não altera os links
   hardcoded, atualizadores, workflows ou serviços de distribuição.
8. **As licenças locais identificam as bases.** O LICENSE da raiz contém MIT,
   copyright 2026 Jacob Moura; as cópias do Office contêm MIT, copyright 2026
   Márcio Junior. O próprio texto exige incluir o aviso de copyright e de
   permissão em cópias ou partes substanciais. A marca visível pode mudar;
   esses avisos não devem ser apagados para aparentar autoria integral.

## 3. Inventário por área

Os caminhos abaixo são relativos à raiz deste repositório.

| Área | Evidência principal | Trabalho necessário |
|---|---|---|
| Aplicativo Flutter | `cockpit/pubspec.yaml`, imports `package:cockpit/` | Renomear pacote e imports, descrição, versão, assets e referências em testes; atualizar lockfiles com ferramentas |
| macOS | `cockpit/macos/Runner/Configs/AppInfo.xcconfig` | Produto, bundle ID, publisher do produto e variante `.debug` próprios |
| Metadados macOS | `cockpit/macos/Runner/Info.plist`, projeto Xcode | Display name, UTIs/documentos, referências a `.app`, assinatura, notificações e recursos do atualizador |
| Android | `cockpit/android/app/build.gradle.kts`, `AndroidManifest.xml`, `kotlin/work/jacobmoura/cockpit/MainActivity.kt` | `applicationId`, namespace, package Kotlin, label, variantes debug e ícones |
| iOS | `cockpit/ios/Runner.xcodeproj/project.pbxproj`, `Runner/Info.plist` | IDs do app/testes/debug, display name, mensagens de permissão, assinatura e ícones |
| Windows | `cockpit/windows/runner/Runner.rc`, `windows/CMakeLists.txt`, `runner/main.cpp` | Executável, título, fabricante, nome do produto, ícone, metadados e chave pública do WinSparkle |
| Instalador Windows | `cockpit/windows/packaging/exe/make_config.yaml`, `inno_template.iss` | AppId, publisher, URLs, pasta, atalhos, ProgIDs e desinstalação próprios |
| Linux | `cockpit/linux/CMakeLists.txt`, `cockpit.desktop`, arquivos `work.jacobmoura.cockpit.*` | Binário, application ID, desktop entry, ícone, MIME/AppStream, WMClass |
| Pacotes Linux | `cockpit/linux/packaging/{deb,rpm}/make_config.yaml` | Nome dos pacotes, mantenedor, email, URLs, dependências e metadados |
| Web | `cockpit/web/index.html`, `manifest.json`, ícones | Nome, título, descrição, favicon, PWA e cores; suporte funcional web continua uma decisão separada |
| Marca interna | `cockpit/assets/branding/cockpit_logo.png`, UI, `lib/i18n/` | Logo, menus, Sobre, onboarding, mensagens, links e exemplos PT/EN/ES |
| Atualizações | `cockpit/lib/app/cockpit/data/update/`, `cockpit_module.dart`, `domain/value_objects/update_target.dart` | Desligar feeds originais e conectar somente infraestrutura própria |
| CLI e skills | `cockpit/cli/{Cargo.toml,src,text,skills}`, `tool/`, scripts nativos | Binários, ajuda, comando `orkest`, skills com namespace próprio, instalação e paths |
| IPC e terminais | `data/hooks/terminal_status_server_impl.dart`, `cli/src/{transport,util}.rs` | Sockets/portas anunciadas, tokens, variáveis e descoberta isolados |
| Hooks de harness | `data/hooks/`, `packages/cockpit_server/lib/src/host_hook_installer.dart` | Instalar apenas entradas próprias, preservar entradas do Cockpit e de terceiros |
| Armazenamento | `core/data/setup/{remote_pi_resolver,storage_location}.dart`, repositórios, secure storage | HOME, application support, bancos, cache, logs, segredos e arquivos relocáveis separados |
| Configuração do workspace | `.cockpit`, `.env.cockpit`, caminhos em `data/{db,filesystem,telemetry,remote}` | Nova pasta `.orkest`, env próprio, precedência de importação e worktrees existentes |
| Servidor remoto | `packages/cockpit_server/`, `data/remote/host_shell/`, `cockpit/install-server.sh` | Executável, caminhos locais/remotos, serviço systemd, bundle, locks, staging, download e desinstalação |
| Biblioteca/protocolo | `cockpit/packages/cockpit_{core,engine,protocol,remote,server,keepawake}`, plugin PTY | Planejar renomeação atômica de pacotes e build nativo; compatibilidade do protocolo não depende do nome |
| Publicação | `.github/workflows/cockpit-release.yml`, `cockpit-server-release.yml`, `scripts/build-cockpit.sh` | Tags, artefatos, destinos, chaves próprias, runners e nomes dos bundles |
| Site e suporte | `site/src/`, `core/data/diagnostics/issue_report.dart`, schemas de tema | Downloads, issues, documentação, política de privacidade, termos e URLs próprios |
| Office | `cockpit/tool/habblaud_world/`, `assets/habblaud_{world,art}/`, widgets Office | Placas, logos, textos, nomes de bridge/assets e build independente |

Não alterar bibliotecas de terceiros só para remover o nome dos autores.
`flterm`, ícones de arquivos, media-kit e demais componentes conservam sua
proveniência e seus avisos. Nomes de bibliotecas/protocolos não são marca do
produto para o usuário.

## 4. Atualizações, distribuição e infraestrutura própria — prioridade P0

- [ ] Criar uma configuração central da identidade com nome, slug, IDs,
      caminhos, CLI, links, namespace e configuração de updates. Separar a
      definição de build nativo dos valores de runtime, mantendo-os coerentes.
- [ ] No primeiro build independente, desabilitar **checagem de manifestos e
      inicialização do atualizador nativo** enquanto não houver feeds próprios.
      Não usar a origem antiga como fallback em caso de falha.
- [ ] Definir domínio/repositório oficial e URLs de manifesto, appcast, notas,
      artefatos, checksums e instalador do servidor. Sem URLs fictícias ativas.
- [ ] Gerar chave de atualização própria; substituir a chave pública no
      `SUPublicEDKey` do macOS e `EdDSAPub` do Windows. Guardar a privada fora
      do Git e configurar secrets na infraestrutura do titular.
- [ ] Configurar assinatura/notarização Apple, assinatura Windows e assinatura
      Android com contas e certificados próprios. Não reutilizar identidades
      ou credenciais de publicação do projeto original.
- [ ] Reescrever os workflows antes de habilitar publicação no fork: há upload
      para `rp-s3.jacobmoura.work`, SignPath e nomes de release antigos.
- [ ] Definir tags próprias, por exemplo `orkest-v*` e `orkest-server-v*`, e
      uma política de versão app/CLI/servidor/protocolo.
- [ ] Garantir que atualização e desinstalação reconheçam apenas Orkest Code.
      Uma versão `1.0.0` própria não deve competir com o `2.1.18+116` da base.

Recursos de terceiros funcionais (APIs escolhidas pelo usuário, GitHub, LSP,
downloads de runtimes etc.) não devem ser removidos indiscriminadamente. Fazer
um inventário de acessos de rede e classificar dependência técnica, serviço
original e configuração do usuário. A busca estática não comprova quais hosts
foram acessados em execução; validar isso também no build final.

## 5. Coexistência e migração de dados — prioridade P0

Contrato de isolamento proposto:

| Recurso | Cockpit atual | Orkest proposto |
|---|---|---|
| CLI | `cockpit` | `orkest` |
| Raiz do usuário | `~/.cockpit` | `~/.orkest` |
| Socket local | `status[-debug].sock` na raiz antiga | Mesmo padrão na raiz nova |
| Descoberta Windows | `status[-debug].json` na raiz antiga | Arquivo separado na raiz nova |
| Env do terminal | `COCKPIT_TAB_ID`, `COCKPIT_STATUS_*` etc. | `ORKEST_TAB_ID`, `ORKEST_STATUS_*` e equivalentes |
| Arquivos por projeto | `.cockpit`, `.env.cockpit` | `.orkest`, `.env.orkest` |
| Serviço remoto | `cockpit-server` | `orkest-server` |

- [ ] Separar também Keychain/secure-storage, credenciais de bancos e SSH,
      notificações Windows AppUserModelID, logs, scrollback, telemetria local,
      caches, histórico de updates e marcador `storage_root`.
- [ ] Preservar separação Debug/Release além da separação entre produtos.
- [ ] Servidor remoto não deve ocupar socket, diretório, lock ou unit systemd
      do Cockpit. Instalar/desinstalar um não pode encerrar o outro.
- [ ] Importação das configurações antigas deve ser explícita, uma única vez,
      com cópia e backup. Nunca renomear/apagar os dados originais por padrão.
- [ ] Configurações de projeto antigas podem ter importação compatível;
      novos arquivos devem ser gravados na pasta própria. Definir precedência
      e evitar mesclar silenciosamente segredos de duas instalações.
- [ ] Não mover diretórios de worktrees com sessões abertas. Importar os
      caminhos existentes ou oferecer migração posterior controlada.
- [ ] Importar aparência/preferências é diferente de restaurar uma sessão
      viva: nova PTY não deve herdar identidade social, vínculo pai-filho,
      permissões pendentes nem carteira de agente encerrado.
- [ ] Não criar alias global `cockpit` que capture chamadas do aplicativo
      original. Qualquer compatibilidade de env precisa ter origem explícita,
      sem descoberta automática do socket do outro produto.
- [ ] Instaladores de hooks atuais reconhecem comandos `cockpit-hook` e
      `<cli> hook`. Adaptar o reconhecimento para não “migrar” ou remover
      entradas do Cockpit ao instalar Orkest. Skills próprias não devem
      sobrescrever `cockpit-cli`, `cockpit-telemetry` e outras skills antigas.

## 6. Office e identidade visual — prioridade P1

Primeira entrega: remover a imagem de marca Habblaud, o símbolo relacionado e
o texto do overlay na recepção; manter uma recepção neutra ou placa discreta
“Orkest Code”. Preservar a geometria, colisões e pontos de interação.

Segunda entrega: direção artística própria, com paleta, pisos, paredes,
mobiliário, sinalização e detalhes dos personagens. Trocar apenas as cores não
transforma automaticamente todos os assets em criação original. Registrar
quais são derivados, substituídos ou criados do zero. Revalidar contraste,
pixel art, tema claro/escuro, escala e áreas de clique.

Também revisar textos, HTML de fallback, bridge `window.cockpitHabblaudWorld`,
nomes de assets e referências Dart/JS. Fazer a mudança de bridge em conjunto,
sem quebrar perfil, edição, sons, atividade, permissões e câmera. Preservar
compatibilidade dos dados versionados que forem importados deliberadamente.

### Entregáveis de marca e ícone

- [ ] Símbolo original, wordmark “Orkest Code” e versões clara/escura.
- [ ] Fonte vetorial editável, paleta e regras de margem e tamanho mínimo.
- [ ] Ícone legível em 16/32 px e variantes 64–1024 px; arquivo `.ico` Windows,
      AppIcon macOS/iOS, recursos Android inclusive adaptativos e ícones PWA.
- [ ] Favicon, ícone de notificação/tray quando aplicável, ícones de documentos,
      imagens do instalador, screenshots e material da página de download.
- [ ] Não usar texto pequeno dentro do ícone nem reaproveitar os símbolos
      originais como se fossem a marca nova.

Direção sugerida: símbolo geométrico de coordenação de três elementos/nós,
com leitura simples no Dock. A imagem do nome escolhida pelo usuário é uma
referência de posicionamento; ainda não é um pacote de ícones de aplicativo.
Nenhum novo logo ou ícone foi criado neste levantamento.

## 7. Build reproduzível e dependências — prioridade P0/P1

- [ ] Incorporar o subconjunto utilizado do motor Office em diretório
      `third_party/office_engine` (ou equivalente), com licença, origem,
      revisão exata e lista de modificações. Não editar a pasta externa.
- [ ] Ter `package.json`/lockfile próprios e versão pinada do esbuild; eliminar
      imports relativos para fora do repositório, inclusive nos testes.
- [ ] Garantir que `assets.ts`, manifesto, imagens e `engine.js` possam ser
      regenerados por comando documentado. Não deixar placas antigas em
      payload base64 ou no bundle depois da alteração dos arquivos visíveis.
- [ ] Para `libghostty` e `flutter_inappwebview_windows`, usar revisão imutável
      e mirror/fork controlado por você ou release upstream equivalente,
      preservando os patches necessários. Não atualizar a biblioteca nativa
      sem reconstruir bindings e invalidar caches correspondentes.
- [ ] Planejar renomeação dos pacotes internos, crate Rust, plugins/channels,
      nomes de dylib/DLL/so, paths CMake/Xcode, FFI e executáveis em uma
      alteração verificável. Nem todo nome interno precisa mudar no primeiro
      build; os nomes compartilhados com instalações antigas, sim.
- [ ] Inventariar o restante do monorepo (`app`, `pi-extension`, `rp-s3`, site,
      relay e ferramentas) e declarar o que faz parte do Orkest. Não renomear
      automaticamente outros produtos só porque estão na mesma raiz.
- [ ] Registrar a revisão da base e manter histórico/proveniência. Alterações
      futuras da base serão integrações manuais revisadas, sem publicação ou
      update automático do produto antigo.

## 8. Licenças, créditos e publicação

Preservar os arquivos MIT encontrados e seus avisos de copyright/permissão.
Adicionar atribuições acessíveis em “Sobre → Licenças e componentes”, além de
`THIRD_PARTY_NOTICES.md` com código, arte, áudio, fontes e dependências.
Identificar separadamente as modificações e titularidade do Orkest Code.

A marca e links comerciais podem ser próprios; não substituir os autores das
bibliotecas em arquivos de licença. Revisar a procedência de cada conjunto de
assets, incluindo fontes e áudio, antes da distribuição. Este levantamento
verificou os avisos locais, não é uma liberação jurídica de marca ou assets.

Antes da publicação: verificar nome/domínio e nome nas lojas; definir titular,
email de suporte, política de privacidade coerente com o comportamento real,
termos, README, SECURITY, CONTRIBUTING, changelog e canais de reporte próprios.
Atualizar o template de issue: hoje aponta para `jacobaraujo7/remote_pi`.

## 9. Sequência de execução e critérios de aceite

| Fase | Resultado | Critério de aceite |
|---|---|---|
| 0 — decisão | Identificadores, titular e escopo de plataformas definidos | Sem placeholders ativos de publicação |
| 1 — isolamento | Update original desligado, identidade/config central, raiz/IPC próprios | Orkest e Cockpit abrem juntos sem compartilhar socket, dados ou update |
| 2 — produto | Nome, IDs, pacote/imports, CLI, hooks e servidores coerentes | Agentes genéricos aparecem no Office e CLI controla somente o produto certo |
| 3 — Office | Build autônomo, recepção neutra, créditos preservados | Compilar de clone limpo sem checkout vizinho; mapa sem marca antiga visível |
| 4 — marca | Logo e pacote completo de ícones | Dock, menus, perfil, instalador e variantes de tema consistentes |
| 5 — release | Pipelines, assinatura e canal próprio | Instalar, atualizar e desinstalar sem atingir o outro aplicativo |
| 6 — redesenho | Cenário e linguagem visual próprios | Colisões, câmera, sons e interações preservados após novo desenho |

Validações obrigatórias na execução:

- Build limpo macOS; build/teste das demais plataformas efetivamente publicadas.
- Análise Dart, testes Flutter, testes do CLI e simulação Office; código nativo
  e FFI compilados após qualquer renomeação de binário/símbolo/channel.
- Teste lado a lado com Cockpit: `list-tabs`, leitura, envio de teclas, abertura
  de agentes, delegação, hooks, permissões e notificações sem cruzamento.
- Fluxo Office: trabalho/espera/ociosidade, conclusão, socialização, perfil,
  aparência individual, idiomas, câmera e fechamento de sessão.
- Inserção por voz/OpenLess e acessibilidade após troca de bundle ID/assinatura;
  permissões do macOS devem ser verificadas na nova identidade.
- Migração por cópia com rollback, instalação limpa e desinstalação que conserva
  o produto antigo e os projetos do usuário.
- Update de versão própria A → B, offline, assinatura inválida e feed sem
  versão; nenhuma consulta ao canal original ou tentativa de instalá-lo.
- Busca residual por marca/domínios: ocorrências permitidas somente em
  licenças, créditos, histórico ou compatibilidade explicitamente documentada.

## 10. Limites e próximos dados necessários

Este trabalho fez inspeção estática e escreveu este plano. Não mudou nomes,
IDs, keys, hooks, feeds, arquivos de usuário, remotes ou credenciais; não
publicou artefatos e não interrompeu o aplicativo. Não executou builds porque
nenhum código executável foi alterado nesta etapa.

Para começar a migração: confirmar namespace/titular e plataforma inaugural.
Para publicar depois: domínio/URLs, repositório definitivo, email e contas de
assinatura. É possível desenvolver a identidade independente com updates
desabilitados enquanto a infraestrutura própria é preparada.
