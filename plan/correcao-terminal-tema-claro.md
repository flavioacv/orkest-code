# Contraste do terminal em temas claros

Correção de 13/11/2026, branch `fix/harness-state-detection`.

A paleta clara já escurecia as 16 cores ANSI, mas cores de 256 tons, RGB explícito e texto faint continuavam sendo desenhados sem proteção de contraste. No Ghostty, `minimumContrast` existia no tema, mas não era aplicado na preparação das cores dos frames; a cor padrão também podia ser redefinida por OSC 10.

A renderização agora exige contraste de 4,5:1 para texto sobre células claras em terminais de fundo claro. A correção escurece somente cores insuficientes, após inversão e transparência faint, considerando o fundo da célula. Fundos explícitos escuros e temas escuros preservam o comportamento anterior. A saída VT, o histórico e a paleta de fundos não são reescritos. Seleções e realces próprios do Ghostty continuam usando suas cores específicas.

O cálculo compartilhado fica no pacote local flterm, já utilizado pelo app, com cache limitado a 1.024 pares de cores. A cor candidata é quantizada para ARGB de 8 bits antes de validar o contraste, evitando diferenças entre o cálculo e os pixels do canvas/atlas. O cache é renovado ao trocar o tema.

Validação: 56 testes aprovados (39 de contraste/temas, 16 de regressão dos terminais e 1 de pixels do Ghostty real). Os testes de pixels cobrem os painters Orkest/xterm, cores RGB e indexadas, faint, inversão, fundos escuros, troca entre tema claro/escuro e cor padrão OSC 10 no Ghostty. Análise estática dos 8 arquivos envolvidos sem issues. Build macOS debug e hot reload concluídos. Não foi executado E2E de todos os temas por navegação na aplicação.

Nenhuma dependência ou configuração de usuário adicionada. Commit local, sem push ou merge.
