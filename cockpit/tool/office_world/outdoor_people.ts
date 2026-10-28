import type { ArtModule, Appearance } from '../../third_party/office_engine/client/src/art/api.ts';
import type { ExteriorSeason } from '../../third_party/office_engine/client/src/world/api.ts';
import { outdoorAnimation } from './outdoor_animation.ts';
import type { OutdoorActor } from '../../third_party/office_engine/client/src/world/render/renderer.ts';
import { outdoorLifeLayout, sampleOutdoorRoute, type OutdoorRoute } from '../../third_party/office_engine/client/src/world/layout/outdoor-life.ts';

export function outdoorAppearance(base: Appearance, season: ExteriorSeason): Appearance {
  if (season === 'winter') return { ...base, topStyle: 'jacket', bottomStyle: 'pants', accessory: 'beanie', accessoryColor: '#52778b', hairStyle: ['afro', 'bun', 'mohawk', 'pigtails'].includes(base.hairStyle) ? 'short' : base.hairStyle };
  if (season === 'autumn') return { ...base, topStyle: 'sweater', bottomStyle: 'pants' };
  return { ...base, topStyle: season === 'summer' ? 'tshirt' : 'hoodie', bottomStyle: 'pants' };
}

/** Ambient visitors use the existing character art, independently of terminal agents. */
export class OutdoorPeople {
  private cols = -1;
  private elapsed = 0;
  private scale = 70;
  private season: ExteriorSeason = 'summer';
  private routes: OutdoorRoute[] = [];
  private appearances: Appearance[] = [];
  private actors: OutdoorActor[] = [];
  constructor(private readonly art: ArtModule) {}

  setFurnitureScale(percent: number): void {
    if (this.scale !== percent) { this.scale = percent; this.cols = -1; }
  }

  update(dt: number, cols: number, season: ExteriorSeason = 'summer'): readonly OutdoorActor[] {
    if (cols !== this.cols || season !== this.season) {
      this.season = season;
      this.cols = cols;
      this.routes = outdoorLifeLayout(cols, this.scale, season).routes;
      this.appearances = this.routes.map((route, index) => outdoorAppearance(this.art.appearanceFromSeed(route.seed, { look: index % 2 ? 'f' : 'm' }), season));
      this.actors = [];
    }
    this.elapsed += Math.max(0, Math.min(.1, dt));
    this.actors.length = 0;
    this.routes.forEach((route, index) => {
      const position = sampleOutdoorRoute(route, this.elapsed);
      if (position.hidden) return;
      let sprite = this.art.characterSprite({ appearance: this.appearances[index], pose: position.action === 'chop' ? (Math.floor(this.elapsed * 8) % 8 < 4 ? 'raise_hand' : 'use') : position.pose,
        dir: position.dir, held: position.held, seated: position.seated,
        frame: Math.floor(this.elapsed * 1000 / this.art.poseFrameDuration(position.pose)) % this.art.poseFrameCount(position.pose) });
      if (position.action) sprite = outdoorAnimation(sprite, position.action, Math.floor(this.elapsed * 8) % 8, season);
      this.actors.push({ id: route.id, x: position.x, y: position.y, sprite });
    });
    return this.actors;
  }
}
