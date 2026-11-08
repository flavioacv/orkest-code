import assert from 'node:assert/strict';
import test from 'node:test';
import { configureOfficeLayout, COL_W, CORE_COLS, CORRIDOR_Y, SOUTH_Y } from '../../third_party/office_engine/client/src/world/constants.ts';
import { assembleBuilding } from '../../third_party/office_engine/client/src/world/layout/building.ts';
import { ACTOR_SCALE, coworkingScene } from '../../third_party/office_engine/client/src/world/layout/floor-plan.ts';
import { renderFurniture } from '../../third_party/office_engine/client/src/art/furniture/index.ts';
import { layoutProjectRoom } from '../../third_party/office_engine/client/src/world/layout/room.ts';
import { slotRect } from '../../third_party/office_engine/client/src/world/layout/geometry.ts';
import { roomTheme } from '../../third_party/office_engine/client/src/art/index.ts';
import { PathFinder } from '../../third_party/office_engine/client/src/world/path/astar.ts';
import * as art from '../../third_party/office_engine/client/src/art/index.ts';
import { DEFAULT_WORLD_OPTIONS } from '../../third_party/office_engine/client/src/world/api.ts';
import { OrkestSim } from './sim.ts';
import { outdoorLifeLayout, sampleOutdoorRoute } from '../../third_party/office_engine/client/src/world/layout/outdoor-life.ts';
import { sampleTrainJourney } from '../../third_party/office_engine/client/src/world/layout/train.ts';
import { outdoorAppearance } from './outdoor_people.ts';
import { layoutExterior } from '../../third_party/office_engine/client/src/world/layout/exterior.ts';
import { BUILDING_H, TILE } from '../../third_party/office_engine/client/src/world/constants.ts';
import { Camera } from '../../third_party/office_engine/client/src/world/camera.ts';

test('responsive terrain expands the landscape without moving offices or outdoor landmarks', () => {
  configureOfficeLayout(true);
  try {
    for (const cols of [3, 4, 8, 16]) for (const aspect of [16 / 9, 21 / 9, 32 / 9, 3 / 2, 1 / 2]) {
      const original = layoutExterior(cols);
      const expanded = layoutExterior(cols, 'summer', aspect);
      const b = expanded.bounds;
      assert.ok(b.w >= b.h * Math.max(16 / 9, aspect));
      assert.equal(b.x + b.w / 2, original.bounds.x + original.bounds.w / 2);
      assert.equal(b.y, original.bounds.y);
      assert.equal(b.h, original.bounds.h);
      assert.ok(b.x <= original.bounds.x);
      assert.ok(b.x + b.w >= original.bounds.x + original.bounds.w);
      assert.deepEqual(expanded.lanes, original.lanes);
      for (const kind of ['station_shelter', 'fountain_large', 'garden_set']) {
        assert.deepEqual(expanded.props.find(prop => prop.kind === kind), original.props.find(prop => prop.kind === kind));
      }
      const track = expanded.props.find(prop => prop.kind === 'station_track')!;
      const train = expanded.props.find(prop => prop.kind === 'train')!;
      assert.equal(track.seed, b.w * TILE);
      assert.equal(track.x, (b.x + b.w / 2) * TILE);
      assert.equal(train.seed, track.seed);
      const street = expanded.floors.find(floor => floor.kind === 'street')!;
      assert.equal(street.x, b.x * TILE);
      assert.equal(street.w, b.w * TILE);
      if (b.w > original.bounds.w + 20) {
        assert.ok(expanded.props.some(prop => prop.kind === 'tree' && prop.x < original.bounds.x * TILE));
        assert.ok(expanded.props.some(prop => prop.kind === 'tree' && prop.x > (original.bounds.x + original.bounds.w) * TILE));
      }
    }
  } finally { configureOfficeLayout(false); }
});

test('legacy native terrain ignores browser aspect ratio', () => {
  configureOfficeLayout(false);
  assert.deepEqual(layoutExterior(4, 'summer', 32 / 9), layoutExterior(4));
});

