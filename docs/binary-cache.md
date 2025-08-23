# Binary Cache

Some components needed on Apple Silicon systems are rather big and need a long time to build, specifically the kernel. This is why you might consider using substitutes from a binary cache.

The nix-community buildbot will build the `checks` attribute, which includes the kernel for now, for every PR as well as the main branch of the repo. All store paths produced are pushed to the nix-community binary cache.

As the nix-community buildbot builds untrusted Nix derivations from any PR to a CI-enabled nix-community repo, the nixos-apple-silicon maintainers **cannot guarantee the integrity of the substitutes in the binary cache**.

#### ⚠️  It is up to you whether to trust the nix-community binary cache ⚠️

If you decide to use the nix-community binary cache, you can use the following configuration snippet:

```
  nix.settings = {
    extra-substituters = [
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };
```
