#!/usr/bin/env python3
"""Validate Pwnbox theme packages.

The default mode checks every directory under themes/. Pass --theme to check a
single package. --strict turns warnings into errors and is what CI runs.
"""

from __future__ import annotations

import argparse
import re
import struct
import sys
from dataclasses import dataclass, field
from pathlib import Path
from typing import Dict, List, Optional, Tuple

REPO_ROOT = Path(__file__).resolve().parent.parent
THEMES_ROOT = REPO_ROOT / "themes"

PALETTE_KEYS = [f"color{i}" for i in range(16)]
COLOR_KEYS = ["background", "foreground", "cursor", *PALETTE_KEYS]
KNOWN_KEYS = {"name", "wallpaper", *COLOR_KEYS}
REQUIRED_KEYS = ("name", "wallpaper", "background", "foreground")

HEX_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
SLUG_RE = re.compile(r"^[a-z0-9]+(?:-[a-z0-9]+)*$")
IMAGE_EXTENSIONS = {".png", ".jpg", ".jpeg", ".webp"}
ALLOWED_FILES = {
    "theme.conf",
    "preview.png",
    "README.md",
    "LICENSE",
    "LICENSE.md",
    "LICENSE.txt",
}

MAX_WALLPAPER_BYTES = 20 * 1024 * 1024
MAX_PREVIEW_BYTES = 10 * 1024 * 1024
MAX_NAME_LENGTH = 64


@dataclass
class Check:
    folder: str
    path: Path
    values: Dict[str, str] = field(default_factory=dict)
    notes: List[str] = field(default_factory=list)
    warnings: List[str] = field(default_factory=list)
    errors: List[str] = field(default_factory=list)

    @property
    def display_name(self) -> str:
        return self.values.get("name") or self.folder

    def ok(self, message: str) -> None:
        self.notes.append(message)

    def warn(self, message: str) -> None:
        self.warnings.append(message)

    def error(self, message: str) -> None:
        self.errors.append(message)


def human_size(size: int) -> str:
    if size >= 1024 * 1024:
        return f"{size / (1024 * 1024):.1f} MiB"
    if size >= 1024:
        return f"{size / 1024:.0f} KiB"
    return f"{size} B"


def parse_conf(path: Path, check: Check) -> None:
    try:
        text = path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        check.error("theme.conf is not valid UTF-8")
        return
    except OSError as exc:
        check.error(f"cannot read theme.conf: {exc}")
        return

    if text.startswith("\ufeff"):
        text = text[1:]

    seen: Dict[str, int] = {}
    for lineno, raw in enumerate(text.splitlines(), 1):
        line = raw.strip()
        if not line or line.startswith("#") or line.startswith(";"):
            continue
        if "=" not in line:
            check.warn(f"theme.conf:{lineno}: not a key = value line")
            continue

        key, value = line.split("=", 1)
        key = key.strip()
        value = value.strip()

        if not key:
            check.error(f"theme.conf:{lineno}: empty key")
            continue

        if key.lower() in KNOWN_KEYS and key != key.lower():
            check.error(
                f'theme.conf:{lineno}: key "{key}" must be lowercase '
                f'("{key.lower()}")'
            )
            continue

        if key in seen:
            check.error(
                f'theme.conf:{lineno}: duplicate key "{key}" '
                f"(first used on line {seen[key]})"
            )
            continue

        seen[key] = lineno
        check.values[key] = value

    check.ok(f"theme.conf parsed ({len(check.values)} keys)")


def parse_hex(value: str) -> Optional[Tuple[int, int, int]]:
    if not HEX_RE.fullmatch(value):
        return None
    return (
        int(value[1:3], 16),
        int(value[3:5], 16),
        int(value[5:7], 16),
    )


def luminance(rgb: Tuple[int, int, int]) -> float:
    def channel(value: int) -> float:
        value = value / 255.0
        if value <= 0.04045:
            return value / 12.92
        return ((value + 0.055) / 1.055) ** 2.4

    r, g, b = (channel(value) for value in rgb)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast_ratio(first: Tuple[int, int, int], second: Tuple[int, int, int]) -> float:
    a = luminance(first)
    b = luminance(second)
    lighter = max(a, b)
    darker = min(a, b)
    return (lighter + 0.05) / (darker + 0.05)


