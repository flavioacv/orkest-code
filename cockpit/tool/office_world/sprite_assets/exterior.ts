import type { Renderer } from '../../../third_party/office_engine/client/src/world/render/renderer.ts';
import type { PropSprite } from '../../../third_party/office_engine/client/src/world/render/props.ts';
import { catalog } from './catalog.ts';
import { sampleTrainJourney } from '../../../third_party/office_engine/client/src/world/layout/train.ts';
import { foliage } from './foliage.ts';
import { composeRiver, composeTrain, stationTrack, stationShelter, tiledTrack, snowySprite } from './outdoor_composites.ts';

type Entry = { readonly url: string; readonly crop: readonly [number, number, number, number] };
export async function loadRaster(entry: Entry, flip = false): Promise<PropSprite> {
  const image = new Image();
  await new Promise<void>((resolve, reject) => {
    image.onload = () => resolve();
    image.onerror = () => reject(new Error('Não foi possível carregar um asset externo'));
    image.src = entry.url;
  });
  const [sx, sy, ex, ey] = entry.crop;
  const canvas = document.createElement('canvas');
  canvas.width = ex - sx; canvas.height = ey - sy;
  const ctx = canvas.getContext('2d')!;
  ctx.imageSmoothingEnabled = false;
  if (flip) { ctx.translate(canvas.width, 0); ctx.scale(-1, 1); }
  ctx.drawImage(image, sx, sy, ex - sx, ey - sy, 0, 0, canvas.width, canvas.height);
  return { canvas, ax: canvas.width / 2, ay: canvas.height };
}

export function scaledSprite(source: PropSprite, percent: number): PropSprite {
  const factor = Math.max(0, Math.min(100, percent)) / 100;
  const canvas = document.createElement('canvas');
  canvas.width = Math.max(1, Math.round(source.canvas.width * factor));
  canvas.height = Math.max(1, Math.round(source.canvas.height * factor));
  const ctx = canvas.getContext('2d')!;
  ctx.imageSmoothingEnabled = false;
  if (factor > 0) ctx.drawImage(source.canvas, 0, 0, canvas.width, canvas.height);
  return { canvas, ax: source.ax * factor, ay: source.ay * factor };
}