test('camera fits and centers the full terrain without allowing a farther zoom out', () => {
  for (const [width, height] of [[1600, 900], [700, 1300], [900, 900]]) {
    const camera = new Camera();
    camera.setView(width, height, 2);
    camera.bounds = { x: -320, y: -480, w: 1920, h: 2080 };
    camera.minZoom = camera.fitZoom(camera.bounds, 24);
    camera.zoomAt(0.01, 0, 0, 0, false);
    assert.equal(camera.zoom, camera.minZoom);
    camera.panBy(-100000, 100000);
    const middle = camera.worldToScreen(640, 560);
    assert.ok(Math.abs(middle.x - width / 2) <= 1);
    assert.ok(Math.abs(middle.y - height / 2) <= 1);
    const topLeft = camera.worldToScreen(-320, -480);
    const bottomRight = camera.worldToScreen(1600, 1600);
    assert.ok(topLeft.x >= 23 && topLeft.y >= 23);
    assert.ok(bottomRight.x <= width - 23 && bottomRight.y <= height - 23);
    camera.zoomAt(2, width / 2, height / 2, 0, false);
    camera.panBy(100000, 100000);
    assert.ok(camera.screenToWorld(0, 0).x >= camera.bounds.x - 1);
    assert.ok(camera.screenToWorld(0, 0).y >= camera.bounds.y - 1);
  }
});

test('camera respects a dynamic minimum above the default at every zoom entry point', () => {
  const camera = new Camera();
  camera.minZoom = 1.4;
  assert.equal(camera.levels()[0], 1.4);
  camera.animateTo(0, 0, 0.2, 0, 10);
  camera.update(10, null, 0.01);
  assert.equal(camera.zoom, 1.4);
  camera.zoom = 0.2;
  camera.clamp();
  assert.equal(camera.zoom, 1.4);
});

test('night lighting covers both sidewalks, the promenade and the station in every season', () => {
  configureOfficeLayout(true);
  try {
    for (const season of ['spring', 'summer', 'autumn', 'winter'] as const) {
      const exterior = layoutExterior(5, season);
      const life = outdoorLifeLayout(5);
      const lamps = exterior.props.filter(prop => prop.kind === 'lamp');
      assert.ok(lamps.length >= 30);
      for (const point of [
        { x: 0, y: (BUILDING_H + 3) * TILE },
        { x: 0, y: (BUILDING_H + 10.5) * TILE },
        { x: life.garden.x, y: life.garden.y + 102 },
        { x: life.station.x, y: life.station.y - 40 },
      ]) assert.ok(lamps.some(lamp => Math.hypot(lamp.x - point.x, lamp.y - point.y) < 100));
    }
  } finally { configureOfficeLayout(false); }
});

test('unified floor plan connects every workstation and public interaction through the west entrance', () => {
  configureOfficeLayout(true);
  try {
    for (const cols of [4, 5, 8]) {
      const rooms = [0, 1, 2, 3].map(slot => layoutProjectRoom({ id: `room-${slot}`, slot, seed: slot + 1 }, roomTheme(slot + 1)));
      const building = assembleBuilding(cols, rooms);
      assert.ok(rooms.every(room => room.walls.length === 0 && room.furniture.length === 0));
      const desks = building.spots.filter(s => s.kind === 'desk');
      assert.equal(desks.length, 20 + (cols - 4) * 12);
      assert.equal(new Set(desks.map(s => `${s.tx},${s.ty}`)).size, desks.length);
      const entrance = building.spots.find(s => s.kind === 'elevator')!;
      const finder = new PathFinder(building.grid);
      const inaccessible = building.spots.filter(spot => !finder.find(entrance.tx, entrance.ty, spot.tx, spot.ty, []));
      assert.deepEqual(inaccessible.map(s => `${s.areaId}: ${s.kind} (${s.tx},${s.ty})`), []);
      for (const id of ['core:recepcao', 'core:banheiros', 'core:copa', 'core:focus', 'core:meeting', 'core:coworking', 'core:lounge', 'core:games']) {
        assert.ok(building.core.some(area => area.id === id));
      }
    }
  } finally { configureOfficeLayout(false); }
});

