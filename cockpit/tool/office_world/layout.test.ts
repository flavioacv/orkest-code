import assert from 'node:assert/strict';
import test from 'node:test';
import { configureOfficeLayout, COL_W, CORE_COLS, CORRIDOR_Y, SOUTH_Y } from '../../third_party/office_engine/client/src/world/constants.ts';
import { assembleBuilding } from '../../third_party/office_engine/client/src/world/layout/building.ts';
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

test('spacious Office separates rooms and connects every coworking seat to the corridor', () => {
  configureOfficeLayout(true);
  try {
    assert.equal(COL_W, 20); assert.equal(CORE_COLS, 3);
    assert.equal(slotRect(0).x, 60); assert.ok(SOUTH_Y - CORRIDOR_Y >= 9);
    const rooms = [0, 1, 2, 3].map(slot => layoutProjectRoom({ id: `room-${slot}`, slot, seed: slot + 1 }, roomTheme(slot + 1)));
    const building = assembleBuilding(5, rooms);
    const coworking = building.core.filter(area => area.id === 'core:coworking' || area.id === 'core:lounge');
    assert.equal(coworking.length, 2);
    const seats = coworking.flatMap(area => area.spots.filter(spot => spot.seated));
    assert.ok(seats.length >= 20);
    const shared = building.core.find(area => area.id === 'core:lounge')!;
    assert.equal(shared.rect.w, COL_W + 16);
    assert.equal(shared.spots.filter(spot => spot.furnitureId?.endsWith(':coworking_set')).length, 10);
    assert.ok(!building.core.some(area => area.id === 'core:coworking-lounge'));
    assert.ok(!building.core.flatMap(area => area.furniture).some(f => f.kind === 'meeting_set' || f.kind === 'meeting_pair' || f.kind === 'focus_pod'));
    const finder = new PathFinder(building.grid);
    for (const spot of seats) {
      assert.ok(building.grid.walkable(spot.tx, spot.ty), `Blocked seat: ${spot.id}`);
      const path: number[] = [];
      assert.ok(finder.find(7, CORRIDOR_Y + 2, spot.tx, spot.ty, path), `Unreachable seat: ${spot.id}`);
    }
    for (const room of rooms) for (const spot of room.spots.filter(spot => spot.kind === 'desk')) {
      const path: number[] = [];
      assert.ok(finder.find(7, CORRIDOR_Y + 2, spot.tx, spot.ty, path), `Unreachable desk: ${spot.id}`);
    }
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
