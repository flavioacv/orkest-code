document.addEventListener('contextmenu', event => event.preventDefault(), { capture: true });
import * as art from '../../third_party/office_engine/client/src/art/index.ts';
import { PART_KEYS, type AppearanceParts, type PartKey } from '../../third_party/office_engine/shared/appearance.ts';
import { SoundBoard } from '../../third_party/office_engine/client/src/audio/board.ts';
import { DEFAULT_SOUND_SETTINGS, type SoundSettings } from '../../third_party/office_engine/client/src/audio/scheduler.ts';
import { DEFAULT_WORLD_OPTIONS, exteriorSeasonFor, seasonalThemeFor } from '../../third_party/office_engine/client/src/world/api.ts';
import type { WorldOptions } from '../../third_party/office_engine/client/src/world/api.ts';
import { Camera, overviewFrame } from '../../third_party/office_engine/client/src/world/camera.ts';
import { BUILDING_H, COL_W, TILE, configureOfficeLayout } from '../../third_party/office_engine/client/src/world/constants.ts';
import { attachInput } from '../../third_party/office_engine/client/src/world/input.ts';
import { Overlay } from '../../third_party/office_engine/client/src/world/render/overlay.ts';
import { Renderer } from '../../third_party/office_engine/client/src/world/render/renderer.ts';
import { OrkestSim, type CoworkingZone, type CoworkingTestState } from './sim.ts';
import { SoundCues } from '../../third_party/office_engine/client/src/world/sound-cues.ts';
import { __OFFICE_ASSETS__ } from './assets.ts';
import { setLocale, getLocale, normalizeLocale } from '../../third_party/office_engine/shared/i18n.ts';
import { outdoorLifeLayout } from '../../third_party/office_engine/client/src/world/layout/outdoor-life.ts';
import { OutdoorPeople } from './outdoor_people.ts';
import { installSpriteMix } from './sprite_mix.ts';

configureOfficeLayout(true);
const canvas = document.querySelector<HTMLCanvasElement>('#office')!;
let options: WorldOptions = { ...DEFAULT_WORLD_OPTIONS };
const camera = new Camera();
const sim = new OrkestSim(art, () => options, null);
const soundBoard = new SoundBoard();
const soundCues = new SoundCues(sim, camera);
const renderer = new Renderer(canvas, art, sim, camera);
const outdoorPeople = new OutdoorPeople(art);
renderer.outdoorActors = dt => outdoorPeople.update(dt, sim.building.cols, exteriorSeasonFor(options.season, new Date()));
const overlay = new Overlay(renderer.ctx, sim, renderer, camera);
let snapshotRev = 0;
let selectedAgent: string | null = null;
let hoveredAgent: string | null = null;
let userMoved = false;
let lastCols = -1;
let lastTs = 0;
let raf = 0;
let destroyed = false;
let disposeSpriteMix: (() => void) | null = null;
void installSpriteMix(renderer, sim, percent => outdoorPeople.setFurnitureScale(percent)).then(dispose => {
  if (destroyed) dispose();
  else disposeSpriteMix = dispose;
});
let receivedFirstSnapshot = false;
let soundEnabled = false;
const lastAgentStatuses = new Map<string, string>();

function unlockAudio() {
  if (soundEnabled) void soundBoard.unlock();
}
window.addEventListener('pointerdown', unlockAudio, { passive: true });
window.addEventListener('keydown', unlockAudio);

function loadImage(file: string): Promise<HTMLImageElement | null> {
  return new Promise((resolve) => {
    const image = new Image();
    image.decoding = 'async';
    image.onload = () => resolve(image.naturalWidth ? image : null);
    image.onerror = () => resolve(null);
    const encoded = __OFFICE_ASSETS__[file];
    image.src = encoded ? `data:image/png;base64,${encoded}` : '';
  });
}

async function loadAssets() {
  const manifestData = __OFFICE_ASSETS__['manifest.json'];
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
  renderer.setAssets({ wallArt });
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
  renderer.sync(seasonalThemeFor(options.theme, new Date()), exteriorSeasonFor(options.season, new Date()));
  updateBounds();
  if (sim.initialized && !userMoved) overview(false);
}

