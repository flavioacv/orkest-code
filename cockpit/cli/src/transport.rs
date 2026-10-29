//! Transporte: uma requisição por conexão, uma linha JSON em cada direção.
//!
//! Mesmo socket do hook, discriminado por `type` no wire (`"cmd"` aqui,
//! status no hook). POSIX usa socket Unix (`ORKEST_STATUS_SOCK`); Windows usa
//! TCP no loopback (`ORKEST_STATUS_PORT` + `ORKEST_STATUS_TOKEN`), porque lá
//! não há UDS. O token só importa no TCP: o loopback é acessível por qualquer
//! processo local, enquanto no UDS a permissão do arquivo já protege.

use std::io::{Read, Write};
use std::time::Duration;

use serde_json::{json, Value};

use crate::util::{die, env_non_empty};

/// Conexão aberta com o app, abstraindo UDS x TCP.
enum Conn {
    #[cfg(unix)]
    Unix(std::os::unix::net::UnixStream),
    Tcp(std::net::TcpStream),
}

impl Conn {
    fn set_read_timeout(&self, dur: Duration) -> std::io::Result<()> {
        match self {
            #[cfg(unix)]
            Conn::Unix(s) => s.set_read_timeout(Some(dur)),
            Conn::Tcp(s) => s.set_read_timeout(Some(dur)),
        }
    }
}

impl Read for Conn {
    fn read(&mut self, buf: &mut [u8]) -> std::io::Result<usize> {
        match self {
            #[cfg(unix)]
            Conn::Unix(s) => s.read(buf),
            Conn::Tcp(s) => s.read(buf),
        }
    }
}

impl Write for Conn {
    fn write(&mut self, buf: &[u8]) -> std::io::Result<usize> {
        match self {
            #[cfg(unix)]
            Conn::Unix(s) => s.write(buf),
            Conn::Tcp(s) => s.write(buf),
        }
    }
    fn flush(&mut self) -> std::io::Result<()> {
        match self {
            #[cfg(unix)]
            Conn::Unix(s) => s.flush(),
            Conn::Tcp(s) => s.flush(),
        }
    }
}

/// Abre a conexão com o app pelo transporte da plataforma. `Ok(None)` = as envs
/// não fornecem um endpoint e nenhum endpoint local foi descoberto.
/// Flavor assado no binário pelo build (ver `build.rs`). `Some("debug")` no
/// build de desenvolvimento.
const FLAVOR: Option<&str> = option_env!("ORKEST_FLAVOR");

/// Sockets a tentar, em ordem: o do ambiente (injetado pelo app na PTY da aba)
/// e, como fallback, os caminhos bem conhecidos.
///
/// O fallback é o que permite usar a CLI **de fora** de um terminal do Orkest
/// (ex.: uma ferramenta de ditado chamando `orkest send --focused`), onde não
/// existe env nenhuma herdada.
///
/// Release e debug têm sockets separados de propósito (um Orkest de dev e um
/// instalado rodam lado a lado), então a ordem importa: **o socket do próprio
/// flavor vem primeiro**. Com os dois apps abertos, a CLI de dev era atendida
/// pelo app instalado, que pode ser bem mais velho — deu "tab @focused does not
/// exist" porque aquele app nem conhecia o sentinela. O outro flavor continua
/// como fallback: melhor falar com o app errado do que não falar com nenhum.
#[cfg(unix)]
fn candidate_sockets() -> Vec<String> {
    let mut out = Vec::new();
    if let Some(path) = env_non_empty("ORKEST_STATUS_SOCK") {
        out.push(path);
    }
    if let Some(home) = crate::util::home_dir() {
        let release = format!("{home}/.orkest/status.sock");
        let debug = format!("{home}/.orkest/status-debug.sock");
        if FLAVOR == Some("debug") {
            out.push(debug);
            out.push(release);
        } else {
            out.push(release);
            out.push(debug);
        }
    }
    out
}

/// Windows: `{port, tok}` que o app grava em `~/.orkest/status[-debug].json`
/// ao subir — o equivalente do caminho bem conhecido do socket Unix, pra CLI
/// rodada de FORA de uma aba (sem env herdada). Mesma ordem de flavor do POSIX.
#[cfg(windows)]
fn endpoint_from_file() -> Option<(u16, Option<String>)> {
    let home = crate::util::home_dir()?;
    let mut names = vec!["status.json", "status-debug.json"];
    if FLAVOR == Some("debug") {
        names.reverse();
    }
    for name in names {
        let path = format!("{home}\\.orkest\\{name}");
        let Ok(raw) = std::fs::read_to_string(&path) else {
            continue;
        };
        let Ok(v) = serde_json::from_str::<Value>(&raw) else {
            continue;
        };
        let Some(port) = v.get("port").and_then(Value::as_u64) else {
            continue;
        };
        let tok = v.get("tok").and_then(Value::as_str).map(str::to_string);
        return Some((port as u16, tok));
    }
    None
}

