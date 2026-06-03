---
description: Manage Amaro data sources (connectors) from the shell. Use when the user wants to list connectors, add a Snowflake / Postgres / MCP-stdio / CSV / GitHub source, test a configured connection, reprofile a source, or remove one.
---

# amaro connector — data sources

## What's here

```
amaro connector list
amaro connector get <connector_id>
amaro connector add --source-type <type> --name <name> --config <json|@file|->
amaro connector test <connector_id>
amaro connector reprofile <connector_id>
amaro connector delete <connector_id> --yes
```

Live flag listing: `amaro connector --help`.

## Source types + config shapes

The `--config` value must be a `ConnectionConfig` JSON per
`amaro-store::ConnectionConfig`. Read the source-type-specific schema
from the desktop's existing connector docs before composing one.

Common shapes:

```jsonc
// postgres
{
  "type": "postgres",
  "host": "db.example.com",
  "port": 5432,
  "database": "analytics",
  "username": "ro_user",
  "password_ref": "<vault-secret-ref>"
}

// snowflake
{
  "type": "snowflake",
  "account": "abc12345.us-east-1",
  "username": "amaro_ro",
  "password_ref": "<vault-secret-ref>",
  "database": "PROD",
  "warehouse": "AMARO_WH",
  "role": "AMARO_READ",
  "schema": "PUBLIC"
}

// mcp (stdio)
{
  "type": "mcp",
  "transport": "stdio",
  "command": "node",
  "args": ["./my-mcp-server.js"]
}
```

Pass via file:

```
amaro connector add --source-type snowflake --name "Snowflake prod" --config @sf.json --json
```

## Test

```
amaro connector test <connector_id> --json
```

Returns a structural check by default; the desktop's UI surface
performs the live connection test when the CLI runs under
`--transport ipc` or `--transport mcp`.

## Reprofile

```
amaro connector reprofile <connector_id> --json
```

Re-runs the profiler on the source. Useful after a credential rotation
or a schema change. Not yet exposed via the MCP transport — under
`--transport mcp` returns a clean "use REST" error.

## Delete

```
amaro connector delete <connector_id> --yes --json
```

Same `--yes` rule as `app delete`. The MCP transport additionally
prompts a native confirmation modal on the desktop unless the token
carries the `destructive` scope.
