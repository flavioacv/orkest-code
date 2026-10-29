//! Real CLI/socket tests: normalization must keep the originating tab and output.
#![cfg(unix)]

use std::io::{BufRead, BufReader, Write};
use std::os::unix::{fs::PermissionsExt, net::UnixListener};
use std::process::{Command, Stdio};
use std::sync::atomic::{AtomicU64, Ordering};
use std::time::{Duration, Instant};
use serde_json::{json, Value};

fn directory() -> std::path::PathBuf {
    static SEQ: AtomicU64 = AtomicU64::new(0);
    let dir = std::env::temp_dir().join(format!("orkest-vcs-{}-{}", std::process::id(), SEQ.fetch_add(1, Ordering::Relaxed)));
    std::fs::create_dir_all(&dir).unwrap();
    dir
}

fn request(listener: &UnixListener, response: Option<Value>) -> Value {
    listener.set_nonblocking(true).unwrap();
    let deadline = Instant::now() + Duration::from_secs(5);
    let mut stream = loop {
        match listener.accept() {
            Ok((stream, _)) => break stream,
            Err(e) if e.kind() == std::io::ErrorKind::WouldBlock && Instant::now() < deadline => std::thread::sleep(Duration::from_millis(10)),
            Err(e) => panic!("expected CLI request: {e}"),
        }
    };
    stream.set_nonblocking(false).unwrap();
    let mut line = String::new();
    BufReader::new(&mut stream).read_line(&mut line).unwrap();
    if let Some(response) = response { writeln!(stream, "{response}").unwrap(); }
    serde_json::from_str(&line).unwrap()
}

fn cli(socket: &std::path::Path) -> Command {
    let mut cmd = Command::new(env!("CARGO_BIN_EXE_orkest"));
    cmd.env("ORKEST_STATUS_SOCK", socket).env("ORKEST_TAB_ID", "parent")
        .env_remove("ORKEST_STATUS_PORT").env_remove("ORKEST_STATUS_TOKEN");
    cmd
}

