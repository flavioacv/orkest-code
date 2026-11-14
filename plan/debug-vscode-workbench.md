# Debug do VS Code como referência para o Orkest

## Referência e diagnóstico

Fonte local: `/Volumes/Externo/projetos/zurc/vscode/src/vs/workbench/contrib/debug`. Foram inspecionados `debug.contribution.ts`, `debugViewlet.ts`, `debugSession.ts`, `variablesView.ts`, `watchExpressionsView.ts`, `callStackView.ts`, `breakpointsView.ts`, `debugToolBar.ts` e o protocolo DAP.

O VS Code separa serviços de sessão/configuração, modelos de inspeção e views de Variables, Watch, Call Stack, Breakpoints e Debug Console. As ações dependem das capabilities negociadas com o adaptador, e iniciar um runtime não é equivalente a iniciar um adaptador DAP.

No Orkest já existem codec, cliente DAP, sessões por workspace, configurações JSONC, breakpoints no editor e controles básicos. Lacunas encontradas: Node Inspector anunciado como DAP, transportes TCP tratados como stdio, exceções fixadas em nomes Dart, respostas de breakpoint descartadas, avaliação usando o primeiro frame, variáveis planas e console sem histórico na telemetria. O painel mistura responsabilidades, tem seletor visual sem interação e usa textos literais.

## Implementação autorizada

1. Consolidar o cliente DAP: falhas/tempos de espera, stderr, conexão TCP e reverse requests com capacidades honestas.
2. Resolver adaptadores e configurações de linguagens respeitando stdio/TCP e configuração explícita; não instalar dependências automaticamente nem fingir disponibilidade de um adaptador por encontrar o runtime.
3. Modelar breakpoints habilitados/verificados/condicionais/logpoints e filtros de exceções do adaptador. Corrigir inspeção de threads, frames, variáveis e avaliações com proteção contra respostas obsoletas.
4. Reorganizar Run and Debug com configuração selecionável, ações claras, seções de inspeção recolhíveis, console de avaliação, estados de vazio/erro e layout responsivo. Traduzir en/pt-BR/es.
5. Persistir preferências de debug, breakpoints e watches por workspace no layout existente e encaminhar saída da execução DAP para a ingestão de telemetria.
6. Validar por testes de protocolo, configuração, widgets e adaptadores reais disponíveis; registrar separadamente resultados simulados e execução real.

## Limite de equivalência

Implementar os fluxos de depuração no Flutter sobre DAP, preservando a arquitetura do Orkest. Isso não incorpora o extension host do VS Code nem instala extensões de terceiros. Funcionalidades de cada linguagem dependem do adaptador instalado e das capabilities reais, não apenas do catálogo. A equivalência integral de extensões, visualizadores especializados e depuração de memória não pode ser alegada por testes do cliente DAP.

## Validação

- 105 testes passaram na suíte conjunta de DAP, adaptadores, configurações, widgets e telemetria. Comando, a partir de `cockpit/`: `flutter test test/data/dap_core_test.dart test/data/dart_debug_adapter_test.dart test/data/dap_runtime_integration_test.dart test/domain/multi_language_debug_adapter_test.dart test/tasks/run_configuration_test.dart test/tasks/debug_launch_configuration_test.dart test/ui/debug_widgets_test.dart test/ui/debug_workbench_test.dart test/data/debug_workbench_protocol_test.dart test/data/telemetry --reporter expanded`.
- Integração real: adaptador Dart do SDK inicia um programa temporário, verifica breakpoint, pausa na linha esperada, avalia `value` como `42`, continua e termina. Os demais testes DAP usam uma fixture de protocolo ou socket TCP local; não comprovam execução real de Python, Node, Go, Java, C/C++ ou .NET.
- Widgets: seleção altera o alvo lançado; Run e Debug têm callbacks distintos; variáveis expandem sob demanda; console avalia no frame selecionado; editor envia condição, contagem e logpoint; desativação global limpa os breakpoints no adaptador; layouts de 360×220 e 1280×420 são verificados nos temas claro e escuro.
- Protocolo: respostas obsoletas não substituem a seleção atual; parada recebida antes da resposta do step permanece pausada; launch aguarda o disconnect anterior; attach não solicita terminate; filtros de exceção usam ids reais; reverse requests recebem resposta ou erro explícito; alteração de variável atualiza a inspeção.
- `dart analyze` dos arquivos de produção alterados e testes novos: sem problemas. `git diff --check`: sem erros.
- Build nativo macOS concluído e hot reload de 36 bibliotecas realizado. Permaneceram avisos de plugins nativos já existentes. A inspeção automatizada da tela nativa não pôde ser realizada: Marionette não está inicializado nessa execução e o servidor MCP Dart mantém um diretório de trabalho inválido. A validação visual automatizada disponível foi a de widgets, não um E2E de todos os fluxos na janela nativa.

## Uso e integração

- Escolher uma configuração no topo do painel Debug; o botão principal depura e a ação de terminal executa sem depurar. A engrenagem abre/cria `.vscode/launch.json`, e atualizar relê as configurações.
- F5 inicia/continua, Ctrl+F5 executa, Shift+F5 encerra, F6 pausa, F10 avança, F11 entra, Shift+F11 sai e F9 alterna breakpoint no editor.
- Breakpoints, watches, filtros de exceção e configuração selecionada são guardados por workspace no documento de layout existente. O serializador de layout preserva o campo `debug`; conteúdo do programa, pilhas e variáveis não são persistidos.
- Saída DAP de stdout/stderr/console/important é encaminhada ao serviço de ingestão existente. Debug controla a execução e inspeciona estado; telemetria registra a saída e o histórico. Falha da telemetria é registrada e não impede depurar. `runInTerminal` usa o runner de Tasks existente com argumentos literais e captura própria.
- Python usa debugpy; Node/TypeScript precisa de um servidor js-debug compatível com DAP (Node Inspector isoladamente não serve); Go usa Delve; Rust/C/C++ usa CodeLLDB; .NET usa netcoredbg. Java requer endpoint DAP ou comando configurado. Executáveis/adaptadores externos precisam estar instalados no ambiente; não foram adicionadas dependências.
- Pode-se configurar `adapter.command`, `adapter.args` e `adapter.transport` (`stdio`/`tcp`) no launch; `${port}` em argumentos é preenchido para o servidor TCP iniciado pelo Orkest. `debugServer` conecta a um endpoint DAP em loopback, incluindo portas encaminhadas de hosts remotos.
- Uma sessão ativa por workspace. Não inclui extension host, instalação de extensões, compounds/sessões filhas, `preLaunchTask`/`postDebugTask`, depuração de memória/disassembly ou paridade com visualizadores específicos de cada extensão. As ações exibidas respeitam as capacidades recebidas do adaptador.

As alterações são locais; não há push nem merge automático.
