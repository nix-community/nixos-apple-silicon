{ lib
, callPackage
, linuxPackagesFor
, _kernelPatches ? [ ]
,
}:

let
  linux-asahi-fairydust-pkg =
    { stdenv
    , lib
    , fetchFromGitHub
    , fetchpatch
    , buildLinux
    , ...
    }:
    buildLinux rec {
      inherit stdenv lib;

      pname = "linux-asahi-fairydust";
      version = "6.19.11-fairydust-61b6e71";
      modDirVersion = "6.19.11";
      extraMeta.branch = "6.19";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        # Pinned to tested commit from fairydust branch
        # This branch adds experimental DP-ALT mode support
        rev = "4e84610e5722c34e48fef3f33f7bd8faedb13348";
        hash = "sha256-G32SzJW1paAUaBCnw5cou20WwpuVR8OZSDRpV58IUJU=";
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
      ]
      ++ _kernelPatches;
    };

  linux-asahi-fairydust = callPackage linux-asahi-fairydust-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi-fairydust)
