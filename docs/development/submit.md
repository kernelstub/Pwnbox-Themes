# Submit a theme

Thank you for contributing. This repository is curated: a theme is merged
when it is safe, self-contained, readable and tested on the current Pwnbox.

## Before you start

- Build and test the theme as described in [Create a theme](../usage/create.md).
- Read the [theme format](../reference/theme-format.md). The validator
  enforces it; the review does too.
- Make sure you have the right to redistribute the wallpaper. If it came from
  a wallpaper site, check the licence; "found on the internet" is not enough.
- Credit the original palette if you ported one.
- Keep it to one theme per pull request. Fixes to existing themes can be a
  separate PR.

## 1. Fork and branch

```bash
# fork the repository on GitHub, then:
git clone https://github.com/<you>/Pwnbox-Themes.git
cd Pwnbox-Themes
git checkout -b theme/aurora
```

## 2. Add the theme

```bash
cp -r themes/_template themes/aurora
$EDITOR themes/aurora/theme.conf
cp /path/to/wallpaper.png themes/aurora/wallpaper.png
./scripts/render-preview.sh aurora
```

Add `themes/aurora/README.md`:

```markdown
# Aurora

Author: @your-handle
Palette: original
Wallpaper: original, CC0-1.0
Theme config: Unlicense
```

Use a real name or handle and a real licence. If the wallpaper is CC BY, name
the author and link to the source.

## 3. Add the gallery row

Add a row to the `Themes` table in the root `README.md`:

```markdown
| <a href="themes/aurora"><img src="themes/aurora/preview.png" width="360" alt="Aurora preview"></a> | **Aurora**<br>One-line description.<br><sub>by [@your-handle](https://github.com/your-handle)</sub> | `./scripts/install-theme.sh aurora` |
```

Add the row at the end of the table; maintainers may reorder it later. Do not
edit other people's rows in the same PR.

## 4. Validate

```bash
python3 scripts/validate-theme.py --theme themes/aurora --strict
python3 scripts/validate-theme.py --strict
```

The first command checks your theme. The second checks the whole repository,
including duplicate display names. Both must pass.

Optional checks for tooling changes:

```bash
bash -n scripts/install-theme.sh scripts/render-preview.sh
shellcheck scripts/install-theme.sh scripts/render-preview.sh
```

## 5. Test in Pwnbox

```bash
./scripts/install-theme.sh aurora --flake ~/pwnbox
```

Select `ALT + S -> THEME -> Custom -> Aurora` and walk through the checklist
at the end of [Create a theme](../usage/create.md#checklist). At minimum:

- The theme appears with the right name and wallpaper.
- The bar, terminal, launcher and a GTK app are readable.
- Neovim and Zed have distinguishable syntax colours.
- The theme survives a logout and login.
- No personal information is visible in the preview or wallpaper.

Take a screenshot if you can. Reviewers may ask for one.

## 6. Commit and open the pull request

```bash
git add themes/aurora README.md
git commit -m "theme: add aurora"
git push origin theme/aurora
```

Open the pull request against `main` and fill in the template. In the
description, include:

- The theme name and a one-line description.
- The palette source (original, ported, generated from the wallpaper).
- The wallpaper source and licence.
- A screenshot of the theme in Pwnbox, if available.
- Whether you tested a light or dark variant, if relevant.

## Review criteria

Maintainers check:

- **Format.** The validator passes in strict mode; the gallery row is correct.
- **Completeness.** All 16 colours, a wallpaper, a preview and a README with
  credit and licence.
- **Readability.** Foreground/background contrast is at least 4.5:1, ANSI
  colours are distinguishable, and the bar and editor remain usable.
- **Consistency.** The wallpaper and palette belong together; the preview does
  not misrepresent the theme.
- **Originality and licensing.** Ports are credited and permitted; copied
  artwork is not acceptable without a licence.
- **Safety.** No scripts, binaries, symlinks, absolute paths, network access
  or personal data.
- **Scope.** One theme, no unrelated changes, no edits to other themes.
- **Names.** The folder is a unique lowercase slug; the display name does not
  collide with another theme or imply official status.

A maintainer may suggest palette tweaks, a different wallpaper crop or a
renamed display label. These are normal review comments, not rejection.

## Updating an existing theme

Open a PR that changes only that theme folder and, if necessary, its gallery
row. Explain what changed. If the change is a visual refresh, include a new
preview. Users who installed the old version can update with:

```bash
./scripts/install-theme.sh <name> --force
```

## Removal and maintainership

If a theme is unmaintained, breaks with current Pwnbox, or its licence is
disputed, maintainers may remove it or mark it unmaintained. Because the
repository is Unlicense, the configuration can be adopted, but the artwork
licence still applies. Talk to the original author first when possible.

## Style

- Plain text, no emojis.
- Commit messages: `theme: add aurora`, `theme: update aurora wallpaper`,
  `docs: clarify wallpaper rules`, `fix: validator …`.
- Keep diffs focused. Do not reformat unrelated files.
- Update the docs when you change the format or the tooling.

## Licence

By opening a pull request you agree to release your theme configuration under
the [Unlicense](../../LICENSE) and confirm that you have the right to
redistribute the wallpaper and preview. State any separate artwork licence in
the theme's `README.md`.
