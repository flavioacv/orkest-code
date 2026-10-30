# Orkest — bairro vivo

Laboratório local na branch `feat/office-city-3d-lab`, PR #9. Cidade planejada com cenários distintos, biblioteca de assets e empresas que aparecem dinamicamente. O Office atual do aplicativo não é alterado.

```sh
node cockpit/tool/office_city/prepare.mjs
node cockpit/tool/office_city/server.mjs
node --test cockpit/tool/office_city/*.test.mjs
```

Abra http://127.0.0.1:4175. O preparador aceita o caminho do `city-copy` como primeiro argumento. Usa Three.js já instalado naquele projeto e a arte já existente em `cockpit/assets/sprites`; não instala pacotes.

## Organização da cidade

`scene-plan.js` declara nove lotes sem sobreposição. A avenida circular tem curvas contínuas, conectadas às ruas internas; calçadas, faixas e travessias acompanham a mesma malha viária. Não há distribuição aleatória de prédios nem objetos empilhados em uma galeria. Lotes ainda sem empresa ficam arborizados, sem placas ou quadrados vazios de reserva.

- Distrito de empresas: três posições de expansão, inicialmente uma empresa.
- Praça: jardim, caminho sinuoso, fonte, pérgola e assentos.
- Café: prédio próprio, toldo e terraço com peças do Studio.
- Biblioteca/galeria: fachada cívica, colunas e terraço.
- Vila residencial: telhado inclinado, chaminé e jardim.
- Mercado: expositores e bicicletário.
- Obra: estrutura, tapumes e guindaste original animado.

As empresas têm três volumetrias diferentes. A vista geral mantém todas as fachadas e coberturas. O interior só abre quando a câmera se aproxima do prédio; volta a fechar ao afastar, com histerese para evitar piscar no limite. Não abre automaticamente apenas porque um personagem entrou. O prédio continua no mesmo lote e as paredes de fundo permanecem como enquadramento.

O escritório contém estações distintas, circulação livre, sala de reunião, lounge, estante, rack e café. Mesas de trabalho e cadeiras foram construídas como kits próprios, inspirados no Office existente, sem duplicar os bancos já embutidos na mesa de reunião do catálogo. O percurso do personagem atravessa a porta e termina em sua própria estação, sem atravessar tampos.

## Trânsito e pessoas

Cinco modelos procedurais originais — sedan, hatch, SUV, van e ônibus — percorrem um circuito fechado, com orientação corrigida pela dimensão longitudinal das malhas, cores distintas e espaçamento constante. A bicicleta original percorre uma faixa interna do circuito com um ciclista. Pausar/Continuar afeta trânsito, guindaste e entrada do personagem.

Oito aparências usam cores e nomes de partes encontrados em `third_party/office_engine/shared/world/appearance-flat.ts` e `shared/appearance.ts`: bob, curly, bun, side_part, ponytail, spiky, afro e buzz; óculos, fones, brincos e boné. As geometrias de cabelo/acessórios são interpretações 3D próprias. Triângulos de cabelo originais são removidos antes de aplicar as novas peças, evitando cabelo sobreposto. Não é conversão automática do sprite para 3D. A pose sentada adapta localmente a malha neutra do Studio; não é uma pose recuperada da referência.

Clique em uma pessoa na lista para aproximar e pausar a cena para inspeção. Oito perfis têm penteados e tons de pele distintos. A versão atual ainda não oferece editor completo de aparência.

## Empresas dinâmicas

O formulário cria e remove empresas no próprio bairro, com persistência local. IDs são únicos, nomes são validados e os lotes arborizados dão lugar aos prédios. O limite de três é capacidade deste protótipo, não regra de negócio do produto.

Ponte pública disponível para uma integração futura:

```js
window.orkestCity.setCompanies([
  {id: 'project-1', name: 'Empresa A'},
  {id: 'project-2', name: 'Empresa B'},
]);
window.orkestCity.getCompanies();
window.orkestCity.focusCompany('project-1');
```

