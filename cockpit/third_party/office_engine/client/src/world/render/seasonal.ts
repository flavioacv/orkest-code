import type { CharacterFrameRequest, FurnitureKind, Sprite, WallStyle } from '../../art/api';
import { mix } from '../../art/core/color';
import { hash32 } from '../../../../shared/hash';
import { renderSeasonalProp, type SeasonalProp } from '../../art/seasonal';
import type { SeasonalTheme } from '../api';
import type { AreaLayout, WallSegment } from '../layout/types';

const sprites = new Map<SeasonalProp, Sprite>();
function prop(kind: SeasonalProp): Sprite {
  let sprite = sprites.get(kind);
  if (!sprite) {
    const { buf, ax, ay } = renderSeasonalProp(kind);
    const canvas = document.createElement('canvas');
    canvas.width = buf.w;
    canvas.height = buf.h;
    canvas.getContext('2d')!.putImageData(new ImageData(buf.data, buf.w, buf.h), 0, 0);
    sprites.set(kind, sprite = { canvas, ax, ay });
  }
  return sprite;
}

export function seasonalCostume(theme: SeasonalTheme, seed: number): CharacterFrameRequest['costume'] {
  if (theme === 'christmas') return 'santa';
  // Keep the third variant in its original clothes: the vampire cape obscures
  // the silhouette and does not follow the character's facing direction.
  if (theme === 'halloween') return (['witch', 'pumpkin', undefined] as const)[(seed >>> 0) % 3];
  return undefined;
}

/** Reutiliza footprints de plantas: nenhuma nova colisão ou mudança de caminhos. */
export function seasonalFurniture(theme: SeasonalTheme, kind: FurnitureKind, area: AreaLayout, seed: number): Sprite | null {
  return null;
}

export function seasonalRugColor(theme: SeasonalTheme, original: string): string {
  return original;
}

export function seasonalWallStyle(theme: SeasonalTheme, original: WallStyle): WallStyle {
  return original;
}

/** Motivos de tapete (cacheados junto com o piso). */
export function decorateSeasonalRug(ctx: CanvasRenderingContext2D, theme: SeasonalTheme, rug: { x: number; y: number; w: number; h: number }): void {
  return;
}

/** Enfeites no alto da parede, longe das telas e placas. Os vãos ficam livres. */
export function decorateSeasonalWall(ctx: CanvasRenderingContext2D, theme: SeasonalTheme, wall: WallSegment): void {
  return;
}

/** Guirlandas nas molduras dos elevadores (sem cobrir a porta animada). */
export function decorateElevator(ctx: CanvasRenderingContext2D, theme: SeasonalTheme, x: number, y: number): void {
  return;
}

const glows = new Map<SeasonalTheme, HTMLCanvasElement>();
function glowSprite(theme: SeasonalTheme): HTMLCanvasElement {
  let canvas = glows.get(theme);
  if (!canvas) {
    canvas = document.createElement('canvas');
    canvas.width = canvas.height = 34;
    const ctx = canvas.getContext('2d')!;
    const glow = ctx.createRadialGradient(17, 17, 1, 17, 17, 17);
    glow.addColorStop(0, theme === 'christmas' ? '#ffd58b' : '#d8a5ed');
    glow.addColorStop(1, 'rgba(255,220,180,0)');
    ctx.fillStyle = glow;
    ctx.fillRect(0, 0, 34, 34);
    glows.set(theme, canvas);
  }
  return canvas;
}

/** Luz decorativa suave, limitada à face da parede. Não interfere com salas apagadas. */
export function drawSeasonalLights(ctx: CanvasRenderingContext2D, theme: SeasonalTheme, layout: AreaLayout, light: number): void {
  if (theme === 'none' || light <= 0.01) return;
  ctx.save();
  for (const wall of layout.walls) {
    if (wall.kind !== 'face') continue;
    ctx.save();
    ctx.beginPath();
    ctx.rect(wall.x, wall.y + 4, wall.w, 27);
    ctx.clip();
    for (let x = wall.x + 14; x < wall.x + wall.w - 6; x += 24) {
      if (wall.doorways?.some((d) => x >= d.x - 10 && x <= d.x + d.w + 10)) continue;
      ctx.globalAlpha = light * 0.3;
      ctx.drawImage(glowSprite(theme), Math.round(x - 17), wall.y - 8);
      ctx.globalAlpha = light * 0.85;
      ctx.fillStyle = theme === 'christmas' ? '#ffe4a9' : '#ffd181';
      ctx.fillRect(Math.round(x), wall.y + 9, 2, 2);
    }
    ctx.restore();
  }
  ctx.restore();
}

export function drawSeasonalWindow(ctx: CanvasRenderingContext2D, theme: SeasonalTheme, glass: { x: number; y: number; w: number; h: number }, now: number, seed: number): void {
  if (theme !== 'christmas') return;
  ctx.save();
  ctx.beginPath();
  ctx.rect(glass.x, glass.y, glass.w, glass.h);
  ctx.clip();
  ctx.fillStyle = '#edf3f3';
  ctx.globalAlpha *= 0.7;
  ctx.fillRect(glass.x, glass.y + glass.h - 2, glass.w, 2);
  for (let i = 0; i < 12; i++) {
    const x = ((seed >>> 0) + i * 17) % Math.max(1, Math.floor(glass.w));
    const y = (Math.floor(now / 180) + i * 11) % Math.max(1, Math.floor(glass.h));
    ctx.fillRect(Math.floor(glass.x + x), Math.floor(glass.y + y), 1, 1);
  }
  ctx.restore();
}
