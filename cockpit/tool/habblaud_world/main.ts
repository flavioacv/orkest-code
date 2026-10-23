import * as art from '../../../../habblaud/client/src/art/index.ts';
import { DEFAULT_WORLD_OPTIONS, seasonalThemeFor } from '../../../../habblaud/client/src/world/api.ts';
import type { WorldOptions } from '../../../../habblaud/client/src/world/api.ts';
import { Camera, overviewFrame } from '../../../../habblaud/client/src/world/camera.ts';
import { BUILDING_H, COL_W, TILE } from '../../../../habblaud/client/src/world/constants.ts';
import { attachInput } from '../../../../habblaud/client/src/world/input.ts';
import { Overlay } from '../../../../habblaud/client/src/world/render/overlay.ts';
import { Renderer } from '../../../../habblaud/client/src/world/render/renderer.ts';
import { Sim } from '../../../../habblaud/client/src/world/sim/sim.ts';
import { __HABBLAUD_ASSETS__ } from './assets.ts';

const canvas = document.querySelector<HTMLCanvasElement>('#office')!;
let options: WorldOptions = { ...DEFAULT_WORLD_OPTIONS };
const camera = new Camera();
const sim = new Sim(art, () => options, null);
const renderer = new Renderer(canvas, art, sim, camera);
const overlay = new Overlay(renderer.ctx, sim, renderer, camera);
let snapshotRev = 0;
let selectedAgent: string | null = null;
let hoveredAgent: string | null = null;
let userMoved = false;
let lastCols = -1;
let lastTs = 0;
let raf = 0;
let destroyed = false;

function loadImage(file: string): Promise<HTMLImageElement | null> {
  return new Promise((resolve) => {
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => resolve(image.naturalWidth ? image : null);
    image.onerror = () => resolve(null);
    const encoded = __HABBLAUD_ASSETS__[file];
    image.src = encoded ? `data:image/png;base64,${encoded}` : '';
  });
}

async function loadAssets() {
  const manifestData = __HABBLAUD_ASSETS__['manifest.json'];
  if (!manifestData) return;
  const manifest = JSON.parse(atob(manifestData));
  const list = Array.isArray(manifest.wallArt) ? manifest.wallArt : [];
  const [images, framed] = await Promise.all([
    Promise.all(list.map((item: any) => loadImage(item.file))),
    Promise.all(list.map((item: any) => item.framed ? loadImage(item.framed.file) : null)),
  ]);
  const wallArt = list.flatMap((item: any, index: number) => {
    const image = images[index];
    if (!image || !['painting', 'poster'].includes(item.kind)) return [];
    const frame = framed[index];
    return [{
      id: String(item.id),
      kind: item.kind,
      img: image,
      w: image.naturalWidth,
      h: image.naturalHeight,
      tiles: typeof item.tiles === 'number' ? item.tiles : item.kind === 'poster' ? 1 : image.naturalWidth > 40 ? 4 : 2,
      variant: typeof item.variant === 'string' ? item.variant : undefined,
      framed: frame ? { img: frame, w: frame.naturalWidth, h: frame.naturalHeight } : undefined,
    }];
  });
  const [signageImage, markImage] = await Promise.all([
    loadImage(manifest.brand?.signage?.file),
    loadImage(manifest.brand?.mark?.file),
  ]);
  renderer.setAssets({
    wallArt,
    ...(signageImage ? { signage: { img: signageImage, w: signageImage.naturalWidth, h: signageImage.naturalHeight } } : {}),
    ...(markImage ? { mark: { img: markImage, w: markImage.naturalWidth, h: markImage.naturalHeight } } : {}),
  });
}

function resize() {
  const rect = canvas.getBoundingClientRect();
  const dpr = Math.max(1, Math.min(3, window.devicePixelRatio || 1));
  const width = Math.max(1, Math.floor(rect.width * dpr));
  const height = Math.max(1, Math.floor(rect.height * dpr));
  if (canvas.width !== width || canvas.height !== height) {
    canvas.width = width;
    canvas.height = height;
  }
  camera.setView(rect.width, rect.height, dpr);
  updateBounds();
  if (sim.initialized && !userMoved) overview(false);
}

function buildingRect() {
  return { x: 0, y: 0, w: sim.building.cols * COL_W * TILE, h: BUILDING_H * TILE };
}

function updateBounds() {
  const bounds = buildingRect();
  camera.bounds = { x: bounds.x - 7 * TILE, y: bounds.y - 6 * TILE, w: bounds.w + 14 * TILE, h: bounds.h + 18 * TILE };
  camera.minZoom = Math.min(1, Math.max(0.25, camera.fitZoom(bounds, 16)));
  camera.clamp();
}

