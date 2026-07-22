{
  lib,
  callPackage,
  linuxPackagesFor,
  _kernelPatches ? [ ],
}:

let
  linux-asahi-wip-j314-dp-pkg =
    {
      stdenv,
      lib,
      fetchFromGitHub,
      buildLinux,
      ...
    }:
    buildLinux rec {
      inherit stdenv lib;

      pname = "linux-asahi-wip-j314-dp";
      version = "7.1.3-asahi-wip-j314-dp-f4dd286";
      modDirVersion = "7.1.3";
      extraMeta.branch = "7.1";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        rev = "f4dd286f7888b348c757b9a2f28dd7bde4c3532b";
        hash = "sha256-MlBNMOxaGLpOB3xCZkDYyU3kQVwS4zdBlM+niYcCTDU=";
      };

      kernelPatches = [
        {
          name = "CD321x data status tracking";
          patch = ./patches/0001-usb-typec-tipd-Track-data_status-changes-for-CD321x.patch;
        }
        {
          name = "CD321x DRM hotplug events";
          patch = ./patches/0002-usb-typec-tipd-HACK-Use-drm-oob-hotplug-event.patch;
        }
        {
          name = "J314 and J316 DisplayPort alt mode";
          patch = ./patches/0003-arm64-dts-apple-t60xx-j-34-1-46-Add-dp-altmode-hacks.patch;
        }
        {
          name = "J314 and J316 ATC power domain workaround";
          patch = ./patches/0004-HACK-arm64-dts-apple-t60xx-j-34-1-46-Mark-ps_atc1_co.patch;
        }
        {
          name = "CD321x DP hotplug cleanup";
          patch = ./patches/0005-usb-typec-tipd-clean-up-DP-hotplug-port.patch;
        }
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

  linux-asahi-wip-j314-dp = callPackage linux-asahi-wip-j314-dp-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi-wip-j314-dp)