test('editable objects own their scaled cardinal seat anchors, back layers and collisions', () => {
  configureOfficeLayout(true);
  try {
    for (const cols of [4, 5, 8]) {
      const scene = coworkingScene(cols), building = assembleBuilding(cols, []);
      const nodes = new Map(scene.objects.map(node => [node.id, node]));
      assert.equal(nodes.size, scene.objects.length);
      for (const spot of building.spots.filter(s => s.seated)) {
        const node = nodes.get(spot.furnitureId!)!;
        assert.ok(node, `Missing object for ${spot.id}`);
        assert.ok(node.seatIds.includes(spot.id));
        assert.equal(spot.y, node.y + node.h - 3 * ACTOR_SCALE);
        assert.equal(spot.sortY, node.depth + .25);
        assert.ok(spot.x >= node.x && spot.x <= node.x + node.w);
        if (node.kind === 'office_chair') {
          assert.equal(spot.dir, 'up'); assert.ok(renderFurniture(node.kind, node.variant).front);
        } else if (node.kind === 'office_chair_front') {
          assert.equal(spot.dir, 'down'); assert.ok(!renderFurniture(node.kind, node.variant).front);
        } else if (node.kind === 'armchair' || node.kind === 'cafe_chair' || node.kind === 'sofa') {
          assert.equal(node.variant, spot.dir);
        }
        for (const object of scene.objects) if (object.collision) {
          const r = object.collision;
          assert.ok(spot.x < r.x || spot.x >= r.x + r.w || spot.y < r.y || spot.y >= r.y + r.h,
            `Seat ${spot.id} intersects ${object.id}`);
        }
      }
      for (const node of scene.objects.filter(n => n.collision)) {
        const r = node.collision!;
        const tx = Math.floor((r.x + r.w / 2) / TILE), ty = Math.floor((r.y + r.h / 2) / TILE);
        assert.equal(building.grid.walkable(tx, ty), false, `Missing collision: ${node.id}`);
      }
    }
  } finally { configureOfficeLayout(false); }
});

test('shared hall grows for sessions from multiple projects without moving existing desks', () => {
  configureOfficeLayout(true);
  try {
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    let time = 1_800_000_000_000;
    const input: Parameters<OrkestSim['applySnapshot']>[0] = {
      serverTime: time, accounts: [],
      rooms: [0, 1].map(slot => ({ id: `project-${slot}`, name: `Project ${slot}`, seed: slot + 1,
        slot, path: `/project/${slot}`, createdAt: time })),
      agents: Array.from({ length: 20 }, (_, i) => ({ id: `worker-${i}`, kind: 'main',
        roomId: `project-${i % 2}`, name: `Worker ${i}`, account: 'test', look: 'm', seed: i + 1,
        status: 'working', startedAt: time, statusSince: time, lastEventAt: time, tasks: [],
        stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 } })),
    };
    sim.applySnapshot(input, time);
    const original = [...sim.chars.values()].map(ch => ({ id: ch.id, home: ch.homeSpot, x: ch.x, y: ch.y }));
    for (const count of [21, 33, 45]) {
      const agents = Array.from({ length: count }, (_, i) => ({ ...input.agents[i % 20], id: `worker-${i}` }));
      sim.applySnapshot({ ...input, agents }, time);
      assert.equal(sim.building.cols, 4 + Math.ceil((count - 20) / 12));
      for (let frame = 0; frame < 10800; frame++) { time += 1000 / 60; sim.update(1 / 60, time); }
      assert.equal(new Set([...sim.chars.values()].map(ch => ch.homeSpot)).size, count);
      for (const ch of sim.chars.values()) {
        assert.ok(ch.homeSpot, `Missing desk for ${ch.id}`);
        assert.equal(ch.atSpot, ch.homeSpot, `Did not reach desk: ${ch.id}`);
        assert.equal(ch.seated, true);
      }
      for (const saved of original) {
        const ch = sim.chars.get(saved.id)!;
        assert.equal(ch.homeSpot, saved.home);
        assert.equal(ch.x, saved.x);
        assert.equal(ch.y, saved.y);
      }
      assert.ok(sim.building.rooms.every(room => room.walls.length === 0));
    }
  } finally { configureOfficeLayout(false); }
});

