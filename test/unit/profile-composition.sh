#!/bin/bash
set -euo pipefail

iso_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)
profile_dir="$iso_dir/archiso"
kafy_source=${KAFY_SOURCE:-"$iso_dir/../kafy"}
staging_dir=$(mktemp -d)
trap 'rm -rf "$staging_dir"' EXIT

KAFY_SOURCE="$kafy_source" "$profile_dir/prepare-profile.sh" "$staging_dir" >/dev/null

required_files=(
  "airootfs/etc/skel/.config/hypr/hyprland.conf"
  "airootfs/usr/share/wallpapers/kafy/contents/images/1920x1080.png"
  "airootfs/usr/local/bin/kafy-doctor"
  "airootfs/usr/local/bin/kafy-wallpaper"
  "airootfs/usr/local/bin/kafy-installer"
  "airootfs/etc/sddm.conf.d/kafy-live.conf"
  "airootfs/etc/mkinitcpio.conf.d/archiso.conf"
)

for required_file in "${required_files[@]}"; do
  [[ -f "$staging_dir/$required_file" ]] || {
    printf 'Missing composed file: %s\n' "$required_file" >&2
    exit 1
  }
done

hyprland_config="$staging_dir/airootfs/etc/skel/.config/hypr/hyprland.conf"
rg -qx 'windowrule = float on, match:class \^\(kafy-welcome\)\$' "$hyprland_config"
rg -qx 'windowrule = center on, match:class \^\(kafy-welcome\)\$' "$hyprland_config"
rg -qx 'exec-once = /usr/local/bin/kafy-wallpaper' "$hyprland_config"

printf 'Kafy profile composition test passed.\n'
