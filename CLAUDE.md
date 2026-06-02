# Orama Agent Skills — agent working rules

This repo is Orama's distributable collection of AI agent skills. Every skill here is published for consumers to install with the [`skills` CLI](https://github.com/vercel-labs/skills) (`npx skills`). The hard constraint that governs every decision in this repo: **each skill must be discoverable and installable by `npx skills`.** A skill that the CLI can't find or parse is not shippable.

This file is the authoritative guide for adding and organizing skills. The root [`README.md`](README.md) is the human-facing catalog.

## Repo layout

```
agent-skills/
  <skill-name>/                # one directory per skill, at the repo root
    SKILL.md                   # required — the installable skill definition
    README.md                  # required — human-browsable doc for the skill
    references/                # optional — bundled reference docs loaded on demand
    scripts/                   # optional — bundled helper scripts
    assets/                    # optional — bundled templates / images
  README.md                    # catalog + install instructions
  CLAUDE.md                    # this file
  skills-lock.json             # lock for skills installed FROM elsewhere (see below)
  .claude/skills/              # consumer-style install target — leave empty
  .agents/skills/              # consumer-style install target — leave empty
```

Skills live at the **repo root** as `<skill-name>/`. That is the layout `npx skills` discovers without extra flags (see below) and the one every existing skill follows.

## How `npx skills` discovers and installs skills

`npx skills add oramasearch/agent-skills` clones the repo and scans for skills. Discovery roots, in order:

1. **The repo root, one level deep** — every top-level `<dir>/SKILL.md` is a skill. This is the layout this repo uses.
2. `skills/<name>/SKILL.md`, and catalog form `skills/<category>/<name>/SKILL.md` (walked one extra level). Available if categories are ever wanted; not used today.
3. `.claude/skills/` and `.agents/skills/` — but any skill there that is tracked in `skills-lock.json` (i.e. installed *from* another repo) is ignored as a source. These dirs stay empty in this repo.

A directory is a skill **only** when it contains a `SKILL.md` with valid YAML frontmatter (`name` + `description`). Once a `SKILL.md` is found at a directory, the scanner does not descend further — so `references/`, `scripts/`, `assets/` under a skill are bundled with it, never mistaken for separate skills.

Consumers install with:

```sh
npx skills add oramasearch/agent-skills --skill <skill-name>   # one skill
npx skills add oramasearch/agent-skills --all                  # every skill
```

The `--skill <name>` filter matches the frontmatter `name` (case-insensitive) or the folder name. **Keep the folder name identical to the frontmatter `name`** so both forms resolve.

## Adding a skill — checklist

1. Create `<skill-name>/` at the repo root. Folder name: lowercase letters, digits, hyphens; no leading/trailing hyphen; verb-led where natural (`generate-docs`, `gh-address-comments`).
2. Write `<skill-name>/SKILL.md` (see requirements below). Set frontmatter `name` equal to the folder name.
3. Write `<skill-name>/README.md` (see requirements below).
4. Add bundled resources under `references/` / `scripts/` / `assets/` only as needed. Keep `SKILL.md` lean; push depth into `references/`.
5. Add a catalog row in the root [`README.md`](README.md) `Skills Catalog` table, and a short section describing the skill and its bundled files.
6. Verify discovery before committing (below).
7. Commit. Use the [`commitpush`](https://github.com/oramasearch/agent-skills) discipline; one skill per commit where practical.

## SKILL.md requirements

This is the file `npx skills` installs and the agent loads. It must parse and trigger correctly.

- **Frontmatter (required):**
  ```yaml
  ---
  name: <skill-name>          # == folder name; lowercase/digits/hyphens; ≤64 chars
  description: <what it does AND when to use it>   # ≤1024 chars, trigger-rich
  ---
  ```
  The `description` is what the consuming agent matches against to decide when to invoke the skill — write concrete trigger conditions (commands, file types, task phrases), not just a category label.
- **Body:** capability-oriented (what the skill knows / what the tool does), under ~500 lines. Link bundled references with their usage context. No second copy of content that lives in a reference file.
- **No behavioral boilerplate** (`Always` / `Never` / `Should` / `Must` directives aimed at the agent). State capabilities and facts; let the description carry the trigger.

## README.md requirements (per skill)

Every skill folder carries a `README.md` — the human-browsable doc seen on GitHub and copied alongside `SKILL.md` on install. It complements `SKILL.md` (which is written for the agent); the README is written for a developer evaluating or installing the skill. Include:

- **Title + one-line summary** — what the skill does.
- **Install** — the exact `npx skills add oramasearch/agent-skills --skill <skill-name>` line.
- **What it does / when it triggers** — the capability and the situations that activate it.
- **Bundled files** — a short table of `SKILL.md` + each `references/` / `scripts/` / `assets/` file and its purpose.
- **Requirements** — any external tool, binary, or credential the skill assumes (or "None").

Keep the README and `SKILL.md` description in sync: when the skill's purpose or triggers change, update both. The README is for humans; the depth an agent needs at runtime belongs in `SKILL.md` and `references/`.

## Root README catalog discipline

The root [`README.md`](README.md) is the entry point. On every skill add/rename/remove:

- Update the `Skills Catalog` table: `| [<skill-name>](./<skill-name>/) | <description> |`.
- Add or update the per-skill section beneath the table (summary + bundled-files table), mirroring the existing entries.
- Keep the install examples pointed at `oramasearch/agent-skills`.

## Verify discovery before committing

A skill that doesn't parse silently drops from `--all`. Confirm the new skill is discoverable:

```sh
# List the skills the CLI sees in this working tree (point it at the repo root):
npx skills list .

# Or dry-run an install against the published repo once pushed:
npx skills add oramasearch/agent-skills --skill <skill-name>
```

If the skill doesn't appear: check that `<skill-name>/SKILL.md` exists at the repo root, the frontmatter has both `name` and `description`, and the YAML parses.

## skills-lock.json

`skills-lock.json` tracks skills installed *into* this repo from elsewhere (external sources), not the skills this repo publishes. Skills authored here are **not** added to it. Leave it `{ "version": 1, "skills": {} }` unless an external skill is genuinely vendored in.