export async function loadExterior(): Promise<NonNullable<Renderer['exteriorSprites']> & { setScales(vegetation: number, vehicles: number, furniture?: number): void }> {
  const rawPlants = await Promise.all(foliage.map(entry => loadRaster(entry)));
  let plants = rawPlants.map(plant => scaledSprite(plant, 50));
  // The PNGs are oriented explicitly, rather than inferring direction from their opaque IDs.
  const rawCars = await Promise.all([20, 21, 22, 23, 24, 53].map(async index => ({
    right: await loadRaster(catalog[index], index === 23), left: await loadRaster(catalog[index], index !== 23),
  })));
  const rawDecor = await Promise.all([31, 32, 33].map(index => loadRaster(catalog[index])));
  let decor = rawDecor.map(source => scaledSprite(source, 50));
  const extraEntries = [34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 3, 45, 46, 47, 4];
  const rawExtras = await Promise.all(extraEntries.map(index => loadRaster(catalog[index])));
  let extras = rawExtras.map(source => scaledSprite(source, 70));
  const riverWater = await loadRaster(catalog[52]);
  let river = composeRiver(riverWater, 70);
  const rawTrain = composeTrain(await loadRaster(catalog[54]), await loadRaster(catalog[55]));
  const trainFlip = document.createElement('canvas'); trainFlip.width = rawTrain.canvas.width; trainFlip.height = rawTrain.canvas.height;
  const trainCtx = trainFlip.getContext('2d')!; trainCtx.translate(trainFlip.width, 0); trainCtx.scale(-1, 1); trainCtx.drawImage(rawTrain.canvas, 0, 0);
  const rawTrainLeft = { canvas: trainFlip, ax: rawTrain.ax, ay: rawTrain.ay };
  let train = scaledSprite(rawTrain, 50), trainLeft = scaledSprite(rawTrainLeft, 50);
  let trainStart: number | null = null;
  const rawTrack = stationTrack(), rawShelter = stationShelter();
  let track = scaledSprite(rawTrack, 70), shelter = scaledSprite(rawShelter, 70);
  // Explicit approved colors: yellow, white, black and both greens; no purple tents.
  const rawModernTents = await Promise.all([70, 57, 71, 59, 60].map(index => loadRaster(catalog[index])));
  const rawClassicTents = await Promise.all([61, 62, 63, 64, 65].map(index => loadRaster(catalog[index])));
  let modernTents = rawModernTents.map(source => scaledSprite(source, 70));
  let classicTents = rawClassicTents.map(source => scaledSprite(source, 70));
  const rawMarket = await Promise.all([66, 67, 68, 69].map(index => loadRaster(catalog[index])));
  let market = rawMarket.map(source => scaledSprite(source, 70));
  const hidden = scaledSprite(rawExtras[7], 0);
  const tracks = new Map<number, PropSprite>();
  // Repeat the small shrub across the existing hedge footprint, without recoloring it.
  const hedge = document.createElement('canvas'); hedge.width = 64; hedge.height = 24;
  const hctx = hedge.getContext('2d')!; hctx.imageSmoothingEnabled = false;
  for (const x of [0, 18, 36]) hctx.drawImage(rawPlants[10].canvas, x, 0);
  const rawHedge = { canvas: hedge, ax: 32, ay: 24 };
  let hedgeSprite = scaledSprite(rawHedge, 50);
  let cars = rawCars.map(pair => ({ right: scaledSprite(pair.right, 50), left: scaledSprite(pair.left, 50) }));
  return {
    setScales(vegetation, vehicles, furniture = 50) {
      decor = rawDecor.map(source => scaledSprite(source, furniture));
      extras = rawExtras.map(source => scaledSprite(source, furniture));
      extras[15] = scaledSprite(rawExtras[15], furniture * .6);
      river = composeRiver(riverWater, furniture);
      train = scaledSprite(rawTrain, vehicles); trainLeft = scaledSprite(rawTrainLeft, vehicles);
      track = scaledSprite(rawTrack, furniture); shelter = scaledSprite(rawShelter, furniture);
      modernTents = rawModernTents.map(source => scaledSprite(source, furniture));
      market = rawMarket.map(source => scaledSprite(source, furniture));
      tracks.clear();
      classicTents = rawClassicTents.map(source => scaledSprite(source, furniture));
      plants = rawPlants.map(plant => scaledSprite(plant, vegetation));
      hedgeSprite = scaledSprite(rawHedge, vegetation);
      cars = rawCars.map(pair => ({ right: scaledSprite(pair.right, vehicles), left: scaledSprite(pair.left, vehicles) }));
    },
    position(prop, now) {
      if (prop.kind !== 'train') return prop;
      trainStart ??= now;
      const journey = sampleTrainJourney((now - trainStart) / 1000, prop.x, prop.seed);
      return { ...prop, x: journey.x, seed: journey.dir };
    },
    car(variant, flip) {
      const pair = cars[((variant % cars.length) + cars.length) % cars.length];
      return flip ? pair.left : pair.right;
    },
    prop(prop, season) {
      const seed = Math.abs(prop.seed);
      const seasonal = (sprite: PropSprite) => season === 'winter' ? snowySprite(sprite) : sprite;
      if (season === 'winter' && ['duck', 'duckling', 'goose', 'hen'].includes(prop.kind)) return hidden;
      switch (prop.kind) {
        case 'rock': return seasonal(extras[seed % 2]);
        case 'boulder': return seasonal(extras[2]);
        case 'fountain_large': return seasonal(extras[3]);
        case 'fountain_small': return seasonal(extras[4]);
        case 'tent_classic': return seasonal(classicTents[seed % classicTents.length]);
        case 'duckling': return extras[7];
        case 'goose': return extras[8];
        case 'hen': return extras[9];
        case 'dove': return extras[10];
        case 'stream_lake': return seasonal(river);
        case 'station_track': {
          let full = tracks.get(prop.seed);
          if (!full) { full = tiledTrack(track, prop.seed); tracks.set(prop.seed, full); }
          return seasonal(full);
        }
        case 'station_shelter': return seasonal(shelter);
        case 'train': return seasonal(prop.seed < 0 ? trainLeft : train);
        case 'vendor_cart': return seasonal(market[0]);
        case 'vendor_stall': return seasonal(market[1]);
        case 'stump': return seasonal(market[2 + seed % 2]);
        case 'bridge': return seasonal(extras[15]);
        case 'pond': return seasonal(extras[11]);
        case 'garden_set': return season === 'winter' ? snowySprite(extras[12], true) : extras[12];
        case 'tent': return seasonal(modernTents[seed % modernTents.length]);
        case 'statue': return decor[1];
        case 'duck': return decor[2];
        case 'tree':
          if (season === 'winter') return plants[seed % 3 === 0 ? 5 : 3];
          if (season === 'autumn') return plants[2];
          if (season === 'spring') return plants[seed % 3 === 0 ? 4 : seed % 2];
          return plants[seed % 5 === 0 ? 9 : seed % 2];
        case 'pine': return plants[season === 'winter' ? 8 : season === 'autumn' ? 7 : 6];
        case 'bush': return seasonal(plants[10 + seed % 3]);
        case 'hedge': return seasonal(hedgeSprite);
        case 'flowers': return seasonal(plants[13]);
        default: return null;
      }
    },
  };
}
