// Traços de personalidade: os mesmos para os personagens do escritório (client/src/world/social/persona.ts, que sorteia
// 2 ou 3 por semente) e para o jogador do Habblaud World (que escolhe 2 ou 3). Os ids e os pares que não combinam
// vêm do protocolo; aqui ficam os rótulos (tr) e a validação da escolha do jogador. Puro: sem Node nem DOM.
//
// Os rótulos são substantivos ("Competição", "Vaidade"): não dependem do gênero de ninguém.
import { tr } from '../i18n';
import { PLAYER_TRAITS, TRAIT_CLASHES, TRAIT_IDS, type TraitId } from './protocol';

export { TRAIT_CLASHES, TRAIT_IDS, type TraitId };

export interface Trait {
  id: TraitId;
  emoji: string;
  label: string;
  /** Uma frase explicando o efeito no escritório (dica na interface). */
  desc: string;
}

/** Na ordem de TRAIT_IDS (um teste confere: o sorteio de personaFor depende dela). */
export const TRAITS: Readonly<Record<TraitId, Trait>> = {
  competicao: { id: 'competicao', emoji: '🏆', get label() { return tr('Competição'); }, get desc() { return tr('Adora competir: desafia os colegas no ping-pong, no videogame e no jokenpô.'); } },
  apostas: { id: 'apostas', emoji: '🎲', get label() { return tr('Apostas'); }, get desc() { return tr('Topa qualquer aposta e aposta alto no jokenpô.'); } },
  games: { id: 'games', emoji: '🎮', get label() { return tr('Games'); }, get desc() { return tr('Vive no videogame do lounge e nos fliperamas — e costuma ganhar.'); } },
  series: { id: 'series', emoji: '📺', get label() { return tr('Séries e TV'); }, get desc() { return tr('Não perde um programa na TV do lounge (de preferência com pipoca).'); } },
  fofoca: { id: 'fofoca', emoji: '🗣️', get label() { return tr('Fofoca'); }, get desc() { return tr('Puxa papo na copa e sabe de tudo o que acontece nas salas.'); } },
  vaidade: { id: 'vaidade', emoji: '💄', get label() { return tr('Vaidade'); }, get desc() { return tr('Passa no espelho do banheiro para se arrumar sempre que pode.'); } },
  cafeina: { id: 'cafeina', emoji: '☕', get label() { return tr('Cafeína'); }, get desc() { return tr('Movido a café: a cafeteira da copa é a segunda casa.'); } },
  piadas: { id: 'piadas', emoji: '😂', get label() { return tr('Piadas'); }, get desc() { return tr('Conta piada em toda conversa e faz a roda rir.'); } },
  esporte: { id: 'esporte', emoji: '🏓', get label() { return tr('Esporte'); }, get desc() { return tr('Joga ping-pong, se alonga e vibra com o futebol na TV.'); } },
  timidez: { id: 'timidez', emoji: '🙈', get label() { return tr('Timidez'); }, get desc() { return tr('Prefere ficar na sua: lê, olha a janela e entra menos nas rodas.'); } },
  economia: { id: 'economia', emoji: '💰', get label() { return tr('Economia'); }, get desc() { return tr('Pão-duro: aposta pouco e às vezes foge da aposta.'); } },
  sonecas: { id: 'sonecas', emoji: '😴', get label() { return tr('Sonecas'); }, get desc() { return tr('Qualquer sofá ou puff vira cama.'); } },
  calma: { id: 'calma', emoji: '🧘', get label() { return tr('Calma'); }, get desc() { return tr('Zen: alongamentos, janela e conversas tranquilas.'); } },
  leitura: { id: 'leitura', emoji: '📚', get label() { return tr('Leitura'); }, get desc() { return tr('Sempre com um livro da estante (ou o celular) na mão.'); } },
};

export function isTraitId(v: unknown): v is TraitId {
  return typeof v === 'string' && (TRAIT_IDS as readonly string[]).includes(v);
}

/** Os dois traços não combinam na mesma pessoa (TRAIT_CLASHES, nos dois sentidos). */
export function traitsClash(a: TraitId, b: TraitId): boolean {
  return TRAIT_CLASHES.some(([x, y]) => (x === a && y === b) || (x === b && y === a));
}

/**
 * Traços escolhidos pelo jogador: 2 ou 3 ids conhecidos, sem repetir e sem par que não combina. Devolve a lista (na
 * ordem recebida) ou null.
 */
export function parsePlayerTraits(raw: unknown): TraitId[] | null {
  if (!Array.isArray(raw) || raw.length < PLAYER_TRAITS.min || raw.length > PLAYER_TRAITS.max) return null;
  const out: TraitId[] = [];
  for (const t of raw) {
    if (!isTraitId(t) || out.includes(t) || out.some((o) => traitsClash(o, t))) return null;
    out.push(t);
  }
  return out;
}
