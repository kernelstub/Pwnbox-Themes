# Security policy

This repository distributes theme data for Pwnbox: `theme.conf` files,
wallpapers and preview images. It does not ship installers or hooks that run
at login; the only tooling is the package validator.

## Supported versions

Only the latest commit of the `main` branch is supported. There are no
formal releases.

## In scope

- A theme package that can execute code, escape its folder, write outside the
  theme directory or otherwise affect the host beyond changing colours and a
  wallpaper.
- A `wallpaper` path that traverses directories or points outside the package.
- A package containing scripts, binaries, symlinks or executable files,
  especially when hidden among images.
- A vulnerability in `scripts/validate-theme.py` (for example path handling
  that lets a crafted theme read or write outside its package).
- CI or repository automation that can be tricked by a contributed file.
- Stolen or mislicensed artwork, or previews containing private data. These
  are handled as community/licensing issues rather than software
  vulnerabilities, but report them privately if the content is sensitive.

## Out of scope

- Vulnerabilities in Pwnbox itself. Report those in the
  [Pwnbox repository](https://github.com/kernelstub/Pwnbox/issues).
- Vulnerabilities in image decoders, ImageMagick, pywal, Hyprland, Quickshell
  or other upstream software. Report them upstream; open a regular issue here
  if a theme triggers one.
- A theme that looks bad, has poor contrast or is not to your taste. Use a
  normal issue or PR.
- The fact that a wallpaper can contain any image. Themes are user-chosen
  data; review previews before installing if that matters to you.

## Reporting a vulnerability

Do **not** open a public issue for something that can compromise a user.

Use GitHub's private reporting:

1. Go to **Security -> Report a vulnerability** in this repository.
2. Describe the affected file, the impact, and a minimal reproducer if you
   have one.
3. State whether the issue affects the validator, CI, or a specific theme
   package.

You can also email [kern@skuntir.com](mailto:kern@skuntir.com) with the
subject `pwnbox themes security`. PGP is not required.

This is a small community project: expect a best-effort response, no SLA and
no bug bounty. Fixes are committed to `main` as soon as they are ready.

## Acknowledgements

Reporters are credited in the commit and advisory when a report leads to a
fix, unless they ask to stay anonymous.
