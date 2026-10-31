{
  config,
  pkgs,
  lib,
  ...
}:
let
  extractAtBoot = (
    config.hardware.asahi.extractPeripheralFirmware
    && config.hardware.asahi.peripheralFirmwareDirectory == null
  );
in
{
  config = lib.mkIf config.hardware.asahi.enable {
    # for mounting the ESP
    boot.initrd.availableKernelModules = lib.mkIf extractAtBoot [
      "vfat"
      "nls_cp437"
      "nls_iso8859-1"
    ];

    boot.initrd.systemd = lib.mkIf extractAtBoot {
      extraBin.cpio = lib.getExe pkgs.cpio;

      mounts = [
        {
          what = "vendorfw";
          where = "/sysroot/lib/firmware/vendor";
          type = "tmpfs";
          options = "mode=0755";
          wantedBy = [ "initrd-fs.target" ];
        }
      ];

      services.asahi-peripheral-firmware = {
        description = "Extract Asahi peripheral firmware from the EFI system partition";

        before = [
          "systemd-udevd.service"
          "systemd-udev-trigger.service"
          "sysinit.target"
          "shutdown.target"
        ];
        conflicts = [ "shutdown.target" ];
        wantedBy = [ "sysinit.target" ];

        unitConfig.DefaultDependencies = false;

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };

        # https://github.com/AsahiLinux/asahi-scripts/blob/main/dracut/modules.d/99asahi-firmware/load-asahi-firmware.sh
        script = ''
          # `/lib` is a store path in the initrd, so this can't be done at build time
          mkdir -p /lib/firmware
          ln -s /vendorfw /lib/firmware/vendor

          if [ -e /vendorfw ]; then
            echo ":: Asahi: Vendor firmware was loaded by the bootloader"
            exit 0
          fi

          if [ ! -e /proc/device-tree/chosen/asahi,efi-system-partition ]; then
            echo ":: Asahi: Missing asahi,efi-system-partition variable, firmware will not be loaded!"
            exit 0
          fi

          echo ":: Asahi: Triggering early load of NVMe modules..."
          modprobe nvme-apple

          for i in $(seq 0 50); do
            [ -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ] && break
            sleep 0.1
          done

          if [ ! -e /sys/bus/platform/drivers/nvme-apple/*.nvme/nvme/nvme*/nvme*n1/ ]; then
            echo ":: Asahi: Timed out waiting for NVMe device" >&2
            exit 1
          fi

          # If the above exists, hopefully the /dev device exists and this will work
          echo ":: Asahi: Unpacking vendor firmware into initramfs..."

          VENDORFW="/run/.system-efi/vendorfw/"

          mkdir -p /run/.system-efi
          esp_uuid="$(tr -d '\0' < /proc/device-tree/chosen/asahi,efi-system-partition)"
          mount "PARTUUID=$esp_uuid" /run/.system-efi

          if [ ! -e "$VENDORFW/firmware.cpio" ]; then
            echo ":: Asahi: Vendor firmware not found in ESP." >&2
            umount /run/.system-efi
            exit 1
          fi

          ( cd /; cpio --quiet -i < "$VENDORFW/firmware.cpio" )
          echo ":: Asahi firmware unpacked successfully"
          umount /run/.system-efi
        '';
      };

      # https://github.com/AsahiLinux/asahi-scripts/blob/main/dracut/modules.d/99asahi-firmware/install-asahi-firmware.sh
      services.asahi-peripheral-firmware-install = {
        description = "Install Asahi peripheral firmware to the root filesystem";

        wantedBy = [ "initrd.target" ];
        before = [ "initrd.target" ];

        unitConfig = {
          ConditionPathExists = "/vendorfw";
          RequiresMountsFor = "/sysroot/lib/firmware/vendor";
        };

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStart = "/bin/cp -a /vendorfw/. /sysroot/lib/firmware/vendor";
        };
      };
    };

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

        You can set this to `null` to load the `firmware.cpio` from the ESP
        at boot time (requires systemd in initrd, default on NixOS), see
        https://asahilinux.org/docs/platform/open-os-interop/#os-handling for
        details. This might become the default in the future.
      '';
    };
  };
}
