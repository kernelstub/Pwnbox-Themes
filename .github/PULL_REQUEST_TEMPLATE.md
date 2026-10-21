## What this PR does

Describe the change and why it is needed.

## Theme submission

Fill this in for a new theme; skip it for docs or tooling changes.

- Theme: `<name>`
- Author: `@handle`
- Palette source: original / ported from ...
- Wallpaper source and licence: ...

- [ ] The folder is `themes/<name>/` with a unique lowercase slug
- [ ] `theme.conf` has `name`, `wallpaper`, `background`, `foreground` and all
      16 `colorN` keys, all in `#RRGGBB`
- [ ] The wallpaper is 16:9, at least 1920x1080, and in the theme folder
- [ ] `preview.png` is 16:9 and contains no personal information
- [ ] `themes/<name>/README.md` credits the author, palette and wallpaper
      licence
- [ ] A gallery row was added to the root `README.md`
- [ ] The theme was copied into Pwnbox and tested
- [ ] `python3 scripts/validate-theme.py --strict` passes
- [ ] Only this theme (and its gallery row) changed in this PR

## Code or docs changes

- [ ] `python3 scripts/validate-theme.py --strict` passes if theme files
      changed
- [ ] Docs updated where behaviour changed
- [ ] No emojis in code, docs or the commit message

## Related issues

Closes #
