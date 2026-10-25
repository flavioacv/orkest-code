---
name: orkest-cli
description: >-
  Drive Orkest's terminal tabs from inside one. Use when you (an agent in a Orkest terminal) need to open, split, type into, read or close tabs, run a shell line through the app (`orkest exec`), start or read a task run, or list tabs and workspaces. Triggers on tmux-like needs (new window, send keys, read another tab's output, interrupt a stuck process) and on "where am I / what is open" questions. Databases, telemetry and the files the human reads (.panel, .kanban, .notebook, .ckp, .http) have their own skills: orkest-db, orkest-telemetry, orkest-design.
---

# orkest — Orkest's internal CLI

Orkest is an IDE that multiplexes terminals. The `orkest` command talks to the app and lets you **inject
text/keys** into any tab, **read** what tabs and tasks printed, and **list**
tabs/workspaces. The app injects its PATH and routing into terminal processes;
an agent's execution tool may filter that environment. Missing PATH entries or
`ORKEST_*` variables alone do **not** prove that the session is outside Orkest.
The public command is `orkest`; no Cockpit alias is installed.

## First connection: filtered environments and sandbox permissions

1. Try `command -v orkest`. If missing, check the installed absolute path:
   `"$HOME/.orkest/bin/orkest" --version` (release) or
   `"$HOME/.orkest/bin-debug/orkest" --version` (development build).
   On Windows use `$env:USERPROFILE\.orkest\bin\orkest.exe` in PowerShell.
   On macOS the packaged fallback is
   `/Applications/Orkest Code.app/Contents/Resources/orkest-cli`.
2. Run that binary's `list-tabs --json`. Local socket discovery works without
   `ORKEST_*` environment variables. When both debug and release are running,
   select the binary/endpoint for the intended app; inspect the returned tabs.
3. `Operation not permitted` / `Permission denied` means the execution sandbox
   or OS blocked a local connection, not that the skill or app is absent.
   Inspect the session's permission policy before requesting scoped approval
   for the same command. If an explicit permission-request tool is available,
   request only the local connection it supports, then retry if granted.
   If approvals are disabled (`never` or `sandbox_approval: false`), do not
   repeatedly retry or ask the user to open tabs manually: explain the policy
   and give the concrete recovery in [references/permissions.md](references/permissions.md). Permission
   grants for this agent do not grant access to another session. Do not disable
   sandboxing or change global harness configuration to make this work.
4. If routing variables were removed, use explicit IDs from `list-tabs` for
   `send`/`read-tab`, and `new-tab --parent-tab <known-orchestrator-id>` when
   the parent is known. Do not guess the originating tab from focus alone.
5. If the user requested agents in **Orkest terminal tabs**, do not silently
   substitute internal collaboration agents. Confirm terminal creation with
   returned tab IDs and `read-tab`; if approval is denied, explain the blocked
   operation instead of claiming that terminal agents were created.

The skill is installed globally for discovery; that does not put the CLI on
every subprocess's PATH. Prefer absolute-path fallback over asking the user to
move a conversation that may already be running in the right terminal.

> **Tab vs pane.** A **tab** is a single terminal/agent session, the unit this
> CLI addresses (`--tab-id`). A **pane** is the split leaf that holds tabs; the
> CLI does not address it. `list-panes`/`read-pane`/`$ORKEST_PANE_ID` are
> legacy aliases of `list-tabs`/`read-tab`/`$ORKEST_TAB_ID`.

## Verbs at a glance

