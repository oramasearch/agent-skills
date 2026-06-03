# amaro

Teaches an AI agent to drive a running **Amaro** instance from the shell — inspect/run data apps, manage connectors, drive the live desktop UI, stream telemetry, and control lifecycle — via the headless `amaro` CLI (or raw HTTP-MCP); triggers on `amaro` CLI mentions or any of those tasks.

## Install

```sh
npx skills add oramasearch/agent-skills --skill amaro
```

Non-interactive: add `--agent claude -y` (or `--all`). Needs Node ≥ 18. See **[GETTING-STARTED.md](GETTING-STARTED.md)** for the full setup walkthrough.

## FAQ

**What does it use?**
The `amaro` CLI, or `curl` + `jq` against the desktop's HTTP-MCP endpoint.

**What do I need to use it?**
The `amaro` binary on `PATH` (or `curl` + `jq`), plus a running desktop and/or teams-service credentials.

**What's installed, and where?**
Only docs, into `.claude/skills/amaro/` (`~/.claude/skills/amaro/` with `-g`). No binary, no build.

**Prereqs to install?**
Node ≥ 18 and `npx`.

**What commands does it run?**
`amaro status|app|connector|chat|local|telemetry|lifecycle …`, optionally `curl` to the MCP endpoint.

**What permissions are needed?**
Shell access and manifest read. Destructive ops (`delete` / `reset` / `lifecycle quit`) need `--yes` plus the `destructive` token scope.

**Already installed?**
Re-run `add`, or `npx skills update amaro`. Remove with `npx skills remove amaro`.

> Several surfaces are documented-but-partial — see "Maturity notes" in `SKILL.md`.
