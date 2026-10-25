import type { OfficeSnapshot, AgentInfo } from '../../third_party/office_engine/shared/types.ts';
import type { Sim } from '../../third_party/office_engine/client/src/world/sim/sim.ts';
import { Wallets, type WalletEntry } from '../../third_party/office_engine/client/src/world/social/wallet.ts';

type SessionAgent = AgentInfo & { socialIdentity?: string; socialState?: any; sessionBacked?: boolean };

/** The live session list is the authority: no project/name/localStorage lookup. */
export class SessionSocialBridge {
  private identities = new Map<string, string>();
  constructor(private readonly sim: Sim) {}

  prepare(snapshot: OfficeSnapshot): void {
    const incoming = new Map(snapshot.agents.map(a => [a.id, (a as SessionAgent).socialIdentity ?? a.id]));
    const changed = incoming.size !== this.identities.size || [...incoming].some(([id, key]) => this.identities.get(id) !== key);
    if (!changed) return;
    const keptEvents = this.sim.social.events.filter(event =>
      incoming.has(event.agentId) && this.identities.get(event.agentId) === incoming.get(event.agentId));
    this.sim.social.events.splice(0, this.sim.social.events.length, ...keptEvents);
    const wallets: Record<string, WalletEntry> = {};
    const idForKey = new Map([...incoming].map(([id, key]) => [key, id]));
    for (const agent of snapshot.agents as SessionAgent[]) {
      const same = this.identities.get(agent.id) === incoming.get(agent.id);
      let wallet = same ? this.sim.social.wallets.get(agent.id) : undefined;
      const saved = agent.socialState;
      if (!same && this.identities.has(agent.id)) {
        this.sim.spots.releaseAll(agent.id);
        this.sim.chars.delete(agent.id);
      }
      if (!wallet && saved?.version === 1 && saved.identity === incoming.get(agent.id) && saved.wallet) {
        wallet = { ...saved.wallet, vs: Object.fromEntries(Object.entries(saved.wallet.vs ?? {})
          .filter(([key]) => idForKey.has(key)).map(([key, score]) => [idForKey.get(key)!, score])) };
        for (const event of Array.isArray(saved.events) ? saved.events.slice(-20) : []) {
          if (typeof event.id === 'string' && typeof event.at === 'number' && typeof event.text === 'string') {
            this.sim.social.events.push({ ...event, agentId: agent.id });
          }
        }
      }
      if (wallet) wallets[agent.id] = { ...wallet, vs: Object.fromEntries(Object.entries(wallet.vs ?? {})
        .filter(([id]) => incoming.has(id) && (!this.identities.has(id) || this.identities.get(id) === incoming.get(id)))) };
    }
    // Wallets has a supported serialized loader; use a memory-only storage
    // receipt instead of retaining closed agents in browser localStorage.
    Object.assign(this.sim.social, { wallets: new Wallets({
      getItem: key => key === 'habblaud.wallets.v1' ? JSON.stringify({ v: 1, wallets }) : null,
      setItem: () => {},
    }) });
    this.identities = incoming;
    const validEvents = this.sim.social.events.filter(e => incoming.has(e.agentId));
    this.sim.social.events.splice(0, this.sim.social.events.length, ...validEvents.slice(-40));
  }

  snapshot() {
    const events = this.sim.social.events.filter(e => this.identities.has(e.agentId));
    return {
      agents: Object.fromEntries([...this.identities].map(([id, identity]) => {
        const wallet = this.sim.social.wallets.get(id);
        return [id, {
          identity, social: this.sim.social.info(id),
          state: wallet ? { version: 1, identity, wallet: { ...wallet,
            vs: Object.fromEntries(Object.entries(wallet.vs).filter(([other]) => this.identities.has(other))
              .map(([other, score]) => [this.identities.get(other)!, score])) },
            events: events.filter(e => e.agentId === id).slice(-20),
          } : null,
        }];
      })),
      events,
    };
  }
}
