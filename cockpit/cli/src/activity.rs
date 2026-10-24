//! Provider-neutral activity reporting for the Cockpit Office.

use serde_json::json;

use crate::transport;
use crate::util::{die, self_tab_id};

const KINDS: &[&str] = &[
    "prompt", "thinking", "read", "search", "edit", "write", "command", "wait",
    "test", "web", "plan", "delegate", "needs_input", "respond", "done", "error", "other",
];
const PHASES: &[&str] = &["started", "updated", "completed", "failed", "interrupted"];
const HELP: &str = "cockpit activity <kind> --summary <text> [--phase <phase>] [--tab-id <id>]
  Report a provider-neutral activity to the Office. No terminal output, prompt,
  or transcript is read or sent. Use needs_input only when user action is required.
  Kinds: prompt, thinking, read, search, edit, write, command, wait, test, web,
         plan, delegate, needs_input, respond, done, error, other
  Phases: started (default), updated, completed, failed, interrupted";

pub fn activity(args: &[String]) -> ! {
    if args.is_empty() || args[0] == "--help" || args[0] == "-h" {
        println!("{HELP}");
        std::process::exit(if args.is_empty() { 2 } else { 0 });
    }
    let kind = args[0].as_str();
    if !KINDS.contains(&kind) {
        die(&format!("cockpit activity: unknown kind \"{kind}\"\n{HELP}"), 2);
    }
    let mut summary = None;
    let mut phase = "started".to_string();
    let mut tab_id = None;
    let mut i = 1;
    while i < args.len() {
        let arg = args[i].as_str();
        if !["--summary", "--phase", "--tab-id"].contains(&arg) || i + 1 >= args.len() {
            die(&format!("cockpit activity: invalid or incomplete option \"{arg}\"\n{HELP}"), 2);
        }
        i += 1;
        match arg {
            "--summary" => summary = Some(args[i].clone()),
            "--phase" => phase = args[i].clone(),
            _ => tab_id = Some(args[i].clone()),
        }
        i += 1;
    }
    if !PHASES.contains(&phase.as_str()) {
        die("cockpit activity: invalid phase", 2);
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
        die("cockpit activity: --summary is required", 2);
    }
    let pane_id = tab_id
        .filter(|value| !value.trim().is_empty())
        .or_else(self_tab_id)
        .unwrap_or_else(|| die("cockpit activity: no parent tab — run inside a Cockpit terminal or pass --tab-id", 3));
    let status = if kind == "needs_input" { "waiting" } else { "activity" };
    let payload = json!({
        "paneId": pane_id,
        "st": status,
        "activityKind": kind,
        "activityPhase": phase,
        "activitySummary": summary,
    });
    if let Err(error) = transport::notify(payload) {
        die(&format!("cockpit activity: {error}"), 3);
    }
    std::process::exit(0)
}
