---
description: Tail Amaro telemetry, run the Performance Interpreter on a specific turn, check the live LLM cost meter, snapshot the local store for portable export. Use when the user asks "why was this turn slow", "how much have we spent", "give me the last N events", or "export state".
---

# amaro telemetry — observe + interpret + snapshot

## What's here

```
amaro telemetry tail [--envelope-kind <kind>] [--last N]
amaro telemetry cost [--window-seconds N]
amaro telemetry interpret <turn_id>
amaro telemetry snapshot [--scope all|chat|apps|connectors] [--output <path>]
```

Live flag listing: `amaro telemetry --help`.

## Tail

```
amaro telemetry tail --envelope-kind chat.llm.response --last 20 --json
```

Returns the last N envelopes (optionally filtered by kind) the
desktop has buffered. Under `--transport rest` reads from the
teams-side `/api/v1/telemetry/events` endpoint; under `--transport
mcp` calls `subscribe_telemetry`.

For a continuous stream, wrap in:

```
while true; do
  amaro telemetry tail --last 5 --json | jq '.data'
  sleep 2
done
```

NDJSON-mode streaming follows once the streamable-HTTP subscription
tools come online; the current shape is one envelope batch per call.

## Cost

```
amaro telemetry cost --window-seconds 3600 --json
```

Live LLM cost — tokens + dollars + per-model breakdown for the
current session. Omit `--window-seconds` for all-time totals since
the desktop started.

## Interpret

```
amaro telemetry interpret <turn_id> --json
```

Runs the Performance Interpreter ([`amaro#685`](https://github.com/oramasearch/amaro/pull/685))
against a specific chat turn. Returns the interpretation as JSON; the
desktop's chat session will also pick up the interpretation as a
synthesised assistant turn.

## Snapshot

```
amaro telemetry snapshot --scope all --output snapshot.json --json
```

Portable export of the local store. Pair with `amaro lifecycle reset`
+ `amaro local store-dump` for live-share-style session hand-off.
