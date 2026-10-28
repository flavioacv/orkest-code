import type { Dir, HeldItem, Pose } from '../../art/api';
import { mulberry32 } from '../../../../shared/hash';
import { BUILDING_H, COL_W, TILE } from '../constants';
import type { ExteriorSeason } from '../api';
import type { ExteriorProp } from './types';

export type OutdoorAction = 'chop' | 'serve' | 'warm' | 'tend';
export interface OutdoorStop {
  x: number; y: number; pause: number; pose: Pose; dir: Dir; held?: HeldItem; seated?: boolean; hidden?: boolean; action?: OutdoorAction;
}
export interface OutdoorRoute {
  id: string; seed: number; speed: number; offset: number; tentSeed?: number; tent?: { x: number; y: number }; stops: readonly OutdoorStop[];
}
export interface OutdoorLifeLayout {
  routes: OutdoorRoute[];
  props: ExteriorProp[];
  clearings: { x: number; y: number; w: number; h: number }[];
  camp: { x: number; y: number };
  pond: { x: number; y: number };
  fountain: { x: number; y: number };
  garden: { x: number; y: number };
  station: { x: number; y: number };
  woodland: { x: number; y: number };
  market: { x: number; y: number };
}
const stop = (x: number, y: number, pause = 0, pose: Pose = 'stand', dir: Dir = 'down', held?: HeldItem): OutdoorStop => ({ x, y, pause, pose, dir, held });

