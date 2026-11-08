import * as lines from '../../third_party/office_engine/client/src/world/social/lines.ts';
import { personaFor } from '../../third_party/office_engine/client/src/world/social/persona.ts';
import { KINDS } from '../../third_party/office_engine/client/src/world/social/gathering.ts';
import { TRAITS } from '../../third_party/office_engine/shared/world/traits.ts';
import { EN } from '../../third_party/office_engine/shared/locales/en.ts';
import { ES } from '../../third_party/office_engine/shared/locales/es.ts';
import assert from 'node:assert/strict';
import test from 'node:test';
import * as art from '../../third_party/office_engine/client/src/art/index.ts';
import { DEFAULT_WORLD_OPTIONS, exteriorSeasonFor } from '../../third_party/office_engine/client/src/world/api.ts';
import { layoutExterior, slotShell } from '../../third_party/office_engine/client/src/world/layout/exterior.ts';
import { Sim } from '../../third_party/office_engine/client/src/world/sim/sim.ts';
import { OrkestSim, repairCharacterVisibility } from './sim.ts';
import { coreAreaName } from '../../third_party/office_engine/client/src/world/render/overlay.ts';
import { setLocale, tr } from '../../third_party/office_engine/shared/i18n.ts';
import { configureOfficeLayout } from '../../third_party/office_engine/client/src/world/constants.ts';
import { effectRegions } from '../../third_party/office_engine/client/src/world/render/github-fx.ts';

const now = 1_800_000_000_000;

test('core room labels follow Flutter locale changes without rebuilding the world', () => {
  try {
    setLocale('en');
    assert.deepEqual(['core:recepcao', 'core:banheiros', 'core:copa', 'core:lounge'].map(coreAreaName),
      ['Reception', 'Restrooms', 'Kitchen', 'Lounge']);
    setLocale('pt-BR');
    assert.deepEqual(['core:recepcao', 'core:banheiros', 'core:copa', 'core:lounge'].map(coreAreaName),
      ['Recepção', 'Banheiros', 'Copa', 'Lounge']);
    setLocale('es');
    assert.equal(coreAreaName('core:recepcao'), 'Recepción');
    assert.equal(coreAreaName('project'), undefined);
  } finally {
    setLocale('pt-BR');
  }
});
function snapshot(status = 'working') {
  return {
    serverTime: now,
    accounts: [{ id: 'account', short: 'C', name: 'CLI', color: '#4488ff' }],
    rooms: [{ id: 'project', name: 'Project', seed: 1, slot: 0, path: '/project', createdAt: now }],
    agents: ['orchestrator', 'developer'].map((id, index) => ({
      id, kind: 'main', roomId: 'project', name: id, account: 'account',
      look: 'm', seed: index + 1, status: index === 0 ? status : 'working',
      startedAt: now, statusSince: now, lastEventAt: now, tasks: [],
      stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 },
      activity: { id: `${id}-${status}`, kind: 'command', at: now, label: 'Command' },
    })),
  } as any;
}

function arriving<T extends Sim>(sim: T): T {
  const input = snapshot();
  sim.applySnapshot({ ...input, agents: [] }, now);
  sim.applySnapshot(input, now);
  return sim;
}

test('reproduces an upstream arrival cancelled before its first frame', () => {
  const sim = arriving(new Sim(art, () => DEFAULT_WORLD_OPTIONS, null));
  sim.applySnapshot(snapshot('waiting'), now + 1);
  const ch = sim.chars.get('orchestrator')!;
  assert.equal(ch.inside, true);
  assert.equal(ch.alpha, 0);
  assert.equal(ch.step, null);
  assert.equal(ch.queue.length, 0);
});

test('two terminal sessions survive rapid status changes and get separate desks', () => {
  const sim = arriving(new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null));
  sim.applySnapshot(snapshot('waiting'), now + 1);
  assert.equal(sim.chars.get('orchestrator')!.step?.t, 'elevOut');
  for (let frame = 1; frame <= 3600; frame++) sim.update(1 / 60, now + frame * 1000 / 60);
  const chars = [...sim.chars.values()];
  assert.equal(chars.length, 2);
  assert.equal(new Set(chars.map(ch => ch.homeSpot)).size, 2);
  for (const ch of chars) {
    assert.equal(ch.inside, false);
    assert.equal(ch.alpha, 1);
    assert.equal(ch.atSpot, ch.homeSpot);
    assert.equal(ch.seated, true);
  }
  assert.equal(chars[0].mode, 'wait');
  assert.equal(chars[1].mode, 'work');
});

