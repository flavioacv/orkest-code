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

## Harness-independent events

The Office consumes the terminal session's normalized activities and execution
telemetry. It does not require a particular harness, model, tool name or MCP
namespace. Any agent, extension or runner that can invoke the local Orkest CLI
can use the same contract:

```sh
orkest activity command --id build-1 --phase started --summary 'Build'
orkest activity wait --id build-1 --phase updated --summary 'Waiting for build'
orkest activity command --id build-1 --phase completed --summary 'Build succeeded'
```

Use `failed` or `interrupted` for the corresponding terminal outcome. IDs are
opaque and scoped to the terminal session: reuse one across the phases of an
execution, use a new one for each new execution. Parallel executions use distinct
IDs. Completion is explicit; a turn ending does not complete background work.
Events without `--id` retain the existing single-command behavior.

Confirmed GitHub outcomes use the kinds `pr_opened`, `pr_merged`, `release`,
`push`, `ci_failed` and `ci_passed`, always with `--phase completed`. The summary
is a short display label, not command output. An optional ID deduplicates a
repeated outcome:

```sh
orkest activity pr_merged --id pr-12-merge --phase completed --summary 'PR #12 merged'
orkest activity ci_failed --id ci-42-fail --phase completed --summary 'CI failed'
orkest activity ci_passed --id ci-43-pass --phase completed --summary 'CI recovered'
```

These fields travel through local and remote/sidecar sessions alike. An existing
producer may keep using `orkest telemetry` for execution tracking. Providers that
do not emit activities still use the existing terminal observation fallback;
the Office cannot infer an unreported result reliably. No hook installer or
provider-specific parser is needed for this contract.

### Confirmed VCS results across integrations

The Rust CLI normalizes recognized command results before sending that same
activity contract. The Office renderer does not depend on the provider, harness,
operating system or whether a result came from a CLI, API or MCP adapter.
No provider credentials, titles or raw result payloads are added to Office events.

Commands executed through `orkest exec` and `orkest telemetry` automatically
report recognized Git operations, `gh pr create/merge`, published releases,
completed CI results, `az repos pr create/update` and supported REST calls made
with `gh api`, `az rest` or `curl`. Classification uses the actual argv, exit
code and result. Arbitrary shell scripts, command aliases and unobserved external
processes are not intercepted. Existing plain-terminal detection remains a
limited fallback, independent of whether the agent's turn is idle or working.
An isolated PR/release URL is no longer proof of creation in that fallback;
use the result adapter to establish which operation actually produced it.

```sh
orkest telemetry git push
orkest exec -- gh pr create --fill
orkest exec -- az repos pr create --repository my-repo --source-branch feature --target-branch main
```

An API or MCP integration can feed its completed response through stdin, using
the originating tab and the operation it actually executed:

```sh
orkest activity vcs --operation pr.merge --exit-code 0 --stdin --tab-id t7 < result.json
```

Operations are `pr.create`, `pr.merge`, `push`, `pull`, `merge`, `commit`, `fetch`,
`release` and `ci`. `--exit-code` is the executed command/transport's actual exit
status, not a fabricated success. The adapter accepts GitHub REST/GraphQL and
Azure PR/build objects and standard MCP `structuredContent` or JSON-text content
envelopes. A queued Azure auto-completion or `gh pr merge --auto` is not a
completed merge. Error envelopes, failed requests, draft releases and unfinished
CI runs produce no celebration. Read/list/view PR commands produce no creation
event; an adapter must never label such a request `pr.create`.

Only bounded responses (256 KiB) are inspected. Larger/unsupported responses
produce no event. An optional `--id` supplies a canonical repository/operation
identity for deduplication across producers; otherwise an opaque result-derived
ID is generated. Deduplication is scoped to the originating terminal session.
Existing activity producers can continue reporting canonical
events directly when their provider has another response schema.

PR creation/merge and published releases retain the existing party animation;
CI failure/recovery retain the existing alarm rules. Push remains an activity,
and successful pull/fetch/commit/local merge use the `git` activity without a
party. Repository events never change the agent's turn status, command lifetimes,
presence or permission notification sequence. Both the CLI and app must be
rebuilt/updated to activate the new result adapter and `git` activity handling.

Response references: [GitHub PR creation](https://cli.github.com/manual/gh_pr_create),
[Azure PR CLI](https://learn.microsoft.com/en-us/cli/azure/repos/pr),
[Azure PR response](https://learn.microsoft.com/en-us/rest/api/azure/devops/git/pull-requests/get-pull-request?view=azure-devops-rest-7.1).

## Identity, shell markers and tasks

Automation discovery lists installed CLIs/models. Active Office identity instead
reuses the existing PTY process monitor and shared harness catalog. A producer
outside that catalog may pass `--harness kimi` or `--harness apple-fm`; this is
optional metadata and never gates an event. Process identity takes precedence.

Shells emitting OSC 133/633 C and D markers supply execution boundaries and an
exit code before terminal rendering. Shells without those markers still use
telemetry or the generic activity contract; plain output cannot prove an exit.

```sh
orkest activity task_pending --id task-1 --phase completed --summary 'Review'
orkest activity task_started --id task-1 --phase completed --summary 'Review'
orkest activity task_completed --id task-1 --phase completed --summary 'Review'
orkest activity task_removed --id task-1 --phase completed --summary 'Review'
```

Task events update the real task board without changing the terminal turn.
Titles and IDs are bounded; up to 64 current tasks are retained. Completed tasks
can be evicted when admitting new ones. All fields remain compatible with older
local and sidecar clients.

`office:build` also exports native layout/collision metadata and furniture frame
sprites. Linux renders the Office directly in Flutter, including shell gags,
social scripts, project effects, arrivals/departures and ambient animations.
No additional package or external Habblaud checkout is needed.

The Portuguese animation matrix and trigger report is in
[`docs/office-animations.md`](../../docs/office-animations.md).
