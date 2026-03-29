This directory contains my reproducible KiCad user setup.

It bootstraps KiCad 7.0.x with my personal global symbol and footprint library
tables, injects the custom environment variables required to resolve my
library and 3D model paths, and preserves any existing KiCad library table
files by backing them up once before replacing them with symlinks to the
versions stored here.

The goal is simple: after cloning my dotfiles and KiCad library repos, running
the setup script should make a fresh KiCad installation usable immediately
with the same library configuration on any machine, without relying on manual
GUI setup or hardcoded absolute paths inside the KiCad library files.
Supported KiCad version: 7.0.x only

The setup script fails on other versions by design.

- Requires jq
- Requires my-kicad-library cloned to ~/electronics/kicad-library
- Run:
  ./scripts/setup-kicad.sh
