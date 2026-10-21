# Pwnbox Themes documentation

This repository is a community catalog of fixed-palette themes for
[Pwnbox](https://github.com/kernelstub/Pwnbox). A theme is a small folder with
a `theme.conf` palette and a wallpaper; Pwnbox applies it to the bar,
terminal, launcher, GTK apps, editors, browser and the apps with live theming.

Start with [Install](setup/install.md) if you just want a theme, or
[Create a theme](usage/create.md) if you want to publish one.

## Setup

| Document | What it covers |
| --- | --- |
| [Install](setup/install.md) | Manual copy, update, uninstall |

## Usage

| Document | What it covers |
| --- | --- |
| [Create a theme](usage/create.md) | Palette design, wallpaper, preview, testing, checklist |

## Reference

| Document | What it covers |
| --- | --- |
| [Theme format](reference/theme-format.md) | Exact `theme.conf` grammar, ANSI roles, file rules |
| [Troubleshooting](reference/troubleshooting.md) | Theme does not appear, wrong colours, stale previews |

## Development

| Document | What it covers |
| --- | --- |
| [Architecture](development/architecture.md) | How a theme moves from this repo into Pwnbox |
| [Submit a theme](development/submit.md) | Fork, validation, gallery row, review criteria |
| [Contributing](../CONTRIBUTING.md) | Repository layout, style, testing |
| [Security policy](../SECURITY.md) | Reporting malicious or unsafe themes privately |

## At a glance

- **Install** a theme by copying it into `~/pwnbox/dotfiles/themes/`, then
  `git add` and `upd`.
- **Create** one by copying `themes/_template`.
- **Validate** with `python3 scripts/validate-theme.py --strict`.
- **Preview** it with a 16:9 screenshot of Pwnbox, saved as `preview.png`.
- **Select** it with `ALT + S -> THEME -> Custom` or `pwnbox-theme custom`.

## Conventions used here

- `~/pwnbox` means the Pwnbox flake checkout, the directory containing
  `flake.nix`. Replace it with your path.
- `<name>` means a theme folder name such as `aurora`, not the display name.
- `ALT + S` opens the Pwnbox theme and settings menu.
- Commands are run from the `Pwnbox-Themes` checkout unless stated otherwise.
- Colours are always six-digit hex (`#RRGGBB`).