def image_magic_ok(path: Path, suffix: str) -> bool:
    """Check that the file header matches the extension."""
    try:
        with path.open("rb") as handle:
            head = handle.read(16)
    except OSError:
        return False
    if suffix == ".png":
        return head.startswith(b"\x89PNG\r\n\x1a\n")
    if suffix in (".jpg", ".jpeg"):
        return head.startswith(b"\xff\xd8\xff")
    if suffix == ".webp":
        return head[:4] == b"RIFF" and head[8:12] == b"WEBP"
    return False


def image_size(path: Path) -> Optional[Tuple[int, int]]:
    """Read PNG, JPEG or WebP (VP8X) dimensions without external tools."""
    try:
        with path.open("rb") as handle:
            head = handle.read(1024 * 1024)
    except OSError:
        return None

    if head.startswith(b"\x89PNG\r\n\x1a\n") and len(head) >= 24:
        width, height = struct.unpack(">II", head[16:24])
        return int(width), int(height)

    if head.startswith(b"\xff\xd8"):
        index = 2
        while index + 3 < len(head):
            if head[index] != 0xFF:
                index += 1
                continue
            marker = head[index + 1]
            index += 2

            if marker in (0xD8, 0xD9) or 0xD0 <= marker <= 0xD7:
                continue
            if marker == 0x01:
                continue
            if index + 2 > len(head):
                break

            length = int.from_bytes(head[index : index + 2], "big")
            if length < 2:
                break

            if marker in (
                0xC0,
                0xC1,
                0xC2,
                0xC3,
                0xC5,
                0xC6,
                0xC7,
                0xC9,
                0xCA,
                0xCB,
                0xCD,
                0xCE,
                0xCF,
            ):
                if index + 7 <= len(head):
                    height = int.from_bytes(head[index + 3 : index + 5], "big")
                    width = int.from_bytes(head[index + 5 : index + 7], "big")
                    return width, height
                break

            index += length
        return None

    if (
        head[:4] == b"RIFF"
        and head[8:12] == b"WEBP"
        and head[12:16] == b"VP8X"
        and len(head) >= 30
    ):
        width = int.from_bytes(head[24:27], "little") + 1
        height = int.from_bytes(head[27:30], "little") + 1
        return width, height

    return None


def check_aspect(check: Check, label: str, width: int, height: int) -> None:
    if height <= 0:
        return
    ratio = width / height
    target = 16 / 9
    if abs(ratio - target) > target * 0.03:
        check.warn(
            f"{label} is {width}x{height} ({ratio:.2f}:1), expected 16:9"
        )


def check_wallpaper(check: Check, theme_dir: Path, wallpaper: str) -> None:
    if not wallpaper:
        return

    if wallpaper.startswith(".") or "/" in wallpaper or "\\" in wallpaper:
        check.error(
            "wallpaper must be a plain filename in the theme folder "
            "(no directories, absolute paths or dotfiles)"
        )
        return
    if wallpaper == "preview.png":
        check.error("wallpaper cannot be preview.png; add a separate wallpaper")
        return

    suffix = Path(wallpaper).suffix.lower()
    if suffix not in IMAGE_EXTENSIONS:
        check.error(
            f'wallpaper "{wallpaper}" must be PNG, JPEG or WebP'
        )
        return

    path = theme_dir / wallpaper
    if path.is_symlink():
        check.error(f'wallpaper "{wallpaper}" is a symlink; use a regular file')
        return
    if not path.is_file():
        check.error(f'wallpaper "{wallpaper}" does not exist in the theme folder')
        return
    if not image_magic_ok(path, suffix):
        check.error(
            f'wallpaper "{wallpaper}" does not look like a {suffix.lstrip(".")} image'
        )
        return

    try:
        size = path.stat().st_size
    except OSError as exc:
        check.error(f'cannot stat wallpaper "{wallpaper}": {exc}')
        return

    if size > MAX_WALLPAPER_BYTES:
        check.error(
            f'wallpaper "{wallpaper}" is {human_size(size)}; '
            f"maximum is {human_size(MAX_WALLPAPER_BYTES)}"
        )

    dimensions = image_size(path)
    if dimensions:
        width, height = dimensions
        check.ok(f"{wallpaper} ({width}x{height}, {human_size(size)})")
        check_aspect(check, "wallpaper", width, height)
        if width < 1920 or height < 1080:
            check.warn(
                f"wallpaper is {width}x{height}; 1920x1080 minimum, "
                "2560x1440 recommended"
            )
    else:
        check.ok(f"{wallpaper} ({human_size(size)}; dimensions not checked)")