/** Environmental figures never represent terminal sessions or enter the carriageway. */
export function outdoorLifeLayout(cols: number, furnitureScale = 70, season: ExteriorSeason = 'summer'): OutdoorLifeLayout {
  const w = cols * COL_W * TILE;
  const south = BUILDING_H * TILE;
  const camp = { x: Math.round(w * .24 / TILE) * TILE, y: -9 * TILE };
  const pond = { x: Math.round(w * .72 / TILE) * TILE, y: -9 * TILE };
  const fountain = { x: Math.round(w * .6 / TILE) * TILE, y: south + 23 * TILE };
  const garden = { x: Math.round(w * .25 / TILE) * TILE, y: south + 24 * TILE };
  const station = { x: Math.round(w * .5 / TILE) * TILE, y: south + 43 * TILE };
  const woodland = { x: -10 * TILE, y: south + 24 * TILE };
  const market = { x: garden.x, y: garden.y + 56 };
  const factor = furnitureScale / 100;
  const routes: OutdoorRoute[] = [
    { id: 'sidewalk-east', seed: 80, speed: 34, offset: 4, stops: [
      stop(-8 * TILE, south + 3 * TILE, 3, 'stretch'), stop(w + 8 * TILE, south + 3 * TILE, 4, 'read', 'left', 'book'),
    ] },
    { id: 'sidewalk-west', seed: 81, speed: 29, offset: 23, stops: [
      stop(w + 7 * TILE, south + 3.5 * TILE, 3, 'talk', 'left'), stop(-7 * TILE, south + 3.5 * TILE, 4, 'stand', 'right'),
    ] },
    { id: 'sidewalk-south', seed: 82, speed: 31, offset: 11, stops: [
      stop(-6 * TILE, south + 10 * TILE, 3, 'read', 'down', 'book'), stop(w + 6 * TILE, south + 10 * TILE, 4, 'drink', 'left', 'water'),
    ] },
    { id: 'camp-reader', seed: 83, speed: 26, offset: 0, stops: [
      stop(camp.x - 64, camp.y + 48, 12, 'read', 'up', 'book'),
      stop(camp.x + 64, camp.y + 48, 8, 'drink', 'up', 'coffee'),
      stop(camp.x + 64, camp.y + 80, 0), stop(camp.x - 64, camp.y + 80, 5, 'stretch'),
    ] },
    { id: 'pond-observer', seed: 84, speed: 24, offset: 8, stops: [
      stop(pond.x - 128, pond.y + 32, 12, 'stand', 'right'), stop(pond.x + 128, pond.y + 32, 10, 'read', 'up', 'book'),
      stop(pond.x + 128, pond.y + 80), stop(pond.x - 128, pond.y + 80, 4, 'stretch'),
    ] },
    { id: 'station-passenger', seed: 88, speed: 25, offset: 3, stops: [
      stop(station.x + 220, station.y - 90, 14, 'read', 'down', 'book'),
      stop(station.x + 330, station.y - 90, 12, 'stand', 'down'),
    ] },
    { id: 'fountain-visitor', seed: 85, speed: 27, offset: 15, stops: [
      stop(fountain.x - 190, fountain.y + 40, 5, 'drink', 'right', 'water'),
      stop(fountain.x + 190, fountain.y + 40), stop(fountain.x + 190, fountain.y - 160, 12, 'stand', 'left'),
      stop(fountain.x + 190, fountain.y + 40), stop(fountain.x - 190, fountain.y + 40),
      stop(fountain.x - 190, fountain.y - 160, 10, 'read', 'right', 'book'),
    ] },
  ];
  if (factor > 0) {
    const top = { ...stop(garden.x - 32 * factor, garden.y - 105 * factor + 3, 22, 'read', 'down', 'book'), seated: true };
    const bottom = { ...stop(garden.x + 64 * factor, garden.y - 24 * factor + 3, 18, 'talk', 'up'), seated: true };
    routes.push(
      { id: 'garden-reader', seed: 86, speed: 25, offset: 14, stops: [
        stop(garden.x, garden.y + 40), stop(garden.x, garden.y - 60 * factor),
        stop(top.x, garden.y - 60 * factor), top, stop(top.x, garden.y - 60 * factor),
        stop(garden.x, garden.y - 60 * factor),
      ] },
      { id: 'garden-conversation', seed: 87, speed: 24, offset: 4, stops: [
        stop(garden.x + 18, garden.y + 45), stop(garden.x + 18, garden.y - 8),
        stop(bottom.x, garden.y - 8), bottom, stop(bottom.x, garden.y - 8), stop(garden.x + 18, garden.y - 8),
      ] },
    );
  }
  if (factor > 0) {
    for (const [i, tx, ty, tentSeed] of [[0, camp.x + 10, camp.y, 0], [1, camp.x + 10, camp.y - 100, 2], [2, camp.x - 78, camp.y - 100, 1]] as const) {
      const doorY = ty + 10;
      routes.push({ id: `camper-${i}`, seed: 100 + i, speed: 22, offset: i * 11, tentSeed, tent: { x: tx, y: ty }, stops: [
        stop(tx + 44, ty + 34, 5, 'talk', 'left'), stop(tx, ty + 34),
        stop(tx, doorY, 2, 'use', 'up'),
        { ...stop(tx, ty - 24 * factor, 10 + i * 2, 'stand', 'up'), hidden: true },
        stop(tx, doorY, 2, 'stretch'), stop(tx, ty + 34),
        { ...stop(tx + 44, ty + 34, 6, 'drink', 'left', season === 'winter' ? 'coffee' : 'water'), action: season === 'winter' ? 'warm' : undefined },
      ] });
    }
    const cart = { x: garden.x - 140, y: garden.y + 8 };
    const stall = { x: garden.x + 160, y: garden.y + 12 };
    for (const [i, shop] of [cart, stall].entries()) {
      const reach = i === 0 ? 28 : 45;
      routes.push({ id: `vendor-${i}`, seed: 110 + i, speed: 18, offset: i * 4, stops: [
        { ...stop(shop.x + reach, shop.y - 5, 9, 'use', 'left'), action: 'serve' },
        stop(shop.x + reach, shop.y + 16, 3, 'talk', 'left'),
      ] });
      routes.push({ id: `customer-${i}`, seed: 112 + i, speed: 25, offset: i * 7, stops: [
        stop(shop.x + 22, garden.y + 100, 3, 'stand'),
        stop(shop.x + 22, shop.y + 35, 8, 'talk', 'up'),
        stop(shop.x + 22, garden.y + 100, 8, 'drink', 'down', season === 'winter' ? 'coffee' : 'water'),
      ] });
    }
    const streetShop = { x: w + 5 * TILE, y: south + 2.5 * TILE };
    routes.push({ id: 'vendor-street', seed: 115, speed: 18, offset: 2, stops: [
      { ...stop(streetShop.x + 28, streetShop.y, 9, 'use', 'left'), action: 'serve' },
      stop(streetShop.x + 28, streetShop.y + 14, 4, 'talk', 'left'),
    ] });
    routes.push({ id: 'street-customer', seed: 116, speed: 26, offset: 4, stops: [
      stop(streetShop.x + 100, south + 3.5 * TILE, 4, 'drink', 'left', season === 'winter' ? 'coffee' : 'water'),
      stop(streetShop.x + 20, south + 3.5 * TILE, 8, 'talk', 'up'),
    ] });
    routes.push({ id: 'woodcutter', seed: 118, speed: 24, offset: 8, stops: [
      stop(woodland.x - 60, woodland.y + 30, 3, 'stand', 'right'),
      { ...stop(woodland.x - 22, woodland.y + 8, 15, 'use', 'right'), action: 'chop' },
      stop(woodland.x - 60, woodland.y + 30, 5, 'drink', 'right', 'coffee'),
    ] });
    routes.push({ id: 'forest-caretaker', seed: 119, speed: 23, offset: 11, stops: [
      stop(woodland.x + 60, woodland.y + 70, 3, 'stand'),
      { ...stop(woodland.x + 65, woodland.y + 30, 14, 'use', 'right'), action: 'tend' },
    ] });
  }
  for (let i = 0; i < 3; i++) {
    const x = (i + 1) * w / 4;
    const y = station.y + 120 + i % 2 * 60;
    routes.push({ id: `forest-walker-${i}`, seed: 120 + i, speed: 25 + i * 3, offset: i * 17, stops: [
      stop(x - 80, y, 5, season === 'winter' ? 'drink' : 'read', 'right', season === 'winter' ? 'coffee' : 'book'),
      stop(x + 80, y, 4, 'stretch', 'down'), stop(x + 80, y + 36), stop(x - 80, y + 36),
    ] });
  }
  routes.push({ id: 'platform-walker', seed: 125, speed: 28, offset: 17, stops: [
    stop(station.x - 280, station.y - 46, 4, 'stand'), stop(station.x + 280, station.y - 46, 5, 'read', 'down', 'book'),
  ] });
  if (season === 'winter') for (const route of routes) for (const point of route.stops) {
    if (point.pose === 'read' && !point.seated) { point.pose = 'drink'; point.held = 'coffee'; point.action = 'warm'; }
  }
  const clearings = [
    { x: garden.x - 230, y: garden.y - 170, w: 470, h: 320 },
    { x: camp.x - 175, y: camp.y - 210, w: 350, h: 330 },
    { x: pond.x - 115, y: -30 * TILE, w: 230, h: 440 },
    { x: -20 * TILE, y: station.y - 44, w: w + 40 * TILE, h: 100 },
    { x: woodland.x - 110, y: woodland.y - 90, w: 240, h: 220 },
    { x: station.x - 400, y: station.y - 190, w: 800, h: 210 },
    { x: fountain.x - 245, y: fountain.y - 245, w: 490, h: 320 },
  ];
  const props: ExteriorProp[] = [];
  const add = (kind: string, x: number, y: number, seed: number) => props.push({ kind: kind as ExteriorProp['kind'], x, y, seed });
  add('tent_classic', camp.x - 78, camp.y, 1); add('tent', camp.x + 10, camp.y, 0);
  add('tent', camp.x + 98, camp.y, 3);
  add('tent', camp.x - 78, camp.y - 100, 1); add('tent', camp.x + 10, camp.y - 100, 2);
  add('tent', camp.x + 98, camp.y - 100, 4);
  add('garden_set', garden.x, garden.y, 20);
  add('stream_lake', pond.x, pond.y + 20, 4);
  add('tree', pond.x - 115, pond.y - 260, 201); add('pine', pond.x + 115, pond.y - 250, 202);
  add('tree', pond.x - 110, pond.y - 160, 203); add('tree', pond.x + 120, pond.y - 140, 204);
  add('bridge', pond.x + 16, pond.y - 27, 21);
  add('pond', pond.x + 170, pond.y - 22, 22);
  add('rock', pond.x - 152, pond.y - 130, 24); add('rock', pond.x + 152, pond.y - 130, 25);
  add('boulder', pond.x - 150, pond.y - 245, 26);
  add('fountain_large', fountain.x, fountain.y, 5);
  add('duck', pond.x + 5, pond.y - 72, 7);
  for (let i = 0; i < 4; i++) add('duckling', pond.x + i * 7, pond.y - 65 + i % 2 * 5, 10 + i);
  add('goose', pond.x + 20, pond.y - 80, 16);
  add('hen', camp.x - 112, camp.y + 26, 17); add('dove', camp.x + 105, camp.y + 22, 18);
  add('station_track', w / 2, station.y, w + 40 * TILE);
  add('tree', woodland.x - 85, woodland.y - 65, 180);
  add('pine', woodland.x + 85, woodland.y - 65, 181);
  add('tree', woodland.x - 110, woodland.y + 100, 182);
  add('tree', woodland.x + 125, woodland.y + 100, 183);
  add('bush', woodland.x + 100, woodland.y - 20, 184);
  add('stump', woodland.x, woodland.y + 10, 0);
  add('stump', woodland.x + 100, woodland.y + 36, 1);
  add('vendor_cart', w + 5 * TILE, south + 2.5 * TILE, 1);
  add('vendor_cart', garden.x - 140, garden.y + 8, 0);
  add('vendor_stall', garden.x + 160, garden.y + 12, 0);
  add('tent', garden.x - 180, garden.y - 72, 0);
  add('train', station.x, station.y + 12, w + 40 * TILE);
  add('station_shelter', station.x - 190, station.y - 62, 102);
  add('bench', station.x + 150, station.y - 66, 103);
  add('lamp', station.x + 300, station.y - 66, 104);
  const result = { routes, props, clearings, camp, pond, fountain, garden, station, woodland, market };
  const rng = mulberry32(0xb01de + cols);
  for (let i = 0, added = 0; i < 500 && added < Math.min(40, cols * 5 + 12); i++) {
    const x = (-17 * TILE) + rng() * (w + 34 * TILE);
    const y = -14 * TILE + rng() * (south + 59 * TILE);
    if (x > -32 && x < w + 32 && y > -24 && y < south + 24) continue;
    if (y > south + TILE && y < south + 12 * TILE) continue;
    if (outdoorReserved(x, y, result, 64)) continue;
    add(added % 4 === 0 ? 'boulder' : 'rock', Math.round(x), Math.round(y), added + 30); added++;
    if (added % 5 === 0) add('dove', Math.round(x + 18), Math.round(y + 3), added + 90);
  }
  return result;
}

