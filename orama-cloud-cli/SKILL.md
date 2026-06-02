---
name: orama-cloud-cli
description: Drive the Orama Cloud CLI (the `orama` binary, project `oramacloud-cli`) to provision an account, index a data source, and run search — fully from an agent context with no dashboard and no human in the loop. Use when a task involves the `orama` command, Orama Cloud agentic onboarding, turning a CSV or `postgres://` source into a hosted search endpoint, indexing data into Orama Cloud, querying an Orama Cloud index (full-text / vector / hybrid), binding an agent account to a human identity (claim), or self-updating / uninstalling the CLI. Covers the locked `--json` / `--agent` contract, the frozen exit-code table, env resolution, and the cold-start auto-signup flow.
---

# Orama Cloud CLI

The `orama` CLI (project `oramacloud-cli`, binary `orama`) is the agentic-onboarding entry point for **Orama Cloud** — hosted search built as the substrate for AI. It takes a customer from "no account" to "production search endpoint" without a dashboard: provision an account → upload/connect a source → index → search. Every command is designed to be driven by an LLM.

## Design contract an agent can rely on

- **stdout is data only.** Data lands on stdout; human + agent hint lines go on stderr. Under `--json` the happy path keeps stderr empty.
- **`--json` and `--agent` exist on every command.** `--agent` implies `--json` and adds one `next=…` / `agent: …` hint line on stderr to nudge the next command. Payload shapes are **locked**: adding fields is non-breaking; renaming or removing a field (or an exit code) is a major-version break.
- **Exit codes are a frozen public contract.** `0` = success. Failures map to stable numbers (`2` usage, `12` auth-required, `20` API error, `21` network, plus per-command ranges). Full table: [references/exit-codes.md](references/exit-codes.md).
- **Cold-start auto-signup.** On a machine with no token, the first `orama index` (or any auth-required command) implicitly runs `agent-signup` before the wrapped command — one shot, no email, no OTP. `orama search` does **not** auto-signup; it falls through to the public route. Opt out with `--no-auto-signup` / `ORAMA_NO_AUTO_SIGNUP=1`.

## Install

A single-file binary per platform (macOS Apple Silicon, Linux x86_64, Linux arm64). No Node on the host. Served per env:

```sh
curl -fsSL https://oramasearch.com/install.sh | sh          # production
curl -fsSL https://dev.oramasearch.com/install.sh | sh      # dev (common onboarding target)
```

Atomic install into `~/.orama/cloud/bin/orama`. For local development from source the package runs on Node ≥ 22.11 with pnpm ≥ 9.15.

## Environments

Four hosted envs: `production` (default), `dev`, `staging`, `qa`. Aliases: `prod`→`production`, `stage`→`staging`. Resolution ladder, highest precedence first:

1. `--api-url <url>` — custom URL (HTTPS, or `http://localhost`/`127.0.0.1`/`::1`). Rejected by auth-required commands (`AUTH_URL_OVERRIDE_REJECTED`, 13).
2. `--env <name>` — one of the four built-ins.
3. `ORAMACLOUD_API_URL` env var — custom URL (also rejected by auth-required commands).
4. `ORAMACLOUD_ENV` env var — built-in name.
5. `default_env` in `~/.orama/cloud/config.json` (written at first successful auth).
6. Built-in default: `production`.

Per-env state lives under `~/.orama/cloud/`: `tokens/<env>.json` (API token, mode 0600), `claim-secrets/<env>.json` (the `ocs_*` claim secret), `config.json` (`{ default_env }`), `bin/orama`.

## The agent loop

`status` first, branch on `authenticated`, then index, then search:

```sh
orama status --env dev --json          # authenticated true/false (+ reason); never auto-signs-up
orama index ./products.csv --env dev --yes --json   # cold start auto-signs-up, uploads, enqueues
orama search <index_id> --query "headphones" --env dev --json
```

Discovery document for first contact: `<env-url>/llms.txt` (e.g. `https://dev.oramasearch.com/llms.txt`). Install-on-site recipe: `<env-url>/llms-install-on-site.txt`.

## Commands

