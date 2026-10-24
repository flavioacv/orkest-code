import assert from 'node:assert/strict';
import test from 'node:test';
import * as art from '../../../../habblaud/client/src/art/index.ts';
import { DEFAULT_WORLD_OPTIONS } from '../../../../habblaud/client/src/world/api.ts';
import { Sim } from '../../../../habblaud/client/src/world/sim/sim.ts';
import { CockpitSim, repairCharacterVisibility } from './sim.ts';

const now = 1_800_000_000_000;
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
  const sim = arriving(new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null));
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

test('recovers orphaned visibility while preserving the character position', () => {
  const sim = arriving(new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null));
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
  const first = new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null);
  first.applySnapshot(input, now);
  first.social.wallets.credit('orchestrator', 25, '✅', 'Completed', now);
  const saved = first.sessionSocial.snapshot().agents.orchestrator.state!;
  const restored = new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null);
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
  const sim = new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null);
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
  const sim = new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null);
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
    const sim = new CockpitSim(art, () => DEFAULT_WORLD_OPTIONS, null);
    sim.applySnapshot(input, now);
    assert.equal(sim.chars.get('orchestrator')!.shellStage, stage);
    input.agents[0].status = 'waiting';
    sim.applySnapshot(input, now + 1);
    assert.equal(sim.chars.get('orchestrator')!.mode, 'wait');
  }
});
