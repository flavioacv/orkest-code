// Editable objects own their collision footprints and cardinal seat anchors.
import { FURNITURE, type Dir, type FurnitureKind } from '../../art/api';
import { BUILDING_H, COL_W, TILE } from '../constants';
import { AreaBuilder } from './builder';
import type { AreaLayout, SpotKind } from './types';

export const PLAN = { x: 48, y: 51, w: 1456, h: 944, width: 1280, height: 832, insertX: 1210, southInsertX: 924, southY: 678 } as const;
export const ACTOR_SCALE = 2;
export const planX = (x: number): number => Math.round((x - PLAN.x) * PLAN.width / PLAN.w);
export const planY = (y: number): number => Math.round((y - PLAN.y) * PLAN.height / PLAN.h);
export const expansionWidth = (cols: number): number => Math.max(0, cols - 4) * COL_W * TILE;
export type ObjectShape = 'sprite' | 'wall' | 'glass' | 'counter' | 'bench' | 'monitor' | 'slats' | 'pastry' | 'pool' | 'foosball' | 'display' | 'hygiene';
export interface SceneRect { x: number; y: number; w: number; h: number; }
export interface CoworkingObject extends SceneRect {
  id: string; areaId: string; shape: ObjectShape; depth: number; scale: number;
  kind?: FurnitureKind; variant?: string; color?: string; label?: string;
  collision?: SceneRect; seatIds: string[];
}
export interface CoworkingScene { objects: CoworkingObject[]; areas: AreaLayout[]; }
const scenes = new Map<number, CoworkingScene>();
export function benchPatches(cols: number): { dx: number }[] {
  return Array.from({ length: Math.max(0, cols - 4) }, (_, i) => ({ dx: planX(PLAN.insertX) + i * COL_W * TILE - planX(860) }));
}

