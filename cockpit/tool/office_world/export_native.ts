// Export the original procedural art/layout as native data. No browser, model,
// runtime package or network service is needed by the Flutter renderer.
import { readFile, writeFile } from 'node:fs/promises';
import { deflateSync } from 'node:zlib';
import { FURNITURE } from '../../third_party/office_engine/client/src/art/api.ts';
import { roomTheme } from '../../third_party/office_engine/client/src/art/index.ts';
import { renderFurniture, normalizeFurniture } from '../../third_party/office_engine/client/src/art/furniture/index.ts';
import { renderSeasonalProp } from '../../third_party/office_engine/client/src/art/seasonal.ts';
import { assembleBuilding } from '../../third_party/office_engine/client/src/world/layout/building.ts';
import { layoutProjectRoom } from '../../third_party/office_engine/client/src/world/layout/room.ts';
import { hash32 } from '../../third_party/office_engine/shared/hash.ts';

const atlasW = 1024;
let atlasX = 0, atlasY = 0, rowH = 0;
const images: any[] = [];
const sprites: Record<string, any> = {};
const keys = new Map<string, string>();
function sprite(kind: any, variant: string | undefined, state: number, seed: number) {
  const normalized = normalizeFurniture(kind, variant, state, seed);
  const key = `${kind}:${normalized.variant ?? ''}:${normalized.state}:${normalized.vseed}`;
  const old = keys.get(key);
  if (old) return old;
  const value = renderFurniture(kind, variant, state, seed);
  const layers: any = {};
  for (const layer of ['base', 'front'] as const) {
    const s = value[layer];
    if (!s) continue;
    if (atlasX + s.buf.w > atlasW) { atlasX = 0; atlasY += rowH + 1; rowH = 0; }
    layers[layer] = { x: atlasX, y: atlasY, w: s.buf.w, h: s.buf.h, ax: s.ax, ay: s.ay, rects: s.rects };
    images.push({ x: atlasX, y: atlasY, buf: s.buf });
    atlasX += s.buf.w + 1; rowH = Math.max(rowH, s.buf.h);
  }
  sprites[key] = layers; keys.set(key, key);
  return key;
}

const scenes: Record<string, any> = {};
const leisureKinds = new Set(['arcade','armchair','beanbag','bench','cafe_seat','coffee','fridge','pingpong','shelf','sink','snack','sofa','stall','water','window']);
const points = (list: any[]) => list.map(s => `${s.kind ?? ''}:${s.x}:${s.y}`).sort().join('|');
for (let count = 0; count <= 16; count++) {
  const source = JSON.parse(await readFile(new URL(`../../assets/habblaud_art/worlds/world-${count}.json`, import.meta.url), 'utf8'));
  const rooms: any[] = [];
  for (let slot = 0; slot < count; slot++) {
    const targetDesks = source.workSpots[slot].map((s: any) => ({ ...s, kind: 'desk' }));
    const targetLeisure = source.leisureSpots.filter((s: any) => s.areaId === `workspace-${slot}`);
    let found: any;
    for (let seed = 1; seed <= 4096; seed++) {
      const candidate = layoutProjectRoom({ id: `workspace-${slot}`, slot, seed }, roomTheme(seed));
      if (points(candidate.spots.filter(s => s.kind === 'desk')) === points(targetDesks) &&
          points(candidate.spots.filter(s => leisureKinds.has(s.kind))) === points(targetLeisure)) {
        found = candidate; break;
      }
    }
    if (!found) throw new Error(`Native layout must match the baked map: world ${count}, room ${slot}`);
    rooms.push(found);
  }
  const building = assembleBuilding(source.cols, rooms);
  const areas = [...building.core, building.corridor, ...rooms];
  const furniture = areas.flatMap(area => [
    ...area.furniture.map(f => ({ ...f, areaId: area.id, mount: 'floor',
      ax: (f.tx + FURNITURE[f.kind].footprint.w / 2) * 16 + (f.dx ?? 0),
      ay: (f.ty + FURNITURE[f.kind].footprint.h) * 16 + (f.dy ?? 0),
      seatSpot: area.spots.find(s => s.deskId === f.id)?.id,
      frames: [0,1,2].map(state => sprite(f.kind, f.variant, state, hash32(f.id))) })),
    ...area.wallItems.map(f => ({ ...f, areaId: area.id, mount: 'wall', ax: f.cx, ay: f.baseY,
      frames: [0,1,2].map(state => sprite(f.kind, f.variant, state, hash32(f.id))) })),
  ]);
  scenes[count] = { grid: { w: building.grid.w, h: building.grid.h, cells: Array.from(building.grid.cells) },
    spots: building.spots, furniture,
    areas: areas.map(area => ({ id: area.id, kind: area.kind, rect: area.rect, walls: area.walls, floors: area.floors, rugs: area.rugs, floorTint: area.floorTint })) };
}

for (const kind of ['tree','gift','pumpkin','ghost','wreath','bat'] as const) {
  const s = renderSeasonalProp(kind);
  if (atlasX + s.buf.w > atlasW) { atlasX = 0; atlasY += rowH + 1; rowH = 0; }
  sprites['seasonal:' + kind] = { base: { x: atlasX, y: atlasY, w: s.buf.w, h: s.buf.h, ax: s.ax, ay: s.ay } };
  images.push({ x: atlasX, y: atlasY, buf: s.buf });
  atlasX += s.buf.w + 1; rowH = Math.max(rowH, s.buf.h);
}

const atlasH = atlasY + rowH;
const raw = Buffer.alloc((atlasW * 4 + 1) * atlasH);
for (const image of images) for (let y = 0; y < image.buf.h; y++) {
  const source = Buffer.from(image.buf.data.buffer, image.buf.data.byteOffset + y * image.buf.w * 4, image.buf.w * 4);
  source.copy(raw, (image.y + y) * (atlasW * 4 + 1) + 1 + image.x * 4);
}
function chunk(type: string, data: Buffer) {
  const name = Buffer.from(type); let crc = 0xffffffff;
  for (const byte of Buffer.concat([name, data])) {
    crc ^= byte;
    for (let i = 0; i < 8; i++) crc = crc & 1 ? (crc >>> 1) ^ 0xedb88320 : crc >>> 1;
  }
  const head = Buffer.alloc(4); head.writeUInt32BE(data.length);
  const tail = Buffer.alloc(4); tail.writeUInt32BE((crc ^ 0xffffffff) >>> 0);
  return Buffer.concat([head, name, data, tail]);
}
const header = Buffer.alloc(13); header.writeUInt32BE(atlasW); header.writeUInt32BE(atlasH, 4); header[8] = 8; header[9] = 6;
const png = Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
await writeFile(new URL('../../assets/office_world/native-furniture.png', import.meta.url), png);
await writeFile(new URL('../../assets/office_world/native-scene.json', import.meta.url), JSON.stringify({ width: atlasW, height: atlasH, sprites, scenes }));
console.log(`Native Office: ${Object.keys(sprites).length} furniture states, 17 layouts, ${atlasW}×${atlasH} atlas.`);
