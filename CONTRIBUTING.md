# Contributing

Thanks for wanting to contribute. This repository collects community themes
for [Pwnbox](https://github.com/kernelstub/Pwnbox). Themes that are tested,
licensed and readable are welcome, and so are fixes to the docs and the
validator.

## Ways to contribute

- Add a new theme. Start with [Create a theme](docs/usage/create.md) and read
  [Submit a theme](docs/development/submit.md).
- Fix or update an existing theme (with the original author's agreement when
  possible).
- Improve the validator or the documentation.
- Improve the documentation.
- Report a bug or an unsafe theme privately, per the
  [security policy](SECURITY.md).

## Workflow

1. Look through the [open issues](https://github.com/kernelstub/Pwnbox-Themes/issues)
   or open one to discuss a larger change.
2. Fork the repository and work on a branch.
3. Open a pull request against `main` and fill in the template.

Small, focused pull requests are easier to review. One theme per PR.

## Where things live

The full layout and theme lifecycle are in
[docs/development/architecture.md](docs/development/architecture.md). In short:

```text
.
├── themes/                 # theme packages, one directory per theme
│   └── _template/          # scaffolding for a new theme
├── scripts/
│   └── validate-theme.py   # theme package validator (CI)
├── docs/                   # the manual
├── assets/                 # repository banner
└── .github/                # issue templates, PR template, CI
```

## Theme contributions

A theme package contains:

- `theme.conf` with a complete 16-colour palette.
- A 16:9 wallpaper in the same folder.
- `preview.png`, 16:9, with no personal data.
- `README.md` with author and artwork licence.

The exact rules are in [docs/reference/theme-format.md](docs/reference/theme-format.md).
The validator is the source of truth for CI.

## Style

- Plain text, **no emojis**, in code, docs and commit messages.
- Python: standard library only, Python 3.9 or newer.
- Commit messages: short lowercase-prefix summary, optional body
  (`theme: add aurora`, `docs: fix install example`, `fix: validator …`).
- Keep generated files out of the repository except theme assets that are
  part of a package (`wallpaper.*`, `preview.png`).
- Do not reformat unrelated files in a theme PR.

## Testing

Before opening a PR:

```bash
python3 scripts/validate-theme.py --strict

# copy it into a real Pwnbox checkout, rebuild and select it
cp -r themes/<name> ~/pwnbox/dotfiles/themes/
cd ~/pwnbox
git add dotfiles/themes/<name>
upd
```

CI runs the validator. A theme that only works on the author's machine will be
sent back for testing.

## Licence

This repository is released into the public domain under the
[Unlicense](LICENSE). By contributing you agree to release your contributions
under the same terms. Artwork may carry its own licence; state it in the
theme's `README.md` and make sure it permits redistribution.
