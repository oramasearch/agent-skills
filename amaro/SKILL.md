---
name: amaro
description: Drive a running Amaro instance from Claude Code using the `amaro` CLI. Use when the user wants to inspect data apps / connectors / cache / chat sessions, run a data app, drive the running desktop UI, or stream telemetry. Triggers on mentions of "amaro CLI", "amaro app", "drive amaro", "amaro headless", "amaro mcp", or "list data apps".
---

# amaro — headless CLI for the running desktop, the cloud teams service, or the local MCP server

`amaro` is the headless Rust binary that lets you drive Amaro from the
shell or from agentic tools (Claude Code, Cursor, scripts). It speaks
three transports — cloud REST against `services/teams`, local MCP
against the desktop's inbound server, and Tauri-IPC against a running
desktop's UDS — and picks one automatically based on whether the
desktop is running.

This skill is a **router**: it points at `amaro <command> --help` and at
the per-namespace skill files. Don't ask me to enumerate every flag —
run `amaro app --help` for the live truth, because flags change faster
than this file does.

## When to load this skill

- The user wants to list / get / create / run / delete a data app.
- The user wants to manage connectors (data sources).
- The user wants to drive the running desktop UI from the shell (take
  a screenshot, navigate to a route, snapshot local state).
- The user wants to inspect cache routing or saved-time signals.
- The user wants to tail telemetry, run the Performance Interpreter,
  or check the cost meter.
- The user wants to control desktop lifecycle (restart, reset, feature
  flags).

## First moves

1. **Is the desktop running?** Stat the manifest — this is the ground
   truth, and it works whether or not the CLI is installed:

   | Platform | Path |
   |---|---|
   | macOS | `~/Library/Application Support/com.amaro.desktop/mcp-server.json` |
   | Linux | `~/.local/share/com.amaro.desktop/mcp-server.json` |
   | Windows | `%APPDATA%\com.amaro.desktop\mcp-server.json` |

   The file carries `url` (HTTP MCP, e.g. `http://127.0.0.1:50030/mcp`),
   `token` (bearer), `pid`, `ipc_socket` (UDS path), and granted
   `scopes`. `ps -p <pid> >/dev/null` confirms the process is alive.
   If the file is missing → desktop isn't running and IPC / local-MCP
   transports are off the table; you're cloud-REST-only.

2. **Is the `amaro` CLI installed?** — `command -v amaro`. If missing,
   you have three zero-friction options:
   - `just cli <args>` from the amaro module runs the CLI from source
     without installing it on `PATH`.
   - `just cli-install` (in the amaro module) builds + installs to
     `~/.cargo/bin/amaro`. Same as
     `cargo install --path crates/amaro-cli`.
   - Skip the CLI entirely and hit the HTTP MCP endpoint directly
     using the URL + token from the manifest (see next section).

3. **Then `amaro status --json`** (or `just cli status --json`) to
   confirm transport + env + auth.
4. **Discover the surface** — `amaro --help`. Then drill in with
   `amaro <namespace> --help`. Don't carry the flag list in context;
   the help output is authoritative.
5. **Pick a transport when it matters** — pass `--transport rest`,
   `--transport ipc`, or `--transport mcp` explicitly. Default is
   `auto` (prefer IPC when manifest exists, fall back to REST).
6. **Pass `--json`** when you're going to act on the result.
   The schema is versioned `{"v": 1, "data": ...}`; errors come back
   as `{"v": 1, "error": {"kind": ..., "message": ..., "chain": [...]}}`
   on stderr.

## Talk to the desktop without the CLI

The manifest gives you everything the CLI uses. To call the MCP server
directly:

