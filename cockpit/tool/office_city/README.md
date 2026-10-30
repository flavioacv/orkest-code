# Office City — laboratório local

Protótipo isolado na branch `feat/office-city-3d-lab`. Não altera o escritório atual.

```sh
node cockpit/tool/office_city/prepare.mjs
node cockpit/tool/office_city/server.mjs
node --test cockpit/tool/office_city/server.test.mjs
```

Abrir http://127.0.0.1:4175. O preparador aceita o caminho do City Studio como primeiro argumento. Requer o Three.js já instalado naquele projeto; não baixa pacotes.

## Revisão das fontes

| Local no city-copy | Resultado e aproveitamento |
| --- | --- |
| src | Renderizador próprio, terreno, edifícios, vegetação, materiais e pós-processamento; reutilizados na cena |
| study | Catálogo de 552 peças, 16 prédios fallback, guindaste, três poses de personagens e cinco veículos; acessível pelo link Catálogo original |
| study/vendor | 115 fontes capturadas e ponte derivada; procedência e hashes preservados |
| third-party | Apenas THREE-LICENSE; não contém outro modelo |
| node_modules/three | Biblioteca oficial e exemplos técnicos, não pacote de cidade ou móveis; dependências gráficas copiadas localmente |
| reference | Imagens, manifesto e auditorias; evidências, não assets 3D importáveis |
| JSONs da raiz | Evidências de captura/análise; inventariadas, não servidas nem incorporadas como modelos |
| scripts, tests e análises Markdown | Ferramentas e registros da pesquisa; inventariados |

`generated/inventory.json` reúne caminhos, tamanho, classificação e SHA-256 dos 162 arquivos de projeto encontrados (exclui node_modules e .git). As cópias locais ficam em generated, ignorado pelo Git, preservando o material capturado para estudo sem publicá-lo no repositório. A licença dos módulos específicos CityRT permanece indeterminada. A origem não é modificada. O preparador não remove arquivos antigos; para inventários de versões diferentes use checkout limpo do laboratório.

“Tércio” não foi identificado como nome de modelo/pasta; foram verificadas as hipóteses third-party e Three.js. Se o termo indica outro projeto, ele ainda precisa ser identificado.

## Cena de escritório e catálogo

O escritório ocupa um prédio próprio compacto de 9 × 9 unidades, em terreno seco. Fachada, porta, janelas e telhado são visíveis por fora; a vista de interior remove as superfícies que bloqueiam a câmera. Um personagem original do catálogo percorre a calçada, atravessa a porta e chega à estação em nove segundos; o interior aparece automaticamente depois da entrada. Repetir entrada reinicia o roteiro; Pausar/Continuar controla a animação. Ver prédio, Ver escritório e Ver obra enquadram os ambientes.

Modelos originais efetivamente utilizados na mesma cena:

| Modelo | Uso |
| --- | --- |
| people.d | Quatro personagens e três poses originais de caminhada |
| y4_table_sh | Mesas de trabalho do catálogo (modelo inclui assentos) |
| y4_luxchair_eu | Cadeiras junto às estações |
| y4_sofa_cp | Sofá |
| y4_planter_mp | Vasos |
| y4_lamp_mp | Luminária |
| y4_bench_mp | Banco externo |
| construction-crane | Guindaste com gerador e atualização originais |
| sedan / van | Veículos procedurais locais |

Os monitores, teclados, edifício e estrutura do canteiro são próprios. `catalog-assets.js` copia posições/normais/cores/índices das geometrias capturadas para o Three.js do renderizador próprio, aplicando a paleta de slots dos personagens. Nenhum objeto do runtime capturado é enviado diretamente ao renderizador próprio. O guindaste usa uma hierarquia espelhada, com transformações sincronizadas ao gerador original. Os módulos capturados permanecem byte a byte intactos e ignorados no Git.

A pose sentada é uma adaptação local da malha neutra original, não uma animação sentada recuperada do catálogo. O roteiro é determinístico, sem IA geral ou pathfinding. Estados demonstrativos ainda não recebem sessões reais. A mesa do catálogo tem aparência de mesa de convivência; ainda não equivale a um conjunto de móveis específico de escritório. A identidade visual pode ser refinada após avaliar esse reaproveitamento.

## Validação

Três testes Node passam: restrição de caminhos do servidor, hashes das cópias src/study e percurso atravessando o vão da porta antes de chegar à estação. Sintaxe JavaScript e `git diff --check` passam. O endpoint `/study/` é mapeado ao catálogo gerado para suportar suas URLs absolutas.

Chrome real completou carregamento, reinício da entrada, chegada à estação, pausa e alternância fachada/interior: REA `ev_6062f8f2492b7079520181cced8f10cf68171acedceb5cafc76edebaf373b1ec`. O enquadramento do guindaste também passou: `ev_b136fc881692965e57199e04622911ec1b24ad986cf6ee67164cec06a78a3016`. Capturas de interior e obra foram inspecionadas. Zero page-errors. Há um aviso esperado por carregar duas versões Three.js, e quatro 404 dos packs binários ausentes que o gerador de veículos tenta carregar; sedan/van procedurais funcionam. Não foram fabricados packs substitutos.

Sem benchmark GPU/FPS, validação Flutter ou integração com terminais. O escritório atual do aplicativo não foi substituído.
