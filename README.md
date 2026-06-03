<p align="center">
  <img src="https://raw.githubusercontent.com/oramasearch/orama/refs/heads/main/misc/readme/orama-readme-hero-dark.png#gh-dark-mode-only" />
  <img src="https://raw.githubusercontent.com/oramasearch/orama/refs/heads/main/misc/readme/orama-readme-hero-light.png#gh-light-mode-only" />
</p>

[![Skills CLI](https://img.shields.io/badge/npx-skills-blue?style=flat-square)](https://www.npmjs.com/package/skills)

If you need more info, help, or want to provide general feedback on Orama, join the [Orama Slack channel](https://orama.to/slack)

# Orama Agent Skills

A curated collection of AI agent skills for Claude Code and compatible agents, distributed by Orama.

Agent Skills are self-contained instruction sets that give AI coding agents specialized capabilities. Each skill defines a complete workflow — from persona construction to execution strategy — that an agent can follow to accomplish complex, multi-step tasks autonomously.

This repository is designed for use with the [`skills` CLI](https://www.npmjs.com/package/skills). Install individual skills or the entire collection into your project, and your AI agent gains new abilities instantly.

# Skills Catalog

| Skill | Description |
|-------|-------------|
| [orama-cloud-cli](./orama-cloud-cli/) | Drive the Orama Cloud CLI (`orama`) to provision an account, index a CSV or `postgres://` source, and run search — fully from an agent context, no dashboard, no human in the loop. Covers the locked `--json` / `--agent` contract, the frozen exit-code table, env resolution, search modes, and cold-start auto-signup. |
| [amaro](./amaro/) | Drive a running Amaro instance from the shell via the `amaro` headless CLI — inspect/run data apps, manage connectors, drive the live desktop UI, stream telemetry, control lifecycle. Router skill over three transports (cloud REST / local MCP / Tauri-IPC) with eight namespace reference files and a versioned `--json` output contract. |

# Getting Started

> **⚠️ Run the install from your project folder — not your home directory.**
> Both installers below write a `.claude/skills/` and `.agents/skills/` folder into the **current working directory**. `cd` into the dedicated folder where you actually run your coding agent first (e.g. `~/code/my-project`). Do **not** run it from `~`, `/`, or any generic system path — that scatters skill files across your home directory and makes them apply to every session indiscriminately.
>
> ```bash
> mkdir -p ~/code/my-project && cd ~/code/my-project   # a real project folder
> # …then run one of the installers below
> ```
>
> The `curl | sh` installer **enforces this** — it aborts if you run it from `$HOME`, `/`, a system directory, or a standard home subfolder (Desktop/Documents/Downloads/…), and suggests a dedicated folder. Override with `--force` if you really mean it.

Two ways to install — pick either. Both drop the same skill bundles into `./.claude/skills/<name>/` (Claude Code) and `./.agents/skills/<name>/` (Codex / compatible agents) in the current directory.

## Option A — `curl | sh` (no Node)

The no-frills path. No Node, no flags to learn. The root [`install.sh`](install.sh) downloads the repo once and runs **each skill's own installer** — installing **every** skill for **both** agents by default:

```bash
curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/install.sh | sh
```

Install only some skills:

```bash
curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/install.sh | sh -s -- --skills amaro,orama-cloud-cli
```

Install **a single skill** by running just that skill's installer (each skill ships its own `<skill>/install.sh`):

```bash
curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/amaro/install.sh | sh
```

Other options: `--dir <path>` (target a different project root), `--ref <branch|tag|sha>`, `--list` (show available skills), `--force`, `--help`. Re-running upserts each skill in place.

## Option B — `npx skills` (needs Node ≥ 18)

The [`skills` CLI](https://www.npmjs.com/package/skills). Adds a `skills-lock.json` tracking what's installed (see [Verify installation](#verify-installation)).

Prerequisites:

- [Node.js](https://nodejs.org/) >= 18
- An AI agent that supports skills (e.g., [Claude Code](https://docs.anthropic.com/en/docs/claude-code))

Install one skill:

```bash
npx skills add oramasearch/agent-skills --skill <skill-name>
```

Install all skills:

```bash
npx skills add oramasearch/agent-skills --all
```

---

Once installed (either way), skills are available to your AI agent automatically. Invoke them by describing a task that matches the skill's trigger.

## Verify installation

After installation, you should see the skill files in your project's skills directory and a `skills-lock.json` tracking installed skills:

```json
{
  "version": 1,
  "skills": {
    "<skill-name>": {
      "source": "github/oramasearch/agent-skills",
      "sourceType": "github"
    }
  }
}
```

# Skill Anatomy

Each skill follows a consistent structure:

```
skill-name/                # one directory per skill, at the repo root
  SKILL.md          # Skill definition (required) — YAML frontmatter + instructions
  README.md         # Human-browsable doc for the skill (required)
  references/       # Bundled reference docs loaded on demand (optional)
  scripts/          # Helper scripts (optional)
  assets/           # Templates / images (optional)
```

The `SKILL.md` file is the entry point installed by `npx skills`. Its YAML frontmatter defines the skill's `name` and `description` (used for trigger matching), followed by the full instructions the agent will follow. The folder name matches the frontmatter `name`.

> [!NOTE]
> Reference files are loaded by the agent at runtime — they keep the main `SKILL.md` focused while providing depth on demand.

# Creating Skills

Agents adding skills to this repo follow [`CLAUDE.md`](CLAUDE.md) — it is the authoritative guide for layout, the `npx skills` discovery rules, and the per-skill checklist. In short, each skill should:

1. **Solve a specific, repeatable problem** — skills work best when they encode a well-defined workflow
2. **Be self-contained** — include all instructions, templates, and scripts the agent needs
3. **Use rich frontmatter** — write a descriptive `description` field with trigger phrases so agents know when to activate the skill
4. **Carry a `README.md`** — a human-browsable doc with the install line, what it does, bundled files, and requirements
5. **Include bundled resources** — break complex workflows into reference docs rather than stuffing everything into `SKILL.md`
6. **Be production-oriented** — skills should produce real, working output — not drafts or placeholders

```yaml
---
name: my-skill
description: Short description of what this skill does and when to use it.
---

# My Skill

Instructions the agent follows...
```

# License

Orama Agent Skills is licensed under the [Apache 2.0](https://www.apache.org/licenses/LICENSE-2.0) license.

<img referrerpolicy="no-referrer-when-downgrade" src="https://static.scarf.sh/a.png?x-pxid=16782f89-15fb-4e03-8e9c-2a06106542f7" />