function buildingRect() {
  return { x: 0, y: 0, w: sim.building.cols * COL_W * TILE, h: BUILDING_H * TILE };
}

function updateBounds() {
  const e = renderer.exterior.bounds;
  const bounds = { x: e.x * TILE, y: e.y * TILE, w: e.w * TILE, h: e.h * TILE };
  camera.bounds = bounds;
  camera.minZoom = Math.min(6, Math.max(
    (camera.viewW - camera.insets.left - camera.insets.right) / bounds.w,
    (camera.viewH - camera.insets.top - camera.insets.bottom) / bounds.h,
  ));
  camera.clamp();
}

function overview(animate: boolean, exterior = false) {
  const bounds = buildingRect();
  const e = renderer.exterior.bounds;
  const frame = exterior
    ? { zoom: camera.minZoom, cx: (e.x + e.w / 2) * TILE, cy: (e.y + e.h / 2) * TILE, dy: 0 }
    : overviewFrame(bounds, camera.viewW, camera.viewH, camera.insets);
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

function focusAgent(id: string, follow = false) {
  const person = sim.person(id);
  if (!person) return;
  userMoved = true;
  camera.stop();
  const zoom = Math.max(camera.zoom, camera.snapZoom(3));
  const center = camera.centerFor(person.x, person.y - 12, zoom);
  camera.animateTo(center.x, center.y, zoom, Date.now(), 420);
  camera.follow = follow ? id : null;
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
  const nowDate = new Date();
  renderer.sync(seasonalThemeFor(options.theme, nowDate), exteriorSeasonFor(options.season, nowDate));
  if (sim.building.cols !== lastCols) {
    lastCols = sim.building.cols;
    updateBounds();
    if (sim.initialized && !userMoved) overview(true);
  }
  const followed = camera.follow ? sim.person(camera.follow) : undefined;
  if (camera.follow && !followed) camera.follow = null;
  camera.update(
    now,
    followed
      ? camera.centerFor(followed.x, followed.y - 12, camera.zoom)
      : null,
    dt,
  );
  renderer.frame(now, dt, options, { agent: selectedAgent, room: null, hover: hoveredAgent });
  overlay.draw(now, options, { agent: selectedAgent, room: null, hover: hoveredAgent });
  renderer.pruneHeads();
  soundCues.update(now, (cue) => soundBoard.play(cue.kind, cue));
}

function portraitCanvas(source: HTMLCanvasElement): HTMLCanvasElement {
  const data = source.getContext('2d')!.getImageData(0, 0, source.width, source.height).data;
  let x0 = source.width, y0 = source.height, x1 = -1, y1 = -1;
  for (let y = 0; y < source.height; y++) for (let x = 0; x < source.width; x++) {
    if (data[(y * source.width + x) * 4 + 3] <= 16) continue;
    x0 = Math.min(x0, x); y0 = Math.min(y0, y); x1 = Math.max(x1, x); y1 = Math.max(y1, y);
  }
  if (x1 < 0) return source;
  const cropped = document.createElement('canvas');
  cropped.width = x1 - x0 + 1; cropped.height = y1 - y0 + 1;
  cropped.getContext('2d')!.drawImage(source, x0, y0, cropped.width, cropped.height, 0, 0, cropped.width, cropped.height);
  return cropped;
}

window.orkestOfficeWorld = {
  focusOutdoor(place: string) {
    const layout = outdoorLifeLayout(sim.building.cols);
    const target = place === 'camp' ? layout.camp : place === 'pond' ? layout.pond : place === 'fountain' ? layout.fountain : place === 'garden' ? layout.garden : place === 'station' ? layout.station : place === 'woodland' ? layout.woodland : place === 'market' ? layout.market : null;
    if (!target) return;
    userMoved = true; camera.follow = null;
    const zoom = Math.min(2, camera.viewW / (place === 'station' ? 1000 : 560), camera.viewH / 400);
    const center = camera.centerFor(target.x, target.y - 70, zoom);
    camera.animateTo(center.x, center.y, zoom, Date.now(), 420);
  },
  testCoworking(zone: CoworkingZone) {
    const result = sim.startCoworkingTest(zone, selectedAgent ?? undefined);
    const state = sim.getCoworkingTest();
    if (result.ok && state) focusAgent(state.agentId, true);
    return result;
  },
  testCoworkingGroup() { return sim.startCoworkingGroup(); },
  getCoworkingTests() { return sim.getCoworkingTests(); },
  stopCoworkingTest() { sim.stopCoworkingTest(); camera.follow = null; },
  getCoworkingTest() { return sim.getCoworkingTest(); },
  focusArea(id: string) {
    const area = renderer.areas.get(id); if (!area) return;
    userMoved = true; camera.follow = null;
    const zoom = Math.min(2, camera.viewW / (area.px.w + 64), camera.viewH / (area.px.h + 96));
    const center = camera.centerFor(area.px.x + area.px.w / 2, area.px.y + area.px.h / 2, zoom);
    camera.animateTo(center.x, center.y, zoom, Date.now(), 420);
  },
  overview() { userMoved = true; camera.follow = null; overview(true, true); },
  getSocialSnapshot() { return sim.sessionSocial.snapshot(); },
  getAppearance(seed: number, look: 'f' | 'm', parts: AppearanceParts = {}) {
    const appearance = art.fitToOptions({ ...art.appearanceFromSeed(seed, { look }), ...parts });
    const options = art.editorOptions(appearance);
    const selectable = Object.fromEntries(PART_KEYS.map((key) => [
      key,
      options[key].filter((value) => !art.editorConflict(appearance, key, value)),
    ])) as Record<PartKey, readonly string[]>;
    const sprite = art.characterSprite({ appearance, dir: 'down', pose: 'stand', frame: 0 });
    return {
      parts: Object.fromEntries(PART_KEYS.map((key) => [key, appearance[key]])),
      options: selectable,
      preview: portraitCanvas(sprite.canvas).toDataURL('image/png'),
      avatar: art.avatarCanvas(seed, { look, parts, scale: 3 }).toDataURL('image/png'),
    };
  },
  update(snapshot: any) {
    const now = Date.now();
    if (snapshot?.options && typeof snapshot.options === 'object') {
      const next = snapshot.options;
      if (typeof next.locale === 'string') {
        const locale = normalizeLocale(next.locale) ?? 'pt-BR';
        if (locale !== getLocale()) {
          setLocale(locale);
          for (const gathering of sim.social.gatherings) {
            gathering.pending.length = 0;
            gathering.lastLine = '';
          }
          for (const ch of sim.chars.values()) {
            ch.sayText = ''; ch.sayUntil = 0; ch.bubbleText = null;
          }
        }
      }
      options = {
        ...options,
        ...(typeof next.showNames === 'boolean' ? { showNames: next.showNames } : {}),
        ...(next.bubbles === 'all' || next.bubbles === 'important' || next.bubbles === 'none' ? { bubbles: next.bubbles } : {}),
        ...(next.liveliness === 'calm' || next.liveliness === 'normal' || next.liveliness === 'lively' ? { liveliness: next.liveliness } : {}),
        ...(next.daylight === 'auto' || next.daylight === 'day' || next.daylight === 'night' ? { daylight: next.daylight, dayNight: next.daylight !== 'day' } : {}),
        ...(next.theme === 'auto' || next.theme === 'none' || next.theme === 'christmas' || next.theme === 'halloween' ? { theme: next.theme } : {}),
        ...(next.season === 'auto' || next.season === 'auto_south' || next.season === 'auto_north' || next.season === 'spring' || next.season === 'summer' || next.season === 'autumn' || next.season === 'winter' ? { season: next.season } : {}),
      };
      soundEnabled = next.sound === true;
      const rawSounds = next.sounds && typeof next.sounds === 'object' ? next.sounds : {};
      const volume = typeof rawSounds.volume === 'number' && Number.isFinite(rawSounds.volume)
        ? Math.max(0, Math.min(1, rawSounds.volume))
        : DEFAULT_SOUND_SETTINGS.volume;
      const soundSettings: SoundSettings = {
        volume,
        alerts: typeof rawSounds.alerts === 'boolean' ? rawSounds.alerts : DEFAULT_SOUND_SETTINGS.alerts,
        keys: typeof rawSounds.keys === 'boolean' ? rawSounds.keys : DEFAULT_SOUND_SETTINGS.keys,
        elevator: typeof rawSounds.elevator === 'boolean' ? rawSounds.elevator : DEFAULT_SOUND_SETTINGS.elevator,
        social: typeof rawSounds.social === 'boolean' ? rawSounds.social : DEFAULT_SOUND_SETTINGS.social,
      };
      soundBoard.configure(soundEnabled, soundSettings);
    }
    // As salas nascem prontas no snapshot inicial; em seguida os agentes são
    // apresentados como novas chegadas pelo elevador, em vez de aparecerem já
    // sentados nas mesas (comportamento padrão do Habblaud para histórico).
    if (!receivedFirstSnapshot) {
      sim.applySnapshot({ ...snapshot, agents: [] }, now);
      receivedFirstSnapshot = true;
      for (const agent of Array.isArray(snapshot?.agents) ? snapshot.agents : []) {
        const id = String(agent?.id ?? '');
        if (id) lastAgentStatuses.set(id, String(agent?.status ?? ''));
      }
    } else {
      for (const agent of Array.isArray(snapshot?.agents) ? snapshot.agents : []) {
        const id = String(agent?.id ?? '');
        const status = String(agent?.status ?? '');
        const previous = lastAgentStatuses.get(id);
        if (previous !== undefined && previous !== 'waiting' && status === 'waiting') {
          soundBoard.play('chime');
        }
        if (id) lastAgentStatuses.set(id, status);
      }
    }
    sim.applySnapshot(snapshot, now);
    const nowDate = new Date();
    renderer.sync(seasonalThemeFor(options.theme, nowDate), exteriorSeasonFor(options.season, nowDate));
    if (sim.building.cols !== lastCols) {
      lastCols = sim.building.cols;
      updateBounds();
      if (sim.initialized && !userMoved) overview(false);
    }
    return snapshot.rev;
  },
  selectAgent(id: string | null) { selectedAgent = id; },
  focusAgent(id: string, follow = false) { focusAgent(id, follow); },
  setFollowAgent(id: string, follow: boolean) {
    if (!follow) {
      if (camera.follow === id) camera.follow = null;
      return;
    }
    focusAgent(id, true);
  },
  destroy() {
    destroyed = true;
    disposeSpriteMix?.();
    renderer.outdoorActors = null;
    cancelAnimationFrame(raf);
    window.removeEventListener('pointerdown', unlockAudio);
    window.removeEventListener('keydown', unlockAudio);
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
    orkestOfficeWorld: {
      focusOutdoor(place: string): void;
      testCoworking(zone: CoworkingZone): { ok: boolean; message: string };
      testCoworkingGroup(): { ok: boolean; message: string; count: number };
      getCoworkingTests(): CoworkingTestState[];
      stopCoworkingTest(): void;
      getCoworkingTest(): CoworkingTestState | null;
      focusArea(id: string): void;
      overview(): void;
      getSocialSnapshot(): unknown;
      getAppearance(seed: number, look: 'f' | 'm', parts?: Record<string, string>): {
        parts: Record<string, string>;
        options: Record<string, readonly string[]>;
        preview: string;
        avatar: string;
      };
      update(snapshot: unknown): number | undefined;
      selectAgent(id: string | null): void;
      focusAgent(id: string, follow?: boolean): void;
      setFollowAgent(id: string, follow: boolean): void;
      destroy(): void;
    };
    flutter_inappwebview?: { callHandler(name: string, ...args: unknown[]): Promise<unknown> };
  }
}
