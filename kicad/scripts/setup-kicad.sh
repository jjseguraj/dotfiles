#!/bin/bash
set -e

KICAD_VERSION="7.0"
KICAD_CONFIG_DIR="$HOME/.config/kicad/$KICAD_VERSION"
LIB_DIR="$HOME/electronics/kicad-library"
DOTFILES_DIR="$HOME/dotfiles/kicad/config"

echo "Setting up KiCad environment..."

mkdir -p "$KICAD_CONFIG_DIR"

backup_file() {
  if [ -e "$1" ] && [ ! -L "$1" ] && [ ! -e "$1.backup" ]; then
    mv "$1" "$1.backup"
    echo "Backed up $1 -> $1.backup"
  fi
}

backup_file "$KICAD_CONFIG_DIR/fp-lib-table"
backup_file "$KICAD_CONFIG_DIR/sym-lib-table"

ln -sf "$DOTFILES_DIR/fp-lib-table" "$KICAD_CONFIG_DIR/fp-lib-table"
ln -sf "$DOTFILES_DIR/sym-lib-table" "$KICAD_CONFIG_DIR/sym-lib-table"

CONFIG_FILE="$KICAD_CONFIG_DIR/kicad_common.json"

if [ ! -f "$CONFIG_FILE" ]; then
    echo '{}' > "$CONFIG_FILE"
fi

if ! command -v jq >/dev/null 2>&1; then
    echo "jq is required. Install it first."
    exit 1
fi

tmpfile=$(mktemp)

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
