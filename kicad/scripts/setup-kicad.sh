#!/bin/bash
set -euo pipefail

EXPECTED_KICAD_SERIES="10.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$SCRIPT_DIR/../config"
KICAD_CMD="$HOME/bin/kicad"

DRY_RUN=0

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Bootstrap KiCad user configuration for KiCad ${EXPECTED_KICAD_SERIES}.x.

Required:
  -a, --appimage PATH     Path to the KiCad AppImage executable
  -l, --library PATH      Path to the KiCad library repository

Options:
  -n, --dry-run           Show what would be done without changing anything
  -h, --help              Show this help message and exit

This script:
  - verifies the KiCad AppImage exists and is executable
  - symlinks it to: $KICAD_CMD
  - checks KiCad version matches ${EXPECTED_KICAD_SERIES}.x
  - symlinks fp-lib-table, sym-lib-table, and user.hotkeys
  - patches kicad_common.json with custom paths and preferences
  - verifies the setup at the end
EOF
}

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

run() {
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY-RUN] $*"
  else
    "$@"
  fi
}

backup_file() {
  if [ -e "$1" ] && [ ! -L "$1" ] && [ ! -e "$1.backup" ]; then
    if [ "$DRY_RUN" -eq 1 ]; then
      echo "[DRY-RUN] mv $1 $1.backup"
    else
      mv "$1" "$1.backup"
      echo "Backed up $1 -> $1.backup"
    fi
  fi
}

KICAD_IMAGE=""
LIB_DIR=""

if [ "$#" -eq 0 ]; then
  usage
  exit 1
fi

while [ "$#" -gt 0 ]; do
  case "$1" in
    -a|--appimage)
      [ "$#" -ge 2 ] || fail "$1 requires a path argument"
      KICAD_IMAGE="$2"
      shift 2
      ;;
    -l|--library)
      [ "$#" -ge 2 ] || fail "$1 requires a path argument"
      LIB_DIR="$2"
      shift 2
      ;;
    -n|--dry-run)
      DRY_RUN=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      echo "Unknown option: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
    *)
      echo "Unexpected argument: $1" >&2
      echo >&2
      usage >&2
      exit 1
      ;;
  esac
done

[ -n "$KICAD_IMAGE" ] || {
  echo "ERROR: missing required option: --appimage" >&2
  echo >&2
  usage >&2
  exit 1
}

[ -n "$LIB_DIR" ] || {
  echo "ERROR: missing required option: --library" >&2
  echo >&2
  usage >&2
  exit 1
}

echo "Setting up KiCad environment..."

if [ ! -x "$KICAD_IMAGE" ]; then
  fail "KiCad AppImage not found or not executable at $KICAD_IMAGE"
fi

if [ -e "$KICAD_CMD" ] && [ ! -L "$KICAD_CMD" ]; then
  fail "$KICAD_CMD exists and is not a symlink"
fi

run mkdir -p "$(dirname "$KICAD_CMD")"
run ln -sfn "$KICAD_IMAGE" "$KICAD_CMD"

if ! command -v kicad >/dev/null 2>&1; then
  fail "KiCad is not installed or not in PATH."
fi

KICAD_VERSION_RAW="$(kicad kicad-cli --version 2>/dev/null || true)"
[ -n "$KICAD_VERSION_RAW" ] || fail "Unable to read KiCad version."

INSTALLED_KICAD_SERIES="$(printf '%s\n' "$KICAD_VERSION_RAW" | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)"
[ -n "$INSTALLED_KICAD_SERIES" ] || fail "Could not parse KiCad version from: $KICAD_VERSION_RAW"

if [ "$INSTALLED_KICAD_SERIES" != "$EXPECTED_KICAD_SERIES" ]; then
  fail "KiCad version mismatch. Expected $EXPECTED_KICAD_SERIES.x, found: $KICAD_VERSION_RAW"
fi

echo "Detected compatible KiCad version: $KICAD_VERSION_RAW"

KICAD_CONFIG_DIR="$HOME/.config/kicad/$EXPECTED_KICAD_SERIES"
[ -d "$KICAD_CONFIG_DIR" ] || fail "Expected KiCad config directory not found: $KICAD_CONFIG_DIR"

[ -d "$LIB_DIR" ] || fail "KiCad library directory not found: $LIB_DIR"
[ -d "$DOTFILES_DIR" ] || fail "Dotfiles KiCad config directory not found: $DOTFILES_DIR"
[ -f "$DOTFILES_DIR/fp-lib-table" ] || fail "Missing fp-lib-table in $DOTFILES_DIR"
[ -f "$DOTFILES_DIR/sym-lib-table" ] || fail "Missing sym-lib-table in $DOTFILES_DIR"
[ -f "$DOTFILES_DIR/user.hotkeys" ] || fail "Missing user.hotkeys in $DOTFILES_DIR"

