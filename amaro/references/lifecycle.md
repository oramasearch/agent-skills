---
description: Control the running Amaro desktop's lifecycle from the shell — restart, quit, reset state, toggle a feature flag. Use only when the user explicitly asks; these are destructive ops and require `--yes` plus the `destructive` scope on the active token.
---

# amaro lifecycle — process control

## What's here

```
amaro lifecycle restart --reason "<text>" --yes
amaro lifecycle quit --yes
amaro lifecycle reset --scope chat|cache|all --yes
amaro lifecycle feature-flag <name> <json-value>
```

Live flag listing: `amaro lifecycle --help`.

## Confirmation rules

These are all `destructive`-scope operations:

- Every command refuses to run without `--yes` for non-interactive
  use.
- Under `--transport ipc` / `--transport mcp`, the desktop additionally
  shows a native confirmation modal unless the active token already
  carries the `destructive` scope.
- Under `--transport rest`, the cloud teams service is the gate; these
  ops return `LocalOnly` until the cloud surface adds them (they're
  fundamentally desktop-local in design).

**These run only when the user explicitly asks; surface the intent to
the user before passing `--yes` to a destructive op.**

## Restart

```
amaro lifecycle restart --reason "post-feature-flag rollout" --yes --json
```

Triggers the desktop's lifecycle handler to restart the process. The
manifest is removed on shutdown and rewritten by the new instance —
clients that cache the manifest URL should re-resolve after a
restart.

## Quit

```
amaro lifecycle quit --yes --json
```

Cleanly shuts the desktop down. The manifest is removed on graceful
exit; clients see `manifest_present: false` from `amaro status` on
the next poll.

## Reset state

```
amaro lifecycle reset --scope chat --yes --json
amaro lifecycle reset --scope cache --yes --json
amaro lifecycle reset --scope all --yes --json
```

Wipes desktop-local state. `chat` clears chat history; `cache` clears
the runner / data-app caches; `all` clears everything (including
SQLite tables — connectors, apps, chats).

## Feature flag

```
amaro lifecycle feature-flag <name> '{"enabled": true}' --json
amaro lifecycle feature-flag plan-preview-pause true --json
amaro lifecycle feature-flag default-model '"claude-haiku-4-5-20251001"' --json
```

The value argument is parsed as JSON when possible, falls back to a
string. Useful for flipping experiments mid-test without touching the
Settings UI.
