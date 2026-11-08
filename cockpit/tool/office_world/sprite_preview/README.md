# Prévia do coworking integrado

Na pasta `cockpit`, execute:

```sh
node tool/office_world/sprite_preview/serve.mjs
```

Abra http://127.0.0.1:4318/. A variável `PORT` permite escolher outra porta.
O servidor reutiliza o esbuild instalado neste checkout ou no checkout principal,
sem baixar pacotes, e escuta somente em localhost.

A prévia importa o `main.ts` real do Office e fornece duas identidades de projeto
com seis sessões de exemplo. O aplicativo macOS/Windows carrega o bundle desse
mesmo entry point em `HabblaudWorldWebView`; a prévia não substitui essa ponte.

O parâmetro `?agents=20` preenche as bancadas iniciais. `?agents=45` exercita a
expansão do salão. O limite de 60 deste parâmetro serve somente à prévia; não é
um limite da capacidade do motor. O seletor de estação e o botão de visão geral
usam as opções e a câmera reais.

## Cena e interações

O salão é montado com objetos e sprites independentes, com colisões e assentos
cardinais. A imagem de referência não é renderizada como fundo. Recepção, leitura,
copa, cabines de foco, reunião, sanitários, lounge e arena mantêm seus pontos de
interação no registro do motor. As bancadas crescem sem criar salas fechadas.

Plantas usam palmeira, ficus, monstera e bonsai, com plantas menores variadas nas
mesas. O banheiro tem espelhos com reflexo animado, pias, cabines, dispensador,
lixeira e relógio. A copa tem equipamentos com estados de uso. Lounge e arena
possuem telas distintas, dois arcades e uma mesa de pingue-pongue. Sinuca e pebolim
são peças decorativas com pontos de conversa.

As oito atividades sociais existentes usam o mesmo `OrkestSim`: TV, videogame,
fliperama, pingue-pongue, copa, conversa, jokenpô e espelho. Reservas, personalidades,
moedas, apostas e retorno ao trabalho continuam no motor. O estado social do
aplicativo permanece associado à identidade da sessão, pela ponte Flutter.

## Validação

```sh
npm run office:test
node tool/office_world/build.mjs
node tool/office_world/webview-smoke.mjs
```

O último comando serve o teste do contrato da WebView em localhost:4322, usando
o bundle de produção e o HTML extraído do loader Flutter. Aguarde o resultado
`passed`; são verificadas identidade social, restauração da carteira, retratos,
confirmação de snapshots, câmera, clique no personagem e fechamento de sessão.
Os snapshots desse teste são fixtures, não terminais reais.

O build atualiza `assets/office_world/engine.js`. Recrie a WebView ou recompile o
aplicativo para carregar o bundle novo. O renderizador Flutter separado do Linux
e o exportador nativo permanecem com o perfil legado.
