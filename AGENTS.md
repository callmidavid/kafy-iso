# Kafy ISO Builder Guide

This repository is intentionally limited to ISO construction. Keep desktop configuration, user-facing tools, installers, wallpapers, and product defaults in the Kafy source repository.

The composition boundary is `archiso/prepare-profile.sh`: it copies `config/`, `default/`, and `install/live/` from `KAFY_SOURCE` into the temporary Archiso profile. Update `test/unit/profile-composition.sh` whenever that boundary changes.

Run `./test/unit/profile-composition.sh` before an ISO build. Build from `archiso/` with `sudo ./build.sh`; it reads the sibling `../kafy` source checkout by default.
