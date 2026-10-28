//! Normalize confirmed VCS results before sending the existing Office contract.
//! Provider payloads stay in this process; only fixed labels and opaque IDs travel.

use std::collections::hash_map::DefaultHasher;
use std::hash::{Hash, Hasher};
use std::io::Read;

use serde_json::{json, Value};

use crate::{transport, util::{die, self_tab_id}};

pub const MAX_RESULT: usize = 256 * 1024;
const HELP: &str = "orkest activity vcs --operation <pr.create|pr.merge|push|pull|merge|commit|fetch|release|ci> --exit-code <n> --stdin [--id <id>] [--tab-id <id>]
  Normalize a completed command/API/MCP result from stdin for the Office.
  Supply the operation actually executed, never a read/list/view request.
  GitHub and Azure PR/CI JSON, MCP text/structuredContent envelopes and CLI
  confirmations are supported. Queued merges and failed requests do not celebrate.
  Only a fixed label and opaque event ID are sent; raw results are not forwarded.";

#[derive(Clone, Copy, Debug, PartialEq)]
pub enum Operation { PrCreate, PrMerge, Push, Pull, Merge, Commit, Fetch, Release, Ci }

impl Operation {
    fn parse(value: &str) -> Option<Self> {
        Some(match value {
            "pr.create" => Self::PrCreate, "pr.merge" => Self::PrMerge,
            "push" => Self::Push, "pull" => Self::Pull, "merge" => Self::Merge,
            "commit" => Self::Commit, "fetch" => Self::Fetch,
            "release" => Self::Release, "ci" => Self::Ci, _ => return None,
        })
    }
}

pub struct Event { pub kind: &'static str, pub summary: String, pub id: String }

impl Event {
    pub fn payload(&self, tab: &str) -> Value {
        json!({"paneId": tab, "st": "activity", "activityKind": self.kind,
            "activityPhase": "completed", "activitySummary": self.summary, "activityId": self.id})
    }
}

fn event(kind: &'static str, summary: &str, identity: &str) -> Event {
    let mut hash = DefaultHasher::new();
    identity.hash(&mut hash);
    Event { kind, summary: summary.to_string(), id: format!("vcs:{kind}:{:016x}", hash.finish()) }
}

fn text<'a>(v: &'a Value, key: &str) -> &'a str { v.get(key).and_then(Value::as_str).unwrap_or("") }
fn positive_id(v: &Value) -> bool { v.as_u64().is_some_and(|id| id > 0) }

// Accept standard MCP and API transport envelopes, but never an error envelope.
fn unwrap_result(mut v: Value) -> Option<Value> {
    for _ in 0..5 {
        if v.get("isError") == Some(&Value::Bool(true)) ||
            v.get("ok") == Some(&Value::Bool(false)) ||
            v.get("success") == Some(&Value::Bool(false)) ||
            v.get("error").is_some_and(|e| !e.is_null()) ||
            v.get("errors").and_then(Value::as_array).is_some_and(|e| !e.is_empty()) { return None; }
        if let Some(next) = v.get("structuredContent").or_else(|| v.get("data")).cloned() {
            v = next; continue;
        }
        if let Some(next) = v.pointer("/createPullRequest/pullRequest")
            .or_else(|| v.pointer("/mergePullRequest/pullRequest")).cloned() {
            v = next; continue;
        }
        if let Some(content) = v.get("content").and_then(Value::as_array) {
            if content.len() != 1 { return None; }
            let raw = text(&content[0], "text");
            v = serde_json::from_str(raw).ok()?; continue;
        }
        if let Some(next) = v.get("result").filter(|r| r.is_object()).cloned() {
            v = next; continue;
        }
        if let Some(raw) = v.get("result").and_then(Value::as_str) {
            if raw.trim_start().starts_with('{') || raw.trim_start().starts_with('[') {
                v = serde_json::from_str(raw).ok()?; continue;
            }
        }
        return Some(v);
    }
    None
}

