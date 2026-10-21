# Troubleshooting

## The theme does not appear in `ALT + S`

Check, in order:

1. **Was the folder staged?** The Pwnbox flake only sees files tracked by git.
   An untracked theme is silently invisible even after a rebuild.

   ```bash
   cd ~/pwnbox
   git status --short dotfiles/themes
   git add dotfiles/themes/<name>
   upd
   ```

2. **Is there a `theme.conf`?** Pwnbox ignores directories without one.

   ```bash
   ls -la ~/pwnbox/dotfiles/themes/<name>/theme.conf
   ```

3. **Did the rebuild actually run?** `upd` must finish without errors. A
   failed `nixos-rebuild` leaves the old generation active.

4. **Does home-manager link the folder?** After a successful rebuild:

   ```bash
   ls -la ~/.config/pwnbox/themes/
   ```

   The folder should be a link into the Nix store with the same name.

5. **Is the menu scrolled?** `ALT + S -> THEME -> Custom` shows one card per
   theme. Use the arrow keys or type to filter.

If the folder is a symlink outside the flake, or the checkout is read-only,
copy it into the flake and rebuild instead of editing the runtime link.

## The theme appears but the colours are partly grey

One or more palette keys are missing or misspelled, so Pwnbox falls back to
Monochrome for those slots.

```bash
python3 scripts/validate-theme.py --theme themes/<name> --strict
```

Common causes:

- `color10` ... `color15` not copied from the source palette.
- `background` or `foreground` missing.
- A key written as `Color4` or `colour4`; keys are lowercase and
  case-sensitive.
- An inline comment after a value:
  `background = #101014 # dark` is parsed as an invalid colour.

## The theme fails to apply with "Invalid colours"

A colour is present but not six-digit hex. Pwnbox rejects the whole theme
instead of falling back.

```bash
python3 scripts/validate-theme.py --theme themes/<name> --strict
```

Fix `#RGB`, `rgb()`, `#RRGGBBAA` or named colours to `#RRGGBB`.

## The picker card shows the wrong image

`preview.png` is not used by Pwnbox as the theme wallpaper. The card image is
the wallpaper pointed to by `wallpaper =`.

- Make sure `theme.conf` has an explicit `wallpaper = wallpaper.png`.
- If `wallpaper` is missing or points to a file that does not exist, Pwnbox
  falls back to the first image it finds. `preview.png` sorts before
  `wallpaper.png` and can win that fallback.
- A copied folder can contain `preview.png` too. Keep `wallpaper =` explicit
  so Pwnbox never has to fall back to the first image.

## The wallpaper is not applied

- Check the filename in `wallpaper =` matches the file exactly, including
  case.
- Pwnbox supports PNG, JPEG and WebP. If a format fails, convert it:

  ```bash
  magick input.avif themes/<name>/wallpaper.png
  ```

- If the theme is active while you replace the wallpaper, rebuild; activation
  re-applies the active custom theme's wallpaper.
- Try selecting the theme again:

  ```bash
  pwnbox-theme custom
  ```

## The preview thumbnail is stale

Thumbnails are cached in `~/.cache/pwnbox/theme/thumbs` and keyed on the
resolved wallpaper path plus its size and modification time. A rebuild
normally refreshes them. If it does not:

```bash
pwnbox-theme refresh
```

As a last resort, remove the cache and apply the theme again:

```bash
rm -rf ~/.cache/pwnbox/theme/thumbs
pwnbox-theme custom
```

## Some apps still show the old colours

Many apps update live; some read their theme only at startup:

| App | What to do |
| --- | --- |
| IDA Free / Pro | Restart IDA |
| Stremio Enhanced | Restart Stremio (apply the `pwnbox` theme once under Settings -> Themes) |
| Obsidian | Restart Obsidian or "Reload app without saving" |
| SimpleX | Restart SimpleX |
| Zen | Reload the browser or reopen it; site styles may need a reload |
| Signal, Element, Wire | Usually live; restart if a window was already open |
| Spotify, Equibop, Telegram | Usually live; restart if not |
| GTK apps | Close and reopen the app; log out if the whole desktop is stale |

To re-apply the current theme manually:

```bash
pwnbox-theme restore
```

## After logout and login the theme is gone

Pwnbox re-applies the saved theme with `pwnbox-theme restore` on login. If it
falls back to the default:

- Check that the theme folder still exists in `~/.config/pwnbox/themes/`.
- Check the saved name:

  ```bash
  cat ~/.cache/pwnbox/theme/custom-theme
  ```

- Re-select the theme, then log out and back in to verify.
- If the theme folder was removed, the saved name points at nothing. Pick
  another theme or run `pwnbox-theme monochrome`.

## The theme removes my fonts, bar style or transparency

It should not. A theme only supplies colours and a wallpaper. Bar style,
radius, fonts, blur, transparency, borders, shadows and animations are stored
separately in `~/.cache/pwnbox/theme/` and are not part of `theme.conf`.

If those settings reset, check whether the whole `~/.cache/pwnbox/theme`
directory was deleted, and re-apply them from `ALT + S`.

## Light themes look wrong

Pwnbox's generated UI is tuned for dark backgrounds. A light palette is
allowed, but derived borders, shadows and translucent surfaces can become
invisible or harsh. Before submitting:

- Check the bar, notifications, rofi, GTK apps and Neovim.
- Keep enough contrast between `background`, `foreground` and `color8`.
- Avoid a white `background` with a white `foreground` on the bar.

If an app is genuinely broken by a light palette, that is useful feedback for
Pwnbox; open an issue there with a screenshot.

## `git add` refuses the theme

The path may be ignored by the Pwnbox checkout's `.gitignore`:

```bash
cd ~/pwnbox
git check-ignore -v dotfiles/themes/<name>/theme.conf
```

Remove the matching ignore rule, or add an exception, then stage again.

## A folder with the same name already exists

If you are updating the same theme, replace the installed folder:

```bash
rm -rf ~/pwnbox/dotfiles/themes/<name>
cp -r themes/<name> ~/pwnbox/dotfiles/themes/

cd ~/pwnbox
git add -A dotfiles/themes/<name>
upd
```

If it is a different theme with a colliding folder name, rename one of them.
The folder name is the installed identity; the display `name` can be changed
freely.

## CI fails but the theme works locally

CI runs:

```bash
python3 scripts/validate-theme.py --strict
```

Strict mode turns warnings into errors. Typical causes:

- Missing `preview.png`.
- Incomplete 16-colour palette.
- Wallpaper or preview not 16:9, or below the minimum size.
- Contrast below 4.5:1.
- An extra file in the theme folder, such as a `.DS_Store`, `wallpaper.xcf`
  or a second image.
- A display name longer than 64 characters or duplicated by another theme.

Run the same command locally and fix the reported lines.

## Reporting a theme problem

Open an issue with:

- The theme name and a link to its folder.
- The Pwnbox commit (`git -C ~/pwnbox rev-parse --short HEAD`).
- What you expected, what happened, and a screenshot if useful.
- The output of the validator.

If the issue is about Pwnbox itself rather than a theme, report it in the
[Pwnbox issue tracker](https://github.com/kernelstub/Pwnbox/issues) instead.
