# This branch adds experimental DP-ALT mode support

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
      version = "7.0.13-fairydust-c839922";
      modDirVersion = "7.0.13";
      extraMeta.branch = "7.0";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        rev = "c83992242bc1e38bfc861a91696534479a2dbdf4";
        hash = "sha256-sGcgrrf/rpb8u9dvwiTFdNjp18UyuRhW94biH1WMO5I=";
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