fn identity(v: &Value, fallback: &str) -> String {
    for field in ["html_url", "web_url", "url"] {
        if !text(v, field).is_empty() { return text(v, field).to_string(); }
    }
    // Azure build/PR identifiers are scoped to their repository/project.
    format!("{}:{}:{}:{}:{}:{}", v.pointer("/repository/id").unwrap_or(&Value::Null),
        v.pointer("/project/id").unwrap_or(&Value::Null),
        v.get("pullRequestId").unwrap_or(&Value::Null), v.get("id").or_else(|| v.get("databaseId")).unwrap_or(&Value::Null), v.get("sha").unwrap_or(&Value::Null), fallback)
}

fn plain(raw: &str) -> String {
    let mut out = String::new();
    let mut chars = raw.chars().peekable();
    while let Some(c) = chars.next() {
        if c == '\x1b' {
            match chars.next() {
                Some('[') => { for c in chars.by_ref() { if ('@'..='~').contains(&c) { break; } } }
                Some(']') => {
                    while let Some(c) = chars.next() {
                        if c == '\x07' || (c == '\x1b' && chars.next_if_eq(&'\\').is_some()) { break; }
                    }
                }
                _ => {}
            }
        } else if !c.is_control() || c == '\n' || c == '\t' { out.push(c); }
    }
    out
}

fn pr_url(line: &str) -> bool {
    let url = line.trim();
    if !url.starts_with("https://") || url.chars().any(char::is_whitespace) { return false; }
    let parts: Vec<_> = url.split('/').collect();
    parts.windows(2).any(|p| (p[0] == "pull" || p[0].eq_ignore_ascii_case("pullrequest")) &&
        p[1].split(['?', '#']).next().unwrap_or("").parse::<u64>().is_ok_and(|n| n > 0))
}

pub fn normalize(op: Operation, code: i32, stdout: &str, stderr: &str) -> Option<Event> {
    if stdout.len() + stderr.len() > MAX_RESULT { return None; }
    if code != 0 && !(op == Operation::Ci && code == 1) { return None; }
    let out = plain(stdout);
    let err = plain(stderr);
    let stdout = out.as_str();
    let stderr = err.as_str();
    let raw = stdout.trim();
    let parsed = serde_json::from_str::<Value>(raw).ok();
    let value = match parsed { Some(v) => Some(unwrap_result(v)?), None => None };
    if let Some(v) = &value {
        let id = identity(v, "");
        if op == Operation::Ci {
            if let Some(checks) = v.as_array() {
                if checks.is_empty() || checks.iter().any(|check| !["pass", "fail", "cancel", "skipping"].contains(&text(check, "bucket"))) { return None; }
                if checks.iter().any(|check| text(check, "bucket") == "fail") {
                    return Some(event("ci_failed", "CI falhou", raw));
                }
                if code == 0 && checks.iter().all(|check| ["pass", "skipping"].contains(&text(check, "bucket"))) {
                    return Some(event("ci_passed", "CI passou", raw));
                }
                return None;
            }
        }
        match op {
            Operation::PrCreate => {
                let github = positive_id(&v["number"]) && text(v, "state").eq_ignore_ascii_case("open") &&
                    (pr_url(text(v, "html_url")) || pr_url(text(v, "web_url")) || pr_url(text(v, "url")));
                let azure = positive_id(&v["pullRequestId"]) && text(v, "status") == "active";
                if github || azure { return Some(event("pr_opened", "Pull request criado", &id)); }
            }
            Operation::PrMerge => {
                let github = (v["merged"] == true && !text(v, "sha").is_empty()) || (positive_id(&v["number"]) &&
                    v.get("merged_at").or_else(|| v.get("mergedAt")).is_some_and(|d| d.as_str().is_some_and(|s| !s.is_empty())));
                let azure = positive_id(&v["pullRequestId"]) && text(v, "status") == "completed" &&
                    text(v, "mergeStatus") == "succeeded";
                if github || azure { return Some(event("pr_merged", "Pull request mergeado", &id)); }
            }
            Operation::Ci if text(v, "status") == "completed" => {
                let outcome = v.get("conclusion").or_else(|| v.get("result")).and_then(Value::as_str).unwrap_or("");
                return match outcome {
                    "success" | "succeeded" if code == 0 => Some(event("ci_passed", "CI passou", &id)),
                    "failure" | "failed" | "timed_out" => Some(event("ci_failed", "CI falhou", &id)),
                    _ => None,
                };
            }
            Operation::Release if positive_id(&v["id"]) && v["draft"] == false &&
                v.get("published_at").is_some_and(|d| d.as_str().is_some_and(|s| !s.is_empty())) => {
                return Some(event("release", "Release publicada", &id));
            }
            _ => {}
        }
        // A JSON response without the expected proof is not a textual success.
        if matches!(op, Operation::PrCreate | Operation::PrMerge | Operation::Ci | Operation::Release) { return None; }
    }
    let output = format!("{stdout}\n{stderr}");
    match op {
        Operation::PrCreate => output.lines().find(|line| pr_url(line))
            .map(|url| event("pr_opened", "Pull request criado", url.trim())),
        Operation::PrMerge => output.lines().find(|line| {
            let line = line.trim();
            line.starts_with('✓') && line.to_lowercase().contains("merged pull request ") && line.contains('#')
        }).map(|line| event("pr_merged", "Pull request mergeado", line.trim())),
        Operation::Push if !output.to_lowercase().contains("everything up-to-date") && !output.to_lowercase().contains("everything up to date") =>
            Some(event("push", "Push concluído", &output)),
        Operation::Pull => Some(event("git", "Git pull concluído", &output)),
        Operation::Fetch => Some(event("git", "Git fetch concluído", &output)),
        Operation::Commit => Some(event("git", "Commit criado", &output)),
        Operation::Merge if !output.to_lowercase().contains("already up to date") => Some(event("git", "Merge local concluído", &output)),
        Operation::Release => output.lines().find(|l| l.starts_with("https://") && l.contains("/releases/tag/"))
            .map(|url| event("release", "Release publicada", url.trim())),
        Operation::Ci if output.lines().any(|l| l.trim() == "Some checks were not successful") => Some(event("ci_failed", "CI falhou", &output)),
        Operation::Ci if code == 0 && output.lines().any(|l| l.trim() == "All checks were successful") => Some(event("ci_passed", "CI passou", &output)),
        _ => None,
    }
}

