# orama-cloud-cli

Teaches an AI agent to drive the **Orama Cloud CLI** (the `orama` binary, project `oramacloud-cli`) end-to-end: provision an account, index a CSV or `postgres://` source, and run search — from an agent context, with no dashboard and no human in the loop.

## Install

```sh
npx skills add oramasearch/agent-skills --skill orama-cloud-cli
```

Installs the skill into your agent. The interactive picker uses **↑/↓** to move, **Space** to toggle an agent (Claude Code, Cursor, …), **Enter** to confirm. Non-interactive: add `--agent claude -y` (or `--all` for every skill + agent). Needs Node ≥ 18.

## What it does

Orama Cloud is hosted search built as the substrate for AI: hand it a data source, it provisions an account, indexes the data, and returns a production search endpoint. Its CLI is designed to be operated by an LLM. This skill gives an agent the full operating surface:

- **The agent loop** — `status` → cold-start auto-signup → `index` → `search`, plus the `<env-url>/llms.txt` discovery document.
- **The locked contract** — `--json` / `--agent` payload shapes and the frozen exit-code table an agent can branch on deterministically.
- **Indexing** — file-first source detection (CSV via presigned R2 upload, or `postgres://` connection string), engine selection (`v1` / `v2`), and the embedding-model catalogue.
- **Search** — route auto-selection (authed vs public), `fulltext` / `vector` / `hybrid` modes and their tunables, and how to pick a mode.
- **Identity** — agent accounts, the one-time claim secret, and `orama claim` (promote-in-place to a Clerk human identity).

## When it triggers

Tasks that involve the `orama` command, Orama Cloud agentic onboarding, turning a data source into a hosted search endpoint, indexing into or querying an Orama Cloud index, claiming an agent account, or updating/uninstalling the CLI.

## Bundled files

| File | Purpose |
|------|---------|
| `SKILL.md` | Skill definition — design contract, install, env resolution, the agent loop, command table, and the indexing / search / identity surfaces. |
| `references/commands.md` | Per-command reference: flags, source detection, route ladder, search modes + tunables, and the locked `--json` envelopes. |
| `references/exit-codes.md` | The frozen exit-code table plus claim-specific codes. |
| `references/agent-recipes.md` | Copy-paste agent workflows: cold-start index, status-branching, polling to completion, public-route search, mode selection, postgres credentials, claim, and update/uninstall. |

## FAQ

**What does the skill use?** The `orama` CLI (project `oramacloud-cli`) — a single-file binary for macOS Apple Silicon, Linux x86_64, or Linux arm64. No Node on the host at runtime. The CLI talks to Orama Cloud over HTTPS.

**What do I need to *use* it?** The `orama` binary on `PATH`. Install per env: `curl -fsSL https://oramasearch.com/install.sh | sh` (production) or `https://dev.oramasearch.com/install.sh` (dev). No account needed up front — the first auth-required command cold-start auto-signs-up.

**What gets installed, and where?**
- *The skill* — docs only (`SKILL.md`, `README.md`, `references/*.md`) into `.claude/skills/orama-cloud-cli/` project-level (or `~/.claude/skills/…` with `-g`); tracked in `skills-lock.json`.
- *The `orama` binary* — atomically into `~/.orama/cloud/bin/orama`; per-env state under `~/.orama/cloud/` (`tokens/<env>.json` mode 0600, `claim-secrets/<env>.json`, `config.json`).

**Prereqs to *install* the skill?** Node ≥ 18 and `npx`. (Building the CLI from source instead needs Node ≥ 22.11 + pnpm ≥ 9.15 — not required to use the released binary.)

**What commands does it run?** `orama status | index | search | claim | update | uninstall …`, with implicit `agent-signup` on first auth-required call. `--json` / `--agent` for machine-readable output.

**What permissions are needed?** Shell exec for the agent, network egress to the chosen env, and write access to `~/.orama/cloud/` (where tokens land, mode 0600). No elevated/root permissions.

**Already have it installed?** Re-running `add` updates the skill (or `npx skills update orama-cloud-cli`; remove with `npx skills remove orama-cloud-cli`). The CLI self-updates via `orama update` and removes itself with `orama uninstall`.
