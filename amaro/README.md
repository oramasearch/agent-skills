# amaro

Teaches an AI agent to drive a running **Amaro** instance from the shell via the `amaro` headless CLI — inspect and run data apps, manage connectors, drive the live desktop UI, stream telemetry, and control lifecycle. A router skill: the agent leans on `amaro <command> --help` for live flags and on per-namespace reference files for depth.

## Install

```sh
npx skills add oramasearch/agent-skills --skill amaro
```

Installs the skill into your agent. The interactive picker uses **↑/↓** to move, **Space** to toggle an agent (Claude Code, Cursor, …), **Enter** to confirm. Non-interactive: add `--agent claude -y` (or `--all` for every skill + agent). Needs Node ≥ 18.

New here? **[GETTING-STARTED.md](GETTING-STARTED.md)** — a no-fluff command guide: prereqs → skill → desktop → verify.

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
| `GETTING-STARTED.md` | No-fluff command guide — prereqs → skill → desktop → verify. |
| `SKILL.md` | Router — transports, bootstrap (manifest + CLI + raw MCP), output contract, namespace table, common workflows, maturity notes. |
| `references/auth.md` | Login, token precedence, scoped-token minting (`read`/`write`/`ui`/`destructive`/`observe`/`full`). |
| `references/app.md` | Data apps — list / get / create / run+watch / status / pin / delete / export. |
| `references/connector.md` | Data sources — add (postgres / snowflake / mcp-stdio), test, reprofile, delete, with `ConnectionConfig` shapes. |
| `references/cache.md` | Routing-tier badge + saved-time signal (stats / routing / savings / tier). |
| `references/chat.md` | Sessions — list / history / send / new / replay. |
| `references/local.md` | Drive the running desktop — state / screenshot / navigate / store-dump / devtools. |
| `references/telemetry.md` | Tail envelopes, cost meter, Performance Interpreter, portable snapshot. |
| `references/lifecycle.md` | Process control — restart / quit / reset / feature-flag (destructive; `--yes` + `destructive` scope). |

## FAQ

**What does the skill use?** The `amaro` CLI (a headless Rust binary). For the no-CLI path, `curl` + `jq` against the desktop's HTTP-MCP endpoint. It talks to a running Amaro desktop (manifest / IPC / local-MCP) or a cloud teams service (REST).

**What do I need to *use* it?** Either the `amaro` binary on `PATH`, or `curl` + `jq` to hit the manifest's MCP URL — plus a running Amaro desktop and/or teams-service credentials. The skill itself is just docs, no runtime deps.

**What gets installed, and where?** Only the skill's docs — `SKILL.md`, `README.md`, `references/*.md`. Project-level into `.claude/skills/amaro/` (and any other agents you pick); user-level into `~/.claude/skills/amaro/` with `-g`. Tracked in `skills-lock.json`. No binary, no build, no Rust toolchain.

**Prereqs to *install* the skill?** Node ≥ 18 and `npx`. Nothing else.

**What commands does it run?** Stats the desktop manifest, then `amaro status|app|connector|chat|local|telemetry|lifecycle …`; optionally `curl` to the MCP endpoint. Passes `--json` when acting on output.

**What permissions are needed?** The agent must be allowed to run shell commands and read the manifest file. Auth is a bearer token via `amaro auth login` or `$AMARO_TOKEN`. Destructive ops (`delete` / `reset` / `lifecycle quit`) require `--yes` plus the `destructive` token scope.

**Already have it installed?** Re-running `add` updates it; or `npx skills update amaro`. Remove with `npx skills remove amaro`.

> Several surfaces are documented-but-partial — see the "Maturity notes" in `SKILL.md`.
