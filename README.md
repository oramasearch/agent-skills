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

# Getting Started

## Prerequisites

- [Node.js](https://nodejs.org/) >= 18
- An AI agent that supports skills (e.g., [Claude Code](https://docs.anthropic.com/en/docs/claude-code))

## Install a specific skill

```bash
npx skills add oramasearch/agent-skills --skill <skill-name>
```

## Install all skills

```bash
npx skills add oramasearch/agent-skills --all
```

Once installed, skills are available to your AI agent automatically. Invoke them by describing a task that matches the skill's trigger.

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
skill-name/
  SKILL.md          # Skill definition (required) — YAML frontmatter + instructions
  *.md              # Bundled reference docs (optional)
  *.sh              # Helper scripts (optional)
```

The `SKILL.md` file is the entry point. Its YAML frontmatter defines the skill's `name` and `description` (used for trigger matching), followed by the full instructions the agent will follow.

> [!NOTE]
> Reference files are loaded by the agent at runtime — they keep the main `SKILL.md` focused while providing depth on demand.

# Creating Skills

Want to add a new skill to this collection? Each skill should:

1. **Solve a specific, repeatable problem** — skills work best when they encode a well-defined workflow
2. **Be self-contained** — include all instructions, templates, and scripts the agent needs
3. **Use rich frontmatter** — write a descriptive `description` field with trigger phrases so agents know when to activate the skill
4. **Include bundled resources** — break complex workflows into reference docs rather than stuffing everything into `SKILL.md`
5. **Be production-oriented** — skills should produce real, working output — not drafts or placeholders

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
