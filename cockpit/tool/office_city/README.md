# Orkest — bairro vivo

Laboratório local na branch `feat/office-city-3d-lab`, PR #9. Cidade planejada com cenários distintos, biblioteca de assets e empresas que aparecem dinamicamente. O Office atual do aplicativo não é alterado.

```sh
node cockpit/tool/office_city/prepare.mjs
node cockpit/tool/office_city/server.mjs
node --test cockpit/tool/office_city/*.test.mjs
```

Abra http://127.0.0.1:4175. O preparador aceita o caminho do `city-copy` como primeiro argumento. Usa Three.js já instalado naquele projeto e a arte já existente em `cockpit/assets/sprites`; não instala pacotes.

## Organização da cidade

`scene-plan.js` declara nove lotes centrais sem sobreposição. O mapa completo é retangular, com 220 × 116 unidades, incluindo quarteirões periféricos, parque ampliado e bosques. A avenida circular tem curvas contínuas, conectadas às ruas internas; calçadas, faixas e travessias acompanham a mesma malha viária. Não há distribuição aleatória de prédios nem objetos empilhados em uma galeria. Frentes comerciais ocupam os lotes de expansão até uma empresa ser criada; fachadas, coberturas, varandas e alturas variam. Vegetação instanciada forma bosques e sombra no parque.

- Distrito de empresas: três posições de expansão, inicialmente uma empresa.
- Praça: jardim, caminho sinuoso, fonte, pérgola e assentos.
- Café: prédio próprio, toldo e terraço com peças do Studio.
- Biblioteca/galeria: fachada cívica, colunas e terraço.
- Vila residencial: telhado inclinado, chaminé e jardim.
- Mercado: expositores e bicicletário.
- Obra: estrutura, tapumes e guindaste original animado.

As empresas têm fachadas e coberturas próprias, com altura correspondente aos níveis realmente construídos. O restante da cidade usa sobrados, lojas no térreo, apartamentos, galpões e edifícios cívicos com variações de dois a cinco pavimentos. A vista geral mantém todas as fachadas e coberturas. O interior só abre quando a câmera se aproxima do prédio; volta a fechar ao afastar, com histerese para evitar piscar no limite. Não abre automaticamente apenas porque um personagem entrou. O prédio continua no mesmo lote e as paredes de fundo permanecem como enquadramento.

O escritório contém estações distintas, circulação livre, sala de reunião, lounge, estante, rack e café. Mesas de trabalho e cadeiras foram construídas como kits próprios, inspirados no Office existente, sem duplicar os bancos já embutidos na mesa de reunião do catálogo. O percurso do personagem atravessa a porta e termina em sua própria estação, sem atravessar tampos.

## Trânsito e pessoas

Cinco modelos procedurais originais — sedan, hatch, SUV, van e ônibus — percorrem as avenidas e ruas centrais, com orientação corrigida pela dimensão longitudinal das malhas e cores distintas. A bicicleta original percorre uma faixa interna do circuito com um ciclista. Viatura e ambulância são adaptações locais dos geradores originais e circulam no anel do parque. Dezoito pedestres seguem rotas ambientais e seis vendedores ocupam a feira, além das figuras anteriores do bairro. O parque inclui lago, píer, fonte, canteiros, brinquedos do catálogo e quadra; os bosques possuem mais de 250 árvores com variação de forma e escala. Pausar/Continuar afeta trânsito, guindaste e entrada do personagem.

Oito aparências usam cores e nomes de partes encontrados em `third_party/office_engine/shared/world/appearance-flat.ts` e `shared/appearance.ts`: bob, curly, bun, side_part, ponytail, spiky, afro e buzz; óculos, fones, brincos e boné. As geometrias de cabelo/acessórios são interpretações 3D próprias. Triângulos de cabelo originais são removidos antes de aplicar as novas peças, evitando cabelo sobreposto. Não é conversão automática do sprite para 3D. A pose sentada adapta localmente a malha neutra do Studio; não é uma pose recuperada da referência.

Clique em uma pessoa na lista para aproximar e pausar a cena para inspeção. Oito perfis têm penteados e tons de pele distintos. A versão atual ainda não oferece editor completo de aparência.

## Empresas dinâmicas

O formulário cria e remove empresas no próprio bairro, com persistência local. IDs são únicos, nomes são validados e os lotes arborizados dão lugar aos prédios. O limite de três empresas e 64 agentes por empresa é capacidade deste protótipo, não regra de negócio do produto. Oito agentes ocupam oito mesas no primeiro escritório. O térreo tem recepção e dois banheiros; o nível seguinte tem cafeteria e convívio. Portanto, a sede já começa com três pavimentos. O nono agente acrescenta um piso de trabalho, totalizando quatro; dezessete usam três pisos de trabalho, totalizando cinco. O seletor de andares permite inspecionar recepção, cafeteria e cada escritório. Ao crescer, os agentes existentes conservam IDs e estações; ao reduzir, somente os excedentes e pisos desnecessários são removidos. Há escadas modeladas e conexões semânticas de elevador; a entrada demonstrativa oculta o personagem durante o transporte, sem fazê-lo caminhar no ar.

Ponte pública disponível para uma integração futura:

```js
window.orkestCity.setCompanies([
  {id: 'project-1', name: 'Empresa A', agentCount: 8},
  {id: 'project-2', name: 'Empresa B', agentCount: 17},
]);
window.orkestCity.getCompanies();
window.orkestCity.focusCompany('project-1');
window.orkestCity.setAgents('project-1', 9);
window.orkestCity.getInteractionMap('project-1');
```

