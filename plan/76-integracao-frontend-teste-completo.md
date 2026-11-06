# Integração para teste completo — 06/11/2026

Continuidade da revisão [75](75-revisao-entrega-frontend.md), na branch única `fix/harness-state-detection`. Commits locais de implementação: `57366273` (Database) e `cdbf555b` (workbench/Debug/LSP/Git). Sem push, PR ou instalação sobre o app existente. Este documento distingue integração implementada de homologação manual do produto.

## Conexões concluídas

- A tela principal fornece Debug, Problems, Outline e revisão de PRs ao FileTreePanel. São componentes ligados à composição de produção, não apenas builders em testes.
- O OrkestViewModel mantém controllers DAP e Problems isolados por workspace. Recebe diagnósticos do pool LSP, atualiza badges e limpa diagnósticos quando documentos são fechados. Descarta os controllers e a assinatura ao encerrar.
- Todos os FileViewer do PaneView recebem o controller DAP de seu workspace e escutam mudanças. Breakpoints e linha pausada aparecem no gutter. Navegação por diagnóstico, símbolo ou frame abre o arquivo em linha e coluna; respostas antigas de símbolos e frames são rejeitadas.
- WorkspaceDebugPanel carrega `.vscode/launch.json` e `.orkest/run.json` em JSONC, preserva argumentos próprios do adaptador, ambiente e launch/attach. Também oferece configurações contextuais do arquivo, detectando o projeto da linguagem em pastas internas. Run/Test usa o runner PTY existente; Debug usa Dart/Flutter ou adaptadores catalogados disponíveis no host.
- A inicialização DAP envia launch/attach, aguarda initialized, configura breakpoints e conclui configurationDone antes de aguardar o lançamento. Testes Dart/Flutter selecionam o modo `--test` do adaptador. Eventos continued/terminated atualizam o estado; watches são reavaliados ao pausar.
- A abertura de arquivo de PR busca a revisão sintética de merge em uma ref local dedicada e usa o DiffViewer existente para mostrar o PR completo contra sua base, sem checkout automático. A troca de workspace durante o fetch impede abertura no projeto errado.
- O diálogo de conflitos lê os estágios Git e reconstrói diff3 em arquivos temporários; associa a base por correspondência dos dois lados de cada bloco. Trechos sem correspondência segura permanecem sem base. Não insere o documento ancestral inteiro como base de um trecho.
- O grid Database executa UPDATE real com chave primária e condição do valor anterior. Restringe edição a projeções diretas de tabela única, valida tipos e diferencia texto `NULL` de nulo. Resultados sem proveniência de consulta/conexão não habilitam gravação. Trava edição/execução e trata concorrência ou contagem indeterminada de linhas explicitamente.
- O botão de consulta passa a **Descartar resultado**: mantém a execução ocupada até o driver encerrar, ignora respostas tardias e impede executar os statements restantes do lote. Não anuncia cancelamento físico que os drivers não oferecem.

## Evidências

- Suíte combinada de 18 arquivos: 110 testes aprovados antes dos últimos ajustes específicos de proveniência Database. Após os ajustes finais, 42 testes direcionados aprovados, incluindo 25 de serviço e view Database reais, teste do adaptador Dart real e teste de fetch de PR com Git local. Há sobreposição de testes entre as execuções; não somar as contagens.
- Adaptador Dart real: processo iniciado pelo DAP, breakpoint atingido, variável avaliada e encerramento observado.
- Repositório Git temporário real: duas regiões de conflito receberam bases distintas corretas; trecho modificado pelo usuário não recebeu uma base presumida; arquivo de trabalho preservado.
- Widgets de produção WorkspaceDebugPanel e WorkspaceOutlinePanel testados a 300px, com navegação e rejeição de resposta obsoleta.
- Análise final `dart analyze --fatal-infos lib test`: sem issues; `git diff --check` limpo.
- Build macOS de debug final compilado com `lib/main.dart`, restaurando o artefato normal após a prévia: `cockpit/build/macos/Build/Products/Debug/Orkest Code.app`. Prévia isolada inspecionada em `/private/tmp/orkest-workbench-integrated.png`; ela usa dados de demonstração e não equivale à jornada completa com projetos do usuário. Hot reload concluído com sucesso (5 bibliotecas recarregadas). A primeira sessão perdeu a conexão; a sessão reaberta concluiu a validação. Avisos nativos de desktop_multi_window/merged threads foram observados na inicialização da prévia; não foram alteradas configurações globais ou plugins para suprimi-los.

## Roteiro de homologação

1. Abrir o app compilado deste checkout e um projeto local. Conferir preservação do workspace esquerdo e das sessões de terminal. Alternar Files/Git/Database/Debug/Problems/Outline e restaurar o layout.
2. Abrir arquivo da linguagem com servidor LSP disponível. Introduzir um diagnóstico, navegar por Problems e Outline, editar o documento e alternar arquivos. Confirmar atualização da estrutura e do badge, sem símbolos do arquivo anterior.
3. Abrir script Dart simples; selecionar a configuração contextual em Debug; marcar breakpoint no gutter, iniciar Debug, inspecionar frame/variáveis, adicionar watch, avaliar expressão, continuar e encerrar. Repetir com um teste e, quando configurado, com launch/attach de `.vscode/launch.json`. Usar Run/Test para execução no terminal.
4. Em repositório descartável, testar diff split/unificado, hunks, blame, histórico e comparação. Gerar dois conflitos; abrir revisão completa, comparar as bases por bloco, resolver, revisar o arquivo final, cancelar e reaplicar. Salvar explicitamente; verificar que não houve stage automático.
5. No Git de um repositório GitHub, abrir Pull Requests e um arquivo alterado. Verificar comparação completa do PR e preservação da branch local. Checkout e comentário continuam ações explícitas do usuário.
6. No Database, executar SELECT direto contendo a PK; editar texto, número e NULL; reexecutar SELECT e confirmar persistência. Alterar o mesmo dado externamente antes de salvar no grid e verificar conflito. Resultados sem PK, com aliases/agregações ou sem proveniência devem recusar edição.
7. Executar consulta lenta em ambiente de teste e acionar Descartar resultado. Verificar estado ocupado até o driver concluir, ausência de publicação tardia e bloqueio de uma nova execução nessa aba. Em lote, confirmar que statements subsequentes não são enviados.

## Limites para interpretar o teste

- Homologação manual na aplicação completa continua uma etapa própria. Build e testes automatizados não a substituem.
- Os novos painéis DAP/LSP/PR estão habilitados em workspaces locais. Adaptadores e servidores de linguagem precisam existir no host; nenhuma dependência externa foi instalada automaticamente.
- PRs usam GitHub, credenciais do serviço existente e a ref sintética `refs/pull/<n>/merge`. PRs conflitados ou servidores que não expõem essa ref apresentam erro explícito ao abrir diff. Fetch atualiza somente uma ref de revisão, não a branch de trabalho.
- Cancelamento físico de consulta não foi adicionado aos drivers. DML já enviado pode ter sido aplicado mesmo se o driver não confirmar a contagem; a interface orienta recarregar e não afirma rollback.
- Edição Database é conservadora: consultas complexas permanecem somente leitura. Não houve mudança de schema ou migration.
- Área inferior do workbench, expansão de provedores e outras evoluções do plano 73 continuam separadas desta correção de integração.
