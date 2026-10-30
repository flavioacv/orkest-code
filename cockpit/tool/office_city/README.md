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

## Primeiro teste

Cena própria com cidade procedural, escritório em terreno seco, seis estações de trabalho, personagens geométricos próprios estáticos, teto removível, câmera da cidade/escritório e seleção por clique. Os personagens originais continuam no catálogo de estudo, sem misturar os dois runtimes Three.js. Os estados exibidos são demonstrativos, sem ligação às sessões reais.

Validação: dois testes passam (restrições de arquivos do servidor e integridade SHA-256 de todas as cópias src/study). Chrome real carregou a cena e completou os controles teto/cidade/escritório, sem page-errors; favicon ausente gera 404. Evidência REA: ev_19df7e86e30966d9292f0c16c12da0cd8fc9565ad3e706a22d78e04bbc992b6c. Captura visual inspecionada. Não mede FPS/GPU, não valida integração Flutter nem todas as peças do catálogo nesta execução.

Próxima etapa: personagens articulados, animações de escritório e adaptação da ponte de snapshots/callbacks do OrkestCode. A substituição do escritório atual não foi realizada.
