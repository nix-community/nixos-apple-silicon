{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.hardware.asahi;

  # Script to extract Asahi firmware during boot
  extractAsahiFirmwareInitrdScript = pkgs.writeShellScript "asahi-firmware-extract-initrd" ''
    set -u
    mkdir -p /run/asahi-firmware

    esp_partuuid=""
    read -r -d ''' esp_partuuid < /proc/device-tree/chosen/asahi,efi-system-partition 2>/dev/null || true
    if [ -z "$esp_partuuid" ]; then
      echo "Warning: could not determine Asahi ESP partition UUID"
      exit 0
    fi

    esp_dev="/dev/disk/by-partuuid/$esp_partuuid"

    # Wait up to 3 seconds for udev to create the block device symlink
    i=0
    while [ $i -lt 30 ]; do
      if [ -e "$esp_dev" ]; then
        break
      fi
      sleep 0.1
      i=$((i + 1))
    done
    if [ ! -e "$esp_dev" ]; then
      echo "Warning: ESP block device $esp_dev not found, skipping firmware extraction"
      exit 0
    fi

    mkdir -p /tmp/asahi-esp
    if ! mount -o ro -t vfat "$esp_dev" /tmp/asahi-esp 2>/dev/null; then
      # Fallback: ESP may already be mounted (e.g. custom initrd config).
      # Resolve the real backing device and look it up in /proc/mounts.
      real_dev=""
      real_dev=$(readlink -f "$esp_dev" 2>/dev/null || true)
      existing=""
      if [ -n "$real_dev" ] && [ -r /proc/mounts ]; then
        while read -r dev mnt _; do
          if [ "$dev" = "$esp_dev" ] || [ "$dev" = "$real_dev" ]; then
            existing="$mnt"
            break
          fi
        done < /proc/mounts
      fi
      if [ -n "$existing" ] && mount --bind "$existing" /tmp/asahi-esp; then
        echo "ESP already mounted at $existing, bind-mounting for firmware extraction"
      else
        echo "Warning: failed to mount ESP, skipping firmware extraction"
        rmdir /tmp/asahi-esp 2>/dev/null || true
        exit 0
      fi
    fi

    cleanup() {
      umount /tmp/asahi-esp 2>/dev/null || true
      rmdir /tmp/asahi-esp 2>/dev/null || true
    }
    trap cleanup EXIT

    echo "Extracting Asahi firmware from ESP..."

    if [ -f /tmp/asahi-esp/vendorfw/firmware.cpio ]; then
      mkdir -p /tmp/asahi-fwextract
      (
        cd /tmp/asahi-fwextract
        ${pkgs.cpio}/bin/cpio -id --quiet --no-absolute-filenames < /tmp/asahi-esp/vendorfw/firmware.cpio
      )
      if [ -d /tmp/asahi-fwextract/vendorfw ]; then
        cp -a /tmp/asahi-fwextract/vendorfw/. /run/asahi-firmware/
        echo "Asahi firmware extracted successfully"
        if [ -f /sys/module/firmware_class/parameters/path ]; then
          echo -n "/run/asahi-firmware" > /sys/module/firmware_class/parameters/path
          echo "Registered /run/asahi-firmware as kernel firmware search path"
        fi
      else
        echo "Warning: firmware archive did not contain vendorfw/ directory"
      fi
    elif [ -f /tmp/asahi-esp/asahi/all_firmware.tar.gz ]; then
      echo "Warning: legacy all_firmware.tar.gz found on ESP but boot-time extraction only supports vendorfw/firmware.cpio"
    else
      echo "Warning: vendorfw/firmware.cpio not found on ESP"
    fi
    exit 0
  '';

  # Script to extract Asahi firmware
  # at eval time (not boot-time)
  extractAsahiFirmwareAtEval =
    let
      firmwareDir = cfg.peripheralFirmwareDirectory;
    in
    pkgs.runCommand "asahi-peripheral-firmware"
      {
        nativeBuildInputs = [
          cfg.pkgs.asahi-fwextract
          pkgs.cpio
        ];
      }
      ''
        mkdir -p $out/lib/firmware

        if [ -f "${firmwareDir}/firmware.cpio" ]; then
          cpio_src="${firmwareDir}/firmware.cpio"

        elif [ -f "${firmwareDir}/all_firmware.tar.gz" ]; then
          mkdir extracted
          asahi-fwextract "${firmwareDir}" extracted
          cpio_src=extracted/firmware.cpio

        else
          echo "ERROR: No recognized Asahi firmware format found in ${firmwareDir}" >&2
          echo "Expected: firmware.cpio (installer 0.8.0+) or all_firmware.tar.gz (legacy)" >&2
          exit 1
        fi

        cpio -id --quiet --no-absolute-filenames < "$cpio_src"
        cp -a vendorfw/. $out/lib/firmware
      '';
in
{
  imports = [
    (lib.mkRemovedOptionModule [ "hardware" "asahi" "extractPeripheralFirmware" ] ''
      Eval-time firmware extraction is now enabled by setting
      `hardware.asahi.peripheralFirmwareDirectory` to a path.
      Leave it as `null` (the default) to load firmware from
      the ESP at boot time (recommended).
    '')
  ];

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      {
        hardware.firmware = lib.mkIf (cfg.peripheralFirmwareDirectory != null) [
          extractAsahiFirmwareAtEval
        ];
      }

      (lib.mkIf (cfg.peripheralFirmwareDirectory == null) {
        # vfat + codepage modules for ESP mounting in initrd
        boot.initrd.availableKernelModules = [
          "vfat"
          "nls_cp437"
          "nls_iso8859-1"
        ];

        # Stage 1 systemd service: mount ESP, extract vendorfw, register firmware path.
        # The script and cpio binary must be present in the initrd.
        boot.initrd.systemd.storePaths = [
          pkgs.cpio
          extractAsahiFirmwareInitrdScript
        ];

        boot.initrd.systemd.services.asahi-firmware-extract = {
          description = "Extract Asahi peripheral firmware from ESP";
          wantedBy = [ "initrd.target" ];
          after = [ "systemd-udevd.service" ];
          before = [
            "systemd-modules-load.service"
            "initrd-switch-root.target"
          ];
          unitConfig.DefaultDependencies = false;
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStart = extractAsahiFirmwareInitrdScript;
          };
        };

        # NixOS's udev activation snippet (nixpkgs:
        # nixos/modules/services/hardware/udev.nix, the firmware-loading-path
        # block) unconditionally overwrites
        # /sys/module/firmware_class/parameters/path with the Nix-store combined
        # firmware directory. Re-point it at the initrd-extracted firmware so
        # Wi-Fi/Bluetooth drivers find their blobs. Must run after "udevd" but
        # before systemd-modules-load triggers driver binds.
        system.activationScripts.asahi-firmware-path = lib.stringAfter [ "udevd" ] ''
          if [ -d /run/asahi-firmware ] && [ -e /sys/module/firmware_class/parameters/path ]; then
            echo -n "/run/asahi-firmware" > /sys/module/firmware_class/parameters/path
          fi
        '';
      })
    ]
  );

  options.hardware.asahi.peripheralFirmwareDirectory = lib.mkOption {
    type = lib.types.nullOr lib.types.path;

    default = null;

    description = ''
      Path to a directory containing non-free non-redistributable Asahi
      peripheral firmware (required for Wi-Fi, Bluetooth, etc.).

      When set to a path, the firmware is extracted from that directory into
      the Nix store at evaluation time. Both <filename>firmware.cpio</filename>
      (modern installer 0.8.0+) and <filename>all_firmware.tar.gz</filename>
      (legacy) are supported. This is useful for users who want
      declarative/offline firmware management.

      When left as <literal>null</literal> (the default), firmware is loaded
      directly from the EFI System Partition at boot time. This is the
      recommended approach and matches upstream Fedora Asahi Linux.
    '';
  };
}
