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
