import { Sim } from '../../third_party/office_engine/client/src/world/sim/sim.ts';
import type { Character } from '../../third_party/office_engine/client/src/world/sim/character.ts';
import type { AgentInfo, OfficeSnapshot } from '../../third_party/office_engine/shared/types.ts';
import { SessionSocialBridge } from './social.ts';
import { PathFinder } from '../../third_party/office_engine/client/src/world/path/astar.ts';

export type CoworkingZone = 'focus' | 'meeting' | 'lounge';
export interface CoworkingTestState {
  agentId: string;
  name: string;
  spotId: string;
  zone: CoworkingZone;
  phase: 'walking' | 'using';
}

const hidingSteps = new Set(['elevOut', 'elevIn', 'stall']);

export function repairCharacterVisibility(ch: Character): boolean {
  if (ch.gone || ch.leaving || (!ch.inside && ch.alpha >= 1)) return false;
  if (ch.step && hidingSteps.has(ch.step.t)) return false;
  if (ch.queue.some(step => hidingSteps.has(step.t))) return false;
  // A cancelled arrival used to leave the actor walking and sitting with the
  // elevator's invisible flags forever. Keep its current position and plan.
  ch.inside = false;
  ch.alpha = 1;
  ch.hiddenUntil = 0;
  return true;
}

export class OrkestSim extends Sim {
  readonly sessionSocial = new SessionSocialBridge(this);
  private readonly pendingDeliveries = new Map<string, string>();
  private readonly coworkingTests = new Map<string, CoworkingTestState & { activityId: string | undefined; status: string }>();

  getCoworkingTests(): CoworkingTestState[] {
    return [...this.coworkingTests.values()].map(state => ({ agentId: state.agentId, name: state.name,
      spotId: state.spotId, zone: state.zone, phase: this.chars.get(state.agentId)?.atSpot === state.spotId ? 'using' : 'walking' }));
  }

  getCoworkingTest(): CoworkingTestState | null { return this.getCoworkingTests()[0] ?? null; }

  startCoworkingTest(zone: CoworkingZone, preferredAgent?: string): { ok: boolean; message: string } {
    if (!['focus', 'meeting', 'lounge'].includes(zone)) return { ok: false, message: 'Escolha uma área do coworking.' };
    this.stopCoworkingTest();
    const ch = [...this.chars.values()].find(person => (!preferredAgent || person.id === preferredAgent) && this.availableForCoworking(person));
    return ch ? this.planCoworking(ch, zone) : { ok: false, message: 'Aguarde um personagem sair do elevador para iniciar o teste.' };
  }

  startCoworkingGroup(): { ok: boolean; message: string; count: number } {
    this.stopCoworkingTest();
    let count = 0;
    for (const ch of this.chars.values()) if (this.availableForCoworking(ch) && this.planCoworking(ch, 'lounge', true).ok) count++;
    return { ok: count > 0, count, message: count ? `${count} personagens estão indo ao lounge e coworking.` : 'Aguarde personagens disponíveis.' };
  }

  private availableForCoworking(ch: Character): boolean {
    return !ch.gone && !ch.leaving && !ch.inside && ch.alpha >= 1 && (!ch.step || this.interruptible(ch.step));
  }

  private planCoworking(ch: Character, zone: CoworkingZone, group = false): { ok: boolean; message: string } {
    const kind = zone === 'focus' ? 'office_chair' : zone === 'meeting' ? 'armchair' : 'coworking_set';
    const furniture = this.building.core.flatMap(area => area.furniture.filter(f => group ? area.id === 'core:lounge' : f.kind === kind));
    const furnitureIds = new Set(furniture.map(f => f.id));
    const finder = new PathFinder(this.building.grid), path: number[] = [];
    const candidates = this.building.spots.filter(s => s.seated && !!s.furnitureId && furnitureIds.has(s.furnitureId));
    if (group) candidates.sort((a, b) => Number(!a.furnitureId?.endsWith(':coworking_set')) - Number(!b.furnitureId?.endsWith(':coworking_set')));
    const spot = candidates.find(s => this.spots.isFree(s.id, ch.id) && finder.find(ch.tx, ch.ty, s.tx, s.ty, path));
    if (!spot) return { ok: false, message: 'Nenhum assento acessível está livre nessa área.' };
    this.interrupt(ch);
    if (ch.step || !this.reserveTemp(ch, spot)) return { ok: false, message: 'O personagem está terminando outra ação. Tente novamente.' };
    ch.replan = false;
    const state = { agentId: ch.id, name: ch.info.name, spotId: spot.id, zone, phase: 'walking' as const,
      activityId: ch.info.activity?.id, status: ch.info.status };
    this.coworkingTests.set(ch.id, state);
    if (ch.atSpot) ch.queue.push({ t: 'exit' });
    ch.queue.push({ t: 'go', tx: spot.tx, ty: spot.ty }, { t: 'enter', spot: spot.id },
      { t: 'act', pose: zone === 'focus' ? 'type' : zone === 'meeting' ? 'talk' : 'sit', dir: spot.dir, ms: group ? 60000 : 30000 },
      { t: 'exit' }, { t: 'do', fn: () => {
        this.spots.release(spot.id, ch.id);
        ch.tempSpots = ch.tempSpots.filter(id => id !== spot.id);
        if (this.coworkingTests.get(ch.id) === state) this.coworkingTests.delete(ch.id);
      } });
    return { ok: true, message: `${ch.info.name} está indo ao coworking.` };
  }