/** Reserve the visitor paths and points of interest when scattering vegetation. */
export function outdoorReserved(x: number, y: number, layout: OutdoorLifeLayout, padding = 48): boolean {
  if (layout.clearings.some(r => x > r.x - padding && x < r.x + r.w + padding && y > r.y - padding && y < r.y + r.h + padding)) return true;
  for (const route of layout.routes) for (let i = 0; i < route.stops.length; i++) {
    const a = route.stops[i], b = route.stops[(i + 1) % route.stops.length];
    if (x >= Math.min(a.x, b.x) - padding && x <= Math.max(a.x, b.x) + padding &&
        y >= Math.min(a.y, b.y) - padding && y <= Math.max(a.y, b.y) + padding) return true;
  }
  return false;
}

export function sampleOutdoorRoute(route: OutdoorRoute, seconds: number): { x: number; y: number; pose: Pose; dir: Dir; held: HeldItem; seated?: boolean; hidden?: boolean; action?: OutdoorAction } {
  const durations = route.stops.map((b, i) => {
    const a = route.stops[(i + route.stops.length - 1) % route.stops.length];
    return Math.hypot(b.x - a.x, b.y - a.y) / route.speed + b.pause;
  });
  const total = durations.reduce((sum, value) => sum + value, 0);
  let t = ((seconds + route.offset) % total + total) % total;
  for (let i = 0; i < route.stops.length; i++) {
    const a = route.stops[(i + route.stops.length - 1) % route.stops.length], b = route.stops[i];
    const travel = durations[i] - b.pause;
    if (t < durations[i]) {
      if (t >= travel || travel === 0) return { ...b, held: b.held ?? 'none' };
      const progress = t / travel;
      const dir = Math.abs(b.x - a.x) >= Math.abs(b.y - a.y) ? (b.x > a.x ? 'right' : 'left') : (b.y > a.y ? 'down' : 'up');
      return { x: a.x + (b.x - a.x) * progress, y: a.y + (b.y - a.y) * progress, pose: 'walk', dir, held: 'none' };
    }
    t -= durations[i];
  }
  return { ...route.stops[0], held: route.stops[0].held ?? 'none' };
}
