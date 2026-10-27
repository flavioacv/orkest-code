// Sprites procedurais da área externa (árvores, arbustos, postes, carros...) e utilitários
// visuais do mundo (sombra, brilhos). Mesma direção de arte do módulo de arte: contorno
// cinza-azulado escuro, 3–4 tons por material, luz vinda de cima/esquerda.
import { mulberry32 } from '../../../../shared/hash';
import type { ExteriorSeason } from '../api';
import type { ExteriorProp } from '../layout/types';

export interface PropSprite {
  canvas: HTMLCanvasElement;
  ax: number;
  ay: number;
}

const cache = new Map<string, PropSprite>();

function makeCanvas(w: number, h: number): [HTMLCanvasElement, CanvasRenderingContext2D] {
  const c = document.createElement('canvas');
  c.width = w;
  c.height = h;
  const ctx = c.getContext('2d')!;
  ctx.imageSmoothingEnabled = false;
  return [c, ctx];
}

function hex(c: string): [number, number, number] {
  const n = parseInt(c.slice(1), 16);
  return [(n >> 16) & 255, (n >> 8) & 255, n & 255];
}

/** Pintor por pixel (ImageData) para formas orgânicas. */
class Painter {
  readonly data: ImageData;
  constructor(
    readonly ctx: CanvasRenderingContext2D,
    readonly w: number,
    readonly h: number,
  ) {
    // parte do conteúdo já desenhado (ex.: sombra) para não apagá-lo no putImageData
    this.data = ctx.getImageData(0, 0, w, h);
  }
  set(x: number, y: number, color: string, a = 255): void {
    if (x < 0 || y < 0 || x >= this.w || y >= this.h) return;
    const [r, g, b] = hex(color);
    const i = (y * this.w + x) * 4;
    this.data.data[i] = r;
    this.data.data[i + 1] = g;
    this.data.data[i + 2] = b;
    this.data.data[i + 3] = a;
  }
  alpha(x: number, y: number): number {
    if (x < 0 || y < 0 || x >= this.w || y >= this.h) return 0;
    return this.data.data[(y * this.w + x) * 4 + 3];
  }
  flush(): void {
    this.ctx.putImageData(this.data, 0, 0);
  }
}

function shadowEllipse(ctx: CanvasRenderingContext2D, cx: number, cy: number, rx: number, ry: number, a = 0.22): void {
  ctx.fillStyle = `rgba(28,36,52,${a})`;
  for (let y = -ry; y <= ry; y++) {
    const half = Math.round(rx * Math.sqrt(Math.max(0, 1 - (y * y) / (ry * ry))));
    ctx.fillRect(cx - half, cy + y, half * 2, 1);
  }
}

/** Copa arredondada: união de círculos com sombreamento por luz superior-esquerda. */
function canopy(p: Painter, rng: () => number, cx: number, cy: number, r: number, tones: string[], outline: string): void {
  const blobs: [number, number, number][] = [[cx, cy, r]];
  for (let i = 0; i < 4; i++) {
    const a = rng() * Math.PI * 2;
    const d = r * (0.35 + rng() * 0.35);
    blobs.push([cx + Math.cos(a) * d, cy + Math.sin(a) * d * 0.8, r * (0.55 + rng() * 0.25)]);
  }
  const inside = (x: number, y: number) => blobs.some(([bx, by, br]) => (x - bx) ** 2 + (y - by) ** 2 <= br * br);
  const x0 = Math.floor(cx - r * 1.8);
  const x1 = Math.ceil(cx + r * 1.8);
  const y0 = Math.floor(cy - r * 1.6);
  const y1 = Math.ceil(cy + r * 1.6);
  for (let y = y0; y <= y1; y++) {
    for (let x = x0; x <= x1; x++) {
      if (!inside(x + 0.5, y + 0.5)) continue;
      const edge = !inside(x - 0.5, y + 0.5) || !inside(x + 1.5, y + 0.5) || !inside(x + 0.5, y - 0.5) || !inside(x + 0.5, y + 1.5);
      if (edge) {
        p.set(x, y, outline);
        continue;
      }
      // luz: topo-esquerda mais claro; ruído para "folhas"
      const nx = (x - cx) / r;
      const ny = (y - cy) / r;
      const light = -nx * 0.45 - ny * 0.75 + (rng() - 0.5) * 0.55;
      const k = light > 0.55 ? 3 : light > 0.05 ? 2 : light > -0.5 ? 1 : 0;
      p.set(x, y, tones[k]);
    }
  }
}

function treeSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(36, 48);
  shadowEllipse(ctx, 18, 45, 12, 3, 0.25);
  const p = new Painter(ctx, 36, 48);
  // tronco
  for (let y = 30; y < 46; y++) {
    for (let x = 16; x < 21; x++) {
      const col = x === 16 ? '#8a6243' : x === 20 ? '#4a3222' : '#6b4a32';
      p.set(x, y, col);
    }
  }
  p.set(15, 45, '#4a3222');
  p.set(21, 45, '#4a3222');

  if (season === 'spring') {
    const springVariants: { tones: string[]; outline: string; blossoms?: string[] }[] = [
      // Ipê-rosa / cerejeira
      { tones: ['#a34870', '#cc6290', '#eb8ab5', '#ffdbf0'], outline: '#612842', blossoms: ['#ffffff', '#ffeaf7'] },
      // Ipê-amarelo
      { tones: ['#9e741e', '#c99826', '#ecc23e', '#fff08a'], outline: '#5c4212', blossoms: ['#fff9c4', '#ffffff'] },
      // Copa verde fresca florida
      { tones: ['#2f6e41', '#429152', '#63b864', '#94de80'], outline: '#244732', blossoms: ['#f794be', '#ffe96b', '#ffffff', '#c896ff'] },
    ];
    const v = springVariants[seed % springVariants.length];
    canopy(p, rng, 18, 18, 11 + Math.floor(rng() * 3), v.tones, v.outline);
    if (v.blossoms) {
      for (let i = 0; i < 20; i++) {
        const bx = 9 + Math.floor(rng() * 18);
        const by = 8 + Math.floor(rng() * 18);
        if (p.alpha(bx, by) > 0) p.set(bx, by, v.blossoms[Math.floor(rng() * v.blossoms.length)]);
      }
    }
  } else if (season === 'autumn') {
    const autumnVariants: { tones: string[]; outline: string }[] = [
      { tones: ['#7a2e22', '#a84228', '#d4652f', '#f29b4b'], outline: '#4a1b14' },
      { tones: ['#7d521e', '#a87324', '#d69c32', '#f7cb5c'], outline: '#4d3112' },
      { tones: ['#633924', '#87502f', '#b06f3c', '#d99952'], outline: '#3d2215' },
    ];
    const v = autumnVariants[seed % autumnVariants.length];
    canopy(p, rng, 18, 18, 11 + Math.floor(rng() * 3), v.tones, v.outline);
    // folhinhas caídas ao pé do tronco
    const leafCols = ['#d4652f', '#e89d38', '#b83f2b'];
    for (let i = 0; i < 5; i++) {
      p.set(12 + Math.floor(rng() * 12), 44 + Math.floor(rng() * 2), leafCols[i % leafCols.length]);
    }
  } else if (season === 'winter') {
    const winterVariants: { tones: string[]; outline: string }[] = [
      { tones: ['#4c5c6e', '#6f8399', '#b8cadb', '#eef5fc'], outline: '#2f3d4c' },
      { tones: ['#3d5466', '#5c758a', '#9eb5c9', '#eaf2fa'], outline: '#283845' },
    ];
    const v = winterVariants[seed % winterVariants.length];
    canopy(p, rng, 18, 18, 11 + Math.floor(rng() * 3), v.tones, v.outline);
    // neve acumulada na base do tronco
    for (let x = 14; x <= 22; x++) {
      p.set(x, 45, '#eef5fc');
      if (x >= 15 && x <= 21) p.set(x, 44, '#cfe0f0');
    }
  } else {
    const variants = [
      ['#28663b', '#38854b', '#56ad5b', '#8ce076'],
      ['#306b37', '#468c40', '#66b352', '#a0db72'],
      ['#26614d', '#36805e', '#50a672', '#82cf8a'],
    ];
    canopy(p, rng, 18, 18, 11 + Math.floor(rng() * 3), variants[Math.floor(rng() * variants.length)], '#214536');
  }
  p.flush();
  return { canvas: c, ax: 18, ay: 45 };
}

function pineSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(28, 48);
  shadowEllipse(ctx, 14, 45, 9, 3, 0.25);
  const p = new Painter(ctx, 28, 48);
  for (let y = 38; y < 46; y++) for (let x = 12; x < 16; x++) p.set(x, y, x === 12 ? '#8a6243' : x === 15 ? '#4a3222' : '#6b4a32');
  const tones =
    season === 'autumn'
      ? ['#264736', '#355e44', '#4d7a53', '#739e68']
      : season === 'winter'
        ? ['#22453a', '#2e594b', '#437563', '#689c88']
        : ['#24533f', '#2f6b4f', '#3f8a5f', '#62ab79'];
  const outline = season === 'winter' ? '#1b362e' : '#1d3f33';
  const layers = 4;
  for (let l = 0; l < layers; l++) {
    const top = 4 + l * 8;
    const bottom = top + 14;
    for (let y = top; y < bottom; y++) {
      const half = Math.round(((y - top) / (bottom - top)) * (5 + l * 2.2));
      for (let x = 14 - half; x <= 14 + half; x++) {
        const edge = x === 14 - half || x === 14 + half || y === bottom - 1;
        const relY = (y - top) / (bottom - top);
        if (season === 'winter' && !edge && (relY < 0.34 || (relY < 0.52 && rng() < 0.55))) {
          p.set(x, y, x <= 14 ? '#f2f7fd' : '#cfe0f0');
          continue;
        }
        const light = (14 - x) / (half + 1) - relY + (rng() - 0.5) * 0.5;
        p.set(x, y, edge ? outline : tones[light > 0.5 ? 3 : light > -0.1 ? 2 : light > -0.6 ? 1 : 0]);
      }
    }
  }
  if (season === 'winter') {
    for (let x = 11; x <= 16; x++) p.set(x, 45, '#eef5fc');
  }
  p.flush();
  return { canvas: c, ax: 14, ay: 45 };
}

function bushSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(22, 16);
  shadowEllipse(ctx, 11, 14, 9, 2, 0.22);
  const p = new Painter(ctx, 22, 16);
  if (season === 'autumn') {
    canopy(p, rng, 11, 9, 6, ['#6e3b24', '#8f4f2b', '#b86b35', '#de954b'], '#452415');
    if (rng() < 0.7) {
      for (let i = 0; i < 4; i++) p.set(6 + Math.floor(rng() * 10), 5 + Math.floor(rng() * 6), '#f2b84b');
    }
  } else if (season === 'winter') {
    canopy(p, rng, 11, 9, 6, ['#465b6e', '#657c91', '#b4c7d9', '#eef5fc'], '#2d3c4a');
  } else if (season === 'spring') {
    canopy(p, rng, 11, 9, 6, ['#326b3d', '#468f4d', '#64b35f', '#92d676'], '#244a32');
    const cols = ['#ff85b3', '#ffe047', '#ffffff', '#c78dff'];
    for (let i = 0; i < 7; i++) {
      p.set(5 + Math.floor(rng() * 12), 4 + Math.floor(rng() * 7), cols[Math.floor(rng() * cols.length)]);
    }
  } else {
    canopy(p, rng, 11, 9, 6, ['#34663f', '#47864c', '#62a45a', '#8cc66f'], '#264a36');
    if (rng() < 0.65) {
      const col = ['#f2d14b', '#f28aa5', '#ffffff'][Math.floor(rng() * 3)];
      for (let i = 0; i < 4; i++) p.set(6 + Math.floor(rng() * 10), 5 + Math.floor(rng() * 6), col);
    }
  }
  p.flush();
  return { canvas: c, ax: 11, ay: 14 };
}

function flowersSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(30, 14);
  const p = new Painter(ctx, 30, 14);
  // canteiro: borda de pedra + terra (ou neve no inverno)
  for (let y = 4; y < 13; y++) {
    for (let x = 1; x < 29; x++) {
      const border = y === 4 || y === 12 || x === 1 || x === 28;
      const soil = season === 'winter' ? '#c8d8e8' : season === 'autumn' ? '#5e4330' : '#6a4b35';
      const rim = season === 'winter' ? (y === 12 ? '#8b9cad' : '#dce7f2') : y === 12 ? '#8d8a82' : '#b9b5aa';
      p.set(x, y, border ? rim : soil);
    }
  }
  if (season === 'winter') {
    for (let i = 0; i < 18; i++) {
      const x = 3 + Math.floor(rng() * 24);
      const y = 3 + Math.floor(rng() * 8);
      p.set(x, y, rng() < 0.7 ? '#eef5fc' : '#3d6b58');
      if (rng() < 0.25) p.set(x, y - 1, '#d94848');
    }
  } else if (season === 'autumn') {
    const cols = ['#e06a2b', '#f2a238', '#c9432b', '#d9b44a'];
    for (let i = 0; i < 22; i++) {
      const x = 3 + Math.floor(rng() * 24);
      const y = 2 + Math.floor(rng() * 9);
      p.set(x, y + 1, '#6e522b');
      p.set(x, y, cols[Math.floor(rng() * cols.length)]);
    }
  } else {
    const cols =
      season === 'spring'
        ? ['#ff6b9d', '#ffde4d', '#ffffff', '#b37feb', '#ff8552', '#6bd4ff']
        : ['#e8574a', '#f2c94c', '#f08bb0', '#ffffff', '#9b7be0'];
    const count = season === 'spring' ? 38 : 26;
    for (let i = 0; i < count; i++) {
      const x = 3 + Math.floor(rng() * 24);
      const y = 2 + Math.floor(rng() * 9);
      p.set(x, y + 1, '#3f8550');
      p.set(x, y, rng() < 0.82 ? cols[Math.floor(rng() * cols.length)] : '#5aa45d');
    }
  }
  p.flush();
  return { canvas: c, ax: 15, ay: 13 };
}

function hedgeSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(34, 16);
  shadowEllipse(ctx, 17, 14, 15, 2, 0.2);
  const p = new Painter(ctx, 34, 16);
  for (let y = 3; y < 14; y++) {
    for (let x = 1; x < 33; x++) {
      const r = y === 3 ? 2 : y === 4 ? 1 : 0;
      if (x < 1 + r || x > 32 - r) continue;
      const edge = y === 3 || y === 13 || x === 1 + r || x === 32 - r;
      const light = -(y - 3) / 10 + (rng() - 0.5) * 0.6;
      if (season === 'winter') {
        if (!edge && y <= 6 && (y <= 4 || rng() < 0.65)) {
          p.set(x, y, y === 4 ? '#f2f7fd' : '#d2e2f0');
        } else {
          p.set(x, y, edge ? '#223b32' : light > 0 ? '#557d6a' : light > -0.4 ? '#3f6353' : '#2e4d3f');
        }
      } else if (season === 'autumn') {
        p.set(x, y, edge ? '#452817' : light > 0 ? '#ba7838' : light > -0.4 ? '#945b27' : '#6e411b');
      } else {
        p.set(x, y, edge ? '#264a36' : light > 0 ? '#6aa956' : light > -0.4 ? '#4b8a45' : '#356b3c');
      }
    }
  }
  if (season === 'spring') {
    const blossoms = ['#ff8ab8', '#ffe359', '#ffffff'];
    for (let i = 0; i < 9; i++) {
      p.set(4 + Math.floor(rng() * 26), 4 + Math.floor(rng() * 7), blossoms[Math.floor(rng() * blossoms.length)]);
    }
  }
  p.flush();
  return { canvas: c, ax: 17, ay: 14 };
}

