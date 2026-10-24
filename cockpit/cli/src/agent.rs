//! Provider-neutral lifecycle reporting for child agents.

use serde_json::json;

use crate::transport;
use crate::util::{die, self_tab_id};

const HELP: &str = "cockpit agent <start|stop> <agent-id> [--type <role>] [--outcome success|error|interrupted] [--parent-agent-id <parent-agent>] [--tab-id <parent-tab>]
  Report a child-agent lifecycle event to the Office in the current Cockpit tab.
  IDs must be stable across start/stop. No prompt or transcript is sent.";

/// Reports a provider-neutral start/stop event for a subagent.
pub fn agent(args: &[String]) -> ! {
    if args.is_empty() || args[0] == "--help" || args[0] == "-h" {
        println!("{HELP}");
        std::process::exit(if args.is_empty() { 2 } else { 0 });
    }
    let event = match args[0].as_str() {
        "start" => "SubagentStart",
        "stop" | "finish" => "SubagentStop",
        other => die(&format!("cockpit agent: unknown action \"{other}\"\n{HELP}"), 2),
    };

    let mut id: Option<String> = None;
    let mut kind: Option<String> = None;
    let mut outcome: Option<String> = None;
    let mut tab_id: Option<String> = None;
    let mut parent_agent_id: Option<String> = None;
    let mut i = 1;
    while i < args.len() {
        let arg = args[i].as_str();
        match arg {
            "--id" | "--type" | "--outcome" | "--parent-agent-id" | "--tab-id" => {
                if i + 1 >= args.len() {
                    die(&format!("cockpit agent: {arg} requires a value"), 2);
                }
                i += 1;
                match arg {
                    "--id" => id = Some(args[i].clone()),
                    "--type" => kind = Some(args[i].clone()),
                    "--outcome" => outcome = Some(args[i].clone()),
                    "--parent-agent-id" => parent_agent_id = Some(args[i].clone()),
                    _ => tab_id = Some(args[i].clone()),
                }
            }
            _ if arg.starts_with('-') => {
                die(&format!("cockpit agent: unknown option \"{arg}\""), 2)
            }
            _ if id.is_none() => id = Some(arg.to_string()),
            _ => die("cockpit agent: unexpected positional argument", 2),
        }
        i += 1;
    }

    let id = match id {
        Some(value) => safe(value, 120).filter(|value| !value.is_empty()),
        None => None,
    }
    .unwrap_or_else(|| die("cockpit agent: missing or invalid agent-id", 2));
    let pane_id = tab_id
        .filter(|value| !value.trim().is_empty())
        .or_else(self_tab_id)
        .unwrap_or_else(|| {
            die(
                "cockpit agent: no parent tab — run inside a Cockpit terminal or pass --tab-id",
                2,
            )
        });
    let kind = kind.and_then(|value| safe(value, 80)).filter(|value| !value.is_empty());
    let parent_agent_id = parent_agent_id
        .and_then(|value| safe(value, 120))
        .filter(|value| !value.is_empty());
    let outcome = match outcome.as_deref() {
        None if event == "SubagentStop" => Some("success"),
        None => None,
        Some(value @ ("success" | "error" | "interrupted")) => Some(value),
        Some(_) => die("cockpit agent: --outcome must be success, error, or interrupted", 2),
    };
    if outcome.is_some() && event != "SubagentStop" {
        die("cockpit agent: --outcome is only valid with stop", 2);
    }

    let mut payload = json!({
        "paneId": pane_id,
        "st": "subagent",
        "ev": event,
        "sub": id,
    });
    if let Some(kind) = kind {
        payload["subType"] = json!(kind);
    }
    if let Some(parent_agent_id) = parent_agent_id {
        payload["subParent"] = json!(parent_agent_id);
    }
    if let Some(outcome) = outcome {
        payload["subOutcome"] = json!(outcome);
    }
    if let Err(error) = transport::notify(payload) {
        die(&format!("cockpit agent: {error}"), 3);
    }
    std::process::exit(0)
}

fn safe(value: String, max_chars: usize) -> Option<String> {
    let value: String = value
        .chars()
        .filter(|character| !character.is_control())
        .take(max_chars)
        .collect();
    let value = value.trim().to_string();
    if value.is_empty() { None } else { Some(value) }
}
