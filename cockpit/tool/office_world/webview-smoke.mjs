// Browser contract check against the production bundle and the actual Flutter HTML template.
// Run after office:build; open http://127.0.0.1:4322 and inspect #result[data-state].
import { createServer } from 'node:http';
import { readFile } from 'node:fs/promises';

const dart = await readFile(new URL('../../lib/app/orkest/ui/widgets/habblaud_world_webview.dart', import.meta.url), 'utf8');
const bundle = await readFile(new URL('../../assets/office_world/engine.js', import.meta.url), 'utf8');
const template = dart.match(/return '''(<!doctype html>[\s\S]*?)''';/);
if (!template || !dart.includes("'assets/office_world/engine.js'")) throw new Error('Review the Flutter Office loader before running this smoke test');
const officeDocument = template[1].replace('$safeBundle', () => bundle.replaceAll('</script', '<\\/script'));

async function browserChecks() {
  const result = document.querySelector('#result');
  const frame = document.querySelector('iframe');
  const checks = [], errors = [], clicks = [];
  const check = (name, valid) => {
    if (!valid) throw new Error(name);
    checks.push(name);
  };
  const wait = ms => new Promise(resolve => setTimeout(resolve, ms));
  const load = () => new Promise((resolve, reject) => {
    frame.onload = () => resolve(); frame.onerror = () => reject(new Error('Office document failed to load'));
    frame.src = '/office-document?generation=' + Date.now();
  });
  const attach = () => {
    const child = frame.contentWindow;
    child.addEventListener('error', event => errors.push(String(event.error ?? event.message)));
    child.addEventListener('unhandledrejection', event => errors.push(String(event.reason)));
    child.flutter_inappwebview = { callHandler: async (name, ...args) => { clicks.push({ name, args }); } };
    return child.orkestOfficeWorld;
  };
  try {
    await load();
    let api = attach();
    check('production API is available', !!api);
    const at = Date.now();
    const input = { rev: 101, serverTime: at,
      accounts: [{ id: 'codex', provider: 'codex', short: 'C', name: 'Codex', color: '#596273', configDir: '~/.orkest', sessions: 2 }],
      rooms: [{ id: 'workspace', name: 'Workspace', slot: 0, seed: 7, path: '/workspace', createdAt: at }],
      agents: ['pty-a', 'pty-b'].map((id, i) => ({ id, kind: 'main', sessionId: id, sessionBacked: true,
        socialIdentity: id + ':live', roomId: 'workspace', provider: 'codex',
        harness: { id: 'codex', label: 'Codex', source: 'terminal' },
        account: 'codex', name: i ? 'Bruno' : 'Ana', look: i ? 'm' : 'f', seed: 4 + i,
        status: 'working', activity: { id: id + '-work', kind: 'command', at, label: 'Working' },
        startedAt: at, lastEventAt: at, statusSince: at, tasks: [],
        stats: { toolCalls: 0, tokensIn: 0, tokensOut: 0, subagents: 0 } })),
      options: { locale: 'pt-BR', showNames: true, bubbles: 'all', liveliness: 'normal', daylight: 'day',
        theme: 'none', season: 'summer', sound: false, sounds: { volume: 0, alerts: false, keys: false, elevator: false, social: false } },
      meta: { demo: false, sources: [], startedAt: at, version: 'orkest' } };
    check('snapshot revision is acknowledged', api.update(input) === 101);
    const social = api.getSocialSnapshot();
    check('only supplied terminal sessions are exposed', Object.keys(social.agents).sort().join() === 'pty-a,pty-b');
    check('live social identity matches Flutter', social.agents['pty-a'].identity === 'pty-a:live');
    const saved = social.agents['pty-a'].state;
    check('wallet and social state can be persisted', !!saved?.wallet && saved.version === 1);
    saved.wallet.coins = 321;
    const appearance = api.getAppearance(4, 'f');
    check('profile editor returns usable portraits', appearance.preview.startsWith('data:image/png;base64,') && appearance.avatar.startsWith('data:image/png;base64,'));
    check('profile editor preserves selectable appearance parts', Object.keys(appearance.parts).length > 5 && Object.keys(appearance.options).length > 5);
    api.selectAgent('pty-a'); api.setFollowAgent('pty-a', false); api.overview();
    check('selection and camera bridge calls are accepted', true);
    await load(); api = attach();
    input.rev++; input.agents[0].socialState = saved;
    check('recreated WebView accepts the session snapshot', api.update(input) === input.rev);
    check('session wallet survives WebView recreation', api.getSocialSnapshot().agents['pty-a'].state.wallet.coins === 321);
    input.agents[0].socialIdentity = 'pty-a:new-live'; input.rev++;
    api.update(input);
    check('a replaced session cannot inherit the previous wallet', api.getSocialSnapshot().agents['pty-a'].state.wallet.coins !== 321);
    // Allow the real arrival/navigation loop to finish, then exercise the click callback used by Flutter.
    await wait(16000);
    api.focusAgent('pty-a', false); await wait(600);
    const canvas = frame.contentDocument.querySelector('#office');
    const bounds = canvas.getBoundingClientRect();
    for (let offset = -84; offset <= 12 && !clicks.length; offset += 12) {
      const point = { clientX: bounds.width / 2, clientY: bounds.height / 2 + offset,
        pointerId: 1, pointerType: 'mouse', button: 0, bubbles: true };
      canvas.dispatchEvent(new frame.contentWindow.PointerEvent('pointerdown', point));
      canvas.dispatchEvent(new frame.contentWindow.PointerEvent('pointerup', point));
    }
    check('agent click uses the Flutter callback and live session id', clicks.some(c => c.name === 'officeAgentClicked' && c.args[0] === 'pty-a'));
    input.agents = [input.agents[0]]; input.rev++; api.update(input);
    check('closing a terminal removes its social entry', !api.getSocialSnapshot().agents['pty-b']);
    check('no JavaScript runtime errors', errors.length === 0);
    result.dataset.state = 'passed';
    result.textContent = JSON.stringify({ state: 'passed', checks, errors, clicks }, null, 2);
  } catch (error) {
    result.dataset.state = 'failed';
    result.textContent = JSON.stringify({ state: 'failed', error: String(error), checks, errors, clicks }, null, 2);
  }
}

const html = `<!doctype html><meta charset="utf-8"><title>Office WebView contract check</title>
<style>body{margin:0;background:#18181b;color:#eee;font:13px monospace}iframe{width:100vw;height:80vh;border:0}pre{white-space:pre-wrap;padding:12px}</style>
<iframe title="Production Office document"></iframe><pre id="result" data-state="running">Checking production WebView contract…</pre>
<script>(${browserChecks.toString()})()</script>`;
const port = Number(process.env.PORT ?? 4322);
createServer((req, res) => {
  const path = new URL(req.url, 'http://127.0.0.1').pathname;
  res.setHeader('Cache-Control', 'no-store');
  if (path === '/office-document') { res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); res.end(officeDocument); }
  else if (path === '/') { res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); res.end(html); }
  else { res.writeHead(404); res.end(); }
}).listen(port, '127.0.0.1', () => console.log(`Office WebView smoke: http://127.0.0.1:${port}`));