// Classify argv, not prose or shell scripts. Unknown commands are left alone.
pub fn command_operation(argv: &[String]) -> Option<Operation> {
    if argv.iter().any(|arg| [";", "&&", "||", "|", "&"].contains(&arg.as_str()) || arg.contains('\n')) { return None; }
    let executable = argv.first()?.rsplit(['/', '\\']).next()?.trim_end_matches(".exe");
    let mut args = &argv[1..];
    while let Some(flag) = args.first() {
        if ["-C", "-c", "--git-dir", "--work-tree", "-R", "--repo", "--hostname"].contains(&flag.as_str()) {
            args = args.get(2..)?;
        } else if flag.starts_with("--git-dir=") || flag.starts_with("--work-tree=") || flag.starts_with("--repo=") {
            args = &args[1..];
        } else { break; }
    }
    let words: Vec<_> = args.iter().map(String::as_str).collect();
    match (executable, words.as_slice()) {
        ("git", ["push", ..]) if !words.contains(&"--dry-run") && !words.contains(&"-n") => Some(Operation::Push),
        ("git", ["pull", ..]) if !words.contains(&"--dry-run") => Some(Operation::Pull),
        ("git", ["fetch", ..]) if !words.contains(&"--dry-run") => Some(Operation::Fetch),
        ("git", ["commit", ..]) if !words.contains(&"--dry-run") => Some(Operation::Commit),
        ("git", ["merge", ..]) if !words.iter().any(|w| ["--abort", "--quit", "--no-commit", "--squash"].contains(w)) => Some(Operation::Merge),
        ("gh", ["pr", "create", ..]) if !words.contains(&"--dry-run") && !words.contains(&"--web") => Some(Operation::PrCreate),
        ("gh", ["pr", "merge", ..]) => Some(Operation::PrMerge),
        ("gh", ["release", "create", ..]) if !words.iter().any(|w| w.starts_with("--draft")) => Some(Operation::Release),
        ("gh", ["run", "view", ..] | ["pr", "checks", ..]) => Some(Operation::Ci),
        ("az", ["repos", "pr", "create", ..]) => Some(Operation::PrCreate),
        ("az", ["repos", "pr", "update", ..]) => Some(Operation::PrMerge),
        ("az", ["pipelines", "runs", "show", ..]) => Some(Operation::Ci),
        ("gh", ["api", ..]) => api_operation(&args[1..], "gh"),
        ("az", ["rest", ..]) => api_operation(&args[1..], "az"),
        ("curl", _) => api_operation(args, "curl"),
        _ => None,
    }
}

