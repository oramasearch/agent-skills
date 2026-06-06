---
description: Drive the local orama-installer data-node sidecar from the amaro CLI — create/list/delete named full-text indexes, add documents, and run BM25F search. Use when the user wants to stash documents in the local search sidecar and search them, or asks to check whether the data node is running.
---

# amaro datanode — the local search sidecar

`amaro datanode` drives the **orama-installer data-node sidecar**
(`orama-installer serve`): a loopback REST service that owns a data node
in-process and exposes named full-text indexes, document ingest, and BM25F
search. The CLI connects to it **directly** (not through the cloud-REST /
MCP / IPC transports), so it works whether or not the desktop is running —
the `--transport` flag is ignored here.

> This is the standalone search sidecar, separate from `amaro cache` (the
> routing/cache surface). Different process, full-text only.

## First move — is the sidecar running?

```
amaro datanode status --json
```

`{"v":1,"data":{"status":"ok","indexes":N,"docs":M}}` means it's up. An error
like *"the data-node sidecar isn't reachable"* means it isn't — start it with
`orama-installer serve`. The CLI discovers the port (default `6480`) and bearer
token (`~/.orama-installer/serve.token`); override with `ORAMA_INSTALLER_URL` /
`ORAMA_INSTALLER_TOKEN` / `ORAMA_INSTALLER_PORT`.

## What's here

```
amaro datanode status
amaro datanode list
amaro datanode create <name>
amaro datanode delete <name> --yes
amaro datanode add <index> --documents '<json | @file.json | ->'
amaro datanode clear <index> --yes
amaro datanode search <index> <query> [--top-k N] [--tokens]
```

Live flag listing: `amaro datanode --help`. Index names must match
`[A-Za-z0-9._-]`, 1–64 chars; a `default` index always exists.

## Create → add → search (the common flow)

```sh
amaro datanode create sales --json
amaro datanode add sales --json --documents '[
  {"title":"Postgres HA","body":"streaming replication WAL"},
  {"title":"Redis","body":"in-memory store"}
]'
amaro datanode search sales "postgres replication" --top-k 5 --tokens --json
```

`add` accepts one object or an array of flat objects (field → string / number
/ bool — nested values are rejected). `search` returns ranked hits best-first,
each carrying its stored `fields` for display/citation; `--tokens` appends the
query's tokenization.

## Destructive ops

`delete` (drop an index) and `clear` (drop every document, keep the index)
require `--yes`. Confirm with the user before passing it.

## Output contract

Same versioned envelope as every other namespace: `--json` →
`{"v":1,"data":…}` on success, `{"v":1,"error":…}` on stderr on failure.
