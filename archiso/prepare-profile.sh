#!/bin/bash
set -euo pipefail

profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
iso_dir=$(cd "$profile_dir/.." && pwd)
kafy_source=${KAFY_SOURCE:-"$iso_dir/../kafy"}
staging_dir=${1:?"Usage: prepare-profile.sh STAGING_DIRECTORY"}

[[ -d "$kafy_source/config" && -d "$kafy_source/default" && -d "$kafy_source/install" ]] || {
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

install -Dm755 "$kafy_source/bin/kafy-doctor" "$staging_dir/airootfs/usr/local/bin/kafy-doctor"
chmod 755 "$staging_dir/airootfs/usr/local/bin/kafy-wallpaper"

printf 'Prepared Archiso profile at %s\n' "$staging_dir"
