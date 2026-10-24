# Entrada do OpenLess nos terminais macOS

Validado em 24/10/2026 no Cockpit executado com `flutter run -d macos`.

## Fluxo do OpenLess

O código-fonte consultado está em `zurc/openless/openless-all/app/src-tauri/src`:

- `core_adapters.rs`: mantém o PID do aplicativo de destino e seleciona a
  inserção contínua ou final.
- `macos_streaming_input.rs` e `unicode_keystroke.rs`: a inserção contínua
  publica eventos CoreGraphics com texto Unicode em blocos de até 20 unidades
  UTF-16. O código virtual usado para esses blocos é 0.
- `insertion.rs`: a inserção final coloca o texto no clipboard e publica
  V pressionado/solto com a flag Command. A preferência de restauração pode
  devolver o clipboard anterior após 750 ms.

## Falha reproduzida

A instância usa `AdaptiveTerminalPane` com Ghostty/flterm. Eventos Unicode
chegaram normalmente ao terminal. O Cmd+V sintético não acionava a colagem:
`HardwareKeyboard.isMetaPressed` era falso, enquanto `RawKeyboard.keysPressed`
preservava Command proveniente das flags do evento nativo.

O OpenLess informava `Inserted` mesmo assim: esse resultado confirma o envio
do evento ao sistema, sem confirmar a inserção no aplicativo de destino.

## Correção

`MacOsSyntheticPasteActivator` reconhece V pressionado com Command no estado
bruto do macOS, quando o teclado moderno não registra Meta. Ele rejeita
soltura, repetição e combinações adicionais com Shift, Control ou Option.
O fallback fica restrito ao macOS e ao atalho de colagem.

`_GhosttyPane` liga esse atalho à ação de colagem já existente na sessão.
`pane_view.dart` aplica o mesmo reconhecimento no caminho xterm.
`TerminalSession.pasteFromClipboard` consulta texto primeiro no macOS para
ler o conteúdo antes da restauração temporizada do OpenLess.

A dependência da API legada `RawKeyboard` está isolada no activator porque
`KeyEvent` não expõe as flags nativas necessárias neste caso.

## Validação

- Falha e correção reproduzidas ao vivo em uma aba isolada com `cat`, usando
  CGEvents equivalentes aos do OpenLess, sem executar o texto inserido.
- Colagem confirmada mesmo com restauração do clipboard após 750 ms.
- Usuário confirmou a transcrição real do OpenLess na instância corrigida.
- Três testes em `test/core/terminal/macos_paste_activator_test.dart` cobrem
  Command sem tecla física, exclusão de teclas/combinações e limite de plataforma.

Não é necessário instalar uma integração por harness: o texto entra na mesma
sessão PTY usada pelo teclado e pela colagem normal do Cockpit.
