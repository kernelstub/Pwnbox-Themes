#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
THEMES_DIR="$REPO_DIR/themes"

die() {
    printf 'render-preview: %s\n' "$*" >&2
    exit 1
}

usage() {
    cat <<'EOF'
Usage: scripts/render-preview.sh THEME [OPTIONS]

Render a 16:9 palette card for a theme: the wallpaper with a dark footer,
the theme name and the 16 ANSI colours. The result is written to
themes/<name>/preview.png unless --out is given.

Arguments:
  THEME                  theme folder name (for example: midnight) or path

Options:
  -o, --out FILE         output file (default: <theme>/preview.png)
  -w, --width PX         image width, 640-3840 (default: 1280)
  -h, --help             show this help

Requires ImageMagick (`magick` or `convert`) and a font available through
fontconfig (DejaVu Sans is used by default).

Examples:
  ./scripts/render-preview.sh midnight
  ./scripts/render-preview.sh themes/ember --width 1920
  ./scripts/render-preview.sh aurora --out /tmp/aurora-preview.png
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

theme_arg=""
out=""
width=1280

while [ "$#" -gt 0 ]; do
    case "$1" in
    -o | --out)
        [ "$#" -ge 2 ] || die "$1 needs a file"
        out="$2"
        shift 2
        ;;
    --out=*)
        out="${1#*=}"
        shift
        ;;
    -w | --width)
        [ "$#" -ge 2 ] || die "$1 needs a number"
        width="$2"
        shift 2
        ;;
    --width=*)
        width="${1#*=}"
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
        [ -z "$theme_arg" ] || die 'only one theme can be rendered at a time'
        theme_arg="$1"
        shift
        ;;
    esac
done

[ -n "$theme_arg" ] || {
    usage
    exit 1
}

case "$width" in
'' | *[!0-9]*) die "width must be a number: $width" ;;
esac
if [ "$width" -lt 640 ] || [ "$width" -gt 3840 ]; then
    die 'width must be between 640 and 3840'
fi
height=$((width * 9 / 16))

if [ -d "$theme_arg" ]; then
    theme_dir="$(cd -- "$theme_arg" && pwd)"
elif [ -d "$THEMES_DIR/$theme_arg" ]; then
    theme_dir="$(cd -- "$THEMES_DIR/$theme_arg" && pwd)"
else
    die "theme not found: $theme_arg"
fi

conf="$theme_dir/theme.conf"
[ -f "$conf" ] || die "no theme.conf in $theme_dir"

name="$(conf_get "$conf" name)"
[ -n "$name" ] || name="$(basename -- "$theme_dir")"
wallpaper="$(conf_get "$conf" wallpaper)"
[ -n "$wallpaper" ] || die 'theme.conf has no wallpaper = entry'
case "$wallpaper" in
*/* | *\\* | .*)
    die "wallpaper must be a plain filename in the theme folder: $wallpaper"
    ;;
esac
wallpaper_path="$theme_dir/$wallpaper"
[ -f "$wallpaper_path" ] || die "wallpaper not found: $wallpaper_path"

background="$(conf_get "$conf" background)"
[ -n "$background" ] || background='#101014'
foreground="$(conf_get "$conf" foreground)"
[ -n "$foreground" ] || foreground='#e6e6e6'

if [ -z "$out" ]; then
    out="$theme_dir/preview.png"
fi
out_dir="$(dirname -- "$out")"
mkdir -p -- "$out_dir"
if [ "$(cd -- "$out_dir" && pwd)/$(basename -- "$out")" = "$wallpaper_path" ]; then
    die 'refusing to overwrite the wallpaper with the preview'
fi

if command -v magick >/dev/null 2>&1; then
    im=(magick)
elif command -v convert >/dev/null 2>&1; then
    im=(convert)
else
    die 'ImageMagick not found (install magick or convert)'
fi

font=""
if command -v fc-match >/dev/null 2>&1; then
    font="$(fc-match -f '%{file}' 'DejaVu Sans' 2>/dev/null || true)"
fi
if [ -z "$font" ] || [ ! -f "$font" ]; then
    font='DejaVu-Sans'
fi

colors=()
for i in $(seq 0 15); do
    colors[i]="$(conf_get "$conf" "color$i")"
    [ -n "${colors[$i]}" ] || colors[i]="$background"
done

accent="${colors[4]}"
label_color="${colors[7]}"
[ -n "$accent" ] || accent="$foreground"
[ -n "$label_color" ] || label_color="$foreground"

margin=$((width * 3 / 80))
gap=$((width / 160))
[ "$gap" -lt 4 ] && gap=4
swatch_h=$((height / 40))
[ "$swatch_h" -lt 10 ] && swatch_h=10
bottom_margin=$((width / 53))
swatch_w=$(((width - 2 * margin - 15 * gap) / 16))
[ "$swatch_w" -lt 12 ] && swatch_w=12
swatch_y=$((height - bottom_margin - swatch_h))
name_size=$((width / 27))
name_chars=${#name}
if [ "$name_chars" -gt 22 ]; then
    name_size=$((width / 34))
fi
if [ "$name_chars" -gt 36 ]; then
    name_size=$((width / 45))
fi
if [ "$name_chars" -gt 50 ]; then
    name_size=$((width / 58))
fi
label_size=$((width / 71))
[ "$label_size" -lt 12 ] && label_size=12
name_baseline=$((swatch_y - gap - name_size / 2 - 6))
label_baseline=$((name_baseline - name_size - 4))
panel_top=$((label_baseline - label_size - 14))
[ "$panel_top" -lt $((height / 2)) ] && panel_top=$((height / 2))

swatch_x=$(((width - (16 * swatch_w + 15 * gap)) / 2))
draw=""
for i in $(seq 0 15); do
    x=$((swatch_x + i * (swatch_w + gap)))
    radius=$((swatch_w / 8))
    [ "$radius" -lt 2 ] && radius=2
    draw+="fill ${colors[$i]} roundrectangle $x,$swatch_y $((x + swatch_w)),$((swatch_y + swatch_h)) $radius,$radius "
done

"${im[@]}" "$wallpaper_path" \
    -resize "${width}x${height}^" \
    -gravity center -extent "${width}x${height}" \
    -fill 'rgba(0,0,0,0.68)' \
    -draw "rectangle 0,$panel_top $((width - 1)),$((height - 1))" \
    -fill "$accent" \
    -draw "rectangle 0,$panel_top $((width - 1)),$((panel_top + 2))" \
    -gravity northwest \
    -font "$font" \
    -fill "$label_color" -pointsize "$label_size" \
    -annotate "+$margin+$label_baseline" 'PWNBOX THEME' \
    -fill "$foreground" -pointsize "$name_size" \
    -annotate "+$margin+$name_baseline" "$name" \
    -stroke 'rgba(255,255,255,0.22)' -strokewidth 1 \
    -draw "$draw" \
    -strip \
    -define png:compression-level=9 \
    "$out"

printf 'Wrote %s (%sx%s)\n' "$out" "$width" "$height"
