---
description: Inspect Amaro's cache routing-tier badge and saved-time signal. Use when the user asks "what routed this answer", "what cache hit rate are we at", or "did the cache save us time on this run".
---

# amaro cache — routing-tier + savings

The cache namespace surfaces the routing-tier badge and the
saved-time signal that `amaro#962` (cache-engine common interface)
produces. Until that trait lands and the engines (OramaCore-based
[`amaro#757`](https://github.com/oramasearch/amaro/pull/757) and
GraphRAG) plumb through it, this namespace returns descriptive stubs
explaining where to look.

## What's here

```
amaro cache stats
amaro cache routing [--app-id <id>]
amaro cache savings [--app-id <id>]
amaro cache tier <turn_or_run_id>
```

Live flag listing: `amaro cache --help`.

## Stats

```
amaro cache stats --json
```

Aggregate: hit count by tier, saved-time per app, freshness
distribution.

## Routing for a specific app

```
amaro cache routing --app-id <id> --json
```

Returns the per-app routing tier (`chat-only` / `cache` / `graph` /
`live-api`) with sample envelopes for the last few runs.

## Savings for a specific app

```
amaro cache savings --app-id <id> --json
```

Wall-clock time saved versus the cold-run alternative — the signal
[`amaro#656`](https://github.com/oramasearch/amaro/issues/656) ships
as a UI badge.

## Tier for a single turn / run

```
amaro cache tier <turn_or_run_id> --json
```

Drill-in for a specific incident: "why was this turn slow / fast?"
Pairs with `amaro telemetry interpret` for the longer story.