test('expansion keeps a seated meeting participant attached to the glass room', () => {
  configureOfficeLayout(true);
  try {
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    const time = 1_800_000_000_000;
    const input: Parameters<OrkestSim['applySnapshot']>[0] = { serverTime: time, accounts: [],
      rooms: [{ id: 'project', name: 'Project', seed: 1, slot: 0, path: '/project', createdAt: time }],
      agents: Array.from({ length: 20 }, (_, i) => ({ id: `worker-${i}`, kind: 'main', roomId: 'project',
        name: `Worker ${i}`, account: 'test', look: 'm', seed: i + 1, status: 'working',
        startedAt: time, statusSince: time, lastEventAt: time, tasks: [],
        stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 } })) };
    sim.applySnapshot(input, time);
    const ch = sim.chars.get('worker-0')!;
    assert.equal(sim.startCoworkingTest('meeting', ch.id).ok, true);
    const seatId = sim.getCoworkingTest()!.spotId;
    let elapsed = 0;
    while ((!ch.seated || ch.atSpot !== seatId) && elapsed < 30000) {
      elapsed += 1000 / 60; sim.update(1 / 60, time + elapsed);
    }
    assert.equal(ch.atSpot, seatId);
    sim.applySnapshot({ ...input, agents: [...input.agents, { ...input.agents[0], id: 'new-worker' }] }, time + elapsed);
    const seat = sim.spots.get(seatId)!;
    assert.equal(ch.atSpot, seatId);
    assert.equal(ch.x, seat.x);
    assert.equal(ch.y, seat.y);
    assert.equal(sim.spots.ownerOf(seatId), ch.id);
  } finally { configureOfficeLayout(false); }
});

test('legacy raster exports retain their original geometry after a spacious simulation', () => {
  configureOfficeLayout(false);
  assert.equal(COL_W, 16); assert.equal(CORE_COLS, 2); assert.equal(slotRect(0).x, 32);
  assert.equal(assembleBuilding(3, []).core.length, 4);
});

test('coworking interaction walks, reserves, uses and releases all three seat categories', () => {
  configureOfficeLayout(true);
  try {
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    let time = 1_800_000_000_000;
    const agent = { id: 'worker', kind: 'main', roomId: 'project', name: 'Ana', account: 'test',
      look: 'f', seed: 4, status: 'working', startedAt: time, statusSince: time, lastEventAt: time,
      tasks: [], stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 },
      activity: { id: 'original-command', kind: 'command', at: time, label: 'Work' } };
    const snapshot = { serverTime: time, accounts: [],
      rooms: [{ id: 'project', name: 'Project', seed: 1, slot: 0, path: '/project', createdAt: time }], agents: [agent] } as Parameters<OrkestSim['applySnapshot']>[0];
    sim.applySnapshot({ ...snapshot, agents: [] }, time);
    sim.applySnapshot(snapshot, time);
    const advance = () => { time += 1000 / 60; sim.update(1 / 60, time); };
    for (let i = 0; i < 4800; i++) advance();
    const ch = sim.chars.get('worker')!;
    const home = ch.homeSpot;
    for (const zone of ['focus', 'meeting', 'lounge'] as const) {
      assert.equal(sim.startCoworkingTest(zone).ok, true);
      const target = sim.getCoworkingTest()!.spotId;
      assert.equal(sim.spots.ownerOf(target), ch.id);
      for (let i = 0; i < 4800 && ch.atSpot !== target; i++) advance();
      assert.equal(ch.atSpot, target, `Did not arrive in ${zone}`);
      assert.equal(ch.seated, true);
      assert.equal(ch.homeSpot, home);
      for (let i = 0; i < 2100; i++) advance();
      assert.equal(sim.spots.ownerOf(target), undefined);
      assert.equal(sim.getCoworkingTest(), null);
    }
    assert.equal(ch.info.activity?.id, 'original-command');
    assert.equal(sim.startCoworkingTest('focus').ok, true);
    const cancelled = sim.getCoworkingTest()!.spotId;
    sim.applySnapshot({ ...snapshot, agents: [{ ...snapshot.agents[0], activity: { ...agent.activity, id: 'real-command' } }] }, time);
    for (let i = 0; i < 60; i++) advance();
    assert.equal(sim.getCoworkingTest(), null);
    assert.equal(sim.spots.ownerOf(cancelled), undefined);
  } finally { configureOfficeLayout(false); }
});

