# ISO Build and Test

## Build contract

Kafy builds an x86_64 Arch Linux ISO through `mkarchiso`. The profile supports both BIOS through Syslinux and UEFI through systemd-boot. The Archiso initramfs hook is required for the live compressed root filesystem to mount.

Build locally from `archiso/` with `sudo ./build.sh`. It reads the product source from the sibling `../kafy` checkout, or from `KAFY_SOURCE` when set. On an Arch host it runs `mkarchiso` directly. On a Debian/Ubuntu host it uses an Arch container when Docker is available. The GitHub workflow checks out this ISO builder and the selected Kafy source revision separately, then uploads only the ISO and SHA-256 checksum.

Before the full build, run `./test/unit/profile-composition.sh` at the repository root. This verifies the source-to-ISO boundary without downloading packages.

Before changing `packages.x86_64`, resolve every new package against official Arch repositories. Do not add AUR packages to the ISO build path. A package that is not in the official repositories needs a Kafy-maintained package repository, reproducible package build, and update story first.

## Source revision contract

For a developer build, `KAFY_SOURCE` identifies the Kafy product checkout. GitHub Actions checks out `King12-D/kafyOS` separately from this builder repository. Manual runs may choose a branch, tag, or commit through the `kafy_ref` input.

Release automation must record the exact Kafy commit used for every published ISO. Do not treat an unpinned development checkout as a release input.

## Stable-release integrity

The normal build workflow produces test artifacts only. A public release must be created from immutable Kafy and ISO-builder tags, and must publish all of the following together:

- the versioned ISO;
- a SHA-256 manifest;
- a detached GPG signature for that manifest;
- the signing-key fingerprint and verification command;
- the exact source and builder commits; and
- the completed VM and hardware acceptance record.

The release owner must create and protect the signing key, add its private key and passphrase as GitHub Actions secrets, and publish the public fingerprint before enabling a release workflow. Do not generate a key in CI or publish an unsigned build as stable.

The `Release Kafy OS ISO` workflow runs only when an ISO-builder tag named `v*` is pushed. It checks out the Kafy source at the *same* tag, runs source and composition checks, builds the ISO, writes `SHA256SUMS` with both commits, produces `SHA256SUMS.asc`, and creates the GitHub release. It requires these repository secrets:

- `KAFY_RELEASE_GPG_PRIVATE_KEY`: ASCII-armored private signing key.
- `KAFY_RELEASE_GPG_PASSPHRASE`: passphrase for that key.

Before a public release, publish the fingerprint emitted in `SIGNING_KEY_FINGERPRINT` on the Kafy website and repository profile. A user verifies a downloaded ISO with:

```sh
gpg --verify SHA256SUMS.asc SHA256SUMS
sha256sum --ignore-missing -c SHA256SUMS
```

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
