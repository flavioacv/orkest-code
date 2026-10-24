import { build } from '../../../../habblaud/node_modules/esbuild/lib/main.js';
import { writeFile } from 'node:fs/promises';
import { fileURLToPath } from 'node:url';

const result = await build({ entryPoints: [fileURLToPath(new URL('./main.ts', import.meta.url))],
  bundle: true, format: 'iife', target: 'es2022', write: false });
let source = result.outputFiles[0].text;
const locale = /function setLocale\((\w+)\) \{\s*current = \1;\s*\}/;
if (!locale.test(source)) throw new Error('Review Habblaud locale compatibility before rebuilding');
source = source.replace(locale, `function setLocale(value) {
  const next = normalizeLocale(value) ?? "pt-BR";
  if (current === next) return;
  current = next;
  if (typeof KINDS !== "undefined") {
    const labels = {tv:"Vendo TV",videogame:"Jogando videogame",arcade:"Duelo no fliperama",pingpong:"Jogando pingue-pongue",kitchen:"Papo na copa",talk:"Conversando",rps:"Jokenpô",mirror:"Se arrumando no espelho"};
    for (const [kind, label] of Object.entries(labels)) KINDS[kind].label = tr(label);
    PLACES = { [LOUNGE_ID]: tr("Lounge"), [CAFE_ID]: tr("Copa"), [RECEPTION_ID]: tr("Recepção"), [RESTROOM_ID]: tr("Banheiros") };
    MATCH_WHAT = { rps: tr("no jokenpô"), pingpong: tr("no pingue-pongue"), videogame: tr("no videogame"), arcade: tr("no fliperama") };
  }
}`);
const bubble = 'const age = now - ch.activityChangedAt;';
if (!source.includes(bubble)) throw new Error('Review completion bubble compatibility before rebuilding');
source = source.replace(bubble, `${bubble}\n      if (act.kind === "done" && age >= RECENT_MS) return null;`);
await writeFile(new URL('../../assets/habblaud_world/engine.js', import.meta.url), source);
console.log('Built Cockpit Office with session-scoped social state and compatibility patches.');