backup_file "$KICAD_CONFIG_DIR/fp-lib-table"
backup_file "$KICAD_CONFIG_DIR/sym-lib-table"
backup_file "$KICAD_CONFIG_DIR/user.hotkeys"

run ln -sfn "$DOTFILES_DIR/fp-lib-table" "$KICAD_CONFIG_DIR/fp-lib-table"
run ln -sfn "$DOTFILES_DIR/sym-lib-table" "$KICAD_CONFIG_DIR/sym-lib-table"
run ln -sfn "$DOTFILES_DIR/user.hotkeys" "$KICAD_CONFIG_DIR/user.hotkeys"

CONFIG_FILE="$KICAD_CONFIG_DIR/kicad_common.json"
if [ ! -f "$CONFIG_FILE" ]; then
  if [ "$DRY_RUN" -eq 1 ]; then
    echo "[DRY-RUN] create $CONFIG_FILE with minimal JSON"
  else
    echo '{"environment":{"vars":{}}}' > "$CONFIG_FILE"
  fi
fi

if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required but not installed."
fi

tmpfile="$(mktemp)"
trap 'rm -f "$tmpfile"' EXIT

jq --arg lib "$LIB_DIR" \
   --arg model "$LIB_DIR/3dmodels" \
'
def vars_to_object:
  if . == null then
    {}
  elif type == "object" then
    .
  elif type == "array" then
    map(select(type == "object" and has("name") and has("value")))
    | map({key: .name, value: .value})
    | from_entries
  else
    {}
  end;

.environment = (.environment // {}) |
.environment.vars = ((.environment.vars | vars_to_object) + {
  "KICAD_USER_LIB_DIR": $lib,
  "KICAD_USER_3DMODEL_DIR": $model
}) |

.input = (.input // {}) |
.input.center_on_zoom = false |
.input.mouse_left = -2 |
.input.scroll_modifier_pan_h = 306 |
.input.scroll_modifier_pan_v = 0 |
.input.scroll_modifier_zoom = 308
' "$CONFIG_FILE" > "$tmpfile"

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY-RUN] patch $CONFIG_FILE"
else
  mv "$tmpfile" "$CONFIG_FILE"
fi

echo "KiCad setup complete."
echo "Verified KiCad series: $EXPECTED_KICAD_SERIES"
echo "Config dir: $KICAD_CONFIG_DIR"
echo "Library dir: $LIB_DIR"
echo "AppImage: $KICAD_IMAGE"

echo "Verifying setup..."

if [ "$DRY_RUN" -eq 1 ]; then
  echo "[DRY-RUN] Verification skipped because no changes were applied."
  exit 0
fi

kicad kicad-cli --version >/dev/null 2>&1 || fail "KiCad CLI not working"

jq -e --arg lib "$LIB_DIR" '.environment.vars.KICAD_USER_LIB_DIR == $lib' "$CONFIG_FILE" >/dev/null \
  || fail "KICAD_USER_LIB_DIR not set correctly in $CONFIG_FILE"

jq -e --arg model "$LIB_DIR/3dmodels" '.environment.vars.KICAD_USER_3DMODEL_DIR == $model' "$CONFIG_FILE" >/dev/null \
  || fail "KICAD_USER_3DMODEL_DIR not set correctly in $CONFIG_FILE"

[ -L "$KICAD_CONFIG_DIR/fp-lib-table" ] || fail "fp-lib-table is not a symlink"
[ -L "$KICAD_CONFIG_DIR/sym-lib-table" ] || fail "sym-lib-table is not a symlink"
[ -L "$KICAD_CONFIG_DIR/user.hotkeys" ] || fail "user.hotkeys is not a symlink"

[ "$(readlink -f "$KICAD_CONFIG_DIR/fp-lib-table")" = "$(readlink -f "$DOTFILES_DIR/fp-lib-table")" ] \
  || fail "fp-lib-table symlink target is wrong"

[ "$(readlink -f "$KICAD_CONFIG_DIR/sym-lib-table")" = "$(readlink -f "$DOTFILES_DIR/sym-lib-table")" ] \
  || fail "sym-lib-table symlink target is wrong"

[ "$(readlink -f "$KICAD_CONFIG_DIR/user.hotkeys")" = "$(readlink -f "$DOTFILES_DIR/user.hotkeys")" ] \
  || fail "user.hotkeys symlink target is wrong"

[ -L "$KICAD_CMD" ] || fail "$KICAD_CMD is not a symlink"
[ "$(readlink -f "$KICAD_CMD")" = "$(readlink -f "$KICAD_IMAGE")" ] \
  || fail "$KICAD_CMD does not point to the requested AppImage"

echo "Verification passed."
