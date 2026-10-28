//! Provider-neutral activity reporting for the Orkest Office.

use serde_json::json;

use crate::transport;
use crate::util::{die, self_tab_id};

const KINDS: &[&str] = &[
    "prompt", "thinking", "read", "search", "edit", "write", "command", "wait",
    "test", "web", "plan", "delegate", "needs_input", "respond", "done", "error", "other",
    "pr_opened", "pr_merged", "release", "ci_failed", "ci_passed", "push", "git",
    "task_pending", "task_started", "task_completed", "task_removed",
];
const PHASES: &[&str] = &["started", "updated", "completed", "failed", "interrupted"];
const HELP: &str = "orkest activity <kind> --summary <text> [--phase <phase>] [--id <execution-id>] [--harness <id>] [--tab-id <id>]
  Report a provider-neutral activity to the Office. No terminal output, prompt,
  or transcript is read or sent. Use needs_input only when user action is required.
  Kinds: prompt, thinking, read, search, edit, write, command, wait, test, web,
         plan, delegate, needs_input, respond, done, error, other,
         pr_opened, pr_merged, release, ci_failed, ci_passed, push, git,
         task_pending, task_started, task_completed, task_removed
  Phases: started (default), updated, completed, failed, interrupted
  --id correlates parallel command/wait executions or deduplicates GitHub events.
  --harness is optional descriptive metadata, including unregistered producers.
  Reuse the same ID for all phases of an execution; use a new ID for a new run.
  Repository kinds require --phase completed and report a confirmed outcome only.
  Task kinds require --id and --phase completed; --summary is the task title.
  Use `orkest activity vcs --help` to normalize a command/API/MCP result from stdin.";

pub fn activity(args: &[String]) -> ! {
    if args.first().map(String::as_str) == Some("vcs") {
        crate::vcs::report(&args[1..]);
    }
    if args.is_empty() || args[0] == "--help" || args[0] == "-h" {
        println!("{HELP}");
        std::process::exit(if args.is_empty() { 2 } else { 0 });
    }
    let kind = args[0].as_str();
    if !KINDS.contains(&kind) {
        die(&format!("orkest activity: unknown kind \"{kind}\"\n{HELP}"), 2);
    }
    let mut summary = None;
    let mut phase = "started".to_string();
    let mut tab_id = None;
    let mut activity_id = None;
    let mut harness = None;
    let mut i = 1;
    while i < args.len() {
        let arg = args[i].as_str();
        if !["--summary", "--phase", "--tab-id", "--id", "--harness"].contains(&arg) || i + 1 >= args.len() {
            die(&format!("orkest activity: invalid or incomplete option \"{arg}\"\n{HELP}"), 2);
        }
        i += 1;
        match arg {
            "--summary" => summary = Some(args[i].clone()),
            "--phase" => phase = args[i].clone(),
            "--id" => activity_id = Some(args[i].clone()),
            "--harness" => harness = Some(args[i].clone()),
            _ => tab_id = Some(args[i].clone()),
        }
        i += 1;
    }
    if !PHASES.contains(&phase.as_str()) {
        die("orkest activity: invalid phase", 2);
    }
    if let Some(id) = &activity_id {
        if id.is_empty() || id.len() > 160 ||
            !id.bytes().all(|b| b.is_ascii_alphanumeric() || b"_.:/-".contains(&b)) {
            die("orkest activity: --id must be 1-160 ASCII letters, digits or _ . : / -", 2);
        }
    }
    if let Some(id) = &harness {
        if id.is_empty() || id.len() > 80 || !id.bytes().all(|b| b.is_ascii_alphanumeric() || b"_.:/-".contains(&b)) {
            die("orkest activity: invalid --harness identifier", 2);
        }
    }
    if ["pr_opened", "pr_merged", "release", "ci_failed", "ci_passed", "push", "git"].contains(&kind)
        && phase != "completed" {
        die("orkest activity: repository outcomes require --phase completed", 2);
    }
    if ["task_pending", "task_started", "task_completed", "task_removed"].contains(&kind)
        && (activity_id.is_none() || phase != "completed") {
        die("orkest activity: task updates require --id and --phase completed", 2);
    }
    let summary: String = summary
        .unwrap_or_default()
        .chars()
        .filter(|c| !c.is_control())
        .take(160)
        .collect::<String>()
        .trim()
        .to_string();
    if summary.is_empty() {
        die("orkest activity: --summary is required", 2);
    }
    let pane_id = tab_id
        .filter(|value| !value.trim().is_empty())
        .or_else(self_tab_id)
        .unwrap_or_else(|| die("orkest activity: no parent tab — run inside a Orkest terminal or pass --tab-id", 3));
    let status = if kind == "needs_input" { "waiting" } else { "activity" };
    let mut payload = json!({
        "paneId": pane_id,
        "st": status,
        "activityKind": kind,
        "activityPhase": phase,
        "activitySummary": summary,
    });
    if let Some(id) = activity_id {
        payload["activityId"] = json!(id);
    }
    if let Some(id) = harness {
        payload["hn"] = json!(id);
    }
    if let Err(error) = transport::notify(payload) {
        die(&format!("orkest activity: {error}"), 3);
    }
    std::process::exit(0)
}
