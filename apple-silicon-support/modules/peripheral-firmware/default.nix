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
    systemd = lib.mkIf extractAtBoot {
      mounts = [
        {
          what = "vendorfw";
          where = "/lib/firmware/vendor";
          type = "tmpfs";
          options = "mode=0755";
          unitConfig.DefaultDependencies = false;
          conflicts = [ "umount.target" ];
          before = [
            "umount.target"
            "sysinit.target"
          ];
          wantedBy = [ "sysinit.target" ];
        }
      ];

      services.asahi-peripheral-firmware = {
        description = "Extract Asahi peripheral firmware from the EFI system partition";

        after = [ "systemd-udevd.service" ];
        before = [
          "systemd-udev-trigger.service"
          "sysinit.target"
          "shutdown.target"
        ];
        conflicts = [ "shutdown.target" ];
        wantedBy = [ "sysinit.target" ];

        unitConfig = {
          DefaultDependencies = false;
          ConditionPathExists = [
            "/proc/device-tree/chosen/asahi,efi-system-partition"
            # already loaded, either by the bootloader or by an earlier run of this service
            "!/lib/firmware/vendor/.vendorfw.manifest"
          ];
          RequiresMountsFor = "/lib/firmware/vendor";
        };

        path = [
          pkgs.cpio
          pkgs.util-linux
        ];

        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          # https://github.com/AsahiLinux/asahi-scripts/blob/main/dracut/modules.d/99asahi-firmware/load-asahi-firmware.sh
          ExecStart = pkgs.writeShellScript "load-asahi-firmware" ''
            set -eu

            VENDORFW=/lib/firmware/vendor

            # mount_sys_esp from asahi-scripts' functions.sh
            mountpoint=/run/.system-efi
            mkdir -p "$mountpoint"
            while grep -q " $mountpoint " /proc/mounts; do
              umount "$mountpoint"
            done

            esp_uuid="$(sed 's/\x00//' /proc/device-tree/chosen/asahi,efi-system-partition)"
            # nixos-rebuild switch means that the mountpoint might be already mounted
            # use bind mount instead
            esp_mnt="$(findmnt --first-only --noheadings --output TARGET --source "PARTUUID=$esp_uuid" || true)"
            if [ -n "$esp_mnt" ]; then
              mount --bind "$esp_mnt" "$mountpoint"
              echo ":: Asahi: Bind-mounted System ESP from $esp_mnt at $mountpoint"
            else
              mount -o ro "PARTUUID=$esp_uuid" "$mountpoint"
              echo ":: Asahi: Mounted System ESP at $mountpoint"
            fi

            if [ ! -e "$mountpoint/vendorfw/firmware.cpio" ]; then
              echo ":: Asahi: Vendor firmware not found in ESP." >&2
              umount "$mountpoint"
              exit 1
            fi

            echo ":: Asahi: Unpacking vendor firmware..."
            staging="$(mktemp -d -p "$VENDORFW")"
            ( cd "$staging"; cpio --quiet -i < "$mountpoint/vendorfw/firmware.cpio" )
            mv "$staging"/vendorfw/* "$VENDORFW"
            if [ -e "$staging/vendorfw/.vendorfw.manifest" ]; then
              mv "$staging"/vendorfw/.vendorfw.manifest "$VENDORFW"
            fi
            rm -rf "$staging"
            echo ":: Asahi firmware unpacked successfully"

            umount "$mountpoint"
          '';
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
        at boot time, see
        https://asahilinux.org/docs/platform/open-os-interop/#os-handling for
        details. This might become the default in the future.
      '';
    };
  };
}
