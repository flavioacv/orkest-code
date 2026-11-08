// Temas de sala modernos para o Orkest Studio: paletas sofisticadas, contrastantes e contemporâneas.
import type { RoomTheme } from './api';

const THEMES: readonly RoomTheme[] = [
  { carpet: '#2a3342', carpet2: '#202733', wall: { base: '#3a4454', trim: '#56667d', pattern: 'plain' }, accent: '#38bdf8', deskVariant: 'dark', chairVariant: 'blue' },
  { carpet: '#342f2b', carpet2: '#282421', wall: { base: '#433c37', trim: '#6a5e56', pattern: 'wood_panel' }, accent: '#f59e0b', deskVariant: 'wood', chairVariant: 'black' },
  { carpet: '#24342d', carpet2: '#1b2823', wall: { base: '#32453c', trim: '#4c675a', pattern: 'plain' }, accent: '#10b981', deskVariant: 'dark', chairVariant: 'green' },
  { carpet: '#31293c', carpet2: '#262030', wall: { base: '#423752', trim: '#65547d', pattern: 'plain' }, accent: '#a855f7', deskVariant: 'white', chairVariant: 'gray' },
  { carpet: '#382b2d', carpet2: '#2b2123', wall: { base: '#4a393c', trim: '#73585d', pattern: 'brick' }, accent: '#f43f5e', deskVariant: 'dark', chairVariant: 'red' },
  { carpet: '#22353a', carpet2: '#1a292d', wall: { base: '#30474e', trim: '#486b76', pattern: 'stripes' }, accent: '#06b6d4', deskVariant: 'white', chairVariant: 'green' },
  { carpet: '#262a33', carpet2: '#1d2027', wall: { base: '#363c48', trim: '#555e71', pattern: 'brick' }, accent: '#eab308', deskVariant: 'dark', chairVariant: 'black' },
  { carpet: '#362832', carpet2: '#2a1f27', wall: { base: '#493643', trim: '#715468', pattern: 'stripes' }, accent: '#ec4899', deskVariant: 'white', chairVariant: 'black' },
  { carpet: '#253044', carpet2: '#1c2535', wall: { base: '#35435e', trim: '#526892', pattern: 'wood_panel' }, accent: '#3b82f6', deskVariant: 'wood', chairVariant: 'blue' },
  { carpet: '#322b27', carpet2: '#27211e', wall: { base: '#443a34', trim: '#6b5c53', pattern: 'wood_panel' }, accent: '#f97316', deskVariant: 'dark', chairVariant: 'gray' },
];

export const THEME_COUNT = THEMES.length;

export function roomTheme(seed: number): RoomTheme {
  const n = THEMES.length;
  const t = THEMES[((Math.floor(seed) % n) + n) % n];
  return { ...t, wall: { ...t.wall } };
}
