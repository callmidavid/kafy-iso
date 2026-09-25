# ISO Build and Test

## Build contract

Kafy builds an x86_64 Arch Linux ISO through `mkarchiso`. The profile supports both BIOS through Syslinux and UEFI through systemd-boot. The Archiso initramfs hook is required for the live compressed root filesystem to mount.

Build locally from `archiso/` with `sudo ./build.sh`. It reads the product source from the sibling `../kafy` checkout, or from `KAFY_SOURCE` when set. On an Arch host it runs `mkarchiso` directly. On a Debian/Ubuntu host it uses an Arch container when Docker is available. The GitHub workflow checks out this ISO builder and the selected Kafy source revision separately, then uploads only the ISO and SHA-256 checksum.

Before the full build, run `./test/unit/profile-composition.sh` at the repository root. This verifies the source-to-ISO boundary without downloading packages.

Before changing `packages.x86_64`, resolve every new package against official Arch repositories. Do not add AUR packages to the ISO build path. A package that is not in the official repositories needs a Kafy-maintained package repository, reproducible package build, and update story first.

## Source revision contract

For a developer build, `KAFY_SOURCE` identifies the Kafy product checkout. For GitHub Actions, set the ISO repository variable `KAFY_SOURCE_REPOSITORY` to the `owner/repository` name of the Kafy source project if it differs from the workflow default. Manual runs may choose a branch, tag, or commit through the `kafy_ref` input.

Release automation must record the exact Kafy commit used for every published ISO. Do not treat an unpinned development checkout as a release input.

## Minimum acceptance checklist

Every ISO change must be tested in a VM before being presented as working.

- ISO builds and has a checksum.
- ISO boots with UEFI.
- ISO boots with BIOS when BIOS support changes.
- The live system reaches the Hyprland session without a terminal login.
- Wallpaper, top bar, app launcher, file manager, Firefox, sound, and NetworkManager work.
- `Super + L` starts a usable lock screen.
- The Kafy installer entry point opens, but no destructive installation claim is made until an installed-system test succeeds.

## Physical-hardware checklist

Test at least Intel, AMD, and NVIDIA hardware as available. Record boot method, GPU, display arrangement, Wi-Fi chipset, Bluetooth, audio, suspend/resume, and controller results. Screenshot or copy errors before rebooting.

## Installer boundary

The present `kafy-installer` script delegates to Archinstall. It is experimental and must not be considered production-ready until Kafy can prove: partition handling, user creation, copied Kafy defaults, no live-user autologin on the installed system, first boot, networking, updates, and recovery.
