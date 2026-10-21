# Theme template

Copy this folder to start a new theme:

```bash
cp -r themes/_template themes/my-theme
```

Then:

1. Change `name` and every colour in `theme.conf`.
2. Replace `wallpaper.png` with your own 16:9 wallpaper.
3. Replace `preview.png` with a 16:9 screenshot of Pwnbox.
4. Update this README with your name and the artwork licence.
5. Run `python3 scripts/validate-theme.py --theme themes/my-theme --strict`.
6. Copy the folder into `~/pwnbox/dotfiles/themes/`, run `git add` and `upd`.

The template is scaffolding and is not part of the gallery. Its placeholder
wallpaper and preview are original and released under the Unlicense.

See [Create a theme](../../docs/usage/create.md) for the full walkthrough.