function lampSprite(season: ExteriorSeason): PropSprite {
  const [c, ctx] = makeCanvas(10, 36);
  shadowEllipse(ctx, 5, 34, 4, 1, 0.25);
  ctx.fillStyle = '#2e3648';
  ctx.fillRect(4, 6, 2, 28);
  ctx.fillStyle = '#4a5468';
  ctx.fillRect(4, 6, 1, 28);
  ctx.fillStyle = '#2e3648';
  ctx.fillRect(1, 2, 8, 5);
  ctx.fillStyle = '#ffe9a8';
  ctx.fillRect(2, 4, 6, 2);
  ctx.fillStyle = '#fff6d6';
  ctx.fillRect(3, 4, 2, 1);
  ctx.fillStyle = '#3a4152';
  ctx.fillRect(3, 32, 4, 2);
  if (season === 'winter') {
    ctx.fillStyle = '#eef5fc';
    ctx.fillRect(2, 1, 6, 1);
  }
  return { canvas: c, ax: 5, ay: 34 };
}

function benchSprite(season: ExteriorSeason): PropSprite {
  const [c, ctx] = makeCanvas(26, 14);
  shadowEllipse(ctx, 13, 12, 11, 2, 0.22);
  ctx.fillStyle = '#2e3648';
  ctx.fillRect(3, 8, 2, 4);
  ctx.fillRect(21, 8, 2, 4);
  // encosto e assento em ripas
  ctx.fillStyle = '#7a5232';
  ctx.fillRect(1, 1, 24, 3);
  ctx.fillRect(1, 6, 24, 3);
  ctx.fillStyle = '#a0703f';
  ctx.fillRect(1, 1, 24, 1);
  ctx.fillRect(1, 6, 24, 1);
  ctx.fillStyle = '#5b3c25';
  ctx.fillRect(1, 8, 24, 1);
  ctx.fillRect(1, 3, 24, 1);
  if (season === 'winter') {
    ctx.fillStyle = '#eef5fc';
    ctx.fillRect(2, 1, 9, 1);
    ctx.fillRect(15, 1, 8, 1);
    ctx.fillRect(3, 6, 7, 1);
  }
  return { canvas: c, ax: 13, ay: 12 };
}

function rockSprite(seed: number, season: ExteriorSeason): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(16, 12);
  const p = new Painter(ctx, 16, 12);
  const tones =
    season === 'winter'
      ? ['#7d8896', '#9ba8b8', '#c8d6e6', '#eef5fc']
      : ['#7d8590', '#959da8', '#b3bac4', '#d3d8de'];
  canopy(p, rng, 8, 7, 4, tones, '#4d5562');
  p.flush();
  return { canvas: c, ax: 8, ay: 11 };
}