test('local and remote projects keep their sessions in separate rooms and update agent state', () => {
  const input = snapshot();
  input.rooms.push({ id: 'remote', name: 'Remote host', seed: 2, slot: 1,
    path: '/srv/remote', createdAt: now });
  input.agents[1].roomId = 'remote';
  const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  sim.applySnapshot(input, now);
  assert.deepEqual([...sim.rooms.values()].map(room => room.info.name), ['Project', 'Remote host']);
  assert.equal(sim.chars.get('orchestrator')!.roomId, 'project');
  assert.equal(sim.chars.get('developer')!.roomId, 'remote');
  input.agents[1].status = 'waiting';
  input.agents[1].activity = { ...input.agents[1].activity,
    id: 'developer-waiting', kind: 'ask', at: now + 1 };
  sim.applySnapshot(input, now + 1);
  assert.equal(sim.chars.get('developer')!.info.status, 'waiting');
  assert.equal(sim.chars.get('orchestrator')!.mode, 'work');
});

test('recovers orphaned visibility while preserving the character position', () => {
  const sim = arriving(new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null));
  const ch = sim.chars.get('orchestrator')!;
  assert.equal(repairCharacterVisibility(ch), false); // legitimate elevator queue
  ch.queue.length = 0;
  ch.x = 42;
  ch.y = 73;
  assert.equal(repairCharacterVisibility(ch), true);
  assert.equal(ch.inside, false);
  assert.equal(ch.alpha, 1);
  assert.equal(ch.x, 42);
  assert.equal(ch.y, 73);
  ch.inside = true;
  ch.alpha = 0;
  ch.step = { t: 'stall', spot: 'bathroom', ms: 2000, phase: 2 };
  assert.equal(repairCharacterVisibility(ch), false);
});

test('social data survives world recreation only for the same live identity', () => {
  const input = snapshot();
  input.agents[0].socialIdentity = 'session-a';
  input.agents[1].socialIdentity = 'session-b';
  const first = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  first.applySnapshot(input, now);
  first.social.wallets.credit('orchestrator', 25, '✅', 'Completed', now);
  const saved = first.sessionSocial.snapshot().agents.orchestrator.state!;
  const restored = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  restored.applySnapshot({ ...input, agents: input.agents.map((a: any) =>
    a.id === 'orchestrator' ? { ...a, socialState: saved } : a) }, now);
  assert.equal(restored.social.wallets.coins('orchestrator'), 125);
  input.agents[0].socialIdentity = 'different-session-same-tab';
  input.agents[0].socialState = saved;
  restored.applySnapshot(input, now + 1);
  assert.equal(restored.social.wallets.coins('orchestrator'), 100);
  restored.applySnapshot({ ...input, agents: [] }, now + 2);
  assert.deepEqual(restored.sessionSocial.snapshot().agents, {});
  assert.equal(restored.social.wallets.get('orchestrator'), undefined);
});

test('closed colleagues disappear from balances, history and game relationships', () => {
  const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  const input = snapshot();
  input.agents[0].socialIdentity = 'session-a';
  input.agents[1].socialIdentity = 'session-b';
  sim.applySnapshot(input, now);
  sim.social.wallets.recordMatch('orchestrator', 'developer');
  sim.social.events.push({id: 'game', agentId: 'developer', text: 'Game', icon: '🎮', place: 'Lounge', at: now});
  sim.applySnapshot({ ...input, agents: [input.agents[0]] }, now + 1);
  const state = sim.sessionSocial.snapshot();
  assert.equal(state.agents.developer, undefined);
  assert.deepEqual(state.agents.orchestrator.state!.wallet.vs, {});
  assert.deepEqual(state.events, []);
});