def check_preview(check: Check, theme_dir: Path) -> None:
    path = theme_dir / "preview.png"
    if not path.exists():
        check.warn("preview.png is missing (required for submission)")
        return
    if path.is_symlink():
        check.error("preview.png is a symlink; use a regular file")
        return
    if not path.is_file():
        check.error("preview.png is not a regular file")
        return
    if not image_magic_ok(path, ".png"):
        check.error("preview.png is not a valid PNG image")
        return

    try:
        size = path.stat().st_size
    except OSError as exc:
        check.error(f"cannot stat preview.png: {exc}")
        return

    if size > MAX_PREVIEW_BYTES:
        check.error(
            f"preview.png is {human_size(size)}; "
            f"maximum is {human_size(MAX_PREVIEW_BYTES)}"
        )

    dimensions = image_size(path)
    if dimensions:
        width, height = dimensions
        check.ok(f"preview.png ({width}x{height}, {human_size(size)})")
        check_aspect(check, "preview.png", width, height)
    else:
        check.ok(f"preview.png ({human_size(size)}; dimensions not checked)")


def check_files(check: Check, theme_dir: Path, wallpaper: str) -> None:
    allowed = set(ALLOWED_FILES)
    if wallpaper:
        allowed.add(wallpaper)

    try:
        children = sorted(theme_dir.iterdir(), key=lambda item: item.name)
    except OSError as exc:
        check.error(f"cannot list theme folder: {exc}")
        return

    for child in children:
        name = child.name
        if child.is_symlink():
            check.error(f'symlink "{name}" is not allowed')
            continue
        if child.is_dir():
            check.warn(f'subdirectory "{name}" is not part of a theme package')
            continue

        try:
            executable = bool(child.stat().st_mode & 0o111)
        except OSError:
            executable = False
        if executable:
            check.warn(f'"{name}" is executable; theme files must be data')

        if name not in allowed:
            check.warn(
                f'unexpected file "{name}"; allowed files are theme.conf, '
                "the wallpaper, preview.png, README.md and LICENSE"
            )


def check_theme(theme_dir: Path, template: bool = False) -> Check:
    check = Check(folder=theme_dir.name, path=theme_dir)

    if not theme_dir.is_dir():
        check.error("theme path is not a directory")
        return check

    folder = theme_dir.name
    if not template:
        if folder.startswith("_"):
            check.error('folders starting with "_" are reserved')
        elif not SLUG_RE.fullmatch(folder):
            check.error(
                "folder name must be lowercase kebab-case "
                "(letters, digits and single hyphens)"
            )

    conf_path = theme_dir / "theme.conf"
    if not conf_path.exists():
        check.error("theme.conf is missing")
        return check
    if conf_path.is_symlink():
        check.error("theme.conf is a symlink; use a regular file")
        return check
    if not conf_path.is_file():
        check.error("theme.conf is not a regular file")
        return check

    parse_conf(conf_path, check)
    values = check.values

    for key in REQUIRED_KEYS:
        if not values.get(key):
            check.error(f'"{key}" is required and cannot be empty')

    name = values.get("name", "").strip()
    if name:
        check.ok(f'name "{name}"')
        if len(name) > MAX_NAME_LENGTH:
            check.error(
                f"display name is {len(name)} characters; "
                f"maximum is {MAX_NAME_LENGTH}"
            )

    wallpaper = values.get("wallpaper", "").strip()
    check_wallpaper(check, theme_dir, wallpaper)

    for key in COLOR_KEYS:
        value = values.get(key, "")
        if not value:
            continue
        if not HEX_RE.fullmatch(value):
            check.error(f'"{key}" must be #RRGGBB, got "{value}"')

    missing = [key for key in PALETTE_KEYS if not values.get(key)]
    if missing:
        check.warn(
            f"palette incomplete ({16 - len(missing)}/16); missing "
            + ", ".join(missing)
        )
    else:
        check.ok("16/16 palette colours")

    background = parse_hex(values.get("background", ""))
    foreground = parse_hex(values.get("foreground", ""))
    if background and foreground:
        ratio = contrast_ratio(background, foreground)
        if ratio < 3.0:
            check.error(
                f"contrast background/foreground is {ratio:.1f}:1; "
                "minimum is 3.0:1 (4.5:1 recommended)"
            )
        elif ratio < 4.5:
            check.warn(
                f"contrast background/foreground is {ratio:.1f}:1; "
                "below the 4.5:1 submission target"
            )
        else:
            check.ok(f"contrast background/foreground {ratio:.1f}:1")

    for key in values:
        if key not in KNOWN_KEYS:
            check.warn(f'unknown key "{key}" (Pwnbox ignores it)')

    check_preview(check, theme_dir)
    check_files(check, theme_dir, wallpaper)

    return check