fn api_operation(args: &[String], tool: &str) -> Option<Operation> {
    let gh = tool == "gh";
    let mut method = "GET".to_string();
    let mut explicit_method = false;
    let mut endpoint = None;
    let mut i = 0;
    while i < args.len() {
        let arg = args[i].as_str();
        match arg {
            "-X" | "--method" | "--request" => {
                i += 1; method = args.get(i)?.to_uppercase(); explicit_method = true;
            }
            "-m" if tool == "az" => { i += 1; method = args.get(i)?.to_uppercase(); explicit_method = true; }
            "-m" if tool == "curl" => { i += 1; args.get(i)?; }
            "-G" | "--get" if tool == "curl" => { method = "GET".to_string(); explicit_method = true; }
            "--url" => { i += 1; endpoint = Some(args.get(i)?.as_str()); }
            "-f" | "-F" | "--field" | "--raw-field" if gh => {
                i += 1; args.get(i)?;
                if !explicit_method { method = "POST".to_string(); }
            }
            "--data" | "--data-binary" | "-d" => {
                i += 1; args.get(i)?;
                if !explicit_method { method = "POST".to_string(); }
            }
            "-H" | "--header" | "--headers" | "--input" | "--body" | "--jq" | "-q" | "--template" | "--output" | "-o" | "-u" | "--user" | "--max-time" => { i += 1; args.get(i)?; }
            _ if arg.starts_with('-') => {}
            _ => { if endpoint.is_none() { endpoint = Some(arg); } }
        }
        i += 1;
    }
    let path = endpoint?.split('?').next()?.trim_end_matches('/').to_lowercase();
    match method.as_str() {
        "POST" if path.ends_with("/pulls") || path.ends_with("/pullrequests") => Some(Operation::PrCreate),
        "PUT" if path.contains("/pulls/") && path.ends_with("/merge") => Some(Operation::PrMerge),
        "PATCH" if path.contains("/pullrequests/") => Some(Operation::PrMerge),
        "GET" if path.contains("/actions/runs/") || path.contains("/_apis/build/builds/") => Some(Operation::Ci),
        _ => None,
    }
}

pub fn observe_command(argv: &[String], code: i32, stdout: &str, stderr: &str, tab: Option<&str>) {
    let Some(tab) = tab.filter(|s| !s.is_empty()) else { return };
    let Some(op) = command_operation(argv) else { return };
    if let Some(event) = normalize(op, code, stdout, stderr) {
        // Reporting is best effort and never changes the child's exit code.
        if let Err(e) = transport::notify(event.payload(tab)) { eprintln!("orkest: VCS event not delivered: {e}"); }
    }
}

