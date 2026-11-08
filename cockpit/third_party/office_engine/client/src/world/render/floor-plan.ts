import type { ArtModule, Sprite } from '../../art/api';
import { COL_W, TILE } from '../constants';
import type { Sim } from '../sim/sim';
import { PLAN, benchPatches, expansionWidth, planX, planY, type CoworkingObject } from '../layout/floor-plan';
import { getLocale, tr } from '../../../../shared/i18n';

/** Procedural floor plus independent native sprites. The reference PNG is never rendered. */
export class CoworkingSceneRenderer {
  private cache: HTMLCanvasElement | null = null;
  private columns = -1;
  private locale = '';

  draw(ctx: CanvasRenderingContext2D, cols: number): void {
    const currentLocale = getLocale();
    if (this.columns !== cols || this.locale !== currentLocale || !this.cache) {
      const canvas = document.createElement('canvas');
      canvas.width = cols * COL_W * TILE; canvas.height = PLAN.height;
      const c = canvas.getContext('2d')!, extra = expansionWidth(cols);
      c.fillStyle = '#c9935a'; c.fillRect(0, 0, canvas.width, canvas.height);
      // Staggered wood boards have individual grain and bevels.
      for (let y = 0; y < canvas.height; y += 14) for (let x = -90; x < canvas.width; x += 116) {
        const xx = x + (y / 14 % 2) * 58, seed = ((x + 200) * 19 + y * 31) >>> 0;
        c.fillStyle = ['#d8a66c', '#d4a064', '#dca970', '#cd975e'][seed % 4]; c.fillRect(xx, y, 115, 13);
        c.fillStyle = '#e8b982'; c.fillRect(xx + 1, y, 113, 1);
        c.fillStyle = '#ba854f'; c.fillRect(xx, y + 13, 116, 1);
        c.fillStyle = '#ce995f'; c.fillRect(xx + 12, y + 7, 57, 1);
      }
      const rug = (x: number, y: number, w: number, h: number, color: string, shift = 0) => {
        const xx = planX(x) + shift, yy = planY(y), ww = Math.round(w * PLAN.width / PLAN.w), hh = Math.round(h * PLAN.height / PLAN.h);
        c.fillStyle = '#f1c18a'; c.fillRect(xx - 2, yy - 2, ww + 4, hh + 4);
        c.fillStyle = color; c.fillRect(xx, yy, ww, hh);
        c.fillStyle = '#ffffff0c';
        for (let py = yy + 3; py < yy + hh; py += 6) for (let px = xx + 3; px < xx + ww; px += 8) c.fillRect(px, py, 2, 1);
      };
      rug(155, 290, 258, 98, '#9a8b80'); rug(625, 252, 505, 113, '#a8947f');
      rug(145, 460, 223, 177, '#7c6b72'); rug(390, 452, 380, 214, '#a39180');
      rug(861, 452, 348, 214, '#a39180');
      for (const p of benchPatches(cols)) rug(861, 452, 348, 214, '#a39180', p.dx);
      rug(553, 756, 315, 164, '#454551'); rug(927, 770, 552, 175, '#685578', extra);
      rug(1255, 369, 222, 255, '#a99e91', extra);
      // A tiled private washroom is the only opaque enclosed room.
      const rx = planX(65), ry = planY(711), rw = planX(476) - rx, rh = planY(965) - ry;
      c.fillStyle = '#d7dbe3'; c.fillRect(rx, ry, rw, rh);
      c.strokeStyle = '#b4bccb'; c.lineWidth = 1;
      for (let x = rx; x <= rx + rw; x += 32) { c.beginPath(); c.moveTo(x, ry); c.lineTo(x, ry + rh); c.stroke(); }
      for (let y = ry; y <= ry + rh; y += 32) { c.beginPath(); c.moveTo(rx, y); c.lineTo(rx + rw, y); c.stroke(); }
      // Glass entrance and direction mat are floor details, not phantom elevators.
      c.fillStyle = '#364052'; c.fillRect(21, planY(444), 38, 86);
      c.fillStyle = '#e6b551'; c.font = '22px sans-serif'; c.fillText('‹ ›', 24, planY(495));
      c.strokeStyle = '#d4f5ff'; c.lineWidth = 3;
      for (const y of [planY(404), planY(550)]) c.strokeRect(9, y, 5, 120);
      const sign = (text: string, x: number, y: number, shift = 0) => {
        c.font = '600 13px system-ui'; const w = c.measureText(text).width + 22;
        c.fillStyle = '#232936'; c.fillRect(planX(x) + shift - w / 2, planY(y), w, 23);
        c.fillStyle = '#f5f0e8'; c.textAlign = 'center'; c.fillText(text, planX(x) + shift, planY(y) + 16); c.textAlign = 'left';
      };
      sign(tr('Recepção'), 277, 271); sign(tr('Cafeteria'), 803, 203); sign(tr('Games'), 1100, 930, extra);
      this.cache = canvas; this.columns = cols; this.locale = currentLocale;
    }
    ctx.drawImage(this.cache, 0, 0);
  }