test('delegated terminal reports a completed turn and stays available', () => {
  const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  const input = snapshot();
  Object.assign(input.agents[1], {kind: 'sub', parentId: 'orchestrator', sessionBacked: true});
  sim.applySnapshot(input, now);
  for(let frame = 1; frame <= 1200; frame++) sim.update(1/60, now + frame * 1000/60);
  const reportAt = now + 20000;
  input.agents[1] = {...input.agents[1], status: 'idle', activity: {id: 'delivery', kind: 'done', text: 'Completed', icon: '✅', at: reportAt}};
  sim.applySnapshot(input, reportAt);
  let returned = false;
  for(let frame = 1; frame <= 1800; frame++) {
    sim.update(1/60, reportAt + frame * 1000/60);
    const child = sim.chars.get('developer')!;
    if (sim.social.wallets.coins(child.id) === 45 && child.atSpot === child.homeSpot) { returned = true; break; }
  }
  assert.equal(returned, true);
  assert.equal(sim.chars.get('developer')!.gone, false);
  assert.equal(sim.chars.get('orchestrator')!.mode, 'work');
  const coins = sim.social.wallets.coins('developer');
  sim.applySnapshot(input, reportAt + 31000);
  assert.equal(sim.social.wallets.coins('developer'), coins); // no replay reward
});

test('reliable shell waits activate all age stages and preserve human approval priority', () => {
  for (const [minutes, stage] of [[1, 'popcorn'], [4, 'restless'], [11, 'cobweb'], [26, 'nap']] as const) {
    const input = snapshot();
    input.agents[0].status = 'shell';
    input.agents[0].shells = [{id:'command', label:'Build', startedAt:now - minutes*60000, background:true, kind:'shell'}];
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    assert.equal(sim.chars.get('orchestrator')!.shellStage, stage);
    input.agents[0].status = 'waiting';
    sim.applySnapshot(input, now + 1);
    assert.equal(sim.chars.get('orchestrator')!.mode, 'wait');
  }
});

test('one session approval and completion do not reward or reactivate idle peers', () => {
  const input = snapshot('idle');
  input.agents[0].activity = { id: 'idle-completion', kind: 'done', text: 'Completed', icon: '✅', at: now };
  const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  sim.applySnapshot(input, now);
  const idle = sim.chars.get('orchestrator')!;
  const coins = sim.social.wallets.coins(idle.id);
  const activity = idle.lastActivityId;
  for (const [index, status] of ['waiting', 'working', 'idle', 'working', 'waiting', 'idle'].entries()) {
    input.agents[1] = { ...input.agents[1], status, activity: {
      id: `active-${index}`, kind: status === 'idle' ? 'done' : status === 'waiting' ? 'ask' : 'run',
      text: status, icon: '', at: now + index + 1,
    } } as any;
    sim.applySnapshot(input, now + index + 1);
    assert.equal(idle.info.status, 'idle');
    assert.equal(idle.lastActivityId, activity);
    assert.equal(sim.social.wallets.coins(idle.id), coins);
  }
});

test('unregistered harness metadata and task rewards survive snapshots', () => {
  const input = snapshot();
  input.accounts[0].provider = 'apple-fm';
  input.agents[0].tasks = [{id:'review', title:'Review', status:'pending'}];
  const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  sim.applySnapshot(input, now);
  assert.equal(sim.accounts.get('account')?.provider, 'apple-fm');
  input.agents[0].tasks[0].status = 'completed';
  sim.applySnapshot(input, now + 1);
  assert.equal(sim.social.wallets.coins('orchestrator'), 110);
  sim.applySnapshot(input, now + 2);
  assert.equal(sim.social.wallets.coins('orchestrator'), 110);
});

test('confirmed shell outcomes trigger the correct effect once', () => {
  for (const error of [false, true]) {
    const input = snapshot();
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    for (let i=1;i<=1200;i++) sim.update(1/60, now+i*1000/60);
    input.agents[0] = {...input.agents[0], recent:[{id:'result', at:now+20001, error, text:'Result', icon:'', tool:'ShellDone', kind:error?'error':'done'}]};
    sim.applySnapshot(input, now+20001);
    assert.equal(sim.chars.get('orchestrator')!.icon, error?'storm':'star');
    const count = sim.effects.filter(e => e.kind==='confetti').length;
    assert.equal(count, error?0:1);
    sim.applySnapshot(input, now+20002);
    assert.equal(sim.effects.filter(e => e.kind==='confetti').length, count);
  }
});

