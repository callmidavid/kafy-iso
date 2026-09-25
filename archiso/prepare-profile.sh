#!/bin/bash
set -euo pipefail

profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
iso_dir=$(cd "$profile_dir/.." && pwd)
kafy_source=${KAFY_SOURCE:-"$iso_dir/../kafy"}
staging_dir=${1:?"Usage: prepare-profile.sh STAGING_DIRECTORY"}

[[ -d "$kafy_source/config" && -d "$kafy_source/default" && -d "$kafy_source/themes" && -d "$kafy_source/shell/kafy" && -d "$kafy_source/install/live" && -d "$kafy_source/install/system" ]] || {
  printf 'Kafy source was not found at %s. Set KAFY_SOURCE to a Kafy checkout.\n' "$kafy_source" >&2
  exit 1
}

rm -rf "$staging_dir"
mkdir -p "$staging_dir"

# The profile contains only Archiso-specific files. Kafy product sources are
# composed into it at build time so the ISO never becomes their source of truth.
tar -C "$profile_dir" \
  --exclude='./out' \
  --exclude='./cache' \
  --exclude='./work' \
  --exclude='./.gitignore' \
  -cf - . | tar -C "$staging_dir" -xf -

for source_tree in "$kafy_source/config" "$kafy_source/default" "$kafy_source/install/live"; do
  tar -C "$source_tree" -cf - . | tar -C "$staging_dir/airootfs" -xf -
done

mkdir -p "$staging_dir/airootfs/usr/share/kafy/themes"
tar -C "$kafy_source/themes" -cf - . | tar -C "$staging_dir/airootfs/usr/share/kafy/themes" -xf -

mkdir -p "$staging_dir/airootfs/etc/xdg/quickshell/kafy/theme"
tar -C "$kafy_source/shell/kafy" -cf - . | \
  tar -C "$staging_dir/airootfs/etc/xdg/quickshell/kafy" -xf -
install -Dm644 "$kafy_source/themes/kafy/shell/KafyTheme.qml" \
  "$staging_dir/airootfs/etc/xdg/quickshell/kafy/theme/KafyTheme.qml"

mkdir -p "$staging_dir/airootfs/usr/local/share/kafy-installer/system"
tar -C "$kafy_source/install/system" -cf - . | \
  tar -C "$staging_dir/airootfs/usr/local/share/kafy-installer/system" -xf -

install -Dm755 "$kafy_source/bin/kafy-doctor" "$staging_dir/airootfs/usr/local/bin/kafy-doctor"
install -Dm755 "$kafy_source/bin/kafy-theme" "$staging_dir/airootfs/usr/local/bin/kafy-theme"
install -Dm755 "$kafy_source/bin/kafy-shell" "$staging_dir/airootfs/usr/local/bin/kafy-shell"
chmod 755 "$staging_dir/airootfs/usr/local/bin/kafy-wallpaper"

printf 'Prepared Archiso profile at %s\n' "$staging_dir"
