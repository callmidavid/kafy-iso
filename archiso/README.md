# Kafy Arch ISO Profile

This repository is the Kafy ISO builder. It uses Arch Linux's `archiso` to build a current, small, bootable Hyprland desktop from a separate Kafy source checkout.

Kafy deliberately keeps the desktop explicit rather than installing a broad desktop meta-package. Step 1 provides a polished Hyprland baseline with a top bar, application launcher, gentle motion, and hardware support. The dock, control center, installer flow, and Kafy shell are added only after this image boots reliably.

The previous Debian implementation is preserved at `../kafy-deb`.

## Build locally

On an Arch Linux or Arch-based host:

```sh
cd ~/Documents/kafy-iso/archiso
sudo ./build.sh
```

The default expects the product source beside this repository at `~/Documents/kafy`. Set `KAFY_SOURCE` when it is elsewhere:

```sh
cd ~/Documents/kafy-iso/archiso
sudo env KAFY_SOURCE=/path/to/kafy ./build.sh
```

The ISO and SHA-256 checksum are written to `kafy-iso/out/`.

On Ubuntu or Debian, install Docker and build through the included Arch container:

```sh
sudo apt update
sudo apt install -y docker.io
cd ~/Documents/kafy-iso/archiso
sudo ./build.sh
```

Do not run `pacman` directly on Ubuntu or Debian; it is Arch's package manager. The build script selects the Docker path automatically when `mkarchiso` is not installed.

## Profile layout

- `packages.x86_64`: exact packages installed in the image.
- `airootfs/`: Archiso-only files copied into the live system.
- `prepare-profile.sh`: builds a temporary profile and composes `config/`, `default/`, and `install/live/` from the Kafy source repository into it.
- `profiledef.sh`: ISO metadata, architecture, boot modes, and compression settings.
- `pacman.conf`: Arch repositories used during the image build; `multilib` is enabled for Steam and 32-bit graphics support.

The live image signs in automatically as `liveuser` so it opens straight to the desktop. The installer is source code for the live environment, not a statement that Kafy installation is production-ready.
