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

      version = "6.16.8-asahi";
      modDirVersion = version;
      extraMeta.branch = "6.16";

      src = fetchFromGitHub {
        owner = "AsahiLinux";
        repo = "linux";
        tag = "asahi-6.16.8-1";
        hash = "sha256-dGYPhmOa/ZSB7uJtAZ9ugz08Pqy6/YvhXrbLrwzxPXk=";
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

            # These are necessary, otherwise sound is very quiet.
            # According to James Calligeros (chadmed) this is most likely a race condition.
            SND_SOC_APPLE_MCA = module;
            SND_SOC_APPLE_MACAUDIO = module;
            SND_SOC_CS42L42_CORE = module;
            SND_SOC_CS42L42 = module;
            SND_SOC_CS42L83 = module;
            SND_SOC_CS42L84 = module;
            SND_SOC_TAS2764 = module;
            SND_SOC_TAS2770 = module;
            SND_SIMPLE_CARD_UTILS = module;
          };
          features.rust = true;
        }
      ]
      ++ _kernelPatches;
    };

  linux-asahi = callPackage linux-asahi-pkg { };
in
lib.recurseIntoAttrs (linuxPackagesFor linux-asahi)
