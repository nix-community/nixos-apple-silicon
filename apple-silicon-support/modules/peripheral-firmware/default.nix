{
  config,
  pkgs,
  lib,
  ...
}:
{
  config = lib.mkIf config.hardware.asahi.enable {
    assertions = lib.mkIf config.hardware.asahi.extractPeripheralFirmware [
      {
        assertion = config.hardware.asahi.peripheralFirmwareDirectory != null;
        message = ''
          Asahi peripheral firmware extraction is enabled but the firmware
          location appears incorrect.
        '';
      }
    ];

    hardware.firmware =
      let
        pkgs' = config.hardware.asahi.pkgs;
      in
      lib.mkIf
        (
          (config.hardware.asahi.peripheralFirmwareDirectory != null)
          && config.hardware.asahi.extractPeripheralFirmware
        )
        [
          (pkgs.stdenv.mkDerivation {
            name = "asahi-peripheral-firmware";

            nativeBuildInputs = [
              pkgs'.asahi-fwextract
              pkgs.cpio
            ];

            buildCommand = ''
              mkdir extracted
              asahi-fwextract ${config.hardware.asahi.peripheralFirmwareDirectory} extracted

              mkdir -p $out/lib/firmware
              cat extracted/firmware.cpio | cpio -id --quiet --no-absolute-filenames
              mv vendorfw/* $out/lib/firmware
            '';
          })
        ];
  };

  options.hardware.asahi = {
    extractPeripheralFirmware = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Automatically extract the non-free non-redistributable peripheral
        firmware necessary for features like Wi-Fi.
      '';
    };

    peripheralFirmwareDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;

      default = lib.findFirst (path: builtins.pathExists (path + "/all_firmware.tar.gz")) null [
        # path when the system is operating normally
        /boot/asahi
        # path when the system is mounted in the installer
        /mnt/boot/asahi
      ];

      description = ''
        Path to the directory containing the non-free non-redistributable
        peripheral firmware necessary for features like Wi-Fi. Ordinarily, this
        will automatically point to the appropriate location on the ESP. Flake
        users and those interested in maximum purity will want to copy those
        files elsewhere and specify this manually.

        Currently, this consists of the files `all-firmware.tar.gz` and
        `kernelcache*`. The official Asahi Linux installer places these files
        in the `asahi` directory of the EFI system partition when creating it.
      '';
    };
  };
}
