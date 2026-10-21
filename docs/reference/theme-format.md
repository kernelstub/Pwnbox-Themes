# Theme format reference

This is the canonical specification for a theme package in this repository.
Pwnbox's own parser is deliberately small; the rules below are the subset this
community repository accepts and validates.

## Package layout

```text
themes/<name>/
├── theme.conf      # required
├── wallpaper.png   # required (PNG, JPEG or WebP)
├── preview.png     # required for submission
├── README.md       # optional, recommended for credit and licence
└── LICENSE         # optional, if the artwork is not Unlicense/CC0
```

`<name>` is the folder name. It must be unique, lowercase and hyphenated:
`^[a-z0-9]+(-[a-z0-9]+)*$`. The folder `_template` is the only exception; it is
scaffolding and is not a published theme.

The display name comes from `name` in `theme.conf` and may contain spaces,
capitals and punctuation. Two themes in this repository may not use the same
display name, because the Pwnbox picker would show two identical labels.

Everything in the folder must be data. Scripts, binaries, symlinks, absolute
paths, network references and subdirectories are not allowed.

## `theme.conf` grammar

- INI-style `key = value`, one entry per line.
- Leading and trailing whitespace around the key and value is trimmed.
- Blank lines are ignored.
- A line whose first non-whitespace character is `#` or `;` is a comment.
- A line without `=` is ignored by Pwnbox. The validator reports it.
- Keys are lowercase and case-sensitive.
- If a key is repeated, Pwnbox uses the first occurrence. The validator
  rejects duplicates.
- Inline comments are not supported. `background = #101014 # dark` is not a
  colour and will make the theme fail to apply.
- Values are not quoted. `name = "Aurora"` would display the quotes.

## Keys

| Key | Required | Default in Pwnbox | Meaning |
| --- | --- | --- | --- |
| `name` | yes | Folder name | Label shown in the theme picker |
| `wallpaper` | yes | First image in the folder, then the bundled wallpaper | Wallpaper filename, relative to the theme folder |
| `background` | yes | Monochrome `background` | Window and terminal background |
| `foreground` | yes | Monochrome `foreground` | Main text colour |
| `cursor` | no | `foreground` | Text cursor colour |
| `color0` ... `color15` | yes | Monochrome palette | The 16-colour ANSI palette |

For this repository, "required" is enforced by `--strict`. Pwnbox itself is
more forgiving: a missing colour falls back to the built-in Monochrome
palette. A colour that is present but malformed is different: Pwnbox rejects
the whole theme and shows "Invalid colours". Always run the validator.

Pwnbox ignores unknown keys. The validator warns about them, and strict mode
rejects them. Do not add non-standard keys to `theme.conf`; put notes in the
theme's `README.md` instead.

## Colour values

The only accepted format is six-digit hex:

```text
#RRGGBB
```

- The leading `#` is required.
- Exactly six hex digits. `#RGB`, `#RRGGBBAA`, `rgb(…)`, `hsl(…)` and named
  colours are not supported.
- Hex digits are case-insensitive; Pwnbox normalizes the case.
- No transparency. Opacity and blur are user settings in `ALT + S`, not theme
  properties.

## Colour roles

| Key | ANSI role | Notes |
| --- | --- | --- |
| `color0` | Black | Often the terminal background; keep it close to `background` |
| `color1` | Red | Errors, deletions, alerts |
| `color2` | Green | Success, additions, strings |
| `color3` | Yellow | Warnings, search |
| `color4` | Blue | Directories, links, a common accent |
| `color5` | Magenta | Keywords, constants |
| `color6` | Cyan | Types, information |
| `color7` | White / light grey | Normal terminal text |
| `color8` | Bright black | Comments and muted text |
| `color9` | Bright red | Bright alerts |
| `color10` | Bright green | Bright success |
| `color11` | Bright yellow | Bright warnings |
| `color12` | Bright blue | Bright links |
| `color13` | Bright magenta | Bright keywords |
| `color14` | Bright cyan | Bright information |
| `color15` | Bright white | Emphasized text |

