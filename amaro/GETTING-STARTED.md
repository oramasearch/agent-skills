# Getting started — amaro skill

## 1. Install the skill

```bash
npx skills add oramasearch/agent-skills --skill amaro
```

Picker: **↑/↓** move, **Space** toggle agent, **Enter** confirm. Or
non-interactive: `--agent claude -y`.

## 2. Launch the desktop

Start the Amaro desktop. On launch it writes the MCP manifest (mode
0600):

## Next

- [`SKILL.md`](SKILL.md) — router: transports, bootstrap, namespaces,
  output contract.
- [`references/`](references/) — per-namespace deep-dives (`auth`,
  `app`, `connector`, `cache`, `chat`, `local`, `telemetry`,
  `lifecycle`).
- [`README.md`](README.md) — overview + FAQ.
