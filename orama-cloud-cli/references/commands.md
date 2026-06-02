# Command reference

Per-command surface for the `orama` CLI. Every command accepts the global flags `--json`, `--agent` (implies `--json`), `--no-auto-signup`, `--public` (search only), `--env <name>`, `--api-url <url>`. Locked `--json` envelopes are shown inline. Exit codes referenced by name map to numbers in [exit-codes.md](exit-codes.md).

## Table of contents

- [orama status](#orama-status)
- [orama signup / orama login](#orama-signup--orama-login)
- [orama agent-signup](#orama-agent-signup)
- [Auto-signup (cold start)](#auto-signup-cold-start)
- [orama claim](#orama-claim)
- [orama index](#orama-index)
- [orama index-status](#orama-index-status)
- [orama search](#orama-search)
- [orama update](#orama-update)
- [orama uninstall](#orama-uninstall)
- [orama version / orama help](#orama-version--orama-help)

## orama status

`requiresAuth: false`. The intended first call in an agentic flow — branch on `authenticated` to choose signup vs login vs proceed. Never auto-signs-up.

```sh
orama status --env dev --json
```

Authenticated envelope:

```json
{
  "env": "dev",
  "api_url": "https://...",
  "authenticated": true,
  "email": "you@example.com",
  "account_id": "...",
  "token_path": "/Users/you/.orama/cloud/tokens/dev.json",
  "identity_kind": "user",
  "has_claim_secret": false,
  "next_search_route": "authed"
}
```

- `identity_kind`: `"user"` (non-null `clerk_user_id`), `"agent"` (null), or omitted when unclassifiable (no token / `/me` not 200).
- `has_claim_secret`: `true` when `claim-secrets/<env>.json` exists (existence check only).
- `next_search_route`: previews which route `orama search` (without `--public`) would pick — `"authed"` iff `/me` just returned 200, else `"public"`.
- When `authenticated: false`, a `reason` field is added: `no_token`, `token_invalid`, `token_expired`, or `network_error`. Exit is `0` regardless of `authenticated`; non-zero only on network/IO error.

## orama signup / orama login

Magic-link / OTP auth via Clerk. `signup` mints a new Clerk-bound account; `login` binds an existing one. Same flow, same flags.

Interactive: `orama signup --env dev --email you@example.com` prints a magic-link URL on stderr, polls, writes the per-env token (mode 0600).

Agent two-shot (under `--json` / `--agent`, never prompts — OTP supplied out-of-band):

```sh
# Shot 1 — request OTP. Emits otp_required, exits OTP_REQUIRED (50).
orama signup --email you@example.com --env dev --json
# {"status":"otp_required","auth_session_id":"<UUID>","email":"...","expires_in_seconds":600,"attempts_remaining":5}

# Shot 2 — submit OTP. Calls /verify, exits 0.
orama signup --email you@example.com --env dev --otp <code> --auth-session-id <UUID> --json
# {"status":"verified","env":"dev","account_id":"...","email":"..."}
```

Failure envelopes: `{"status":"otp_invalid","attempts_remaining":N}` → `OTP_INVALID` (51); `OTP_EXPIRED` (52); `OTP_LOCKED` (53). `signup` against an existing identity → `ACCOUNT_EXISTS` (54); `login` against a missing one → `ACCOUNT_NOT_FOUND` (55). Under `--agent`, shot 1 writes `agent: rerun with --otp <code> --auth-session-id <id>` on stderr.

## orama agent-signup

`requiresAuth: false`. Mints an account in one shot — no email, no OTP, no prompt — and returns a one-time **claim secret**.

```sh
orama agent-signup --env dev --json
```

```json
{
  "status": "agent_signed_up",
  "env": "dev",
  "account_id": "<uuid>",
  "claim_secret": "ocs_<32>",
  "token_path": "/Users/you/.orama/cloud/tokens/dev.json",
  "claim_secret_path": "/Users/you/.orama/cloud/claim-secrets/dev.json"
}
```

- Token persists at `tokens/<env>.json` (0600); the claim secret persists separately at `claim-secrets/<env>.json` so it can be backed up / revoked independently.
- The claim secret is single-use and never recoverable — capture it the moment the response lands.
- An existing token short-circuits to `{"status":"already_signed_in",...}` and does **not** overwrite.
- Failure exits match the auto-signup table below.
- Human mode prints the secret to stderr in a fenced "store this" block; stdout stays one data line.

## Auto-signup (cold start)

When no token exists on the resolved env, the dispatcher implicitly runs `agent-signup` before a wrapped `index` (or other auth-required command) and emits a **composite** envelope:

```json
{
  "agent_bootstrap": {
    "status": "agent_bootstrapped", "env": "dev", "account_id": "<uuid>",
    "claim_secret": "ocs_<32>", "token_path": "...", "claim_secret_path": "..."
  },
  "result": {
    "status": "queued", "uploadRequestId": "...", "uploadedDocumentId": "...",
    "indexingRequestId": "...", "filename": "products.csv"
  }
}
```

- Branch on `"agent_bootstrap" in payload`: **present** → a new agent account was minted, persist `claim_secret` immediately; **absent** → a token already existed, the wrapped command's envelope is at top level.
- The resolved target is logged to stderr before every auto-signup POST in both modes: `agent-signup target env=dev url=https://dev.oramasearch.com` (the one intentional break of "stderr empty under `--json`" — URL-poisoning visibility).
- Auto-signup only POSTs to the built-in `--env` URL map. A custom `--api-url` / `ORAMACLOUD_API_URL` falls through to the wrapped command's own `AUTH_REQUIRED` (12) instead of minting against an attacker-controlled URL.
- Opt out: `--no-auto-signup` or `ORAMA_NO_AUTO_SIGNUP=1` → wrapped command exits `AUTH_REQUIRED` (12) when no token.
- `signup` / `login` / `agent-signup` never auto-signup (they are the auth surface). `orama search` never auto-signs-up (it is `"optional"`).
- Auto-signup failure exits (no `result` produced): 429 → `AGENT_SIGNUP_RATE_LIMITED` (58); 503 `auth_unconfigured` → `AUTH_UNCONFIGURED` (57); fetch reject → `NETWORK_ERROR` (21); other non-2xx → `API_ERROR` (20).

## orama claim

`requiresAuth: true` (rejects `--api-url`; excluded from auto-signup). Binds an unclaimed agent account to a Clerk identity — promote-in-place: `account.id` survives, `kind` flips agent→user, the prior agent token is revoked and replaced with a user-identity token, the claim secret file is cleared. Pre-flight requires a local token + claim secret for the env and `/me` reporting `clerk_user_id: null`.

Two mutually-exclusive paths:

**Email + OTP** (`--email`, optional `--mode signin|signup`, default `signin`):

```sh
# Interactive: single call, prompts for the code.
orama claim --email you@example.com --env dev

# Agent two-shot:
orama claim --email you@example.com --env dev --json
# step 1 → {"status":"claim_otp_required","env":"dev","auth_session_id":"<uuid>","expires_in_seconds":N,"attempts_remaining":N}, exits OTP_REQUIRED (50)
orama claim --email you@example.com --otp <code> --auth-session-id <uuid> --env dev --json
# step 2 → {"status":"claimed","env":"dev","account_id":"<uuid>","email":"...","token_path":"...","claim_secret_path_cleared":"...","claimed_at":"<iso>"}
```

**Dashboard code** (`--code`, 10-char Crockford-Base32 uppercase; mutually exclusive with `--email`, `--otp`, `--auth-session-id`):

```sh
orama claim --code A1B2C3D4E5 --env dev --json
# success → {"status":"claimed",...}; failures → mismatch / locked / already_bound / invalid envelopes
```

Failure exits: `CLAIM_PRECONDITIONS_NOT_MET` (no token / no claim secret / already-user / server pair invalid), `CLAIM_SECRET_INVALID`, `CLAIM_IDENTITY_ALREADY_BOUND`, `CLAIM_LOCKED`, `CLAIM_CODE_INVALID`, `CLAIM_CODE_EXPIRED`, plus the shared `OTP_*` / `ACCOUNT_*` / `AUTH_UNCONFIGURED` / `NETWORK_ERROR` / `API_ERROR` codes.

## orama index

`requiresAuth: true`. Indexes a source detected by shape (file-first).

```sh
orama index --env dev --json --yes ./products.csv        # file flow (CSV only)
orama index --env dev --json "$DATABASE_URL"             # URL flow (postgres://)
```

Source detection:

1. `<arg>` resolves to an existing regular file → **file flow**. Only `.csv` accepted. Streams to Cloudflare R2 via a presigned PUT, calls the confirm endpoint (verifies size + row count), enqueues an indexing request.
2. `<arg>` parses as a `postgres://` URL → **URL flow**. Posts the connection string straight to the API; no upload spine.
3. Any other URL scheme → `INDEX_UNSUPPORTED_SOURCE` (74). A non-existent path still routes through the file flow → `INDEX_FILE_NOT_FOUND` (40).

Locked envelope (identical across both flows; URL-flow upload fields are `null`, not omitted):

```json
{ "status": "queued", "uploadRequestId": "...", "uploadedDocumentId": "...", "indexingRequestId": "...", "filename": "products.csv" }
```

Flags:

- **`--yes`** — gates the file-flow confirm prompt; mandatory under `--json` / `--agent` on the file flow. Interactive prompt is strict: only the single char `y` proceeds. Ignored on the URL flow.
- **`--engine v1|v2`** — backend at index-creation time, immutable after. `v2` (Oramacore-backed; vector/hybrid-capable) is the default; `v1` (`@orama/orama` in-process) is deprecated. `--engine v1` prints a one-line deprecation notice on stderr in human mode only. Invalid value → `USAGE_ERROR` (2) pre-network.
- **`--embedding-model <name>`** — per-collection model for `v2`. 8-variant catalogue: `BGESmall` (default, 384d, EN), `BGEBase` (768, EN), `BGELarge` (1024, EN), `MultilingualE5Small` (384), `MultilingualE5Base` (768), `MultilingualE5Large` (1024), `MultilingualMiniLML12V2` (384), `JinaEmbeddingsV2BaseCode` (768, code). Immutable after build. Invalid value, or use with `--engine v1`, or use on a `postgres://` source → `USAGE_ERROR` (2) pre-network (the v1 case surfaces server-side as `INDEX_REQUEST_CREATE_FAILED` (73) with code `embedding_model_not_supported_for_v1_engine`). Omitting it sends no key; server applies `BGESmall`.

**Userinfo redaction.** Connection-string user+password is replaced with `***` before any stderr / agent-hint / error-envelope echo. The raw URL is still forwarded to the API as the request body. Source the URL from an env var so it stays out of shell history / transcripts:

```sh
# .env (gitignored)
DATABASE_URL=postgres://user:pass@host:5432/db
set -a; source .env; set +a
orama index --env dev --yes --json "$DATABASE_URL"
```

Index-flow failure exits: `INDEX_FILE_NOT_FOUND` (40), `INDEX_UNSUPPORTED_TYPE` (41), `INDEX_R2_PUT_FAILED` (42), `INDEX_VERIFICATION_FAILED` (43), `INDEX_NETWORK_ERROR` (44), `INDEX_NEEDS_CONFIRM` (45), `INDEX_REQUEST_CREATE_FAILED` (73), `INDEX_UNSUPPORTED_SOURCE` (74).

## orama index-status

`requiresAuth: true`. Checks an indexing request via `GET /api/v1/indexing-requests/{id}`.

```sh
orama index-status <indexing_request_id> --env dev --json
```

```json
{
  "status": "queued | running | succeeded | failed",
  "indexingRequestId": "...",
  "createdAt": "2026-05-15T13:00:00.000Z",
  "startedAt": "2026-05-15T13:00:10.000Z",
  "completedAt": "2026-05-15T13:00:30.000Z"
}
```

`startedAt` / `completedAt` are omitted when the API returns null. `--watch` polls every 2s and prints transitions on stderr — human-only; rejected under `--json` / `--agent` (`INDEX_WATCH_NOT_ALLOWED`, 72). Unknown id → `INDEX_REQUEST_NOT_FOUND` (70); terminal failed under `--watch` → `INDEX_REQUEST_FAILED` (71).

## orama search

`requiresAuth: "optional"`. `<index>` is a UUIDv7 `index_id` (slug input → `INDEX_NOT_FOUND` (75); slug resolution not wired in v1).

```sh
orama search <index> --query "<text>" [--limit N] [--offset N] \
  [--mode fulltext|vector|hybrid] [--similarity 0.7] [--threshold 0] [--exact] [--tolerance 1] \
  --env dev --json
```

**Route-selection ladder** (first match wins):

1. `--public` set → public route.
2. `--api-url` / `ORAMACLOUD_API_URL` (resolves to `(custom)` env, no token slot) → public route.
3. No token for the named env → public route ("index ID is the credential"; no signup step needed).
4. Token present → authed route. On `404` the CLI silently retries the public route and surfaces the public outcome (`route=public`).

`--public` suppresses the `Authorization` header even when a token exists. It does not imply `--no-auto-signup`; `search` never auto-signs-up regardless. Under `--agent`, every outcome carries `route=authed|public` on the stderr hint, e.g. `agent: search-ok total=42 took_ms=18 index=<uuid> route=authed`.

Happy-path body (forwarded byte-for-byte; no `_route` key):

```json
{
  "status": "ok",
  "index": { "id": "<uuid>", "slug": "products" },
  "query": "china",
  "total": 42,
  "took_ms": 18,
  "hits": [ { "id": "...", "score": 0.91, "document": { "...": "..." } } ]
}
```

`index.slug` and `hits[].highlights` are omitted when the server returns them null/absent.

**`--mode`** — selects the server-side algorithm:

- `fulltext` — BM25F over the inverted index. Default, lowest latency. Best for verbatim terms (SKUs, names, IDs).
- `vector` — cosine similarity over per-collection embeddings (v2 only). Best for synonyms / paraphrases / cross-lingual. Pays an embedding cost per query; ignores keyword overlap.
- `hybrid` — union of fulltext + vector, merged scoring (v2 only). Highest latency. Best when query shape is unpredictable.

Omitting `--mode` sends no `mode` key (server applies `fulltext`). `--mode vector|hybrid` against a v1 index → server HTTP 400 `mode_not_supported_for_v1_engine`. `--mode auto` is forbidden. Any value outside the set → `USAGE_ERROR` (2) pre-network with hint `reason=mode_invalid`.

**Tunables** (range/type validated pre-network; per-mode applicability is server-enforced and a wrong-mode flag returns HTTP 400 `field_not_valid_for_mode` → `USAGE_ERROR` (2)):

| Flag | Type | Valid modes | Server default | Pre-network reject |
|---|---|---|---|---|
| `--similarity` | number `[0,1]` | vector, hybrid | `0.7` | `similarity_range` |
| `--threshold` | number `[0,1]` | fulltext, hybrid | `0` | `threshold_range` |
| `--exact` | boolean | fulltext, hybrid | `false` | — |
| `--tolerance` | int ≥ 0 | fulltext, hybrid | engine default | `tolerance_range` |

**Embedding-model note for paraphrase recall.** The default `BGESmall` favors latency over paraphrase recall; on short conceptual queries over mixed-field corpora it can mis-rank. `MultilingualE5Small` (same 384d) measured better on geographic/concept paraphrases. The model is set at index time (`orama index --embedding-model …`), immutable after. Cloud always embeds `all_properties` (every column contributes), so a non-target column sharing lexical tokens can outweigh the target — switching models mitigates but does not eliminate this.

Search failure exits: `INDEX_NOT_FOUND` (75), `SEARCH_FAILED` (76, non-2xx/non-404/422/429), `SEARCH_RATE_LIMITED` (77, 429 — `Retry-After` parsed and surfaced as `retry_after=<n>`), 422 → `USAGE_ERROR` (2), fetch reject → `NETWORK_ERROR` (21). The 404 / 422 / 429 bodies are forwarded verbatim.

## orama update

`requiresAuth: false`. Rolls the installed binary forward to the version the resolved env serves — same selection logic as `install.sh`, driven from inside the CLI. `--api-url` accepted.

```sh
orama update --check --env dev --json        # read-only: up_to_date | update_available
orama update --env dev                        # install the env's pinned version (no-op if current)
orama update --pin 0.7.0 --env dev            # pin to a bare semver (allows downgrade)
```

```json
{ "status": "updated", "currentVersion": "0.6.0", "targetVersion": "0.7.0", "env": "dev", "api_url": "https://dev.oramasearch.com", "binary_path": "/Users/you/.orama/cloud/bin/orama" }
```

`status`: `up_to_date` | `update_available` (`--check` only) | `updated`. Refuses to overwrite a non-canonical binary (source build, `npx`, anything whose `process.execPath` ≠ `~/.orama/cloud/bin/orama`) → `UPDATE_NOT_APPLICABLE` (82); `--check` skips that guard. Other exits: `UPDATE_DOWNLOAD_FAILED` (83), `UPDATE_INTEGRITY_FAILED` (84, size-floor check), `UPDATE_IO_ERROR` (85). Under `--agent`, a successful update emits `agent: next=orama status --env <env> --json`.

## orama uninstall

`requiresAuth: false`. Reverses `install.sh` — removes `bin/orama`, `config.json`, `tokens/*.json`, then prunes empty parent dirs. No network; succeeds even with broken tokens.

```sh
orama uninstall                 # interactive: lists paths, prompts y/N (strict 'y')
orama uninstall --yes           # skip prompt
orama uninstall --dry-run       # preview, disk untouched
orama uninstall --yes --json    # agent-driven
```

```json
{ "status": "removed", "removed": ["...bin/orama","...config.json","...tokens/dev.json"], "home": "/Users/you/.orama/cloud", "skipped": [] }
```

`status`: `removed` | `dry_run` | `nothing_to_remove` | `needs_confirm`. `--yes` is mandatory under `--json` / `--agent`; without it → `UNINSTALL_NEEDS_CONFIRM` (80) with the would-remove list on stdout. `skipped[]` entries (`reason: "symlink" | "escapes_root"`) record paths refused for symlink-hardening. FS failure mid-removal → `UNINSTALL_IO_ERROR` (81, `agentHint` carries `removed=<N>`). A symlinked cloud root itself → `UNINSTALL_SYMLINKED_ROOT` (86), no envelope. Under `--agent`, a successful removal emits `agent: next=curl -fsSL <env-api>/install.sh | sh`.

## orama version / orama help

`orama version` prints the CLI version (env-resolution-only; uses the soft config read path). `orama --version` short-circuits the same. `orama help` prints usage.
