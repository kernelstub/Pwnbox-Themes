# Architecture

This repository is a catalog of Pwnbox custom themes. It does not build a
package or run a service; a theme is data that you copy into the Pwnbox flake.
The only tool here is the package validator.

## Repository layout

```text
.
├── themes/
│   └── _template/          # scaffolding for a new theme
├── scripts/
│   └── validate-theme.py   # package and palette validator
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
        │  cp -r themes/<name> ~/pwnbox/dotfiles/themes/
        │  git add dotfiles/themes/<name>
        │  upd
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

## What Pwnbox needs

Pwnbox reads `theme.conf` and the wallpaper named in it. `preview.png` and
`README.md` exist for this repository's gallery and licensing. They are
harmless inside the installed folder as long as `wallpaper =` is explicit.

This means:

- the gallery can show a real screenshot or palette card;
- a theme's licence and authorship travel with the copied folder;
- Pwnbox never uses the preview as the wallpaper.

## Validation

`scripts/validate-theme.py` is the single source of truth for package rules.
It is standard-library Python, so it runs on Pwnbox, GitHub Actions and a
plain Linux host. CI runs it in `--strict` mode, where warnings are errors.

There is no installer and no preview generator. Contributors copy folders into
their own Pwnbox dotfiles and take their own screenshots. That keeps the
repository data-only and avoids a second implementation of Pwnbox's file
layout.

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
- **New documentation:** start at [docs/README.md](../README.md).
