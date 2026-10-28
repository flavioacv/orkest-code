import { FURNITURE, TILE, type FurnitureSprites, type Sprite } from '../../third_party/office_engine/client/src/art/api.ts';
import type { Renderer } from '../../third_party/office_engine/client/src/world/render/renderer.ts';
import type { OrkestSim } from './sim.ts';
import { COWORKING_SEATS } from '../../third_party/office_engine/client/src/world/layout/coworking.ts';
import { catalog } from './sprite_assets/catalog.ts';
import { loadExterior, loadRaster, scaledSprite } from './sprite_assets/exterior.ts';

type Scales = { vegetation: number; vehicles: number; furniture: number };
const storageKey = 'orkest.office.sprite-scales.v1';
const defaults: Scales = { vegetation: 70, vehicles: 50, furniture: 70 };
function readScales(): Scales {
  const scales = { ...defaults };
  try {
    const saved: unknown = JSON.parse(localStorage.getItem(storageKey) ?? 'null');
    if (saved && typeof saved === 'object') for (const key of Object.keys(defaults) as (keyof Scales)[]) {
      const value = (saved as Record<string, unknown>)[key];
      if (typeof value === 'number' && Number.isFinite(value)) scales[key] = Math.max(0, Math.min(100, Math.round(value)));
    }
  } catch (error) { console.warn('Não foi possível recuperar as escalas do Office.', error); }
  return scales;
}

