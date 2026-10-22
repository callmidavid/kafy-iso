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
  "airootfs/etc/skel/.config/hypr/hyprland.lua"
  "airootfs/etc/skel/.config/hypr/autostart.lua"
  "airootfs/etc/skel/.config/hypr/theme.lua"
  "airootfs/usr/share/wallpapers/kafy/contents/images/1920x1080.png"
  "airootfs/usr/local/bin/kafy-doctor"
  "airootfs/etc/skel/.config/quickshell/shell.qml"
  "airootfs/etc/skel/.config/quickshell/components/Bar.qml"
  "airootfs/etc/skel/.config/quickshell/components/Colors.qml"
  "airootfs/etc/skel/.config/theme/current/colors.conf"
  "airootfs/etc/skel/.config/systemd/user/watchcat.service"
  "airootfs/etc/skel/.mozilla/firefox/profiles.ini"
  "airootfs/usr/share/sddm/themes/elarun-custom/Main.qml"
  "airootfs/usr/share/kafy/firefox/user.js"
  "airootfs/usr/share/icons/Bibata-Modern-Ice/index.theme"
  "airootfs/usr/local/bin/kafy-installer"
  "airootfs/usr/local/bin/kafy-install-target"
  "airootfs/usr/local/lib/kafy/install/kafy-install-backend"
  "airootfs/usr/local/share/kafy-installer/packages"
  "airootfs/usr/local/share/kafy-installer/optional-packages.json"
  "airootfs/usr/local/share/kafy-installer/system/usr/local/lib/kafy/install/provision-target"
  "airootfs/usr/local/share/kafy-installer/system/usr/local/bin/kafy-first-boot"
  "airootfs/usr/local/share/kafy-installer/system/etc/sudoers.d/kafy-watchcat"
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

# The session paints the wallpaper through this absolute symlink.
[[ -L "$staging_dir/airootfs/etc/skel/.config/theme/current/background" ]] || {
  printf 'Missing composed wallpaper symlink.\n' >&2
  exit 1
}

# Firefox is pre-wired so the first-run profile gets the generated chrome.
[[ -L "$staging_dir/airootfs/etc/skel/.mozilla/firefox/kafy.default/user.js" ]] || {
  printf 'Missing Firefox user.js profile symlink.\n' >&2
  exit 1
}

# The live autologin and the installed target both use the uwsm-managed session
# so uwsm-app shortcuts and per-user systemd services work.
grep -Fqx 'Session=hyprland-uwsm.desktop' "$staging_dir/airootfs/etc/sddm.conf.d/kafy-live.conf" || {
  printf 'Live SDDM session is not uwsm-managed.\n' >&2
  exit 1
}
grep -Fq 'Session=hyprland-uwsm.desktop' \
  "$staging_dir/airootfs/usr/local/share/kafy-installer/system/usr/local/lib/kafy/install/provision-target" || {
  printf 'Installed SDDM session is not uwsm-managed.\n' >&2
  exit 1
}

# partprobe is needed after sgdisk creates the target partitions.
grep -Fqx 'parted' "$staging_dir/packages.x86_64" || {
  printf 'parted is missing from the live package list.\n' >&2
  exit 1
}

# The live image must not stall in systemd-firstboot before the desktop.
grep -Fq 'systemctl mask systemd-firstboot.service' \
  "$staging_dir/airootfs/root/customize_airootfs.sh" || {
  printf 'Live image does not disable systemd-firstboot.\n' >&2
  exit 1
}

for executable in \
  kafy-doctor kafy-installer kafy-install-target kafy-welcome; do
  [[ -x "$staging_dir/airootfs/usr/local/bin/$executable" ]] || {
    printf 'Composed command is not executable: %s\n' "$executable" >&2
    exit 1
  }
done

[[ -x "$staging_dir/airootfs/usr/local/lib/kafy/install/kafy-install-backend" ]] || {
  printf 'Installer backend is not executable.\n' >&2
  exit 1
}

profile_definition="$profile_dir/profiledef.sh"
for executable in \
  kafy-doctor kafy-installer kafy-install-target kafy-welcome; do
  grep -Fqx "  [\"/usr/local/bin/$executable\"]=\"0:0:755\"" "$profile_definition"
done
grep -Fqx '  ["/usr/local/lib/kafy/install/kafy-install-backend"]="0:0:755"' "$profile_definition"

hyprland_config="$staging_dir/airootfs/etc/skel/.config/hypr/hyprland.conf"
grep -Fqx 'source = ~/.config/theme/current/colors.conf' "$hyprland_config"

windowrules_config="$staging_dir/airootfs/etc/skel/.config/hypr/windowrules.conf"
grep -Fqx 'windowrule = float on, match:class ^(org\.kafy\.Installer)$' "$windowrules_config"
grep -Fqx 'windowrule = center on, match:class ^(org\.kafy\.Installer)$' "$windowrules_config"

autostart_config="$staging_dir/airootfs/etc/skel/.config/hypr/autostart.conf"
grep -Fqx 'exec-once = quickshell -p ~/.config/quickshell' "$autostart_config"

hyprland_lua="$staging_dir/airootfs/etc/skel/.config/hypr/hyprland.lua"
grep -Fqx 'require("theme")' "$hyprland_lua"

autostart_lua="$staging_dir/airootfs/etc/skel/.config/hypr/autostart.lua"
grep -Fq 'quickshell -p ~/.config/quickshell' "$autostart_lua"
grep -Fq '/usr/local/bin/kafy-welcome' "$autostart_lua"

windowrules_lua="$staging_dir/airootfs/etc/skel/.config/hypr/windowrules.lua"
grep -Fq 'org\\.kafy\\.Installer' "$windowrules_lua"

printf 'Kafy profile composition test passed.\n'