pub fn report(args: &[String]) -> ! {
    if args.iter().any(|a| a == "--help" || a == "-h") { println!("{HELP}"); std::process::exit(0); }
    let mut op = None;
    let mut code = None;
    let mut tab = None;
    let mut id = None;
    let mut stdin = false;
    let mut i = 0;
    while i < args.len() {
        let key = args[i].as_str();
        if key == "--stdin" { stdin = true; i += 1; continue; }
        i += 1;
        let value = args.get(i).unwrap_or_else(|| die(HELP, 2));
        match key {
            "--operation" => op = Operation::parse(value),
            "--exit-code" => code = value.parse::<i32>().ok(),
            "--tab-id" => tab = Some(value.clone()),
            "--id" if !value.is_empty() && value.len() <= 160 && value.bytes().all(|b| b.is_ascii_alphanumeric() || b"_.:/-".contains(&b)) => id = Some(value.clone()),
            _ => die(HELP, 2),
        }
        i += 1;
    }
    let op = op.unwrap_or_else(|| die(HELP, 2));
    let code = code.unwrap_or_else(|| die(HELP, 2));
    if !stdin { die(HELP, 2); }
    let tab = tab.filter(|s| !s.is_empty()).or_else(self_tab_id)
        .unwrap_or_else(|| die("orkest activity vcs: no target tab", 3));
    let mut raw = String::new();
    if std::io::stdin().take((MAX_RESULT + 1) as u64).read_to_string(&mut raw).is_err() || raw.len() > MAX_RESULT { die("orkest activity vcs: invalid or oversized result", 2); }
    if let Some(mut event) = normalize(op, code, &raw, "") {
        if let Some(id) = id { event.id = id; }
        if let Err(e) = transport::notify(event.payload(&tab)) { die(&format!("orkest activity vcs: {e}"), 3); }
    }
    std::process::exit(0)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn operation(command: &[&str]) -> Option<Operation> {
        command_operation(&command.iter().map(|s| s.to_string()).collect::<Vec<_>>())
    }

    #[test]
    fn commands_have_explicit_mutation_context_and_portable_paths() {
        for (args, op) in [
            (vec!["git", "-C", "/repo", "push"], Operation::Push),
            (vec![r"C:\Git\git.exe", "pull"], Operation::Pull),
            (vec!["/usr/bin/gh", "-R", "org/repo", "pr", "create", "--fill"], Operation::PrCreate),
            (vec!["az", "repos", "pr", "update", "--id", "42", "--status", "completed"], Operation::PrMerge),
            (vec!["gh", "api", "repos/org/repo/pulls/42/merge", "-X", "PUT"], Operation::PrMerge),
            (vec!["gh", "api", "repos/org/repo/pulls", "-f", "title=Title"], Operation::PrCreate),
            (vec!["az", "rest", "--method", "PATCH", "--url", "https://dev.azure.com/o/p/_apis/git/repositories/r/pullrequests/42?api-version=7.1"], Operation::PrMerge),
            (vec!["curl", "-X", "POST", "-H", "Authorization: secret", "https://git.example/api/repos/o/r/pulls"], Operation::PrCreate),
        ] { assert_eq!(operation(&args), Some(op), "{args:?}"); }
    }

    #[test]
    fn reads_dry_runs_and_shell_scripts_are_not_creation_events() {
        for args in [
            vec!["git", "push", "--dry-run"], vec!["gh", "pr", "view", "42"],
            vec!["gh", "api", "repos/o/r/pulls/42"], vec!["az", "repos", "pr", "list"],
            vec!["git", "merge", "--abort"], vec!["sh", "-c", "gh pr create"],
            vec!["git", "push", ";", "true"], vec!["gh", "pr", "create", "--web"],
            vec!["gh", "release", "create", "v1", "--draft=true"],
        ] { assert_eq!(operation(&args), None, "{args:?}"); }
    }

    #[test]
    fn github_and_azure_create_normalize_to_the_same_contract() {
        for raw in [
            r#"{"number":42,"state":"open","html_url":"https://github.com/o/r/pull/42","body":"secret"}"#,
            r#"{"pullRequestId":42,"status":"active","repository":{"id":"repo"},"title":"secret"}"#,
            "https://github.com/o/r/pull/42\n",
            "https://dev.azure.com/o/p/_git/r/pullrequest/42\n",
        ] {
            let result = normalize(Operation::PrCreate, 0, raw, "").unwrap();
            assert_eq!(result.kind, "pr_opened");
            let payload = result.payload("t1").to_string();
            assert!(!payload.contains("secret"));
            assert!(!payload.contains("github.com"));
            assert!(!payload.contains("dev.azure.com"));
        }
    }

    #[test]
    fn actual_merge_is_required_not_auto_merge_or_an_http_error() {
        for raw in [
            r#"{"merged":true,"sha":"abc123"}"#,
            r#"{"number":42,"merged_at":"2026-10-28T10:00:00Z","html_url":"https://github.com/o/r/pull/42"}"#,
            r#"{"pullRequestId":42,"status":"completed","mergeStatus":"succeeded"}"#,
            "\x1b[32m✓ Merged pull request o/r#42 (Title)\x1b[0m",
        ] { assert_eq!(normalize(Operation::PrMerge, 0, raw, "").unwrap().kind, "pr_merged"); }
        for raw in [
            r#"{"merged":false,"message":"Not mergeable"}"#,
            r#"{"pullRequestId":42,"status":"active","autoCompleteSetBy":{"id":"u"}}"#,
            r#"{"pullRequestId":42,"status":"completed","mergeStatus":"conflicts"}"#,
            "✓ Pull request o/r#42 will be automatically merged when ready",
        ] { assert!(normalize(Operation::PrMerge, 0, raw, "").is_none()); }
        assert!(normalize(Operation::PrMerge, 1, r#"{"merged":true,"sha":"abc"}"#, "").is_none());
    }

    #[test]
    fn mcp_and_graphql_envelopes_work_but_error_envelopes_never_celebrate() {
        let pr = json!({"number":42,"state":"OPEN","url":"https://git.example/o/r/pull/42"});
        for envelope in [
            json!({"structuredContent": pr}),
            json!({"content":[{"type":"text","text":pr.to_string()}]}),
            json!({"structuredContent":{"result":pr.to_string()}}),
            json!({"data":{"createPullRequest":{"pullRequest":pr}}}),
        ] { assert_eq!(normalize(Operation::PrCreate, 0, &envelope.to_string(), "").unwrap().kind, "pr_opened"); }
        for envelope in [
            json!({"isError":true,"structuredContent":pr}),
            json!({"ok":false,"data":pr}),
            json!({"errors":[{"message":"failed"}],"data":pr}),
        ] { assert!(normalize(Operation::PrCreate, 0, &envelope.to_string(), "").is_none()); }
    }

    #[test]
    fn ci_requires_a_terminal_result_instead_of_a_process_failure() {
        for (raw, expected) in [
            (r#"{"id":1,"status":"completed","conclusion":"failure"}"#, "ci_failed"),
            (r#"{"id":1,"status":"completed","result":"succeeded"}"#, "ci_passed"),
        ] { assert_eq!(normalize(Operation::Ci, 0, raw, "").unwrap().kind, expected); }
        assert!(normalize(Operation::Ci, 0, r#"{"status":"in_progress","conclusion":null}"#, "").is_none());
        assert!(normalize(Operation::Ci, 1, "", "authentication failed").is_none());
        assert!(normalize(Operation::Ci, 1, r#"{"status":"completed","result":"succeeded"}"#, "").is_none());
        assert_eq!(normalize(Operation::Ci, 1, r#"[{"bucket":"fail","link":"https://github.com/o/r/actions/runs/1"}]"#, "").unwrap().kind, "ci_failed");
        assert!(normalize(Operation::Ci, 8, r#"[{"bucket":"pending"}]"#, "").is_none());
        assert_eq!(normalize(Operation::Ci, 0, r#"[{"bucket":"pass"}]"#, "").unwrap().kind, "ci_passed");
    }

    #[test]
    fn ordinary_git_success_is_activity_and_does_not_imply_a_pr_merge() {
        for (op, kind) in [(Operation::Pull,"git"),(Operation::Merge,"git"),(Operation::Push,"push")] {
            assert_eq!(normalize(op, 0, "Fast-forward\n", "").unwrap().kind, kind);
            assert!(normalize(op, 1, "", "rejected").is_none());
        }
        assert!(normalize(Operation::Push, 0, "Everything up-to-date", "").is_none());
    }

    #[test]
    fn identifiers_are_stable_distinguish_repositories_and_bound_input() {
        let make = |repo| json!({"pullRequestId":1,"status":"active","repository":{"id":repo}}).to_string();
        let one = normalize(Operation::PrCreate,0,&make("one"),"").unwrap();
        let again = normalize(Operation::PrCreate,0,&make("one"),"").unwrap();
        let other = normalize(Operation::PrCreate,0,&make("two"),"").unwrap();
        assert_eq!(one.id, again.id);
        assert_ne!(one.id, other.id);
        assert!(normalize(Operation::PrCreate,0,&"x".repeat(MAX_RESULT+1),"").is_none());
    }

    #[test]
    fn explicit_get_with_fields_does_not_become_a_mutation() {
        for args in [
            vec!["gh", "api", "repos/o/r/pulls", "-X", "GET", "-f", "state=open"],
            vec!["curl", "--get", "-d", "state=open", "https://github.example/repos/o/r/pulls"],
        ] { assert_eq!(operation(&args), None); }
        assert_eq!(operation(&["curl", "--request", "PUT", "https://api.github.com/repos/o/r/pulls/1/merge"]), Some(Operation::PrMerge));
    }
}
