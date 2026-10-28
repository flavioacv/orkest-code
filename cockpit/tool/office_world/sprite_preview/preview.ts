// Load the actual Office entry point; the preview only supplies example sessions.
import '../main.ts';

const startedAt = Date.now();
let season = 'summer';
const snapshot = () => ({
  serverTime: Date.now(),
  options: { locale: 'pt-BR', daylight: 'day', season, theme: 'none', sound: false, showNames: true },
  accounts: [{ id: 'preview', short: 'O', name: 'Office', color: '#4488ff' }],
  rooms: [
    { id: 'project-a', name: 'Sala · sprites novos + originais', seed: 1, slot: 0, path: '/office/a', createdAt: startedAt },
    { id: 'project-b', name: 'Sala · comparação de móveis', seed: 2, slot: 1, path: '/office/b', createdAt: startedAt },
  ],
  agents: Array.from({ length: 6 }, (_, index) => ({
    id: `person-${index}`, kind: 'main', roomId: index < 3 ? 'project-a' : 'project-b',
    name: ['Ana', 'Bruno', 'Carla', 'Diego', 'Elisa', 'Fábio'][index], account: 'preview',
    look: index % 2 ? 'm' : 'f', seed: index + 4, status: 'working',
    startedAt, statusSince: startedAt, lastEventAt: startedAt, tasks: [],
    stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 },
    activity: { id: `demo-${index}`, kind: 'command', at: startedAt, label: 'Trabalhando no Office' },
  })),
});
window.orkestOfficeWorld.update(snapshot());
requestAnimationFrame(() => requestAnimationFrame(() => window.orkestOfficeWorld.overview()));
const timer = setInterval(() => window.orkestOfficeWorld.update(snapshot()), 1500);
window.addEventListener('pagehide', () => { clearInterval(timer); window.orkestOfficeWorld.destroy(); }, { once: true });
document.querySelector<HTMLSelectElement>('#season')!.onchange = event => {
  season = (event.target as HTMLSelectElement).value; window.orkestOfficeWorld.update(snapshot());
};
document.querySelector<HTMLButtonElement>('#overview')!.onclick = () => window.orkestOfficeWorld.overview();
document.querySelector<HTMLElement>('#status')!.textContent = 'Mesmo motor e integração do Office · sessões de exemplo';
