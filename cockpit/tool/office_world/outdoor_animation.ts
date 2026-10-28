import type { Sprite } from '../../third_party/office_engine/client/src/art/api.ts';
import type { ExteriorSeason } from '../../third_party/office_engine/client/src/world/api.ts';
import type { OutdoorAction } from '../../third_party/office_engine/client/src/world/layout/outdoor-life.ts';

const cache = new WeakMap<HTMLCanvasElement, Map<string, Sprite>>();

/** Small pixel animations layered onto the original character rig, cached by frame. */
export function outdoorAnimation(base: Sprite, action: OutdoorAction, frame: number, season: ExteriorSeason): Sprite {
  let frames = cache.get(base.canvas);
  if (!frames) cache.set(base.canvas, frames = new Map());
  const key = `${action}:${frame}:${season}`;
  const existing = frames.get(key); if (existing) return existing;
  const canvas = document.createElement('canvas'); canvas.width = 72; canvas.height = 64;
  const ctx = canvas.getContext('2d')!; ctx.imageSmoothingEnabled = false;
  const ax = 32, ay = 56, swing = frame / 7;
  const bob = action === 'chop' && frame >= 4 ? 1 : 0;
  ctx.drawImage(base.canvas, ax - base.ax, ay - base.ay + bob);
  if (action === 'chop' || action === 'tend') {
    ctx.save(); ctx.translate(ax + 6, ay - 14);
    ctx.rotate(action === 'chop' ? -1.7 + swing * 2.3 : -.7 + Math.sin(swing * Math.PI * 2) * .5);
    ctx.fillStyle = '#76513a'; ctx.fillRect(0, -1, 17, 3);
    if (action === 'chop') {
      ctx.fillStyle = '#434f5c'; ctx.fillRect(13, -5, 5, 10);
      ctx.fillStyle = '#d9e6e9'; ctx.fillRect(17, -5, 2, 10);
    } else if (season === 'winter') {
      ctx.fillStyle = '#b1c7d8'; ctx.fillRect(14, -4, 8, 9);
    } else if (season === 'autumn') {
      ctx.fillStyle = '#c39153'; ctx.fillRect(15, -6, 2, 12);
      for (let y = -6; y <= 6; y += 3) ctx.fillRect(17, y, 4, 1);
    } else {
      ctx.fillStyle = '#5c9e7a'; ctx.fillRect(10, -4, 8, 7); ctx.fillRect(18, -2, 5, 2);
    }
    ctx.restore();
    if (frame >= 4) for (let i = 0; i < 4; i++) {
      ctx.fillStyle = action === 'chop' || season === 'autumn' ? '#c3935b' : season === 'winter' ? '#eff7ff' : '#8ed9ed';
      ctx.fillRect(ax + 17 + i * 3 + frame % 2, ay - 7 - (i + frame) % 5, 2, 1);
    }
  } else if (action === 'serve') {
    ctx.fillStyle = '#d4b590'; ctx.fillRect(ax - 11, ay - 12, 10, 2);
    ctx.fillStyle = '#f0eee0'; ctx.fillRect(ax - 9, ay - 17 - frame % 2, 4, 5);
    if (season === 'winter') { ctx.fillStyle = '#dcecf1'; ctx.fillRect(ax - 8, ay - 20 - frame % 3, 1, 2); }
  } else if (action === 'warm') {
    ctx.fillStyle = '#d8e8ef';
    for (let i = 0; i < 3; i++) ctx.fillRect(ax + 5 + i * 2 + frame % 3, ay - 24 - i - frame % 2, 2, 1);
  }
  const sprite = { canvas, ax, ay }; frames.set(key, sprite); return sprite;
}
