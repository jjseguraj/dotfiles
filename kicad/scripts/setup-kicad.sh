#!/bin/bash
set -euo pipefail

EXPECTED_KICAD_SERIES="7.0"
LIB_DIR="$HOME/electronics/my-kicad-library"
DOTFILES_DIR="$HOME/dotfiles/kicad/config"

echo "Setting up KiCad environment..."

fail() {
  echo "ERROR: $1" >&2
  exit 1
}

backup_file() {
  if [ -e "$1" ] && [ ! -L "$1" ] && [ ! -e "$1.backup" ]; then
    mv "$1" "$1.backup"
    echo "Backed up $1 -> $1.backup"
  fi
}

# 1) Check KiCad exists
if ! command -v kicad-cli >/dev/null 2>&1; then
  fail "KiCad is not installed or not in PATH."
fi

# 2) Read installed version
KICAD_VERSION_RAW="$(kicad-cli --version 2>/dev/null || true)"
[ -n "$KICAD_VERSION_RAW" ] || fail "Unable to read KiCad version."

# Extract first major.minor occurrence, e.g. 7.0 from 7.0.11
INSTALLED_KICAD_SERIES="$(printf '%s\n' "$KICAD_VERSION_RAW" | grep -oE '[0-9]+\.[0-9]+' | head -n1 || true)"
[ -n "$INSTALLED_KICAD_SERIES" ] || fail "Could not parse KiCad version from: $KICAD_VERSION_RAW"

if [ "$INSTALLED_KICAD_SERIES" != "$EXPECTED_KICAD_SERIES" ]; then
  fail "KiCad version mismatch. Expected $EXPECTED_KICAD_SERIES.x, found: $KICAD_VERSION_RAW"
fi

echo "Detected compatible KiCad version: $KICAD_VERSION_RAW"

# 3) Check expected config dir exists
KICAD_CONFIG_DIR="$HOME/.config/kicad/$EXPECTED_KICAD_SERIES"
[ -d "$KICAD_CONFIG_DIR" ] || fail "Expected KiCad config directory not found: $KICAD_CONFIG_DIR"

# 4) Check required repos/paths exist
[ -d "$LIB_DIR" ] || fail "KiCad library directory not found: $LIB_DIR"
[ -d "$DOTFILES_DIR" ] || fail "Dotfiles KiCad config directory not found: $DOTFILES_DIR"
[ -f "$DOTFILES_DIR/fp-lib-table" ] || fail "Missing fp-lib-table in $DOTFILES_DIR"
[ -f "$DOTFILES_DIR/sym-lib-table" ] || fail "Missing sym-lib-table in $DOTFILES_DIR"

# 5) Backup existing library tables once, then symlink
backup_file "$KICAD_CONFIG_DIR/fp-lib-table"
backup_file "$KICAD_CONFIG_DIR/sym-lib-table"

ln -sf "$DOTFILES_DIR/fp-lib-table" "$KICAD_CONFIG_DIR/fp-lib-table"
ln -sf "$DOTFILES_DIR/sym-lib-table" "$KICAD_CONFIG_DIR/sym-lib-table"

CONFIG_FILE="$KICAD_CONFIG_DIR/kicad_common.json"
if [ ! -f "$CONFIG_FILE" ]; then
  echo '{"environment":{"vars":{}}}' > "$CONFIG_FILE"
fi

if ! command -v jq >/dev/null 2>&1; then
  fail "jq is required but not installed."
fi

tmpfile="$(mktemp)"

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
})
' "$CONFIG_FILE" > "$tmpfile"

mv "$tmpfile" "$CONFIG_FILE"

echo "KiCad setup complete."
echo "Verified KiCad series: $EXPECTED_KICAD_SERIES"
echo "Config dir: $KICAD_CONFIG_DIR"
echo "Library dir: $LIB_DIR"