for (const unified of [false, true]) for (const kind of ['tv','videogame','arcade','pingpong','kitchen','talk','rps','mirror'] as const) {
  test(`social ${kind} executes its script and yields to work (${unified ? 'coworking' : 'legacy'})`, () => {
    configureOfficeLayout(unified);
    try {
    const input = snapshot('idle');
    input.agents[1].status = 'idle';
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    assert.ok(sim.social.force(kind, now+1, ['orchestrator','developer']));
    const poses = new Set<string>();
    let ran = false;
    for (let i=1;i<=4200;i++) {
      sim.update(1/60, now+i*1000/60);
      for(const ch of sim.chars.values()) poses.add(ch.pose);
      ran ||= [...sim.social.gatherings].some(g => g.kind === kind && g.phase === 'run');
    }
    const expected = {tv:'sit',videogame:'game',arcade:'use',pingpong:'play',kitchen:'talk',talk:'talk',rps:'rps',mirror:'groom'}[kind];
    assert.ok(ran, `${kind} never left the gathering phase`);
    assert.ok(poses.has(expected), `${kind} did not execute ${expected}: ${[...poses]}`);
    input.agents[0] = {...input.agents[0], status:'working'};
    sim.applySnapshot(input, now+70001);
    for (let i=1;i<=2400;i++) sim.update(1/60, now+70001+i*1000/60);
    assert.equal(sim.chars.get('orchestrator')!.mode, 'work');
    assert.equal(sim.chars.get('orchestrator')!.gathering, null);
    assert.equal(sim.chars.get('orchestrator')!.atSpot, sim.chars.get('orchestrator')!.homeSpot);
    } finally { configureOfficeLayout(false); }
  });
}

test('shared workstations keep project celebrations and CI alarms scoped to their real sessions', () => {
  configureOfficeLayout(true);
  try {
    const input = snapshot();
    input.rooms.push({ ...input.rooms[0], id: 'remote', name: 'Remote', slot: 1 });
    input.agents[1].roomId = 'remote';
    input.rooms[0].effect = { kind: 'party', at: now, until: now + 12000, text: 'PR merged', agentId: 'orchestrator' };
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    for (let i = 1; i <= 120; i++) sim.update(1 / 60, now + i * 1000 / 60);
    const party = sim.roomFx.get('project', now + 2000)!;
    assert.ok(party.cheered.has('orchestrator'));
    assert.ok(!party.cheered.has('developer'));
    const regions = effectRegions(sim, 'project');
    assert.equal(regions.length, 1);
    const home = sim.spots.get(sim.chars.get('orchestrator')!.homeSpot)!;
    assert.ok(home.x >= regions[0].room.x && home.x < regions[0].room.x + regions[0].room.w);
    input.rooms[0].effect = { kind: 'alarm', at: now + 2001, until: now + 62001, text: 'CI failed', agentId: 'orchestrator' };
    sim.applySnapshot(input, now + 2001);
    assert.ok(sim.roomFx.alarmOwner('orchestrator', now + 2001));
    assert.equal(sim.roomFx.alarmOwner('developer', now + 2001), undefined);
    assert.equal(sim.chars.get('developer')!.info.status, 'working');
  } finally { configureOfficeLayout(false); }
});

test('a running pingpong match keeps its participants and reservations when the hall expands', () => {
  configureOfficeLayout(true);
  try {
    const input = snapshot('idle'); input.agents[1].status = 'idle';
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    assert.ok(sim.social.force('pingpong', now + 1, ['orchestrator', 'developer']));
    const match = [...sim.social.gatherings][0];
    let time = now;
    for (let frame = 0; match.phase !== 'run' && frame < 4200; frame++) { time += 1000 / 60; sim.update(1 / 60, time); }
    assert.equal(match.phase, 'run');
    const members = match.members.map(m => ({ id: m.id, spot: m.spot, x: sim.chars.get(m.id)!.x }));
    input.agents.push(...Array.from({ length: 19 }, (_, i) => ({ ...input.agents[0], id: `arrival-${i}`, status: 'working' })));
    sim.applySnapshot(input, time);
    assert.equal(sim.building.cols, 5); assert.equal(match.phase, 'run');
    for (const member of members) {
      const ch = sim.chars.get(member.id)!;
      assert.equal(ch.x, member.x + 320);
      assert.equal(ch.x, sim.spots.get(member.spot)!.x);
      assert.equal(ch.gathering, match);
      assert.ok(sim.spots.ownerOf(member.spot!));
    }
  } finally { configureOfficeLayout(false); }
});

