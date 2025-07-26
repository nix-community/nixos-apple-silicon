{ config, pkgs, lib, ... }:
{
  imports = [
    (lib.mkRemovedOptionModule [ "hardware" "asahi" "extractPeripheralFirmware" ] "This option is no longer necessary as the peripheral firmware will be extracted every boot automatically.")
  ];

  config = let
    inherit (lib) mkIf;
    cfg = config.hardware.asahi;
    pkgs' = cfg.pkgs;
  in mkIf config.hardware.asahi.enable {
    assertions = mkIf cfg.usePeripheralFirmwareFromNixStore [
      { assertion = cfg.peripheralFirmwareDirectory != null;
        message = ''
          Managing the peripheral firmware in the Nix Store is enabled
          but the firmware location appears incorrect.
        '';
      }
    ];

    hardware.firmware = mkIf (cfg.peripheralFirmwareDirectory != null && cfg.usePeripheralFirmwareFromNixStore) [
      (pkgs.stdenv.mkDerivation {
        name = "asahi-peripheral-firmware";

        nativeBuildInputs = [ pkgs'.asahi-fwextract pkgs.cpio ];

        buildCommand = ''
          mkdir extracted
          asahi-fwextract ${cfg.peripheralFirmwareDirectory} extracted

          mkdir -p $out/lib/firmware
          cat extracted/firmware.cpio | cpio -id --quiet --no-absolute-filenames
          mv vendorfw/* $out/lib/firmware
        '';
      })
    ];

    boot.postBootCommands = mkIf (!cfg.usePeripheralFirmwareFromNixStore) ''
      echo Extracting Asahi firmware...
      mkdir -p /tmp/.fwsetup/{esp,extracted}

      mount /dev/disk/by-partuuid/`cat /proc/device-tree/chosen/asahi,efi-system-partition` /tmp/.fwsetup/esp
      ${pkgs'.asahi-fwextract}/bin/asahi-fwextract /tmp/.fwsetup/esp/asahi /tmp/.fwsetup/extracted
      umount /tmp/.fwsetup/esp

      pushd /tmp/.fwsetup/
      cat /tmp/.fwsetup/extracted/firmware.cpio | ${pkgs.cpio}/bin/cpio -id --quiet --no-absolute-filenames
      mkdir -p /lib/firmware
      mv vendorfw/* /lib/firmware
      popd
      rm -rf /tmp/.fwsetup
    '';
  };

  options.hardware.asahi = {
    usePeripheralFirmwareFromNixStore = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        By default, the non-free non-redistributable peripheral firmware is
        automatically extracted every boot. If you want more purity,
        this option will add the firmware to the Nix Store and manage it
        like all other firmware in NixOS.

        The firmware is necessary for features like Wi-Fi.

        It is not recommended for flake users to enable this option as the
        firmware is non-redistributable.
      '';
    };

    peripheralFirmwareDirectory = lib.mkOption {
      type = lib.types.nullOr lib.types.path;

      default = lib.findFirst (path: builtins.pathExists (path + "/all_firmware.tar.gz")) null
        [
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