| Verb | What |
|---|---|
| `send [--tab-id] [--enter] <text>` | type text; `--enter` submits |
| `send-key [--tab-id] <Key>...` | `Enter`, `Tab`, `Escape`, arrows, `C-c`... |
| `agent start <id> [--type]` · `agent stop <id> [--outcome]` | report a child agent to Office from a harness adapter |
| `activity <kind> --summary <text> [--phase]` | report a provider-neutral Office activity; use `needs_input` only when a human must act |
| `new-tab [--cwd] [--title] [--split h\|v] [--parent-tab id \| --independent]` | open a terminal tab, prints its id; agent callers become its Office parent |
| `close-tab [<label\|id>]` | close a tab (**no target = your own tab**) |
| `open <file>` / `orkest <file>` | open a file in the app's viewer |
| `exec [--cwd] [--timeout] [--json] -- <cmd>` | run a shell line through the app (on the host, in a remote workspace) |
| `browse <url>` | open the built-in browser tab |
| `read-tab [<label\|id>] [--lines N]` | a tab's rendered output, tail by default |
| `list-tasks` · `run-task` · `stop-task` · `restart-task` · `send-task-key` · `read-task` | drive and read the Tasks panel |
| `list-tabs` · `list-workspaces` | what is open (ids change every boot) |
| `new-workspace <path> [--host]` · `close-workspace` · `rename-workspace` | the rail |
| `orchestrate <file.ckp> [--append]` | apply a pane layout (format: orkest-design, `references/ckp.md`) |
| `panel new --template <t> <file>` · `panel screenshot [<target>]` | scaffold a `.panel`, see it as a PNG (orkest-design) |

Flags, output shapes and edge cases of every verb: **read `references/verbs.md`**
before using a verb for the first time.

Other skills, when the task is one of these:
- SQL / Redis / Mongo / `.dbq` / connections: **orkest-db**.
- Errors, logs, "why did it fail", instrumenting a project: **orkest-telemetry**.
- Writing a `.panel`, `.html`, `.kanban`, `.notebook`, `.ckp` or `.http` the
  human will open: **orkest-design**.

## Target (--tab-id)

Without `--tab-id`, the command acts on **your own tab** (via `$ORKEST_TAB_ID`,
legacy fallback `$ORKEST_PANE_ID`). To drive **another** tab, pass
`--tab-id <id>`.

> Ids (`t0`, `t1`…) are sequential and **change on every app boot**. Never
> guess an id: run `orkest list-tabs` first and use the `id` from there.

## Usage pattern

To run a command in a tab, use `--enter` (the text alone is only typed, not
submitted):

```sh
orkest send --enter "npm test"
```

`--enter` presses Enter as a separate keystroke right after the text, which is
what TUIs expect. The two-step form still works when you need to type something
and press a different key:

```sh
orkest send "npm test"
orkest send-key Enter
```

Cross-tab (drive another tab):

```sh
orkest list-tabs                        # find the target id, e.g. t4
orkest send --tab-id t4 --enter "git status"
```

Interrupt a stuck process in another tab:

```sh
orkest send-key --tab-id t4 C-c
```

Read what another tab printed (e.g. check on a worker, debug a failure):

```sh
orkest read-tab t4 --lines 50            # last 50 lines of t4
orkest read-tab Extension                # by stable label (last 100 lines)
orkest read-tab t4 --lines 100 --offset 100   # the 100 lines before those
```

Read a task run's output (dev server, build, test — the Task Run feature):

```sh
orkest list-tasks                        # ids: ● = running, [output] = readable
orkest read-task npm:dev --lines 80      # tail of the "npm:dev" task output
```

Typical loop — dispatch work to a tab, wait, then read the result:

```sh
orkest send --tab-id t4 --enter "npm test"
# poll `orkest list-tabs --json` until t4 shows "working": false, then:
orkest read-tab t4 --lines 60
```

## Common errors

- "ORKEST_STATUS_SOCK is unset" → check well-known socket discovery; environment may be filtered.
- "Operation not permitted" / "Permission denied" → request scoped execution approval and retry the same CLI command.
- "tab ... does not exist" → stale id (app reboot). Run `list-tabs` again.
- "tab ... is not a terminal" → the target is an agent/file tab, not a shell.
- "has no readable output" → read-tab target is an agent/file tab; only
  terminal and task-output tabs are readable.
- "no output recorded for task ..." → the task never ran this app boot, or the
  id is wrong — check both with `orkest list-tasks` (`[output]` = readable).