test('coworking supports larger kitchen and videogame groups using furniture identities', () => {
  configureOfficeLayout(true);
  try {
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(snapshot('idle'), now);
    const host = sim.chars.get('orchestrator')!;
    for (const size of [2, 3, 4]) {
      const kitchen = sim.social.plan('kitchen', size, host)!;
      assert.ok(kitchen); assert.equal(kitchen.seats.length, size);
      assert.equal(new Set(kitchen.seats.map(s => s.group)).size, 1);
      const game = sim.social.plan('videogame', size, host)!;
      assert.ok(game); assert.equal(game.seats.length, size);
      assert.ok(game.seats.every(s => s.areaId === 'core:games'));
      assert.equal(game.seats[0].furnitureId, game.seats[1].furnitureId);
    }
    assert.ok(sim.social.plan('tv', 4, host)!.seats.every(s => s.areaId === 'core:lounge'));
  } finally { configureOfficeLayout(false); }
});

test('coworking reserves desks for arrivals while a full previous shift is still leaving', () => {
  configureOfficeLayout(true);
  try {
    const input = snapshot();
    input.agents = Array.from({ length: 20 }, (_, i) => ({ ...input.agents[0], id: `old-${i}`, seed: i + 1 }));
    const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    const existing = [...sim.chars.values()].map(ch => [ch.id, ch.homeSpot] as const);
    assert.equal(existing.length, 20);
    input.agents = input.agents.map((a, i) => ({ ...a, id: `new-${i}` }));
    sim.applySnapshot(input, now + 1);
    assert.equal(sim.chars.size, 40);
    assert.equal(sim.building.spots.filter(s => s.kind === 'desk').length, 44);
    for (const [id, spot] of existing) assert.equal(sim.chars.get(id)!.homeSpot, spot);
    for (let frame = 1; frame <= 10800; frame++) sim.update(1 / 60, now + frame * 1000 / 60);
    const arrivals = input.agents.map(a => sim.chars.get(a.id)!);
    assert.equal(new Set(arrivals.map(ch => ch.homeSpot)).size, 20);
    for (const ch of arrivals) { assert.ok(ch.homeSpot); assert.equal(ch.atSpot, ch.homeSpot); }
  } finally { configureOfficeLayout(false); }
});

for (const kind of ['coffee', 'water', 'snack', 'fridge', 'sink', 'stall', 'shelf', 'window'] as const) {
  test(`coworking environment ${kind} approaches, uses, releases and returns to its desk`, () => {
    configureOfficeLayout(true);
    try {
      const sim = new OrkestSim(art, () => DEFAULT_WORLD_OPTIONS, null);
      sim.applySnapshot(snapshot(), now);
      const ch = sim.chars.get('orchestrator')!;
      const spot = sim.spots.ofKind(kind)[0]; assert.ok(spot);
      sim.clearPlan(ch); ch.replan = false;
      assert.ok(sim.reserveTemp(ch, spot));
      let used = false, observedBusy = false;
      ch.queue.push({ t: 'exit' }, { t: 'go', tx: spot.tx, ty: spot.ty, fx: spot.x, fy: spot.y, dir: spot.dir },
        { t: 'do', fn: () => { used = true; assert.equal(ch.x, spot.x); assert.equal(ch.y, spot.y); } });
      if (kind === 'stall') ch.queue.push({ t: 'stall', spot: spot.id, ms: 700, phase: 0 });
      else ch.queue.push({ t: 'act', pose: kind === 'shelf' ? 'read' : kind === 'window' ? 'stand' : 'use',
        ms: 700, machine: kind === 'coffee' ? spot.furnitureId : undefined });
      ch.queue.push({ t: 'do', fn: () => { sim.releaseTemp(ch); sim.pushHome(ch, 'none'); } });
      for (let frame = 1; frame <= 9000; frame++) {
        sim.update(1 / 60, now + frame * 1000 / 60);
        if (kind === 'coffee') observedBusy ||= (sim.machineUntil.get(spot.furnitureId!) ?? 0) > sim.now;
        if (kind === 'stall') observedBusy ||= sim.stallBusy.has(spot.furnitureId!);
        if (used && ch.atSpot === ch.homeSpot) break;
      }
      assert.ok(used); assert.equal(ch.atSpot, ch.homeSpot);
      assert.equal(sim.spots.ownerOf(spot.id), undefined);
      if (kind === 'coffee' || kind === 'stall') assert.ok(observedBusy, `No object state change: ${kind}`);
      assert.equal(ch.inside, false); assert.equal(ch.alpha, 1);
    } finally { configureOfficeLayout(false); }
  });
}

