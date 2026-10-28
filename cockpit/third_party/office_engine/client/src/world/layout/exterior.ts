// Área externa: grama, árvores, calçada e rua; pátio/jardim nos slots sem sala.
import type { WallStyle } from '../../art/api';
import { mulberry32 } from '../../../../shared/hash';
import type { ExteriorSeason } from '../api';
import { BUILDING_H, COL_W, CORE_COLS, CORRIDOR_Y, EXT_EAST, EXT_NORTH, EXT_SOUTH, EXT_WEST, SOUTH_Y, TILE } from '../constants';
import { cellRect, slotAt, slotColumn, slotSide } from './geometry';
import type { ExteriorProp, FloorPatch, TileRect, WallItemPlacement, WallSegment } from './types';
import { outdoorLifeLayout, outdoorReserved } from './outdoor-life';

export const EXTERIOR_WALL: WallStyle = { base: '#cfc8bd', trim: '#8a8174', pattern: 'brick', exterior: true };

export interface ExteriorLayout {
  /** Limites da área desenhada (tiles). */
  bounds: TileRect;
  floors: FloorPatch[];
  props: ExteriorProp[];
  /** Faixas da rua (y em px) e sentido (+1 = leste, -1 = oeste). */
  lanes: { y: number; dir: 1 | -1 }[];
  /** Linha central da rua (px), para as faixas tracejadas. */
  streetY: number;
  streetH: number;
}

/** Fechamento do corredor e pátio de um slot sem sala. */
export interface SlotShell {
  slot: number;
  rect: TileRect;
  walls: WallSegment[];
  windows: WallItemPlacement[];
  floors: FloorPatch[];
  props: ExteriorProp[];
}

