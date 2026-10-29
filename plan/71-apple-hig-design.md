# 71 — Design System Apple HIG no Orkest Code

## Contexto

A base de conhecimento global (`global/frontend/design-padrao-apple.md` e
`global/frontend/adoção-universal-irrestrita-do-design-apple-hig-na-maitan-software.md`)
estabelece a adoção universal e irrestrita do **Apple Human Interface Guidelines (Apple HIG)**
como padrão oficial de design e engenharia de interface.

O **Orkest Code** (`cockpit/`) já possui fundações sólidas de aplicativo macOS/Desktop
(integração com semáforos nativos, `WindowActivityController` para estado ativo/inativo da
janela, separadores hairline de `1px`, arquitetura de 3 colunas), mas apresenta lacunas
visuais e de interação frente ao padrão Apple HIG:

1. **Tipografia desconectada do ecossistema Apple (`app_typography.dart`, `font_catalog.dart`):**
   - Força `'Inter'` na UI e `'JetBrains Mono'` no código sem aproveitar a família nativa
     San Francisco (`.AppleSystemUIFont` / `SF Pro Display` / `SF Pro Text` / `SF Mono`)
     como padrão primário no macOS/iOS e no catálogo de fontes.
   - Falta *letter-spacing* negativo (*tight tracking*) em títulos (`display`, `title`) e
     ajustes de altura de linha (`1.45` para corpo, `1.22` para títulos).
2. **Ausência de Materiais Translúcidos (*Liquid Glass* / Vibrancy) e Geometria Contínua (*Squircles*):**
   - Popovers, menus de contexto (`app_menu.dart`), Command Palette (`file_finder_palette.dart`),
     diálogos modais (`confirm_dialog.dart`) e tooltips (`app_tooltip.dart`) utilizam fundos
     100% opacos (`colors.panel2`) e `BorderRadius.circular` convencional em vez de
     superfícies translúcidas com `BackdropFilter` (`ImageFilter.blur(sigmaX: 24, sigmaY: 24)`),
     borda especular de `1px` e curvatura contínua (`ContinuousRectangleBorder` / *squircle*).
3. **Micro-interações sem Física de Mola/Desaceleração Apple e Controles de Janela Estáticos:**
   - `AppPopoverOverlayHandler` (`app_popover_handler.dart`) usa `Curves.linear` em vez da
     curva de desaceleração fluida da Apple (`Cubic(0.16, 1, 0.3, 1)`).
   - `HoverTap` (`hover_tap.dart`) troca cor instantaneamente sem transição suave nem
     feedback tátil de pressão (`scale: 0.98`) e usa cantos circulares simples.
   - `WindowControls` (`window_controls.dart`) mantém os botões de semáforo sempre acesos
     (`#FF5F57`, `#FEBC2E`, `#28C840`) mesmo quando a janela perde o foco, ignorando o
     `WindowActivityScope` já existente no app.
4. **Áreas de Toque/Clique (*Hit Targets*) e Agrupamento Visual (*Inset Grouped*):**
   - Botões de ícone na topbar (`orkest_topbar.dart`) e rail (`projects_rail.dart`) possuem
     alvos compactos demais (`20x20` a `26x26`), abaixo do mínimo ergonômico de `28x28pt`
     no macOS e `44x44pt` em plataformas touch (`isMobilePlatform`).
   - Cartões e seções de configurações (`settings_page.dart`) podem adotar geometria contínua
     (*squircle* `12px`–`14px`), cabeçalhos de seção e espaçamento refinado no estilo
     *macOS System Settings*.

## Decisões

