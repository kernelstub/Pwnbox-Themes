# Architecture

This repository is a catalog and installer for Pwnbox custom themes. It does
not build a package or run a service; a theme is data that becomes part of the
Pwnbox flake.

## Repository layout

```text
.
├── themes/
│   ├── _template/          # scaffolding, not installable
│   ├── midnight/           # example theme package
│   └── ember/              # example theme package
├── scripts/
│   ├── install-theme.sh    # copy a package into a Pwnbox checkout
│   ├── validate-theme.py   # package and palette validator
│   └── render-preview.sh   # gallery preview card generator
├── docs/                   # this manual
├── assets/                 # banner
├── .github/                # CI, PR template, issue forms
├── CONTRIBUTING.md
├── CODE_OF_CONDUCT.md
├── SECURITY.md
├── LICENSE
└── README.md
```

A theme package contains `theme.conf`, a wallpaper, `preview.png` and
optionally `README.md`/`LICENSE`. The format is documented in
[the theme format reference](../reference/theme-format.md).

## How a theme reaches the desktop

```text
Pwnbox-Themes/themes/<name>/
        │
        │  ./scripts/install-theme.sh <name>
        │  (validate, copy theme.conf + wallpaper, git add, rebuild)
        ▼
~/pwnbox/dotfiles/themes/<name>/
        │
        │  home-manager module (modules/home/dotfiles.nix)
        ▼
~/.config/pwnbox/themes/<name>/     read-only Nix store links
        │
        │  ALT + S -> THEME -> Custom
        ▼
pwnbox-theme (theme engine)          generated app themes
        │
        ├── Quickshell Theme.js, kitty, rofi, fuzzel
        ├── GTK, Hyprland, Neovim, Zed
        ├── Telegram, Spotify, Equibop
        ├── Signal, Element, Wire
        ├── Zen chrome and site styles
        └── IDA, Stremio Enhanced, Obsidian, SimpleX
```

The Pwnbox side of this flow is owned by the
[Pwnbox theme engine](https://github.com/kernelstub/Pwnbox/blob/main/docs/usage/themes.md).

## Why the installer copies only two files

Pwnbox only reads `theme.conf` and the wallpaper named in it. `preview.png`
and `README.md` exist for this repository's gallery and licensing. Keeping
them out of the installed folder means:

- the runtime theme directory stays tiny;
- the picker always uses the wallpaper, never a preview fallback;
- the flake rebuild does not carry gallery assets;
- a theme's licence and authorship stay with the source package.

If a user copies the whole folder manually, the extra files are harmless as
long as `wallpaper =` is set.

## Validation

`scripts/validate-theme.py` is the single source of truth for package rules.
It is standard-library Python, so it runs on Pwnbox, GitHub Actions and a
plain Linux host. CI runs it in `--strict` mode, where warnings are errors.

`scripts/render-preview.sh` is a contributor convenience, not part of
validation. It uses ImageMagick and produces a deterministic palette card
from the wallpaper and the 16 colours. A real screenshot is also accepted.

## Activation and state

The active theme is stored outside the flake in
`~/.cache/pwnbox/theme/custom-theme`. On login, `pwnbox-theme restore`
re-applies the saved theme. Deleting the theme folder from the flake makes
that saved name stale; selecting another theme repairs it.

Rebuilding the flake updates the home-manager links, so changing a theme is
always a rebuild, never an edit under `~/.config`.

## Extension points

- **New theme:** add a folder under `themes/`; no code changes.
- **New package rule:** update `scripts/validate-theme.py` and the
  [format reference](../reference/theme-format.md) together.
- **New installer behaviour:** update `scripts/install-theme.sh`,
  `docs/setup/install.md` and the CI shell checks.
- **New preview style:** update `scripts/render-preview.sh`; regenerate the
  tracked previews.
- **New documentation:** start at [docs/README.md](../README.md).
