#!/bin/sh
# install.sh — installer for the `amaro` agent skill.
#
#   curl -fsSL https://raw.githubusercontent.com/oramasearch/agent-skills/main/amaro/install.sh | sh
#
# Installs this one skill into the current project for BOTH Claude Code
# (./.claude/skills/<skill>/) and Codex / compatible agents (./.agents/skills/<skill>/).
# Re-running upserts (replaces) it. Run from your project folder, not $HOME.
#
# Self-contained: the repo-wide installer (../install.sh) just runs this for
# every skill. Body is identical across skills except the SKILL line below.
set -eu

SKILL="amaro"            # the one skill this installer handles
REPO="oramasearch/agent-skills"
REF="main"
DEST="."
FROM=""
FORCE=0

err()  { printf 'install.sh: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

usage() {
  cat <<EOF
Install the '$SKILL' agent skill into the current project.

Run this from your project folder (e.g. ~/code/my-project) — NOT \$HOME
or a generic system path. It writes .claude/skills/$SKILL/ and
.agents/skills/$SKILL/ into the current directory.

Usage:
  curl -fsSL https://raw.githubusercontent.com/$REPO/$REF/$SKILL/install.sh | sh
  curl -fsSL .../$SKILL/install.sh | sh -s -- [options]

Options:
  --dir <path>   Project root to install into (default: current directory).
  --ref <ref>    Branch, tag, or commit to pull (default: main).
  --force        Install even if the target looks like a generic/home path.
  --from <dir>   Copy from a local checkout instead of downloading (testing).
  -h, --help     Show this help.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --dir)      DEST="${2:-}"; shift 2;;
    --dir=*)    DEST="${1#*=}"; shift;;
    --ref)      REF="${2:-}"; shift 2;;
    --ref=*)    REF="${1#*=}"; shift;;
    --from)     FROM="${2:-}"; shift 2;;
    --from=*)   FROM="${1#*=}"; shift;;
    --force|-f) FORCE=1; shift;;
    -h|--help)  usage; exit 0;;
    *)          printf 'install.sh: unknown option: %s\n\n' "$1" >&2; usage >&2; exit 2;;
  esac
done

[ -n "$DEST" ] || err "--dir must not be empty"

# --- resolve DEST to an absolute path (without requiring it to exist yet) ------
if [ -d "$DEST" ]; then
  ABS_DEST="$(cd "$DEST" && pwd)"
else
  case "$DEST" in
    /*) ABS_DEST="$DEST" ;;
    *)  ABS_DEST="$(pwd)/$DEST" ;;
  esac
fi
ABS_DEST="${ABS_DEST%/}"; [ -n "$ABS_DEST" ] || ABS_DEST="/"

# --- refuse generic / home install targets unless --force ---------------------
is_generic_path() {
  p="$1"
  case "$p" in
    "$HOME"|/|/Users|/home) return 0 ;;
    /usr|/bin|/sbin|/etc|/var|/tmp|/opt|/root|/srv|/mnt|/sys|/proc|/dev) return 0 ;;
    /Library|/System|/Applications|/private|/cores|/Volumes) return 0 ;;
  esac
  if [ -n "${HOME:-}" ]; then
    case "$p" in
      "$HOME"/Desktop|"$HOME"/Documents|"$HOME"/Downloads|"$HOME"/Movies|"$HOME"/Music|"$HOME"/Pictures|"$HOME"/Public|"$HOME"/.config) return 0 ;;
    esac
  fi
  return 1
}

if [ "$FORCE" -eq 0 ] && is_generic_path "$ABS_DEST"; then
  cat >&2 <<EOF
install.sh: refusing to install into a generic location:
    $ABS_DEST

Installing here puts .claude/skills/ and .agents/skills/ in a shared
directory, so the skill applies to every coding-agent session you start
from here — not what you usually want.

Use a dedicated project folder instead:
    mkdir -p ~/code/my-project && cd ~/code/my-project
    curl -fsSL https://raw.githubusercontent.com/$REPO/$REF/$SKILL/install.sh | sh

Or target one explicitly:  ... | sh -s -- --dir ~/code/my-project
Install here anyway:       ... | sh -s -- --force
EOF
  exit 3
fi

# --- resolve the source tree (local --from, or download tarball) --------------
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

[ -f "$SRC/$SKILL/SKILL.md" ] || err "skill '$SKILL' not found in $REPO@$REF"

# --- install (upsert) into both agent targets ---------------------------------
for base in .claude/skills .agents/skills; do
  tdir="$DEST/$base/$SKILL"
  mkdir -p "$DEST/$base"
  rm -rf "$tdir"
  cp -R "$SRC/$SKILL" "$tdir"
  rm -f "$tdir/install.sh"   # don't ship the installer into the installed skill
done

printf 'Installed %s -> %s/{.claude,.agents}/skills/%s/\n' "$SKILL" "$DEST" "$SKILL"
