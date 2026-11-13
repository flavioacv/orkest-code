# Contraste do terminal em temas claros

Correção de 13/11/2026, branch `fix/harness-state-detection`.

A paleta clara já escurecia as 16 cores ANSI, mas cores de 256 tons, RGB explícito e texto faint continuavam sendo desenhados sem proteção de contraste. No Ghostty, `minimumContrast` existia no tema, mas não era aplicado na preparação das cores dos frames; a cor padrão também podia ser redefinida por OSC 10.

A renderização agora exige contraste de 4,5:1 para texto em terminais de tema claro. A correção atua após inversão e transparência faint, considerando o fundo efetivo da célula. Cores já legíveis são preservadas; cores insuficientes se aproximam de preto ou branco conforme o fundo. Temas escuros preservam o comportamento anterior. A saída VT e o histórico não são reescritos. Seleções e realces próprios do Ghostty continuam usando suas cores específicas.

Após as referências visuais enviadas pelo usuário, a correção foi ampliada para elementos gráficos dos agentes. Fundos explícitos de campos e blocos coloridos recebem separação mínima de 1,5:1 em relação à superfície do terminal. O fundo padrão continua intacto. O texto é ajustado contra o fundo já corrigido, evitando letras claras sobre campos claros. A mesma resolução é usada ao pintar fundos e ao calcular o contraste do texto, inclusive em células invertidas. A separação de 1,5:1 é uma escolha visual para superfícies; não representa conformidade WCAG de gráficos.

O cálculo compartilhado fica no pacote local flterm, já utilizado pelo app, com cache limitado a 1.024 pares de cores. A cor candidata é quantizada para ARGB de 8 bits antes de validar o contraste, evitando diferenças entre o cálculo e os pixels do canvas/atlas. O cache é renovado ao trocar o tema.

Validação final consolidada: 56 testes aprovados (39 de contraste/temas, 16 de regressão dos terminais e 1 de pixels do Ghostty real). A ampliação acrescenta casos de pixels para fundos RGB/indexados, campos, blocos de logos, bordas Unicode, meios blocos e Braille, mantendo a verificação de faint, inversão, fundos escuros, troca de tema e OSC 10. Análise estática dos 7 arquivos Dart da ampliação sem issues e diff sem erros de whitespace. São fixtures representativas dos mecanismos vistos nas capturas, não uma sessão E2E completa de cada agente. Não foi executado E2E de todos os temas por navegação na aplicação.

Nenhuma dependência ou configuração de usuário adicionada. Commit local, sem push ou merge.

## Logo real ainda ausente: causa reproduzida no ambiente

A captura posterior do usuário mostrou o logo ausente e a interface do Antigravity sem cores, mesmo após os ajustes de contraste. Os testes genéricos anteriores não comprovavam esse caso real.

O processo de debug iniciado pela ferramenta herdava `NO_COLOR=1` e o repassava aos PTYs. A reprodução com o executável Antigravity CLI 1.5.8 confirmou que essa variável faz o programa emitir somente espaços na região do logo; sem a variável, emite 16 blocos RGB de fundo. Logo, a renderização não poderia recuperar um logo que o programa deixou de emitir.

`TerminalSession` agora anuncia cores para sessões interativas: `NO_COLOR=''`, `FORCE_COLOR=3` e `CLICOLOR_FORCE=1`. O ambiente explícito do workspace prevalece, inclusive `NO_COLOR`, `FORCE_COLOR=0` e `CLICOLOR=0`. Isso alcança gateways locais, sidecar e remotos sem alterar os ambientes dos executores de tarefas.

Validação específica: 9 testes aprovados (4 de ambiente, 1 da captura real do logo e 4 de renderização/contraste); análise estática dos 3 arquivos Dart novos/alterados sem issues. A fixture contém apenas a região do logo real, sem conta, autenticação ou dados de projeto. O teste desenha a captura no Ghostty claro e verifica mais de 500 pixels coloridos e pelo menos 8 cores distintas. A imagem gerada foi inspecionada. Uma aba separada `Teste cores Antigravity` foi aberta pela CLI e o programa iniciou com o logo usando `env -u NO_COLOR FORCE_COLOR=3 CLICOLOR_FORCE=1 agy`, sem enviar prompts.

Abas antigas conservam seu ambiente; precisam reiniciar o programa com a variável removida. A mudança de criação vale para novas sessões quando o código atualizado estiver carregado. O último app Flutter debug foi encerrado durante a revisão; a tentativa final de hot reload ficou indisponível (DTD sem conexão e daemon com diretório corrente inválido). Não afirmar atualização automática do binário em execução ou E2E completo de todos os agentes.
