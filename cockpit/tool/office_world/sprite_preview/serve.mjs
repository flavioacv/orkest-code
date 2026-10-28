import { createServer } from 'node:http';
import { createRequire } from 'node:module';
import { execFileSync } from 'node:child_process';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { readFile } from 'node:fs/promises';

const root = fileURLToPath(new URL('../../../', import.meta.url));
const require = createRequire(new URL('../../../package.json', import.meta.url));
let esbuild;
try { esbuild = require('esbuild'); }
catch {
  // Worktrees can share an already installed build tool with the primary checkout.
  const common = execFileSync('git', ['rev-parse', '--path-format=absolute', '--git-common-dir'], { cwd: root, encoding: 'utf8' }).trim();
  esbuild = createRequire(resolve(dirname(common), 'cockpit/package.json'))('esbuild');
}
const result = await esbuild.build({
  entryPoints: [fileURLToPath(new URL('./preview.ts', import.meta.url))],
  bundle: true, format: 'esm', target: 'es2022', write: false,
  loader: { '.png': 'dataurl' },
});
const css = await readFile(new URL('../../../assets/panel/lib/orkest.css', import.meta.url), 'utf8');
const html = `<!doctype html><html lang="pt-BR"><head>
<link rel="stylesheet" href="/__orkest__/orkest.css">
<meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Office · teste de mesclagem</title>
<style>
body{margin:0;padding:0;background:var(--ckp-bg,Canvas);color:var(--ckp-text,CanvasText);font:13px system-ui}
.toolbar{height:52px;display:flex;align-items:center;gap:12px;padding:8px 12px;padding-right:310px;overflow:auto;white-space:nowrap}h1{font-size:15px;margin:0}.status{color:var(--ckp-text-secondary,GrayText)}
button,select{font:inherit;padding:4px 8px;background:var(--ckp-bg-raised,ButtonFace);color:var(--ckp-text,ButtonText);border:1px solid var(--ckp-border,GrayText);border-radius:4px}
canvas{display:block;width:100vw;height:calc(100vh - 52px);touch-action:none}.error{position:fixed;bottom:10px;background:var(--ckp-bg,Canvas);color:var(--ckp-error,MarkText)}
</style></head><body><div class="toolbar"><h1>Office · sprites nas salas</h1><button id="overview">Visão geral</button>
<label>Estação <select id="season"><option value="spring">Primavera</option><option value="summer" selected>Verão</option><option value="autumn">Outono</option><option value="winter">Inverno</option></select></label>
<span id="status" class="status">Carregando o Office…</span></div>
<canvas id="office" aria-label="Office com sprites novos nas próprias salas"></canvas>
<pre class="error" id="error" hidden></pre>
<script>const showError=e=>{const el=document.querySelector('#error');el.hidden=false;el.textContent=String(e);document.querySelector('#status').textContent='Falha ao carregar a prévia';};window.addEventListener('error',e=>showError(e.message));window.addEventListener('unhandledrejection',e=>showError(e.reason));</script>
<script type="module" src="/preview.js"></script></body></html>`;
const port = Number(process.env.PORT ?? 4318);
createServer((req, res) => {
  res.setHeader('Cache-Control', 'no-store');
  if (req.url === '/preview.js') { res.writeHead(200, { 'Content-Type': 'text/javascript' }); res.end(result.outputFiles[0].text); }
  else if (req.url === '/__orkest__/orkest.css') { res.writeHead(200, { 'Content-Type': 'text/css' }); res.end(css); }
  else if (req.url === '/') { res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' }); res.end(html); }
  else { res.writeHead(404); res.end(); }
}).listen(port, '127.0.0.1', () => console.log(`Office sprite preview: http://127.0.0.1:${port}`));