function overview(animate: boolean) {
  const frame = overviewFrame(buildingRect(), camera.viewW, camera.viewH, camera.insets);
  const fit = Math.max(camera.minZoom, frame.zoom);
  const snapped = camera.snapZoom(fit, 'down');
  const zoom = Math.min(4, snapped >= fit * 0.82 ? snapped : fit);
  const center = camera.centerFor(frame.cx, frame.cy, zoom);
  if (animate) camera.animateTo(center.x, center.y - frame.dy / zoom, zoom, Date.now(), 420);
  else {
    camera.stop();
    camera.x = center.x;
    camera.y = center.y - frame.dy / zoom;
    camera.zoom = zoom;
    camera.clamp();
  }
}

function pick(sx: number, sy: number): { type: 'agent'; id: string } | { type: 'room'; id: string } | null {
  const point = camera.screenToWorld(sx, sy);
  let best: string | null = null;
  let depth = -Infinity;
  const slack = Math.max(1, 3 / camera.zoom);
  for (const [id, head] of renderer.heads) {
    if (!head.visible || point.x < head.bx - slack || point.x > head.bx + head.bw + slack || point.y < head.by - slack || point.y > head.by + head.bh + slack) continue;
    if (head.depth > depth) { best = id; depth = head.depth; }
  }
  if (best) return { type: 'agent', id: best };
  const tx = Math.floor(point.x / TILE);
  const ty = Math.floor(point.y / TILE);
  for (const room of sim.rooms.values()) {
    const r = room.layout.rect;
    if (room.present && !room.ghost && tx >= r.x && tx < r.x + r.w && ty >= r.y && ty < r.y + r.h) return { type: 'room', id: room.id };
  }
  return null;
}

const detachInput = attachInput(canvas, camera, {
  pick,
  click: (hit) => {
    if (hit?.type === 'agent') window.flutter_inappwebview?.callHandler('officeAgentClicked', hit.id);
  },
  doubleClick: (hit) => {
    if (hit?.type === 'agent') window.flutter_inappwebview?.callHandler('officeAgentClicked', hit.id);
  },
  hover: (x, y, inside) => {
    const hit = inside ? pick(x, y) : null;
    hoveredAgent = hit?.type === 'agent' ? hit.id : null;
  },
  interact: () => { userMoved = true; camera.follow = null; camera.stop(); },
  overview: () => { userMoved = false; overview(true); },
  zoomStep: (steps, x = camera.viewW / 2, y = camera.viewH / 2) =>
    camera.zoomAt(camera.stepZoom(steps), x, y, Date.now(), true),
});

function loop(ts: number) {
  if (destroyed) return;
  raf = requestAnimationFrame(loop);
  const now = Date.now();
  const dt = lastTs ? Math.min(0.1, Math.max(0, (ts - lastTs) / 1000)) : 1 / 60;
  lastTs = ts;
  sim.update(dt, now);
  renderer.sync(seasonalThemeFor(options.theme, new Date()));
  if (sim.building.cols !== lastCols) {
    lastCols = sim.building.cols;
    updateBounds();
    if (sim.initialized && !userMoved) overview(true);
  }
  camera.update(now, null, dt);
  renderer.frame(now, dt, options, { agent: selectedAgent, room: null, hover: hoveredAgent });
  overlay.draw(now, options, { agent: selectedAgent, room: null, hover: hoveredAgent });
  renderer.pruneHeads();
}

window.cockpitHabblaudWorld = {
  update(snapshot: any) {
    const now = Date.now();
    if (snapshot?.options && typeof snapshot.options === 'object') {
      const next = snapshot.options;
      options = {
        ...options,
        ...(typeof next.showNames === 'boolean' ? { showNames: next.showNames } : {}),
        ...(next.bubbles === 'all' || next.bubbles === 'important' || next.bubbles === 'none' ? { bubbles: next.bubbles } : {}),
        ...(next.liveliness === 'calm' || next.liveliness === 'normal' || next.liveliness === 'lively' ? { liveliness: next.liveliness } : {}),
        ...(next.daylight === 'auto' || next.daylight === 'day' || next.daylight === 'night' ? { daylight: next.daylight, dayNight: next.daylight !== 'day' } : {}),
        ...(next.theme === 'auto' || next.theme === 'none' || next.theme === 'christmas' || next.theme === 'halloween' ? { theme: next.theme } : {}),
      };
    }
    sim.applySnapshot(snapshot, now);
    renderer.sync(seasonalThemeFor(options.theme, new Date()));
    if (sim.building.cols !== lastCols) {
      lastCols = sim.building.cols;
      updateBounds();
      if (sim.initialized && !userMoved) overview(false);
    }
  },
  selectAgent(id: string | null) { selectedAgent = id; },
  destroy() {
    destroyed = true;
    cancelAnimationFrame(raf);
    detachInput();
    window.removeEventListener('resize', resize);
  },
};

new ResizeObserver(resize).observe(canvas);
window.addEventListener('resize', resize);
resize();
void loadAssets();
raf = requestAnimationFrame(loop);

declare global {
  interface Window {
    cockpitHabblaudWorld: {
      update(snapshot: unknown): void;
      selectAgent(id: string | null): void;
      destroy(): void;
    };
    flutter_inappwebview?: { callHandler(name: string, ...args: unknown[]): Promise<unknown> };
  }
}
