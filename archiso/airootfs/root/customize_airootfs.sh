#!/usr/bin/env bash
set -euo pipefail

useradd -m -G wheel,audio,video,storage -s /bin/bash liveuser
passwd -d liveuser
chown -R liveuser:liveuser /home/liveuser

# Matugen rewrites the SDDM login palette in place, so the live session must own
# the theme directory just like the provisioned target does.
[[ -d /usr/share/sddm/themes/elarun-custom ]] && chown -R liveuser:liveuser /usr/share/sddm/themes/elarun-custom

systemctl enable NetworkManager.service bluetooth.service cups.service power-profiles-daemon.service sddm.service
systemctl set-default graphical.target

# The live image is not an installed system: it must reach SDDM directly.
# Without this, systemd-firstboot opens an interactive console on tty1 and
# blocks the graphical session behind a timezone/locale/root-password prompt.
systemctl mask systemd-firstboot.service || \
  ln -sf /dev/null /etc/systemd/system/systemd-firstboot.service
ln -sf /usr/share/zoneinfo/UTC /etc/localtime
printf 'LANG=en_US.UTF-8\n' > /etc/locale.conf
printf 'KEYMAP=us\n' > /etc/vconsole.conf
if [[ -f /etc/locale.gen ]]; then
  sed -i 's/^#en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
  locale-gen
fi

pacman-key --init
pacman-key --populate archlinux
