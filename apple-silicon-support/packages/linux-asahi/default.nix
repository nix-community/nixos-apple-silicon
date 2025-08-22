{
  lib,
  callPackage,
  linuxPackagesFor,
  _kernelPatches ? [ ],
}:

let
  linux-asahi-pkg =
    {
      stdenv,
      lib,
      fetchFromGitHub,
      buildLinux,
      ...
    }:
    buildLinux rec {
      inherit stdenv lib;

      version = "6.15.10-asahi";
      modDirVersion = version;
      extraMeta.branch = "6.15";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        tag = "asahi-6.15.10-3";
        hash = "sha256-au/v0bLzBaAMscfk47MZpyiG8pomw08qlT1RjVO9/x4=";
      };

      kernelPatches = [
        {
          name = "Asahi config";
          patch = null;
          structuredExtraConfig = with lib.kernel; {
            # Needed for GPU
            ARM64_16K_PAGES = yes;

            # Might lead to the machine rebooting if not loaded soon enough
            APPLE_WATCHDOG = yes;

            # Can not be built as a module, defaults to no
            APPLE_M1_CPU_PMU = yes;

            # Defaults to 'y', but we want to allow the user to set options in modprobe.d
            HID_APPLE = module;
          };
          features.rust = true;
        }
      ]
      ++ _kernelPatches;
    };

  linux-asahi = (callPackage linux-asahi-pkg { }).overrideAttrs (_: {
    # FIXME: Remove when https://github.com/NixOS/nixpkgs/pull/436245 lands
    preConfigure = ''
      export RUST_LIB_SRC KRUSTFLAGS
    '';
  });
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)