#[cfg(not(windows))]
fn endpoint_from_file() -> Option<(u16, Option<String>)> {
    None
}

fn connect() -> std::io::Result<Option<Conn>> {
    let mut port = env_non_empty("ORKEST_STATUS_PORT").and_then(|p| p.parse::<u16>().ok());
    if port.is_none() {
        port = endpoint_from_file().map(|(p, _)| p);
    }

    #[cfg(unix)]
    {
        let candidates = candidate_sockets();
        let mut last_err = None;
        let mut permission_error = None;
        for path in &candidates {
            // Socket órfão (app fechado sem limpar) existe no disco mas recusa
            // conexão — por isso quem decide é o connect, não o exists.
            match std::os::unix::net::UnixStream::connect(path) {
                Ok(s) => return Ok(Some(Conn::Unix(s))),
                Err(e) if e.kind() == std::io::ErrorKind::PermissionDenied => {
                    // O primeiro endpoint é o explícito ou o do flavor atual.
                    // Um fallback bloqueado não deve trocar o path que o
                    // usuário precisa autorizar.
                    permission_error.get_or_insert_with(|| {
                        std::io::Error::new(e.kind(), format!("socket {path}: {e}"))
                    });
                }
                Err(e) => last_err = Some(e),
            }
        }
        if port.is_none() {
            return match permission_error.or(last_err) {
                Some(e) => Err(e),
                None => Ok(None),
            };
        }
    }

    if let Some(port) = port {
        return std::net::TcpStream::connect(("127.0.0.1", port))
            .map(|s| Some(Conn::Tcp(s)));
    }
    Ok(None)
}

fn connection_error(error: &std::io::Error) -> String {
    if error.kind() == std::io::ErrorKind::PermissionDenied {
        format!(
            "orkest: local socket access blocked by permissions or sandbox: {error}. \
The app may be running even when ORKEST_* variables are absent. \
Request approval for this same CLI command outside the execution sandbox; \
if the session forbids approvals (never or sandbox_approval=false), \
use its permissions UI or resume Codex with \
`codex resume <session-id> --sandbox workspace-write --ask-for-approval on-request`, \
then approve the CLI command. A socket allowlist must use the socket path above. \
Do not disable sandboxing globally."
        )
    } else {
        format!("orkest: could not connect to app: {error}")
    }
}

/// `true` quando há algum caminho possível até o app (env de socket, porta, ou
/// um socket bem conhecido no disco).
pub fn transport_configured() -> bool {
    if env_non_empty("ORKEST_STATUS_SOCK").is_some()
        || env_non_empty("ORKEST_STATUS_PORT")
            .and_then(|p| p.parse::<u16>().ok())
            .is_some()
    {
        return true;
    }
    #[cfg(unix)]
    {
        candidate_sockets()
            .iter()
            .any(|p| std::path::Path::new(p).exists())
    }
    #[cfg(not(unix))]
    endpoint_from_file().is_some()
}

