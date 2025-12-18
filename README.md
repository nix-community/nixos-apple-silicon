## About

This repository contains package expressions and NixOS configuration modules which are intended to provide a useful and straightforward bare metal NixOS experience on Apple Silicon Macs. Once NixOS is installed and the Apple Silicon configuration module is added, the system can be configured and operated like any other NixOS system.

We aim to generally replicate the experience and software configuration/versions provided by the Asahi Linux reference distro, and we rely primarily on their hard work. Contributions to improve the NixOS experience and address specific issues are welcome, but configuration and versions which diverge significantly will not be accepted.

Please see the documentation and guide below to get started.

## Documentation

To read the latest version of the installation/maintenance manual, use an existing Nix installation to open a page in your web browser displaying the manual.

```shellsession
nix --extra-experimental-features "nix-command flakes" run github:nix-community/nixos-apple-silicon#nas-manual
```

To read a specific version tied to the installer, you can either read it within the installer's live system (via `start-manual-info` or `start-manual-web`) or build and view the manual from the specific release branch (replace "RELEASE" with the release tag).

```shellsession
nix --extra-experimental-features "nix-command flakes" run github:nix-community/nixos-apple-silicon/<RELEASE>#nas-manual
```

## Credits

This is mostly a restructuring of work many others have already done, and it wouldn't have been possible without them. Important parts of the NixOS on Apple Silicon experience include (but are not limited to):
* [Asahi Linux's m1n1 bootloader/hypervisor](https://github.com/AsahiLinux/m1n1)
* [Asahi Linux's kernel patches](https://github.com/AsahiLinux/linux)
* [Mark Kettenis' U-boot port](https://github.com/kettenis/u-boot)
* [Alyssa Rosenzweig's Mesa GPU driver](https://gitlab.freedesktop.org/asahi/mesa)

The Nix derivations and documentation in this repository are licensed under the MIT license as included in the [LICENSE](LICENSE) file. Patches included in this repository, and the files that Nix builds, are covered by separate licenses.
