# orama-cloud-cli

Teaches an AI agent to drive the **Orama Cloud CLI** (the `orama` binary, project `oramacloud-cli`) end-to-end: provision an account, index a CSV or `postgres://` source, and run search — from an agent context, with no dashboard and no human in the loop.

## Install

```sh
npx skills add oramasearch/agent-skills --skill orama-cloud-cli
```

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

## Requirements

The `orama` binary on the host — installed per env via `curl -fsSL https://<env>.oramasearch.com/install.sh | sh` (production: `oramasearch.com`). No Node required on the host; the release is a single-file binary for macOS Apple Silicon, Linux x86_64, or Linux arm64. The skill itself is documentation and assumes the agent can shell out to `orama`.
