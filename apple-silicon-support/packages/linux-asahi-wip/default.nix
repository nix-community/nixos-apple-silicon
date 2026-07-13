{
  lib,
  callPackage,
  linuxPackagesFor,
  _kernelPatches ? [ ],
}:

let
  linux-asahi-wip-pkg =
    {
      stdenv,
      lib,
      fetchFromGitHub,
      buildLinux,
      ...
    }:
    buildLinux rec {
      inherit stdenv lib;

      pname = "linux-asahi-wip";
      version = "7.1.3-asahi-wip-9015099";
      modDirVersion = "7.1.3";
      extraMeta.branch = "7.1";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        rev = "9015099fc457dbd67181f415b257c201f89ee87c";
        hash = "sha256-dx6S8Q7v7/DlfW9h0Yey/I8vaFWIolV+SOkilHUW4A0=";
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

  linux-asahi-wip = callPackage linux-asahi-wip-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi-wip)