/** Mesa de jardim com guarda-sol listrado (vista de cima, 3/4) e duas cadeirinhas. */
function parasolSprite(seed: number, season: ExteriorSeason): PropSprite {
  const [c, ctx] = makeCanvas(32, 34);
  const palettes: [string, string, string][] =
    season === 'autumn'
      ? [
          ['#c9592c', '#f5ebd6', '#8a3918'],
          ['#d99326', '#f5ebd6', '#966112'],
          ['#8c422b', '#f2e6cf', '#5e2918'],
        ]
      : season === 'winter'
        ? [
            ['#5c7fa6', '#eef5fc', '#3c5673'],
            ['#738fa8', '#f2f7fd', '#4b6278'],
          ]
        : [
            ['#e8574a', '#f6efe2', '#a83a33'],
            ['#2fb3a3', '#f6efe2', '#1f8579'],
            ['#f2b33d', '#fbf4e4', '#c88a1f'],
          ];
  const [a, b, dk] = palettes[seed % palettes.length];
  // sombra do guarda-sol no chão
  shadowEllipse(ctx, 16, 29, 12, 3, 0.24);
  // cadeirinhas (laterais) e mesa
  ctx.fillStyle = '#5b3c25';
  ctx.fillRect(2, 24, 6, 5);
  ctx.fillRect(24, 24, 6, 5);
  ctx.fillStyle = '#a0703f';
  ctx.fillRect(2, 24, 6, 2);
  ctx.fillRect(24, 24, 6, 2);
  ctx.fillStyle = '#d8dde3';
  ctx.fillRect(10, 24, 12, 5);
  ctx.fillStyle = '#f4f6f8';
  ctx.fillRect(10, 24, 12, 2);
  ctx.fillStyle = '#8d96a3';
  ctx.fillRect(10, 28, 12, 1);
  // haste
  ctx.fillStyle = '#4a5468';
  ctx.fillRect(15, 11, 2, 14);
  // lona: octógono achatado com gomos alternados e borda escura
  const p = new Painter(ctx, 32, 34);
  const cx = 15.5;
  const cy = 8;
  for (let y = 0; y <= 15; y++) {
    for (let x = 0; x < 32; x++) {
      const dx = (x - cx) / 14.5;
      const dy = (y - cy) / 7.5;
      const d = Math.abs(dx) + Math.abs(dy) * 0.55 + Math.hypot(dx, dy) * 0.45;
      if (d > 1) continue;
      const ang = Math.atan2(y - cy, x - cx);
      const gomo = Math.floor(((ang + Math.PI) / (Math.PI * 2)) * 8) % 2;
      const edge = d > 0.86;
      const lit = y < cy - 1;
      p.set(x, y, edge ? dk : gomo ? (lit ? '#ffffff' : b) : lit ? a : dk);
    }
  }
  p.set(15, 8, '#2e3648');
  p.set(16, 8, '#2e3648');
  p.flush();
  return { canvas: c, ax: 16, ay: 29 };
}

/** Monte de folhas secas caídas no chão (outono). */
function leafPileSprite(seed: number): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(22, 12);
  shadowEllipse(ctx, 11, 9, 9, 2, 0.16);
  const p = new Painter(ctx, 22, 12);
  const cols = ['#8c3b20', '#b85228', '#d9762e', '#eba83b', '#6e351c'];
  for (let i = 0; i < 42; i++) {
    const a = rng() * Math.PI * 2;
    const r = rng() * 7.5;
    const x = Math.round(11 + Math.cos(a) * r);
    const y = Math.round(7 + Math.sin(a) * r * 0.45);
    const col = cols[Math.floor(rng() * cols.length)];
    p.set(x, y, col);
    if (rng() < 0.55) p.set(x + 1, y, col);
  }
  p.flush();
  return { canvas: c, ax: 11, ay: 10 };
}

/** Boneco de neve em pixel art (inverno). */
function snowmanSprite(seed: number): PropSprite {
  const [c, ctx] = makeCanvas(20, 26);
  shadowEllipse(ctx, 10, 23, 7, 2, 0.22);
  const p = new Painter(ctx, 20, 26);
  const ball = (cx: number, cy: number, r: number) => {
    for (let y = cy - r - 1; y <= cy + r + 1; y++) {
      for (let x = cx - r - 1; x <= cx + r + 1; x++) {
        const d2 = (x - cx) ** 2 + (y - cy) ** 2;
        if (d2 > r * r) continue;
        const edge = d2 >= (r - 0.9) ** 2;
        const lit = x - cx + (y - cy) < -1;
        p.set(x, y, edge ? '#4a5c70' : lit ? '#ffffff' : '#d5e3f0');
      }
    }
  };
  ball(10, 18, 5);
  ball(10, 10, 3.6);
  // gravetos (braços)
  for (let i = 1; i <= 3; i++) {
    p.set(5 - i, 15 - (i >> 1), '#5b3c25');
    p.set(15 + i, 15 - (i >> 1), '#5b3c25');
  }
  // olhos, nariz de cenoura e botões
  p.set(9, 9, '#222a38');
  p.set(11, 9, '#222a38');
  p.set(10, 10, '#f07829');
  p.set(11, 10, '#f07829');
  p.set(10, 16, '#222a38');
  p.set(10, 19, '#222a38');
  // cachecol colorido
  const scarf = seed % 2 === 0 ? '#d94848' : '#2f82b8';
  for (let x = 7; x <= 13; x++) p.set(x, 13, scarf);
  p.set(12, 14, scarf);
  p.set(12, 15, scarf);
  // cartola / gorro
  for (let x = 7; x <= 13; x++) p.set(x, 6, '#2b3242');
  for (let y = 3; y <= 5; y++) for (let x = 8; x <= 12; x++) p.set(x, y, '#394257');
  p.flush();
  return { canvas: c, ax: 10, ay: 23 };
}