| # | Decisão |
|---|---|
| A | **Preservar Invariantes de Tema e Testes (`theme_codec_test.dart`):** Toda evolução cromática em `AppColors.dark` / `AppColors.light` e `builtInThemes` deve manter 100% dos invariantes de contraste WCAG (`>= 3.0`), hierarquia de luminância (`bg` vs `panel` vs `panel2` vs `panel3`), distância de matiz (`>= 20°`) e serialização JSON de 25 chaves. Adicionar também o preset oficial **`apple-hig` (Apple HIG — Liquid Glass)** ao `theme_registry.dart`. |
| B | **Respeitar `ClampingScrollBehavior`:** Conforme regra explícita do `cockpit/CLAUDE.md`, manter `ClampingScrollPhysics` em todo o app (não introduzir bounce). |
| C | **Componente Reutilizável `AppleGlassSurface` + Geometria Squircle:** Centralizar o material translúcido (`BackdropFilter` blur `24px`, fundo semitransparente calibrado por tema claro/escuro, borda especular hairline `1px` e `ContinuousRectangleBorder`) em `lib/app/core/ui/widgets/apple_glass_surface.dart` para uso consistente em menus, command palette, diálogos e tooltips. |
| D | **Tipografia Nativa Apple como Default Inteligente:** Em plataformas Apple (`macOS`/`iOS`), quando o usuário não fixou fonte customizada (`uiFont` vazio), usar `.AppleSystemUIFont` com fallback `['SF Pro Text', 'SF Pro Display', 'Inter']` e tracking óptico Apple HIG; incluir `SF Pro Text` e `SF Mono` no `font_catalog.dart` sem quebrar fontes Google existentes. |

## Estrutura esperada

```
cockpit/lib/app/core/ui/
├── font_catalog.dart                    # Suporte híbrido: fontes nativas Apple (SF Pro / SF Mono) + Google Fonts
├── overlay/
│   └── app_popover_handler.dart         # Curva Apple Cubic(0.16, 1, 0.3, 1) e transição fluida
├── themes/
│   ├── app_colors.dart                  # Refinamento cromático Apple HIG (mantendo invariantes WCAG)
│   ├── app_theme.dart                   # Radius 0.625 (10px) e integração tipográfica
│   ├── app_typography.dart              # Escala tipográfica Apple HIG + tracking óptico + fallback SF Pro
│   └── theme_registry.dart              # Novo tema built-in "Apple HIG" + temas existentes intactos
└── widgets/
    ├── apple_glass_surface.dart         # [NOVO] Superfície Liquid Glass (BackdropFilter + Squircle + Hairline)
    ├── app_menu.dart                    # Menus e submenus com Liquid Glass e seleção estilo macOS
    ├── app_tooltip.dart                 # Tooltip translúcido com geometria contínua
    ├── hover_tap.dart                   # Micro-interação suave (120ms Cubic, scale 0.98 no tap, squircle)
    └── window_controls.dart             # Semáforos macOS conscientes de WindowActivityScope (inativo = cinza)

cockpit/lib/app/orkest/ui/widgets/
├── confirm_dialog.dart                  # Alertas/Modais estilo macOS (Liquid Glass + Squircle 14px)
├── file_finder_palette.dart             # Spotlight / Command Palette (Cmd+P) em Liquid Glass
├── orkest_topbar.dart                   # Hit targets ergonômicos (28pt desktop / 44pt mobile) + refinamento
└── projects_rail.dart                   # Sidebar estilo macOS com seleção contínua e hit targets adequados

cockpit/lib/app/settings/ui/
└── settings_page.dart                   # Estilo macOS System Settings (Inset Grouped cards + Squircle)
```

## Waves de Implementação

