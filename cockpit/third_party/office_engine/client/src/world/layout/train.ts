export interface TrainJourney {
  x: number;
  dir: 1 | -1;
  phase: 'station' | 'departing' | 'returning';
}

/** Depart in each direction, turn outside the map, then stop at the same platform. */
export function sampleTrainJourney(seconds: number, stationX: number, span: number): TrainJourney {
  const dwell = 10, turn = 2;
  const distance = span / 2 + 500;
  const travel = Math.max(8, distance / 110);
  const halfCycle = dwell + travel * 2 + turn;
  const cycle = halfCycle * 2;
  const t = ((seconds % cycle) + cycle) % cycle;
  const side: 1 | -1 = t < halfCycle ? 1 : -1;
  const local = t % halfCycle;
  if (local < dwell) return { x: stationX, dir: side, phase: 'station' };
  const elapsed = local - dwell;
  // Zero speed at the platform and a continuous, faster cruise toward the boundary.
  const outward = (p: number) => p * p * (2 - p);
  if (elapsed < travel) return { x: stationX + side * distance * outward(elapsed / travel), dir: side, phase: 'departing' };
  if (elapsed < travel + turn) return { x: stationX + side * distance, dir: -side as 1 | -1, phase: 'returning' };
  const progress = Math.min(1, (elapsed - travel - turn) / travel);
  return { x: stationX + side * distance * outward(1 - progress), dir: -side as 1 | -1, phase: 'returning' };
}