def find_themes(root: Path) -> List[Path]:
    if not root.is_dir():
        return []
    return sorted(
        (
            path
            for path in root.iterdir()
            if path.is_dir() and not path.name.startswith(".")
        ),
        key=lambda item: item.name,
    )


def mark_duplicate_names(checks: List[Check]) -> None:
    seen: Dict[str, str] = {}
    for check in checks:
        key = check.display_name.casefold()
        if key in seen:
            check.error(
                f'display name "{check.display_name}" is also used by '
                f"themes/{seen[key]}"
            )
        else:
            seen[key] = check.folder


def print_check(check: Check, quiet: bool) -> None:
    if quiet:
        for message in check.errors:
            print(f"{check.folder}: error: {message}")
        for message in check.warnings:
            print(f"{check.folder}: warning: {message}")
        return

    print(check.folder)
    for message in check.notes:
        print(f"  ok    {message}")
    for message in check.warnings:
        print(f"  warn  {message}")
    for message in check.errors:
        print(f"  error {message}")
    print()


def main() -> int:
    parser = argparse.ArgumentParser(
        description="Validate Pwnbox theme packages.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument(
        "--theme",
        metavar="PATH",
        help="validate one theme directory instead of the whole repository",
    )
    parser.add_argument(
        "--strict",
        action="store_true",
        help="treat warnings as errors (what CI runs)",
    )
    parser.add_argument(
        "--quiet",
        action="store_true",
        help="only print warnings and errors",
    )
    args = parser.parse_args()

    if args.theme:
        theme_dir = Path(args.theme).expanduser()
        if not theme_dir.is_absolute():
            theme_dir = (Path.cwd() / theme_dir).resolve()
        if not theme_dir.is_dir():
            parser.error(f"theme directory not found: {theme_dir}")
        checks = [
            check_theme(theme_dir, template=theme_dir.name == "_template")
        ]
        scope = str(theme_dir)
    else:
        if not THEMES_ROOT.is_dir():
            print(f"error: themes directory not found: {THEMES_ROOT}", file=sys.stderr)
            return 1
        checks = [
            check_theme(path, template=path.name == "_template")
            for path in find_themes(THEMES_ROOT)
        ]
        mark_duplicate_names(checks)
        scope = str(THEMES_ROOT)

    if not args.quiet:
        print("Pwnbox theme validator")
        print(f"Scope: {scope}")
        print(f"Themes: {len(checks)}")
        print()

    for check in checks:
        print_check(check, args.quiet)

    errors = sum(len(check.errors) for check in checks)
    warnings = sum(len(check.warnings) for check in checks)
    failed = errors > 0 or (args.strict and warnings > 0)

    if not args.quiet:
        print(
            f"{len(checks)} theme(s) checked: "
            f"{errors} error(s), {warnings} warning(s)"
        )
        if args.strict and warnings:
            print("strict mode: warnings are treated as errors")
        if failed:
            print("result: FAIL")
        else:
            print("result: PASS")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