export function layoutExterior(cols: number, season: ExteriorSeason = 'summer', viewportAspect = 0): ExteriorLayout {
  const w = cols * COL_W;
  const north = CORE_COLS > 2 ? 30 : EXT_NORTH;
  const bounds: TileRect = { x: -EXT_WEST, y: -north, w: w + EXT_WEST + EXT_EAST, h: BUILDING_H + north + (CORE_COLS > 2 ? 64 : EXT_SOUTH) };
  const original = { ...bounds };
  if (CORE_COLS > 2 && Number.isFinite(viewportAspect) && viewportAspect > 0) {
    const width = Math.max(bounds.w, Math.ceil(bounds.h * Math.max(16 / 9, viewportAspect)));
    bounds.x -= (width - bounds.w) / 2;
    bounds.w = width;
  }
  const px = (t: number) => t * TILE;
  const floors: FloorPatch[] = [];
  const props: ExteriorProp[] = [];
  const rng = mulberry32(0xc0de + cols);

  floors.push({ kind: 'grass', x: px(bounds.x), y: px(bounds.y), w: px(bounds.w), h: px(bounds.h), seed: 11, tint: season });
  // calçada em volta do prédio
  const south = BUILDING_H;
  floors.push({ kind: 'sidewalk', x: px(bounds.x), y: px(south + 2), w: px(bounds.w), h: px(2), seed: 12, tint: season });
  floors.push({ kind: 'street', x: px(bounds.x), y: px(south + 4), w: px(bounds.w), h: px(5), seed: 13 });
  floors.push({ kind: 'sidewalk', x: px(bounds.x), y: px(south + 9), w: px(bounds.w), h: px(2), seed: 14, tint: season });
  // caminho de pedra até a calçada, na frente da recepção
  floors.push({ kind: 'sidewalk', x: px(-3), y: px(CORRIDOR_Y), w: px(3), h: px(5), seed: 15, tint: season });
  floors.push({ kind: 'sidewalk', x: px(-3), y: px(CORRIDOR_Y + 5), w: px(2), h: px(south + 2 - CORRIDOR_Y - 5), seed: 16, tint: season });

  // árvores ao norte (fileira com variação) e a oeste/leste
  for (let x = bounds.x + 1; x < bounds.x + bounds.w - 1; x += 4 + Math.floor(rng() * 3)) {
    const tx = px(x) + Math.floor(rng() * 8);
    const ty = px(-3) - Math.floor(rng() * 20);
    props.push({ kind: rng() < 0.25 ? 'pine' : 'tree', x: tx, y: ty, seed: Math.floor(rng() * 1e9) });
    if (rng() < 0.6) props.push({ kind: 'bush', x: px(x + 2), y: px(-1) - 2, seed: Math.floor(rng() * 1e9) });
  }
  // bosque ao norte: fileiras irregulares cada vez mais esparsas
  for (const [row, gap] of [
    [-6, 5],
    [-10, 6],
    [-14, 8],
  ] as const) {
    for (let x = bounds.x + 2; x < bounds.x + bounds.w - 1; x += gap + Math.floor(rng() * 4)) {
      props.push({ kind: rng() < 0.3 ? 'pine' : 'tree', x: px(x) + Math.floor(rng() * 8), y: px(row) - Math.floor(rng() * 12), seed: Math.floor(rng() * 1e9) });
    }
  }
  for (const side of [-1, 1]) {
    for (const band of [0, 7, 13]) {
      const baseX = side < 0 ? -6 - band : w + 4 + band;
      for (let y = 1; y < BUILDING_H; y += 3 + Math.floor(rng() * 3)) {
        if (side < 0 && band === 0 && y >= CORRIDOR_Y - 1 && y <= south + 1) continue;
        props.push({ kind: rng() < 0.3 ? 'pine' : 'tree', x: px(baseX + Math.floor(rng() * 5)), y: px(y + 1), seed: Math.floor(rng() * 1e9) });
        if (band === 0 && rng() < 0.5) props.push({ kind: 'bush', x: px(side < 0 ? -2 : w + 1), y: px(y + 2), seed: Math.floor(rng() * 1e9) });
      }
    }
  }
  // cerca viva + flores ao longo da fachada sul e postes na calçada; diante de cada slot de
  // projeto, o trecho do caminho do jardim só tem cerca quando há sala ali
  for (let x = 0; x < w; x += 2) {
    const col = Math.floor(x / COL_W);
    const lx = x - col * COL_W;
    const gate = col >= CORE_COLS && (lx === 6 || lx === 8) ? slotAt(col, 'south') : undefined;
    props.push({ kind: (x / 2) % 3 === 1 ? 'flowers' : 'hedge', x: px(x) + TILE, y: px(south + 1) + 10, seed: x * 7 + 3, whenRoom: gate });
  }
  for (let x = bounds.x + 4; x < bounds.x + bounds.w; x += 10) {
    props.push({ kind: 'lamp', x: px(x), y: px(south + 3) + 6, seed: x });
  }
  for (const row of (CORE_COLS > 2 ? [13, 17, 21, 47, 53, 59] : [13, 17, 21])) {
    for (let x = bounds.x + 3; x < bounds.x + bounds.w - 2; x += 6 + Math.floor(rng() * 5)) {
      props.push({ kind: rng() < 0.2 ? 'pine' : 'tree', x: px(x) + Math.floor(rng() * 10), y: px(south + row) + Math.floor(rng() * 10), seed: Math.floor(rng() * 1e9) });
      if (rng() < 0.3) props.push({ kind: 'bush', x: px(x + 3), y: px(south + row + 1), seed: Math.floor(rng() * 1e9) });
    }
  }
  props.push({ kind: 'bench', x: px(-4), y: px(CORRIDOR_Y + 3) + 6, seed: 1 });
  // totem com a marca na entrada principal (oeste)
  props.push({ kind: 'totem', x: px(-3) + 6, y: px(CORRIDOR_Y + 1), seed: 2 });

  // Elementos exclusivos da estação externa (sem alterar a semente base das árvores)
  const srng = mulberry32(0x5ea5 + cols * 17);
  if (season === 'autumn') {
    for (let x = bounds.x + 3; x < bounds.x + bounds.w - 3; x += 7 + Math.floor(srng() * 5)) {
      props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: px(x) + Math.floor(srng() * 10), y: px(-2) - Math.floor(srng() * 8), seed: Math.floor(srng() * 1e9) });
      if (srng() < 0.7) {
        props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: px(x) + Math.floor(srng() * 8), y: px(south + 12) + Math.floor(srng() * 16), seed: Math.floor(srng() * 1e9) });
      }
    }
    props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: px(-5), y: px(CORRIDOR_Y + 5), seed: 101 });
    props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: px(w + 2), y: px(CORRIDOR_Y + 2), seed: 102 });
  } else if (season === 'winter') {
    props.push({ kind: 'snowman' as ExteriorProp['kind'], x: px(-5), y: px(CORRIDOR_Y + 2), seed: 201 });
    props.push({ kind: 'snowman' as ExteriorProp['kind'], x: px(Math.max(4, Math.floor(w * 0.35))), y: px(-2) - 4, seed: 202 });
    props.push({ kind: 'snowman' as ExteriorProp['kind'], x: px(Math.max(10, Math.floor(w * 0.72))), y: px(south + 12) + 6, seed: 203 });
    for (let x = bounds.x + 4; x < bounds.x + bounds.w - 4; x += 9 + Math.floor(srng() * 5)) {
      props.push({ kind: 'snowdrift' as ExteriorProp['kind'], x: px(x), y: px(-2) - Math.floor(srng() * 10), seed: Math.floor(srng() * 1e9) });
      if (srng() < 0.65) {
        props.push({ kind: 'snowdrift' as ExteriorProp['kind'], x: px(x + 2), y: px(south + 12) + Math.floor(srng() * 12), seed: Math.floor(srng() * 1e9) });
      }
    }
  } else if (season === 'spring') {
    for (let x = bounds.x + 4; x < bounds.x + bounds.w - 4; x += 8 + Math.floor(srng() * 5)) {
      props.push({ kind: 'flowers', x: px(x), y: px(-2) + 4, seed: Math.floor(srng() * 1e9) });
      if (srng() < 0.65) {
        props.push({ kind: 'flowers', x: px(x + 2), y: px(south + 12) + 2, seed: Math.floor(srng() * 1e9) });
      }
    }
  }

  // Extend the landscape rather than exposing a flat canvas around the existing scene.
  for (let x = bounds.x + 2; x < bounds.x + bounds.w - 2; x += 5) {
    if (x >= original.x && x <= original.x + original.w) continue;
    for (let y = bounds.y + 3; y < bounds.y + bounds.h - 2; y += 6) {
      if (y >= south + 1 && y <= south + 12) continue;
      if (Math.abs(y - (south + 43)) < 4) continue;
      props.push({ kind: rng() < .3 ? 'pine' : 'tree', x: px(x) + Math.floor(rng() * 24), y: px(y) + Math.floor(rng() * 24), seed: Math.floor(rng() * 1e9) });
      if (rng() < .25) props.push({ kind: 'bush', x: px(x + 2), y: px(y + 1), seed: Math.floor(rng() * 1e9) });
    }
  }

  if (CORE_COLS > 2) {
    const life = outdoorLifeLayout(cols);
    // Clear walking paths and points of interest before adding the curated objects.
    for (let i = props.length - 1; i >= 0; i--) {
      if (props[i].kind !== 'lamp' && outdoorReserved(props[i].x, props[i].y, life, 64)) props.splice(i, 1);
    }
    for (const prop of life.props) {
      if (prop.kind === 'station_track') props.push({ ...prop, x: px(bounds.x + bounds.w / 2), seed: px(bounds.w) });
      else if (prop.kind === 'train') props.push({ ...prop, seed: px(bounds.w) });
      else props.push(prop);
    }
    // Keep the walking routes readable at night without flooding the surrounding woods.
    const lamp = (x: number, y: number) => props.push({ kind: 'lamp', x, y, seed: Math.round(x * 7 + y) });
    for (let x = bounds.x + 4; x < bounds.x + bounds.w - 2; x += 10) lamp(px(x), px(south + 10.5));
    for (let x = life.garden.x - 200; x <= life.fountain.x + 200; x += 128) lamp(x, life.garden.y + 102);
    for (let x = life.station.x - 320; x <= life.station.x + 320; x += 128) lamp(x, life.station.y - 40);
    for (let y = px(south + 14); y < life.fountain.y - 180; y += 96) lamp(life.fountain.x + 36, y);
    for (let y = life.garden.y + 160; y < life.station.y - 128; y += 112) lamp(life.station.x + 48, y);
    lamp(life.fountain.x - 190, life.fountain.y - 160);
    lamp(life.fountain.x + 190, life.fountain.y - 160);
    lamp(life.camp.x - 120, life.camp.y + 44);
    lamp(life.pond.x + 64, life.pond.y + 44);
    lamp(px(-2), px(CORRIDOR_Y + 5));
    // A shared promenade links the market, fountain plaza and a centered station approach.
    floors.push({ kind: 'sidewalk', x: life.garden.x - 230, y: life.garden.y + 62, w: life.fountain.x - life.garden.x + 475, h: 48, seed: 904, tint: season });
    floors.push({ kind: 'sidewalk', x: life.fountain.x - 216, y: life.fountain.y - 216, w: 432, h: 280, seed: 905, tint: season });
    floors.push({ kind: 'sidewalk', x: life.station.x - 360, y: life.station.y - 128, w: 720, h: 96, seed: 906, tint: season });
    floors.push({ kind: 'sidewalk', x: life.station.x - 32, y: life.garden.y + 110, w: 64, h: life.station.y - 238 - life.garden.y, seed: 907, tint: season });
    props.push({ kind: 'duck' as ExteriorProp['kind'], x: px(2 * COL_W + 18), y: px(7), seed: 903 });
    floors.push({ kind: 'sidewalk', x: life.fountain.x - 24, y: px(south + 11), w: 48, h: life.fountain.y - 216 - px(south + 11), seed: 908, tint: season });

  }
  const streetY = px(south + 4);
  const streetH = px(5);
  return {
    bounds,
    floors,
    props,
    lanes: [
      { y: streetY + Math.round(streetH * 0.36), dir: 1 },
      { y: streetY + Math.round(streetH * 0.86), dir: -1 },
    ],
    streetY,
    streetH,
  };
}

