---
description: Authenticate the `amaro` CLI against a teams instance, manage cached tokens, mint scope-limited tokens for integrations. Use when the user gets "transport not authenticated", asks how to log in, or wants to mint a read-only token for a CI job.
---

# amaro auth — authentication

## What's here

```
amaro auth login [--endpoint <url>]
amaro auth logout
amaro auth whoami
amaro auth token --scope read|write|ui|destructive|observe|full [--ttl-minutes N]
```

## Token precedence

Whenever a command needs a bearer token, `amaro` resolves it in this
order:

1. `--token` flag (or `$AMARO_TOKEN` env var).
2. The desktop's manifest at `~/Library/Application
   Support/com.amaro.desktop/mcp-server.json` (when the desktop is
   running).
3. `~/.amaro/config.toml`'s `[envs.<env>].token`.

The first hit wins. `amaro status --json` reports which lane is
active.

## Login flow

`amaro auth login` resolves the endpoint, hands you the URL to open in
a browser to finish device-code completion, and caches the token onto
the active env. Until the device-code endpoint ships, the flow accepts
`--token <token>` (or `$AMARO_TOKEN`) and stashes it in
`~/.amaro/config.toml`.

```
amaro --env dev auth login --token "$AMARO_DEV_TOKEN" --json
```

## Whoami

```
amaro auth whoami --json
```

Returns the active user object. Routed through the chosen transport
— under `--transport rest` it hits `/api/v1/users/me`; under
`--transport mcp` it calls the `get_user` MCP tool.

## Scoped tokens

```
amaro auth token --scope read --ttl-minutes 60 --json
```

Tokens are minted by the desktop's Settings UI (the row that the
manifest publishes). The CLI surfaces the intent; the desktop
generates the token row with the matching scope set. Available
scopes: `read`, `write`, `ui`, `destructive`, `observe`, `full`.

Use `--scope read` for read-only integrations (Slack bot that lists
data apps, dashboard puller). Use `--scope ui` if the integration
takes screenshots or clicks elements. Reserve `destructive` for
explicit clean-up automation; pair with `--ttl-minutes 5` so the
token can't outlive the operation.

## Logout

```
amaro auth logout --json
```

Clears the cached token from `~/.amaro/config.toml` for the active
env. Does **not** revoke the underlying token row on the server; use
the Settings UI for revocation.
