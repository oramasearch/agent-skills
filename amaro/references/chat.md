---
description: Drive Amaro chat sessions from the shell — list sessions, send messages, replay a turn from telemetry, dump history. Use when the user wants to script a chat workflow, reproduce a bug from a turn ID, or extract a session's history for analysis.
---

# amaro chat — sessions

## What's here

```
amaro chat list
amaro chat history <session_id>
amaro chat send <session_id> "<content>" [--detach]
amaro chat new [--app-id <id>] [--message "<text>"]
amaro chat replay <turn_id>
```

Live flag listing: `amaro chat --help`.

## List sessions

```
amaro chat list --json | jq '.data[] | {id, title, updated_at}'
```

## History

```
amaro chat history <session_id> --json
```

Returns the full chat session detail (`ChatSessionDetail` from
`amaro-store`) — messages, artifacts, timestamps.

## Send

```
amaro chat send <session_id> "what was Q3 SF MRR?" --json
```

Appends a user message to the session. Default mode does **not** wait
for the assistant reply (the chat pipeline is asynchronous on the
desktop). For one-shot send + watch, run:

```
amaro chat send <session_id> "..." --json
amaro chat history <session_id> --json | jq '.data.messages[-1]'
```

`--detach` is reserved for the eventual sync mode; today it's a no-op.

## New session

```
amaro chat new --app-id <app_id> --message "First question" --json
```

Creates a session (optionally scoped to a data app), and if
`--message` is provided, appends it as the first user turn.

## Replay

```
amaro chat replay <turn_id> --json
```

Routes through the telemetry-interpret pipeline: feed the original
turn's inputs back in, watch the new turn materialise. Useful for
reproducing a customer-reported bug locally.
