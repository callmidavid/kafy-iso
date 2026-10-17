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
  "airootfs/usr/local/bin/kafy-theme"
  "airootfs/usr/local/bin/kafy-shell"
  "airootfs/usr/share/kafy/themes/kafy/metadata.json"
  "airootfs/usr/share/kafy/themes/kafy/hyprland.conf"
  "airootfs/usr/share/kafy/themes/kafy/waybar.css"
  "airootfs/etc/xdg/quickshell/kafy/shell.qml"
  "airootfs/etc/xdg/quickshell/kafy/KafyBar.qml"
  "airootfs/etc/xdg/quickshell/kafy/theme/KafyTheme.qml"
  "airootfs/etc/skel/.config/quickshell/shell.qml"
  "airootfs/etc/skel/.config/theme/current/colors.conf"
  "airootfs/usr/share/sddm/themes/elarun-custom/Main.qml"
  "airootfs/usr/share/icons/Bibata-Modern-Ice/index.theme"
  "airootfs/usr/local/bin/kafy-wallpaper"
  "airootfs/usr/local/bin/kafy-installer"
  "airootfs/usr/local/bin/kafy-install-target"
  "airootfs/usr/local/share/kafy-installer/system/usr/local/lib/kafy/install/provision-target"
  "airootfs/usr/local/share/kafy-installer/system/usr/local/bin/kafy-first-boot"
  "airootfs/usr/local/share/kafy-installer/system/etc/systemd/user/kafy-first-boot.service"
  "airootfs/etc/sddm.conf.d/kafy-live.conf"
  "airootfs/etc/mkinitcpio.conf.d/archiso.conf"
)

for required_file in "${required_files[@]}"; do
  [[ -f "$staging_dir/$required_file" ]] || {
    printf 'Missing composed file: %s\n' "$required_file" >&2
    exit 1
  }
done

for executable in \
  kafy-doctor kafy-installer kafy-install-target kafy-shell kafy-theme kafy-welcome kafy-wallpaper; do
  [[ -x "$staging_dir/airootfs/usr/local/bin/$executable" ]] || {
    printf 'Composed command is not executable: %s\n' "$executable" >&2
    exit 1
  }
done

profile_definition="$profile_dir/profiledef.sh"
for executable in \
  kafy-doctor kafy-installer kafy-install-target kafy-shell kafy-theme kafy-welcome kafy-wallpaper; do
  grep -Fqx "  [\"/usr/local/bin/$executable\"]=\"0:0:755\"" "$profile_definition"
done

hyprland_config="$staging_dir/airootfs/etc/skel/.config/hypr/hyprland.conf"
grep -Fqx 'source = ~/.config/theme/current/colors.conf' "$hyprland_config"

windowrules_config="$staging_dir/airootfs/etc/skel/.config/hypr/windowrules.conf"
grep -Fqx 'windowrule = float on, match:class ^(kafy-welcome)$' "$windowrules_config"
grep -Fqx 'windowrule = center on, match:class ^(kafy-welcome)$' "$windowrules_config"

autostart_config="$staging_dir/airootfs/etc/skel/.config/hypr/autostart.conf"
grep -Fqx 'exec-once = quickshell -p ~/.config/quickshell' "$autostart_config"

printf 'Kafy profile composition test passed.\n'