test('outdoor visitors move outside the building and carriageway while the map contains varied points of interest', () => {
  configureOfficeLayout(true);
  try {
    for (const cols of [4, 6, 10]) {
      const life = outdoorLifeLayout(cols);
      assert.ok(life.routes.length >= 20);
      assert.ok(outdoorLifeLayout(cols, 0).routes.length < life.routes.length);
      const kinds = new Set(life.props.map(prop => prop.kind));
      for (const kind of ['stream_lake', 'bridge', 'garden_set', 'rock', 'boulder', 'tent', 'tent_classic', 'pond', 'fountain_large', 'station_track', 'station_shelter', 'train', 'stump', 'vendor_cart', 'vendor_stall', 'duck', 'duckling', 'goose', 'hen', 'dove']) {
        assert.ok(kinds.has(kind), `Missing outdoor object: ${kind}`);
      }
      assert.ok(!life.props.some(prop => prop.kind === 'fountain_small'));
      assert.ok(!life.props.some(prop => prop.kind === 'tent_classic' && prop.x < 0));
      const exterior = layoutExterior(cols, 'summer');
      assert.ok(life.station.y > life.fountain.y + 200);
      assert.ok(life.station.y + 60 < (exterior.bounds.y + exterior.bounds.h) * TILE);
      assert.ok(life.pond.y + 20 - 288 > exterior.bounds.y * TILE);
      const track = life.props.find(prop => prop.kind === 'station_track')!;
      assert.equal(track.x - track.seed / 2, exterior.bounds.x * TILE);
      assert.equal(track.x + track.seed / 2, (exterior.bounds.x + exterior.bounds.w) * TILE);
      assert.ok(!exterior.props.some(prop => prop.seed === 901 || prop.seed === 902));
      const roadTop = (BUILDING_H + 4) * TILE;
      const roadBottom = (BUILDING_H + 9) * TILE;
      const buildingW = cols * COL_W * TILE;
      for (const route of life.routes) {
        const seen = new Set<string>();
        let usesSeat = false;
        for (let seconds = 0; seconds < 360; seconds += .5) {
          const p = sampleOutdoorRoute(route, seconds);
          usesSeat ||= p.seated === true;
          assert.ok(p.y < roadTop || p.y > roadBottom, `Visitor entered the road: ${route.id}`);
          assert.ok(p.x < 0 || p.x > buildingW || p.y < 0 || p.y > BUILDING_H * TILE, `Visitor entered the building: ${route.id}`);
          assert.ok(p.y < (exterior.bounds.y + exterior.bounds.h) * TILE);
          for (const prop of life.props.filter(prop => prop.kind === 'rock' || prop.kind === 'boulder')) {
            assert.ok(Math.hypot(p.x - prop.x, p.y - prop.y) > 48, `Route crosses a rock: ${route.id}`);
          }
          seen.add(`${Math.round(p.x)},${Math.round(p.y)}`);
        }
        assert.ok(seen.size > 3, `Visitor is stationary: ${route.id}`);
        if (route.id.startsWith('garden-')) assert.ok(usesSeat, `Garden visitor never uses a seat: ${route.id}`);
      }
    }
  } finally { configureOfficeLayout(false); }
});