/** Parede externa + jardim de um slot vazio: deck de madeira com mesas e guarda-sóis, canteiros e caminho. */
export function slotShell(slot: number, lastColumn: boolean, season: ExteriorSeason = 'summer'): SlotShell {
  const col = slotColumn(slot);
  const side = slotSide(slot);
  const rect = cellRect(col, side);
  const x0 = rect.x * TILE;
  const rng = mulberry32(0x9a7d + slot * 31);
  const walls: WallSegment[] = [];
  const windows: WallItemPlacement[] = [];
  const floors: FloorPatch[] = [];
  const props: ExteriorProp[] = [];
  const W = COL_W * TILE;
  const T = (n: number) => n * TILE;
  const seed = () => Math.floor(rng() * 1e9);
  /** Deck de madeira com borda de pedra (tiles locais). */
  const deck = (lx: number, ly: number, w: number, h: number) => {
    floors.push({ kind: 'sidewalk', x: x0 + T(lx), y: T(rect.y + ly), w: T(w), h: T(h), seed: slot + 7, tint: season });
    floors.push({ kind: 'wood', x: x0 + T(lx) + 4, y: T(rect.y + ly) + 4, w: T(w) - 8, h: T(h) - 8, seed: slot + 8 });
  };

  if (side === 'north') {
    // fachada com janelas fechando o corredor (linhas 10–11)
    const fy = (CORRIDOR_Y - 2) * TILE;
    walls.push({ kind: 'face', x: x0, y: fy, w: W, style: EXTERIOR_WALL });
    [3, 8, 13].forEach((cx, i) =>
      windows.push({ id: `shell:${slot}:janela${i}`, kind: 'window', cx: x0 + cx * TILE, baseY: CORRIDOR_Y * TILE, on: 'face', order: 0 }),
    );
    if (lastColumn) walls.push({ kind: 'cap', x: x0 + W - TILE / 2, y: fy, w: TILE / 2, h: 2 * TILE, style: EXTERIOR_WALL });
    // caminho do gramado até o deck, deck no meio e canteiros sob as janelas
    floors.push({ kind: 'sidewalk', x: x0 + T(7), y: T(rect.y), w: T(2), h: T(3), seed: slot, tint: season });
    deck(3, 3, 10, 5);
    props.push({ kind: 'parasol', x: x0 + T(5.5), y: T(rect.y + 6) + 4, seed: seed(), slot });
    props.push({ kind: 'parasol', x: x0 + T(10.5), y: T(rect.y + 6) + 4, seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(3.5), y: T(rect.y + 3) + 6, seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(12.5), y: T(rect.y + 3) + 6, seed: seed(), slot });
    for (const cx of [3, 8, 13]) props.push({ kind: 'flowers', x: x0 + T(cx), y: T(rect.y + 9) + 12, seed: slot * 3 + cx, slot });
    props.push({ kind: 'tree', x: x0 + T(1) + 4, y: T(rect.y + 3), seed: seed(), slot });
    props.push({ kind: rng() < 0.5 ? 'pine' : 'tree', x: x0 + T(15) - 4, y: T(rect.y + 3) + 6, seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(1) + 8, y: T(rect.y + 8), seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(15) - 8, y: T(rect.y + 8), seed: seed(), slot });
    if (season === 'autumn') {
      props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: x0 + T(2.2), y: T(rect.y + 5.5), seed: slot + 41, slot });
    } else if (season === 'winter') {
      props.push({ kind: (slot % 2 === 0 ? 'snowman' : 'snowdrift') as ExteriorProp['kind'], x: x0 + T(2.2), y: T(rect.y + 5.5), seed: slot + 51, slot });
    }
  } else {
    // mureta externa fechando o corredor (linha 17) e jardim abaixo, ligado à calçada da rua
    walls.push({ kind: 'south', x: x0, y: SOUTH_Y * TILE, w: W, style: EXTERIOR_WALL });
    if (lastColumn) walls.push({ kind: 'cap', x: x0 + W - TILE / 2, y: SOUTH_Y * TILE, w: TILE / 2, h: TILE, style: EXTERIOR_WALL });
    floors.push({ kind: 'sidewalk', x: x0 + T(7), y: T(rect.y + 1), w: T(2), h: T(rect.h - 1), seed: slot, tint: season });
    // trecho entre a fachada e a calçada: só existe enquanto o slot está vazio (a cerca viva fecha)
    props.push({ kind: 'paving', x: x0 + T(7), y: T(BUILDING_H), seed: slot, slot });
    deck(3, 3.5, 10, 5);
    props.push({ kind: 'parasol', x: x0 + T(5.5), y: T(rect.y + 6.5) + 4, seed: seed(), slot });
    props.push({ kind: 'parasol', x: x0 + T(10.5), y: T(rect.y + 6.5) + 4, seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(3.5), y: T(rect.y + 4) + 4, seed: seed(), slot });
    props.push({ kind: 'bush', x: x0 + T(12.5), y: T(rect.y + 4) + 4, seed: seed(), slot });
    for (const cx of [3, 13]) props.push({ kind: 'flowers', x: x0 + T(cx), y: T(rect.y + 2), seed: slot * 3 + cx, slot });
    props.push({ kind: 'bench', x: x0 + T(4), y: T(rect.y + 10) + 6, seed: slot, slot });
    props.push({ kind: 'bench', x: x0 + T(12), y: T(rect.y + 10) + 6, seed: slot + 1, slot });
    props.push({ kind: 'tree', x: x0 + T(1) + 6, y: T(rect.y + 11), seed: seed(), slot });
    props.push({ kind: rng() < 0.5 ? 'pine' : 'tree', x: x0 + T(15) - 6, y: T(rect.y + 11) + 4, seed: seed(), slot });
    props.push({ kind: 'rock', x: x0 + T(14), y: T(rect.y + 2) + 4, seed: slot + 3, slot });
    if (season === 'autumn') {
      props.push({ kind: 'leaf_pile' as ExteriorProp['kind'], x: x0 + T(2.2), y: T(rect.y + 9.2), seed: slot + 61, slot });
    } else if (season === 'winter') {
      props.push({ kind: (slot % 2 === 1 ? 'snowman' : 'snowdrift') as ExteriorProp['kind'], x: x0 + T(2.2), y: T(rect.y + 9.2), seed: slot + 71, slot });
    }
  }
  return { slot, rect, walls, windows, floors, props };
}
