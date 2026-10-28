import { FURNITURE, TILE, type FurnitureSprites, type Sprite } from '../../third_party/office_engine/client/src/art/api.ts';
import type { Renderer } from '../../third_party/office_engine/client/src/world/render/renderer.ts';
import type { OrkestSim } from './sim.ts';
import { COWORKING_SEATS } from '../../third_party/office_engine/client/src/world/layout/coworking.ts';
import { catalog } from './sprite_assets/catalog.ts';
import { loadExterior, loadRaster, scaledSprite } from './sprite_assets/exterior.ts';

type Scales = { vegetation: number; vehicles: number; furniture: number };
const defaults: Scales = { vegetation: 70, vehicles: 50, furniture: 70 };

/** The same installation is used by the actual Office and its browser preview. */
export async function installSpriteMix(renderer: Renderer, sim: OrkestSim, onFurnitureScale?: (percent: number) => void): Promise<() => void> {
  const [exterior, rasters] = await Promise.all([
    loadExterior(), Promise.all(catalog.map(entry => loadRaster(entry))),
  ]);
  const scales = { ...defaults };
  const previousExterior = renderer.exteriorSprites;
  const previousFurniture = renderer.furnitureOverride;
  renderer.exteriorSprites = exterior;
  exterior.setScales(scales.vegetation, scales.vehicles, scales.furniture);
  onFurnitureScale?.(scales.furniture);
  const cache = new Map<string, FurnitureSprites>();

  function alignSeats() {
    const factor = scales.furniture / 100;
    const anchors: Partial<Record<keyof typeof FURNITURE, { index: number; points: readonly (readonly [number, number])[] }>> = {
      coworking_set: { index: 27, points: COWORKING_SEATS.map(seat => [seat[3], seat[4]] as const) },
    };
    for (const area of sim.building.core) for (const f of area.furniture) {
      const anchor = anchors[f.kind]; if (!anchor) continue;
      const source = rasters[anchor.index].canvas;
      const footprint = FURNITURE[f.kind].footprint;
      const ax = (f.tx + footprint.w / 2) * TILE + (f.dx ?? 0);
      const ay = (f.ty + footprint.h) * TILE + (f.dy ?? 0);
      const seats = area.spots.filter(spot => spot.furnitureId === f.id && spot.seated);
      seats.forEach((spot, index) => {
        const point = anchor.points[index]; if (!point) return;
        spot.x = ax + (point[0] - source.width / 2) * factor;
        spot.y = ay + (point[1] - source.height) * factor + 3;
        spot.sortY = spot.y + 1;
        for (const ch of sim.chars.values()) if (ch.atSpot === spot.id && ch.seated) {
          ch.x = spot.x; ch.y = spot.y; ch.sortY = spot.sortY;
        }
      });
    }
  }
  alignSeats();


  function furniture(index: number): FurnitureSprites {
    const key = String(index);
    const hit = cache.get(key); if (hit) return hit;
    const base: Sprite = scaledSprite(rasters[index], scales.furniture);
    const result: FurnitureSprites = { base };
    if (scales.furniture > 0) {
      const front = document.createElement('canvas'); front.width = base.canvas.width; front.height = base.canvas.height;
      const ctx = front.getContext('2d')!, top = Math.floor(front.height * .88);
      ctx.drawImage(base.canvas, 0, top, front.width, front.height - top, 0, top, front.width, front.height - top);
      result.front = { canvas: front, ax: base.ax, ay: base.ay };
    }
    cache.set(key, result); return result;
  }
  // Only the accepted coworking set replaces interior art; every other item uses Habblaud.
  renderer.furnitureOverride = f => f.kind === 'coworking_set' ? furniture(27) : null;

  return () => {
    cache.clear(); renderer.exteriorSprites = previousExterior; renderer.furnitureOverride = previousFurniture;
  };
}