Pwnbox passes these 16 colours to pywal, which feeds the generated Quickshell,
kitty, rofi, fuzzel, GTK, Hyprland, Neovim, Zed and app-specific themes. The
bar, borders and accents are derived from the palette, so the slots should be
cohesive rather than 16 independent colours.

## Wallpaper rules

- Must be a regular file in the theme folder, named by `wallpaper` with no
  directory component.
- Allowed extensions: `.png`, `.jpg`, `.jpeg`, `.webp`.
- 16:9 aspect ratio. 2560x1440 recommended, 1920x1080 minimum.
- At most 20 MiB.
- It is used as the desktop wallpaper and as the picker thumbnail. It should
  represent the palette.
- No personal data in the image. A wallpaper is published with the theme.

Pwnbox also supports absolute wallpaper paths and subdirectories, but this
repository forbids both so a package stays self-contained and safe to copy.

## Preview rules

- `preview.png` in the theme folder, used only by this repository's gallery.
  Pwnbox does not need it at runtime.
- 16:9 aspect ratio; 1280x720 recommended.
- At most 10 MiB.
- No hostnames, IP addresses, usernames, chat names, keys or other private
  data. Previews are committed to a public repository.
- A 16:9 palette card made in your image editor is acceptable. A real
  screenshot of the theme in Pwnbox is better.

The file must be named exactly `preview.png`. Other preview formats are not
part of the package layout.

## README and licensing

A theme's `README.md` is not read by Pwnbox. It exists so users and reviewers
know where the theme came from. Recommended contents:

```markdown
# Aurora

Author: @your-handle
Palette: original
Wallpaper: original, CC0-1.0
Theme config: Unlicense
```

If you port a palette or use a wallpaper with a different licence, state it
and link to the source. The repository itself is Unlicense, but that does not
override the licence of artwork you did not create.

## Pwnbox fallback behaviour

Useful to know when debugging, not a target for submissions:

1. Missing `name` -> folder name.
2. Missing `cursor` -> `foreground`.
3. Missing or unreadable `wallpaper` -> first image in the folder (glob
   order: png, jpg, jpeg, webp), then the bundled default wallpaper.
4. Missing `background`, `foreground` or `colorN` -> the corresponding
   Monochrome palette colour.
5. Invalid hex in any present colour -> the entire theme is rejected with
   "Invalid colours".
6. A folder without `theme.conf` is ignored by Pwnbox.

## What the validator enforces

`scripts/validate-theme.py` checks the package structure and palette. In
`--strict` mode, warnings become errors. That is what CI runs.

Always enforced:

- `theme.conf` exists, is a regular file and parses.
- `name`, `wallpaper`, `background`, `foreground` are present and non-empty.
- Every present colour is six-digit hex.
- `wallpaper` is a safe relative filename, exists, has an allowed extension
  and is at most 20 MiB.
- `preview.png`, if present, is a valid PNG and is at most 10 MiB.
- No symlinks.
- `foreground` on `background` has a contrast ratio of at least 3:1.
- Display names are unique across the repository.
- Folder names match the slug rules (except `_template`).

Required by `--strict`:

- All 16 `colorN` keys are present.
- `preview.png` is present, is a regular file and is 16:9.
- The wallpaper is 16:9 and at least 1920x1080 (when the dimensions can be
  read).
- Contrast between `foreground` and `background` is at least 4.5:1.
- No executable files.
- Only allowed files are present: `theme.conf`, the wallpaper, `preview.png`,
  `README.md`, `LICENSE`, `LICENSE.md` or `LICENSE.txt`.
- No unknown keys and no non-theme files.
- Display names are at most 64 characters.

If the validator cannot read image dimensions (for example, some WebP
variants), it skips the dimension checks rather than failing.

## Compatibility

The format is the same one Pwnbox uses for `dotfiles/themes/<name>/` and is
stable across current Pwnbox releases. There is no version field: a theme is
just a `theme.conf` and an image. Test with the current `main` branch of
Pwnbox before submitting. If Pwnbox changes the format, this document and the
validator are updated together.
