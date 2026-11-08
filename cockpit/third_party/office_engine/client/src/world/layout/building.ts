// Montagem do prédio: núcleo + corredor + salas de projeto -> grade de caminhabilidade e spots.
import { FURNITURE } from '../../art/api';
import { UNIFIED_COWORKING, BUILDING_H, COL_W, CORE_COLS, TILE } from '../constants';
import { BLOCKED, FREE, SEAT, WalkGrid } from '../path/grid';
import { furnitureBlocks, furnitureIsSeat } from './builder';
import { layoutCafe, layoutLounge, layoutReception, layoutRestroom } from './core';
import { layoutCorridor } from './corridor';
import { layoutCoworking, layoutCoworkingLounge } from './coworking';
import { coworkingAreas, coworkingScene } from './floor-plan';
import { buildingRect } from './geometry';
import type { AreaLayout, SpotDef, TileRect } from './types';

export interface BuildingLayout {
  cols: number;
  rect: TileRect;
  core: AreaLayout[];
  corridor: AreaLayout;
  rooms: AreaLayout[];
  grid: WalkGrid;
  spots: SpotDef[];
}

let coreCache: AreaLayout[] | null = null;
let coreCacheProfile = '';

/** Áreas fixas do núcleo (calculadas uma vez). */
export function coreAreas(): AreaLayout[] {
  const profile = `${COL_W}:${CORE_COLS}:${BUILDING_H}`;
  if (!coreCache || coreCacheProfile !== profile) {
    coreCache = [layoutReception(), layoutRestroom(), layoutCafe(), CORE_COLS > 2 ? layoutCoworkingLounge() : layoutLounge()];
    if (CORE_COLS > 2) coreCache.push(layoutCoworking());
    coreCacheProfile = profile;
  }
  return coreCache;
}

/** Marca na grade as células caminháveis de uma área, os bloqueios e os assentos. */
export function paintArea(grid: WalkGrid, area: AreaLayout): void {
  for (const r of area.walkable) grid.fill(r.x, r.y, r.w, r.h, FREE);
  for (const r of area.blocked ?? []) grid.fill(r.x, r.y, r.w, r.h, BLOCKED);
  for (const f of area.furniture) {
    const def = FURNITURE[f.kind];
    if (def.mount !== 'floor') continue;
    const { w, h } = def.footprint;
    if (furnitureBlocks(f.kind)) grid.fill(f.tx, f.ty, w, h, BLOCKED);
    else if (furnitureIsSeat(f.kind)) {
      for (let y = f.ty; y < f.ty + h; y++) for (let x = f.tx; x < f.tx + w; x++) if (grid.get(x, y) === FREE) grid.set(x, y, SEAT);
    }
  }
}

export function buildWalkGrid(cols: number, areas: readonly AreaLayout[], version = 0): WalkGrid {
  const grid = new WalkGrid(cols * COL_W, BUILDING_H, version);
  for (const a of areas) paintArea(grid, a);
  return grid;
}

export function assembleBuilding(cols: number, rooms: readonly AreaLayout[], version = 0): BuildingLayout {
  if (UNIFIED_COWORKING) {
    const core = coworkingAreas(cols);
    const corridor: AreaLayout = { id: 'core:corredor', kind: 'corridor', rect: buildingRect(cols), floors: [], rugs: [], walls: [], wallItems: [], furniture: [], spots: [], walkable: [] };
    const grid = new WalkGrid(cols * COL_W, BUILDING_H, version);
    // Unified objects already register their scaled footprints; legacy sprite sizes do not apply.
    for (const area of core) for (const r of area.walkable) grid.fill(r.x, r.y, r.w, r.h, FREE);
    for (const area of core) for (const r of area.blocked ?? []) grid.fill(r.x, r.y, r.w, r.h, BLOCKED);
    const spots = core.flatMap(area => area.spots);
    const seatObjects = new Set(spots.filter(s => s.seated).map(s => s.furnitureId));
    // The complete scaled chair/sofa footprint has seat cost, so routes avoid cutting through it.
    for (const node of coworkingScene(cols).objects) if (seatObjects.has(node.id)) {
      for (let ty = Math.floor(node.y / TILE); ty < Math.ceil((node.y + node.h) / TILE); ty++) {
        for (let tx = Math.floor(node.x / TILE); tx < Math.ceil((node.x + node.w) / TILE); tx++) {
          if (grid.get(tx, ty) === FREE) grid.set(tx, ty, SEAT);
        }
      }
    }
    // Seat approaches never erase physical furniture or wall collisions.
    for (const spot of spots) if (spot.seated && grid.get(spot.tx, spot.ty) === FREE) grid.set(spot.tx, spot.ty, SEAT);
    return { cols, rect: buildingRect(cols), core, corridor, rooms: [...rooms], grid, spots };
  }
  const core = coreAreas();
  const corridor = layoutCorridor(cols);
  const all = [...core, corridor, ...rooms];
  const grid = buildWalkGrid(cols, all, version);
  const spots: SpotDef[] = [];
  for (const a of all) spots.push(...a.spots);
  return { cols, rect: buildingRect(cols), core, corridor, rooms: [...rooms], grid, spots };
}
