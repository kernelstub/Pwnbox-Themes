#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
THEMES_DIR="$REPO_DIR/themes"
VALIDATOR="$REPO_DIR/scripts/validate-theme.py"

die() {
    printf 'install-theme: %s\n' "$*" >&2
    exit 1
}

note() {
    printf '%s\n' "$*"
}

usage() {
    cat <<'EOF'
Usage: scripts/install-theme.sh [THEME] [OPTIONS]

Install a theme from this repository into a Pwnbox flake checkout.

Arguments:
  THEME                  theme folder name (for example: midnight) or path

Options:
  -f, --flake DIR        Pwnbox checkout containing flake.nix
                         (default: $PWNBOX_DIR, current directory, ~/pwnbox,
                         ~/Pwnbox)
  -N, --no-rebuild       copy and stage only; do not rebuild
      --force            replace an installed theme with the same folder name
      --skip-validation  do not run scripts/validate-theme.py first
      --dry-run          show what would happen without changing anything
  -l, --list             list installable themes and exit
  -h, --help             show this help

Examples:
  ./scripts/install-theme.sh --list
  ./scripts/install-theme.sh midnight
  ./scripts/install-theme.sh ember --flake ~/src/Pwnbox
  ./scripts/install-theme.sh midnight --no-rebuild
  ./scripts/install-theme.sh midnight --force

The theme is copied to <flake>/dotfiles/themes/<name>/. Only theme.conf and
the wallpaper named in it are installed; preview.png and README.md stay in
this repository. The folder is staged with git add, because the Pwnbox flake
only sees tracked files.
EOF
}

