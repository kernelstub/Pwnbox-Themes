# Theme packages

Every directory in this folder that contains a `theme.conf` is a Pwnbox theme
package. The folder name is the theme's identity in Pwnbox's saved state;
`name` in `theme.conf` is the label shown in the picker.

```text
themes/<name>/
├── theme.conf      # palette, required
├── wallpaper.png   # wallpaper, required
├── preview.png     # gallery image, required for submission
└── README.md       # author, licence and notes
```

The root [README](../README.md) has the gallery with previews and install
instructions. `_template` is scaffolding; copy it to a new name before using
it.

## Adding a theme

1. Copy the template:

   ```bash
   cp -r themes/_template themes/my-theme
   ```

2. Edit `theme.conf`, add a 16:9 wallpaper and a 16:9 screenshot called
   `preview.png`.

3. Validate:

   ```bash
   python3 scripts/validate-theme.py --theme themes/my-theme --strict
   ```

4. Copy it into Pwnbox, test it, then open a pull request:

   ```bash
   cp -r themes/my-theme ~/pwnbox/dotfiles/themes/
   cd ~/pwnbox
   git add dotfiles/themes/my-theme
   upd
   ```

Read [Create a theme](../docs/usage/create.md) and the
[format reference](../docs/reference/theme-format.md) before submitting.

## Rules

- Folder names are lowercase, hyphenated and unique: `deep-space`, not
  `Deep Space`.
- The complete 16-colour palette is required.
- Colours are `#RRGGBB` only.
- The wallpaper must be in the folder and named by `wallpaper =`.
- `preview.png` must not contain personal information.
- Theme packages contain data only: no scripts, binaries, symlinks or
  absolute paths.
- Credit the palette and wallpaper sources in the theme's `README.md`, and
  state the artwork licence.
