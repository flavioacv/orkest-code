# ADR: Decisão de Arquitetura por Domínio com Resultados Medidos (A04)

> **Status:** Aprovado e Fundamentado em Dados Experimentais  
> **Data:** 05/11/2026  
> **Autor:** Orkest Core Engineering Team  
> **Branch:** `fix/harness-state-detection`  
> **Atividade:** `A04 · Decidir arquitetura por domínio com resultados medidos` (P0)  
> **Referências:** [Contratos A01](72-contratos-servicos-capacidades.md), [Spike A03](72-prova-reaproveitamento-rust-vcs-dap.md), [Plano 72](72-orkest-ide-completa.md)

---

## 1. Contexto e Problema

O plano de evolução do Orkest Code para uma IDE completa (`plan/72-orkest-ide-completa.md`) levantou a hipótese de reaproveitar crates Rust do OpenIDEA (`ide-vcs`, `ide-dap`, `ide-search`) ou empacotar um binário auxiliar `openidea-server` para lidar com controle de versão, depuração e busca.

Antes de comprometer o produto com novos binários, dependências de compilação cruzada ou pontes nativas, foi estabelecido o critério mandatório:
- Medir a viabilidade real em testes automatizados (realizado na atividade **A03**);
- Comparar o custo total de distribuição, estabilidade, paridade funcional e facilidade de manutenção;
- Garantir que a interface e o ecossistema continuem estritamente focados em **Dart/Flutter**, **project-first** e **terminal-first**.

---

## 2. Abordagens Avaliadas

| Dimensão | Abordagem 1: Dart Puro + Ferramentas do Sistema (CLI/stdio) | Abordagem 2: Processo Auxiliar Rust Supervisionado (JSON-RPC) | Abordagem 3: FFI C/Rust (Foreign Function Interface) |
|---|---|---|---|
| **Isolamento de Falhas** | **Total**: Falhas de processos filhos retornam exit codes/erros capturados em Dart sem derrubar o app. | **Total**: Falhas e crashes do processo Rust são capturados tipadamente como `RustRpcException` (comprovado em A03). | **CRÍTICO**: Qualquer panic, segfault ou violação de acesso em Rust/C **derruba instantaneamente** o aplicativo Flutter inteiro. |
| **Distribuição e Empacotamento** | **Trivial**: Usa o runtime Dart e binários já presentes na máquina do desenvolvedor (Git, Dart SDK). | **Complexa**: Requer compilar e empacotar binários nativos para 6 alvos (macOS x64/ARM64, Linux x64/ARM64, Windows x64/ARM64). | **Altíssima**: Requer empacotar bibliotecas dinâmicas (.dylib, .so, .dll) assinadas e sincronizar ABIs de memória. |
| **Latência Operacional** | 15–40ms para comandos esporádicos do Git CLI; submilissegundo para DAP/LSP sobre stdio em Dart. | Submilissegundo para chamadas RPC (p50: 0.25ms, p95: 0.89ms medidos em A03). | Imediata (< 0.01ms). |
| **Complexidade de Depuração** | **Baixa**: Stack traces unificados em Dart, logs transparentes de subprocessos. | **Média**: Exige inspeção de dois processos e serialização JSON-RPC intermediária. | **Alta**: Debug de crash exige lldb/gdb acoplado ao Flutter engine. |
| **Suporte a Configurações do Usuário** | **Nativo**: Respeita `.gitconfig`, credenciais SSH, GPG, submodules e worktrees sem re-implementação. | **Parcial**: Exige mapear e repassar configs de ambiente e chaves para o crate Rust. | **Complexo**: Requer reconfigurar libgit2 para cada feature de autenticação/ambiente. |

---

## 3. Decisões Arquiteturais por Domínio

### 3.1. Controle de Versão (VCS) — Git
- **Decisão:** **Dart Nativo via CLI Git do Sistema (`GitController`) para ciclo de vida e comandos, com Algoritmo de Hunks e Staging em Dart Puro.**
- **Justificativa:**
  - O Git CLI instalado no sistema do desenvolvedor já possui suporte completo a hooks, credenciais, SSH/GPG e worktrees.
  - Para a funcionalidade **G01 (Revisão e Staging por Hunks)**, o parsing do diff unificado (`UnifiedDiffParser`) e a geração de patches em memória para `git apply --cached` em Dart puro eliminam qualquer necessidade de carregar binários Rust adicionais ou crates complexas.
  - Mantém o fallback transparente caso ferramentas externas não estejam disponíveis.

### 3.2. Depuração (DAP — Debug Adapter Protocol)
- **Decisão:** **Cliente DAP Dart Puro gerenciando Adaptadores Subprocesso via Stdio.**
- **Justificativa:**
  - O próprio protocolo DAP é nativamente um protocolo JSON-RPC 2.0 sobre stdio com framing `Content-Length`.
  - Como o Dart já gerencia streams stdio com máxima eficiência (como comprovado no LSP do Orkest), introduzir um processo intermediário Rust entre a UI do Flutter e o adaptador de debug (ex: `dart debug_adapter`, `debugpy`, `delve`) introduziria um "hop" de rede e serialização duplicada sem nenhum benefício arquitetural.
  - O cliente DAP em Dart terá controle direto sobre o ciclo de vida do subprocesso de depuração e das sessões de debug de projetos Flutter/Dart.

### 3.3. Assistência de Linguagem (LSP)
- **Decisão:** **Manter e Evoluir o `StdioLspClient` em Dart.**
- **Justificativa:**
  - Arquitetura já em produção e homologada com 114 testes aprovados.
  - Cancelamento imediato de UI (`$/cancelRequest`), descarte de requisições obsoletas e pooling por projeto já plenamente implementados em Dart com zero jank.

### 3.4. Foreign Function Interface (FFI)
- **Decisão:** **REJEITADA para VCS, DAP e Editor.**
- **Justificativa:**
  - O risco de instabilidade (panics derrubando a UI) viola o mandamento de zero sobre-engenharia e estabilidade do ambiente de trabalho do desenvolvedor.
  - FFI permanece restrita exclusivamente a bibliotecas de infraestrutura de baixo nível pré-existentes onde o custo de IPC fosse proibitivo (ex: PTY/Terminal existente).

### 3.5. Busca Textual em Arquivos
- **Decisão:** **Dart com `Isolate` dedicado + detecção inteligente de `ripgrep` (`rg`) nativo do sistema.**
- **Justificativa:**
  - `Isolate` em Dart já previne qualquer travamento na UI durante buscas de pequeno e médio porte.
  - Para repositórios com mais de 50.000 arquivos, a invocação direta do binário `rg` (quando instalado) entrega a velocidade bruta de Rust sem a complexidade de compilar o `ide-search` no app.

---

## 4. Consequências e Próximos Passos

1. **Simplicidade de Build (KISS/YAGNI):**
   - Nenhuma nova dependência binária Rust precisa ser adicionada ao pipeline de distribuição do Orkest Code neste momento.
   - O projeto compila com `flutter build` padrão sem requisitos de toolchain Rust para o editor/VCS/debug.
2. **Desbloqueio de Atividades no Kanban:**
   - Desbloqueia formalmente **`G01 · Entregar revisão e staging por hunks`** (que dependia de A04 e W03).
   - Desbloqueia formalmente **`R02 · Entregar núcleo DAP e UI de depuração`** (que dependia de A04, R01 e W03).
   - Desbloqueia formalmente **`A05 · Empacotar e supervisionar serviços nativos selecionados`** (condicionado às decisões de A04).
