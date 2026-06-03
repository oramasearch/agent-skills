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

Front the loopback-only MCP server with a public tunnel so a remote agent can reach it (manifest bearer token still required; default port `57552`).

Ask the agent to "expose the Amaro MCP server with a tunnel" and it runs this for you — or do it manually:

**[cloudflared](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/do-more-with-tunnels/trycloudflare/)** — no account, ephemeral `*.trycloudflare.com`:

```sh
brew install cloudflared
cloudflared tunnel --url http://127.0.0.1:57552
```

**[ngrok](https://ngrok.com/)** — one-time authtoken, random `*.ngrok-free.app`:

```sh
brew install ngrok
ngrok config add-authtoken <YOUR_NGROK_AUTHTOKEN>
ngrok http 57552
```

**[cftunn](https://github.com/thatjuan/cftunn)** — your Cloudflare domain, stable hostname:

```sh
brew install cloudflared
cloudflared tunnel login
curl -fsSL https://raw.githubusercontent.com/thatjuan/cftunn/main/install.sh | bash
cftunn 57552 amaro.example.com
```

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