conf_get() {
    local file="$1" key="$2" line k v
    [ -f "$file" ] || return 0
    while IFS= read -r line || [ -n "$line" ]; do
        line="${line#"${line%%[![:space:]]*}"}"
        case "$line" in
        '' | '#'* | ';'*) continue ;;
        esac
        case "$line" in
        *=*) ;;
        *) continue ;;
        esac
        k="${line%%=*}"
        v="${line#*=}"
        k="${k%"${k##*[![:space:]]}"}"
        v="${v#"${v%%[![:space:]]*}"}"
        v="${v%"${v##*[![:space:]]}"}"
        if [ "$k" = "$key" ]; then
            printf '%s' "$v"
            return 0
        fi
    done <"$file"
    return 0
}

list_themes() {
    local path name display found=0
    printf '%-24s %s\n' 'THEME' 'NAME'
    for path in "$THEMES_DIR"/*/; do
        [ -f "${path}theme.conf" ] || continue
        name="$(basename "${path%/}")"
        case "$name" in
        _*) continue ;;
        esac
        display="$(conf_get "${path}theme.conf" name)"
        [ -n "$display" ] || display="$name"
        printf '%-24s %s\n' "$name" "$display"
        found=1
    done
    if [ "$found" -eq 0 ]; then
        note 'No installable themes found.'
    fi
}

discover_flake() {
    local candidate
    local candidates=()
    [ -n "${PWNBOX_DIR:-}" ] && candidates+=("$PWNBOX_DIR")
    candidates+=("$PWD" "$HOME/pwnbox" "$HOME/Pwnbox")
    for candidate in "${candidates[@]}"; do
        if [ -f "$candidate/flake.nix" ] && [ -d "$candidate/dotfiles/themes" ]; then
            (cd -- "$candidate" && pwd)
            return 0
        fi
    done
    return 1
}

theme_arg=""
flake_opt=""
rebuild=1
force=0
dry_run=0
skip_validation=0
want_list=0

while [ "$#" -gt 0 ]; do
    case "$1" in
    -f | --flake)
        [ "$#" -ge 2 ] || die "$1 needs a directory"
        flake_opt="$2"
        shift 2
        ;;
    --flake=*)
        flake_opt="${1#*=}"
        shift
        ;;
    -N | --no-rebuild)
        rebuild=0
        shift
        ;;
    -R | --rebuild)
        rebuild=1
        shift
        ;;
    --force)
        force=1
        shift
        ;;
    --skip-validation)
        skip_validation=1
        shift
        ;;
    --dry-run)
        dry_run=1
        shift
        ;;
    -l | --list)
        want_list=1
        shift
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    -*)
        die "unknown option: $1 (try --help)"
        ;;
    *)
        [ -z "$theme_arg" ] || die 'only one theme can be installed at a time'
        theme_arg="$1"
        shift
        ;;
    esac
done

if [ "$want_list" -eq 1 ]; then
    list_themes
    exit 0
fi

if [ -z "$theme_arg" ]; then
    usage
    note ''
    list_themes
    exit 0
fi

if [ -d "$theme_arg" ]; then
    theme_dir="$(cd -- "$theme_arg" && pwd)"
elif [ -d "$THEMES_DIR/$theme_arg" ]; then
    theme_dir="$(cd -- "$THEMES_DIR/$theme_arg" && pwd)"
else
    die "theme not found: $theme_arg (try --list)"
fi

folder="$(basename -- "$theme_dir")"
case "$folder" in
_*)
    die "folder \"$folder\" is scaffolding and cannot be installed"
    ;;
'' | . | .. | */*)
    die "invalid theme folder name: $folder"
    ;;
esac

[ -f "$theme_dir/theme.conf" ] || die "no theme.conf in $theme_dir"

if [ "$skip_validation" -eq 0 ]; then
    command -v python3 >/dev/null 2>&1 ||
        die 'python3 is required for validation (or use --skip-validation)'
    if ! python3 "$VALIDATOR" --theme "$theme_dir" --quiet; then
        die 'theme validation failed'
    fi
fi

name="$(conf_get "$theme_dir/theme.conf" name)"
[ -n "$name" ] || name="$folder"

wallpaper="$(conf_get "$theme_dir/theme.conf" wallpaper)"
[ -n "$wallpaper" ] || die 'theme.conf has no wallpaper = entry'
case "$wallpaper" in
*/* | *\\* | .*)
    die "wallpaper must be a plain filename in the theme folder: $wallpaper"
    ;;
esac
[ -f "$theme_dir/$wallpaper" ] ||
    die "wallpaper not found: $theme_dir/$wallpaper"
if [ "$wallpaper" = 'preview.png' ]; then
    die 'wallpaper cannot be preview.png; add a separate wallpaper'
fi

if [ -n "$flake_opt" ]; then
    [ -d "$flake_opt" ] || die "flake directory not found: $flake_opt"
    flake_dir="$(cd -- "$flake_opt" && pwd)"
else
    flake_dir="$(discover_flake || true)"
    [ -n "$flake_dir" ] || die \
        'could not find a Pwnbox checkout; use --flake /path/to/Pwnbox'
fi

[ -f "$flake_dir/flake.nix" ] ||
    die "not a Pwnbox flake checkout (no flake.nix): $flake_dir"
[ -d "$flake_dir/dotfiles/themes" ] ||
    die "not a Pwnbox flake checkout (no dotfiles/themes): $flake_dir"

target_root="$flake_dir/dotfiles/themes"
target="$target_root/$folder"
already_installed=0

if [ -e "$target" ]; then
    if [ "$force" -eq 1 ]; then
        :
    elif [ -f "$target/theme.conf" ] &&
        [ -f "$target/$wallpaper" ] &&
        cmp -s "$theme_dir/theme.conf" "$target/theme.conf" &&
        cmp -s "$theme_dir/$wallpaper" "$target/$wallpaper"; then
        already_installed=1
    else
        die "theme folder already exists: $target (use --force to replace it)"
    fi
fi

if [ "$already_installed" -eq 1 ]; then
    note "Theme already installed at $target"
else
    if [ "$dry_run" -eq 1 ]; then
        if [ -e "$target" ]; then
            note "[dry-run] remove $target (--force)"
        else
            note "[dry-run] create $target"
        fi
        note "[dry-run] copy theme.conf and $wallpaper to $target"
    else
        if [ "$force" -eq 1 ] && [ -e "$target" ]; then
            rm -rf -- "$target"
        fi
        mkdir -p -- "$target"
        install -m 0644 -- "$theme_dir/theme.conf" "$target/theme.conf"
        install -m 0644 -- "$theme_dir/$wallpaper" "$target/$wallpaper"
        note "Copied $folder to $target"
    fi
fi

if git -C "$flake_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if git -C "$flake_dir" check-ignore -q "dotfiles/themes/$folder/theme.conf"; then
        die "dotfiles/themes/$folder is ignored by .gitignore; the flake will not see it"
    fi
    if [ "$dry_run" -eq 1 ]; then
        note "[dry-run] git add dotfiles/themes/$folder"
    else
        git -C "$flake_dir" add -- "dotfiles/themes/$folder"
        note "Staged dotfiles/themes/$folder"
    fi
else
    note "Note: $flake_dir is not a git repository; the folder is used directly."
fi

if [ "$rebuild" -eq 1 ]; then
    if [ "$dry_run" -eq 1 ]; then
        if [ -x "$flake_dir/scripts/install.sh" ]; then
            note "[dry-run] (cd $flake_dir && ./scripts/install.sh switch)"
        else
            note "[dry-run] (cd $flake_dir && sudo nixos-rebuild switch --flake .#<host>)"
        fi
    elif [ -x "$flake_dir/scripts/install.sh" ]; then
        note 'Rebuilding and activating...'
        (cd -- "$flake_dir" && ./scripts/install.sh switch)
    else
        host="$(hostname -s 2>/dev/null || hostname)"
        note 'Rebuilding and activating...'
        (cd -- "$flake_dir" && sudo nixos-rebuild switch --flake ".#$host")
    fi
else
    note "Rebuild when ready:"
    note "  cd $flake_dir && ./scripts/install.sh switch"
fi

if [ "$dry_run" -eq 1 ]; then
    note ''
    note '[dry-run] no changes made'
    exit 0
fi

note ''
note "Theme: $name ($folder)"
if [ "$rebuild" -eq 1 ]; then
    note 'Select it:'
    note "  ALT + S -> THEME -> Custom -> $name"
    note '  or: pwnbox-theme custom'
    note ''
    note 'If this theme was already active, re-apply it with:'
    note '  pwnbox-theme restore'
else
    note "After rebuilding, select it from ALT + S -> THEME -> Custom."
fi
