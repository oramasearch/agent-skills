# amaro

Teaches an AI agent to drive a running **Amaro** instance from the shell.

## Setup

**1. Install the skill.** Run from your project folder (not `$HOME`). Two options:

`curl | sh` — no Node, installs for both Claude Code and Codex:

```sh
curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/amaro/install.sh | sh
```

`npx skills` (Node ≥ 18) — interactive picker, writes a `skills-lock.json`:

```sh
npx skills add oramasearch/agent-skills --skill amaro
```

Picker: **↑/↓** move, **Space** toggle agent, **Enter** confirm. Non-interactive: add `--agent claude -y` (or `--all`).

**2. Launch the Amaro desktop.** It writes an MCP manifest:

| Platform | Manifest path |
|---|---|
| macOS | `~/Library/Application Support/com.amaro.desktop/mcp-server.json` |
| Linux | `~/.local/share/com.amaro.desktop/mcp-server.json` |
| Windows | `%APPDATA%\com.amaro.desktop\mcp-server.json` |

No manifest → desktop isn't running; you're cloud-REST-only.

**3. Verify:** `amaro status --json` confirms transport, env, and auth. No CLI on `PATH`? Hit the manifest's MCP URL directly with `curl` + `jq`.

## Connect a remote agent (tunnel)

The MCP server binds to loopback only, so an agent on another machine can't reach it directly — put a public tunnel in front of the local port. The manifest bearer token is still required on every request; the tunnel adds reachability, not auth.

**Let the skill do it.** Ask the agent to "expose the Amaro MCP server with a tunnel" and it follows the "Expose the MCP server to a remote agent" recipe in `SKILL.md` — it reads the port from the manifest and starts the tunnel for you.

**Or set it up manually.** First get the local port:

```sh
MANIFEST=~/Library/Application\ Support/com.amaro.desktop/mcp-server.json
PORT=$(jq -r .url "$MANIFEST" | sed -E 's#.*:([0-9]+)/.*#\1#')   # e.g. 57552
```

Then pick one tunnel. The remote MCP URL is the printed host + `/mcp`.

| Method | Account / domain | Stability | Commands |
|---|---|---|---|
| **cloudflared** quick tunnel | none | ephemeral `*.trycloudflare.com` | `brew install cloudflared`<br>`cloudflared tunnel --url http://127.0.0.1:$PORT` |
| **ngrok** | one-time authtoken | random `*.ngrok-free.app` per session | `brew install ngrok`<br>`ngrok config add-authtoken <YOUR_NGROK_AUTHTOKEN>`<br>`ngrok http $PORT` |
| **cftunn** | your Cloudflare domain | stable hostname, survives restarts | `brew install cloudflared`<br>`cloudflared tunnel login`<br>`curl -fsSL https://raw.githubusercontent.com/thatjuan/cftunn/main/install.sh \| bash`<br>`cftunn $PORT amaro.example.com` |

Full notes (auth scopes, what each prints) live under "Expose the MCP server to a remote agent" in `SKILL.md`.

## FAQ

**What does it use?**\
The `amaro` CLI, or `curl` + `jq` against the desktop's HTTP-MCP endpoint.

**What do I need to use it?**\
The `amaro` binary on `PATH` (or `curl` + `jq`), plus a running desktop and/or teams-service credentials.

**What's installed, and where?**\
Only docs, into `.claude/skills/amaro/` (`~/.claude/skills/amaro/` with `-g`). No binary, no build.

**Prereqs to install?**\
Node ≥ 18 and `npx`.

**What commands does it run?**\
`amaro status|app|connector|chat|local|telemetry|lifecycle …`, optionally `curl` to the MCP endpoint.

**What permissions are needed?**\
Shell access and manifest read. Destructive ops (`delete` / `reset` / `lifecycle quit`) need `--yes` plus the `destructive` token scope.

**Already installed?**\
Re-run `add`, or `npx skills update amaro`. Remove with `npx skills remove amaro`.

> Several surfaces are documented-but-partial — see "Maturity notes" in `SKILL.md`.
