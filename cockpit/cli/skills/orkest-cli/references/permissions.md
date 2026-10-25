# Local socket permissions

Orkest's CLI uses a local Unix socket on macOS/Linux. A coding agent can read
the executable and discover the socket while its execution sandbox still
rejects `connect()` with `Operation not permitted`. Moving or renaming the
socket does not grant permission. The app cannot change another program's
sandbox policy.

## Recover an interactive Codex session

1. Inspect the current policy (`/status` and `/permissions` in Codex).
   `approval_policy = "never"` and granular `sandbox_approval = false` both
   prevent execution-approval requests. A separate `request_permissions = true`
   is not the same permission; use that tool only if actually exposed and able
   to request the required connection.
2. If execution approvals are enabled, request scoped approval for the exact
   CLI invocation and retry it if approved. A persisted command rule helps only
   in sessions whose active policy permits that rule/approval mechanism.
3. If the session prohibits approvals, the user must choose a policy that
   permits them through `/permissions`, or exit the TUI and resume the **same**
   conversation from its terminal shell:

   ```sh
   codex resume <session-id> --sandbox workspace-write --ask-for-approval on-request
   ```

   Replace `<session-id>` with the known conversation ID. Do not guess it from
   the focused tab or resume an unrelated latest session. This keeps workspace
   sandboxing and enables permission prompts for that invocation. Managed
   requirements can still prohibit this choice; report that constraint.
4. Retry `"$HOME/.orkest/bin/orkest" list-tabs --json` through scoped approval,
   then target the returned IDs explicitly. Approval must happen in the
   **orchestrator's** session; approval in a diagnostic agent is not inherited.

Do not send a restart command into a running TUI as if it were a shell. Do not
change another session's permissions, create global allow rules, enable all
network access, or bypass the sandbox without explicit authorization. Installing
or rereading a skill alone cannot grant socket access.

## Verify the boundary on macOS

With authorization to run a diagnostic sandbox from the host, Codex 0.164.0
supports the following comparison (older versions may use
`codex sandbox macos`; check `codex sandbox --help`):

```sh
codex sandbox -- "$HOME/.orkest/bin/orkest" list-tabs --json
codex sandbox --allow-unix-socket "$HOME/.orkest/status.sock" -- \
  "$HOME/.orkest/bin/orkest" list-tabs --json
```

The first can fail with a permission error while the second succeeds. The second
allows only the specified socket in that diagnostic child; it does not change
an existing agent session. For a development build use `bin-debug/orkest` and
`status-debug.sock`. Use the endpoint actually reported by the CLI; remote
workspaces may have a different endpoint. Do not silently fall back to a TCP or
shell bridge to evade a denied connection.

For durable permission profiles, use the active Codex version's documented
Unix socket allowlist and the absolute socket path. Do not assume a profile is
active merely because its TOML exists.

Official references:
- [Approvals and security](https://learn.chatgpt.com/docs/agent-approvals-security)
- [Permission profiles and Unix sockets](https://learn.chatgpt.com/docs/permissions)
