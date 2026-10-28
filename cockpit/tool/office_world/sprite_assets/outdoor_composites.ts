import type { PropSprite } from '../../../third_party/office_engine/client/src/world/render/props.ts';

function surface(w: number, h: number): { sprite: PropSprite; ctx: CanvasRenderingContext2D } {
  const canvas = document.createElement('canvas'); canvas.width = w; canvas.height = h;
  const ctx = canvas.getContext('2d')!; ctx.imageSmoothingEnabled = false;
  return { sprite: { canvas, ax: w / 2, ay: h }, ctx };
}

/** A stream continues beyond the north edge, with a rounded mouth and irregular banks. */
export function composeRiver(water: PropSprite, percent: number): PropSprite {
  const factor = Math.max(0, Math.min(100, percent)) / 100;
  if (!factor) return surface(1, 1).sprite;
  const { sprite, ctx } = surface(Math.max(1, Math.round(192 * factor)), 420);
  const cx = sprite.canvas.width / 2;
  for (let y = 0; y < 420; y++) {
    const distance = 420 - y;
    const wave = (Math.sin(distance / 85) * 30 + Math.sin(distance / 39) * 8) * factor;
    let half = (33 + Math.sin(distance / 61) * 6) * factor;
    if (distance < 24) half *= Math.sqrt(1 - (1 - distance / 24) ** 2);
    const left = Math.round(cx + wave - half), right = Math.round(cx + wave + half);
    const bank = Math.max(1, Math.round(4 * factor));
    // Original soil and water textures, with nearest-neighbour pixel contours.
    ctx.drawImage(water.canvas, y % 64, 10, 8, 1, left - bank, y, bank, 1);
    ctx.drawImage(water.canvas, (y + 17) % 64, 12, 8, 1, right + 1, y, bank, 1);
    ctx.drawImage(water.canvas, 0, 32 + y % 22, 96, 1, left, y, Math.max(1, right - left + 1), 1);
    ctx.fillStyle = '#222034'; ctx.fillRect(left - 1, y, 1, 1); ctx.fillRect(right + 1, y, 1, 1);
    if (y % 9 < 5) {
      ctx.fillStyle = '#cfedf7'; ctx.fillRect(left + 1, y, 1, 1); ctx.fillRect(right - 1, y, 1, 1);
    }
  }
  return sprite;
}

export function composeTrain(engine: PropSprite, wagon: PropSprite): PropSprite {
  const { sprite, ctx } = surface(wagon.canvas.width + engine.canvas.width + 6, 104);
  ctx.drawImage(wagon.canvas, 0, 0); ctx.drawImage(engine.canvas, wagon.canvas.width + 6, 0);
  ctx.fillStyle = '#393e4b'; ctx.fillRect(wagon.canvas.width, 78, 6, 5);
  return sprite;
}

export function stationTrack(): PropSprite {
  const { sprite, ctx } = surface(1200, 88);
  ctx.fillStyle = '#777a73'; ctx.fillRect(0, 0, 1200, 88);
  for (let x = 2; x < 1200; x += 10) {
    ctx.fillStyle = x % 3 ? '#95978e' : '#5f625d'; ctx.fillRect(x, 4 + x % 11, 5, 3);
    ctx.fillRect(x + 2, 66 + x % 13, 4, 3);
  }
  for (let x = 8; x < 1200; x += 22) {
    ctx.fillStyle = '#514536'; ctx.fillRect(x, 10, 9, 68);
    ctx.fillStyle = '#89765b'; ctx.fillRect(x, 10, 7, 64);
  }
  for (const y of [22, 60]) {
    ctx.fillStyle = '#343c46'; ctx.fillRect(0, y, 1200, 6);
    ctx.fillStyle = '#c3cbd1'; ctx.fillRect(0, y, 1200, 2);
  }
  sprite.ay = 44;
  return sprite;
}

export function stationShelter(): PropSprite {
  const { sprite, ctx } = surface(260, 108);
  ctx.fillStyle = '#343f49'; ctx.fillRect(8, 24, 6, 84); ctx.fillRect(246, 24, 6, 84);
  ctx.fillStyle = '#597e87'; ctx.fillRect(0, 0, 260, 28);
  ctx.fillStyle = '#91b3b6'; ctx.fillRect(0, 0, 260, 5);
  ctx.fillStyle = '#233d4d'; ctx.fillRect(16, 8, 228, 16);
  ctx.fillStyle = '#fff1c4'; ctx.font = 'bold 12px monospace'; ctx.textAlign = 'center'; ctx.fillText('ESTAÇÃO OFFICE', 130, 20);
  ctx.fillStyle = '#89634b'; ctx.fillRect(32, 76, 196, 12);
  ctx.fillStyle = '#b5916b'; ctx.fillRect(32, 61, 196, 13);
  ctx.fillStyle = '#42464b'; ctx.fillRect(42, 88, 6, 20); ctx.fillRect(212, 88, 6, 20);
  return sprite;
}

/** A fixed world span with the rail height controlled by the furniture slider. */
export function tiledTrack(source: PropSprite, width: number): PropSprite {
  const { sprite, ctx } = surface(width, source.canvas.height);
  for (let x = 0; x < width; x += source.canvas.width) ctx.drawImage(source.canvas, x, 0);
  sprite.ay = source.ay;
  return sprite;
}

const snowCache = new WeakMap<HTMLCanvasElement, PropSprite>();
const snowyGroundCache = new WeakMap<HTMLCanvasElement, PropSprite>();
export function snowySprite(source: PropSprite, coverGrass = false): PropSprite {
  const cache = coverGrass ? snowyGroundCache : snowCache;
  const cached = cache.get(source.canvas); if (cached) return cached;
  const { sprite, ctx } = surface(source.canvas.width, source.canvas.height);
  sprite.ax = source.ax; sprite.ay = source.ay;
  ctx.drawImage(source.canvas, 0, 0);
  const pixels = ctx.getImageData(0, 0, sprite.canvas.width, sprite.canvas.height);
  const { data, width, height } = pixels;
  for (let x = 0; x < width; x++) {
    let top = -1;
    for (let y = 0; y < height; y++) {
      const i = (y * width + x) * 4;
      if (data[i + 3] < 128) continue;
      if (top < 0) top = y;
      // Snow lies on the opaque roof/upper contour; water becomes pale ice.
      const ice = data[i + 2] > 170 && data[i + 1] > 140 && data[i] < 155;
      const grass = coverGrass && data[i + 1] > data[i] && data[i] > data[i + 2] && data[i + 2] < 100;
      if (grass || (top < height * .65 && y < top + 2 + x % 3) || ice) {
        data[i] = ice ? 181 : 232; data[i + 1] = ice ? 216 : 241; data[i + 2] = ice ? 234 : 249;
      }
    }
  }
  ctx.putImageData(pixels, 0, 0); cache.set(source.canvas, sprite); return sprite;
}