test('exteriorSeasonFor resolves southern and northern hemisphere calendars and fixed seasons', () => {
  assert.equal(exteriorSeasonFor('auto_south', new Date(2026, 0, 15)), 'summer');
  assert.equal(exteriorSeasonFor('auto_south', new Date(2026, 3, 15)), 'autumn');
  assert.equal(exteriorSeasonFor('auto_south', new Date(2026, 6, 15)), 'winter');
  assert.equal(exteriorSeasonFor('auto_south', new Date(2026, 9, 15)), 'spring');

  assert.equal(exteriorSeasonFor('auto_north', new Date(2026, 0, 15)), 'winter');
  assert.equal(exteriorSeasonFor('auto_north', new Date(2026, 3, 15)), 'spring');
  assert.equal(exteriorSeasonFor('auto_north', new Date(2026, 6, 15)), 'summer');
  assert.equal(exteriorSeasonFor('auto_north', new Date(2026, 9, 15)), 'autumn');

  assert.equal(exteriorSeasonFor('spring', new Date(2026, 6, 15)), 'spring');
  assert.equal(exteriorSeasonFor('winter', new Date(2026, 0, 15)), 'winter');
});

test('layoutExterior and slotShell apply seasonal floor tints and seasonal props', () => {
  const autumn = layoutExterior(3, 'autumn');
  assert.equal(autumn.floors[0].tint, 'autumn');
  assert.ok(autumn.props.some((p) => (p.kind as string) === 'leaf_pile'));

  const winter = layoutExterior(3, 'winter');
  assert.equal(winter.floors[0].tint, 'winter');
  assert.ok(winter.props.some((p) => (p.kind as string) === 'snowman'));
  assert.ok(winter.props.some((p) => (p.kind as string) === 'snowdrift'));

  const shellWinter = slotShell(0, true, 'winter');
  assert.equal(shellWinter.floors[0].tint, 'winter');
  assert.ok(shellWinter.props.some((p) => (p.kind as string) === 'snowman' || (p.kind as string) === 'snowdrift'));
});

 test('all dialogue pools and cached personalities follow live IDE locale', () => {
  const collect = (value: unknown): string[] => typeof value === 'string' ? [value] :
    value && typeof value === 'object' ? Object.values(value).flatMap(collect) : [];
  const pools = Object.entries(lines).filter(([key]) => key !== 'TRAIT_TOPICS').flatMap(([, value]) => collect(value));
  setLocale('pt-BR');
  const persona = personaFor(12345);
  const original = persona.catchphrase;
  try {
    for (const [locale, dict] of [['en', EN], ['es', ES]] as const) {
      setLocale(locale);
      for (const source of pools.filter(text => /[a-zA-ZÀ-ÿ]/.test(text))) {
        assert.ok(Object.hasOwn(dict, source), `${locale}: missing dialogue ${source}`);
      }
      assert.equal(persona.catchphrase, tr(original));
      assert.equal(lines.pick(lines.ACCEPT, () => 0), tr('Bora!'));
      assert.equal(KINDS.tv.label, tr('Vendo TV'));
      assert.equal(TRAITS.cafeina.label, tr('Cafeína'));
      assert.equal(coreAreaName('core:coworking'), locale === 'en' ? 'Individual work' : 'Trabajo individual');
    }
  } finally { setLocale('pt-BR'); }
 });
