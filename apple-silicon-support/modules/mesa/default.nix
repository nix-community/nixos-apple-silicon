{ config, lib, ... }:
{
  config = lib.mkIf config.hardware.asahi.enable (lib.mkMerge [
    {
      # required for proper DRM setup even without GPU driver
      services.xserver.config = ''
        Section "OutputClass"
            Identifier "appledrm"
            MatchDriver "apple"
            Driver "modesetting"
            Option "PrimaryGPU" "true"
        EndSection
      '';
    }
    (lib.mkIf config.hardware.asahi.useExperimentalGPUDriver {
      # install the Asahi Mesa version
      hardware.graphics.package = config.hardware.asahi.pkgs.mesa-asahi-edge;
      # required for in-kernel GPU driver
      hardware.asahi.withRust = true;
    })
  ]);

  options.hardware.asahi.useExperimentalGPUDriver = lib.mkOption {
    type = lib.types.bool;
    default = false;
    description = ''
      Use the experimental Asahi Mesa GPU driver.

      Do not report issues using this driver under NixOS to the Asahi project.
    '';
  };

  # hopefully no longer used, should be deprecated eventually
  options.hardware.asahi.experimentalGPUInstallMode = lib.mkOption {
    type = lib.types.enum [ "driver" "replace" "overlay" ];
    default = "replace";
    description = ''
      Mode to use to install the experimental GPU driver into the system.

      driver: install only as a driver, do not replace system Mesa.
        Causes issues with certain programs like Plasma Wayland.

      replace (default): use replaceRuntimeDependencies to replace system Mesa with Asahi Mesa.
        Does not work in pure evaluation context (i.e. in flakes by default).

      overlay: overlay system Mesa with Asahi Mesa
        Requires rebuilding the world.
    '';
  };
}