export function coworkingScene(cols: number): CoworkingScene {
  const cached = scenes.get(cols); if (cached) return cached;
  const extra = expansionWidth(cols), objects: CoworkingObject[] = [];
  const hall = new AreaBuilder('core:floor-plan', 'corridor', { x: 0, y: 0, w: cols * COL_W, h: BUILDING_H });
  hall.walk(1, 2, cols * COL_W - 2, BUILDING_H - 3);
  const areas: AreaLayout[] = [hall.area];
  const zone = (id: string, kind: AreaLayout['kind']) => {
    const b = new AreaBuilder(id, kind, hall.area.rect); areas.push(b.area); return b;
  };
  const px = (x: number, y: number, dx = 0) => planX(x) + dx + (x >= (y >= PLAN.southY ? PLAN.southInsertX : PLAN.insertX) ? extra : 0);
  const block = (b: AreaBuilder, r: SceneRect) => {
    const tx = Math.floor(r.x / TILE), ty = Math.floor(r.y / TILE);
    b.block(tx, ty, Math.ceil((r.x + r.w) / TILE) - tx, Math.ceil((r.y + r.h) / TILE) - ty);
  };
  const object = (b: AreaBuilder, shape: ObjectShape, x: number, y: number, w: number, h: number,
    opts: { color?: string; label?: string; solid?: boolean; dx?: number } = {}) => {
    const totalW = cols * COL_W * TILE;
    const r = { x: px(x, y, opts.dx), y: planY(y), w: Math.round(w * PLAN.width / PLAN.w), h: Math.round(h * PLAN.height / PLAN.h) };
    if (shape === 'wall') {
      if (w === 1447) {
        r.w = totalW - r.x;
        if (y === 51) r.y = 0;
        else if (y === 966) r.y = PLAN.height - r.h;
      } else if (x === 1480) {
        r.x = totalW - r.w;
        r.h = PLAN.height - r.y;
      } else if (x === 49 && y === 680) {
        r.h = PLAN.height - 18 - r.y;
      }
    }
    const node: CoworkingObject = { ...r, id: `${b.area.id}:object:${objects.length}`, areaId: b.area.id, shape,
      scale: ACTOR_SCALE, depth: r.y + r.h, color: opts.color, label: opts.label, seatIds: [] };
    if (opts.solid !== false) {
      // In the 3/4 view the elevated tabletop overhangs its floor contact footprint.
      node.collision = shape === 'bench' ? { ...r, y: r.y + 16, h: Math.max(1, r.h - 16) } : { ...r };
      block(b, node.collision);
    }
    objects.push(node); return node;
  };
  // Native sprites use a bottom-centre anchor, including the separate chair back layer.
  const sprite = (b: AreaBuilder, kind: FurnitureKind, x: number, base: number, variant?: string, solid = true, dx = 0) => {
    const def = FURNITURE[kind], ax = px(x, base, dx), ay = planY(base);
    const scale = kind === 'toilet_stall' ? 1.5 : ACTOR_SCALE;
    const w = def.footprint.w * TILE * scale, h = def.footprint.h * TILE * scale;
    const id = b.furn(kind, Math.floor((ax - w / 2) / TILE), Math.floor((ay - h) / TILE), variant);
    const node: CoworkingObject = { id, areaId: b.area.id, shape: 'sprite', kind, variant,
      x: ax - w / 2, y: ay - h, w, h, scale, depth: ay, seatIds: [] };
    if (solid) { node.collision = { x: node.x, y: node.y, w, h }; block(b, node.collision); }
    objects.push(node); return node;
  };
  const interaction = (b: AreaBuilder, kind: SpotKind, x: number, y: number, dir: Dir, node?: CoworkingObject) => {
    const fx = px(x, y), fy = planY(y);
    const s = b.spot(kind, Math.floor(fx / TILE), Math.floor(fy / TILE), dir, { x: fx, y: fy, furnitureId: node?.id });
    node?.seatIds.push(s.id); return s;
  };
  const seat = (b: AreaBuilder, kind: SpotKind, x: number, base: number, dir: Dir,
    furniture: FurnitureKind, variant: string = dir, dx = 0, parent?: CoworkingObject, offset = 0) => {
    const node = parent ?? sprite(b, furniture, x, base, variant, false, dx);
    const fx = node.x + node.w / 2 + offset, fy = node.y + node.h - 3 * ACTOR_SCALE;
    const approachX = fx + (dir === 'left' ? 12 : dir === 'right' ? -12 : 0);
    const approachY = fy + (furniture === 'stool' ? 0 : dir === 'up' ? 12 : dir === 'down' ? -12 : 0);
    const s = b.spot(kind, Math.floor(approachX / TILE), Math.floor(approachY / TILE), dir,
      { x: fx, y: fy, seated: true, furnitureId: node.id, sortY: node.depth + .25 });
    node.seatIds.push(s.id); return s;
  };
  const plant = (b: AreaBuilder, x: number, y: number, dx = 0) => {
    const variants = ['palm', 'ficus', 'monstera', 'bonsai'];
    return sprite(b, 'plant_tall', x, y, variants[(Math.floor(x / 31) + Math.floor(y / 23)) % variants.length], true, dx);
  };
  const reception = zone('core:recepcao', 'reception');
  // The west doors retain the arrival protocol; the enclosing walls have physical footprints.
  object(reception, 'wall', 49, 51, 1447, 17);
  object(reception, 'wall', 49, 51, 14, 345);
  object(reception, 'wall', 49, 680, 14, 300);
  object(reception, 'wall', 1480, 51, 16, 930);
  object(reception, 'wall', 49, 966, 1447, 18);
  object(reception, 'wall', 496, 51, 118, 313);
  object(reception, 'slats', 65, 70, 426, 100, { label: 'Coworking' });
  object(reception, 'counter', 160, 210, 265, 48);
  for (const x of [259, 340]) object(reception, 'monitor', x - 16, 194, 32, 24, { solid: false }).depth = planY(258) + 1;
  interaction(reception, 'elevator', 91, 425, 'right').group = 'elevator:0';
  interaction(reception, 'elevator', 91, 598, 'right').group = 'elevator:1';
  seat(reception, 'armchair', 193, 352, 'right', 'armchair');
  seat(reception, 'armchair', 346, 352, 'left', 'armchair');
  sprite(reception, 'cafe_table', 269, 349);
  seat(reception, 'beanbag', 241, 510, 'down', 'beanbag', 'yellow');
  seat(reception, 'beanbag', 285, 589, 'up', 'beanbag', 'blue');
  sprite(reception, 'coffee_table', 300, 553);
  sprite(reception, 'bookshelf', 180, 626);
  interaction(reception, 'shelf', 230, 640, 'up');
  for (const [x, y] of [[89, 193], [465, 198], [83, 333], [466, 336], [327, 476], [109, 697]]) plant(reception, x, y);
  sprite(reception, 'floor_lamp', 273, 487);
  const window = sprite(reception, 'window', 555, 340, undefined, false);
  window.depth = planY(364) + 1;
  interaction(reception, 'window', 555, 390, 'up', window);
  const cabinet = sprite(reception, 'filing_cabinet', 405, 691);
  sprite(reception, 'printer', 405, 674, undefined, false).depth = cabinet.depth + 1;

  const cafe = zone('core:copa', 'cafe');
  object(cafe, 'wall', 615, 68, 590, 20);
  const kitchenCounter = sprite(cafe, 'counter', 712, 171, 'drawers');
  sprite(cafe, 'microwave', 712, 149, undefined, false).depth = kitchenCounter.depth + 1;
  for (const [kind, x, spotKind] of [['fridge', 650, 'fridge'], ['counter_sink', 770, 'sink'],
    ['coffee_machine', 817, 'coffee'], ['coffee_machine', 861, 'coffee'], ['vending_machine', 927, 'snack'], ['water_cooler', 973, 'water']] as const) {
    const node = sprite(cafe, kind, x, 171); interaction(cafe, spotKind, x, 195, 'up', node);
  }
  object(cafe, 'counter', 879, 210, 239, 46);
  object(cafe, 'pastry', 1018, 133, 101, 67);
  for (const x of [926, 969, 1012, 1055, 1098]) seat(cafe, 'cafe_seat', x, 299, 'up', 'stool', '').group = 'cafe:bar';
  for (const [x, y] of [[700, 293], [843, 322], [1008, 349]]) {
    sprite(cafe, 'cafe_table', x, y);
    seat(cafe, 'cafe_seat', x - 49, y, 'right', 'cafe_chair').group = `cafe:bistro:${x}`;
    seat(cafe, 'cafe_seat', x + 49, y, 'left', 'cafe_chair').group = `cafe:bistro:${x}`;
    seat(cafe, 'cafe_seat', x, y + 47, 'up', 'cafe_chair').group = `cafe:bistro:${x}`;
  }
  plant(cafe, 1172, 199); plant(cafe, 1168, 350);
  const focus = zone('core:focus', 'lounge');
  object(focus, 'wall', 1214, 69, 272, 35);
  for (const x of [1250, 1324, 1398]) {
    object(focus, 'wall', x - 30, 134, 7, 149, { color: '#3b3552' });
    object(focus, 'slats', x - 23, 137, 58, 47, { color: '#4d3b47' });
    object(focus, 'counter', x - 20, 201, 48, 24);
    seat(focus, 'armchair', x + 4, 266, 'up', 'office_chair', 'black');
  }
  sprite(focus, 'bookshelf', 1461, 282);
  interaction(focus, 'shelf', 1461, 309, 'up');
  const meeting = zone('core:meeting', 'lounge');
  object(meeting, 'glass', 1252, 354, 231, 10);
  object(meeting, 'glass', 1252, 354, 7, 272);
  object(meeting, 'glass', 1477, 354, 7, 272);
  object(meeting, 'glass', 1252, 626, 84, 8);
  object(meeting, 'glass', 1414, 626, 70, 8);
  object(meeting, 'display', 1324, 399, 96, 50, { solid: false, label: 'stats' });
  object(meeting, 'bench', 1315, 492, 120, 52);
  for (const x of [1334, 1375, 1416]) {
    seat(meeting, 'armchair', x, 510, 'down', 'office_chair_front', 'black');
    seat(meeting, 'armchair', x, 577, 'up', 'office_chair', 'black');
  }
  plant(meeting, 1287, 420); plant(meeting, 1450, 420);
  const restroom = zone('core:banheiros', 'restroom');
  for (const [x, y, w, h] of [[65, 704, 169, 8], [298, 704, 186, 8], [65, 704, 8, 260], [476, 704, 8, 260]]) object(restroom, 'wall', x, y, w, h);
  // Bloqueia a passagem atrás das pias/espelhos e a brecha entre a pia 1 e a parede esquerda
  block(restroom, { x: px(65, 704), y: planY(704), w: planX(236) - planX(65), h: planY(765) - planY(704) });
  block(restroom, { x: px(65, 704), y: planY(704), w: planX(108) - planX(65), h: planY(795) - planY(704) });
  for (const x of [125, 173, 221]) {
    sprite(restroom, 'mirror', x, 753, undefined, false);
    const sink = sprite(restroom, 'sink', x, 791);
    interaction(restroom, 'sink', x, 815, 'up', sink).group = 'mirror:vanity';
  }
  object(restroom, 'hygiene', 80, 738, 24, 48, { solid: false });
  // Lixeira posicionada no canto oeste do banheiro (junto à parede), liberando totalmente o corredor central da porta
  sprite(restroom, 'trash_bin', 88, 846);
  sprite(restroom, 'clock', 269, 741, undefined, false);
  for (const x of [325, 386, 447]) {
    const stall = sprite(restroom, 'toilet_stall', x, 803); interaction(restroom, 'stall', x, 827, 'up', stall);
  }
  const wcBench = sprite(restroom, 'bench', 171, 935, undefined, false);
  for (const offset of [-16, 16]) seat(restroom, 'bench', 0, 0, 'down', 'bench', '', 0, wcBench, offset);
  plant(restroom, 97, 936); plant(restroom, 426, 947);
  const lounge = zone('core:lounge', 'lounge');
  const sofa = sprite(lounge, 'sofa', 713, 794, 'down', false);
  for (const offset of [-24, 0, 24]) seat(lounge, 'sofa', 0, 0, 'down', 'sofa', 'down', 0, sofa, offset).group = 'screen:tv';
  sprite(lounge, 'coffee_table', 714, 850);
  seat(lounge, 'armchair', 637, 899, 'right', 'armchair').group = 'screen:tv';
  seat(lounge, 'armchair', 803, 899, 'left', 'armchair').group = 'screen:tv';
  object(lounge, 'display', 671, 932, 87, 30, { solid: false, label: 'social-tv' });
  plant(lounge, 574, 766); plant(lounge, 855, 814);
  sprite(lounge, 'floor_lamp', 603, 870);
  const games = zone('core:games', 'lounge');
  const pingpong = sprite(games, 'pingpong_table', 1058, 795);
  interaction(games, 'pingpong', 975, 785, 'right', pingpong).group = 'pingpong:arena';
  interaction(games, 'pingpong', 1142, 785, 'left', pingpong).group = 'pingpong:arena';
  for (const x of [995, 1058, 1120]) interaction(games, 'watch', x, 711, 'down');
  object(games, 'pool', 959, 826, 95, 103);
  object(games, 'foosball', 1096, 846, 95, 72);
  const arcade = sprite(games, 'arcade', 1204, 826); interaction(games, 'arcade', 1204, 852, 'up', arcade);
  const secondArcade = sprite(games, 'arcade', 1250, 826); interaction(games, 'arcade', 1250, 852, 'up', secondArcade);
  object(games, 'display', 1335, 736, 123, 76, { label: 'game' });
  const gameSofa = sprite(games, 'sofa', 1384, 888, 'up', false);
  for (const offset of [-24, 0, 24]) seat(games, 'sofa', 0, 0, 'up', 'sofa', 'up', 0, gameSofa, offset).group = 'screen:videogame';
  for (const [x, y, color] of [[1268, 892, 'blue'], [1319, 926, 'yellow'], [1440, 929, 'red']] as const) {
    seat(games, 'beanbag', x, y, 'up', 'beanbag', color).group = 'screen:videogame';
  }
  interaction(games, 'talk', 940, 865, 'right').group = 'talk:pool';
  interaction(games, 'talk', 1080, 810, 'left').group = 'talk:pool';
  interaction(games, 'talk', 1071, 911, 'right').group = 'talk:foosball';
  interaction(games, 'talk', 1203, 911, 'left').group = 'talk:foosball';
  plant(games, 1470, 952); plant(games, 946, 777);
  const desks = zone('core:coworking', 'lounge');
  const island = (xs: readonly number[], y: number, dx = 0) => {
    const table = object(desks, 'bench', xs[0] - 55, y + 18, xs[xs.length - 1] - xs[0] + 110, 44, { dx });
    for (const x of xs) {
      for (const [base, dir] of [[y + 37, 'down'], [y + 92, 'up']] as const) {
        const s = seat(desks, 'desk', x, base, dir, dir === 'up' ? 'office_chair' : 'office_chair_front', 'black', dx);
        s.rank = desks.area.spots.length; s.side = dir === 'up' ? 'S' : 'N';
      }
      object(desks, 'monitor', x - 17, y + 19, 34, 24, { dx, solid: false }).depth = table.depth + 1;
      sprite(desks, 'plant_small', x + 31, y + 40, ['succulent', 'fern', 'flower'][(x + y) % 3], false, dx).depth = table.depth + 2;
    }
    plant(desks, xs[0] - 83, y + 77, dx); plant(desks, xs[xs.length - 1] + 78, y + 77, dx);
  };
  for (const y of [428, 553]) { island([521, 638], y); island([980, 1051, 1120], y); }
  for (const patch of benchPatches(cols)) for (const y of [428, 553]) island([980, 1051, 1120], y, patch.dx);
  plant(desks, 818, 587);
  const scene = { objects, areas }; scenes.set(cols, scene); return scene;
}
export function coworkingAreas(cols: number): AreaLayout[] { return coworkingScene(cols).areas; }
