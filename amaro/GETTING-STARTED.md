# Getting started — amaro skill

No-fluff path from nothing to driving Amaro from Claude Code. Commands
first; minimal notes.

## Prerequisites

- Amaro desktop installed and signed in to a tenant.
- The `amaro` binary on `PATH` (or `curl` + `jq` to hit the manifest's
  HTTP-MCP endpoint directly).
- Node ≥ 18 (for `npx skills`).
- `jq` (optional — JSON piping in the examples below).

## 1. Install the skill

```bash
npx skills add oramasearch/agent-skills --skill amaro
```

Picker: **↑/↓** move, **Space** toggle agent, **Enter** confirm. Or
non-interactive: `--agent claude -y`.

## 2. Launch the desktop

Start the Amaro desktop. On launch it writes the MCP manifest (mode
0600):

| Platform | Manifest path |
|---|---|
| macOS | `~/Library/Application Support/com.amaro.desktop/mcp-server.json` |
| Linux | `~/.local/share/com.amaro.desktop/mcp-server.json` |
| Windows | `%APPDATA%/com.amaro.desktop/mcp-server.json` |

Confirm transport is live:

```bash
amaro status --json        # → "transport": "mcp" when the manifest is present
```

## 3. Verify end-to-end

```bash
amaro app list --json | jq -r '.data[].name'
amaro local screenshot --output ~/Desktop/amaro-now.png --json
```

Then, in a Claude Code session: **"List my data apps."** — it loads the
skill and runs `amaro app list`.

## Auth (only if `transport not authenticated`)

```bash
amaro auth login           # or: export AMARO_TOKEN=<token>
```

## Next

- [`SKILL.md`](SKILL.md) — router: transports, bootstrap, namespaces,
  output contract.
- [`references/`](references/) — per-namespace deep-dives (`auth`,
  `app`, `connector`, `cache`, `chat`, `local`, `telemetry`,
  `lifecycle`).
- [`README.md`](README.md) — overview + FAQ.
