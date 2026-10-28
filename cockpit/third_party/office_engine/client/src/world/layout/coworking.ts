import { COL_W, ROOM_H, SOUTH_Y, TILE } from '../constants';
import { AreaBuilder } from './builder';
import { CORE_WALLS, LOUNGE_ID, layoutLounge } from './core';
import type { AreaLayout } from './types';

/** Individual workstations use the original desks/chairs, without a meeting set. */
export function layoutCoworking(): AreaLayout {
  const b = new AreaBuilder('core:coworking', 'lounge', { x: 2 * COL_W, y: 0, w: 16, h: ROOM_H });
  const wall = CORE_WALLS.glass;
  b.floor('wood', 0, 0, 16, 12, 801);
  b.face(.5, 15, wall); b.cap(0, 0, .5, 12, wall); b.cap(15.5, 0, .5, 12, wall);
  b.wall('sign', 8); b.south(.5, 15, 11, wall, [{ lx: 7, w: 2 }]);
  b.walk(1, 2, 14, 9); b.walk(7, 11, 2, 1);
  b.area.door = { x: b.x0 + 7, y: 11, w: 2, h: 1 };
  for (const x of [3, 7, 11]) {
    b.furn('desk', x, 4);
    b.seat('armchair', 'office_chair', x, 5, 'up', 'black', { dx: TILE / 2 });
  }
  b.furn('bookshelf', 2, 8); b.furn('plant_tall', 13, 9, 'monstera');
  b.spot('shelf', 2, 9, 'up');
  return b.build();
}

/** Navigation tile and native-PNG seat coordinate for every cushion in the set. */
export const COWORKING_SEATS = [
  [25, 4, 'down', 48, 23], [26, 4, 'down', 80, 23], [28, 4, 'down', 112, 23], [29, 4, 'down', 144, 23],
  [24, 6, 'right', 16, 82],
  [30, 6, 'left', 176, 82],
  [24, 9, 'up', 24, 112], [25, 9, 'up', 48, 112], [29, 9, 'up', 144, 112], [30, 9, 'up', 168, 112],
] as const;

/** One continuous room preserves the original leisure area and adds the shared set. */
export function layoutCoworkingLounge(): AreaLayout {
  const area = layoutLounge();
  const width = COL_W + 16;
  const right = new AreaBuilder('core:lounge:shared', 'lounge', { x: COL_W, y: SOUTH_Y, w: width, h: ROOM_H });
  const wall = CORE_WALLS.lounge;
  area.rect.w = width;
  area.floors[0].w = width * TILE;
  area.walls = area.walls.filter(w => !(w.kind === 'cap' && w.x > COL_W * TILE));
  const south = area.walls.find(w => w.kind === 'south'); if (south) south.w = (width - 1) * TILE;
  right.face(15.5, width - 16, wall, [{ lx: 25, w: 3 }]);
  right.cap(width - .5, 0, .5, 12, wall);
  right.walk(15, 2, width - 16, 9); right.walk(25, 0, 3, 2);
  const set = right.furn('coworking_set', 24, 5);
  right.block(24, 3, 7, 1); right.block(23, 6, 1, 3); right.block(31, 6, 1, 3);
  right.block(25, 6, 1, 2); right.block(29, 6, 1, 2);
  for (const [tx, ty, dir, x, y] of COWORKING_SEATS) {
    right.spot('sofa', tx, ty, dir, { seated: true, furnitureId: set,
      x: right.px(27) + (x - 96) * .7,
      y: right.py(9) + (y - 128) * .7 + 3,
      sortY: right.py(9) + (y - 128) * .7 + 4,
    });
  }
  right.seat('beanbag', 'beanbag', 17, 10, 'up', 'green');
  right.seat('beanbag', 'beanbag', 19, 10, 'up', 'red');
  right.furn('bookshelf', 33, 2); right.furn('plant_tall', 34, 10, 'monstera');
  right.spot('talk', 18, 7, 'right', { group: 'lounge:shared' });
  right.spot('talk', 19, 7, 'left', { group: 'lounge:shared' });
  const addition = right.build();
  for (const spot of addition.spots) spot.areaId = LOUNGE_ID;
  area.walls.push(...addition.walls); area.furniture.push(...addition.furniture);
  area.spots.push(...addition.spots); area.walkable.push(...addition.walkable);
  (area.blocked ??= []).push(...(addition.blocked ?? []));
  return area;
}
