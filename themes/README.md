# Theme packages

Every directory in this folder that contains a `theme.conf` is a Pwnbox theme
package. The folder name is the installer identity; `name` in `theme.conf` is
the label shown in Pwnbox.

```text
themes/<name>/
├── theme.conf      # palette, required
├── wallpaper.png   # wallpaper, required
├── preview.png     # gallery image, required for submission
└── README.md       # author, licence and notes
```

The root [README](../README.md) has the gallery with previews and install
commands. `_template` is scaffolding and is not installable.

## Adding a theme

1. Copy the template:

   ```bash
   cp -r themes/_template themes/my-theme
   ```

2. Edit `theme.conf`, add a 16:9 wallpaper and generate `preview.png`:

   ```bash
   ./scripts/render-preview.sh my-theme
   ```

3. Validate:

   ```bash
   python3 scripts/validate-theme.py --theme themes/my-theme --strict
   ```

4. Install and test it in Pwnbox, then open a pull request:

   ```bash
   ./scripts/install-theme.sh my-theme --flake ~/pwnbox
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
