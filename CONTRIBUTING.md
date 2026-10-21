# Contributing

Thanks for wanting to contribute. This repository collects community themes
for [Pwnbox](https://github.com/kernelstub/Pwnbox). Themes that are tested,
licensed and readable are welcome, and so are fixes to the docs, validator
and installer.

## Ways to contribute

- Add a new theme. Start with [Create a theme](docs/usage/create.md) and read
  [Submit a theme](docs/development/submit.md).
- Fix or update an existing theme (with the original author's agreement when
  possible).
- Improve the validator, installer or preview renderer.
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
│   ├── _template/          # scaffolding, not installable
│   ├── midnight/           # example theme
│   └── ember/              # example theme
├── scripts/
│   ├── install-theme.sh    # install a theme into a Pwnbox checkout
│   ├── validate-theme.py   # theme package validator (CI)
│   └── render-preview.sh   # generate a gallery preview card
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
- Shell: `bash -n scripts/*.sh` and `shellcheck scripts/*.sh` must pass.
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
bash -n scripts/install-theme.sh scripts/render-preview.sh
shellcheck scripts/install-theme.sh scripts/render-preview.sh

# install and select the theme in a real Pwnbox checkout
./scripts/install-theme.sh <name> --flake ~/pwnbox
```

CI runs the validator, the shell syntax checks and ShellCheck. A theme that
only works on the author's machine will be sent back for testing.

## Licence

This repository is released into the public domain under the
[Unlicense](LICENSE). By contributing you agree to release your contributions
under the same terms. Artwork may carry its own licence; state it in the
theme's `README.md` and make sure it permits redistribution.
