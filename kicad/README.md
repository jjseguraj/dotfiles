This directory contains my reproducible KiCad user setup.

It bootstraps KiCad 10.0.x with my personal global symbol and footprint library
tables, injects the custom environment variables required to resolve my
library and 3D model paths, and preserves any existing KiCad library table
files by backing them up once before replacing them with symlinks to the
versions stored here.

The goal is simple: after cloning my dotfiles and KiCad library repo, running
the setup script should make a fresh KiCad installation usable immediately
with the same library configuration on any machine, without relying on manual
GUI setup or hardcoded absolute paths inside the KiCad library files.

Supported KiCad version: 10.0.x only  
The setup script fails on other versions by design.

Requirements:
- jq
- KiCad library repo cloned to a local path
- user.hotkeys, fp-lib-table and sym-lib-table under ~/dotfiles/kicad/config

Usage:

Dry run (recommended first):
```bash
./scripts/setup-kicad.sh --dry-run -a <path/to/kicad.AppImage> -l <path/to/kicad-library>