  hasFront(node: CoworkingObject, art: ArtModule): boolean {
    return node.shape === 'sprite' && !!node.kind && !!art.furnitureSprites(node.kind, node.variant).front;
  }

  object(ctx: CanvasRenderingContext2D, node: CoworkingObject, art: ArtModule, now: number, sim: Sim, front = false, busy = false): void {
    const { x, y, w, h } = node;
    if (node.shape === 'sprite' && node.kind) {
      const sprites = art.furnitureSprites(node.kind, node.variant, busy ? 1 : 0);
      const s = front ? sprites.front : sprites.base; if (!s) return;
      this.sprite(ctx, s, x + w / 2, y + h, node.scale);
      if (!front && node.kind === 'arcade' && s.rects?.screen) {
        const r = s.rects.screen;
        art.drawScreen(ctx, { x: x + w / 2 + (r.x - s.ax) * node.scale, y: y + h + (r.y - s.ay) * node.scale,
          w: r.w * node.scale, h: r.h * node.scale }, 'game', now, sim.social.arcadeSeed() ?? 4);
      }
      if (!front && node.kind === 'mirror' && s.rects?.glass) this.reflection(ctx, node, s, art, sim);
      if (!front && node.kind === 'coffee_machine' && busy) {
        ctx.fillStyle = '#edf7ff';
        for (let i = 0; i < 3; i++) {
          const phase = (now / 1200 + i / 3) % 1;
          ctx.fillRect(x + w / 2 - 5 + i * 4, y - 10 - phase * 20, 2, 4);
        }
      }
      return;
    }
    if (front) return;
    const rect = (xx: number, yy: number, ww: number, hh: number, color: string) => { ctx.fillStyle = color; ctx.fillRect(xx, yy, ww, hh); };
    const box = (color: string, edge = '#33343f') => {
      rect(x + 3, y + 5, w, h, '#1b22302b'); rect(x, y, w, h, edge); rect(x + 2, y + 2, w - 4, h - 4, color);
    };
    switch (node.shape) {
      case 'wall':
        box(node.color ?? '#414354'); rect(x + 2, y + 2, w - 4, 3, '#76798a'); break;
      case 'glass':
        box('#a9e1eb2b');
        rect(x, y, w, 2, '#cee9ed');
        if (h > w) for (let yy = y + 25; yy < y + h; yy += 55) rect(x, yy, w, 2, '#424c59');
        break;
      case 'slats':
        box(node.color ?? '#543a29');
        for (let xx = x + 3; xx < x + w - 3; xx += 7) { rect(xx, y + 3, 2, h - 6, '#956039'); rect(xx + 2, y + 3, 1, h - 6, '#322c2b'); }
        if (node.label) {
          const translated = tr(node.label);
          ctx.save(); ctx.textAlign = 'center'; ctx.fillStyle = '#ffdf93'; ctx.shadowColor = '#ffb435'; ctx.shadowBlur = 12;
          ctx.font = '600 25px system-ui'; ctx.fillText('◇', x + w / 2, y + h / 2 - 4);
          ctx.font = '600 19px system-ui'; ctx.fillText(translated, x + w / 2, y + h - 13); ctx.restore();
        }
        break;
      case 'counter':
      case 'bench':
        rect(x + 4, y + h - 1, 5, 15, '#49434a'); rect(x + w - 9, y + h - 1, 5, 15, '#49434a');
        box('#eac18b', '#70553b'); rect(x + 2, y + 2, w - 4, 3, '#ffe0ad');
        for (let yy = y + 8; yy < y + h - 3; yy += 11) rect(x + 6, yy, w - 12, 1, '#dab17d');
        rect(x, y + h - 5, w, 5, '#9e704a');
        if (node.shape === 'counter') { rect(x + 3, y + h - 3, w - 6, 20, '#ab8056'); rect(x + 3, y + h + 16, w - 6, 4, '#55463d'); }
        break;
      case 'monitor':
        rect(x + w / 2 - 2, y + h - 6, 4, 9, '#242d40'); rect(x + 6, y + h + 1, w - 12, 3, '#334355');
        box('#142b46'); rect(x + 3, y + 3, w - 6, h - 7, '#174064');
        for (let i = 0; i < 5; i++) rect(x + 5 + i % 2 * 3, y + 5 + i * 3, (w - 11) * (.4 + ((i + Math.floor(now / 500)) % 3) * .2), 1, i % 2 ? '#61d4c0' : '#88b9e8');
        rect(x - 1, y + h + 9, w + 2, 5, '#586277');
        break;
      case 'pastry':
        box('#a57041'); rect(x + 3, y + 3, w - 6, h - 6, '#d0edee70');
        for (let row = 0; row < 3; row++) {
          rect(x + 2, y + 4 + row * h / 3, w - 4, 2, '#ffe4a4');
          for (let col = 0; col < 3; col++) { rect(x + 10 + col * 23, y + 12 + row * h / 3, 13, 7, '#d68b32'); rect(x + 11 + col * 23, y + 11 + row * h / 3, 10, 3, '#f8d17d'); }
        }
        break;
      case 'pool':
        box('#65452f'); rect(x + 7, y + 7, w - 14, h - 14, '#08744e'); rect(x + 10, y + 10, w - 20, h - 20, '#12825a');
        for (const xx of [x + 5, x + w - 9]) for (const yy of [y + 5, y + h / 2 - 2, y + h - 9]) rect(xx, yy, 5, 5, '#19252a');
        for (let i = 0; i < 6; i++) rect(x + w / 2 + i % 3 * 4 - 4, y + h * .7 + Math.floor(i / 3) * 4, 3, 3, ['#f8e7c2', '#f6c23d', '#f16b5e'][i % 3]);
        ctx.strokeStyle = '#dfbd7f'; ctx.lineWidth = 2; ctx.beginPath(); ctx.moveTo(x + 20, y + 45); ctx.lineTo(x + w - 18, y + 16); ctx.stroke(); break;
      case 'foosball':
        box('#72503a'); rect(x + 7, y + 7, w - 14, h - 14, '#306354');
        for (let i = 0; i < 5; i++) {
          const xx = x + 12 + i * (w - 24) / 4; rect(xx, y - 5, 2, h + 10, '#a7b7c4');
          for (let j = 0; j < 3; j++) rect(xx - 2, y + 12 + j * 13, 6, 8, i % 2 ? '#efaa55' : '#478cc3');
        }
        break;
      case 'display':
        box('#253148'); rect(x + 4, y + 4, w - 8, h - 8, node.label === 'game' ? '#42205f' : '#254b7b');
        if (node.label === 'game' || node.label === 'social-tv') {
          const mode = node.label === 'game' ? 'game' : 'show';
          const live = sim.social.tvScreen();
          art.drawScreen(ctx, { x: x + 4, y: y + 4, w: w - 8, h: h - 8 }, mode, now, live?.mode === mode ? live.seed : 4);
        } else for (let i = 0; i < 5; i++) rect(x + 15 + i * 10, y + h - 12 - i * 5, 6, 6 + i * 5, '#e5d89e');
        break;
      case 'hygiene':
        box('#e4e9ee'); rect(x + 5, y + 6, w - 10, 10, '#697d8a');
        rect(x + 6, y + 19, w - 12, 13, '#ffffff'); rect(x + 4, y + h - 7, w - 8, 3, '#a3b9c4');
        break;
    }
  }

