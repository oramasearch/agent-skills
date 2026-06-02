# Agent recipes

Copy-paste workflows for driving the `orama` CLI from an agent context. Each recipe pairs the commands with the JSON keys and exit codes to branch on. Flag and envelope details: [commands.md](commands.md). Exit numbers: [exit-codes.md](exit-codes.md).

## Table of contents

- [Discovery on first contact](#discovery-on-first-contact)
- [Status-first branching](#status-first-branching)
- [Cold-start index (auto-signup)](#cold-start-index-auto-signup)
- [Two-shot interactive signup](#two-shot-interactive-signup)
- [Poll an indexing request to completion](#poll-an-indexing-request-to-completion)
- [Search on a clean machine (public route)](#search-on-a-clean-machine-public-route)
- [Choosing a search mode](#choosing-a-search-mode)
- [Indexing a postgres source safely](#indexing-a-postgres-source-safely)
- [Claiming an agent account](#claiming-an-agent-account)
- [Keeping the binary current / removing it](#keeping-the-binary-current--removing-it)

## Discovery on first contact

Each env serves an [llms.txt](https://llmstxt.org/) discovery index linking the agent loop, the CLI reference, the exit-code table, and the install script:

| Env | URL |
|---|---|
| Production | `https://oramasearch.com/llms.txt` |
| Dev | `https://dev.oramasearch.com/llms.txt` |
| Staging | `https://staging.oramasearch.com/llms.txt` |
| QA | `https://qa.oramasearch.com/llms.txt` |

Install-on-site recipe (create an index from a customer's data, wire search UI into their site, verify in a browser): `https://<env>.oramasearch.com/llms-install-on-site.txt`.

## Status-first branching

`orama status` is the cheap first call — it never auto-signs-up, exits 0 unless the network is down, and tells the agent which branch to take.

```sh
orama status --env dev --json
```

- `authenticated: true` → proceed to `index` / `search`.
- `authenticated: false`, `reason: "no_token"` → `agent-signup` (no human) or `signup`/`login` (human identity wanted).
- `reason: "token_invalid"` / `"token_expired"` → re-run `login`.
- `next_search_route` previews the route `search` would take; `has_claim_secret` / `identity_kind` reveal whether this is an unclaimed agent account.

## Cold-start index (auto-signup)

On a machine with no token, one command mints an agent account and indexes:

```sh
orama index ./products.csv --env dev --yes --json
```

Parse the result by probing for the composite key:

- `"agent_bootstrap" in payload` → a new account was minted. **Persist `payload.agent_bootstrap.claim_secret` immediately** (single-use, never recoverable). The index outcome is `payload.result`.
- absent → a token already existed; `payload` is the plain `index` envelope (`status`, `indexingRequestId`, …).

To force an explicit auth failure instead of auto-signup (CI lanes): add `--no-auto-signup` → exits `AUTH_REQUIRED` (12) when no token.

## Two-shot interactive signup

When a human Clerk identity is wanted up front (not an agent account), the `--json` flow is two processes with the OTP supplied out-of-band:

```sh
orama signup --email you@example.com --env dev --json
# → otp_required, auth_session_id=<UUID>, exit 50. Human reads the emailed code.
orama signup --email you@example.com --env dev --otp <code> --auth-session-id <UUID> --json
# → verified, exit 0.
```

`login` is identical for an existing identity. Branch: `ACCOUNT_EXISTS` (54) on signup → switch to `login`; `ACCOUNT_NOT_FOUND` (55) on login → switch to `signup`.

## Poll an indexing request to completion

`--watch` is human-only. From an agent, loop on one-shot calls and branch on `status`:

```sh
id=$(orama index ./products.csv --env dev --yes --json | jq -r '.result.indexingRequestId // .indexingRequestId')
while :; do
  s=$(orama index-status "$id" --env dev --json | jq -r .status)
  case "$s" in
    succeeded) break ;;
    failed)    echo "indexing failed" >&2; exit 1 ;;
    *)         sleep 2 ;;
  esac
done
```

`indexingRequestId` lives at `.result.indexingRequestId` in the composite cold-start envelope, or `.indexingRequestId` when a token already existed.

## Search on a clean machine (public route)

`search` never auto-signs-up. With no token it falls through to the unauthenticated public route — the index ID is the only credential, so no signup step is needed:

```sh
orama search <index_id> --query "noise cancelling headphones" --env dev --json
```

Force the public route even when a token exists (e.g. to mirror what a browser bundle does): add `--public`. Under `--agent` the stderr hint carries `route=authed|public`. Rate-limited (429) → `SEARCH_RATE_LIMITED` (77) with `retry_after=<n>` on the hint when the server sent `Retry-After`.

## Choosing a search mode

| Query shape | Mode | Why |
|---|---|---|
| Verbatim terms — SKUs, names, technical IDs | `fulltext` (default) | BM25F, lowest latency, no embedding cost |
| Synonyms / paraphrases / cross-lingual | `vector` | cosine over embeddings; ignores exact-token overlap (v2 index only) |
| Unpredictable / mixed lexical + semantic | `hybrid` | merged fulltext + vector; highest latency (v2 only) |

```sh
orama search <v2-uuid> --query "story about a curious girl" --mode vector --env dev --json
orama search <v2-uuid> --query "alice curious girl wonderland" --mode hybrid --similarity 0.8 --env dev --json
orama search <uuid> --query "alyce" --mode fulltext --tolerance 1 --env dev --json   # 1 typo allowed
```

`vector` / `hybrid` need a `v2` index; against `v1` the server rejects the mode. If paraphrase recall matters, the index's embedding model is the lever — set it at index time (`--embedding-model MultilingualE5Small`), immutable after.

## Indexing a postgres source safely

Keep the connection string out of argv, shell history, and transcripts. Source it from an env var; the shell expands it before the CLI sees it, and the CLI redacts userinfo from any echo:

```sh
# .env (gitignored — never committed)
DATABASE_URL=postgres://user:pass@host:5432/db

set -a; source .env; set +a
orama index --env dev --yes --json "$DATABASE_URL"
```

When prompting another agent, point at the variable (`"My database URL is in $DATABASE_URL"`), not the literal URL. `--embedding-model` is not valid on the postgres path (`USAGE_ERROR`, 2).

## Claiming an agent account

Bind an unclaimed agent account to a human Clerk identity. Pre-flight needs the env's token + claim secret on disk and `/me` reporting `clerk_user_id: null`. Promote-in-place revokes the old agent token.

Email path, agent two-shot:

```sh
orama claim --email you@example.com --env dev --json
# → claim_otp_required, auth_session_id=<uuid>, exit 50
orama claim --email you@example.com --otp <code> --auth-session-id <uuid> --env dev --json
# → claimed, exit 0
```

Dashboard-code path (human pastes a 10-char code minted in the dashboard):

```sh
orama claim --code A1B2C3D4E5 --env dev --json
```

If the account was minted on another machine, copy `tokens/<env>.json` + `claim-secrets/<env>.json` to this host first. Lost claim secret → the agent account is unclaimable.

## Keeping the binary current / removing it

```sh
orama update --check --env dev --json     # status: up_to_date | update_available, no download
orama update --env dev                     # install the env's pinned version
orama uninstall --yes --json               # remove binary + config + tokens
```

`update` only rewrites the canonical `~/.orama/cloud/bin/orama` install (else `UPDATE_NOT_APPLICABLE`, 82). `uninstall` needs `--yes` under `--json` (else `UNINSTALL_NEEDS_CONFIRM`, 80); a fresh `curl … install.sh | sh` then starts from zero.
