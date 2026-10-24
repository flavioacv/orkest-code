import { Sim } from '../../../../habblaud/client/src/world/sim/sim.ts';
import type { Character } from '../../../../habblaud/client/src/world/sim/character.ts';
import type { AgentInfo, OfficeSnapshot } from '../../../../habblaud/shared/types.ts';
import { SessionSocialBridge } from './social.ts';

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

export class CockpitSim extends Sim {
  readonly sessionSocial = new SessionSocialBridge(this);
  private readonly pendingDeliveries = new Map<string, string>();

  override applySnapshot(input: OfficeSnapshot, now: number): void {
    const previous = new Map([...this.chars].map(([id, ch]) => [id, ch.lastActivityId]));
    this.sessionSocial.prepare(input);
    super.applySnapshot(input, now);
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
