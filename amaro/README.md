# amaro

Teaches an AI agent to drive a running **Amaro** instance from the shell via the `amaro` headless CLI — inspect and run data apps, manage connectors, drive the live desktop UI, stream telemetry, and control lifecycle. A router skill: the agent leans on `amaro <command> --help` for live flags and on per-namespace reference files for depth.

## Install

```sh
npx skills add oramasearch/agent-skills --skill amaro
```

## What it does

`amaro` is a headless Rust binary that drives Amaro over three transports — cloud REST (the teams service), local MCP (the desktop's inbound server), and Tauri-IPC (a running desktop's UDS) — auto-selecting one based on whether the desktop is running. This skill gives an agent the operating surface:

- **Bootstrap** — detect a running desktop via its manifest, locate the `amaro` binary on `PATH`, or skip the CLI and hit the HTTP MCP endpoint directly with the manifest's URL + token.
- **The locked output contract** — `--json` / `--quiet` / `--no-color`, the versioned `{"v": 1, "data" | "error"}` envelope, and NDJSON streaming subcommands.
- **Eight namespaces** — `auth`, `app`, `connector`, `cache`, `chat`, `local`, `telemetry`, `lifecycle`, each with its own reference file.
- **Transport-aware guidance** — when an op is desktop-local (`LocalOnly`), when it needs the `destructive` scope, and when to pick `--transport rest|ipc|mcp` explicitly.

## When it triggers

Mentions of the `amaro` CLI, "amaro app", "drive amaro", "amaro headless", "amaro mcp", or "list data apps" — and tasks that inspect/run data apps, manage connectors, drive the live desktop UI from a script, or stream telemetry.

## Bundled files

| File | Purpose |
|------|---------|
| `SKILL.md` | Router — transports, bootstrap (manifest + CLI + raw MCP), output contract, namespace table, common workflows, maturity notes. |
| `references/auth.md` | Login, token precedence, scoped-token minting (`read`/`write`/`ui`/`destructive`/`observe`/`full`). |
| `references/app.md` | Data apps — list / get / create / run+watch / status / pin / delete / export. |
| `references/connector.md` | Data sources — add (postgres / snowflake / mcp-stdio), test, reprofile, delete, with `ConnectionConfig` shapes. |
| `references/cache.md` | Routing-tier badge + saved-time signal (stats / routing / savings / tier). |
| `references/chat.md` | Sessions — list / history / send / new / replay. |
| `references/local.md` | Drive the running desktop — state / screenshot / navigate / store-dump / devtools. |
| `references/telemetry.md` | Tail envelopes, cost meter, Performance Interpreter, portable snapshot. |
| `references/lifecycle.md` | Process control — restart / quit / reset / feature-flag (destructive; `--yes` + `destructive` scope). |

## Requirements

A running Amaro desktop and/or a reachable teams service, plus the `amaro` binary on the host (or the ability to call the desktop's HTTP MCP endpoint directly using the manifest's URL + token). The skill itself is documentation and assumes the agent can shell out. Several surfaces are documented-but-partial — see the "Maturity notes" in `SKILL.md`.
