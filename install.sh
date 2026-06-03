#!/bin/sh
# install.sh — one-shot installer for Orama's agent skills.
#
#   curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/install.sh | sh
#
# Default: download every skill in this repo and install it for BOTH Claude Code
# (./.claude/skills/<name>/) and Codex / compatible agents (./.agents/skills/<name>/),
# into the current directory. Re-running upserts (replaces) each skill cleanly.
#
# Subset:  ... | sh -s -- --skills amaro,orama-cloud-cli
#
# This is the no-frills alternative to `npx skills` — no Node, no flags to learn.
set -eu

REPO="oramasearch/agent-skills"
REF="main"            # branch, tag, or sha to pull
DEST="."              # where .claude/ and .agents/ get written (consumer project root)
WANT=""               # space-separated skill names; empty = all
FROM=""               # local checkout to copy from instead of downloading (testing)
LIST_ONLY=0

TARGETS=".claude/skills .agents/skills"

err()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Install Orama agent skills into the current project.

Run this from the dedicated folder where you work with your coding agent
(e.g. ~/code/my-project) — NOT your home directory or a generic system path.
It writes .claude/skills/ and .agents/skills/ into the current directory.

Usage:
  curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/install.sh | sh
  curl -fsSL .../install.sh | sh -s -- [options]

Options:
  --skills a,b,c   Install only these skills (comma- or space-separated). Repeatable.
  --skill <name>   Install one skill. Repeatable.
  --dir <path>     Project root to install into (default: current directory).
  --ref <ref>      Branch, tag, or commit to pull (default: main).
  --list           List available skills and exit.
  --from <dir>     Copy from a local checkout instead of downloading (testing).
  -h, --help       Show this help.

With no options, every skill is installed for both Claude Code (.claude/skills/)
and Codex / compatible agents (.agents/skills/).
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --skills)   WANT="$WANT $(printf '%s' "${2:-}" | tr ',' ' ')"; shift 2;;
    --skills=*) WANT="$WANT $(printf '%s' "${1#*=}" | tr ',' ' ')"; shift;;
    --skill)    WANT="$WANT ${2:-}"; shift 2;;
    --skill=*)  WANT="$WANT ${1#*=}"; shift;;
    --dir)      DEST="${2:-}"; shift 2;;
    --dir=*)    DEST="${1#*=}"; shift;;
    --ref)      REF="${2:-}"; shift 2;;
    --ref=*)    REF="${1#*=}"; shift;;
    --from)     FROM="${2:-}"; shift 2;;
    --from=*)   FROM="${1#*=}"; shift;;
    --list|-l)  LIST_ONLY=1; shift;;
    -h|--help)  usage; exit 0;;
    *)          printf 'install.sh: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2;;
  esac
done

[ -n "$DEST" ] || err "--dir must not be empty"

# --- resolve the source tree (download tarball, or use a local checkout) -------
SRC=""
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; }
trap cleanup EXIT INT TERM

if [ -n "$FROM" ]; then
  [ -d "$FROM" ] || err "--from path is not a directory: $FROM"
  SRC="$FROM"
else
  have tar || err "need 'tar' on PATH"
  TMP="$(mktemp -d 2>/dev/null || mktemp -d -t agent-skills)"
  url="https://codeload.github.com/$REPO/tar.gz/$REF"
  if have curl; then
    curl -fsSL "$url" -o "$TMP/src.tgz" || err "download failed: $url"
  elif have wget; then
    wget -qO "$TMP/src.tgz" "$url" || err "download failed: $url"
  else
    err "need 'curl' or 'wget' on PATH"
  fi
  tar -xzf "$TMP/src.tgz" -C "$TMP" || err "tarball extract failed"
  SRC="$(find "$TMP" -maxdepth 1 -mindepth 1 -type d | head -n1)"
  [ -n "$SRC" ] && [ -d "$SRC" ] || err "could not locate extracted source"
fi

# --- enumerate skills: any top-level <name>/SKILL.md (dotdirs excluded) --------
available=""
for d in "$SRC"/*/; do
  [ -f "${d}SKILL.md" ] || continue
  name="$(basename "$d")"
  available="$available $name"
done
available="$(printf '%s\n' $available | sort)"
[ -n "$available" ] || err "no skills found in $REPO@$REF"

if [ "$LIST_ONLY" -eq 1 ]; then
  printf 'Available skills in %s@%s:\n' "$REPO" "$REF"
  printf '  %s\n' $available
  exit 0
fi

# --- pick the selection -------------------------------------------------------
selected=""
if [ -z "$(printf '%s' "$WANT" | tr -d ' ')" ]; then
  selected="$available"
else
  for req in $WANT; do
    match=""
    for a in $available; do [ "$a" = "$req" ] && match="$a" && break; done
    if [ -n "$match" ]; then
      selected="$selected $match"
    else
      printf 'install.sh: no such skill: %s (have:%s)\n' "$req" "$(printf ' %s' $available)" >&2
      exit 1
    fi
  done
fi

# --- install (upsert) ---------------------------------------------------------
count=0
for name in $selected; do
  # hard guard before any rm -rf: name must be a plain skill slug
  case "$name" in
    *[!a-z0-9-]*|''|-*|*-) err "refusing unsafe skill name: '$name'";;
  esac
  [ -d "$SRC/$name" ] || err "missing skill dir: $SRC/$name"
  for base in $TARGETS; do
    tdir="$DEST/$base/$name"
    [ -n "$base" ] || err "internal: empty target base"
    mkdir -p "$DEST/$base"
    rm -rf "$tdir"
    cp -R "$SRC/$name" "$tdir"
  done
  count=$((count + 1))
  printf '  installed %s\n' "$name"
done

printf 'Done. %d skill(s) -> %s/{.claude,.agents}/skills/\n' "$count" "$DEST"
