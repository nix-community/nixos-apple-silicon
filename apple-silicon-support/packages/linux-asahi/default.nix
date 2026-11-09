{
  lib,
  callPackage,
  linuxPackagesFor,
  _kernelPatches ? [ ],
}@args:

let
  extraArgs = lib.removeAttrs args [
    "lib"
    "callPackage"
    "linuxPackagesFor"
    "_kernelPatches"
  ];

  linux-asahi-pkg =
    {
      stdenv,
      lib,
      fetchFromGitHub,
      buildLinux,
      ...
    }:
    buildLinux (
      lib.recursiveUpdate rec {
        inherit stdenv lib;

        pname = "linux-asahi";
        version = "7.3.3";
        modDirVersion = version;
        extraMeta.branch = "7.3";

        src = fetchFromGitHub {
          owner = "AsahiLinux";
          repo = "linux";
          tag = "asahi-7.3.3-1";
          hash = "sha256-ly6HBI8yCFWpaY0BlVGSvyF0Dq3lpeZnv6Y2clTjYMk=";
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

              # Defaults to 'n', but needed to prevent bluetooth stuttering
              BT_BRCMEXT = yes;

              # TODO: Delete me when TYR fixes applied
              # https://github.com/AsahiLinux/linux/issues/673
              # asahi adds some fields to OpMapRequest, a gpuvm structure that Tyr
              # uses, but we don't initialise these new fields for them. Should
              # be fixed sometime hopefully.
              DRM_TYR = no;
            };
            features.rust = true;
          }
        ]
        ++ _kernelPatches;
      } extraArgs
    );

  linux-asahi = callPackage linux-asahi-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)
