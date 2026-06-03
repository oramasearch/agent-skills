---
description: Drive the running Amaro desktop from the shell — take screenshots, navigate routes, focus / minimize, snapshot local SQLite, tail the log file, open devtools. Use when the user wants to interact with the live UI from a script or agent.
---

# amaro local — drive the running desktop

These commands require the desktop to be running. The CLI auto-detects
this via the manifest at `~/Library/Application
Support/com.amaro.desktop/mcp-server.json`. Under `--transport rest`
they return a `LocalOnly` error — by design, the cloud teams service
can't reach the desktop's webview.

## What's here

```
amaro local state
amaro local screenshot [--output <path>]
amaro local navigate <route>
amaro local focus
amaro local minimize
amaro local restore
amaro local store-dump [--scope all|chat|apps|connectors]
amaro local logs-tail [--lines N]
amaro local devtools
```

Live flag listing: `amaro local --help`.

## State

```
amaro local state --json
```

Returns the desktop's app-state snapshot: signed-in user, active
tenant, window position/size, current route. Cheap; safe to call as
the first probe from a workflow.

## Screenshot

```
amaro local screenshot --output ~/Desktop/now.png --json
```

The desktop writes a PNG to a temp path; the CLI optionally copies it
to `--output`. The JSON envelope always includes the source path so
you can chain with image tools.

## Navigate

```
amaro local navigate "chat/abc123" --json
amaro local navigate "apps/def456" --json
amaro local navigate "settings?section=sources" --json
```

Drives the React app's router via a Tauri event the frontend already
listens for.

## Store dump

```
amaro local store-dump --scope chat --json > chat-snapshot.json
```

Exports the desktop's `amaro-store` SQLite tables to JSON. Useful for
post-hoc analysis or for shipping a snapshot to a teammate. Scoped:
`all` (default), `chat`, `apps`, `connectors`.

## Devtools

```
amaro local devtools --json
```

Opens the embedded webview devtools. Pair with browser-native tools
for frontend debugging without rebuilding.