/// Envia uma requisição e devolve a resposta decodificada.
///
/// Fora de um terminal do Orkest, encerra com exit 3 (mesma mensagem da CLI
/// Dart). Falha de rede também é exit 3; resposta ausente/malformada vira um
/// `{"ok": false, "error": …}` pro chamador tratar como erro de aplicação.
pub fn request(mut req: Value, timeout: Duration) -> Value {
    if req.get("tabId").and_then(Value::as_str) == crate::util::self_tab_id().as_deref() {
        if let Ok(generation) = std::env::var("ORKEST_SESSION_TOKEN") { req["gen"] = json!(generation); }
    }
    if !transport_configured() {
        die(
            "orkest: no Orkest app to talk to (ORKEST_STATUS_SOCK is unset and \
no socket found in ~/.orkest). Is the app running?",
            3,
        );
    }
    req["type"] = json!("cmd");
    if let Ok(tok) = std::env::var("ORKEST_STATUS_TOKEN") {
        req["tok"] = json!(tok);
    } else if let Some((_, Some(tok))) = endpoint_from_file() {
        req["tok"] = json!(tok);
    }

    let mut conn = match connect() {
        Ok(Some(c)) => c,
        Ok(None) => die(
            "orkest: not inside a Orkest terminal (ORKEST_STATUS_SOCK is unset)",
            3,
        ),
        Err(e) => die(&connection_error(&e), 3),
    };
    let _ = conn.set_read_timeout(timeout);

    let mut payload = req.to_string();
    payload.push('\n');
    if let Err(e) = conn
        .write_all(payload.as_bytes())
        .and_then(|_| conn.flush())
    {
        die(&format!("orkest: could not connect to app: {e}"), 3);
    }

    // O servidor responde UMA linha e fecha. Lemos até a primeira quebra (ou
    // até o EOF), o que também nos protege se ele mantiver a conexão aberta.
    let mut buf: Vec<u8> = Vec::with_capacity(4096);
    let mut chunk = [0u8; 4096];
    loop {
        match conn.read(&mut chunk) {
            Ok(0) => break,
            Ok(n) => {
                buf.extend_from_slice(&chunk[..n]);
                if buf.contains(&b'\n') {
                    break;
                }
            }
            Err(_) => break, // timeout ou erro: trata como resposta ausente
        }
    }

    let raw = String::from_utf8_lossy(&buf);
    let line = raw.trim();
    if line.is_empty() {
        return json!({"ok": false, "error": "no response from app"});
    }
    match serde_json::from_str::<Value>(line) {
        Ok(v) if v.is_object() => v,
        Ok(_) => json!({"ok": false, "error": "malformed response"}),
        Err(_) => json!({"ok": false, "error": "malformed response"}),
    }
}

/// Envia um evento de ciclo de vida sem esperar resposta. Ao contrário de
/// [request], não marca o envelope como comando: o socket e o sidecar o
/// encaminham pelo fluxo de status de turno, local ou remoto.
pub fn notify(mut event: Value) -> Result<(), String> {
    if let Ok(generation) = std::env::var("ORKEST_SESSION_TOKEN") {
        // Explicit targeting of another tab must not carry this PTY's token.
        if event.get("paneId").and_then(Value::as_str) == crate::util::self_tab_id().as_deref() {
            event["gen"] = json!(generation);
        }
    }
    if !transport_configured() {
        return Err("no Orkest app to talk to (is the app running?)".to_string());
    }
    if let Ok(tok) = std::env::var("ORKEST_STATUS_TOKEN") {
        event["tok"] = json!(tok);
    } else if let Some((_, Some(tok))) = endpoint_from_file() {
        event["tok"] = json!(tok);
    }
    let mut conn = connect()
        .map_err(|error| connection_error(&error))?
        .ok_or_else(|| "no Orkest status socket".to_string())?;
    let mut payload = event.to_string();
    payload.push('\n');
    conn.write_all(payload.as_bytes())
        .and_then(|_| conn.flush())
        .map_err(|e| format!("could not send event to Orkest: {e}"))
}

/// `resp["ok"] == true`. Emite no **stderr** o aviso que a resposta trouxer.
///
/// Aviso vai pro stderr de propósito: o stdout dos comandos de banco é uma
/// linha JSON que agentes parseiam, e sujá-la quebraria o contrato. Hoje o
/// único caso é `--workspace` mirando outra máquina — a execução está certa,
/// mas o resultado tem cara de ser da máquina onde o comando foi digitado.
pub fn is_ok(resp: &Value) -> bool {
    if let Some(Value::String(w)) = resp.get("warning") {
        eprintln!("orkest: {w}");
    }
    resp.get("ok") == Some(&Value::Bool(true))
}

/// Mensagem de erro da resposta, com o mesmo fallback da CLI Dart.
pub fn error_text(resp: &Value) -> String {
    match resp.get("error") {
        Some(Value::String(s)) => s.clone(),
        Some(other) => other.to_string(),
        None => "failed".to_string(),
    }
}

/// Encerra com o erro da resposta (exit 1) — padrão dos comandos "simples".
pub fn fail_with(resp: &Value) -> ! {
    die(&format!("orkest: {}", error_text(resp)), 1)
}

#[cfg(test)]
mod tests {
    use super::connection_error;
    use std::io::{Error, ErrorKind};

    #[test]
    fn sandbox_denial_requests_scoped_approval_without_claiming_missing_context() {
        let text = connection_error(&Error::from(ErrorKind::PermissionDenied));
        assert!(text.contains("Request approval"));
        assert!(text.contains("ORKEST_* variables are absent"));
        assert!(!text.contains("not inside"));
    }

    #[test]
    fn connection_refusal_is_not_reported_as_sandbox_denial() {
        let text = connection_error(&Error::from(ErrorKind::ConnectionRefused));
        assert!(text.contains("could not connect"));
        assert!(!text.contains("Request approval"));
    }
}
