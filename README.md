# Kafy ISO

The ISO builder for Kafy OS. It deliberately owns only Archiso metadata, package selection, boot assets, build cache, CI, and composition checks. Product configuration and desktop code live in the sibling [Kafy source repository](../kafy).

## Build

```sh
cd archiso
sudo ./build.sh
```

The builder reads Kafy source from `../kafy` by default and writes the image to `out/`. Use `KAFY_SOURCE=/path/to/kafy` to select another checkout.

Before a full build, verify the composition contract:

```sh
./test/unit/profile-composition.sh
```

See [the builder guide](docs/iso-build-and-test.md) for host requirements and VM testing.
