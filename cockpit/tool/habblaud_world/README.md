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