| Command | Purpose | Auth |
|---|---|:--:|
| `orama status` | Report auth state for an env. First call in an agentic flow; branch on `authenticated`. | — |
| `orama signup` / `orama login` | Magic-link / OTP auth via Clerk. Two-shot under `--json` (OTP out-of-band). | — |
| `orama agent-signup` | Mint an account in one shot — no email, no OTP. Returns a one-time claim secret. | — |
| `orama claim` | Bind an agent account to a Clerk human identity (promote-in-place). Email+OTP or dashboard `--code`. | ✓ |
| `orama index <src>` | Index a `.csv` file (presigned R2 upload → confirm → enqueue) or a `postgres://` URL. `--engine v1\|v2`, `--embedding-model <name>`. | ✓ |
| `orama index-status <id>` | Check an indexing request's state. `--watch` is human-only (rejected under `--json`). | ✓ |
| `orama search <index>` | Search an index. `--mode fulltext\|vector\|hybrid`, tunables, `--public`. Auth-optional. | opt |
| `orama update` | Roll the installed binary forward (mirrors `install.sh`). `--check`, `--pin <semver>`. | — |
| `orama uninstall` | Reverse the install — binary, config, tokens. `--yes`, `--dry-run`. | — |
| `orama version` / `orama help` | Print CLI version / usage. | — |

Global flags (parsed before the subcommand): `--json`, `--agent`, `--version`, `--no-auto-signup`, `--public`, `--env <name>`, `--api-url <url>`.

Full per-command reference — flags, source detection, route selection, search modes, locked envelopes: [references/commands.md](references/commands.md). Frozen exit-code table: [references/exit-codes.md](references/exit-codes.md). Copy-paste agent workflows (cold-start index, status-branching, search-mode selection, postgres credentials, claim, update/uninstall): [references/agent-recipes.md](references/agent-recipes.md).

## Indexing surface

- **Source detection is file-first.** An `<arg>` that resolves to an existing regular file → file flow (only `.csv` accepted; streams to Cloudflare R2 via a presigned PUT, confirms size + row count, enqueues an indexing request). An `<arg>` parsing as a `postgres://` URL → URL flow (connection string posted straight to the API). Any other URL scheme → `INDEX_UNSUPPORTED_SOURCE` (74).
- **`--yes`** gates the file-flow confirm prompt and is required under `--json` / `--agent` on the file flow. Ignored on the URL flow.
- **`--engine v1|v2`** picks the backend at index-creation time, immutable after. `v2` (Oramacore-backed; supports vector/hybrid) is the default; `v1` (in-process `@orama/orama`) is the deprecated legacy escape hatch.
- **`--embedding-model <name>`** sets the per-collection embedding model for `v2` indexes (8-variant catalogue, default `BGESmall`). Invalid only with `v1` or with a `postgres://` source.
- **Postgres credentials** belong in an env var, not the command line. The CLI redacts userinfo from echoes, but the literal URL still lands in shell history / transcripts. Pattern: `set -a; source .env; set +a; orama index --env dev --yes --json "$DATABASE_URL"`.

## Search surface

- **Route is auto-selected.** `--public` set, or a custom `--api-url`, or no token for the env → unauthenticated public route (`/api/v1/public/indexes/{id}/search`); the index ID is the only credential. Token present → authed route, with a silent public retry on a 404. The chosen route surfaces on the `agent:` stderr hint as `route=authed|public`; the `--json` body never carries a `_route` key.
- **`--mode`**: `fulltext` (BM25F, default, lowest latency), `vector` (cosine over embeddings; v2 only), `hybrid` (merged; v2 only). Omitting the flag lets the server apply its `fulltext` default.
- **Tunables** (per-mode, server-enforced): `--similarity` (vector/hybrid), `--threshold` (fulltext/hybrid), `--exact` and `--tolerance` (fulltext/hybrid). Out-of-range values exit `USAGE_ERROR` (2) before any network call.
- The `--json` happy-path body is the API's `SearchIndexResponse` forwarded byte-for-byte: `{ status, index, query, total, took_ms, hits[] }`.

## Identity model

- **Agent account** — minted by `agent-signup` (or auto-signup) with no email/OTP; `clerk_user_id` is null. `orama status` reports `identity_kind: "agent"`.
- **Claim secret** — the `ocs_*` one-time string returned at mint, persisted at `claim-secrets/<env>.json`. Single-use, never recoverable; it lets a human later bind the agent account to their Clerk identity. Captured in the `agent_signed_up` envelope and, on cold-start, inside the composite `agent_bootstrap` envelope.
- **`orama claim`** — promote-in-place: `account.id` survives, `kind` flips agent→user, the prior agent token is revoked and replaced with a user-identity token. Two paths: `--email` (+ OTP, two-shot under `--json`) or `--code` (dashboard-minted 10-char code).