/** The same installation is used by the actual Office and its browser preview. */
export async function installSpriteMix(renderer: Renderer, sim: OrkestSim, onFurnitureScale?: (percent: number) => void): Promise<() => void> {
  const [exterior, rasters] = await Promise.all([
    loadExterior(), Promise.all(catalog.map(entry => loadRaster(entry))),
  ]);
  const scales = readScales();
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

  const controls = document.createElement('details');
  controls.id = 'office-sprite-controls';
  controls.open = true;
  controls.style.cssText = 'position:fixed;right:14px;top:14px;z-index:20;width:278px;max-width:calc(100vw - 28px);padding:10px 12px;border:1px solid var(--ckp-border,GrayText);border-radius:8px;background:var(--ckp-bg-raised,Canvas);color:var(--ckp-text,CanvasText);font:12px system-ui';
  const summary = document.createElement('summary');
  summary.textContent = 'Escala dos sprites'; summary.style.cursor = 'pointer'; controls.append(summary);
  const description = document.createElement('p');
  description.textContent = '100% = tamanho do PNG. 0% oculta a categoria nova.';
  description.style.cssText = 'margin:8px 0;color:var(--ckp-text-secondary,GrayText)'; controls.append(description);
  const outputs = new Map<keyof Scales, { input: HTMLInputElement; output: HTMLOutputElement }>();
  function apply() {
    cache.clear();
    onFurnitureScale?.(scales.furniture);
    if (scales.furniture === 0) sim.stopCoworkingTest();
    alignSeats();
    exterior.setScales(scales.vegetation, scales.vehicles, scales.furniture);
    try { localStorage.setItem(storageKey, JSON.stringify(scales)); }
    catch (error) { console.warn('Não foi possível salvar as escalas do Office.', error); }
    for (const [key, { input, output }] of outputs) { input.value = String(scales[key]); output.value = `${scales[key]}%`; }
  }
  for (const [key, label] of [
    ['vegetation', 'Árvores e arbustos'], ['vehicles', 'Veículos'], ['furniture', 'Móveis novos'],
  ] as const) {
    const row = document.createElement('label');
    row.style.cssText = 'display:grid;grid-template-columns:1fr 42px;gap:6px;margin:10px 0';
    const text = document.createElement('span'); text.textContent = label;
    const output = document.createElement('output'); output.value = `${scales[key]}%`; output.style.textAlign = 'right';
    const input = document.createElement('input');
    input.id = `scale-${key}`; input.type = 'range'; input.min = '0'; input.max = '100'; input.step = '1'; input.value = String(scales[key]);
    input.style.cssText = 'grid-column:1 / -1;width:100%;margin:0';
    input.oninput = () => { scales[key] = Number(input.value); apply(); };
    outputs.set(key, { input, output }); row.append(text, output, input); controls.append(row);
  }
  const reset = document.createElement('button');
  reset.textContent = 'Restaurar padrão'; reset.type = 'button';
  reset.onclick = () => { Object.assign(scales, defaults); apply(); }; controls.append(reset);
  const coworking = document.createElement('button'); coworking.type = 'button';
  coworking.textContent = 'Ir ao coworking'; coworking.style.marginLeft = '8px';
  coworking.onclick = () => window.orkestOfficeWorld.focusArea('core:lounge'); controls.append(coworking);
  const interaction = document.createElement('fieldset'); interaction.style.cssText = 'margin:12px 0 0;padding:8px;border:1px solid var(--ckp-border,GrayText)';
  const legend = document.createElement('legend'); legend.textContent = 'Testar personagem'; interaction.append(legend);
  const feedback = document.createElement('p'); feedback.style.cssText = 'margin:8px 0 0'; feedback.setAttribute('aria-live', 'polite');
  let lastMessage = 'Escolha uma área. O personagem usa o assento por 30 segundos.';
  let wasTesting = false;
  for (const [zone, name] of [['focus', 'Mesa individual'], ['meeting', 'Poltrona'], ['lounge', 'Coworking']] as const) {
    const button = document.createElement('button'); button.type = 'button'; button.id = `test-${zone}`;
    button.textContent = name; button.style.margin = '0 4px 4px 0';
    button.onclick = () => {
      if (scales.furniture === 0 && zone === 'lounge') { lastMessage = 'Aumente a escala dos móveis para visualizar o teste.'; return; }
      const result = window.orkestOfficeWorld.testCoworking(zone); lastMessage = result.message;
    }; interaction.append(button);
  }
  const group = document.createElement('button'); group.type = 'button'; group.id = 'test-group'; group.textContent = 'Ocupar assentos';
  group.onclick = () => {
    if (!scales.furniture) { lastMessage = 'Aumente a escala dos móveis para visualizar os assentos do coworking.'; return; }
    lastMessage = window.orkestOfficeWorld.testCoworkingGroup().message;
  }; interaction.append(group);
  const stop = document.createElement('button'); stop.type = 'button'; stop.id = 'test-stop'; stop.textContent = 'Encerrar teste';
  stop.onclick = () => { window.orkestOfficeWorld.stopCoworkingTest(); lastMessage = 'Teste encerrado. O personagem retoma sua atividade.'; };
  interaction.append(stop, feedback); controls.append(interaction);
  const timer = setInterval(() => {
    const state = window.orkestOfficeWorld.getCoworkingTest();
    if (state) wasTesting = true;
    else if (wasTesting) { lastMessage = 'Teste encerrado. O personagem retoma sua atividade.'; wasTesting = false; }
    const place = state?.zone === 'focus' ? 'mesa individual' : state?.zone === 'meeting' ? 'poltrona' : 'sofá coletivo';
    const visits = window.orkestOfficeWorld.getCoworkingTests();
    feedback.textContent = visits.length > 1 ? `${visits.filter(visit => visit.phase === 'using').length}/${visits.length} personagens sentados no lounge e coworking.` : state ? `${state.name}: ${state.phase === 'using' ? 'usando' : 'caminhando até'} ${place}.` : lastMessage;
  }, 250);
  feedback.textContent = lastMessage;
  const exteriorButton = document.createElement('button'); exteriorButton.type = 'button'; exteriorButton.id = 'view-exterior';
  exteriorButton.textContent = 'Ver exterior'; exteriorButton.style.marginTop = '8px';
  exteriorButton.onclick = () => window.orkestOfficeWorld.overview(); controls.append(exteriorButton);
  const outdoorSelect = document.createElement('select'); outdoorSelect.id = 'outdoor-place';
  outdoorSelect.setAttribute('aria-label', 'Visitar área externa'); outdoorSelect.style.cssText = 'margin:8px 0 0 8px;max-width:145px';
  for (const [value, label] of [['', 'Visitar exterior…'], ['garden', 'Jardim externo'], ['camp', 'Acampamento'], ['pond', 'Rio e ponte'], ['fountain', 'Praça da fonte'], ['station', 'Estação de trem'], ['market', 'Vendedores'], ['woodland', 'Bosque e lenhador']]) {
    const option = document.createElement('option'); option.value = value; option.textContent = label; outdoorSelect.append(option);
  }
  outdoorSelect.onchange = () => { if (outdoorSelect.value) window.orkestOfficeWorld.focusOutdoor(outdoorSelect.value); };
  controls.append(outdoorSelect);
  document.body.append(controls);
  return () => {
    clearInterval(timer); controls.remove(); cache.clear(); renderer.exteriorSprites = previousExterior; renderer.furnitureOverride = previousFurniture;
  };
}
