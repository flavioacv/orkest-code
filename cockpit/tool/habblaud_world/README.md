# Habblaud Canvas world bundle

`main.ts` adapts Cockpit's local project/session snapshot to Habblaud's original
Canvas 2D simulation, renderer, camera, overlay, and input handling. The
runtime bundle is `assets/habblaud_world/engine.js`; the original art files are
embedded in `assets.ts` so the WebView makes no network requests.

The adapter imports the Habblaud source from the adjacent `habblaud` checkout
(`../../../../habblaud/client/src`). Rebuild the runtime bundle from the
Cockpit directory with:

```sh
node tool/habblaud_world/build.mjs
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

The build script preserves locale compatibility and expiring completion bubbles.
Portrait cropping lives in `main.ts`. Use this script instead of a raw esbuild
invocation. The script fails if an upstream compatibility anchor changes.

`social.ts` exports the simulation's social profile and game events through a
session-owned bridge. Wallets and opponent records use the terminal's immutable
Office identity, never its project, character name or harness. Closed sessions
are pruned. See [session lifecycle](../../docs/office-social-session-lifecycle.md).

After changing the bundled engine, restart the Flutter application (hot restart
is sufficient) to recreate the WebView with the new JavaScript. Ordinary tab and
Office switching must continue to preserve the existing simulation.
