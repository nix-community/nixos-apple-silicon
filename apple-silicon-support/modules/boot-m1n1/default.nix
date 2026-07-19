{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.hardware.asahi.enable (
    let
      bootM1n1 = pkgs.m1n1.override (
        lib.optionalAttrs (config.boot.m1n1CustomLogo != null) {
          customLogo = config.boot.m1n1CustomLogo;
        }
      );

      bootUBoot = config.hardware.asahi.pkgs.uboot-asahi.override {
        m1n1 = bootM1n1;
      };

      bootFiles = {
        "m1n1/boot.bin" = pkgs.runCommand "boot.bin" { } ''
          cat ${bootM1n1}/lib/m1n1/m1n1.bin \
              ${config.boot.kernelPackages.kernel}/dtbs/apple/*.dtb \
              ${bootUBoot}/u-boot-nodtb.bin.gz \
              > $out
          if [ -n "${config.boot.m1n1ExtraOptions}" ]; then
            echo '${config.boot.m1n1ExtraOptions}' >> $out
          fi
        '';
      };

    in
    {
      # install m1n1 with the boot loader
      boot.loader.grub.extraFiles = bootFiles;
      boot.loader.systemd-boot.extraFiles = bootFiles;
      boot.loader.limine.additionalFiles = bootFiles;

      # ensure the installer has m1n1 in the image
      system.extraDependencies = lib.mkForce [
        bootM1n1
        bootUBoot
      ];
      system.build.m1n1 = bootFiles."m1n1/boot.bin";
    }
  );

  options.boot = {
    m1n1ExtraOptions = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Append extra options to the m1n1 boot binary. Might be useful for fixing
        display problems on Mac minis.
        https://github.com/AsahiLinux/m1n1/issues/159
      '';
    };

    m1n1CustomLogo = lib.mkOption {
      type = lib.types.nullOr lib.types.path;
      default = null;
      description = ''
        Custom logo to build into m1n1. The path must point to a 256x256 PNG.
      '';
    };
  };
}
