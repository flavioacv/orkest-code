# W02 · Unificação de Ações, Atalhos e Navegação do Desenvolvedor

## 1. Visão Geral e Objetivos
O item **W02** estabelece a unificação do sistema de ações, atalhos de teclado e paleta de comandos do Orkest Code:
- Prover uma **Command Palette** unificada (`Cmd+Shift+P` / `Ctrl+Shift+P` ou `F1`), permitindo buscar e executar todas as ações da IDE pelo teclado.
- Integrar transição suave entre a busca rápida de arquivos (`Cmd+P`) e comandos através do prefixo `>`, seguindo a ergonomia de editores modernos sem interferir na autoridade do modelo project-first.
- Mapear comandos em um `CommandRegistry` desacoplado, com categorias claras (Arquivo, Edição, Visualização, Terminal, Navegação, Preferências), atalhos associados e feedback contextual para ações indisponíveis (indicando a capacidade faltante).
- Garantir coerência de atalhos, foco automático, acessibilidade e suporte à internacionalização (i18n).

## 2. Arquitetura de Comandos e Atalhos

### 2.1. Modelo `CommandItem` e `CommandRegistry`
- `CommandItem`:
  - `id`: identificador canônico estável (ex.: `file.openProject`, `file.save`, `edit.format`, `view.commandPalette`, `terminal.new`).
  - `title`: descrição textual legível para o usuário.
  - `category`: agrupamento conceitual (ex.: `File`, `Edit`, `View`, `Terminal`, `Workspace`, `Settings`).
  - `shortcutHint`: representação textual amigável do atalho (ex.: `⌘P`, `⇧⌘P`, `⌘S`, `⇧⌘F`, `⌘T`, `⌘,`).
  - `icon`: glifo visual representativo.
  - `isEnabled`: booleano avaliado dinamicamente conforme o contexto ativo (workspace presente, editor em edição, etc.).
  - `disabledReason`: mensagem amigável explicando por que a ação não está acessível no momento (ex.: "Nenhum arquivo em edição com alterações pendentes").
  - `run`: callback executado ao disparar o comando.

### 2.2. Command Palette UI (`showCommandPalette`)
- Modal flutuante centrado no topo com `AppleGlassSurface` e efeito blur.
- Campo de busca responsivo com filtro instantâneo por título e categoria.
- Navegação completa por teclado:
  - `↑` / `↓`: seleção de comandos.
  - `Enter` / `NumpadEnter`: execução imediata da ação e fechamento da paleta.
  - `Esc`: fechamento sem ação.
- Ações desabilitadas são exibidas em tom esmaecido com tooltip/legenda informando a capacidade faltante, evitando cliques silenciosamente ignorados.

### 2.3. Integração com Shell e Menus
- **Atalhos Globais do Shell**: `SingleActivator(LogicalKeyboardKey.keyP, meta: true, shift: true)` e `SingleActivator(LogicalKeyboardKey.f1)` mapeados no `OrkestPage._shellBindings`.
- **Menu Nativo**: `buildAppMenus` inclui a ação `tr.commandPalette` com acelerador `⇧⌘P`.
- **Quick-Open Dinâmico**: Ao abrir o quick-open (`Cmd+P`) e digitar `>`, a interface transiciona instantaneamente para busca de comandos.
