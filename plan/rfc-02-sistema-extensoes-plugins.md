# RFC 02 · Sistema de Extensões, Plugins e Modelo de Sandbox no Orkest Code

**Status:** Aprovado com Rejeição de Plugins React e Adoção de Extensibilidade Declarativa (Headless)  
**Autor:** Antigravity / Flavio Valdez  
**Data:** 05/11/2026  
**Contexto:** Item X04 do Plano Mestre de Evolução do Orkest Code  

---

## 1. Sumário Executivo

Esta RFC define os limites arquiteturais para o sistema de plugins e extensões do Orkest Code. Estabelece a política de isolamento em sandbox, o formato de manifesto declarativo (`PluginManifest`) e responde de forma definitiva à questão sobre reaproveitamento de plugins web baseados em React/DOM provenientes de outras ferramentas (Theia/VS Code).

---

## 2. Ponto Crítico de Arquitetura: "Plugins React NÃO são Widgets Flutter"

### 2.1 A Incompatibilidade Técnica
No ecossistema Electron/Theia, plugins de UI constroem árvores DOM através de componentes React injetados em iframes web. No Orkest Code, todo o subsistema de renderização gráfica é baseado em Flutter puro (Skia / Impeller), desenhando frames diretamente via GPU a 60-120fps.

### 2.2 Por Que Embutir React em WebViews é Rejeitado
1. **Degradação de Desempenho e Jank:** Cada painel React exigiria uma instância separada de WebView (`WKWebView` / `WebView2`), quebrando a renderização sincronizada e introduzindo atrasos de composição;
2. **Consumo Excessivo de Memória:** Cada engine WebView aloca de 80MB a 200MB de RSS. Abrir múltiplos plugins de terceiros elevaria o consumo de memória do aplicativo a patamares proibitivos;
3. **Incompatibilidade de Acessibilidade e Tema:** Temas, atalhos globais e acessibilidade de leitores de tela do Flutter não atravessam a fronteira do DOM sem pontes complexas e frágeis.

**Decisão:** Rejeitar categoricamente o modelo de plugins com renderização React. O Orkest Code não implementará um container web para UI de extensões.

---

## 3. Modelo de Extensibilidade Declarativa e Headless

A extensibilidade sustentável do Orkest baseia-se em 3 pilares:
1. **Manifestos Declarativos (`PluginManifest`):** Extensões declaram pontos de contribuição em JSON estático:
   - Comandos (`commands`);
   - Itens de menu (`menus`);
   - Mapeamentos de atalho (`keybindings`);
   - Esquemas de sintaxe TextMate e temas (`themes`).
2. **Protocolos Abertos Padronizados:**
   - Inteligência de Linguagem via **LSP (Language Server Protocol)**;
   - Depuração via **DAP (Debug Adapter Protocol)**;
   - Ferramentas e contexto de IA via **MCP (Model Context Protocol)**.
3. **Política de Sandbox e Permissões Explícitas (`PluginSandboxPolicy`):**
   - Extensões declaram estritamente o que necessitam (`filesystem.read`, `network`, `terminal.pty`);
   - Permissões destrutivas (`filesystem.write`, `terminal.pty`) são auditadas e bloqueadas por padrão sem consentimento expresso do desenvolvedor;
   - O runtime de extensões opera em subprocessos isolados via JSON-RPC, impedindo que falhas em plugins derrubem a IDE.
