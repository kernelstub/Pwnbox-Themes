# Create a theme

A Pwnbox custom theme is a fixed palette plus a wallpaper. There is nothing to
compile: Pwnbox reads `theme.conf` when you select the theme and applies the
colours to the bar, terminal, launcher, GTK apps, editors, browser and the
apps with live theming.

This guide takes you from an empty folder to a tested theme that is ready for
a pull request.

## Fixed themes, not pywal

Pwnbox has two theming modes:

- **Pywal** extracts a palette from any wallpaper at runtime. It is not a
  theme package.
- **Custom** uses a fixed `theme.conf` palette and a fixed wallpaper. This is
  what this repository ships.

A custom theme gives the same result on every machine and does not depend on
the wallpaper being present at runtime. Do not put pywal commands or generated
files in a theme package.

## Requirements

- A Pwnbox checkout for testing.
- This repository cloned:

  ```bash
  git clone https://github.com/kernelstub/Pwnbox-Themes.git
  cd Pwnbox-Themes
  ```

- Python 3 for the validator. It is already installed on Pwnbox.
- ImageMagick for `render-preview.sh` (`magick` or `convert`). It is also
  already installed on Pwnbox.
- An image editor or a wallpaper you have the right to redistribute.

## 1. Start from the template

```bash
cp -r themes/_template themes/aurora
```

Use a lowercase, hyphenated folder name: `aurora`, `solar-flare`,
`deep-space`. The folder name is the theme's identity in the installer and in
Pwnbox's saved state. The `name` key inside `theme.conf` is the display label;
it can contain spaces and capitals.

`_template` itself is scaffolding. The installer refuses folders that start
with `_`.

## 2. Choose the palette

Pwnbox themes use the standard 16-colour ANSI layout:

| Key | ANSI role | Typical use in a palette |
| --- | --- | --- |
| `color0` | black | terminal background, usually close to `background` |
| `color1` | red | errors, deletions, alerts |
| `color2` | green | success, additions, strings |
| `color3` | yellow | warnings, search highlights |
| `color4` | blue | directories, links, primary accent |
| `color5` | magenta | keywords, constants |
| `color6` | cyan | types, info, secondary accent |
| `color7` | white / light grey | normal terminal text |
| `color8` | bright black | comments, muted text |
| `color9` | bright red | bright errors and alerts |
| `color10` | bright green | bright success and strings |
| `color11` | bright yellow | bright warnings |
| `color12` | bright blue | bright links and accents |
| `color13` | bright magenta | bright keywords |
| `color14` | bright cyan | bright info |
| `color15` | bright white | emphasized text |

The important relationships:

- `background` and `foreground` carry most of the UI. Keep them readable.
- `color0` should be close to `background`, because many terminal programs
  paint their own background with `color0`.
- `color7` and `color15` should read clearly on `background` and `color0`.
- `color1` ... `color6` are normal accents; `color9` ... `color14` are their
  brighter counterparts. They do not have to be exact lightened copies, but
  they should feel related.
- Pwnbox derives bar accents, borders and editor colours from these slots, so
  a palette with 16 near-identical greys will look flat everywhere.

A contrast ratio of at least **4.5:1** between `foreground` and `background`
is required for submission. The validator checks it with the WCAG formula.
Aim for at least 3:1 for `color7` on `color0` and `color15` on `color8` as
well.

### Use pywal as a starting point

If you already have a wallpaper, pywal can suggest a palette:

```bash
wal -i wallpaper.png -n
jq -r '.colors | to_entries[] | "\(.key) = \(.value)"' ~/.cache/wal/colors.json
jq -r '.special | "background = \(.background)\nforeground = \(.foreground)\ncursor = \(.cursor)"' \
  ~/.cache/wal/colors.json
```

Copy the result into `theme.conf` and adjust it by hand. Pywal optimizes for a
wallpaper, not for readable UI, so check the contrast and fix muddy colours.
The theme itself must remain a fixed palette; do not make `theme.conf` depend
on pywal at runtime.

### Porting an existing palette

Ports of published palettes are welcome when the licence allows it. Credit the
original project and link to it in the theme's `README.md`. Do not call a port
official, and check for display-name collisions with Pwnbox's built-in themes
(`Pwnbox`, `Monochrome`, `Amoled`, `Beach`, `Catppuccin`, `Compose`,
`Gruvbox`, `Nord`). Distinct folder names can coexist, but two identical names
in the picker are confusing.

## 3. Write `theme.conf`

```ini
name = Aurora
wallpaper = wallpaper.png

background = #0b1020
foreground = #d7e0ff
cursor = #7de2ff

color0 = #0b1020
color1 = #ff6b81
color2 = #5ee6a8
color3 = #ffd166
color4 = #6ea8ff
color5 = #c792ea
color6 = #4dd6e8
color7 = #c6d0e8
color8 = #3b4468
color9 = #ff8fa0
color10 = #7cf0bc
color11 = #ffe08a
color12 = #8fbcff
color13 = #d8aef5
color14 = #74e4f2
color15 = #f2f6ff
```

Rules that matter:

- One `key = value` per line. Whitespace around `=` is trimmed.
- Only six-digit hex colours: `#RRGGBB`. `#RGB`, `rgb()`, named colours and
  eight-digit hex are rejected. Hex digits are case-insensitive.
- Comments must be on their own line and start with `#` or `;`. Pwnbox does
  not strip inline comments, so `background = #101014 # dark` is invalid.
- Keys are lowercase and case-sensitive. Do not repeat a key.
- `wallpaper` is a filename in the theme folder. No absolute paths, no `..`,
  no subdirectories.