/** Monte suave de neve acumulada (inverno). */
function snowdriftSprite(seed: number): PropSprite {
  const rng = mulberry32(seed);
  const [c, ctx] = makeCanvas(24, 12);
  const p = new Painter(ctx, 24, 12);
  canopy(p, rng, 12, 8, 5, ['#b5c8db', '#cfe0f0', '#e6f0fa', '#ffffff'], '#6d8299');
  p.flush();
  return { canvas: c, ax: 12, ay: 10 };
}

/** Totem da entrada com a marca (azul-marinho e laranja, como a placa da recepção). */
function totemSprite(): PropSprite {
  const [c, ctx] = makeCanvas(14, 34);
  shadowEllipse(ctx, 7, 32, 6, 1.5, 0.25);
  ctx.fillStyle = '#141b30';
  ctx.fillRect(2, 2, 10, 30);
  ctx.fillStyle = '#1c2541';
  ctx.fillRect(3, 3, 8, 28);
  ctx.fillStyle = '#2a355a';
  ctx.fillRect(3, 3, 1, 28);
  // faixa laranja no topo, "H" claro e "b" laranja (as cores de "Hab" e "blaud" na placa)
  ctx.fillStyle = '#f2a33a';
  ctx.fillRect(3, 5, 8, 2);
  ctx.fillStyle = '#f5f1e6';
  ctx.fillRect(4, 11, 1, 6);
  ctx.fillRect(8, 11, 1, 6);
  ctx.fillRect(5, 13, 3, 1);
  ctx.fillStyle = '#f2a33a';
  ctx.fillRect(5, 19, 1, 6);
  ctx.fillRect(6, 21, 2, 1);
  ctx.fillRect(8, 22, 1, 2);
  ctx.fillRect(6, 24, 2, 1);
  // base
  ctx.fillStyle = '#8d96a3';
  ctx.fillRect(1, 31, 12, 2);
  return { canvas: c, ax: 7, ay: 32 };
}

export function propSprite(prop: ExteriorProp, season: ExteriorSeason = 'summer'): PropSprite {
  const kind = prop.kind as string;
  const key = kind === 'totem' ? kind : `${season}:${kind}:${prop.seed % 7}`;
  let s = cache.get(key);
  if (s) return s;
  switch (kind) {
    case 'tree':
      s = treeSprite(prop.seed % 7, season);
      break;
    case 'pine':
      s = pineSprite(prop.seed % 7, season);
      break;
    case 'bush':
      s = bushSprite(prop.seed % 7, season);
      break;
    case 'flowers':
      s = flowersSprite(prop.seed % 7, season);
      break;
    case 'hedge':
      s = hedgeSprite(prop.seed % 7, season);
      break;
    case 'lamp':
      s = lampSprite(season);
      break;
    case 'bench':
      s = benchSprite(season);
      break;
    case 'rock':
      s = rockSprite(prop.seed % 7, season);
      break;
    case 'parasol':
      s = parasolSprite(prop.seed % 7, season);
      break;
    case 'leaf_pile':
      s = leafPileSprite(prop.seed % 7);
      break;
    case 'snowman':
      s = snowmanSprite(prop.seed % 7);
      break;
    case 'snowdrift':
      s = snowdriftSprite(prop.seed % 7);
      break;
    case 'totem':
      s = totemSprite();
      break;
    default:
      // 'paving' e outros tipos desenhados pelo próprio renderer
      s = { canvas: makeCanvas(1, 1)[0], ax: 0, ay: 0 };
  }
  cache.set(key, s);
  return s;
}

