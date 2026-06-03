# amaro

Teaches an AI agent to drive a running **Amaro** instance from the shell — inspect/run data apps, manage connectors, drive the live desktop UI, stream telemetry, and control lifecycle — via the headless `amaro` CLI (or raw HTTP-MCP); triggers on `amaro` CLI mentions or any of those tasks.

## Install

```sh
npx skills add oramasearch/agent-skills --skill amaro
```

Non-interactive: add `--agent claude -y` (or `--all`). Needs Node ≥ 18. See **[GETTING-STARTED.md](GETTING-STARTED.md)** for the full setup walkthrough.

## FAQ

**What does it use?**
The `amaro` CLI (a headless Rust binary), or `curl` + `jq` against the desktop's HTTP-MCP endpoint. Talks to a running Amaro desktop (manifest / IPC / local-MCP) or a cloud teams service (REST).

**What do I need to use it?**
Either the `amaro` binary on `PATH`, or `curl` + `jq` to hit the manifest's MCP URL — plus a running desktop and/or teams-service credentials. The skill itself is just docs, no runtime deps.

**What's installed, and where?**
Only docs — `SKILL.md`, `README.md`, `references/*.md`. Project-level: `.claude/skills/amaro/`. User-level (`-g`): `~/.claude/skills/amaro/`. Tracked in `skills-lock.json`. No binary, no build, no Rust toolchain.

**Prereqs to install?**
Node ≥ 18 and `npx`. Nothing else.

**What commands does it run?**
Stats the desktop manifest, then `amaro status|app|connector|chat|local|telemetry|lifecycle …` — optionally `curl` to the MCP endpoint. Passes `--json` when acting on output.

**What permissions are needed?**
Shell access + read the manifest file. Auth is a bearer token via `amaro auth login` or `$AMARO_TOKEN`. Destructive ops (`delete` / `reset` / `lifecycle quit`) require `--yes` plus the `destructive` token scope.

**Already installed?**
Re-run `add`, or `npx skills update amaro`. Remove with `npx skills remove amaro`.

> Several surfaces are documented-but-partial — see "Maturity notes" in `SKILL.md`.