Também é possível fornecer uma lista `agents: [{id, name}]` por empresa; IDs repetidos entre empresas são rejeitados. A ponte ainda não recebe os projetos/sessões reais da IDE. [ENGINE-ADAPTATION.md](ENGINE-ADAPTATION.md) documenta a adaptação de OrkestSim, incluindo ociosidade, reservas, estados, áreas comuns e navegação entre andares. O motor original não foi substituído e suas rotinas ainda não dirigem os personagens deste laboratório. Dados e movimentos são demonstrativos. O roteiro de entrada e o trânsito são determinísticos, sem pathfinding geral, regras de prioridade ou simulação de acidentes.

## Biblioteca unificada

O botão **Assets unificados** abre busca com filtros, miniaturas de PNGs e links aos originais. Studio continua acessível separadamente para prévia de suas geometrias. `generated/unified-assets.json` reúne:

| Origem | Conteúdo |
| --- | --- |
| Studio | 571 entradas: 569 disponíveis e duas indisponíveis, preservando IDs e origem |
| Orkest | Doze famílias de modelos/adaptações locais |
| Aparência Habbo | Oito perfis 3D com referência às paletas/partes pixel art |
| Acervo pixel art | 12.991 PNGs, 12.591 conteúdos únicos, 400 cópias idênticas consolidadas por SHA-256 |

São 13.182 entradas únicas, das quais 13.180 disponíveis. Variantes visuais diferentes são mantidas: deduplicar conteúdo idêntico não elimina orientações ou cores de sprites. Os PNGs são indexados e servidos em leitura; não são copiados novamente nem apresentados como malhas 3D. A cena usa uma seleção do catálogo, não milhares de modelos ao mesmo tempo.

O inventário do `city-copy` mantém 162 arquivos de projeto com hashes, excluindo node_modules/.git. `src` fornece o renderizador próprio; `study` contém os módulos capturados e procedência; `third-party` contém a licença Three, sem modelos adicionais; `reference` e JSONs da raiz são evidências, não meshes importáveis.

`generated/` é ignorado pelo Git. Fontes do Studio e sprites existentes não são modificados. Licença do material específico CityRT continua indeterminada: uso local de estudo. Prédios completos gerados no servidor e quatro packs binários continuam ausentes; não foram inventados substitutos apresentados como originais.

## Estrutura

- `prepare.mjs`, `pixel-inventory.mjs`, `asset-registry.js`: preparação, hashes, deduplicação e procedência.
- `scene-plan.js`: lotes, perfis, colocações únicas, validação de empresas e circuito de trânsito.
- `district.js`, `urban-building.js`: cidade e fachadas instanciadas.
- `office-plan.js`, `office-building.js`: alocação de agentes, capacidade, áreas comuns e construção vertical.
- `life-plan.js`, `city-life.js`: mapa ampliado, pedestres, floresta, lazer, feira e veículos de serviço.
- `interaction-map.js`: pontos semânticos para a futura projeção do motor, sem outro planejador de comportamento.
- `catalog-assets.js`: adaptação geométrica entre runtimes Three, sem alterar fontes capturadas.
- `character-style.js`: cabelos e acessórios 3D próprios.
- `walk-cycle.js`: percurso de entrada.
- `main.js`: interação, câmera, empresas, navegação e animação.
- `server.mjs`: servidor loopback e acesso restrito aos modelos/sprites.

## Validação e limites

Dezesseis testes Node passam: lotes/corredores, continuidade dos circuitos, crescimento e redução de equipe, identidade global dos agentes, catálogo e paletas, rota sem atravessar mesas, servidor e hashes, deduplicação de PNGs, limites/vegetação do mapa, caminhos de pedestres, portais e recursos semânticos, entrada sem flutuar e transporte oculto. Casos de capacidade incluem 0, 1, 8, 9, 16, 17 e 64 agentes. Sintaxe JavaScript e `git diff --check` passam.

Chrome real:

- `ev_b8ef39e9dec4afa2238bd558611ead2a2dedcdfe25f3177304a01c8598087de5`: oito agentes em três pavimentos, nove em quatro, dezessete em cinco; troca de andares e ocupação correta (oito no piso completo e um no novo piso); cafeteria inspecionada.
- `ev_7d0feb0d3e72aab102a3a6fff694559ce178a6609a641dca8873b74a5e9621e2`: parque/lago, feira, brinquedos do catálogo e pedestres, captura inspecionada.
- `ev_2b28222cf6098736c4d971838787a391b3cc8f02cd5b87a5687800312448f807`: mapa retangular, edifícios variados e sede com altura inicial maior, captura inspecionada (antes do ajuste final de escala dos brinquedos).

As primeiras capturas em modo launch concluíram as ações, mas tiveram timeout ao confirmar o encerramento do navegador; os resultados posteriores acima usaram CDP em navegador de teste isolado e desconectaram corretamente. Zero page-errors nos cenários aprovados. Persistem o aviso de duas versões Three.js e quatro 404 dos packs opcionais ausentes durante a inicialização dos veículos; os geradores procedurais funcionam.

Não há benchmark GPU/FPS, integração Flutter ou ligação completa às rotinas ociosas/sessões reais. Polícia, ambulância, vendedores e pedestres são ambientação, sem simulação de ocorrências. Os pesos e a lógica de comportamento do motor original não foram alterados. O Office atual continua intacto.
