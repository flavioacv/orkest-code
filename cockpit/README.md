# Orkest Code

**Orchestrate AI. Build Better.**

Independent development environment combining terminals, project tools and an
interactive Office for AI agents. Harness communication remains provider-neutral.

- Application: `Orkest Code`
- CLI: `orkest`
- Application ID: `com.flavioacv.orkestcode`
- User data: `~/.orkest` (isolated from Cockpit)
- Workspace configuration: `.orkest/`, `.env.orkest`
- Source: https://github.com/flavioacv/orkest-code

## Develop

The repository directory remains `cockpit/` during migration.

```sh
cd cockpit
flutter pub get
npm ci
npm run office:build
flutter run -d macos
```

The Office engine is vendored in `third_party/office_engine`; no adjacent
Habblaud checkout is needed. `npm run office:test` tests its session adapter.
`python3 tool/generate_orkest_icons.py` regenerates platform icons (Pillow).

## CLI

Inside an Orkest terminal:

```sh
orkest list-tabs
orkest new-tab --title Developer
orkest read-tab Developer
```

The application injects its CLI path and `ORKEST_*` connection variables. It
does not register a global `cockpit` alias or route to the other product.

If an agent reports `Operation not permitted`, its sandbox may be blocking the
local socket. Sessions with `sandbox_approval: false` cannot request execution
approval. Enable interactive approvals in that session, keeping the workspace
sandbox, then approve the CLI command. See the
[permission recovery guide](cli/skills/orkest-cli/references/permissions.md).

## Distribution status

Automatic updates are powered by Sparkle (macOS) and WinSparkle (Windows) using Cloudflare Pages (`https://orkest-updates.pages.dev`).
Releases are signed cryptographically with Ed25519 keys via GitHub Actions (`.github/workflows/orkest-release.yml`).
The new app starts with independent data; old sessions/secrets are not imported.

## Attribution

Derived from Cockpit/Remote Pi and the Habblaud Office engine. Original MIT
notices are preserved; see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md) and
[Office provenance](third_party/office_engine/PROVENANCE.md).

Migration details: [implementation status](docs/orkest-code-migration-status.md).