```sh
MANIFEST=~/Library/Application\ Support/com.amaro.desktop/mcp-server.json
URL=$(jq -r .url "$MANIFEST")
TOKEN=$(jq -r .token "$MANIFEST")

# 1. initialize — capture the session id from the response header
curl -s -D /tmp/h -X POST "$URL" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{
        "protocolVersion":"2025-06-18","capabilities":{},
        "clientInfo":{"name":"claude-code","version":"1.0"}}}' >/dev/null
SID=$(awk -F': ' 'tolower($1)=="mcp-session-id"{print $2}' /tmp/h | tr -d '\r')

# 2. notifications/initialized (required before any other call)
curl -s -X POST "$URL" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","method":"notifications/initialized"}' >/dev/null

# 3. tools/list, tools/call, etc. — thread the session id back
curl -s -X POST "$URL" -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -H "mcp-session-id: $SID" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/list"}'
```

Same tool surface the CLI uses — just lower-level. Use this when the
CLI isn't installed and you don't want to build it, or when you need
to wire the desktop into another tool that already speaks MCP.

## Namespaces

| Namespace | What lives there | Sub-skill |
|---|---|---|
| `amaro auth` | login / logout / whoami / mint scoped tokens | [auth.md](references/auth.md) |
| `amaro app` | data apps — list / get / run / status / create / delete | [app.md](references/app.md) |
| `amaro connector` | data sources — list / add / test / reprofile / delete | [connector.md](references/connector.md) |
| `amaro cache` | routing-tier badge + saved-time signal | [cache.md](references/cache.md) |
| `amaro chat` | sessions — list / send / replay / history | [chat.md](references/chat.md) |
| `amaro local` | drive the running desktop (screenshot, navigate, snapshot) | [local.md](references/local.md) |
| `amaro telemetry` | tail envelopes, cost meter, interpret a turn, snapshot | [telemetry.md](references/telemetry.md) |
| `amaro lifecycle` | restart / quit / reset / feature flags | [lifecycle.md](references/lifecycle.md) |
| `amaro status` | one-shot — version, env, transport, auth, manifest | (this file) |

## Output contract

Every command supports three global flags:

- `--json` — `{"v": 1, "data": ...}` for success; `{"v": 1, "error":
  {...}}` for error. Errors land on stderr; success on stdout.
- `--quiet` — suppresses progress notes on stderr; success/error
  output unchanged.
- `--no-color` — disables ANSI colors. `--json` enforces this
  automatically; the `NO_COLOR` env var per <https://no-color.org/> is
  respected.

Streaming subcommands (`amaro telemetry tail`, `amaro app run` without
`--detach`) emit NDJSON — one envelope per line.

## Common workflows

### List the data apps and run the most-recent one

```
amaro app list --json | jq -r '.data[0].id' \
    | xargs amaro app run --json
```

### Take a screenshot of the running desktop

```
amaro local screenshot --output ~/Desktop/amaro-now.png --json
```

This works **only** when the desktop is running (the manifest carries
the URL the screenshot tool talks to). Returns a `LocalOnly` error
under `--transport rest`.

### Watch telemetry for a single envelope kind

```
amaro telemetry tail --envelope-kind chat.llm.response --last 20 --json
```

### Interpret why a chat turn was slow

```
amaro telemetry interpret <turn_id> --json
```

Returns the Performance Interpreter's analysis for the given turn.

## When to escalate vs. ask the user

- Destructive ops (`delete`, `reset`, `lifecycle quit`) need `--yes` on
  the CLI side. Confirm intent with the user before running them rather
  than passing `--yes` unprompted.
- Auth errors → tell the user to run `amaro auth login` or set
  `AMARO_TOKEN`.
- `LocalOnly` errors → tell the user the desktop isn't running (or
  hand them `--transport rest` if the cloud route handles it).
- Unfamiliar shapes → call the relevant `--help` and quote it back.

## Maturity notes

Some surfaces are stubbed while the underlying engines land — treat
these as documented-but-partial:

- `amaro cache *` returns descriptive stubs until the cache-engine
  common interface and its engines plumb through the saved-time signal.
- `amaro chat send --detach` is a no-op today (reserved for the
  eventual synchronous mode).
- `amaro auth login` device-code completion is unshipped; the flow
  currently accepts `--token` / `$AMARO_TOKEN`.
- `amaro connector reprofile` is not yet exposed over MCP; it returns a
  clean "use REST" error under `--transport mcp`.
