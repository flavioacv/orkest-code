# Orkest Office world

The adapter bundles a locally vendored Office simulation with the terminal
session lifecycle. Upstream attribution is in third_party/office_engine.

```sh
npm ci
npm run office:build
npm run office:test
```

Sources are local: no adjacent Habblaud checkout or node_modules is required.
The build preserves locale compatibility and expiring completion bubbles.
Brand images are not loaded; the reception label is Orkest Code.
The embedded manifest has no upstream brand plaque or logo payload.

After changing the bundle, recreate the application/WebView. Ordinary Office
switching retains the simulation of the same live sessions.
