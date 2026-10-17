#!/bin/bash
set -euo pipefail

profile_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
iso_dir=$(cd "$profile_dir/.." && pwd)
kafy_source=${KAFY_SOURCE:-"$iso_dir/../kafy"}
staging_dir=${1:?"Usage: prepare-profile.sh STAGING_DIRECTORY"}

[[ -d "$kafy_source/config" && -d "$kafy_source/default" && -d "$kafy_source/install/live" && -d "$kafy_source/install/system" ]] || {
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

mkdir -p "$staging_dir/airootfs/usr/local/share/kafy-installer/system"
tar -C "$kafy_source/install/system" -cf - . | \
  tar -C "$staging_dir/airootfs/usr/local/share/kafy-installer/system" -xf -

install -Dm755 "$kafy_source/bin/kafy-doctor" "$staging_dir/airootfs/usr/local/bin/kafy-doctor"

# Optional: pin a package mirror for the image build. The profile's pacman.conf
# includes /etc/pacman.d/mirrorlist, which is slow by default in the build
# container; KAFY_MIRROR replaces that include with an explicit server.
if [[ -n ${KAFY_MIRROR:-} ]]; then
  sed -i "s|^Include = /etc/pacman.d/mirrorlist\$|Server = ${KAFY_MIRROR}|" "$staging_dir/pacman.conf"
  grep -Fq "Server = ${KAFY_MIRROR}" "$staging_dir/pacman.conf" || {
    printf 'KAFY_MIRROR was not applied to %s\n' "$staging_dir/pacman.conf" >&2
    exit 1
  }
  printf 'Using Kafy package mirror: %s\n' "$KAFY_MIRROR"
fi

printf 'Prepared Archiso profile at %s\n' "$staging_dir"