- `name`, `wallpaper`, `background` and `foreground` are required by this
  repository. A submission also needs all 16 `colorN` keys.

The complete grammar and fallback rules are in the
[theme format reference](../reference/theme-format.md).

## 4. Add the wallpaper

Put the image in the theme folder and set `wallpaper =` to its filename:

```bash
cp ~/Pictures/aurora.png themes/aurora/wallpaper.png
```

Requirements:

- 16:9 aspect ratio. 2560x1440 is the recommended size; 1920x1080 is the
  minimum.
- PNG or JPEG is safest; WebP works in Pwnbox.
- At most 20 MiB in this repository.
- No text, logos or watermarks that make the desktop look accidental.
- Enough calm space for the bar and windows. A very busy image makes a
  transparent bar unreadable.
- You must have the right to redistribute it. Record the author and licence
  in `themes/<name>/README.md`.

Pwnbox uses this image as the theme's picker thumbnail, so it is the first
thing people see. Pick something that represents the palette.

## 5. Add a preview

`preview.png` is the gallery image. It is required for submissions and is not
copied into Pwnbox by the installer.

Generate a consistent palette card from the wallpaper and the 16 colours:

```bash
./scripts/render-preview.sh aurora
```

Or use a real screenshot of Pwnbox with the theme active:

1. Install the theme and select it.
2. Take a screenshot with `PRINT` (clipboard), `SUPER + SHIFT + S` (region) or
   `SUPER + SHIFT + R` (save).
3. Crop and resize to 16:9, for example with ImageMagick:

   ```bash
   magick screenshot.png -resize 1280x720^ -gravity center \
     -extent 1280x720 themes/aurora/preview.png
   ```

4. Remove or blur hostnames, IP addresses, usernames, chat names and anything
   else private. Screenshots are published on GitHub.

Recommended: 1280x720, PNG, 16:9. A palette card is perfectly acceptable and
is what the maintainers use for the example themes.

## 6. Validate

```bash
python3 scripts/validate-theme.py --theme themes/aurora --strict
```

Strict mode is what CI runs. It requires the complete palette, a wallpaper,
a preview, only allowed files, and treats warnings as errors. Fix everything
it reports before opening a pull request.

To validate the whole repository:

```bash
python3 scripts/validate-theme.py --strict
```

## 7. Install and test in Pwnbox

```bash
./scripts/install-theme.sh aurora --flake ~/pwnbox
```

The installer validates the theme, copies `theme.conf` and the wallpaper,
stages the folder, and rebuilds. Then select it:

```text
ALT + S -> THEME -> Custom -> Aurora
```

Check at least:

- [ ] The picker card shows the right wallpaper and display name.
- [ ] The Quickshell bar, notifications and control center use the palette.
- [ ] `kitty` opens with readable colours.
- [ ] The launcher (`ALT + SPACE`) and `ALT + S` menus are readable.
- [ ] A GTK app (Files, Settings) follows the theme.
- [ ] Hyprland window borders are visible.
- [ ] Neovim and Zed are readable; syntax highlights are distinguishable.
- [ ] Zen browser chrome and pages are readable.
- [ ] Spotify, Equibop (Discord), Telegram, Signal, Element and Wire update
      if you use them. Some apps need a restart; see
      [Troubleshooting](../reference/troubleshooting.md).
- [ ] After a logout and login, the theme is restored automatically.
- [ ] The wallpaper still looks good behind translucent windows.

If an app does not pick up the change, restart it. Some apps only read their
theme file at startup (IDA, Stremio Enhanced, Obsidian, SimpleX). Pwnbox's
theme docs list which apps update live.

## 8. Submit

When the theme is installed, tested and committed locally:

```bash
git checkout -b theme/aurora
git add themes/aurora README.md
git commit -m "theme: add aurora"
git push origin theme/aurora
```

Open a pull request against `main`. Add a row to the gallery in the root
`README.md` with the preview and install command. The full review process is
in [Submit a theme](../development/submit.md).

## Design guidelines

- **One idea per theme.** A palette with one dominant hue and two accents
  looks more deliberate than six unrelated bright colours.
- **Dark is the default, but light works.** Pwnbox's derived UI is tuned for
  dark backgrounds; if you make a light theme, test every app and watch for
  white-on-white text.
- **Contrast beats saturation.** A slightly desaturated accent stays readable
  in the bar and editor; pure neon often turns into glare.
- **Keep ANSI distinct.** Red, green, yellow and their bright variants should
  be distinguishable in a terminal, including for common colour-vision
  deficiencies. Do not rely on hue alone for critical UI.
- **Match the wallpaper.** The wallpaper should feel like the palette, not
  like a stock photo with a recoloured bar on top.
- **Less detail in the wallpaper.** Abstract gradients, landscapes with soft
  areas and dark textures work better than high-contrast patterns.
- **Short names.** Display names longer than about 24 characters are
  truncated or cramped in the picker.
- **No personal branding.** Do not use a real company's name or logo unless
  you have permission. Palette names are fine when credited.

## Checklist

- [ ] Folder is `themes/<lowercase-name>/`.
- [ ] `theme.conf` has `name`, `wallpaper`, `background`, `foreground` and
      all 16 `colorN` keys.
- [ ] Every colour is `#RRGGBB`.
- [ ] `wallpaper` points to a file in the folder.
- [ ] Wallpaper is 16:9, at least 1920x1080, at most 20 MiB.
- [ ] `preview.png` exists, is 16:9, and contains no personal information.
- [ ] `README.md` credits the author and the wallpaper licence.
- [ ] Validator passes with `--strict`.
- [ ] Theme was installed and tested in Pwnbox.
- [ ] Gallery row added to the root `README.md`.
- [ ] One theme per pull request.
