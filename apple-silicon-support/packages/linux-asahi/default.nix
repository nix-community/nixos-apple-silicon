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
      fetchpatch,
      buildLinux,
      ...
    }:
    buildLinux rec {
      inherit stdenv lib;

      pname = "linux-asahi";
      version = "6.18.8";
      modDirVersion = version;
      extraMeta.branch = "6.18";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        tag = "asahi-6.18.8-1";
        hash = "sha256-0GOtKHW9yIJjruwD13pEFDtqxy5oDefu09pZ6php9xU=";
      };

      kernelPatches = [
        {
          name = "Asahi config";
          patch = null;
          structuredExtraConfig = with lib.kernel; {
            # Needed for GPU
            ARM64_16K_PAGES = yes;

            ARM64_MEMORY_MODEL_CONTROL = yes;
            ARM64_ACTLR_STATE = yes;

            # Might lead to the machine rebooting if not loaded soon enough
            APPLE_WATCHDOG = yes;

            # Can not be built as a module, defaults to no
            APPLE_M1_CPU_PMU = yes;

            # Defaults to 'y', but we want to allow the user to set options in modprobe.d
            HID_APPLE = module;

            APPLE_PMGR_MISC = yes;
            APPLE_PMGR_PWRSTATE = yes;
          };
          features.rust = true;
        }
        {
          name = "Fix https://github.com/nix-community/nixos-apple-silicon/issues/422";
          patch = fetchpatch {
            url = "https://lore.kernel.org/asahi/20260205-asahi-iio-aop-cfg-v1-1-c83e3b00fd0e@kloenk.dev/raw";
            hash = "sha256-XZloBRRe3Y1JoDxFuf4U5GZME8Y7tBG/xJ1VlqNcISk=";
          };
        }
      ]
      ++ _kernelPatches;
    };

  linux-asahi = callPackage linux-asahi-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)
