---
description: Manage Amaro data apps from the shell — list, get, create, run, watch, pin, delete, export. Use when the user asks to list data apps, run one, watch a job to completion, create a new app from a template, or export an existing app as runnable Python.
---

# amaro app — data apps

## What's here

```
amaro app list
amaro app get <app_id>
amaro app create --name <name> [--description <text>] [--template-id <id>]
amaro app run <app_id> [--params <json|@file|->] [--detach]
amaro app status <run_id>
amaro app pin <app_id>
amaro app unpin <app_id>
amaro app delete <app_id> --yes
amaro app export <app_id>
```

Live flag listing: `amaro app --help`.

## List

```
amaro app list --json | jq '.data[]'
```

Returns the rows from `amaro-store::list_data_apps()` (under
`--transport ipc`/`mcp`) or the teams-service `GET /api/v1/apps`
(under `--transport rest`).

## Run + watch

The default `amaro app run` polls the run row until it hits
`completed`, `failed`, or `cancelled`. Add `--detach` to print the
`run_id` and exit immediately.

Params are forwarded to the runner verbatim. Three accepted forms:

- Inline JSON: `--params '{"from":"2026-05-01"}'`
- File: `--params @params.json`
- Stdin: `--params -` (then pipe the JSON in)

```
echo '{"from":"2026-05-01"}' | amaro app run abc123 --params - --json
```

Streaming progress notes land on stderr (suppressed under `--quiet`).
Final status lands on stdout as a single JSON envelope under `--json`.

## Status

```
amaro app status <run_id> --json
```

One-shot status; doesn't poll. Pair with `watch -n 2` if you want to
build your own polling loop.

## Create

```
amaro app create --name "Churn snapshot" --description "Weekly run" --json
```

`--template-id` seeds the new app from a template. Under
`--transport mcp` this calls the desktop's `create_data_app` tool;
under `--transport rest` it hits `POST /api/v1/apps`.

## Delete

```
amaro app delete <app_id> --yes --json
```

Requires `--yes` for non-interactive runs. Under `--transport mcp` /
`--transport ipc`, the desktop additionally requires the
`destructive` scope on the active token (the Settings UI mints
these). REST: enforced server-side.

## Export

```
amaro app export <app_id> --json
```

Returns the data-app row with its source script. Use this to extract
an app for hand-off ("let me give this code to a real eng").
