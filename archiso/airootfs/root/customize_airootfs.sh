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

pacman-key --init
pacman-key --populate archlinux
