# Habblaud Canvas world bundle

`main.ts` adapts Cockpit's local project/session snapshot to Habblaud's original
Canvas 2D simulation, renderer, camera, overlay, and input handling. The
runtime bundle is `assets/habblaud_world/engine.js`; the original art files are
embedded in `assets.ts` so the WebView makes no network requests.

The adapter imports the Habblaud source from the adjacent `habblaud` checkout
(`../../../../habblaud/client/src`). Rebuild the runtime bundle from the
Cockpit directory with:

```sh
../../habblaud/node_modules/.bin/esbuild tool/habblaud_world/main.ts \
  --bundle --format=iife --target=es2022 \
  --outfile=assets/habblaud_world/engine.js
```

The copied Habblaud license is in `assets/habblaud_world/LICENSE`.

`CockpitSim` in `sim.ts` preserves an elevator arrival when a PTY status changes
before the first animation frame. It also repairs orphaned invisible characters
without moving them or changing their work/wait/idle status. Each terminal keeps
its own character and reserved desk, even when several terminals share a project.

Regression checks (real Habblaud simulation, no renderer/browser required):

```sh
../../habblaud/node_modules/.bin/esbuild tool/habblaud_world/sim.test.ts \
  --bundle --platform=node --format=cjs --outfile=/tmp/cockpit-office-sim.test.cjs
node --test /tmp/cockpit-office-sim.test.cjs
```

The current runtime bundle also contains existing compatibility patches for
locale changes, cropped character portraits and expiring completion bubbles.
A raw rebuild must preserve these patches; the `CockpitSim` update was applied
to the existing bundle without replacing them.

After changing the bundled engine, restart the Flutter application (hot restart
is sufficient) to recreate the WebView with the new JavaScript. Ordinary tab and
Office switching must continue to preserve the existing simulation.
