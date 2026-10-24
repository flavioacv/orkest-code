import { Sim } from '../../../../habblaud/client/src/world/sim/sim.ts';
import type { Character } from '../../../../habblaud/client/src/world/sim/character.ts';

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
  }
}