#[test]
fn mcp_azure_result_sends_only_normalized_fields_to_the_requested_tab() {
    let dir = directory();
    let socket = dir.join("status.sock");
    let listener = UnixListener::bind(&socket).unwrap();
    let server = std::thread::spawn(move || request(&listener, None));
    let mut child = cli(&socket).args(["activity", "vcs", "--operation", "pr.create", "--exit-code", "0", "--stdin", "--id", "repo:pr7", "--tab-id", "azure-tab"])
        .stdin(Stdio::piped()).stdout(Stdio::piped()).stderr(Stdio::piped()).spawn().unwrap();
    child.stdin.take().unwrap().write_all(br#"{"structuredContent":{"pullRequestId":7,"status":"active","repository":{"id":"repo"},"title":"private-title","token":"private-token"}}"#).unwrap();
    let out = child.wait_with_output().unwrap();
    assert!(out.status.success(), "{}", String::from_utf8_lossy(&out.stderr));
    let req = server.join().unwrap();
    assert_eq!(req["paneId"], "azure-tab");
    assert_eq!(req["st"], "activity");
    assert_eq!(req["activityKind"], "pr_opened");
    assert_eq!(req["activityPhase"], "completed");
    assert_eq!(req["activityId"], "repo:pr7");
    assert!(!req.to_string().contains("private-"));
    assert!(out.stdout.is_empty());
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn exec_normalizes_github_api_success_without_changing_the_response() {
    let dir = directory();
    let socket = dir.join("status.sock");
    let listener = UnixListener::bind(&socket).unwrap();
    let server = std::thread::spawn(move || {
        let execution = request(&listener, Some(json!({"ok":true,"data":{"code":0,"stdout":"{\"merged\":true,\"sha\":\"abc123\"}","stderr":"","timedOut":false}})));
        let event = request(&listener, None);
        (execution, event)
    });
    let out = cli(&socket).args(["exec", "--json", "--tab-id", "github-tab", "--", "gh", "api", "repos/o/r/pulls/7/merge", "-X", "PUT"]).output().unwrap();
    assert!(out.status.success(), "{}", String::from_utf8_lossy(&out.stderr));
    let (execution, event) = server.join().unwrap();
    assert_eq!(execution["tabId"], "github-tab");
    assert_eq!(event["paneId"], "github-tab");
    assert_eq!(event["activityKind"], "pr_merged");
    let data: Value = serde_json::from_slice(&out.stdout).unwrap();
    assert_eq!(data["code"], 0);
    assert_eq!(data["stdout"], r#"{"merged":true,"sha":"abc123"}"#);
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn telemetry_observes_git_result_and_preserves_child_output_and_exit() {
    let dir = directory();
    let socket = dir.join("status.sock");
    let listener = UnixListener::bind(&socket).unwrap();
    let git = dir.join("git");
    std::fs::write(&git, "#!/bin/sh\nprintf 'To https://dev.azure.com/o/p/_git/r\\n   abc123..def456 main -> main\\n'\n").unwrap();
    std::fs::set_permissions(&git, std::fs::Permissions::from_mode(0o755)).unwrap();
    let server = std::thread::spawn(move || {
        let open = request(&listener, Some(json!({"ok":true,"data":{"run":"r_vcs","env":{}}})));
        assert_eq!(open["cmd"], "telemetry-open");
        loop {
            let req = request(&listener, Some(json!({"ok":true,"data":{}})));
            if req["cmd"] == "telemetry-close" {
                assert_eq!(req["args"]["exit_code"], 0);
                break;
            }
            assert_eq!(req["cmd"], "telemetry-ingest");
        }
        request(&listener, None)
    });
    let out = cli(&socket).args(["telemetry", "-q", "--", git.to_str().unwrap(), "push"]).stdin(Stdio::null()).output().unwrap();
    assert!(out.status.success(), "{}", String::from_utf8_lossy(&out.stderr));
    assert!(String::from_utf8_lossy(&out.stdout).starts_with("To https://dev.azure.com/"));
    let event = server.join().unwrap();
    assert_eq!(event["activityKind"], "push");
    assert_eq!(event["paneId"], "parent");
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn unsuccessful_or_queued_results_send_no_notification() {
    let dir = directory();
    for raw in [r#"{"isError":true,"content":[]}"#, r#"{"merged":false,"sha":"abc"}"#, r#"{"pullRequestId":7,"status":"active","autoCompleteSetBy":{"id":"u"}}"#] {
        let mut child = cli(&dir.join("no-server.sock"))
            .args(["activity", "vcs", "--operation", "pr.merge", "--exit-code", "0", "--stdin"])
            .stdin(Stdio::piped()).stdout(Stdio::piped()).stderr(Stdio::piped()).spawn().unwrap();
        child.stdin.take().unwrap().write_all(raw.as_bytes()).unwrap();
        let output = child.wait_with_output().unwrap();
        assert_eq!(output.status.code(), Some(4));
        assert!(String::from_utf8_lossy(&output.stderr).contains("no Office event emitted"));
    }
    std::fs::remove_dir_all(dir).unwrap();
}

#[test]
fn exec_preserves_python_arguments_and_explicit_vcs_context() {
    let dir = directory();
    let socket = dir.join("status.sock");
    let listener = UnixListener::bind(&socket).unwrap();
    let server = std::thread::spawn(move || {
        let execution = request(&listener, Some(json!({"ok":true,"data":{"code":0,"stdout":"{\"number\":42,\"state\":\"open\",\"html_url\":\"https://github.com/o/r/pull/42\"}","stderr":"","timedOut":false}})));
        let event = request(&listener, None);
        (execution,event)
    });
    let code = "print('space and quotes')";
    let output = cli(&socket).args(["exec","--vcs-operation","pr.create","--","python3","-c",code]).output().unwrap();
    assert!(output.status.success());
    let (execution,event) = server.join().unwrap();
    assert_eq!(execution["args"]["argv"],json!(["python3","-c",code]));
    assert_eq!(event["activityKind"],"pr_opened");
    std::fs::remove_dir_all(dir).unwrap();
}
