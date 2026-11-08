# PROJETO: REPLICAR LAYOUT DO COWORKING UNIFICADO NO ORKEST OFFICE

## OBJETIVO
Substituir o layout atual do Orkest Office por um salão integrado e unificado de aceleradora/coworking, replicando de forma idêntica a planta baixa de pixel art presente em `coworking-floor-plan-referencia.png`.

Consulte os arquivos já presentes neste diretório:
1. `coworking-floor-plan-referencia.png` - Imagem de referência da planta baixa idêntica a ser replicada.
2. `PLANO_COWORKING.md` - Mapeamento detalhado das zonas e especificações técnicas.

---

## DIRETRIZES TÉCNICAS E ARQUITETURAIS

### 1. Salão Único Integrado (Sem salas de projeto fechadas)
- Eliminar o modelo antigo de criar salas de projeto separadas nas colunas externas.
- Todos os agentes trabalham juntos no salão integrado de coworking.
- Caso falte espaço para novos agentes, expandir modularmente as bancadas de coworking face-a-face no salão principal, sem criar salas fechadas.
- Piso unificado de madeira contemporânea fluindo por todo o salão (Recepção, Cafeteria, Coworking, Lounge e Circulação).

### 2. Zonas Idênticas à Planta Baixa de Referência:
1. **Recepção Tech (Topo Esquerdo)**:
   - Balcão comprido com computadores e fundo ripado de madeira escura com logo "Coworking" iluminado.
   - Área de espera com poltronas azuis e canto de leitura circular com estante curva e pufe.
   - Porta de entrada dupla envidraçada na extrema esquerda com tapete `< >`.
2. **Sanitários Reservados (Canto Inferior Esquerdo)**:
   - Único bloco fechado com portas privativas para as cabines, bancada de pias com espelhos modernos iluminados.
3. **Cafeteria Bistrô (Topo Central)**:
   - Bancada gourmet ao fundo (cafeteiras espresso, micro-ondas, geladeira, vending machine).
   - Balcão americano com banquetas amarelas altas e vitrine iluminada de doces/padaria.
   - Mesinhas redondas bistrô com cadeiras amarelas no centro.
4. **Focus Booths & Sala Aquário (Nordeste / Leste)**:
   - 3 a 4 cabines individuais acústicas (*phone booths*) com iluminação quente.
   - Sala de reunião 100% envidraçada (paredes de vidro panorâmico), com mesa de conferência, cadeiras executivas e telão na parede norte.
5. **Ilhas Centrais de Bancadas de Coworking (Coração do Salão)**:
   - Mesas face-a-face com computadores e monitores azuis de código, cadeiras executivas pretas ergonômicas e divisórias de plantas ornamentais entre os módulos.
   - É aqui que os agentes das sessões/terminais sentam e trabalham lado a lado.
6. **Lounge Central (Sul Central)**:
   - Sofá azul de 3 lugares, poltronas de apoio, mesinha de centro sobre tapete grafite e plantas.
7. **Arena Games & Descompressão (Canto Inferior Direito)**:
   - Mesa de sinuca/bilhar verde, mesa de pebolim (totó), fliperama retrô arcade.
   - Telão com videogame e símbolo neon roxo, caixas de som verticais, sofá azul e pufes coloridos.

---

## CÓDIGO-FONTE PRINCIPAL
Os arquivos do motor de escritório estão localizados em:
- `cockpit/third_party/office_engine/client/src/world/layout/core.ts`
- `cockpit/third_party/office_engine/client/src/world/layout/building.ts`
- `cockpit/third_party/office_engine/client/src/world/layout/corridor.ts`
- `cockpit/third_party/office_engine/client/src/world/layout/coworking.ts`
- `cockpit/third_party/office_engine/client/src/art/furniture/`
- `cockpit/third_party/office_engine/client/src/world/constants.ts`

## REQUISITOS DE COMPILAÇÃO E VALIDAÇÃO
Após as alterações:
1. Recompilar o bundle de assets do office engine:
   ```bash
   cd cockpit && node tool/office_world/build.mjs
   ```
2. Executar a suíte de testes para garantir integridade das simulações:
   ```bash
   cd cockpit && npm run office:test
   ```
