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
