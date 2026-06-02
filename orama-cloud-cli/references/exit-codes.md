# Exit codes

Frozen exit-code table for the `orama` CLI. Numbers are a public contract — renaming or renumbering is a breaking change; re-use is forbidden. An agent can branch on these deterministically. `0` is the only success code.

| Code | Name | Meaning |
|---:|---|---|
| 0 | `OK` | Success. |
| 1 | `GENERIC_ERROR` | Unhandled error. |
| 2 | `USAGE_ERROR` | Flag parse failure, unknown command, missing arg, pre-network validation reject. |
| 10 | `UNKNOWN_ENV` | Env name is not one of the four built-ins. |
| 11 | `INVALID_API_URL` | `--api-url` / `ORAMACLOUD_API_URL` failed URL parse or scheme check. |
| 12 | `AUTH_REQUIRED` | Command requires an authenticated session (no token; auto-signup off or unavailable). |
| 13 | `AUTH_URL_OVERRIDE_REJECTED` | `--api-url` not accepted by an auth-required command. |
| 14–18 | `AUTH_EMAIL_*` / `AUTH_SESSION_*` / `AUTH_CODE_INVALID` | Deprecated (bridge #28 browser-handoff). Reserved — not reused. |
| 20 | `API_ERROR` | API returned a non-2xx response. |
| 21 | `NETWORK_ERROR` | `fetch` rejected (DNS, TLS, connect, timeout). |
| 30 | `CONFIG_IO_ERROR` | Config dir/file IO failure. |
| 31 | `CONFIG_SCHEMA_ERROR` | `config.json` exists but failed schema validation. |
| 40 | `INDEX_FILE_NOT_FOUND` | `index` target file missing, unreadable, empty, or not a regular file. |
| 41 | `INDEX_UNSUPPORTED_TYPE` | `index` target is not a `.csv` file. |
| 42 | `INDEX_R2_PUT_FAILED` | Object storage rejected the streamed presigned PUT. |
| 43 | `INDEX_VERIFICATION_FAILED` | API returned 4xx on the upload confirm step. |
| 44 | `INDEX_NETWORK_ERROR` | `fetch` rejected during the `index` flow. |
| 45 | `INDEX_NEEDS_CONFIRM` | File-flow confirm declined, or required under `--json` / `--agent` without `--yes`. |
| 50 | `OTP_REQUIRED` | Non-interactive auth/claim emitted the OTP-pending envelope; rerun with `--otp` + `--auth-session-id`. |
| 51 | `OTP_INVALID` | Server rejected the OTP; `attempts_remaining` on the agent hint. |
| 52 | `OTP_EXPIRED` | OTP TTL (10 min) elapsed before verify. |
| 53 | `OTP_LOCKED` | Attempts exhausted, or `auth_session_id` unknown/consumed. |
| 54 | `ACCOUNT_EXISTS` | `signup` (or `claim --mode signup`) against an email that already has a Clerk identity. |
| 55 | `ACCOUNT_NOT_FOUND` | `login` (or `claim --mode signin`) against an email with no Clerk identity. |
| 56 | `OTP_DELIVERY_FAILED` | Email service rejected the OTP send. |
| 57 | `AUTH_UNCONFIGURED` | Server 503 `auth_unconfigured` — auth sub-app mounted as a stub (missing Clerk / pepper / Cloudflare config). |
| 58 | `AGENT_SIGNUP_RATE_LIMITED` | `agent-signup` got 429 — per-IP or global token-bucket ceiling. |
| 60 | `NOT_IMPLEMENTED` | Command parses but the implementation is a stub. |
| 70 | `INDEX_REQUEST_NOT_FOUND` | `index-status` got 404; id unknown or not visible to this account. |
| 71 | `INDEX_REQUEST_FAILED` | `index-status --watch` polled until terminal `failed`. |
| 72 | `INDEX_WATCH_NOT_ALLOWED` | `index-status --watch` invoked with `--json` / `--agent`. |
| 73 | `INDEX_REQUEST_CREATE_FAILED` | `index` got 4xx on the create-indexing-request call (e.g. `embedding_model_not_supported_for_v1_engine`). |
| 74 | `INDEX_UNSUPPORTED_SOURCE` | `index <arg>` is neither an existing regular file nor a supported source URL (`postgres://`). |
| 75 | `INDEX_NOT_FOUND` | `search` got 404; index id unknown or no `succeeded` build. Also emitted for slug input (no v1 slug resolution). |
| 76 | `SEARCH_FAILED` | `search` got a non-2xx (and non-404/422/429) response. |
| 77 | `SEARCH_RATE_LIMITED` | `search` got 429 from either route. `Retry-After` parsed → `retry_after=<n>` on the hint; 429 body forwarded verbatim. |
| 80 | `UNINSTALL_NEEDS_CONFIRM` | `uninstall` confirm declined, or `--json` / `--agent` without `--yes`. |
| 81 | `UNINSTALL_IO_ERROR` | `uninstall` failed a filesystem op mid-removal; partial removals leave the rest in place. |
| 82 | `UPDATE_NOT_APPLICABLE` | `update` refused — running binary is not at `~/.orama/cloud/bin/orama`. |
| 83 | `UPDATE_DOWNLOAD_FAILED` | `update` failed fetching `install.sh` or the binary asset. |
| 84 | `UPDATE_INTEGRITY_FAILED` | `update` rejected the downloaded asset on the ≥1 MB size-floor check. |
| 85 | `UPDATE_IO_ERROR` | `update` failed `chmod` / atomic-rename. |
| 86 | `UNINSTALL_SYMLINKED_ROOT` | `uninstall` refused — `~/.orama/cloud/` is itself a symlink (incl. dangling). |

## Claim-specific codes

`orama claim` additionally surfaces (names stable; numbers in the same frozen space): `CLAIM_PRECONDITIONS_NOT_MET` (no token / no claim secret / already-user / server reports not-an-agent / server pair invalid), `CLAIM_SECRET_INVALID` (HMAC mismatch — repeated failures lock), `CLAIM_IDENTITY_ALREADY_BOUND` (Clerk identity already bound; v1 enforces 1:1), `CLAIM_LOCKED` (per-account attempt lockout), `CLAIM_CODE_INVALID` (unknown/consumed/mismatched dashboard code), `CLAIM_CODE_EXPIRED` (5-minute window elapsed). It also reuses `OTP_*`, `ACCOUNT_*`, `AUTH_UNCONFIGURED`, `NETWORK_ERROR`, and `API_ERROR`.