A ponte ainda não recebe os projetos/sessões reais da IDE. Dados e movimentos são demonstrativos. O roteiro de entrada e o trânsito são determinísticos, sem pathfinding geral, regras de prioridade ou simulação de acidentes.

## Biblioteca unificada

O botão **Assets unificados** abre busca com filtros, miniaturas de PNGs e links aos originais. Studio continua acessível separadamente para prévia de suas geometrias. `generated/unified-assets.json` reúne:

| Origem | Conteúdo |
| --- | --- |
| Studio | 571 entradas: 569 disponíveis e duas indisponíveis, preservando IDs e origem |
| Orkest | Sete famílias de modelos próprios |
| Aparência Habbo | Oito perfis 3D com referência às paletas/partes pixel art |
| Acervo pixel art | 12.991 PNGs, 12.591 conteúdos únicos, 400 cópias idênticas consolidadas por SHA-256 |

São 13.177 entradas únicas, das quais 13.175 disponíveis. Variantes visuais diferentes são mantidas: deduplicar conteúdo idêntico não elimina orientações ou cores de sprites. Os PNGs são indexados e servidos em leitura; não são copiados novamente nem apresentados como malhas 3D. A cena usa uma seleção do catálogo, não milhares de modelos ao mesmo tempo.

O inventário do `city-copy` mantém 162 arquivos de projeto com hashes, excluindo node_modules/.git. `src` fornece o renderizador próprio; `study` contém os módulos capturados e procedência; `third-party` contém a licença Three, sem modelos adicionais; `reference` e JSONs da raiz são evidências, não meshes importáveis.

`generated/` é ignorado pelo Git. Fontes do Studio e sprites existentes não são modificados. Licença do material específico CityRT continua indeterminada: uso local de estudo. Prédios completos gerados no servidor e quatro packs binários continuam ausentes; não foram inventados substitutos apresentados como originais.

## Estrutura

- `prepare.mjs`, `pixel-inventory.mjs`, `asset-registry.js`: preparação, hashes, deduplicação e procedência.
- `scene-plan.js`: lotes, perfis, colocações únicas, validação de empresas e circuito de trânsito.
- `district.js`: cidade, arquitetura e kits de interiores.
- `catalog-assets.js`: adaptação geométrica entre runtimes Three, sem alterar fontes capturadas.
- `character-style.js`: cabelos e acessórios 3D próprios.
- `walk-cycle.js`: percurso de entrada.
- `main.js`: interação, câmera, empresas, navegação e animação.
- `server.mjs`: servidor loopback e acesso restrito aos modelos/sprites.

## Validação e limites

Nove testes Node passam: lotes/corredores, continuidade do circuito incluindo curvas e fechamento, entradas de empresas, catálogo único e paletas, percurso sem atravessar mesas, caminhos do servidor, hashes, sprites/deduplicação e passagem pela porta. Verificações de sintaxe e `git diff --check` passam.

Chrome real, com capturas inspecionadas:

- `ev_0b3cc88089a8a966db9c52507070f6367b064cb1ecf8a8bbd07201d07f067151`: criar três empresas, remover todas, recriar uma, abrir interior, navegar sete destinos, fechar fachadas na cidade e observar avanço do tráfego.
- `ev_5fcce13bcdaa15662a5f04300de9eebe681607dd89eceff5baec93c7d636306f`: biblioteca, busca por Office chair e miniaturas reais, sem falhas de imagens.
- `ev_06c95c16a9540802d00635244cef3ab0f6f88c1c4b21d51f48fdb1a3c4b21ddf`: interior final, chegada à estação e pausa.
- `ev_c14da9c589e72f6643c4b747aa064f4e988c240a83101a066f3ea5ce4122b475`: aparência afro, aproximação e pausa.

Zero page-errors nos cenários. Permanecem o aviso de duas versões Three.js carregadas e quatro 404 dos packs opcionais ausentes durante a inicialização dos veículos; os geradores procedurais funcionam. Não há benchmark GPU/FPS, integração Flutter, simulação urbana completa ou substituição do Office atual.
