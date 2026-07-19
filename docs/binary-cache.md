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
