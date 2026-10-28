# Office: ambientes integrados

Na pasta `cockpit`, execute:

```sh
node tool/office_world/sprite_preview/serve.mjs
```

Abra http://127.0.0.1:4318. `PORT` permite escolher outra porta. O servidor
reutiliza esbuild instalado neste checkout ou no principal, sem baixar pacotes.
A página importa o `main.ts` real do Office e fornece duas salas e seis sessões
de exemplo. O cenário é o mesmo da WebView, sem um ambiente paralelo.

## Interiores

As salas usam novamente mesas, monitores, cadeiras, arquivos, estantes, sofás e
mesas de centro originais do Habblaud. O único override de mobiliário interno é
o conjunto de convivência `Coworking Area (Set)_696c72_0759c`.

Lounge e coworking são uma área contínua de 36×12 tiles, com piso, circulação e
paredes compartilhados. Mantêm TV, pingue-pongue, fliperamas e assentos originais.
O conjunto novo tem dez lugares calibrados: quatro no sofá superior, um em cada
lateral e quatro nos trechos inferiores. Com os assentos originais há vinte
lugares no lounge. Todos usam A*, reservas individuais e as poses do motor.
A antiga sala de reunião/cabines foi substituída por três mesas individuais com
móveis originais. O perfil legado do exportador raster continua preservado.

**Ir ao coworking** enquadra a sala unificada. **Mesa individual**, **Poltrona**
e **Coworking** enviam um personagem existente para um assento por 30 segundos.
**Ocupar assentos** envia os personagens disponíveis ao lounge, com reservas
separadas, por até 60 segundos. **Encerrar teste** libera as reservas. Eventos
reais das sessões cancelam o teste correspondente; os lugares de trabalho
originais dos personagens são preservados.

## Exterior

Vegetação e veículos usam os PNGs novos, sem nave e com velocidades de rua
preservadas. Há acampamento, rio com ponte, lago de carpas, jardim amarelo,
vendedores na calçada e no jardim, praça da fonte, bosque e estação ferroviária.
A barraca e a fonte pequena da lateral oeste foram removidas. A estátua e a
barraca entre os prédios também foram removidas.

Barracas modernas mantêm sempre a orientação frontal, inclusive quando campistas
entram e saem: não alternam entre imagens de perspectivas diferentes. A seleção
usa amarelo, laranja, branco, preto e verdes; não usa roxos. O rio tem margens
curvas e continua até o limite norte; substitui o lago retangular anterior.

Há 24 rotas ambientais com a arte original dos personagens: pedestres,
campistas, vendedores, clientes, visitantes, lenhador e cuidador do bosque.
As figuras não representam sessões de terminal. Há animações de machado/cavacos,
atendimento e ferramentas de jardinagem, com frames em cache. Campistas passam
algum tempo dentro das barracas, ficando ocultos no interior.

Os trilhos atravessam toda a largura externa. O trem acelera ao sair, retorna,
para na mesma plataforma e repete a viagem para o outro lado. A inversão de
sentido ocorre fora da área visível. Plataforma, passeio central e praça são
conectados. O seletor **Visitar exterior** oferece os pontos de interesse.

## Escalas e estações

Os três sliders independentes vão de 0 a 100: vegetação, veículos e móveis novos.
100% representa os pixels de origem dos sprites; 0% oculta a categoria nova.
Os padrões são 70/50/70, persistidos em localStorage. **Restaurar padrão** redefine
os três. No interior, a escala dos móveis afeta somente o conjunto coworking;
no exterior ela controla os decorativos. Trilhos e rio mantêm sua extensão no
mapa enquanto a espessura acompanha a escala. Trem/ônibus seguem a de veículos.

As quatro estações usam as opções reais do motor. No inverno há casacos, calças,
gorros, bebidas quentes, respiração, neve nos contornos e na grama do jardim e
aparência de gelo na água. Patos, filhotes, gansos e galinha deixam a área exposta.
No outono há suéteres e ancinho; primavera/verão usam regador; inverno usa pá.
As aparências base dos personagens permanecem preservadas.

## Validação e integração

28 testes cobrem a simulação, conectividade dos assentos, preservação do perfil
legado, uso concorrente por uma sala cheia, roupas/percursos sazonais e ida/volta
do trem. Chrome também verificou vinte pessoas sentadas simultaneamente,
retorno do trem à mesma posição nos dois sentidos e ausência de exceções.
Capturas dos móveis originais, coworking, barracas, rio e inverno foram inspecionadas.

`node tool/office_world/build.mjs` regenera `assets/office_world/engine.js` e o
exportador nativo. Recriar a WebView/app carrega o bundle novo; esta integração
não altera o renderer Flutter nativo do Linux nem recompila o aplicativo instalado.
O servidor escuta somente em localhost; encerre com Ctrl+C.

O inventário completo de todas as pastas de sprites continua para uma etapa
posterior, conforme solicitado. O catálogo aqui contém a seleção usada no teste.
