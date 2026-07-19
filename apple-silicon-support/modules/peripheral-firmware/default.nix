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
      lib.mkIf
        (
          (config.hardware.asahi.peripheralFirmwareDirectory != null)
          && config.hardware.asahi.extractPeripheralFirmware
        )
        [
          (pkgs.stdenv.mkDerivation {
            name = "asahi-peripheral-firmware";

            nativeBuildInputs = [
              pkgs.cpio
            ];

            buildCommand = ''
              f=${config.hardware.asahi.peripheralFirmwareDirectory}/firmware.cpio
              if [ ! -f $f ]; then
                echo "firmware.cpio missing from peripheralFirmwareDirectory!"
                exit 1
              fi
              cat $f | cpio -id --quiet --no-absolute-filenames

              mkdir -p $out/lib/firmware
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
        firmware necessary for features like Wi-Fi, Webcam or ambient light sensor.
      '';
    };

    peripheralFirmwareDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;

      default = lib.findFirst (path: builtins.pathExists (path + "/firmware.cpio")) null [
        # path when the system is operating normally
        /boot/vendorfw
        # path when the system is mounted in the installer
        /mnt/boot/vendorfw
      ];

      description = ''
        Path to the directory containing the non-free non-redistributable
        peripheral firmware necessary for features like Wi-Fi, Webcam or
        ambient light sensor.

        It is shipped in a `vendorfw/firmware.cpio` file on the ESP and put
        there by the official Asahi Installer.

        The installer can also be invoked from MacOS a second time to re-create
        and add more firmware on an existing installation.

        This currently defaults to the ESP.

        Flake users, and those interested in maximum purity or building
        their NixOS config from another machine will want to copy those files
        elsewhere and specify the path manually.

        In the future, this might be changed to default to loading the
        `firmware.cpio` from the ESP at boot time, see
        https://asahilinux.org/docs/platform/open-os-interop/#os-handling for
        details.
      '';
    };
  };
}