### Wave 1 — Tipografia, Catálogo de Fontes & Fundação de Cores Apple HIG
1. **`font_catalog.dart`**: suportar fontes de sistema nativas (`SF Pro`, `SF Mono`) retornando `TextStyle` direto sem chamada de rede ao `GoogleFonts`, mantendo `GoogleFonts.getFont` para as demais.
2. **`app_typography.dart`**: aplicar escala tipográfica Apple HIG (`display` 22pt w600 tracking `-0.4` height `1.22`, `title` 13pt w600 tracking `-0.15`, `body` 13pt height `1.42` tracking `-0.08`, `label` 11.5pt height `1.3`, `tab` 12.5pt w500) e fallback automático para `.AppleSystemUIFont` no macOS/iOS quando `uiFont` for nulo/vazio.
3. **`app_colors.dart`, `app_theme.dart` & `theme_registry.dart`**: ajustar `buildTheme` (`radius: 0.625`), calibrar `AppColors` e registrar o tema `appleHigTheme` (`id: 'apple-hig'`, nome `'Apple HIG'`) cumprindo todos os testes de contraste e luminância de `test/ui/theme_codec_test.dart`.

**Critério de aceite Wave 1:** `flutter test test/ui/theme_codec_test.dart` e `test/domain/app_settings_terminal_typography_test.dart` 100% verdes.

### Wave 2 — Materiais Translúcidos (*Liquid Glass*) & Geometria Contínua (*Squircles*)
1. Criar `cockpit/lib/app/core/ui/widgets/apple_glass_surface.dart` com `AppleGlassSurface` e helper `appleSquircleBorder` (`ContinuousRectangleBorder`).
2. Atualizar `app_menu.dart` (`showAppMenu`, `_SubmenuHost`, `_SearchableMenu`) para usar `AppleGlassSurface`, seleção com `accent` / `accentSoft` em formato squircle e separadores hairline translúcidos.
3. Atualizar `file_finder_palette.dart` (`_FileFinderPalette`) para visual *Spotlight* com `AppleGlassSurface` (`blurSigma: 28`, raio contínuo `28px` equivalente a `14px` visual).
4. Atualizar `confirm_dialog.dart` (`showInfoDialog`, `showCloseDirtyDialog`, `showConfirmDialog`) e `app_tooltip.dart` (`AppTooltip`) com `AppleGlassSurface`.

**Critério de aceite Wave 2:** `flutter analyze` sem erros/avisos; menus, command palette, diálogos e tooltips renderizando com `BackdropFilter` e bordas contínuas.

### Wave 3 — Micro-interações Físicas, Controles de Janela macOS, Hit Targets & Settings
1. **`app_popover_handler.dart`**: substituir `Curves.linear` por `const Cubic(0.16, 1, 0.3, 1)` e `Duration(milliseconds: 160)`.
2. **`hover_tap.dart`**: adicionar transição suave de cor/borda (`120ms`, `Cubic(0.16, 1, 0.3, 1)`), escala tátil sutil no clique (`0.98`) e geometria `ContinuousRectangleBorder`.
3. **`window_controls.dart`**: integrar `WindowActivityScope.maybeOf(context)` para esmaecer os botões de semáforo quando a janela estiver inativa e sem hover, acendendo as cores oficiais da Apple ao focar a janela ou passar o mouse.
4. **`orkest_topbar.dart`, `projects_rail.dart` & `settings_page.dart`**:
   - Garantir hit targets mínimos (`28x28pt` no desktop, `44x44pt` no mobile).
   - Aplicar geometria contínua (*squircle*) nos cards de grupo de `settings_page.dart` e itens selecionados do `projects_rail.dart`.

**Critério de aceite Wave 3:** `flutter analyze` com 0 issues e suíte `flutter test` passando integralmente.

## Definition of Done

- [ ] Branch dedicada `feat/apple-hig-design` criada e ativa
- [ ] Wave 1 concluída e validada por testes automatizados de tema e tipografia
- [ ] Wave 2 concluída (`AppleGlassSurface`, menus, command palette, diálogos, tooltips)
- [ ] Wave 3 concluída (`HoverTap`, `AppPopoverOverlayHandler`, `WindowControls` reativo ao foco, hit targets e `SettingsPage` Inset Grouped)
- [ ] `flutter analyze` retorna zero problemas
- [ ] `flutter test` passa sem regressões
- [ ] Aprendizado registrado na base de conhecimento via `salvar_aprendizado`
