# W03 · Fortalecimento de Edição, Documentos e Sincronização

## 1. Visão Geral e Contexto
O item **W03** do plano Orkest Code consolida as garantias de integridade documental do editor:
- Prevenção ativa de perda de trabalho em cenários de concorrência com agentes e ferramentas externas.
- Detecção e preservação de terminadores de linha originais (CRLF vs LF) e encodings (UTF-8 / Latin-1).
- Gestão de ciclo de vida de buffers sujos (*dirty buffers*), com diálogos atômicos de confirmação no fechamento.
- Sinalização visual e resolução explícita de conflitos de concorrência em disco.
- Suporte a desfazer/refazer (*undo/redo*) e proteção de arquivos grandes (*large files*).

## 2. Arquitetura de Sincronização e Regras de Concorrência

### 2.1. Regra de Autoridade Única do Buffer Editável (*Single Writer*)
1. **Buffer Limpo (`dirty == false`)**:
   - Modificações ocorridas no disco (ex.: geradas por subagentes, refatorações externas ou compilações) são adotadas automaticamente pelo editor via watcher (`FileViewerSession.adoptDisk`).
   - O baseline e os terminadores de linha são sincronizados de forma transparente no frame seguinte.
2. **Buffer Sujo (`dirty == true`)**:
   - Modificações externas no disco **NUNCA** sobrescrevem silenciosamente as alterações em memória do desenvolvedor.
   - O sistema detecta o conflito de concorrência e ativa o estado `FileViewerSession.hasDiskConflict = true`.
   - O editor apresenta uma notificação de conflito permitindo ao desenvolvedor:
     - **Manter edições locais**: mantém o buffer sujo atual e descarta o aviso.
     - **Recarregar do disco**: descarta as alterações locais e adota o conteúdo mais recente do arquivo em disco.

### 2.2. Preservação de Terminadores de Linha (CRLF vs LF)
- Ao carregar o conteúdo do arquivo em `FileViewer._initContent` ou `FileViewer._adoptLoadedContent`, o sistema detecta se o texto contém sequências `\r\n`.
- Ao salvar (`FileViewer._save`), caso o arquivo de origem tenha sido identificado como CRLF, o texto editado pelo Flutter (que normaliza internamente em `\n`) é convertido de volta para `\r\n` (`replaceAll(RegExp(r'(?<!\r)\n'), '\r\n')`).
- Essa preservação evita diffs gigantescos e artificiais no Git quando arquivos criados em Windows ou com padrão CRLF são editados.

### 2.3. Preservação de Encoding e Proteção contra Arquivos Grandes
- Conforme implementado em `FileReaderImpl`, o limite seguro para abertura textual é de 2MB (`_maxTextBytes = 2 * 1024 * 1024`). Arquivos superiores são sinalizados como `FileViewUnsupported` para prevenir estouro de memória e congelamento da UI.
- O encoding original (UTF-8 estrito ou Latin-1) é mantido em `FileViewText`/`FileViewMarkdown`/`FileViewSvg` e reutilizado na escrita em disco via `_fileReader.write(s.path, content, encoding: encoding)`.

### 2.4. Fechamento de Abas e Multi-janela
- `requestCloseTab` intercepta qualquer tentativa de fechamento (atalho ⌘W/Ctrl+W, clique no X ou fechamento em lote).
- Se `item.dirty == true`, o diálogo `showCloseDirtyDialog` exige decisão explícita:
  - *Cancelar*: a aba permanece aberta e o foco retorna ao editor.
  - *Não salvar*: a aba é fechada descartando as alterações pendentes.
  - *Salvar*: executa `item.saveDraft()`. Se a operação de IO falhar (ex.: permissão, disco cheio ou rede indisponível), o fechamento é interrompido para não perder o trabalho em memória.
