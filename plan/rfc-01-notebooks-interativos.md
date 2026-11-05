# RFC 01 · Arquitetura de Notebooks Interativos no Orkest Code

**Status:** Aprovado com Adiamento de Kernel Nativo (Deferred)  
**Autor:** Antigravity / Flavio Valdez  
**Data:** 05/11/2026  
**Contexto:** Item X04 do Plano Mestre de Evolução do Orkest Code  

---

## 1. Sumário Executivo

Esta RFC formaliza a arquitetura e a estratégia de suporte a cadernos interativos no Orkest Code. Avalia a integração entre o formato canônico Jupyter (`.ipynb`) e o formato nativo de notas em Markdown com frontmatter YAML (`nome.notebook/`) já existente no Orkest.

**Decisão Fundamental:** Adotar visualização estática nativa de alta fidelidade para arquivos `.ipynb` e manter cadernos `.notebook` baseados em Markdown, **adiando a implementação de runtime de execução nativa de kernel Jupyter** (ZeroMQ/ipykernel) por razões de simplicidade, estabilidade térmica e aderência ao perfil project-first/terminal-first da IDE.

---

## 2. Modelo de Dados de Células

Um documento de notebook é decomposto em uma lista linear de células imutáveis:
1. **Markdown Cells (`NotebookCellKind.markdown`):** Documentação rica renderizada via árvore Flutter nativa (Markdown renderer);
2. **Code Cells (`NotebookCellKind.code`):** Código-fonte associado a número de execução (`executionCount`), metadados e lista de saídas estruturadas (`NotebookCellOutput`);
3. **Raw Cells (`NotebookCellKind.raw`):** Conteúdo textual não processado.

### Formato de Saídas Suportadas
- `stream`: Texto contínuo de stdout ou stderr;
- `execute_result`: Resultado avaliado da última expressão;
- `display_data`: Rich media incluindo JSON e imagens Base64;
- `error`: Detalhamento de exceções com `ename`, `evalue` e `traceback`.

---

## 3. Ciclo de Vida do Kernel (Kernel Lifecycle)

Caso a execução interativa seja ativada no futuro, o ciclo de vida deve obedecer à máquina de estados:
```
[Uninitialized] -> [Starting] -> [Idle] <--> [Busy]
                                   |            |
                                   v            v
                              [Restarting] -> [Dead]
```
- **Timeouts Rígidos:** Toda execução de célula possui teto configurável (padrão 30s) para prevenir loops infinitos travando recursos;
- **Cancelamento Limpo:** O cancelamento envia sinal de interrupção (SIGINT / interrupt request) ao processo do kernel sem matar a sessão do editor.

---

## 4. Análise de Custo-Benefício e Justificativa do Adiamento (Deferral)

- **Complexidade Operacional:** Gerenciar sockets ZeroMQ, ambientes virtuais Python, dependências de `ipykernel` e multiplexação de canais de heartbeat adicionaria dezenas de milhares de linhas de código e pontos de falha no host;
- **Terminal-First como Alternativa Superior:** Usuários do Orkest que executam scripts de dados podem disparar seus scripts diretamente no terminal integrado (PTY) ou via tasks com saída imediata e sem sobrecarga;
- **Visualizador Leve:** O parser implementado em `JupyterNotebookParser` permite inspecionar qualquer arquivo `.ipynb` com zero dependências externas.