  private reflection(ctx: CanvasRenderingContext2D, node: CoworkingObject, mirror: Sprite, art: ArtModule, sim: Sim): void {
    const r = mirror.rects!.glass!;
    const gx = node.x + node.w / 2 + (r.x - mirror.ax) * node.scale;
    const gy = node.y + node.h + (r.y - mirror.ay) * node.scale;
    const gw = r.w * node.scale, gh = r.h * node.scale;
    const person = [...sim.chars.values()].find(ch => !ch.inside && !ch.seated && ch.alpha > .5 && ch.dir === 'up'
      && Math.abs(ch.x - node.x - node.w / 2) < node.w / 2 && ch.y - node.y > 10 && ch.y - node.y < 90);
    if (!person) return;
    const pose = person.pose === 'groom' ? 'groom' : 'stand';
    const sprite = art.characterSprite({ appearance: person.appearance, dir: 'down', pose,
      frame: Math.floor(person.animT / art.poseFrameDuration(pose)) % art.poseFrameCount(pose),
      held: pose === 'groom' ? person.held : 'none', seated: false });
    ctx.save(); ctx.beginPath(); ctx.rect(gx, gy, gw, gh); ctx.clip(); ctx.globalAlpha = .75;
    ctx.drawImage(sprite.canvas, gx + gw / 2 - sprite.ax * node.scale, gy - 7 * node.scale,
      sprite.canvas.width * node.scale, sprite.canvas.height * node.scale);
    ctx.globalAlpha = .2; ctx.fillStyle = '#d5efff'; ctx.fillRect(gx, gy, gw, gh); ctx.restore();
  }

  private sprite(ctx: CanvasRenderingContext2D, sprite: Sprite, x: number, y: number, scale: number): void {
    ctx.drawImage(sprite.canvas, Math.round(x - sprite.ax * scale), Math.round(y - sprite.ay * scale), sprite.canvas.width * scale, sprite.canvas.height * scale);
  }
}
