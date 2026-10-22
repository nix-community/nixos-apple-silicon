# Binary Cache

Some components needed on Apple Silicon system (mostly the custom kernel) are
rather big and need a long time to build.

As per nixpkgs policy, this doesn't belong into nixpkgs, and for the same
reasons, the rpi kernels have recently been moved into nixos-hardware.

Due to issues with our builders (GH Action runners too slow to build the kernel,
namespace.so runners not supporting sandboxing and causing build failures) we do
not currently have a working cache, as setting up our own runners would be a lot
of work.

The long-term plan is to switch to using the same Hydra that nixos-hardware
plans to switch to (where recently the rpi kernels were migrated to).

See https://github.com/NixOS/nixos-hardware/issues/854 for details.

Short term, we are using the nixbot system run by the nix-community project as a
part of our CI, building all PRs and master branch commits. The logs of this can
be found at https://nixbot.nix-community.org. It automatically uploads these
built packages (including the custom kernels) to the nix-community's cachix
instance. It is possible to pull these artifacts, see
https://nix-community.org/cache/ for information.

However, as always with a binary cache, please remember that it is only as
secure as your trust in the people who run it. These include the nix-community
administrators, found at https://nix-community.org/administrators/, as well as
the maintainers of the nixos-apple-silicon repo, which can be found in it's
GitHub repo description. Be careful.
