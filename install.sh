#!/bin/sh
# install.sh — install ALL Orama agent skills.
#
#   curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/install.sh | sh
#
# Downloads the repo once and runs each skill's own installer (<skill>/install.sh)
# against the same tree, so every skill lands in BOTH Claude Code (./.claude/skills/)
# and Codex / compatible agents (./.agents/skills/) in the current directory.
#
# Subset:  ... | sh -s -- --skills amaro,orama-cloud-cli
# Single:  install one skill directly with its own installer instead —
#          curl -fsSL .../main/<skill>/install.sh | sh
#
# Run from your project folder, not $HOME. No Node — the simple alternative to
# `npx skills`.
set -eu

REPO="oramasearch/agent-skills"
REF="main"
DEST="."
WANT=""               # space-separated skill names; empty = all
FROM=""               # local checkout instead of downloading (testing)
FORCE=0
LIST_ONLY=0

err()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<'EOF'
Install all Orama agent skills into the current project, by running each
skill's own installer.

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
  --force          Install even if the target looks like a generic/home path.
  --from <dir>     Use a local checkout instead of downloading (testing).
  -h, --help       Show this help.

With no options, every skill is installed for both Claude Code (.claude/skills/)
and Codex / compatible agents (.agents/skills/). To install a single skill you
can also curl that skill's installer directly: .../main/<skill>/install.sh
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
    --force|-f) FORCE=1; shift;;
    -h|--help)  usage; exit 0;;
    *)          printf 'install.sh: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2;;
  esac
done

[ -n "$DEST" ] || err "--dir must not be empty"

# --- resolve the source tree (download tarball once, or use a local checkout) -
SRC=""
TMP=""
cleanup() { [ -n "$TMP" ] && rm -rf "$TMP"; return 0; }
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

# --- enumerate installable skills: top-level <name>/ with SKILL.md + install.sh
available=""
for d in "$SRC"/*/; do
  [ -f "${d}SKILL.md" ] || continue
  [ -f "${d}install.sh" ] || continue
  available="$available $(basename "$d")"
done
available="$(printf '%s\n' $available | sort)"
[ -n "$available" ] || err "no installable skills found in $REPO@$REF"

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

# --- run each skill's own installer against the shared tree -------------------
# Each <skill>/install.sh enforces the generic-path guard and does the copy; a
# non-zero exit (e.g. 3 = generic target) propagates straight out.
force_arg=""
[ "$FORCE" -eq 1 ] && force_arg="--force"

count=0
for name in $selected; do
  sh "$SRC/$name/install.sh" --from "$SRC" --dir "$DEST" $force_arg || exit $?
  count=$((count + 1))
done

printf 'Done. %d skill(s) installed into %s/{.claude,.agents}/skills/\n' "$count" "$DEST"
