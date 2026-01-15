# Binary Cache

Some components needed on Apple Silicon systems are rather big and need a long time to build, specifically the kernel. This is why you might consider using substitutes from a binary cache.

Our GitHub Actions workflow builds all of the declared `packages` every time the main branch is pushed, and pushes all store paths to the nixos-apple-silicon binary cache.

If you decide to use the nixos-apple-silicon binary cache, you can use the following configuration snippet:

```
  nix.settings = {
    extra-substituters = [
      "https://nixos-apple-silicon.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nixos-apple-silicon.cachix.org-1:8psDu5SA5dAD7qA0zMy5UT292TxeEPzIz8VVEr2Js20="
    ];
  };
```

#### Who are you trusting by adding this binary cache?

When using additional substituters in Nix/NixOS, you always trust the actors who are involved or have access to the infrastructure for populating the binary cache. No matter which packages you intend to substitute over a binary cache, you should always assume that any of the involved people could gain remote `root`-level access to your system.

Currently, for the nixos-apple-silicon binary cache, the following parties are involved:

- The NixOS Apple Silicon maintainers
- The nix-community org admins
- Microsoft/GitHub (obviously)
- [namespace](https://namespace.so) for the GitHub Action Runners
- Cachix (for using their cachix/install-nix-action & cachix/cachix-action in our CI)