const CAR_COLORS: [string, string, string][] = [
  ['#d9534a', '#a83a33', '#f08a80'],
  ['#3f7fd8', '#2c5ea6', '#7fb0f0'],
  ['#f2f2ee', '#c4c6c8', '#ffffff'],
  ['#f2b33d', '#c88a1f', '#ffd889'],
  ['#2fb3a3', '#1f8579', '#79dccf'],
  ['#4a5468', '#323a4a', '#76819a'],
];

/** Carro visto de lado (3/4), virado para a direita; `flip` desenha para a esquerda. */
export function carSprite(variant: number, flip: boolean): PropSprite {
  const key = `car:${variant % CAR_COLORS.length}:${flip ? 1 : 0}`;
  const hit = cache.get(key);
  if (hit) return hit;
  const [body, dark, light] = CAR_COLORS[variant % CAR_COLORS.length];
  const [c, ctx] = makeCanvas(36, 20);
  if (flip) {
    ctx.translate(36, 0);
    ctx.scale(-1, 1);
  }
  shadowEllipse(ctx, 18, 17, 16, 2, 0.3);
  const o = '#2e3648';
  // carroceria
  ctx.fillStyle = o;
  ctx.fillRect(2, 8, 32, 8);
  ctx.fillRect(8, 3, 18, 6);
  ctx.fillStyle = body;
  ctx.fillRect(3, 9, 30, 6);
  ctx.fillRect(9, 4, 16, 5);
  ctx.fillStyle = light;
  ctx.fillRect(3, 9, 30, 1);
  ctx.fillRect(9, 4, 16, 1);
  ctx.fillStyle = dark;
  ctx.fillRect(3, 13, 30, 2);
  // vidros
  ctx.fillStyle = '#3a5f86';
  ctx.fillRect(10, 5, 6, 3);
  ctx.fillRect(18, 5, 6, 3);
  ctx.fillStyle = '#9cc7ec';
  ctx.fillRect(10, 5, 2, 1);
  ctx.fillRect(18, 5, 2, 1);
  // farol e lanterna
  ctx.fillStyle = '#fff3c4';
  ctx.fillRect(32, 10, 2, 2);
  ctx.fillStyle = '#e04a3a';
  ctx.fillRect(2, 10, 1, 2);
  // rodas
  for (const wx of [7, 25]) {
    ctx.fillStyle = o;
    ctx.fillRect(wx, 13, 5, 5);
    ctx.fillStyle = '#6b7385';
    ctx.fillRect(wx + 1, 14, 3, 3);
    ctx.fillStyle = '#9aa3b5';
    ctx.fillRect(wx + 2, 15, 1, 1);
  }
  const s = { canvas: c, ax: 18, ay: 17 };
  cache.set(key, s);
  return s;
}

/** Sombra de contato sob os personagens. */
export function shadowSprite(): PropSprite {
  const hit = cache.get('shadow');
  if (hit) return hit;
  const [c, ctx] = makeCanvas(14, 6);
  shadowEllipse(ctx, 7, 3, 6, 2, 0.28);
  const s = { canvas: c, ax: 7, ay: 3 };
  cache.set('shadow', s);
  return s;
}

/** Brilho radial (desenhado com composição aditiva). */
export function glowSprite(color: string, size = 64): HTMLCanvasElement {
  const key = `glow:${color}:${size}`;
  const hit = cache.get(key);
  if (hit) return hit.canvas;
  const [c, ctx] = makeCanvas(size, size);
  const g = ctx.createRadialGradient(size / 2, size / 2, 0, size / 2, size / 2, size / 2);
  const [r, gg, b] = hex(color);
  g.addColorStop(0, `rgba(${r},${gg},${b},0.9)`);
  g.addColorStop(0.4, `rgba(${r},${gg},${b},0.35)`);
  g.addColorStop(1, `rgba(${r},${gg},${b},0)`);
  ctx.fillStyle = g;
  ctx.fillRect(0, 0, size, size);
  cache.set(key, { canvas: c, ax: size / 2, ay: size / 2 });
  return c;
}