test('campers enter and leave tents, outdoor activities and clothing follow the season', () => {
  configureOfficeLayout(true);
  try {
    const base = art.appearanceFromSeed(12);
    for (const season of ['spring', 'summer', 'autumn', 'winter'] as const) {
      const life = outdoorLifeLayout(4, 70, season);
      const campers = life.routes.filter(route => route.id.startsWith('camper-'));
      assert.ok(campers.length >= 3);
      for (const route of campers) {
        const hidden: boolean[] = [];
        for (let t = 0; t < 120; t += .25) hidden.push(sampleOutdoorRoute(route, t).hidden === true);
        assert.ok(hidden.includes(true) && hidden.includes(false), `No tent entry/exit in ${season}`);
      }
      for (const action of ['chop', 'serve', 'tend']) {
        assert.ok(life.routes.some(route => route.stops.some(stop => stop.action === action)), `Missing ${action}`);
      }
      const appearance = outdoorAppearance(base, season);
      if (season === 'winter') {
        assert.equal(appearance.topStyle, 'jacket'); assert.equal(appearance.accessory, 'beanie');
        assert.equal(appearance.bottomStyle, 'pants');
        assert.ok(life.routes.some(route => route.stops.some(stop => stop.action === 'warm')));
      }
      assert.deepEqual(base, art.appearanceFromSeed(12));
    }
    const hiddenFurniture = outdoorLifeLayout(4, 0);
    assert.ok(!hiddenFurniture.routes.some(route => route.tentSeed !== undefined || route.id.startsWith('vendor-') || route.id === 'woodcutter'));
  } finally { configureOfficeLayout(false); }
});


test('train departs and returns to the platform in both directions with a station dwell', () => {
  const station = 640, span = 1920;
  assert.deepEqual(sampleTrainJourney(0, station, span), { x: station, dir: 1, phase: 'station' });
  const samples = Array.from({ length: 800 }, (_, i) => sampleTrainJourney(i / 4, station, span));
  assert.ok(samples.some(p => p.x > station + span / 2));
  assert.ok(samples.some(p => p.x < station - span / 2));
  assert.ok(samples.some(p => p.phase === 'station' && p.dir === -1));
  for (let i = 1; i < samples.length; i++) {
    const p = samples[i], prev = samples[i - 1];
    if (p.phase === 'station') assert.equal(p.x, station);
    assert.ok(Math.abs(p.x - prev.x) < 60, 'Train teleported within the visible journey');
    if (p.phase === prev.phase && Math.abs(p.x - prev.x) > .001) assert.equal(Math.sign(p.x - prev.x), p.dir);
  }
});

test('a full lounge reserves separate seats and lets a crowd sit simultaneously', () => {
  configureOfficeLayout(true);
  try {
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    let time = 1_800_000_000_000;
    const agents = Array.from({ length: 20 }, (_, i) => ({
      id: `crowd-${i}`, kind: 'main', roomId: 'project', name: `Pessoa ${i}`, account: 'test', look: 'm', seed: i + 1,
      status: 'working', startedAt: time, statusSince: time, lastEventAt: time, tasks: [],
      stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 },
      activity: { id: `command-${i}`, kind: 'command', at: time, label: 'Work' },
    }));
    const snapshot = { serverTime: time, accounts: [], rooms: [{ id: 'project', name: 'Project', seed: 1, slot: 0, path: '/project', createdAt: time }], agents } as Parameters<OrkestSim['applySnapshot']>[0];
    sim.applySnapshot({ ...snapshot, agents: [] }, time); sim.applySnapshot(snapshot, time);
    const tick = () => { time += 1000 / 60; sim.update(1 / 60, time); };
    for (let i = 0; i < 7200; i++) tick();
    const homes = new Map([...sim.chars.values()].map(ch => [ch.id, ch.homeSpot]));
    const result = sim.startCoworkingGroup();
    assert.ok(result.count >= 16, `Only ${result.count} visitors could reserve a seat`);
    const states = sim.getCoworkingTests();
    assert.equal(new Set(states.map(s => s.spotId)).size, states.length);
    const used = new Set<string>();
    let peak = 0;
    for (let i = 0; i < 4200; i++) {
      tick(); const seated = sim.getCoworkingTests().filter(s => s.phase === 'using');
      peak = Math.max(peak, seated.length);
      for (const state of seated) { used.add(state.spotId); assert.equal(sim.chars.get(state.agentId)!.seated, true); }
    }
    assert.ok(peak >= 16, `Only ${peak} visitors sat simultaneously`);
    for (const state of states) assert.ok(used.has(state.spotId), `Seat never reached: ${state.spotId}`);
    sim.stopCoworkingTest();
    assert.equal(sim.getCoworkingTests().length, 0);
    for (const ch of sim.chars.values()) assert.equal(ch.homeSpot, homes.get(ch.id));
  } finally { configureOfficeLayout(false); }
});