  stopCoworkingTest(agentId?: string): void {
    for (const [id, state] of this.coworkingTests) {
      if (agentId && agentId !== id) continue;
      this.coworkingTests.delete(id);
      const ch = this.chars.get(id);
      if (ch) {
        this.interrupt(ch);
        if (!ch.step && ch.atSpot && ch.atSpot !== ch.homeSpot) ch.queue.push({ t: 'exit' });
      } else this.spots.release(state.spotId, id);
    }
  }

  override applySnapshot(input: OfficeSnapshot, now: number): void {
    const previous = new Map([...this.chars].map(([id, ch]) => [id, ch.lastActivityId]));
    this.sessionSocial.prepare(input);
    super.applySnapshot(input, now);
    for (const testing of this.coworkingTests.values()) {
      const agent = input.agents.find(agent => agent.id === testing.agentId);
      if (!agent || agent.status !== testing.status || agent.activity?.id !== testing.activityId) this.stopCoworkingTest(testing.agentId);
    }
    for (const agent of input.agents) {
      const ch = this.chars.get(agent.id);
      if (ch && previous.get(agent.id) && previous.get(agent.id) !== agent.activity?.id) {
        if ((agent as any).sessionBacked && agent.kind === 'sub' && agent.activity?.kind === 'done') {
          this.pendingDeliveries.set(agent.id, agent.activity.id);
        }
      }
    }
  }

  private reportSessionDelivery(ch: Character, agent: AgentInfo, now: number): boolean {
    // A delegated terminal stays open for follow-ups. Report the completed
    // turn to its orchestrator, then return to its own desk (do not despawn).
    if ((agent as any).sessionBacked && agent.kind === 'sub' && agent.parentId &&
        agent.activity?.kind === 'done') {
      const parent = this.chars.get(agent.parentId);
      if (!parent || parent.gone || parent.leaving || ch.inside || ch.arriving || ch.leaving) return false;
      this.interrupt(ch);
      if (ch.step) return false;
      const target = this.building.grid.nearestWalkable(parent.tx + 1, parent.ty, 4);
      if (!target) return false;
      if (ch.atSpot) ch.queue.push({ t: 'exit' });
      ch.queue.push({ t: 'go', tx: target.x, ty: target.y },
        { t: 'act', pose: 'talk', held: 'papers', ms: 1800 },
        { t: 'do', fn: () => {
          if (ch.info.status !== 'idle') return;
          ch.setIcon('box', 2000, this.now);
          parent.setIcon('check', 2000, this.now);
          this.social.delivered(ch, this.now);
        } });
      return true;
    }
    return false;
  }
  override interrupt(ch: Character): void {
    // PTY events can change status between spawn and the first animation frame.
    // Promote the queued arrival before upstream clears the plan, so its
    // existing non-interruptible-step handling lets the elevator exit finish.
    if (!ch.step && ch.queue[0]?.t === 'elevOut') {
      ch.step = ch.queue.shift()!;
      ch.stepT = 0;
      ch.stepStarted = false;
    }
    super.interrupt(ch);
  }

  override update(dt: number, now: number): void {
    for (const ch of this.chars.values()) repairCharacterVisibility(ch);
    super.update(dt, now);
    for (const state of this.coworkingTests.values()) {
      const ch = this.chars.get(state.agentId);
      if (!ch || ch.gone || ch.leaving || !this.spots.get(state.spotId) || this.spots.ownerOf(state.spotId) !== ch.id) this.stopCoworkingTest(state.agentId);
    }
    for (const [id, activityId] of this.pendingDeliveries) {
      const ch = this.chars.get(id);
      if (!ch || ch.gone || ch.leaving || ch.info.activity?.id !== activityId ||
          ch.info.activity.kind !== 'done') {
        this.pendingDeliveries.delete(id);
      } else if (this.reportSessionDelivery(ch, ch.info, now)) {
        this.pendingDeliveries.delete(id);
      }
    }
  }
}
